using Hims.Common.Data;
using Hims.Common.Http;
using Hims.IdentityOrg.Data;
using Microsoft.EntityFrameworkCore;

namespace Hims.IdentityOrg.Services;

/// <summary>
/// First-run setup for HIMS's own login (WSO2_AUTHENTICATION=false): in each tenant database whose sec.user_account is empty,
/// creates the ADMIN role and the user in Jwt:BootstrapAdmin, so someone can sign in and create the other users (POST /api/auth/users).
/// Does nothing in a database once any user exists there. Change the password afterwards and remove it from appsettings.json.
/// </summary>
public static class AuthBootstrap
{
    public const string AdminRole = "ADMIN";

    public static async Task SeedBootstrapAdminAsync(this WebApplication app)
    {
        var mode = app.Services.GetRequiredService<HimsAuthMode>();
        var username = app.Configuration["Jwt:BootstrapAdmin:Username"];
        var password = app.Configuration["Jwt:BootstrapAdmin:Password"];
        if (!mode.HimsJwt || string.IsNullOrWhiteSpace(username) || string.IsNullOrEmpty(password)) return;

        var log = app.Services.GetRequiredService<ILoggerFactory>().CreateLogger("Hims.Auth");
        foreach (var tenant in app.Services.GetRequiredService<HimsTenants>().All)
            await SeedAsync(app, tenant, username, password, log);
    }

    private static async Task SeedAsync(WebApplication app, HimsTenant tenant, string username, string password, ILogger log)
    {
        try
        {
            await using var scope = app.Services.CreateAsyncScope();
            scope.ServiceProvider.GetRequiredService<HimsTenantContext>().Use(tenant);
            var db = scope.ServiceProvider.GetRequiredService<IdentityOrgDbContext>();
            if (await db.UserAccounts.AnyAsync()) return;

            var organizationId = await db.Organizations.Where(o => o.OrganizationId == tenant.OrganizationId).Select(o => o.OrganizationId).FirstAsync();
            await using var tx = await db.Database.BeginTransactionAsync();
            var role = await EnsureRole(db, organizationId, AdminRole, CancellationToken.None);
            var user = new UserAccount
            {
                OrganizationId = organizationId, UserType = "STAFF", Username = username.Trim(),
                PasswordHash = PasswordHasher.Hash(password), MfaEnabled = false, PasswordChangedAt = DateTime.UtcNow,
            };
            db.UserAccounts.Add(user);
            await db.SaveChangesAsync();
            db.UserRoles.Add(new UserRole { UserId = user.UserId, RoleId = role.RoleId });
            await db.SaveChangesAsync();
            await tx.CommitAsync();
            log.LogWarning("Created bootstrap admin user '{Username}' (user {UserId}, organization {OrganizationId}) in the {Tenant} database - change its password and remove Jwt:BootstrapAdmin from appsettings.json.",
                user.Username, user.UserId, organizationId, tenant.Name);
        }
        catch (Exception e)
        {
            log.LogError(e, "Could not create the bootstrap admin user in the {Tenant} database", tenant.Name);
        }
    }

    /// <summary>The organization's role with this code, created when missing.</summary>
    public static async Task<Role> EnsureRole(IdentityOrgDbContext db, int organizationId, string roleCode, CancellationToken ct)
    {
        var role = await db.Roles.FirstOrDefaultAsync(r => r.OrganizationId == organizationId && r.RoleCode == roleCode, ct);
        if (role is not null) return role;
        var name = string.Join(' ', roleCode.Split('_', StringSplitOptions.RemoveEmptyEntries).Select(w => w[..1] + w[1..].ToLowerInvariant()));
        role = new Role { OrganizationId = organizationId, RoleCode = roleCode, RoleName = name };
        db.Roles.Add(role);
        await db.SaveChangesAsync(ct);
        return role;
    }
}
