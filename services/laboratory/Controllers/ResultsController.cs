using Hims.Laboratory.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.Laboratory.Controllers;

/// <summary>Lab results (lab.result) with parameter names.</summary>
[ApiController]
[Route("api/results")]
public class ResultsController : ControllerBase
{
    private readonly LaboratoryDbContext _db;
    public ResultsController(LaboratoryDbContext db) => _db = db;

    /// <summary>Current (non-superseded) results. Filter by orderId, sampleId and/or patientId.</summary>
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] long? orderId, [FromQuery] long? sampleId, [FromQuery] long? patientId, CancellationToken ct)
    {
        var q = from r in _db.Results
                join p in _db.LabParameters on r.LabParameterId equals p.LabParameterId
                where r.ResultStatus != "AMENDED" && r.ResultStatus != "CANCELLED"
                select new
                {
                    r.ResultId, r.OrderItemId, r.SampleId, r.PatientId, p.ParameterCode, p.ParameterName, r.ValueNumeric, r.ValueText, r.Unit,
                    r.ReferenceRangeText, r.AbnormalFlag, r.IsCritical, r.ResultSource, r.ResultedAt, r.ResultStatus, r.VersionNo,
                };
        if (sampleId is not null) q = q.Where(x => x.SampleId == sampleId);
        if (patientId is not null) q = q.Where(x => x.PatientId == patientId);
        if (orderId is not null)
        {
            var sids = await _db.Samples.Where(s => s.OrderId == orderId).Select(s => (long?)s.SampleId).ToListAsync(ct);
            q = q.Where(x => sids.Contains(x.SampleId));
        }
        return Ok(await q.OrderBy(x => x.ResultId).Take(500).ToListAsync(ct));
    }
}
