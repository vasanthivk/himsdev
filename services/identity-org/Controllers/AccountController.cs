using Hims.Common.Http;
using Hims.IdentityOrg.Data;
using Hims.IdentityOrg.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.IdentityOrg.Controllers;

/// <summary>
/// The signed-in user's own account, in both sign-in modes. The caller is identified from the token: with HIMS's own login the
/// HIMS JWT's preferred_username; with WSO2 sign-in the WSO2 username carried in the API Manager gateway's backend JWT.
/// </summary>
[ApiController]
[Route("api/account")]
public class AccountController(IdentityOrgDbContext db, HimsAuthMode mode, Wso2UserManagementOptions wso2Options, Wso2UserManagement wso2,
    ILogger<AccountController> log) : ControllerBase
{
    public record ChangePasswordRequest(string NewPassword);

    // WSO2 claims that can carry the username, in order of preference (the enduser claim is "username@tenant").
    private static readonly string[] Wso2UsernameClaims = ["http://wso2.org/claims/username", "username", "preferred_username", "http://wso2.org/claims/enduser"];

    /// <summary>Who the caller is (as HIMS sees the token), whether a HIMS account exists, and the token's claims.</summary>
    [HttpGet("me")]
    public async Task<IActionResult> Me(CancellationToken ct)
    {
        var (username, tenantDomain) = Caller();
        var account = username is null ? null : await FindAccount(username, ct);
        return Ok(new
        {
            username, tenantDomain, mode = mode.HimsJwt ? "HIMS" : "WSO2",
            himsUserId = account?.UserId,
            claims = User.Claims.GroupBy(c => c.Type).ToDictionary(g => g.Key, g => g.Count() == 1 ? (object)g.First().Value : g.Select(c => c.Value).ToList()),
        });
    }

    /// <summary>
    /// Changes the caller's password in WSO2 Identity Server (the tenant of the frontend's subdomain) and in HIMS (sec.user_account).
    /// The account signed in with is always changed; the other system's account only when linked (sec.user_account.wso2_user_id).
    /// WSO2 is changed first; if it refuses (e.g. its password policy), HIMS is left unchanged.
    /// </summary>
    [HttpPost("password")]
    public async Task<IActionResult> ChangePassword(ChangePasswordRequest req, CancellationToken ct)
    {
        var password = req.NewPassword ?? "";
        if (password.Length == 0) return BadRequest(new { error = "Enter the new password." });
        if (PasswordPolicy.Problem(password) is { } problem) return BadRequest(new { error = problem });

        var (username, _) = Caller();
        if (username is null) return BadRequest(new { error = "Cannot tell from your sign-in who you are, so the password was not changed." });

        var account = await FindAccount(username, ct);
        // The WSO2 tenant of the frontend's subdomain (checked against the tenant signed in to); none = only HIMS is changed.
        var (tenant, tenantError) = Wso2TenantResolver.Resolve(wso2Options, Request, User);
        if (tenant is null && wso2Options.Enabled)
        {
            if (!mode.HimsJwt) return BadRequest(new { error = tenantError + " The password was not changed." });   // signed in with WSO2
            log.LogInformation("Password change by {Username}: no WSO2 tenant ({Reason})", username, tenantError);
        }

        // The account the caller signed in with is always changed. The account in the other system is changed only when it is the
        // same person: the HIMS account's wso2_user_id is that WSO2 user's id (stored by POST /api/users when it created the user).
        // A shared name alone (e.g. HIMS "admin" and the WSO2 tenant administrator "admin") is not enough.
        var signedInWithWso2 = !mode.HimsJwt;
        Wso2User? wso2User = null;
        string wso2Result = "WSO2 user management is off";
        try
        {
            if (wso2Options.Enabled && tenant is not null)
            {
                wso2User = await wso2.FindUserAsync(tenant, username, ct);
                if (signedInWithWso2 && wso2User is not null && wso2User.Id != User.FindFirst("sub")?.Value) wso2User = null;   // not the caller
                var linked = account?.Wso2UserId is not null && account.Wso2UserId == wso2User?.Id;
                if (wso2User is null) wso2Result = $"no WSO2 user {username} in {tenant.TenantDomain}";
                else if (!signedInWithWso2 && !linked) { wso2Result = $"WSO2 user {username} is a different account (not linked to this HIMS account), left unchanged"; wso2User = null; }
                else
                {
                    await wso2.SetPasswordAsync(tenant, wso2User.Id, password, ct);
                    wso2Result = $"changed in WSO2 ({tenant.TenantDomain})";
                }
            }
        }
        catch (Exception e) when (e is Wso2Exception or HttpRequestException or TaskCanceledException)
        {
            return StatusCode(e is Wso2Exception { StatusCode: 400 } ? 400 : 502,
                new { error = e is Wso2Exception ? e.Message : $"Cannot reach WSO2 Identity Server: {e.Message}. The password was not changed." });
        }

        // With WSO2 sign-in, the HIMS account is changed only when it is linked to the caller's WSO2 user.
        if (signedInWithWso2 && account is not null && (wso2User is null || account.Wso2UserId != wso2User.Id))
        {
            log.LogInformation("Password change by WSO2 user {Username}: HIMS account {Username} is not linked to that WSO2 user, left unchanged", username, username);
            account = null;
        }

        string himsResult = "no linked HIMS account";
        if (account is not null)
        {
            account.PasswordHash = PasswordHasher.Hash(password);
            account.PasswordChangedAt = DateTime.UtcNow;
            account.FailedLoginCount = 0;
            account.IsLocked = false;
            account.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync(ct);
            himsResult = "changed in HIMS";
        }

        if (account is null && !wso2Result.StartsWith("changed"))
            return NotFound(new { error = $"No account found for {username} in HIMS or WSO2, so no password was changed." });

        log.LogInformation("Password changed for {Username}: {Hims}; {Wso2}", username, himsResult, wso2Result);
        return Ok(new { username, hims = himsResult, wso2 = wso2Result });
    }

    /// <summary>The caller's username and (WSO2 sign-in) tenant domain, from the validated token.</summary>
    private (string? Username, string? TenantDomain) Caller()
    {
        if (mode.HimsJwt) return (User.FindFirst(HimsClaims.Username)?.Value, null);
        var orgHandle = User.FindFirst("org_handle")?.Value;   // the WSO2 tenant domain the user signed in to
        foreach (var type in Wso2UsernameClaims)
        {
            var value = User.FindFirst(type)?.Value;
            if (string.IsNullOrWhiteSpace(value)) continue;
            var (name, tenant) = SplitWso2Username(value);
            return (name, orgHandle ?? tenant);
        }
        return (null, orgHandle);
    }

    /// <summary>"DEFAULT/john@newmeksolutions.com" -> ("john", "newmeksolutions.com"): drops the user-store prefix and a known tenant suffix.</summary>
    private (string, string?) SplitWso2Username(string value)
    {
        var name = value[(value.IndexOf('/') + 1)..];
        foreach (var domain in wso2Options.Tenants.Select(t => t.TenantDomain).Append("carbon.super"))
            if (name.EndsWith("@" + domain, StringComparison.OrdinalIgnoreCase)) return (name[..^(domain.Length + 1)], domain);
        return (name, null);
    }

    private Task<UserAccount?> FindAccount(string username, CancellationToken ct)
    {
        var lower = username.ToLowerInvariant();
        return db.UserAccounts.FirstOrDefaultAsync(u => u.Username.ToLower() == lower, ct);
    }
}
