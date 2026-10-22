using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;

namespace Hims.Common.Http;

/// <summary>
/// Config section "Jwt": HIMS's own access tokens, used when WSO2_AUTHENTICATION=false. Identity &amp; Org issues them
/// (POST /api/auth/login); every service validates them from the Authorization: Bearer header with the same settings.
/// </summary>
public sealed class HimsJwtOptions
{
    public string Issuer { get; set; } = "hims";
    public string Audience { get; set; } = "hims-api";
    /// <summary>HMAC-SHA256 key shared by all services (at least 32 characters). Keep it out of source control in production.</summary>
    public string SigningKey { get; set; } = string.Empty;
    public int AccessTokenMinutes { get; set; } = 480;

    public SymmetricSecurityKey Key()
    {
        if (Encoding.UTF8.GetByteCount(SigningKey) < 32)
            throw new InvalidOperationException("Jwt:SigningKey must be at least 32 characters when WSO2_AUTHENTICATION=false.");
        return new SymmetricSecurityKey(Encoding.UTF8.GetBytes(SigningKey));
    }
}

/// <summary>Claim names in HIMS tokens.</summary>
public static class HimsClaims
{
    public const string Subject = "sub";            // user_id
    public const string Name = "name";              // display name
    public const string Username = "preferred_username";
    public const string Role = "role";              // one claim per role_code
    public const string Organization = "org";       // organization_id
    public const string Session = "sid";            // sec.user_session.session_id
}

/// <summary>Issues HIMS access tokens (used by Identity &amp; Org's login endpoint).</summary>
public sealed class HimsTokenIssuer(HimsJwtOptions options)
{
    public (string Token, int ExpiresIn) Issue(long userId, string username, string name, int organizationId, long sessionId, IEnumerable<string> roles)
    {
        var claims = new List<Claim>
        {
            new(HimsClaims.Subject, userId.ToString()),
            new(HimsClaims.Username, username),
            new(HimsClaims.Name, name),
            new(HimsClaims.Organization, organizationId.ToString()),
            new(HimsClaims.Session, sessionId.ToString()),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString("N")),
        };
        claims.AddRange(roles.Select(r => new Claim(HimsClaims.Role, r)));

        var lifetime = TimeSpan.FromMinutes(options.AccessTokenMinutes);
        var token = new JwtSecurityToken(options.Issuer, options.Audience, claims, DateTime.UtcNow, DateTime.UtcNow.Add(lifetime),
            new SigningCredentials(options.Key(), SecurityAlgorithms.HmacSha256));
        return (new JwtSecurityTokenHandler().WriteToken(token), (int)lifetime.TotalSeconds);
    }
}
