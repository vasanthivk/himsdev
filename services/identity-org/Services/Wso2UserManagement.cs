using System.Collections.Concurrent;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace Hims.IdentityOrg.Services;

/// <summary>
/// Config section "Wso2UserManagement": creating HIMS users in WSO2 Identity Server (SCIM2). Each HIMS organization maps to one
/// WSO2 tenant and that tenant's machine-to-machine application (client credentials with the internal_user_mgt_create scope).
/// </summary>
public sealed class Wso2UserManagementOptions
{
    public bool Enabled { get; set; }
    /// <summary>WSO2 IS root, e.g. https://localhost:9443 (the tenant path /t/&lt;domain&gt; is added per tenant).</summary>
    public string BaseUrl { get; set; } = "https://localhost:9443";
    /// <summary>Initial password of users created in WSO2 (and of their HIMS login account).</summary>
    public string DefaultPassword { get; set; } = string.Empty;
    public string Scope { get; set; } = "internal_user_mgt_create internal_role_mgt_users_update";
    /// <summary>Dev only: WSO2 IS ships with a self-signed certificate.</summary>
    public bool AllowUntrustedCertificate { get; set; }
    public List<Wso2Tenant> Tenants { get; set; } = [];

    public Wso2Tenant? TenantFor(int organizationId) => Tenants.FirstOrDefault(t => t.OrganizationId == organizationId);
}

public sealed class Wso2Tenant
{
    public int OrganizationId { get; set; }
    public string TenantDomain { get; set; } = string.Empty;
    public string ClientId { get; set; } = string.Empty;
    public string ClientSecret { get; set; } = string.Empty;
}

/// <summary>A WSO2 call that failed, with WSO2's own message (shown to the user).</summary>
public sealed class Wso2Exception(string message, int statusCode) : Exception(message)
{
    public int StatusCode { get; } = statusCode;
}

/// <param name="Email">Sent as the work email when known; null = no emails attribute.</param>
public sealed record Wso2NewUser(string UserName, string? Email, string Password, string GivenName, string FamilyName, string EmployeeId);

public sealed class Wso2UserManagement(IHttpClientFactory httpFactory, Wso2UserManagementOptions options, ILogger<Wso2UserManagement> log)
{
    public const string HttpClientName = "wso2";
    private const string CoreSchema = "urn:ietf:params:scim:schemas:core:2.0:User";
    private const string CustomSchema = "urn:scim:schemas:extension:custom:User";

    // tenant domain -> (token, expires at). Client-credentials tokens are reused until shortly before they expire.
    private static readonly ConcurrentDictionary<string, (string Token, DateTime ExpiresAt)> Tokens = new();

    private string TenantUrl(Wso2Tenant t) => $"{options.BaseUrl.TrimEnd('/')}/t/{t.TenantDomain}";

    /// <summary>Creates the user in the tenant's WSO2 user store; returns the WSO2 (SCIM) user id.</summary>
    public async Task<string> CreateUserAsync(Wso2Tenant tenant, Wso2NewUser user, CancellationToken ct)
    {
        var body = new Dictionary<string, object>
        {
            ["schemas"] = new[] { CoreSchema, CustomSchema },
            ["userName"] = user.UserName,
            ["password"] = user.Password,
            ["name"] = new { givenName = user.GivenName, familyName = user.FamilyName },
            [CustomSchema] = new { employeeId = user.EmployeeId },
        };
        if (user.Email is not null) body["emails"] = new[] { new { value = user.Email, type = "work", primary = true } };
        using var req = new HttpRequestMessage(HttpMethod.Post, $"{TenantUrl(tenant)}/scim2/Users")
        {
            Content = new StringContent(JsonSerializer.Serialize(body), Encoding.UTF8, "application/scim+json"),
        };
        req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", await TokenAsync(tenant, ct));

        using var res = await httpFactory.CreateClient(HttpClientName).SendAsync(req, ct);
        var text = await res.Content.ReadAsStringAsync(ct);
        if (!res.IsSuccessStatusCode)
        {
            var detail = ErrorDetail(text) ?? res.ReasonPhrase;
            log.LogWarning("WSO2 SCIM create user {UserName} in {Tenant} failed: {Status} {Detail}", user.UserName, tenant.TenantDomain, (int)res.StatusCode, detail);
            throw new Wso2Exception($"WSO2 could not create the user: {detail}", (int)res.StatusCode);
        }
        var id = JsonDocument.Parse(text).RootElement.GetProperty("id").GetString()!;
        log.LogInformation("WSO2 user {UserName} created in {Tenant} (id {Id})", user.UserName, tenant.TenantDomain, id);
        return id;
    }

    private async Task<string> TokenAsync(Wso2Tenant tenant, CancellationToken ct)
    {
        if (Tokens.TryGetValue(tenant.TenantDomain, out var cached) && cached.ExpiresAt > DateTime.UtcNow) return cached.Token;

        using var req = new HttpRequestMessage(HttpMethod.Post, $"{TenantUrl(tenant)}/oauth2/token")
        {
            Content = new FormUrlEncodedContent(new Dictionary<string, string> { ["grant_type"] = "client_credentials", ["scope"] = options.Scope }),
        };
        req.Headers.Authorization = new AuthenticationHeaderValue("Basic",
            Convert.ToBase64String(Encoding.UTF8.GetBytes($"{tenant.ClientId}:{tenant.ClientSecret}")));

        using var res = await httpFactory.CreateClient(HttpClientName).SendAsync(req, ct);
        var text = await res.Content.ReadAsStringAsync(ct);
        if (!res.IsSuccessStatusCode)
            throw new Wso2Exception($"WSO2 rejected the user-management credentials for {tenant.TenantDomain}: {ErrorDetail(text) ?? res.ReasonPhrase}", (int)res.StatusCode);

        var json = JsonDocument.Parse(text).RootElement;
        var token = json.GetProperty("access_token").GetString()!;
        var expiresIn = json.TryGetProperty("expires_in", out var e) ? e.GetInt32() : 3600;
        Tokens[tenant.TenantDomain] = (token, DateTime.UtcNow.AddSeconds(Math.Max(60, expiresIn - 60)));
        return token;
    }

    /// <summary>SCIM errors carry "detail"; OAuth errors carry "error_description".</summary>
    private static string? ErrorDetail(string text)
    {
        try
        {
            var root = JsonDocument.Parse(text).RootElement;
            foreach (var name in new[] { "detail", "error_description", "error", "message" })
                if (root.TryGetProperty(name, out var v) && v.ValueKind == JsonValueKind.String) return v.GetString();
        }
        catch (JsonException) { }
        return string.IsNullOrWhiteSpace(text) ? null : text.Length > 300 ? text[..300] : text;
    }
}
