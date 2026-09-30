using Microsoft.EntityFrameworkCore;

namespace Hims.Common.Data;

public interface ISequenceService
{
    /// <summary>Reserves the next number of <c>core.number_sequence</c> (sequence_code, branch, fiscal year) and formats it
    /// as {prefix}{yy}{number:D6}, e.g. DR26000001 for UHID. Call inside the unit-of-work transaction.</summary>
    Task<string> NextAsync(DbContext db, int organizationId, int branchId, string sequenceCode, string defaultPrefix, CancellationToken ct = default);
}

/// <summary>
/// UHIDs, bill/receipt/order/sample numbers come from <c>core.number_sequence</c> (cloned into every service DB, as the data
/// model describes). The table has no unique constraint on (branch, code, fiscal year), so a transaction-scoped advisory lock
/// serialises the "update or create" and two callers can never get the same number. Runs in the caller's transaction, so a
/// rolled-back registration does not burn a number.
/// </summary>
public sealed class SequenceService : ISequenceService
{
    public async Task<string> NextAsync(DbContext db, int organizationId, int branchId, string sequenceCode, string defaultPrefix, CancellationToken ct = default)
    {
        await using var own = db.Database.CurrentTransaction is null ? await db.Database.BeginTransactionAsync(ct) : null;

        var fy = FiscalYear(DateTime.UtcNow);
        var lockKey = $"seq:{organizationId}:{branchId}:{sequenceCode}:{fy}";
        await db.Database.ExecuteSqlInterpolatedAsync($"SELECT pg_advisory_xact_lock(hashtext({lockKey}))", ct);

        var args = new Dictionary<string, object>
        {
            ["org"] = organizationId, ["branch"] = branchId, ["code"] = sequenceCode, ["fy"] = fy, ["prefix"] = defaultPrefix,
        };

        var rows = await db.QueryAsync(
            @"UPDATE core.number_sequence SET next_value = next_value + 1
               WHERE organization_id = @org AND COALESCE(branch_id, 0) = @branch AND sequence_code = @code AND fiscal_year = @fy AND is_active
           RETURNING prefix, pad_length, next_value - 1", args, ct);

        if (rows.Count == 0)
        {
            rows = await db.QueryAsync(
                @"INSERT INTO core.number_sequence (organization_id, branch_id, sequence_code, prefix, fiscal_year, next_value, pad_length)
                  VALUES (@org, NULLIF(@branch, 0), @code, @prefix, @fy, 2, 6)
               RETURNING prefix, pad_length, next_value - 1", args, ct);
        }

        var prefix = (string?)rows[0][0] ?? defaultPrefix;
        var pad = Convert.ToInt32(rows[0][1]);
        var number = Convert.ToInt64(rows[0][2]);
        if (own is not null) await own.CommitAsync(ct);
        return $"{prefix}{fy[2..4]}{number.ToString().PadLeft(pad, '0')}";
    }

    /// <summary>Indian financial year (April-March) as "2026-27"; the 2-digit start year is used in numbers.</summary>
    public static string FiscalYear(DateTime utcNow)
    {
        var ist = utcNow.AddHours(5.5);
        var start = ist.Month >= 4 ? ist.Year : ist.Year - 1;
        return $"{start}-{(start + 1) % 100:D2}";
    }
}
