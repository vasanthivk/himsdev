using System.Net.Mail;
using Hims.Common.Data;
using Hims.Common.Http;
using Hims.IdentityOrg.Data;
using Hims.IdentityOrg.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.IdentityOrg.Controllers;

/// <summary>
/// Staff users. Creating one writes, in one transaction: the employee (hr.employee), the HIMS login (sec.user_account, username =
/// the username, with sec.user_role rows) and an EmployeeUpdated event that the other services copy into their ref.employee - and
/// creates the user in the organization's WSO2 Identity Server tenant (SCIM2). The transaction is committed only after WSO2
/// accepts the user, so a WSO2 failure leaves nothing behind in HIMS.
/// </summary>
[ApiController]
[Route("api")]
public class UsersController(IdentityOrgDbContext db, HimsAuthMode mode, Wso2UserManagementOptions wso2Options, Wso2UserManagement wso2,
    ILogger<UsersController> log) : ControllerBase
{
    /// <param name="Password">Initial password for WSO2 and the HIMS login; empty = Wso2UserManagement:DefaultPassword.</param>
    public record CreateUserRequest(int BranchId, string? Title, string FirstName, string LastName, string Gender, string Username,
        string? Mobile, int? DepartmentId, string? EmploymentType, string[]? Roles, string? Password);

    /// <summary>8-64 characters with an uppercase letter, a lowercase letter, a digit and a special character (WSO2 applies its own policy too).</summary>
    private static string? PasswordProblem(string password) =>
        password.Length is < 8 or > 64 ? "Password must be 8-64 characters long."
        : !password.Any(char.IsUpper) || !password.Any(char.IsLower) || !password.Any(char.IsDigit) || password.All(char.IsLetterOrDigit)
            ? "Password must contain an uppercase letter, a lowercase letter, a digit and a special character."
        : password.Any(char.IsWhiteSpace) ? "Password must not contain spaces."
        : null;

    /// <summary>Users with their employee details and roles.</summary>
    [HttpGet("users")]
    public async Task<IActionResult> List(CancellationToken ct)
    {
        var users = await (from u in db.UserAccounts
                           join e in db.Employees on u.EmployeeId equals e.EmployeeId into emp
                           from e in emp.DefaultIfEmpty()
                           orderby u.UserId
                           select new
                           {
                               u.UserId, u.Username, u.UserType, u.IsActive, u.IsLocked, u.LastLoginAt, u.CreatedAt,
                               EmployeeId = (long?)e.EmployeeId, EmployeeCode = e.EmployeeCode, FirstName = e.FirstName, LastName = e.LastName,
                               Email = e.Email, Mobile = e.Mobile, BranchId = (int?)e.BranchId, DepartmentId = e.DepartmentId,
                           }).ToListAsync(ct);
        var roles = await (from ur in db.UserRoles
                           join r in db.Roles on ur.RoleId equals r.RoleId
                           where ur.IsActive
                           select new { ur.UserId, r.RoleCode }).ToListAsync(ct);
        return Ok(users.Select(u => new
        {
            u.UserId, u.Username, u.UserType, u.IsActive, u.IsLocked, u.LastLoginAt, u.CreatedAt,
            u.EmployeeId, u.EmployeeCode, u.FirstName, u.LastName, u.Email, u.Mobile, u.BranchId, u.DepartmentId,
            Roles = roles.Where(r => r.UserId == u.UserId).Select(r => r.RoleCode).Distinct().ToList(),
        }));
    }

    /// <summary>Roles defined for the organization (sec.role).</summary>
    [HttpGet("roles")]
    public async Task<IActionResult> Roles(CancellationToken ct) =>
        Ok(await db.Roles.Where(r => r.IsActive).OrderBy(r => r.RoleCode).Select(r => new { r.RoleId, r.RoleCode, r.RoleName }).ToListAsync(ct));

    /// <summary>Creates a staff user in HIMS and in WSO2 Identity Server (see the class summary).</summary>
    [HttpPost("users")]
    public async Task<IActionResult> Create(CreateUserRequest req, CancellationToken ct)
    {
        // With HIMS's own login only ADMIN may create users; with WSO2 sign-in any signed-in user passing Auth:WriteRoles may.
        if (mode.Enabled && mode.HimsJwt && !User.IsInRole(AuthBootstrap.AdminRole))
            return StatusCode(StatusCodes.Status403Forbidden, new { error = "Only ADMIN users can create users." });

        var username = (req.Username ?? "").Trim();
        // When the username is an email address it is also the employee's email (and WSO2's emails attribute).
        string? email = MailAddress.TryCreate(username, out var mail) && mail.Address == username ? username.ToLowerInvariant() : null;
        var firstName = (req.FirstName ?? "").Trim();
        var lastName = (req.LastName ?? "").Trim();
        var gender = (req.Gender ?? "").Trim().ToLowerInvariant();
        if (firstName.Length == 0 || lastName.Length == 0) return BadRequest(new { error = "Name and surname are required." });
        if (username.Length is < 3 or > 100) return BadRequest(new { error = "Username must be 3-100 characters long." });
        if (username.Any(char.IsWhiteSpace)) return BadRequest(new { error = "Username must not contain spaces." });
        if (gender is not ("male" or "female" or "other")) return BadRequest(new { error = "Gender must be male, female or other." });
        var password = string.IsNullOrEmpty(req.Password) ? wso2Options.DefaultPassword : req.Password;
        if (!string.IsNullOrEmpty(req.Password) && PasswordProblem(req.Password) is { } problem) return BadRequest(new { error = problem });

        var branch = await db.Branches.FirstOrDefaultAsync(b => b.BranchId == req.BranchId, ct);
        if (branch is null) return BadRequest(new { error = $"Branch {req.BranchId} does not exist." });
        if (req.DepartmentId is { } dept && !await db.Departments.AnyAsync(d => d.DepartmentId == dept, ct))
            return BadRequest(new { error = $"Department {dept} does not exist." });
        var usernameLower = username.ToLowerInvariant();
        if (await db.UserAccounts.AnyAsync(u => u.Username.ToLower() == usernameLower, ct))
            return Conflict(new { error = $"A user with username {username} already exists." });
        if (email is not null && await db.Employees.AnyAsync(e => e.Email == email, ct))
            return Conflict(new { error = $"An employee with email {email} already exists." });

        Wso2Tenant? tenant = null;
        if (wso2Options.Enabled)
        {
            tenant = wso2Options.TenantFor(branch.OrganizationId);
            if (tenant is null) return BadRequest(new { error = $"WSO2 user management is not configured for organization {branch.OrganizationId} (Wso2UserManagement:Tenants)." });
            if (string.IsNullOrEmpty(password)) return BadRequest(new { error = "Enter a password (no default password is configured)." });
        }
        long? createdBy = long.TryParse(User.FindFirst(HimsClaims.Subject)?.Value, out var by) ? by : null;
        var roleCodes = (req.Roles ?? []).Select(r => r.Trim().ToUpperInvariant()).Where(r => r.Length > 0).Distinct().ToList();

        await using var tx = await db.Database.BeginTransactionAsync(ct);

        // Employee code E0001, E0002, ... - serialised with an advisory lock held until the transaction ends.
        await db.Database.ExecuteSqlRawAsync("SELECT pg_advisory_xact_lock(hashtext('hr.employee.employee_code'))", ct);
        var rows = await db.QueryAsync(@"SELECT COALESCE(MAX(CAST(SUBSTRING(employee_code FROM 2) AS BIGINT)), 0)
                                           FROM hr.employee WHERE employee_code ~ '^E[0-9]+$'", new Dictionary<string, object>(), ct);
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

        var user = new UserAccount
        {
            OrganizationId = branch.OrganizationId, UserType = "STAFF", Username = username, EmployeeId = employee.EmployeeId,
            PasswordHash = string.IsNullOrEmpty(password) ? null : PasswordHasher.Hash(password),
            MfaEnabled = false, PasswordChangedAt = DateTime.UtcNow, CreatedBy = createdBy,
        };
        db.UserAccounts.Add(user);
        await db.SaveChangesAsync(ct);
        foreach (var roleCode in roleCodes)
        {
            var role = await AuthBootstrap.EnsureRole(db, branch.OrganizationId, roleCode, ct);
            db.UserRoles.Add(new UserRole { UserId = user.UserId, RoleId = role.RoleId, CreatedBy = createdBy });
        }

        // Only the columns the other services keep in ref.employee - no personal identifiers in the event.
        db.EnqueueEvent("EmployeeUpdated", "hr.employee", employee.EmployeeId, new
        {
            employee.EmployeeId, employee.OrganizationId, employee.BranchId, employee.EmployeeCode, employee.FirstName, employee.LastName,
            employee.DepartmentId, employee.DesignationId, employee.EmployeeStatus,
        }, employee.OrganizationId, employee.BranchId);
        await db.SaveChangesAsync(ct);

        string? wso2UserId = null;
        if (tenant is not null)
        {
            try
            {
                wso2UserId = await wso2.CreateUserAsync(tenant,
                    new Wso2NewUser(username, email, password, firstName, lastName, employee.EmployeeId.ToString()), ct);
            }
            catch (Exception e) when (e is Wso2Exception or HttpRequestException or TaskCanceledException)
            {
                // Not committed: the employee, login, roles and event are all rolled back.
                var status = e is Wso2Exception { StatusCode: 409 } ? 409 : 502;
                return StatusCode(status, new { error = e is Wso2Exception ? e.Message : $"Cannot reach WSO2 Identity Server: {e.Message}" });
            }
        }
        await tx.CommitAsync(ct);

        log.LogInformation("User {Username} created: employee {EmployeeId} ({Code}), user {UserId}, roles {Roles}, WSO2 {Wso2Tenant} {Wso2UserId}",
            username, employee.EmployeeId, code, user.UserId, string.Join(",", roleCodes), tenant?.TenantDomain ?? "-", wso2UserId ?? "-");
        return Created($"/api/users/{user.UserId}", new
        {
            user.UserId, user.Username, employee.EmployeeId, employee.EmployeeCode, roles = roleCodes,
            wso2 = tenant is null ? null : new { tenant = tenant.TenantDomain, userId = wso2UserId },
        });
    }

    private static string? Clean(string? s) => string.IsNullOrWhiteSpace(s) ? null : s.Trim();
}
