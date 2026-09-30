using System.ComponentModel.DataAnnotations;
using Hims.Common.Data;
using Hims.PatientAccess.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.PatientAccess.Controllers;

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
    private readonly PatientAccessDbContext _db;
    private readonly ISequenceService _seq;
    public PatientsController(PatientAccessDbContext db, ISequenceService seq) { _db = db; _seq = seq; }

    /// <summary>
    /// Registers a patient: allocates the UHID from core.number_sequence, inserts pat.patient and writes a
    /// <c>PatientRegistered</c> event to evt.outbox in the same transaction. Returns 409 when a patient with the same
    /// mobile, first name and date of birth already exists (pass ?force=true to register anyway).
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> Register([FromBody] RegisterPatientRequest req, [FromQuery] bool force, CancellationToken ct)
    {
        var branch = await _db.RefBranches.FirstOrDefaultAsync(b => b.BranchId == req.BranchId, ct);
        if (branch is null || branch.OrganizationId is null)
            return BadRequest(new { error = $"Branch {req.BranchId} is unknown. Load reference data first (POST identity-org /api/admin/republish)." });
        var orgId = branch.OrganizationId.Value;

        if (!force)
        {
            var first = req.FirstName.Trim().ToLower();
            var dup = await _db.Patients.FirstOrDefaultAsync(p => p.Mobile == req.Mobile && p.FirstName.ToLower() == first && p.DateOfBirth == req.DateOfBirth, ct);
            if (dup is not null)
                return Conflict(new { error = "A patient with the same name, mobile and date of birth already exists.", patientId = dup.PatientId, uhid = dup.Uhid });
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

        _db.EnqueueEvent("PatientRegistered", "pat.patient", patient.PatientId, patient, orgId, req.BranchId, patient.PatientId);
        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);

        return CreatedAtAction(nameof(Get), new { id = patient.PatientId }, patient);
    }

    /// <summary>Contact/address update. Publishes PatientUpdated.</summary>
    [HttpPut("{id:long}")]
    public async Task<IActionResult> Update(long id, [FromBody] UpdatePatientRequest req, CancellationToken ct)
    {
        var p = await _db.Patients.FirstOrDefaultAsync(x => x.PatientId == id, ct);
        if (p is null) return NotFound();
        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        if (req.Mobile is not null) p.Mobile = req.Mobile;
        if (req.AltMobile is not null) p.AltMobile = req.AltMobile;
        if (req.Email is not null) p.Email = req.Email;
        if (req.AddressLine1 is not null) p.AddressLine1 = req.AddressLine1;
        if (req.City is not null) p.City = req.City;
        if (req.StateCode is not null) p.StateCode = req.StateCode;
        if (req.Pincode is not null) p.Pincode = req.Pincode;
        await _db.SaveChangesAsync(ct);
        _db.EnqueueEvent("PatientUpdated", "pat.patient", p.PatientId, p, p.OrganizationId, p.RegistrationBranchId, p.PatientId);
        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
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
