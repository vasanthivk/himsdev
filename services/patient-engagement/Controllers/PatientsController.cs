using System.ComponentModel.DataAnnotations;
using Hims.Common.Data;
using Hims.Common.Logging;
using Hims.PatientEngagement.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.PatientEngagement.Controllers;

public class RegisterPatientRequest
{
    /// <summary>Registering branch (see GET /api/branches).</summary>
    [Required] public int BranchId { get; set; }
    public string? Title { get; set; }
    [Required, MaxLength(100)] public string FirstName { get; set; } = string.Empty;
    public string? MiddleName { get; set; }
    public string? LastName { get; set; }
    public DateOnly? DateOfBirth { get; set; }
    /// <summary>male, female, other, unknown</summary>
    [Required, MaxLength(10)] public string Gender { get; set; } = string.Empty;
    [Required, MaxLength(15)] public string Mobile { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? BloodGroup { get; set; }
    public string? AddressLine1 { get; set; }
    public string? City { get; set; }
    public string? StateCode { get; set; }
    public string? Pincode { get; set; }
    /// <summary>COUNTER, PORTAL, APP, CALL_CENTRE, CAMP, B2B, ABDM_SCAN_SHARE</summary>
    public string RegistrationSource { get; set; } = "COUNTER";
}

public class UpdatePatientRequest
{
    public string? Mobile { get; set; }
    public string? AltMobile { get; set; }
    public string? Email { get; set; }
    public string? AddressLine1 { get; set; }
    public string? City { get; set; }
    public string? StateCode { get; set; }
    public string? Pincode { get; set; }
}

/// <summary>Patient registration and search (pat.patient).</summary>
[ApiController]
[Route("api/patients")]
public class PatientsController : ControllerBase
{
    private readonly PatientEngagementDbContext _db;
    private readonly ISequenceService _seq;
    private readonly ILogger<PatientsController> _log;
    public PatientsController(PatientEngagementDbContext db, ISequenceService seq, ILogger<PatientsController> log) { _db = db; _seq = seq; _log = log; }

    /// <summary>
    /// Registers a patient: allocates the UHID from core.number_sequence, inserts pat.patient and writes a
    /// <c>PatientRegistered</c> event to evt.outbox in the same transaction. Returns 409 when a patient with the same
    /// mobile, first name and date of birth already exists (pass ?force=true to register anyway).
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> Register([FromBody] RegisterPatientRequest req, [FromQuery] bool force, CancellationToken ct)
    {
        var corr = HttpContext.GetCorrelationId();
        _log.LogInformation("[FLOW] corr={Corr} step=REG-01 POST /api/patients received: branch {BranchId}, mobile {Mobile}, source {Source}, user {User}, force={Force}",
            corr, req.BranchId, FlowLog.MaskMobile(req.Mobile), req.RegistrationSource, User.Identity?.Name ?? "anonymous", force);

        var branch = await _db.RefBranches.FirstOrDefaultAsync(b => b.BranchId == req.BranchId, ct);
        if (branch is null || branch.OrganizationId is null)
        {
            _log.LogWarning("[FLOW] corr={Corr} step=REG-STOP branch {BranchId} not found in ref.branch -> 400 (reference data not replicated from identity-org yet)", corr, req.BranchId);
            return BadRequest(new { error = $"Branch {req.BranchId} is unknown. Load reference data first (POST identity-org /api/admin/republish)." });
        }
        var orgId = branch.OrganizationId.Value;
        _log.LogInformation("[FLOW] corr={Corr} step=REG-02 branch {BranchId} resolved from ref.branch -> organization {OrgId}", corr, req.BranchId, orgId);

        if (!force)
        {
            var first = req.FirstName.Trim().ToLower();
            var dup = await _db.Patients.FirstOrDefaultAsync(p => p.Mobile == req.Mobile && p.FirstName.ToLower() == first && p.DateOfBirth == req.DateOfBirth, ct);
            if (dup is not null)
            {
                _log.LogWarning("[FLOW] corr={Corr} step=REG-STOP duplicate of patient {PatientId} ({Uhid}) -> 409, nothing saved", corr, dup.PatientId, dup.Uhid);
                return Conflict(new { error = "A patient with the same name, mobile and date of birth already exists.", patientId = dup.PatientId, uhid = dup.Uhid });
            }
            _log.LogInformation("[FLOW] corr={Corr} step=REG-03 duplicate check passed (mobile + first name + date of birth)", corr);
        }
        else
        {
            _log.LogInformation("[FLOW] corr={Corr} step=REG-03 duplicate check skipped (force=true)", corr);
        }

        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        var patient = new Patient
        {
            OrganizationId = orgId,
            RegistrationBranchId = req.BranchId,
            Uhid = await _seq.NextAsync(_db, orgId, req.BranchId, "UHID", "DR", ct),
            Title = req.Title, FirstName = req.FirstName.Trim(), MiddleName = req.MiddleName, LastName = req.LastName,
            DateOfBirth = req.DateOfBirth, Gender = req.Gender.ToLowerInvariant(), BloodGroup = req.BloodGroup,
            Mobile = req.Mobile, Email = req.Email,
            AddressLine1 = req.AddressLine1, City = req.City, StateCode = req.StateCode, Pincode = req.Pincode,
            RegistrationSource = req.RegistrationSource, RegisteredAt = DateTime.UtcNow,
        };
        _db.Patients.Add(patient);
        await _db.SaveChangesAsync(ct);          // identity value for patient_id is needed inside the event
        _log.LogInformation("[FLOW] corr={Corr} step=REG-04 UHID {Uhid} allocated from core.number_sequence; pat.patient inserted, patient_id {PatientId}", corr, patient.Uhid, patient.PatientId);

        var outbox = _db.EnqueueEvent("PatientRegistered", "pat.patient", patient.PatientId, patient, orgId, req.BranchId, patient.PatientId, corr);
        await _db.SaveChangesAsync(ct);
        _log.LogInformation("[FLOW] corr={Corr} event={EventId} step=REG-05 PatientRegistered queued in evt.outbox (outbox_id {OutboxId})", corr, outbox.EventId, outbox.OutboxId);
        await tx.CommitAsync(ct);
        _log.LogInformation("[FLOW] corr={Corr} event={EventId} step=REG-06 committed patient + outbox row; 201 returned to the screen. OutboxRelay publishes next", corr, outbox.EventId);

        return CreatedAtAction(nameof(Get), new { id = patient.PatientId }, patient);
    }

    /// <summary>Contact/address update. Publishes PatientUpdated.</summary>
    [HttpPut("{id:long}")]
    public async Task<IActionResult> Update(long id, [FromBody] UpdatePatientRequest req, CancellationToken ct)
    {
        var corr = HttpContext.GetCorrelationId();
        _log.LogInformation("[FLOW] corr={Corr} step=UPD-01 PUT /api/patients/{PatientId} received", corr, id);
        var p = await _db.Patients.FirstOrDefaultAsync(x => x.PatientId == id, ct);
        if (p is null)
        {
            _log.LogWarning("[FLOW] corr={Corr} step=UPD-STOP patient {PatientId} not found -> 404", corr, id);
            return NotFound();
        }
        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        if (req.Mobile is not null) p.Mobile = req.Mobile;
        if (req.AltMobile is not null) p.AltMobile = req.AltMobile;
        if (req.Email is not null) p.Email = req.Email;
        if (req.AddressLine1 is not null) p.AddressLine1 = req.AddressLine1;
        if (req.City is not null) p.City = req.City;
        if (req.StateCode is not null) p.StateCode = req.StateCode;
        if (req.Pincode is not null) p.Pincode = req.Pincode;
        await _db.SaveChangesAsync(ct);
        var outbox = _db.EnqueueEvent("PatientUpdated", "pat.patient", p.PatientId, p, p.OrganizationId, p.RegistrationBranchId, p.PatientId, corr);
        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        _log.LogInformation("[FLOW] corr={Corr} event={EventId} step=UPD-02 patient {PatientId} ({Uhid}) updated; PatientUpdated queued in evt.outbox (outbox_id {OutboxId}) and committed",
            corr, outbox.EventId, p.PatientId, p.Uhid, outbox.OutboxId);
        return Ok(p);
    }

    /// <summary>Get one patient.</summary>
    [HttpGet("{id:long}")]
    public async Task<IActionResult> Get(long id, CancellationToken ct)
    {
        var p = await _db.Patients.FirstOrDefaultAsync(x => x.PatientId == id, ct);
        return p is null ? NotFound() : Ok(p);
    }

    /// <summary>Search by UHID (exact), mobile (prefix) or name (contains). Returns up to 25 matches.</summary>
    [HttpGet]
    public async Task<IActionResult> Search([FromQuery] string? q, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(q)) return Ok(Array.Empty<object>());
        var term = q.Trim();
        var lower = term.ToLower();
        var list = await _db.Patients
            .Where(p => p.Uhid == term || p.Mobile.StartsWith(term) || p.FirstName.ToLower().Contains(lower) || (p.LastName != null && p.LastName.ToLower().Contains(lower)))
            .OrderByDescending(p => p.PatientId).Take(25)
            .Select(p => new { p.PatientId, p.Uhid, p.Title, p.FirstName, p.MiddleName, p.LastName, p.Gender, p.DateOfBirth, p.Mobile, p.RegistrationBranchId })
            .ToListAsync(ct);
        return Ok(list);
    }
}
