using Hims.ClinicalCare.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.ClinicalCare.Controllers;

/// <summary>The doctor's view of encounters and patients, from this service's ref.encounter / ref.patient replicas.</summary>
[ApiController]
[Route("api/encounters")]
public class EncountersController : ControllerBase
{
    private readonly ClinicalCareDbContext _db;
    public EncountersController(ClinicalCareDbContext db) => _db = db;

    /// <summary>Encounters (default status OPEN) with the patient's name; optionally only for one practitioner.</summary>
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] string? status, [FromQuery] long? practitionerId, CancellationToken ct)
    {
        var st = string.IsNullOrEmpty(status) ? "OPEN" : status;
        var q = _db.RefEncounters.Where(e => e.EncounterStatus == st);
        if (practitionerId is not null) q = q.Where(e => e.AttendingPractitionerId == practitionerId);
        var encounters = await q.OrderByDescending(e => e.EncounterId).Take(50).ToListAsync(ct);
        var pids = encounters.Where(e => e.PatientId != null).Select(e => e.PatientId!.Value).Distinct().ToList();
        var patients = await _db.RefPatients.Where(p => pids.Contains(p.PatientId)).ToListAsync(ct);
        return Ok(encounters.Select(e =>
        {
            var p = patients.FirstOrDefault(x => x.PatientId == e.PatientId);
            return new
            {
                e.EncounterId, e.EncounterNo, e.EncounterType, e.EncounterStatus, e.StartAt, e.AttendingPractitionerId,
                e.PatientId, PatientName = p is null ? null : $"{p.FirstName} {p.LastName}".Trim(), Uhid = p?.Uhid,
            };
        }));
    }

    /// <summary>One encounter with the patient and attending practitioner.</summary>
    [HttpGet("{id:long}")]
    public async Task<IActionResult> Get(long id, CancellationToken ct)
    {
        var e = await _db.RefEncounters.FirstOrDefaultAsync(x => x.EncounterId == id, ct);
        if (e is null) return NotFound(new { error = "Encounter not found (it may not have replicated yet)" });
        var p = e.PatientId is null ? null : await _db.RefPatients.FirstOrDefaultAsync(x => x.PatientId == e.PatientId, ct);
        var d = e.AttendingPractitionerId is null ? null : await _db.RefPractitioners.FirstOrDefaultAsync(x => x.PractitionerId == e.AttendingPractitionerId, ct);
        return Ok(new { encounter = e, patient = p, practitioner = d });
    }
}
