using Hims.Laboratory.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.Laboratory.Controllers;

/// <summary>The lab's pending work, built from ref.clinical_order / ref.order_item (filled by the OrderPlaced event).</summary>
[ApiController]
[Route("api/worklist")]
public class WorklistController : ControllerBase
{
    private readonly LaboratoryDbContext _db;
    public WorklistController(LaboratoryDbContext db) => _db = db;

    /// <summary>Ordered tests with no sample yet, grouped by order, each with its billing status (isBilled, billNo, billStatus, isPaid).</summary>
    [HttpGet("pending")]
    public async Task<IActionResult> Pending(CancellationToken ct)
    {
        var rows = await (from i in _db.RefOrderItems
                          join o in _db.RefClinicalOrders on i.OrderId equals o.OrderId
                          where o.OrderCategory == "LAB" && o.OrderStatus != "CANCELLED" && i.ItemStatus != "CANCELLED"
                                && !_db.SampleOrderItems.Any(s => s.OrderItemId == i.OrderItemId)
                          orderby i.OrderItemId
                          select new { i.OrderItemId, i.OrderId, i.ServiceId, o.OrderNo, o.PatientId, o.EncounterId, o.BranchId, i.BillNo, i.BillStatus, i.IsPaid })
                         .Take(200).ToListAsync(ct);

        var pids = rows.Where(r => r.PatientId != null).Select(r => r.PatientId!.Value).Distinct().ToList();
        var sids = rows.Where(r => r.ServiceId != null).Select(r => r.ServiceId!.Value).Distinct().ToList();
        var patients = await _db.RefPatients.Where(p => pids.Contains(p.PatientId)).ToListAsync(ct);
        var services = await _db.RefServices.Where(s => sids.Contains(s.ServiceId)).ToListAsync(ct);
        var tests = await _db.LabTests.Where(t => sids.Contains(t.ServiceId)).ToListAsync(ct);

        var orders = rows.GroupBy(r => r.OrderId).Select(g =>
        {
            var first = g.First();
            var p = patients.FirstOrDefault(x => x.PatientId == first.PatientId);
            return new
            {
                OrderId = g.Key, first.OrderNo, first.EncounterId, first.PatientId,
                PatientName = p is null ? null : $"{p.FirstName} {p.LastName}".Trim(), Uhid = p?.Uhid,
                Items = g.Select(r => new
                {
                    r.OrderItemId, r.ServiceId,
                    ServiceName = services.FirstOrDefault(s => s.ServiceId == r.ServiceId)?.ServiceName,
                    SpecimenType = tests.FirstOrDefault(t => t.ServiceId == r.ServiceId)?.SpecimenType,
                    ContainerType = tests.FirstOrDefault(t => t.ServiceId == r.ServiceId)?.ContainerType,
                    // Billing status, kept from Revenue Cycle's ChargePosted / PaymentReceived events (no call to Revenue Cycle here).
                    IsBilled = r.BillNo != null, r.BillNo, r.BillStatus, IsPaid = r.IsPaid == true,
                }).ToList(),
            };
        }).ToList();
        return Ok(orders);
    }
}
