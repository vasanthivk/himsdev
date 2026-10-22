using Hims.Common.Http;
using Hims.IdentityOrg.Data;
using Hims.IdentityOrg.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.IdentityOrg.Controllers;

/// <summary>
/// HIMS's own login (WSO2_AUTHENTICATION=false): users, roles and sessions live in sec.user_account, sec.role, sec.user_role and
/// sec.user_session; the access token is a HIMS JWT that every service validates. With WSO2_AUTHENTICATION=true these endpoints
/// answer 404 - users sign in through WSO2 Identity Server instead.
/// </summary>
[ApiController]
[Route("api/auth")]
public class AuthController(IdentityOrgDbContext db, HimsTokenIssuer issuer, HimsAuthMode mode, ILogger<AuthController> log) : ControllerBase
{
    private const int MaxFailedLogins = 5;
    private const int MinPasswordLength = 8;
    private const string InvalidCredentials = "Invalid username or password.";

    public record LoginRequest(string Username, string Password, int? BranchId);
    public record CreateUserRequest(string Username, string Password, string[] Roles, long? EmployeeId, string? UserType);

    private IActionResult HimsLoginOff() => NotFound(new { error = "HIMS login is off (WSO2_AUTHENTICATION=true) - sign in through WSO2 Identity Server." });

    /// <summary>Signs in with username and password. Returns a HIMS access token (Bearer) and the user's roles. 5 wrong passwords lock the account.</summary>
    [AllowAnonymous]
    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginRequest req, CancellationToken ct)
    {
        if (!mode.HimsJwt) return HimsLoginOff();
        if (string.IsNullOrWhiteSpace(req.Username) || string.IsNullOrEmpty(req.Password)) return BadRequest(new { error = "Username and password are required." });

        var username = req.Username.Trim();
        var user = await db.UserAccounts.FirstOrDefaultAsync(u => u.Username == username, ct);
        if (user is null || !user.IsActive || user.PasswordHash is null) return Unauthorized(new { error = InvalidCredentials });
        if (user.IsLocked) return Unauthorized(new { error = "This account is locked - contact an administrator." });

        var now = DateTime.UtcNow;
        if (!PasswordHasher.Verify(req.Password, user.PasswordHash))
        {
            user.FailedLoginCount++;
            if (user.FailedLoginCount >= MaxFailedLogins) user.IsLocked = true;
            user.UpdatedAt = now;
            await db.SaveChangesAsync(ct);
            log.LogWarning("Failed login for {Username} ({Count}/{Max}){Locked}", username, user.FailedLoginCount, MaxFailedLogins, user.IsLocked ? " - account locked" : "");
            return Unauthorized(new { error = user.IsLocked ? "Too many failed attempts - this account is now locked." : InvalidCredentials });
        }

        var roles = await RolesOf(user.UserId, ct);
        var name = await DisplayName(user, ct);
        var session = new UserSession
        {
            UserId = user.UserId, BranchId = req.BranchId, DeviceType = "web",
            ClientIp = HttpContext.Connection.RemoteIpAddress?.ToString(), LoginAt = now, LastActivityAt = now,
        };
        db.UserSessions.Add(session);
        user.FailedLoginCount = 0;
        user.LastLoginAt = now;
        await db.SaveChangesAsync(ct);

        var (token, expiresIn) = issuer.Issue(user.UserId, user.Username, name, user.OrganizationId, session.SessionId, roles);
        log.LogInformation("Login {Username} (user {UserId}, session {SessionId}, roles {Roles})", user.Username, user.UserId, session.SessionId, string.Join(",", roles));
        return Ok(new { accessToken = token, tokenType = "Bearer", expiresIn, user = new { user.UserId, user.Username, name, roles } });
    }

    /// <summary>Ends the caller's session (sec.user_session.logout_at). The token itself stays valid until it expires.</summary>
    [HttpPost("logout")]
    public async Task<IActionResult> Logout(CancellationToken ct)
    {
        if (!mode.HimsJwt) return HimsLoginOff();
        if (long.TryParse(User.FindFirst(HimsClaims.Session)?.Value, out var sessionId) && long.TryParse(User.FindFirst(HimsClaims.Subject)?.Value, out var userId))
        {
            var session = await db.UserSessions.FirstOrDefaultAsync(s => s.SessionId == sessionId && s.UserId == userId, ct);
            if (session is { LogoutAt: null })
            {
                session.LogoutAt = DateTime.UtcNow;
                session.LogoutReason = "user";
                await db.SaveChangesAsync(ct);
            }
        }
        return NoContent();
    }

    /// <summary>Creates a user with the given role codes (e.g. FRONT_OFFICE, BILLING, DOCTOR, LAB_TECH). Missing roles are created. ADMIN only.</summary>
    [HttpPost("users")]
    public async Task<IActionResult> CreateUser(CreateUserRequest req, CancellationToken ct)
    {
        if (!mode.HimsJwt) return HimsLoginOff();
        if (mode.Enabled && !User.IsInRole(AuthBootstrap.AdminRole)) return StatusCode(StatusCodes.Status403Forbidden, new { error = "Only ADMIN users can create users." });
        if (string.IsNullOrWhiteSpace(req.Username)) return BadRequest(new { error = "Username is required." });
        if ((req.Password ?? "").Length < MinPasswordLength) return BadRequest(new { error = $"Password must be at least {MinPasswordLength} characters." });

        var username = req.Username.Trim();
        if (await db.UserAccounts.AnyAsync(u => u.Username == username, ct)) return Conflict(new { error = $"User '{username}' already exists." });

        var organizationId = int.TryParse(User.FindFirst(HimsClaims.Organization)?.Value, out var org) ? org
            : await db.Organizations.OrderBy(o => o.OrganizationId).Select(o => o.OrganizationId).FirstAsync(ct);
        long? createdBy = long.TryParse(User.FindFirst(HimsClaims.Subject)?.Value, out var by) ? by : null;

        await using var tx = await db.Database.BeginTransactionAsync(ct);
        var user = new UserAccount
        {
            OrganizationId = organizationId, UserType = string.IsNullOrWhiteSpace(req.UserType) ? "STAFF" : req.UserType.Trim().ToUpperInvariant(),
            Username = username, EmployeeId = req.EmployeeId, PasswordHash = PasswordHasher.Hash(req.Password!),
            MfaEnabled = false, PasswordChangedAt = DateTime.UtcNow, CreatedBy = createdBy,
        };
        db.UserAccounts.Add(user);
        await db.SaveChangesAsync(ct);

        var roleCodes = (req.Roles ?? []).Select(r => r.Trim().ToUpperInvariant()).Where(r => r.Length > 0).Distinct().ToList();
        foreach (var code in roleCodes)
        {
            var role = await AuthBootstrap.EnsureRole(db, organizationId, code, ct);
            db.UserRoles.Add(new UserRole { UserId = user.UserId, RoleId = role.RoleId, CreatedBy = createdBy });
        }
        await db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);

        log.LogInformation("User {Username} (user {UserId}) created with roles {Roles}", username, user.UserId, string.Join(",", roleCodes));
        return Created($"/api/auth/users/{user.UserId}", new { user.UserId, user.Username, roles = roleCodes });
    }

    private async Task<List<string>> RolesOf(long userId, CancellationToken ct)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        return await (from ur in db.UserRoles
                      join r in db.Roles on ur.RoleId equals r.RoleId
                      where ur.UserId == userId && ur.IsActive && r.IsActive
                            && (ur.ValidFrom == null || ur.ValidFrom <= today) && (ur.ValidTo == null || ur.ValidTo >= today)
                      select r.RoleCode).Distinct().ToListAsync(ct);
    }

    private async Task<string> DisplayName(UserAccount user, CancellationToken ct)
    {
        if (user.EmployeeId is null) return user.Username;
        var e = await db.Employees.Where(x => x.EmployeeId == user.EmployeeId).Select(x => new { x.FirstName, x.LastName }).FirstOrDefaultAsync(ct);
        var name = e is null ? "" : $"{e.FirstName} {e.LastName}".Trim();
        return name.Length > 0 ? name : user.Username;
    }
}
