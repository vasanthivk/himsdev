using System.Text.Json;
using Hims.ClinicalCare.Data;
using Hims.Common.Events;
using Microsoft.EntityFrameworkCore;

namespace Hims.ClinicalCare.Handlers;

/// <summary>
/// Clinical Care subscribes to <c>ResultVerified</c> (Laboratory): the ordered items become VERIFIED so the doctor sees the
/// results are back, and the order is COMPLETED once every item is done.
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

        var order = await _db.ClinicalOrders.FirstOrDefaultAsync(o => o.OrderId == p.OrderId, ct);
        if (order is null) return;
        var open = await _db.OrderItems.CountAsync(i => i.OrderId == p.OrderId && i.ItemStatus != "VERIFIED" && i.ItemStatus != "REPORTED" && i.ItemStatus != "CANCELLED", ct);
        order.OrderStatus = open == 0 ? "COMPLETED" : "IN_PROGRESS";
        await _db.SaveChangesAsync(ct);
    }
}
