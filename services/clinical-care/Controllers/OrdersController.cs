using System.ComponentModel.DataAnnotations;
using Hims.ClinicalCare.Data;
using Hims.Common.Data;
using Hims.Common.Events;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.ClinicalCare.Controllers;

public class PlaceOrderItem
{
    [Required] public int ServiceId { get; set; }
    public decimal Quantity { get; set; } = 1;
    public string? Instructions { get; set; }
}

public class PlaceOrderRequest
{
    [Required] public long EncounterId { get; set; }
    public long? OrderingPractitionerId { get; set; }
    /// <summary>ROUTINE, URGENT, STAT</summary>
    public string Priority { get; set; } = "ROUTINE";
    public string? ClinicalIndication { get; set; }
    [Required, MinLength(1)] public List<PlaceOrderItem> Items { get; set; } = new();
}

/// <summary>CPOE orders (ord.clinical_order / ord.order_item), e.g. lab tests.</summary>
[ApiController]
[Route("api/orders")]
public class OrdersController : ControllerBase
{
    private readonly ClinicalCareDbContext _db;
    private readonly ISequenceService _seq;
    public OrdersController(ClinicalCareDbContext db, ISequenceService seq) { _db = db; _seq = seq; }

    /// <summary>
    /// Places orders for the encounter. Items are grouped by category (LAB, RADIOLOGY, PROCEDURE) into one order each, and an
    /// <c>OrderPlaced</c> event is written to the outbox per order: Revenue Cycle raises the bill from it and Laboratory adds the
    /// tests to its worklist.
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> Place([FromBody] PlaceOrderRequest req, CancellationToken ct)
    {
        var enc = await _db.RefEncounters.FirstOrDefaultAsync(e => e.EncounterId == req.EncounterId, ct);
        if (enc?.PatientId is null || enc.OrganizationId is null || enc.BranchId is null)
            return Conflict(new { error = $"Encounter {req.EncounterId} has not replicated into Clinical Care yet; retry in a moment." });
        if (enc.EncounterStatus == "COMPLETED") return BadRequest(new { error = "The encounter is already closed" });

        var ids = req.Items.Select(i => i.ServiceId).Distinct().ToList();
        var services = await _db.RefServices.Where(s => ids.Contains(s.ServiceId)).ToListAsync(ct);
        foreach (var item in req.Items)
        {
            var s = services.FirstOrDefault(x => x.ServiceId == item.ServiceId);
            if (s is null) return BadRequest(new { error = $"Service {item.ServiceId} is unknown (load reference data: POST revenue-finance /api/admin/republish)" });
            if (s.IsOrderable != true) return BadRequest(new { error = $"Service {s.ServiceCode} cannot be ordered" });
            if (Category(s.ServiceType) is null) return BadRequest(new { error = $"Service {s.ServiceCode} ({s.ServiceType}) is not orderable through CPOE" });
        }

        var placed = new List<object>();
        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        foreach (var group in req.Items.GroupBy(i => Category(services.First(s => s.ServiceId == i.ServiceId).ServiceType)!))
        {
            var order = new ClinicalOrder
            {
                OrganizationId = enc.OrganizationId.Value, BranchId = enc.BranchId.Value,
                OrderNo = await _seq.NextAsync(_db, enc.OrganizationId.Value, enc.BranchId.Value, "ORDER", "ORD", ct),
                PatientId = enc.PatientId.Value, EncounterId = req.EncounterId, OrderCategory = group.Key, OrderSource = "CPOE",
                OrderingPractitionerId = req.OrderingPractitionerId ?? enc.AttendingPractitionerId, Priority = req.Priority,
                ClinicalIndication = req.ClinicalIndication, OrderedAt = DateTime.UtcNow, OrderStatus = "ORDERED",
            };
            _db.ClinicalOrders.Add(order);
            await _db.SaveChangesAsync(ct);

            var items = group.Select(i => new OrderItem
            {
                OrderId = order.OrderId, ServiceId = i.ServiceId, PerformingBranchId = order.BranchId, Quantity = i.Quantity,
                Instructions = i.Instructions, ItemStatus = "ORDERED", IsBilled = false,
            }).ToList();
            foreach (var it in items) _db.OrderItems.Add(it);
            await _db.SaveChangesAsync(ct);

            var payload = new OrderPlacedPayload(order.OrderId, order.OrganizationId, order.BranchId, order.OrderNo, order.PatientId, order.EncounterId,
                order.OrderCategory, order.Priority, order.OrderingPractitionerId, order.DiagnosisId, order.B2bPayerId, order.OrderStatus, order.OrderedAt,
                items.Select(it =>
                {
                    var s = services.First(x => x.ServiceId == it.ServiceId);
                    return new OrderItemPayload(it.OrderItemId, it.OrderId, it.ServiceId, s.ServiceCode, s.ServiceName, it.Quantity, it.ItemStatus,
                        it.IsBilled, it.PerformingBranchId, it.PerformingDepartmentId, it.Instructions);
                }).ToList());
            _db.EnqueueEvent("OrderPlaced", "ord.clinical_order", order.OrderId, payload, order.OrganizationId, order.BranchId, order.PatientId);
            await _db.SaveChangesAsync(ct);
            placed.Add(new { order.OrderId, order.OrderNo, order.OrderCategory, itemIds = items.Select(i => i.OrderItemId) });
        }
        await tx.CommitAsync(ct);
        return Created($"/api/orders?encounterId={req.EncounterId}", placed);
    }

    /// <summary>Orders with items (service names from ref.service) and their status.</summary>
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] long? patientId, [FromQuery] long? encounterId, CancellationToken ct)
    {
        var q = _db.ClinicalOrders.AsQueryable();
        if (patientId is not null) q = q.Where(o => o.PatientId == patientId);
        if (encounterId is not null) q = q.Where(o => o.EncounterId == encounterId);
        var orders = await q.OrderByDescending(o => o.OrderId).Take(30).ToListAsync(ct);
        var oids = orders.Select(o => o.OrderId).ToList();
        var items = await _db.OrderItems.Where(i => oids.Contains(i.OrderId)).ToListAsync(ct);
        var sids = items.Select(i => i.ServiceId).Distinct().ToList();
        var services = await _db.RefServices.Where(s => sids.Contains(s.ServiceId)).ToListAsync(ct);
        return Ok(orders.Select(o => new
        {
            o.OrderId, o.OrderNo, o.OrderCategory, o.Priority, o.OrderedAt, o.OrderStatus,
            items = items.Where(i => i.OrderId == o.OrderId).Select(i => new
            {
                i.OrderItemId, i.ServiceId, ServiceName = services.FirstOrDefault(s => s.ServiceId == i.ServiceId)?.ServiceName, i.ItemStatus, i.IsBilled, i.CompletedAt,
            }),
        }));
    }

    private static string? Category(string? serviceType) => serviceType switch
    {
        "LAB_TEST" => "LAB", "RAD_PROCEDURE" => "RADIOLOGY", "PROCEDURE" => "PROCEDURE", _ => null,
    };
}
