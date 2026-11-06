using System.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;

namespace Hims.Common.Data;

/// <summary>Small helper for the few statements EF cannot express (UPDATE ... RETURNING). Joins the current EF transaction.</summary>
public static class RawSql
{
    public static async Task<List<object?[]>> QueryAsync(this DbContext db, string sql, IReadOnlyDictionary<string, object> args, CancellationToken ct = default)
    {
        var conn = db.Database.GetDbConnection();
        if (conn.State != ConnectionState.Open) await conn.OpenAsync(ct);
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = sql;
        cmd.Transaction = db.Database.CurrentTransaction?.GetDbTransaction();
        foreach (var kv in args)
        {
            var p = cmd.CreateParameter();
            p.ParameterName = kv.Key;
            p.Value = kv.Value;
            cmd.Parameters.Add(p);
        }
        var rows = new List<object?[]>();
        await using var reader = await cmd.ExecuteReaderAsync(ct);
        while (await reader.ReadAsync(ct))
        {
            var row = new object?[reader.FieldCount];
            for (var i = 0; i < row.Length; i++) row[i] = reader.IsDBNull(i) ? null : reader.GetValue(i);
            rows.Add(row);
        }
        return rows;
    }
}
