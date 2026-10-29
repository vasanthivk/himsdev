using Hims.Common.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;

namespace Hims.Common.Data;

/// <summary>One hospital group: its frontend subdomain (= its connection string name), its HIMS organization and its database.</summary>
public sealed record HimsTenant(string Name, int OrganizationId, string ConnectionString);

/// <summary>
/// Every tenant has its own database. appsettings.json:
///   "ConnectionStrings": { "reddys": "...Database=hims_reddys...", "apollo": "...Database=hims_apollo..." },
///   "Tenants": [ { "Name": "reddys", "OrganizationId": 1 }, { "Name": "apollo", "OrganizationId": 2 } ]
/// The first tenant is the default: a request that names no organization (Swagger, curl) uses it.
/// </summary>
public sealed class HimsTenants
{
    private sealed class Entry { public string Name { get; set; } = string.Empty; public int OrganizationId { get; set; } }

    public IReadOnlyList<HimsTenant> All { get; }
    public HimsTenant Default => All[0];

    public HimsTenants(IConfiguration config)
    {
        var entries = config.GetSection("Tenants").Get<Entry[]>() ?? [];
        if (entries.Length == 0) throw new InvalidOperationException("Tenants is not configured (e.g. [ { \"Name\": \"reddys\", \"OrganizationId\": 1 } ])");
        All = entries.Select(e => new HimsTenant(e.Name.ToLowerInvariant(), e.OrganizationId,
            config.GetConnectionString(e.Name) ?? throw new InvalidOperationException($"ConnectionStrings:{e.Name} is not configured (tenant {e.Name})"))).ToList();
        var duplicate = All.GroupBy(t => t.OrganizationId).FirstOrDefault(g => g.Count() > 1);
        if (duplicate is not null) throw new InvalidOperationException($"Tenants: organization {duplicate.Key} is configured more than once");
    }

    public HimsTenant? ForOrganization(int organizationId) => All.FirstOrDefault(t => t.OrganizationId == organizationId);

    public HimsTenant? ForName(string? name) =>
        string.IsNullOrEmpty(name) ? null : All.FirstOrDefault(t => string.Equals(t.Name, name, StringComparison.OrdinalIgnoreCase));

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
}

/// <summary>
/// The tenant (database) of the current unit of work. An API request: the organization of the signed-in user's token, else
/// (sign-in itself) the frontend's subdomain, else the default tenant. An event: set from its organizationId by the consumer.
/// </summary>
public sealed class HimsTenantContext(HimsTenants tenants, IHttpContextAccessor http)
{
    private HimsTenant? _current;

    public HimsTenant Current => _current ??= Resolve();

    /// <summary>Fixes the tenant for this scope (event consumer, background jobs). Must be called before the DbContext is created.</summary>
    public void Use(HimsTenant tenant) => _current = tenant;

    private HimsTenant Resolve()
    {
        var ctx = http.HttpContext;
        if (ctx is null) return tenants.Default;

        if (int.TryParse(ctx.User.FindFirst(HimsClaims.Organization)?.Value, out var org))
            return tenants.ForOrganization(org) ?? throw new InvalidOperationException($"No database is configured for organization {org} (Tenants)");

        var subdomain = HimsTenants.RequestSubdomain(ctx.Request);
        return tenants.ForName(subdomain) ?? tenants.Default;
    }
}
