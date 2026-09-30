using System.ComponentModel.DataAnnotations;
using Hims.Common.Data;
using Hims.PatientAccess.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.PatientAccess.Controllers;

public class StartEncounterRequest
{
    [Required] public long PatientId { get; set; }
    [Required] public int BranchId { get; set; }
    /// <summary>OPD, IPD, EMERGENCY, DAYCARE, TELECONSULT, ...</summary>
    public string EncounterType { get; set; } = "OPD";
    public int? DepartmentId { get; set; }
    /// <summary>Consulting doctor (see GET /api/practitioners).</summary>
    public long? AttendingPractitionerId { get; set; }
    /// <summary>SELF, CORPORATE, INSURANCE, GOVT_SCHEME, B2B, STAFF, FREE</summary>
    public string FinancialClass { get; set; } = "SELF";
    /// <summary>WALK_IN, APPOINTMENT, ONLINE ...</summary>
    public string? VisitChannel { get; set; } = "WALK_IN";
}

/// <summary>Encounters (pat.encounter): an OP visit / admission / ER visit.</summary>
[ApiController]
[Route("api/encounters")]
public class EncountersController : ControllerBase
{
    private readonly PatientAccessDbContext _db;
    private readonly ISequenceService _seq;
    public EncountersController(PatientAccessDbContext db, ISequenceService seq) { _db = db; _seq = seq; }

    /// <summary>Starts an encounter (encounter_no from core.number_sequence) and publishes <c>EncounterStarted</c>.</summary>
    [HttpPost]
    public async Task<IActionResult> Start([FromBody] StartEncounterRequest req, CancellationToken ct)
    {
        var patient = await _db.Patients.FirstOrDefaultAsync(p => p.PatientId == req.PatientId, ct);
        if (patient is null) return NotFound(new { error = $"Patient {req.PatientId} not found" });
        var branch = await _db.RefBranches.FirstOrDefaultAsync(b => b.BranchId == req.BranchId, ct);
        if (branch is null || branch.OrganizationId is null) return BadRequest(new { error = $"Branch {req.BranchId} is unknown (load reference data first)" });

        int? specialtyId = null;
        if (req.AttendingPractitionerId is not null)
        {
            var doc = await _db.RefPractitioners.FirstOrDefaultAsync(p => p.PractitionerId == req.AttendingPractitionerId, ct);
            if (doc is null) return BadRequest(new { error = $"Practitioner {req.AttendingPractitionerId} is unknown" });
            specialtyId = doc.PrimarySpecialtyId;
        }

        var prefix = req.EncounterType switch { "IPD" => "IP", "EMERGENCY" => "ER", "DAYCARE" => "DC", "TELECONSULT" => "TC", _ => "OP" };
        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        var enc = new Encounter
        {
            OrganizationId = branch.OrganizationId.Value,
            BranchId = req.BranchId,
            EncounterNo = await _seq.NextAsync(_db, branch.OrganizationId.Value, req.BranchId, "ENCOUNTER", prefix, ct),
            PatientId = req.PatientId,
            EncounterType = req.EncounterType,
            DepartmentId = req.DepartmentId,
            SpecialtyId = specialtyId,
            AttendingPractitionerId = req.AttendingPractitionerId,
            VisitChannel = req.VisitChannel,
            FinancialClass = req.FinancialClass,
            StartAt = DateTime.UtcNow,
            EncounterStatus = "OPEN",
        };
        _db.Encounters.Add(enc);
        await _db.SaveChangesAsync(ct);

        _db.EnqueueEvent("EncounterStarted", "pat.encounter", enc.EncounterId, enc, enc.OrganizationId, enc.BranchId, enc.PatientId);
        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        return CreatedAtAction(nameof(Get), new { id = enc.EncounterId }, enc);
    }

    /// <summary>Closes (completes) an encounter and publishes <c>EncounterClosed</c>.</summary>
    [HttpPost("{id:long}/close")]
    public async Task<IActionResult> Close(long id, CancellationToken ct)
    {
        var enc = await _db.Encounters.FirstOrDefaultAsync(e => e.EncounterId == id, ct);
        if (enc is null) return NotFound();
        if (enc.EncounterStatus == "COMPLETED") return Ok(enc);
        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        enc.EncounterStatus = "COMPLETED";
        enc.EndAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);
        _db.EnqueueEvent("EncounterClosed", "pat.encounter", enc.EncounterId, enc, enc.OrganizationId, enc.BranchId, enc.PatientId);
        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        return Ok(enc);
    }

    /// <summary>Get one encounter.</summary>
    [HttpGet("{id:long}")]
    public async Task<IActionResult> Get(long id, CancellationToken ct)
    {
        var e = await _db.Encounters.FirstOrDefaultAsync(x => x.EncounterId == id, ct);
        return e is null ? NotFound() : Ok(e);
    }

    /// <summary>List encounters, newest first. Filter by patientId and/or status (OPEN, COMPLETED, ...).</summary>
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] long? patientId, [FromQuery] string? status, CancellationToken ct)
    {
        var q = _db.Encounters.AsQueryable();
        if (patientId is not null) q = q.Where(e => e.PatientId == patientId);
        if (!string.IsNullOrEmpty(status)) q = q.Where(e => e.EncounterStatus == status);
        return Ok(await q.OrderByDescending(e => e.EncounterId).Take(50).ToListAsync(ct));
    }
}
