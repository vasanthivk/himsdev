using System.Collections.Concurrent;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace Hims.IdentityOrg.Services;

/// <summary>
/// Config section "Wso2UserManagement": creating HIMS users in WSO2 Identity Server (SCIM2). Each frontend subdomain
/// (reddys.localhost:3000 -> "reddys") maps to one WSO2 tenant and that tenant's machine-to-machine application (client
/// credentials with the internal_user_mgt_* scopes), like the shell's &lt;SUBDOMAIN&gt;_WSO2_* settings for sign-in.
/// </summary>
public sealed class Wso2UserManagementOptions
{
    public bool Enabled { get; set; }
    /// <summary>WSO2 IS root, e.g. https://localhost:9443 (the tenant path /t/&lt;domain&gt; is added per tenant).</summary>
    public string BaseUrl { get; set; } = "https://localhost:9443";
    /// <summary>Initial password of users created in WSO2 (and of their HIMS login account).</summary>
    public string DefaultPassword { get; set; } = string.Empty;
    public string Scope { get; set; } = "internal_user_mgt_create internal_user_mgt_list internal_user_mgt_update internal_role_mgt_users_update";
    /// <summary>Dev only: WSO2 IS ships with a self-signed certificate.</summary>
    public bool AllowUntrustedCertificate { get; set; }
    public List<Wso2Tenant> Tenants { get; set; } = [];

    public Wso2Tenant? TenantForSubdomain(string? subdomain) =>
        string.IsNullOrEmpty(subdomain) ? null : Tenants.FirstOrDefault(t => string.Equals(t.Subdomain, subdomain, StringComparison.OrdinalIgnoreCase));

    public Wso2Tenant? TenantForDomain(string? tenantDomain) =>
        string.IsNullOrEmpty(tenantDomain) ? null : Tenants.FirstOrDefault(t => string.Equals(t.TenantDomain, tenantDomain, StringComparison.OrdinalIgnoreCase));

    /// <summary>
    /// The subdomain of the frontend the request came from: the first label of the browser's Origin (or Referer) host,
    /// e.g. https://apollo.localhost:3000 -> "apollo". Null when there is none (e.g. a request from Postman or curl).
    /// </summary>
    public static string? RequestSubdomain(HttpRequest request)
    {
        foreach (var header in new[] { "Origin", "Referer" })
        {
            if (!Uri.TryCreate(request.Headers[header].ToString(), UriKind.Absolute, out var uri)) continue;
            var labels = uri.Host.Split('.');
            return labels.Length > 1 ? labels[0].ToLowerInvariant() : null;
        }
        return null;
    }

    /// <summary>The HIMS organization of the frontend the request came from (by subdomain); null = unknown, so not filtered.</summary>
    public int? OrganizationIdFor(HttpRequest request) => TenantForSubdomain(RequestSubdomain(request))?.OrganizationId;
}

public sealed class Wso2Tenant
{
    /// <summary>Frontend subdomain this tenant serves, e.g. "reddys" for https://reddys.localhost:3000.</summary>
    public string Subdomain { get; set; } = string.Empty;
    /// <summary>The HIMS organization (core.organization) of this subdomain: its branches, departments, roles and users.</summary>
    public int? OrganizationId { get; set; }
    public string TenantDomain { get; set; } = string.Empty;
    public string ClientId { get; set; } = string.Empty;
    public string ClientSecret { get; set; } = string.Empty;
}

public static class Wso2TenantResolver
{
    /// <summary>
    /// The WSO2 tenant for this request: the one configured for the frontend's subdomain, else (no Origin, e.g. Postman) the
    /// tenant the caller signed in to (the token's org_handle). With WSO2 sign-in the two must agree, so a reddys user cannot
    /// manage apollo.com users by calling from the apollo site. Error = a message for the caller (tenant is then null).
    /// </summary>
    public static (Wso2Tenant? Tenant, string? Error) Resolve(Wso2UserManagementOptions options, HttpRequest request, System.Security.Claims.ClaimsPrincipal user)
    {
        var subdomain = Wso2UserManagementOptions.RequestSubdomain(request);
        var signedInTenant = user.FindFirst("org_handle")?.Value;
        if (subdomain is not null)
        {
            var tenant = options.TenantForSubdomain(subdomain);
            if (tenant is null) return (null, $"WSO2 user management is not configured for {subdomain} (Wso2UserManagement:Tenants Subdomain \"{subdomain}\").");
            if (signedInTenant is not null && !string.Equals(signedInTenant, tenant.TenantDomain, StringComparison.OrdinalIgnoreCase))
                return (null, $"You are signed in to {signedInTenant}, not to {tenant.TenantDomain} ({subdomain}).");
            return (tenant, null);
        }
        return options.TenantForDomain(signedInTenant) is { } t ? (t, null)
            : (null, "Cannot tell the organization from the request (no Origin header and no WSO2 tenant in the sign-in).");
    }
}

/// <summary>A WSO2 call that failed, with WSO2's own message (shown to the user).</summary>
public sealed class Wso2Exception(string message, int statusCode) : Exception(message)
{
    public int StatusCode { get; } = statusCode;
}

/// <param name="Email">Sent as the work email when known; null = no emails attribute.</param>
/// <summary>A WSO2 user: its SCIM id and the employeeId attribute (HIMS employee_id) when HIMS created it.</summary>
public sealed record Wso2User(string Id, string? EmployeeId);

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

    /// <summary>
    /// The user with this userName (WSO2 id and the employeeId HIMS stored when it created the user), or null when the tenant has
    /// no such user. Needs internal_user_mgt_list.
    /// </summary>
    public async Task<Wso2User?> FindUserAsync(Wso2Tenant tenant, string userName, CancellationToken ct)
    {
        var filter = Uri.EscapeDataString($"userName eq \"{userName.Replace("\"", "")}\"");
        var attributes = Uri.EscapeDataString($"id,userName,{CustomSchema}:employeeId");
        using var req = new HttpRequestMessage(HttpMethod.Get, $"{TenantUrl(tenant)}/scim2/Users?filter={filter}&attributes={attributes}");
        req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", await TokenAsync(tenant, ct));
        using var res = await httpFactory.CreateClient(HttpClientName).SendAsync(req, ct);
        var text = await res.Content.ReadAsStringAsync(ct);
        if (!res.IsSuccessStatusCode) throw new Wso2Exception($"WSO2 could not look up user {userName}: {ErrorDetail(text) ?? res.ReasonPhrase}", (int)res.StatusCode);
        var root = JsonDocument.Parse(text).RootElement;
        if (!root.TryGetProperty("Resources", out var users)) return null;
        // userName may come back with the user-store prefix (e.g. "DEFAULT/john"): match on the part after the slash.
        foreach (var u in users.EnumerateArray())
        {
            var name = u.GetProperty("userName").GetString() ?? "";
            if (!string.Equals(name[(name.IndexOf('/') + 1)..], userName, StringComparison.OrdinalIgnoreCase)) continue;
            var employeeId = u.TryGetProperty(CustomSchema, out var ext) && ext.TryGetProperty("employeeId", out var e) ? e.ToString() : null;
            return new Wso2User(u.GetProperty("id").GetString()!, employeeId);
        }
        return null;
    }

    /// <summary>Replaces the user's password (SCIM2 PATCH). Needs internal_user_mgt_update. WSO2 applies its own password policy.</summary>
    public async Task SetPasswordAsync(Wso2Tenant tenant, string userId, string password, CancellationToken ct)
    {
        var body = new
        {
            schemas = new[] { "urn:ietf:params:scim:api:messages:2.0:PatchOp" },
            Operations = new[] { new { op = "replace", value = new { password } } },
        };
        using var req = new HttpRequestMessage(HttpMethod.Patch, $"{TenantUrl(tenant)}/scim2/Users/{Uri.EscapeDataString(userId)}")
        {
            Content = new StringContent(JsonSerializer.Serialize(body), Encoding.UTF8, "application/scim+json"),
        };
        req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", await TokenAsync(tenant, ct));
        using var res = await httpFactory.CreateClient(HttpClientName).SendAsync(req, ct);
        if (!res.IsSuccessStatusCode)
        {
            var detail = ErrorDetail(await res.Content.ReadAsStringAsync(ct)) ?? res.ReasonPhrase;
            log.LogWarning("WSO2 password change for user {UserId} in {Tenant} failed: {Status} {Detail}", userId, tenant.TenantDomain, (int)res.StatusCode, detail);
            throw new Wso2Exception($"WSO2 did not accept the new password: {detail}", (int)res.StatusCode);
        }
        log.LogInformation("WSO2 password changed for user {UserId} in {Tenant}", userId, tenant.TenantDomain);
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
