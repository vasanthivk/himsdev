using System.Text.Json;
using Hims.Common.Events;
using Hims.RevenueCycle.Data;
using Hims.RevenueCycle.Services;
using Microsoft.EntityFrameworkCore;

namespace Hims.RevenueCycle.Handlers;

/// <summary>
/// Order-to-cash step 1: Revenue Cycle subscribes to <c>OrderPlaced</c> (data-model README) and captures the charges - it prices
/// each ordered service from the tariff and raises a bill for the patient to pay. Idempotent: an order item is billed only once.
/// </summary>
public class OrderPlacedBillingHandler : IEventHandler
{
    private readonly RevenueCycleDbContext _db;
    private readonly BillingService _billing;
    public OrderPlacedBillingHandler(RevenueCycleDbContext db, BillingService billing) { _db = db; _billing = billing; }

    public string EventType => "OrderPlaced";

    public async Task HandleAsync(EventEnvelope envelope, CancellationToken ct)
    {
        var order = envelope.Data.Deserialize<OrderPlacedPayload>(EventJson.Options)
            ?? throw new InvalidOperationException("OrderPlaced payload is empty");
        if (order.Items.Count == 0) return;

        var ids = order.Items.Select(i => i.OrderItemId).ToList();
        if (await _db.BillLines.AnyAsync(l => l.OrderItemId != null && ids.Contains(l.OrderItemId.Value), ct)) return;

        var billType = order.OrderCategory switch { "LAB" => "LAB", "RADIOLOGY" => "RADIOLOGY", _ => "MISC" };
        var lines = order.Items.Select(i => new BillLineRequest(i.ServiceId, null, i.Quantity, i.OrderItemId, order.OrderingPractitionerId)).ToList();
        await _billing.CreateBillAsync(new BillRequest(order.OrganizationId, order.BranchId, order.PatientId, order.EncounterId, billType, lines), ct);
    }
}
