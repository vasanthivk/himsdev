using Hims.ClinicalCare.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.ClinicalCare.Controllers;

/// <summary>What a doctor can order, from the ref.service replica of Revenue Cycle's chargemaster.</summary>
[ApiController]
[Route("api/catalog")]
public class CatalogController : ControllerBase
{
    private readonly ClinicalCareDbContext _db;
    public CatalogController(ClinicalCareDbContext db) => _db = db;

    /// <summary>Orderable services. type = LAB_TEST, RAD_PROCEDURE, PROCEDURE ...</summary>
    [HttpGet("services")]
    public async Task<IActionResult> Services([FromQuery] string? type, [FromQuery] string? q, CancellationToken ct)
    {
        var query = _db.RefServices.Where(s => s.IsOrderable == true);
        if (!string.IsNullOrEmpty(type)) query = query.Where(s => s.ServiceType == type);
        if (!string.IsNullOrEmpty(q)) { var l = q.ToLower(); query = query.Where(s => s.ServiceName!.ToLower().Contains(l) || s.ServiceCode!.ToLower().Contains(l)); }
        return Ok(await query.OrderBy(s => s.ServiceName).Select(s => new { s.ServiceId, s.ServiceCode, s.ServiceName, s.ServiceType }).ToListAsync(ct));
    }
}
