using System.ComponentModel.DataAnnotations;
using Hims.Common.Data;
using Hims.Common.Events;
using Hims.Diagnostics.Data;
using Hims.Diagnostics.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.Diagnostics.Controllers;

public class CollectSampleRequest
{
    [Required] public long OrderId { get; set; }
    /// <summary>Order items to collect for (from GET /api/worklist/pending).</summary>
    [Required, MinLength(1)] public List<long> OrderItemIds { get; set; } = new();
    /// <summary>CENTRE, WARD, HOME, CAMP, B2B</summary>
    public string CollectionLocation { get; set; } = "CENTRE";
    public long? CollectedBy { get; set; }
}

/// <summary>Samples and barcodes (lab.sample, lab.sample_order_item).</summary>
[ApiController]
[Route("api/samples")]
public class SamplesController : ControllerBase
{
    private readonly DiagnosticsDbContext _db;
    private readonly ISequenceService _seq;
    private readonly ResultService _results;
    public SamplesController(DiagnosticsDbContext db, ISequenceService seq, ResultService results) { _db = db; _seq = seq; _results = results; }

    /// <summary>
    /// Collects samples for the chosen tests. Tests are grouped by specimen and container (one tube = one barcode), so an
    /// order for CBC (EDTA) and Fasting Sugar (fluoride) yields two barcoded samples. Publishes SampleCollected for each.
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> Collect([FromBody] CollectSampleRequest req, CancellationToken ct)
    {
        var order = await _db.RefClinicalOrders.FirstOrDefaultAsync(o => o.OrderId == req.OrderId, ct);
        if (order?.PatientId is null || order.OrganizationId is null || order.BranchId is null)
            return NotFound(new { error = $"Order {req.OrderId} is not on the lab worklist" });

        var items = await _db.RefOrderItems.Where(i => req.OrderItemIds.Contains(i.OrderItemId) && i.OrderId == req.OrderId).ToListAsync(ct);
        if (items.Count != req.OrderItemIds.Distinct().Count()) return BadRequest(new { error = "Some order items do not belong to this order" });
        if (await _db.SampleOrderItems.AnyAsync(s => req.OrderItemIds.Contains(s.OrderItemId), ct))
            return Conflict(new { error = "A sample has already been collected for one of these tests" });

        var sids = items.Where(i => i.ServiceId != null).Select(i => i.ServiceId!.Value).ToList();
        var tests = await _db.LabTests.Where(t => sids.Contains(t.ServiceId)).ToListAsync(ct);
        foreach (var i in items)
            if (tests.All(t => t.ServiceId != i.ServiceId)) return BadRequest(new { error = $"Service {i.ServiceId} is not in the lab test catalogue" });
        var refServices = await _db.RefServices.Where(x => sids.Contains(x.ServiceId)).ToListAsync(ct);

        var now = DateTime.UtcNow;
        var created = new List<object>();
        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        var groups = items.GroupBy(i => { var t = tests.First(x => x.ServiceId == i.ServiceId); return (t.SpecimenType, t.ContainerType); });
        foreach (var g in groups)
        {
            var sample = new Sample
            {
                OrganizationId = order.OrganizationId.Value, BranchId = order.BranchId.Value,
                SampleBarcode = await _seq.NextAsync(_db, order.OrganizationId.Value, order.BranchId.Value, "SAMPLE", "SMP", ct),
                PatientId = order.PatientId.Value, OrderId = order.OrderId, SpecimenType = g.Key.SpecimenType, ContainerType = g.Key.ContainerType,
                CollectionLocation = req.CollectionLocation, CollectedAt = now, CollectedBy = req.CollectedBy, ReceivedAt = now, SampleStatus = "RECEIVED",
            };
            _db.Samples.Add(sample);
            await _db.SaveChangesAsync(ct);

            var ids = g.Select(i => i.OrderItemId).ToList();
            foreach (var id in ids) _db.SampleOrderItems.Add(new SampleOrderItem { SampleId = sample.SampleId, OrderItemId = id });
            _db.EnqueueEvent("SampleCollected", "lab.sample", sample.SampleId,
                new SampleCollectedPayload(sample.SampleId, sample.SampleBarcode, sample.OrderId, sample.PatientId, order.EncounterId, ids, now),
                sample.OrganizationId, sample.BranchId, sample.PatientId);
            await _db.SaveChangesAsync(ct);
            created.Add(new
            {
                sample.SampleId, sample.SampleBarcode, sample.SpecimenType, sample.ContainerType, orderItemIds = ids,
                serviceCodes = g.Select(i => refServices.FirstOrDefault(x => x.ServiceId == i.ServiceId)?.ServiceCode).ToList(),
            });
        }
        await tx.CommitAsync(ct);
        return Created($"/api/samples?orderId={req.OrderId}", created);
    }

    /// <summary>List samples (newest first) with the service codes of the tests on each tube. Filter by orderId, patientId or status.</summary>
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] long? orderId, [FromQuery] long? patientId, [FromQuery] string? status, CancellationToken ct)
    {
        var q = _db.Samples.AsQueryable();
        if (orderId is not null) q = q.Where(s => s.OrderId == orderId);
        if (patientId is not null) q = q.Where(s => s.PatientId == patientId);
        if (!string.IsNullOrEmpty(status)) q = q.Where(s => s.SampleStatus == status);
        var samples = await q.OrderByDescending(s => s.SampleId).Take(50).ToListAsync(ct);

        var sampleIds = samples.Select(s => s.SampleId).ToList();
        var links = await _db.SampleOrderItems.Where(x => sampleIds.Contains(x.SampleId)).ToListAsync(ct);
        var itemIds = links.Select(l => l.OrderItemId).ToList();
        var items = await _db.RefOrderItems.Where(i => itemIds.Contains(i.OrderItemId)).ToListAsync(ct);
        var serviceIds = items.Where(i => i.ServiceId != null).Select(i => i.ServiceId!.Value).Distinct().ToList();
        var services = await _db.RefServices.Where(s => serviceIds.Contains(s.ServiceId)).ToListAsync(ct);
        var patientIds = samples.Select(s => s.PatientId).Distinct().ToList();
        var patients = await _db.RefPatients.Where(p => patientIds.Contains(p.PatientId)).ToListAsync(ct);

        return Ok(samples.Select(s =>
        {
            var p = patients.FirstOrDefault(x => x.PatientId == s.PatientId);
            var codes = links.Where(l => l.SampleId == s.SampleId)
                .Select(l => items.FirstOrDefault(i => i.OrderItemId == l.OrderItemId)?.ServiceId)
                .Select(id => services.FirstOrDefault(x => x.ServiceId == id)?.ServiceCode)
                .Where(c => c != null).ToList();
            return new
            {
                s.SampleId, s.SampleBarcode, s.OrderId, s.PatientId, PatientName = p is null ? null : $"{p.FirstName} {p.LastName}".Trim(),
                s.SpecimenType, s.ContainerType, s.SampleStatus, s.CollectedAt, serviceCodes = codes,
            };
        }));
    }

    /// <summary>One sample by barcode (what the analyzer sends back).</summary>
    [HttpGet("barcode/{barcode}")]
    public async Task<IActionResult> ByBarcode(string barcode, CancellationToken ct)
    {
        var s = await _db.Samples.FirstOrDefaultAsync(x => x.SampleBarcode == barcode, ct);
        return s is null ? NotFound() : Ok(s);
    }

    /// <summary>
    /// Manual verification/release (only needed when Laboratory:AutoVerify is false): verifies the sample's entered results,
    /// publishes ResultVerified and, when the order is complete, LabReportReleased.
    /// </summary>
    [HttpPost("{id:long}/verify")]
    public async Task<IActionResult> Verify(long id, [FromQuery] long? verifiedBy, CancellationToken ct)
    {
        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        try { await _results.VerifyAndReleaseAsync(id, verifiedBy, ct); }
        catch (InvalidOperationException ex) { return BadRequest(new { error = ex.Message }); }
        await tx.CommitAsync(ct);
        return Ok(new { sampleId = id, verified = true });
    }
}
