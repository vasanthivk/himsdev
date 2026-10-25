using Hims.Diagnostics.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.Diagnostics.Controllers;

/// <summary>Test catalogue: mst.lab_test and mst.lab_parameter (names come from the ref.service replica).</summary>
[ApiController]
[Route("api/tests")]
public class TestsController : ControllerBase
{
    private readonly DiagnosticsDbContext _db;
    public TestsController(DiagnosticsDbContext db) => _db = db;

    /// <summary>Lab tests with their parameters.</summary>
    [HttpGet]
    public async Task<IActionResult> List(CancellationToken ct)
    {
        var tests = await _db.LabTests.OrderBy(t => t.ServiceId).ToListAsync(ct);
        var sids = tests.Select(t => t.ServiceId).ToList();
        var services = await _db.RefServices.Where(s => sids.Contains(s.ServiceId)).ToListAsync(ct);
        var parameters = await _db.LabParameters.OrderBy(p => p.DisplayOrder).ToListAsync(ct);
        return Ok(tests.Select(t => new
        {
            t.LabTestId, t.ServiceId, ServiceName = services.FirstOrDefault(s => s.ServiceId == t.ServiceId)?.ServiceName, t.LabSection, t.SpecimenType, t.ContainerType, t.TatMinutes,
            parameters = parameters.Where(p => p.LabTestId == t.LabTestId).Select(p => new { p.LabParameterId, p.ParameterCode, p.ParameterName, p.Unit }),
        }));
    }
}
