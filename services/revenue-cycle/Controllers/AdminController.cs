using Hims.RevenueCycle.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.RevenueCycle.Controllers;

[ApiController]
[Route("api/admin")]
public class AdminController : ControllerBase
{
    private readonly RevenueCycleDbContext _db;
    public AdminController(RevenueCycleDbContext db) => _db = db;

    /// <summary>Initial bulk load of <c>ref.service</c> in Clinical Care and Laboratory: publishes ServiceUpdated for every service.</summary>
    [HttpPost("republish")]
    public async Task<IActionResult> Republish(CancellationToken ct)
    {
        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        var services = await _db.Services.ToListAsync(ct);
        foreach (var s in services) _db.EnqueueEvent("ServiceUpdated", "mst.service", s.ServiceId, s, s.OrganizationId);
        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        return Ok(new { services = services.Count });
    }
}
