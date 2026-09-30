using Hims.IdentityOrg.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.IdentityOrg.Controllers;

[ApiController]
[Route("api/admin")]
public class AdminController : ControllerBase
{
    private readonly IdentityOrgDbContext _db;
    public AdminController(IdentityOrgDbContext db) => _db = db;

    /// <summary>
    /// Initial bulk load of every other service's <c>ref.*</c> tables (the data-model README: "an initial bulk load of each ref
    /// table from the owning service's API before event streaming is switched on"). Writes one *Updated event per row to the
    /// outbox; the relay publishes them and each subscriber upserts its ref row. Safe to call again at any time.
    /// </summary>
    [HttpPost("republish")]
    public async Task<IActionResult> Republish(CancellationToken ct)
    {
        await using var tx = await _db.Database.BeginTransactionAsync(ct);

        var orgs = await _db.Organizations.ToListAsync(ct);
        foreach (var o in orgs) _db.EnqueueEvent("OrganizationUpdated", "core.organization", o.OrganizationId, o, o.OrganizationId);

        var branches = await _db.Branches.ToListAsync(ct);
        foreach (var b in branches) _db.EnqueueEvent("BranchUpdated", "core.branch", b.BranchId, b, b.OrganizationId, b.BranchId);

        var depts = await _db.Departments.ToListAsync(ct);
        foreach (var d in depts) _db.EnqueueEvent("DepartmentUpdated", "mst.department", d.DepartmentId, d, d.OrganizationId);

        var practitioners = await _db.Practitioners.ToListAsync(ct);
        foreach (var p in practitioners) _db.EnqueueEvent("PractitionerUpdated", "hr.practitioner", p.PractitionerId, p, p.OrganizationId);

        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        return Ok(new { organizations = orgs.Count, branches = branches.Count, departments = depts.Count, practitioners = practitioners.Count });
    }
}
