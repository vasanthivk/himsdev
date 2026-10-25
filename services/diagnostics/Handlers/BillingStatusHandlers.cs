using System.Text.Json;
using Hims.Common.Events;
using Hims.Diagnostics.Data;
using Microsoft.EntityFrameworkCore;

namespace Hims.Diagnostics.Handlers;

/// <summary>
/// Keeps the billing status of each ordered lab item in ref.order_item (bill_no, bill_status, is_paid), so the worklist can tell
/// whether a sample may be collected without calling Revenue Cycle: ChargePosted = the item is billed, PaymentReceived = paid.
/// "Billed" is bill_no being set (is_billed is also written by OrderPlaced, which arrives on its own schedule).
/// A bill event that arrives before OrderPlaced creates the row; OrderPlaced then fills in the order columns and leaves these.
/// </summary>
internal static class BillingStatus
{
    public static async Task ApplyAsync(DiagnosticsDbContext db, IEnumerable<long> orderItemIds, string billNo, string billStatus, CancellationToken ct)
    {
        var ids = orderItemIds.Distinct().ToList();
        if (ids.Count == 0) return;
        var items = await db.RefOrderItems.Where(i => ids.Contains(i.OrderItemId)).ToDictionaryAsync(i => i.OrderItemId, ct);
        foreach (var id in ids)
        {
            if (!items.TryGetValue(id, out var item))
            {
                item = new RefOrderItem { OrderItemId = id };
                db.RefOrderItems.Add(item);
            }
            item.BillNo = billNo;
            item.BillStatus = billStatus;
            item.IsPaid = billStatus == "SETTLED";
            item.ReplicatedAt = DateTime.UtcNow;
        }
        await db.SaveChangesAsync(ct);
    }
}

/// <summary>ChargePosted (Revenue Cycle): a bill was raised for these order items.</summary>
public class ChargePostedLabHandler : IEventHandler
{
    private readonly DiagnosticsDbContext _db;
    public ChargePostedLabHandler(DiagnosticsDbContext db) => _db = db;

    public string EventType => "ChargePosted";

    public async Task HandleAsync(EventEnvelope envelope, CancellationToken ct)
    {
        var bill = envelope.Data.Deserialize<BillPayload>(EventJson.Options) ?? throw new InvalidOperationException("Empty ChargePosted payload");
        var ids = bill.Lines.Where(l => l.OrderItemId != null).Select(l => l.OrderItemId!.Value);
        await BillingStatus.ApplyAsync(_db, ids, bill.BillNo, bill.BillStatus, ct);
    }
}

/// <summary>PaymentReceived (Revenue Cycle): a payment was taken on the bill; is_paid becomes true once it is SETTLED.</summary>
public class PaymentReceivedLabHandler : IEventHandler
{
    private readonly DiagnosticsDbContext _db;
    public PaymentReceivedLabHandler(DiagnosticsDbContext db) => _db = db;

    public string EventType => "PaymentReceived";

    public async Task HandleAsync(EventEnvelope envelope, CancellationToken ct)
    {
        var p = envelope.Data.Deserialize<PaymentReceivedPayload>(EventJson.Options) ?? throw new InvalidOperationException("Empty PaymentReceived payload");
        await BillingStatus.ApplyAsync(_db, p.OrderItemIds, p.BillNo, p.BillStatus, ct);
    }
}
