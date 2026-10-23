using Hims.ClinicalCare.Data;
using Hims.Common.Events;
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

    /// <summary>
    /// The doctor finishes the visit. The encounter belongs to Patient Access, so this publishes <c>ConsultationCompleted</c>;
    /// Patient Access closes the encounter and publishes <c>EncounterClosed</c>, which updates ref.encounter here (the visit
    /// leaves the queue within a few seconds). Answers 202 Accepted.
    /// </summary>
    [HttpPost("{id:long}/close")]
    public async Task<IActionResult> Close(long id, CancellationToken ct)
    {
        var e = await _db.RefEncounters.FirstOrDefaultAsync(x => x.EncounterId == id, ct);
        if (e is null) return NotFound(new { error = $"Encounter {id} is not known to Clinical Care." });
        if (e.EncounterStatus != "OPEN") return Ok(new { e.EncounterId, e.EncounterStatus, message = "The visit is already closed." });

        _db.EnqueueEvent("ConsultationCompleted", "pat.encounter", e.EncounterId,
            new ConsultationCompletedPayload(e.EncounterId, e.PatientId, e.AttendingPractitionerId, DateTime.UtcNow),
            e.OrganizationId, e.BranchId, e.PatientId);
        await _db.SaveChangesAsync(ct);
        return Accepted(new { e.EncounterId, status = "CLOSE_REQUESTED", message = "Visit close sent to Patient Access." });
    }

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
