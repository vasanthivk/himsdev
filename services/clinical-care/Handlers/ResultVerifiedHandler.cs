using System.Text.Json;
using Hims.ClinicalCare.Data;
using Hims.Common.Events;
using Microsoft.EntityFrameworkCore;

namespace Hims.ClinicalCare.Handlers;

/// <summary>
/// Clinical Care subscribes to <c>ResultVerified</c> (Laboratory): the ordered items become VERIFIED so the doctor sees the
/// results are back, the order is COMPLETED once every item is done, and the result lines are kept in ref.lab_result_summary -
/// the doctor's screen reads results from there instead of calling Laboratory.
/// </summary>
public class ResultVerifiedHandler : IEventHandler
{
    private readonly ClinicalCareDbContext _db;
    public ResultVerifiedHandler(ClinicalCareDbContext db) => _db = db;

    public string EventType => "ResultVerified";

    public async Task HandleAsync(EventEnvelope envelope, CancellationToken ct)
    {
        var p = envelope.Data.Deserialize<ResultVerifiedPayload>(EventJson.Options) ?? throw new InvalidOperationException("Empty ResultVerified payload");
        var ids = p.OrderItemIds.ToList();
        var items = await _db.OrderItems.Where(i => ids.Contains(i.OrderItemId)).ToListAsync(ct);
        foreach (var i in items) { i.ItemStatus = "VERIFIED"; i.CompletedAt = envelope.Time; }
        await _db.SaveChangesAsync(ct);

        await StoreResultsAsync(p, items, envelope, ct);

        var order = await _db.ClinicalOrders.FirstOrDefaultAsync(o => o.OrderId == p.OrderId, ct);
        if (order is null) return;
        var open = await _db.OrderItems.CountAsync(i => i.OrderId == p.OrderId && i.ItemStatus != "VERIFIED" && i.ItemStatus != "REPORTED" && i.ItemStatus != "CANCELLED", ct);
        order.OrderStatus = open == 0 ? "COMPLETED" : "IN_PROGRESS";
        await _db.SaveChangesAsync(ct);
    }

    /// <summary>Upserts each result line (keyed by Laboratory's result id, so an amended result replaces the earlier one).</summary>
    private async Task StoreResultsAsync(ResultVerifiedPayload p, List<OrderItem> items, EventEnvelope envelope, CancellationToken ct)
    {
        if (p.Results.Count == 0) return;
        var serviceIds = items.Select(i => i.ServiceId).Distinct().ToList();
        var serviceNames = await _db.RefServices.Where(s => serviceIds.Contains(s.ServiceId)).ToDictionaryAsync(s => s.ServiceId, s => s.ServiceName, ct);
        var resultIds = p.Results.Select(r => r.ResultId).ToList();
        var existing = await _db.RefLabResultSummaries.Where(r => resultIds.Contains(r.ResultId)).ToDictionaryAsync(r => r.ResultId, ct);

        foreach (var r in p.Results)
        {
            if (!existing.TryGetValue(r.ResultId, out var row))
            {
                row = new RefLabResultSummary { ResultId = r.ResultId };
                _db.RefLabResultSummaries.Add(row);
            }
            var serviceId = items.FirstOrDefault(i => i.OrderItemId == r.OrderItemId)?.ServiceId;
            row.OrderItemId = r.OrderItemId;
            row.PatientId = p.PatientId;
            row.EncounterId = p.EncounterId;
            row.TestName = serviceId is { } sid && serviceNames.TryGetValue(sid, out var name) ? name : null;
            row.ParameterName = r.ParameterName;
            row.ValueNumeric = r.ValueNumeric;
            row.ValueText = r.ValueText;
            row.Unit = r.Unit;
            row.ReferenceRangeText = r.ReferenceRangeText;
            row.AbnormalFlag = r.AbnormalFlag;
            row.IsCritical = r.IsCritical;
            row.VerifiedAt = envelope.Time;
            row.SourceVersion = envelope.SourceVersion;
            row.ReplicatedAt = DateTime.UtcNow;
        }
        await _db.SaveChangesAsync(ct);
    }
}
