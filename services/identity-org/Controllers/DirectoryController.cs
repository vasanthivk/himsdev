using Hims.IdentityOrg.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.IdentityOrg.Controllers;

/// <summary>Read-only directory of organization, branches, departments and practitioners.</summary>
[ApiController]
[Route("api")]
public class DirectoryController : ControllerBase
{
    private readonly IdentityOrgDbContext _db;
    public DirectoryController(IdentityOrgDbContext db) => _db = db;

    /// <summary>Organizations (core.organization).</summary>
    [HttpGet("organizations")]
    public async Task<IActionResult> Organizations(CancellationToken ct) =>
        Ok(await _db.Organizations.OrderBy(o => o.OrganizationId)
            .Select(o => new { o.OrganizationId, o.OrgCode, o.OrgName, o.LegalName }).ToListAsync(ct));

    /// <summary>Branches (core.branch).</summary>
    [HttpGet("branches")]
    public async Task<IActionResult> Branches(CancellationToken ct) =>
        Ok(await _db.Branches.OrderBy(b => b.BranchId)
            .Select(b => new { b.BranchId, b.OrganizationId, b.BranchCode, b.BranchName, b.BranchType, b.City, b.StateCode }).ToListAsync(ct));

    /// <summary>Departments (mst.department).</summary>
    [HttpGet("departments")]
    public async Task<IActionResult> Departments(CancellationToken ct) =>
        Ok(await _db.Departments.OrderBy(d => d.DepartmentId)
            .Select(d => new { d.DepartmentId, d.OrganizationId, d.DeptCode, d.DeptName, d.DeptType }).ToListAsync(ct));

    /// <summary>Practitioner registry (hr.practitioner).</summary>
    [HttpGet("practitioners")]
    public async Task<IActionResult> Practitioners(CancellationToken ct) =>
        Ok(await _db.Practitioners.OrderBy(p => p.DisplayName)
            .Select(p => new { p.PractitionerId, p.OrganizationId, p.DisplayName, p.PractitionerType, p.PrimarySpecialtyId, p.Qualification, p.RegistrationNo, p.DefaultConsultFee }).ToListAsync(ct));
}
