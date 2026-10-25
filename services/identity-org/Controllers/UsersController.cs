using System.Net.Mail;
using Hims.Common.Data;
using Hims.Common.Http;
using Hims.IdentityOrg.Data;
using Hims.IdentityOrg.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.IdentityOrg.Controllers;

/// <summary>
/// Staff users. Creating one writes, in one transaction, the employee (hr.employee) and an EmployeeUpdated event that the other
/// services copy into their ref.employee, and the employee's roles (sec.user_role rows of the employee's sec.user_account). With
/// portal access the account is a login - username and password, plus the user in the organization's WSO2 Identity Server tenant
/// (SCIM2), linked through sec.user_account.wso2_user_id. Without portal access but with roles, the account only holds the roles:
/// its username is the employee code and it has no password and no WSO2 user, so it cannot sign in. The transaction is committed only after WSO2 accepts the user, so a WSO2 failure leaves nothing
/// behind in HIMS.
/// </summary>
[ApiController]
[Route("api")]
public class UsersController(IdentityOrgDbContext db, HimsAuthMode mode, Wso2UserManagementOptions wso2Options, Wso2UserManagement wso2,
    ILogger<UsersController> log) : ControllerBase
{
    /// <param name="PortalAccess">Create a login (WSO2 user + HIMS username and password). Null = true, as before this option existed.</param>
    /// <param name="Roles">The employee's roles, with or without portal access.</param>
    /// <param name="Username">Login name; required with portal access.</param>
    /// <param name="Password">Initial password for WSO2 and the HIMS login; empty = Wso2UserManagement:DefaultPassword.</param>
    public record CreateUserRequest(int BranchId, string? Title, string FirstName, string LastName, string Gender, bool? PortalAccess,
        string? Username, string? Mobile, int? DepartmentId, string? EmploymentType, string[]? Roles, string? Password);

    /// <summary>
    /// Staff with their login, if any: every employee (with or without portal access) plus logins without an employee (e.g. the
    /// bootstrap admin). PortalAccess = the account can sign in: it has a WSO2 user linked to it (sec.user_account.wso2_user_id) or a
    /// HIMS password. Accounts that only hold roles have neither and show no username.
    /// </summary>
    [HttpGet("users")]
    public async Task<IActionResult> List(CancellationToken ct)
    {
        // From a tenant's site (e.g. apollo.localhost) only that tenant's organization.
        var org = wso2Options.OrganizationIdFor(Request);
        var employees = await db.Employees.Where(e => org == null || e.OrganizationId == org).OrderBy(e => e.EmployeeId).ToListAsync(ct);
        var accounts = await db.UserAccounts.Where(u => org == null || u.OrganizationId == org).ToListAsync(ct);
        var roles = await (from ur in db.UserRoles
                           join r in db.Roles on ur.RoleId equals r.RoleId
                           where ur.IsActive
                           select new { ur.UserId, r.RoleCode }).ToListAsync(ct);
        object Row(Employee? e, UserAccount? u)
        {
            var login = u is not null && (u.Wso2UserId is not null || u.PasswordHash is not null);
            return new
            {
                UserId = login ? u!.UserId : (long?)null, Username = login ? u!.Username : null, u?.UserType,
                IsActive = u?.IsActive ?? e?.IsActive ?? false, IsLocked = u?.IsLocked ?? false, u?.LastLoginAt, CreatedAt = u?.CreatedAt ?? e!.CreatedAt,
                EmployeeId = e?.EmployeeId, e?.EmployeeCode, e?.FirstName, e?.LastName, e?.Email, e?.Mobile, BranchId = e?.BranchId, e?.DepartmentId,
                PortalAccess = login,
                Roles = u is null ? [] : roles.Where(r => r.UserId == u.UserId).Select(r => r.RoleCode).Distinct().ToList(),
            };
        }
        var rows = employees.Select(e => Row(e, accounts.FirstOrDefault(a => a.EmployeeId == e.EmployeeId)))
            .Concat(accounts.Where(a => a.EmployeeId is null).OrderBy(a => a.UserId).Select(a => Row(null, a)));
        return Ok(rows);
    }

    /// <summary>Roles defined for the organization (sec.role) - of the tenant's organization when called from a tenant's site.</summary>
    [HttpGet("roles")]
    public async Task<IActionResult> Roles(CancellationToken ct)
    {
        var org = wso2Options.OrganizationIdFor(Request);
        return Ok(await db.Roles.Where(r => r.IsActive && (org == null || r.OrganizationId == org)).OrderBy(r => r.RoleCode).Select(r => new { r.RoleId, r.RoleCode, r.RoleName }).ToListAsync(ct));
    }

    /// <summary>Creates a staff member in HIMS and, with portal access, their login in HIMS and WSO2 Identity Server (see the class summary).</summary>
    [HttpPost("users")]
    public async Task<IActionResult> Create(CreateUserRequest req, CancellationToken ct)
    {
        // With HIMS's own login only ADMIN may create users; with WSO2 sign-in any signed-in user passing Auth:WriteRoles may.
        if (mode.Enabled && mode.HimsJwt && !User.IsInRole(AuthBootstrap.AdminRole))
            return StatusCode(StatusCodes.Status403Forbidden, new { error = "Only ADMIN users can create users." });

        var portalAccess = req.PortalAccess ?? true;
        var firstName = (req.FirstName ?? "").Trim();
        var lastName = (req.LastName ?? "").Trim();
        var gender = (req.Gender ?? "").Trim().ToLowerInvariant();
        if (firstName.Length == 0 || lastName.Length == 0) return BadRequest(new { error = "Name and surname are required." });
        if (gender is not ("male" or "female" or "other")) return BadRequest(new { error = "Gender must be male, female or other." });

        var username = portalAccess ? (req.Username ?? "").Trim() : "";
        var password = string.IsNullOrEmpty(req.Password) ? wso2Options.DefaultPassword : req.Password;
        // When the username is an email address it is also the employee's email (and WSO2's emails attribute).
        string? email = portalAccess && MailAddress.TryCreate(username, out var mail) && mail.Address == username ? username.ToLowerInvariant() : null;
        if (portalAccess)
        {
            if (username.Length is < 3 or > 100) return BadRequest(new { error = "Username must be 3-100 characters long." });
            if (username.Any(char.IsWhiteSpace)) return BadRequest(new { error = "Username must not contain spaces." });
            if (!string.IsNullOrEmpty(req.Password) && PasswordPolicy.Problem(req.Password) is { } problem) return BadRequest(new { error = problem });
        }

        var branch = await db.Branches.FirstOrDefaultAsync(b => b.BranchId == req.BranchId, ct);
        if (branch is null) return BadRequest(new { error = $"Branch {req.BranchId} does not exist." });
        if (wso2Options.OrganizationIdFor(Request) is { } siteOrg && branch.OrganizationId != siteOrg)
            return BadRequest(new { error = $"Branch {branch.BranchName} does not belong to this site's organization." });
        if (req.DepartmentId is { } dept && !await db.Departments.AnyAsync(d => d.DepartmentId == dept && d.OrganizationId == branch.OrganizationId, ct))
            return BadRequest(new { error = $"Department {dept} does not exist in this organization." });

        Wso2Tenant? tenant = null;
        if (portalAccess)
        {
            var usernameLower = username.ToLowerInvariant();
            if (await db.UserAccounts.AnyAsync(u => u.Username.ToLower() == usernameLower, ct))
                return Conflict(new { error = $"A user with username {username} already exists." });
            if (email is not null && await db.Employees.AnyAsync(e => e.Email == email, ct))
                return Conflict(new { error = $"An employee with email {email} already exists." });
            if (wso2Options.Enabled)
            {
                // The WSO2 tenant of the frontend the admin is using (reddys.localhost -> newmeksolutions.com, apollo.localhost -> apollo.com).
                (tenant, var tenantError) = Wso2TenantResolver.Resolve(wso2Options, Request, User);
                if (tenant is null) return BadRequest(new { error = tenantError });
                if (string.IsNullOrEmpty(password)) return BadRequest(new { error = "Enter a password (no default password is configured)." });
            }
        }
        long? createdBy = long.TryParse(User.FindFirst(HimsClaims.Subject)?.Value, out var by) ? by : null;
        var roleCodes = (req.Roles ?? []).Select(r => r.Trim().ToUpperInvariant()).Where(r => r.Length > 0).Distinct().ToList();

        await using var tx = await db.Database.BeginTransactionAsync(ct);

        // Employee code E0001, E0002, ... - serialised with an advisory lock held until the transaction ends.
        await db.Database.ExecuteSqlRawAsync("SELECT pg_advisory_xact_lock(hashtext('hr.employee.employee_code'))", ct);
        // hr.employee, or identity_org.hr_employee in the shared database - taken from the EF mapping.
        var employeeTable = db.Model.FindEntityType(typeof(Employee))!.GetSchemaQualifiedTableName();
        var rows = await db.QueryAsync($@"SELECT COALESCE(MAX(CAST(SUBSTRING(employee_code FROM 2) AS BIGINT)), 0)
                                           FROM {employeeTable} WHERE employee_code ~ '^E[0-9]+$'", new Dictionary<string, object>(), ct);
        var code = $"E{Convert.ToInt64(rows[0][0]) + 1:D4}";

        var employee = new Employee
        {
            OrganizationId = branch.OrganizationId, BranchId = branch.BranchId, EmployeeCode = code, Title = Clean(req.Title),
            FirstName = firstName, LastName = lastName, Gender = gender, Email = email, Mobile = Clean(req.Mobile),
            DepartmentId = req.DepartmentId, EmploymentType = Clean(req.EmploymentType)?.ToUpperInvariant() ?? "PERMANENT",
            EmployeeStatus = "ACTIVE", DateOfJoining = DateOnly.FromDateTime(DateTime.UtcNow), CreatedBy = createdBy,
        };
        db.Employees.Add(employee);
        await db.SaveChangesAsync(ct);

        // The account holds the roles (sec.user_role references sec.user_account); without portal access it is not a login.
        UserAccount? user = null;
        if (portalAccess || roleCodes.Count > 0)
        {
            user = new UserAccount
            {
                OrganizationId = branch.OrganizationId, UserType = "STAFF", Username = portalAccess ? username : code, EmployeeId = employee.EmployeeId,
                PasswordHash = !portalAccess || string.IsNullOrEmpty(password) ? null : PasswordHasher.Hash(password),
                MfaEnabled = false, PasswordChangedAt = DateTime.UtcNow, CreatedBy = createdBy,
            };
            db.UserAccounts.Add(user);
            await db.SaveChangesAsync(ct);
            foreach (var roleCode in roleCodes)
            {
                var role = await AuthBootstrap.EnsureRole(db, branch.OrganizationId, roleCode, ct);
                db.UserRoles.Add(new UserRole { UserId = user.UserId, RoleId = role.RoleId, CreatedBy = createdBy });
            }
        }

        // Only the columns the other services keep in ref.employee - no personal identifiers in the event.
        db.EnqueueEvent("EmployeeUpdated", "hr.employee", employee.EmployeeId, new
        {
            employee.EmployeeId, employee.OrganizationId, employee.BranchId, employee.EmployeeCode, employee.FirstName, employee.LastName,
            employee.DepartmentId, employee.DesignationId, employee.EmployeeStatus,
        }, employee.OrganizationId, employee.BranchId);
        await db.SaveChangesAsync(ct);

        string? wso2UserId = null;
        if (portalAccess && user is not null && tenant is not null)
        {
            try
            {
                wso2UserId = await wso2.CreateUserAsync(tenant,
                    new Wso2NewUser(username, email, password, firstName, lastName, employee.EmployeeId.ToString()), ct);
                user.Wso2UserId = wso2UserId;   // links the HIMS account to its WSO2 user (used e.g. by Change password)
                await db.SaveChangesAsync(ct);
            }
            catch (Exception e) when (e is Wso2Exception or HttpRequestException or TaskCanceledException)
            {
                // Not committed: the employee, login, roles and event are all rolled back.
                var status = e is Wso2Exception { StatusCode: 409 } ? 409 : 502;
                return StatusCode(status, new { error = e is Wso2Exception ? e.Message : $"Cannot reach WSO2 Identity Server: {e.Message}" });
            }
        }
        await tx.CommitAsync(ct);

        log.LogInformation("Employee {Code} ({EmployeeId}) created, portal access {Portal}: user {Username} ({UserId}), roles {Roles}, WSO2 {Wso2Tenant} {Wso2UserId}",
            code, employee.EmployeeId, portalAccess, portalAccess ? user?.Username : "-", user?.UserId, string.Join(",", roleCodes), tenant?.TenantDomain ?? "-", wso2UserId ?? "-");
        return Created($"/api/users/{employee.EmployeeId}", new
        {
            UserId = user?.UserId, Username = portalAccess ? user?.Username : null, employee.EmployeeId, employee.EmployeeCode, PortalAccess = portalAccess, roles = roleCodes,
            wso2 = tenant is null ? null : new { tenant = tenant.TenantDomain, userId = wso2UserId },
        });
    }

    private static string? Clean(string? s) => string.IsNullOrWhiteSpace(s) ? null : s.Trim();
}
