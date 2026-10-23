using Hims.ClinicalCare.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.ClinicalCare.Controllers;

/// <summary>Lookups the doctor's screens need, served from this service's ref.* replicas (no call to Identity/Org or Patient Access).</summary>
[ApiController]
[Route("api")]
public class DirectoryController : ControllerBase
{
    private readonly ClinicalCareDbContext _db;
    public DirectoryController(ClinicalCareDbContext db) => _db = db;

    /// <summary>Practitioners (ref.practitioner), for the doctor filter and names in the queue.</summary>
    [HttpGet("practitioners")]
    public async Task<IActionResult> Practitioners(CancellationToken ct) =>
        Ok(await _db.RefPractitioners.OrderBy(p => p.DisplayName)
            .Select(p => new { p.PractitionerId, p.DisplayName, p.Qualification, p.PrimarySpecialtyId }).ToListAsync(ct));
}
