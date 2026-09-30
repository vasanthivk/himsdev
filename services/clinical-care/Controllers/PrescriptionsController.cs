using System.ComponentModel.DataAnnotations;
using Hims.ClinicalCare.Data;
using Hims.Common.Data;
using Hims.Common.Events;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.ClinicalCare.Controllers;

public class PrescriptionItemInput
{
    /// <summary>Drug as written by the doctor (the drug master lives in Pharmacy; ref.drug can be used later).</summary>
    [Required] public string DrugText { get; set; } = string.Empty;
    public decimal? Dose { get; set; }
    public string? DoseUnit { get; set; }
    /// <summary>ORAL, IV, IM, TOPICAL ...</summary>
    public string? Route { get; set; }
    /// <summary>OD, BD, TDS, QID, HS, SOS ...</summary>
    [Required] public string Frequency { get; set; } = string.Empty;
    /// <summary>AFTER_FOOD, BEFORE_FOOD ...</summary>
    public string? Timing { get; set; }
    public int? DurationValue { get; set; }
    public string? DurationUnit { get; set; }
    public decimal? Quantity { get; set; }
    public string? Instructions { get; set; }
}

public class IssuePrescriptionRequest
{
    [Required] public long EncounterId { get; set; }
    [Required] public long PractitionerId { get; set; }
    public string? Advice { get; set; }
    public DateOnly? FollowupDate { get; set; }
    [Required, MinLength(1)] public List<PrescriptionItemInput> Items { get; set; } = new();
}

/// <summary>E-prescriptions (ord.prescription / ord.prescription_item).</summary>
[ApiController]
[Route("api/prescriptions")]
public class PrescriptionsController : ControllerBase
{
    private readonly ClinicalCareDbContext _db;
    private readonly ISequenceService _seq;
    public PrescriptionsController(ClinicalCareDbContext db, ISequenceService seq) { _db = db; _seq = seq; }

    /// <summary>Issues a signed prescription and publishes <c>PrescriptionIssued</c>.</summary>
    [HttpPost]
    public async Task<IActionResult> Issue([FromBody] IssuePrescriptionRequest req, CancellationToken ct)
    {
        var enc = await _db.RefEncounters.FirstOrDefaultAsync(e => e.EncounterId == req.EncounterId, ct);
        if (enc?.PatientId is null || enc.OrganizationId is null || enc.BranchId is null)
            return Conflict(new { error = $"Encounter {req.EncounterId} has not replicated into Clinical Care yet; retry in a moment." });
        if (enc.EncounterStatus == "COMPLETED") return BadRequest(new { error = "The encounter is already closed" });

        var now = DateTime.UtcNow;
        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        var rx = new Prescription
        {
            OrganizationId = enc.OrganizationId.Value, BranchId = enc.BranchId.Value,
            PrescriptionNo = await _seq.NextAsync(_db, enc.OrganizationId.Value, enc.BranchId.Value, "PRESCRIPTION", "RX", ct),
            PatientId = enc.PatientId.Value, EncounterId = req.EncounterId, PractitionerId = req.PractitionerId, PrescriptionType = "OPD",
            PrescribedAt = now, Advice = req.Advice, FollowupDate = req.FollowupDate, SignedAt = now, PrescriptionStatus = "ACTIVE",
        };
        _db.Prescriptions.Add(rx);
        await _db.SaveChangesAsync(ct);

        var items = req.Items.Select(i => new PrescriptionItem
        {
            PrescriptionId = rx.PrescriptionId, DrugText = i.DrugText.Trim(), Dose = i.Dose, DoseUnit = i.DoseUnit, Route = i.Route,
            Frequency = i.Frequency, Timing = i.Timing, DurationValue = i.DurationValue, DurationUnit = i.DurationUnit,
            Quantity = i.Quantity, Instructions = i.Instructions, ItemStatus = "ACTIVE",
        }).ToList();
        foreach (var it in items) _db.PrescriptionItems.Add(it);
        await _db.SaveChangesAsync(ct);

        var payload = new PrescriptionIssuedPayload(rx.PrescriptionId, rx.PrescriptionNo, rx.PatientId, rx.EncounterId, rx.PractitionerId, rx.PrescribedAt,
            rx.Advice, rx.FollowupDate,
            items.Select(i => new PrescriptionItemPayload(i.PrescriptionItemId, i.DrugText, i.Dose, i.DoseUnit, i.Route, i.Frequency, i.Timing,
                i.DurationValue, i.DurationUnit, i.Quantity, i.Instructions)).ToList());
        _db.EnqueueEvent("PrescriptionIssued", "ord.prescription", rx.PrescriptionId, payload, rx.OrganizationId, rx.BranchId, rx.PatientId);
        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        return Created($"/api/prescriptions?encounterId={req.EncounterId}", new { rx.PrescriptionId, rx.PrescriptionNo, itemIds = items.Select(i => i.PrescriptionItemId) });
    }

    /// <summary>Prescriptions with their items.</summary>
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] long? patientId, [FromQuery] long? encounterId, CancellationToken ct)
    {
        var q = _db.Prescriptions.AsQueryable();
        if (patientId is not null) q = q.Where(p => p.PatientId == patientId);
        if (encounterId is not null) q = q.Where(p => p.EncounterId == encounterId);
        var list = await q.OrderByDescending(p => p.PrescriptionId).Take(30).ToListAsync(ct);
        var ids = list.Select(p => p.PrescriptionId).ToList();
        var items = await _db.PrescriptionItems.Where(i => ids.Contains(i.PrescriptionId)).ToListAsync(ct);
        return Ok(list.Select(p => new { p.PrescriptionId, p.PrescriptionNo, p.PrescribedAt, p.Advice, p.PrescriptionStatus, items = items.Where(i => i.PrescriptionId == p.PrescriptionId) }));
    }
}
