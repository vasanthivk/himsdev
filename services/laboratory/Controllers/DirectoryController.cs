using Hims.Laboratory.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.Laboratory.Controllers;

/// <summary>Lookups from this service's ref.* replicas.</summary>
[ApiController]
[Route("api")]
public class DirectoryController : ControllerBase
{
    private readonly LaboratoryDbContext _db;
    public DirectoryController(LaboratoryDbContext db) => _db = db;

    /// <summary>Branches (ref.branch).</summary>
    [HttpGet("branches")]
    public async Task<IActionResult> Branches(CancellationToken ct) =>
        Ok(await _db.RefBranches.OrderBy(b => b.BranchId).Select(b => new { b.BranchId, b.OrganizationId, b.BranchCode, b.BranchName }).ToListAsync(ct));
}