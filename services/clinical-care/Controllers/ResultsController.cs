using Hims.ClinicalCare.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.ClinicalCare.Controllers;

/// <summary>
/// Verified lab results for the doctor, from this service's ref.lab_result_summary replica (filled from Laboratory's
/// ResultVerified events) - no call to Laboratory at request time.
/// </summary>
[ApiController]
[Route("api/results")]
public class ResultsController : ControllerBase
{
    private readonly ClinicalCareDbContext _db;
    public ResultsController(ClinicalCareDbContext db) => _db = db;

    /// <summary>Verified results of a patient, optionally only one encounter; newest first.</summary>
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] long? patientId, [FromQuery] long? encounterId, CancellationToken ct)
    {
        if (patientId is null && encounterId is null) return BadRequest(new { error = "Give patientId and/or encounterId." });
        var q = _db.RefLabResultSummaries.AsQueryable();
        if (patientId is not null) q = q.Where(r => r.PatientId == patientId);
        if (encounterId is not null) q = q.Where(r => r.EncounterId == encounterId);
        return Ok(await q.OrderByDescending(r => r.VerifiedAt).ThenBy(r => r.ResultId)
            .Select(r => new
            {
                r.ResultId, r.OrderItemId, r.PatientId, r.EncounterId, r.TestName, r.ParameterName, r.ValueNumeric, r.ValueText, r.Unit,
                r.ReferenceRangeText, r.AbnormalFlag, r.IsCritical, r.VerifiedAt,
            }).ToListAsync(ct));
    }
}
