using Hims.RevenueCycle.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.RevenueCycle.Controllers;

/// <summary>Lookups the billing counter needs, from this service's ref.* replicas.</summary>
[ApiController]
[Route("api")]
public class DirectoryController : ControllerBase
{
    private readonly RevenueCycleDbContext _db;
    public DirectoryController(RevenueCycleDbContext db) => _db = db;

    /// <summary>Branches (ref.branch).</summary>
    [HttpGet("branches")]
    public async Task<IActionResult> Branches(CancellationToken ct) =>
        Ok(await _db.RefBranches.OrderBy(b => b.BranchId).Select(b => new { b.BranchId, b.OrganizationId, b.BranchCode, b.BranchName }).ToListAsync(ct));

    /// <summary>Find a patient (ref.patient) by UHID (exact), mobile (prefix) or name (contains).</summary>
    [HttpGet("patients")]
    public async Task<IActionResult> Patients([FromQuery] string? q, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(q)) return Ok(Array.Empty<object>());
        var term = q.Trim();
        var lower = term.ToLower();
        return Ok(await _db.RefPatients
            .Where(p => p.Uhid == term || (p.Mobile != null && p.Mobile.StartsWith(term)) || (p.FirstName != null && p.FirstName.ToLower().Contains(lower)) || (p.LastName != null && p.LastName.ToLower().Contains(lower)))
            .OrderByDescending(p => p.PatientId).Take(25)
            .Select(p => new { p.PatientId, p.Uhid, p.FirstName, p.LastName, p.Gender, p.DateOfBirth, p.Mobile }).ToListAsync(ct));
    }

    /// <summary>One patient (ref.patient).</summary>
    [HttpGet("patients/{id:long}")]
    public async Task<IActionResult> Patient(long id, CancellationToken ct)
    {
        var p = await _db.RefPatients.FirstOrDefaultAsync(x => x.PatientId == id, ct);
        return p is null ? NotFound(new { error = "Patient not found (may not have replicated yet)" }) : Ok(p);
    }

    /// <summary>Encounters (ref.encounter) of a patient, newest first.</summary>
    [HttpGet("encounters")]
    public async Task<IActionResult> Encounters([FromQuery] long patientId, CancellationToken ct) =>
        Ok(await _db.RefEncounters.Where(e => e.PatientId == patientId).OrderByDescending(e => e.EncounterId).Take(20)
            .Select(e => new { e.EncounterId, e.EncounterNo, e.EncounterType, e.EncounterStatus, e.StartAt }).ToListAsync(ct));
}