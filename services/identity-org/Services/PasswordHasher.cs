using System.Security.Cryptography;

namespace Hims.IdentityOrg.Services;

/// <summary>
/// Password hashes for sec.user_account.password_hash: PBKDF2-HMAC-SHA256 with a random 16-byte salt per password.
/// Stored as "pbkdf2-sha256$&lt;iterations&gt;$&lt;salt base64&gt;$&lt;hash base64&gt;", so the iteration count can be raised later
/// without breaking existing hashes.
/// </summary>
/// <summary>Password rule for HIMS users (WSO2 applies its own tenant policy as well).</summary>
public static class PasswordPolicy
{
    /// <summary>Null when acceptable, otherwise what is wrong: 8-64 characters, upper and lower case, a digit, a special character, no spaces.</summary>
    public static string? Problem(string password) =>
        password.Length is < 8 or > 64 ? "Password must be 8-64 characters long."
        : !password.Any(char.IsUpper) || !password.Any(char.IsLower) || !password.Any(char.IsDigit) || password.All(char.IsLetterOrDigit)
            ? "Password must contain an uppercase letter, a lowercase letter, a digit and a special character."
        : password.Any(char.IsWhiteSpace) ? "Password must not contain spaces."
        : null;
}

public static class PasswordHasher
{
    private const string Scheme = "pbkdf2-sha256";
    private const int Iterations = 210_000;
    private const int SaltBytes = 16, HashBytes = 32;

    public static string Hash(string password)
    {
        var salt = RandomNumberGenerator.GetBytes(SaltBytes);
        var hash = Rfc2898DeriveBytes.Pbkdf2(password, salt, Iterations, HashAlgorithmName.SHA256, HashBytes);
        return $"{Scheme}${Iterations}${Convert.ToBase64String(salt)}${Convert.ToBase64String(hash)}";
    }

    public static bool Verify(string password, string stored)
    {
        var parts = stored.Split('$');
        if (parts.Length != 4 || parts[0] != Scheme || !int.TryParse(parts[1], out var iterations)) return false;
        try
        {
            var salt = Convert.FromBase64String(parts[2]);
            var expected = Convert.FromBase64String(parts[3]);
            var actual = Rfc2898DeriveBytes.Pbkdf2(password, salt, iterations, HashAlgorithmName.SHA256, expected.Length);
            return CryptographicOperations.FixedTimeEquals(actual, expected);
        }
        catch (FormatException) { return false; }
    }
}
