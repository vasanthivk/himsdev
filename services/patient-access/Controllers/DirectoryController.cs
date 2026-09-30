using Hims.PatientAccess.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.PatientAccess.Controllers;

/// <summary>Lookups the front desk needs, served from this service's ref.* replicas (no call to Identity/Org at request time).</summary>
[ApiController]
[Route("api")]
public class DirectoryController : ControllerBase
{
    private readonly PatientAccessDbContext _db;
    public DirectoryController(PatientAccessDbContext db) => _db = db;

    /// <summary>Branches (ref.branch).</summary>
    [HttpGet("branches")]
    public async Task<IActionResult> Branches(CancellationToken ct) =>
        Ok(await _db.RefBranches.OrderBy(b => b.BranchId).Select(b => new { b.BranchId, b.OrganizationId, b.BranchCode, b.BranchName }).ToListAsync(ct));

    /// <summary>Departments (ref.department).</summary>
    [HttpGet("departments")]
    public async Task<IActionResult> Departments(CancellationToken ct) =>
        Ok(await _db.RefDepartments.OrderBy(d => d.DepartmentId).Select(d => new { d.DepartmentId, d.DeptCode, d.DeptName }).ToListAsync(ct));

    /// <summary>Practitioners (ref.practitioner).</summary>
    [HttpGet("practitioners")]
    public async Task<IActionResult> Practitioners(CancellationToken ct) =>
        Ok(await _db.RefPractitioners.OrderBy(p => p.DisplayName)
            .Select(p => new { p.PractitionerId, p.DisplayName, p.Qualification, p.PrimarySpecialtyId }).ToListAsync(ct));
}
