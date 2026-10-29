using System.ComponentModel.DataAnnotations;
using Hims.Common.Data;
using Hims.Common.Logging;
using Hims.PatientEngagement.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.PatientEngagement.Controllers;

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
    private readonly PatientEngagementDbContext _db;
    private readonly ISequenceService _seq;
    private readonly ILogger<EncountersController> _log;
    public EncountersController(PatientEngagementDbContext db, ISequenceService seq, ILogger<EncountersController> log) { _db = db; _seq = seq; _log = log; }

    /// <summary>Starts an encounter (encounter_no from core.number_sequence) and publishes <c>EncounterStarted</c>.</summary>
    [HttpPost]
    public async Task<IActionResult> Start([FromBody] StartEncounterRequest req, CancellationToken ct)
    {
        var corr = HttpContext.GetCorrelationId();
        _log.LogInformation("[FLOW] corr={Corr} step=ENC-01 POST /api/encounters received: patient {PatientId}, branch {BranchId}, type {Type}, practitioner {PractitionerId}",
            corr, req.PatientId, req.BranchId, req.EncounterType, req.AttendingPractitionerId);
        var patient = await _db.Patients.FirstOrDefaultAsync(p => p.PatientId == req.PatientId, ct);
        if (patient is null)
        {
            _log.LogWarning("[FLOW] corr={Corr} step=ENC-STOP patient {PatientId} not found -> 404", corr, req.PatientId);
            return NotFound(new { error = $"Patient {req.PatientId} not found" });
        }
        var branch = await _db.RefBranches.FirstOrDefaultAsync(b => b.BranchId == req.BranchId, ct);
        if (branch is null || branch.OrganizationId is null)
        {
            _log.LogWarning("[FLOW] corr={Corr} step=ENC-STOP branch {BranchId} not found in ref.branch -> 400", corr, req.BranchId);
            return BadRequest(new { error = $"Branch {req.BranchId} is unknown (load reference data first)" });
        }

        int? specialtyId = null;
        if (req.AttendingPractitionerId is not null)
        {
            var doc = await _db.RefPractitioners.FirstOrDefaultAsync(p => p.PractitionerId == req.AttendingPractitionerId, ct);
            if (doc is null)
            {
                _log.LogWarning("[FLOW] corr={Corr} step=ENC-STOP practitioner {PractitionerId} not found in ref.practitioner -> 400", corr, req.AttendingPractitionerId);
                return BadRequest(new { error = $"Practitioner {req.AttendingPractitionerId} is unknown" });
            }
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
        _log.LogInformation("[FLOW] corr={Corr} step=ENC-02 encounter no {EncounterNo} allocated; pat.encounter inserted, encounter_id {EncounterId} for patient {PatientId} ({Uhid})",
            corr, enc.EncounterNo, enc.EncounterId, patient.PatientId, patient.Uhid);

        var outbox = _db.EnqueueEvent("EncounterStarted", "pat.encounter", enc.EncounterId, enc, enc.OrganizationId, enc.BranchId, enc.PatientId, corr);
        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        _log.LogInformation("[FLOW] corr={Corr} event={EventId} step=ENC-03 EncounterStarted queued in evt.outbox (outbox_id {OutboxId}) and committed; 201 returned",
            corr, outbox.EventId, outbox.OutboxId);
        return CreatedAtAction(nameof(Get), new { id = enc.EncounterId }, enc);
    }

    /// <summary>Closes (completes) an encounter and publishes <c>EncounterClosed</c>.</summary>
    [HttpPost("{id:long}/close")]
    public async Task<IActionResult> Close(long id, CancellationToken ct)
    {
        var corr = HttpContext.GetCorrelationId();
        _log.LogInformation("[FLOW] corr={Corr} step=CLS-01 POST /api/encounters/{EncounterId}/close received", corr, id);
        var enc = await _db.Encounters.FirstOrDefaultAsync(e => e.EncounterId == id, ct);
        if (enc is null)
        {
            _log.LogWarning("[FLOW] corr={Corr} step=CLS-STOP encounter {EncounterId} not found -> 404", corr, id);
            return NotFound();
        }
        if (enc.EncounterStatus == "COMPLETED")
        {
            _log.LogInformation("[FLOW] corr={Corr} step=CLS-STOP encounter {EncounterNo} already COMPLETED, no event published", corr, enc.EncounterNo);
            return Ok(enc);
        }
        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        enc.EncounterStatus = "COMPLETED";
        enc.EndAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);
        var outbox = _db.EnqueueEvent("EncounterClosed", "pat.encounter", enc.EncounterId, enc, enc.OrganizationId, enc.BranchId, enc.PatientId, corr);
        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        _log.LogInformation("[FLOW] corr={Corr} event={EventId} step=CLS-02 encounter {EncounterNo} COMPLETED; EncounterClosed queued in evt.outbox (outbox_id {OutboxId}) and committed",
            corr, outbox.EventId, enc.EncounterNo, outbox.OutboxId);
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
