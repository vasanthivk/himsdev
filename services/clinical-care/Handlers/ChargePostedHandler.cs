using System.Text.Json;
using Hims.ClinicalCare.Data;
using Hims.Common.Events;
using Microsoft.EntityFrameworkCore;

namespace Hims.ClinicalCare.Handlers;

/// <summary>
/// Revenue Cycle publishes <c>ChargePosted</c> when it bills ordered items. Clinical Care marks those order items
/// <c>is_billed = true</c>, so the doctor sees billing has happened. (Extension beyond the data-model README, which does not list
/// this subscription; it needs no schema change because ord.order_item.is_billed already exists.)
/// </summary>
public class ChargePostedHandler : IEventHandler
{
    private readonly ClinicalCareDbContext _db;
    public ChargePostedHandler(ClinicalCareDbContext db) => _db = db;

    public string EventType => "ChargePosted";

    public async Task HandleAsync(EventEnvelope envelope, CancellationToken ct)
    {
        var bill = envelope.Data.Deserialize<BillPayload>(EventJson.Options) ?? throw new InvalidOperationException("Empty ChargePosted payload");
        var ids = bill.Lines.Where(l => l.OrderItemId != null).Select(l => l.OrderItemId!.Value).ToList();
        if (ids.Count == 0) return;
        var items = await _db.OrderItems.Where(i => ids.Contains(i.OrderItemId)).ToListAsync(ct);
        foreach (var i in items) i.IsBilled = true;
        await _db.SaveChangesAsync(ct);
    }
}
