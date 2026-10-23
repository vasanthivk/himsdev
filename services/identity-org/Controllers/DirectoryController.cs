using Hims.IdentityOrg.Data;
using Hims.IdentityOrg.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.IdentityOrg.Controllers;

/// <summary>
/// Read-only directory of organization, branches, departments and practitioners. Called from a tenant's site (e.g.
/// apollo.localhost), only that tenant's organization is returned (Wso2UserManagement:Tenants OrganizationId).
/// </summary>
[ApiController]
[Route("api")]
public class DirectoryController : ControllerBase
{
    private readonly IdentityOrgDbContext _db;
    private readonly Wso2UserManagementOptions _tenants;
    public DirectoryController(IdentityOrgDbContext db, Wso2UserManagementOptions tenants) { _db = db; _tenants = tenants; }

    private int? Org => _tenants.OrganizationIdFor(Request);

    /// <summary>Organizations (core.organization).</summary>
    [HttpGet("organizations")]
    public async Task<IActionResult> Organizations(CancellationToken ct) =>
        Ok(await _db.Organizations.Where(o => Org == null || o.OrganizationId == Org).OrderBy(o => o.OrganizationId)
            .Select(o => new { o.OrganizationId, o.OrgCode, o.OrgName, o.LegalName }).ToListAsync(ct));

    /// <summary>Branches (core.branch).</summary>
    [HttpGet("branches")]
    public async Task<IActionResult> Branches(CancellationToken ct) =>
        Ok(await _db.Branches.Where(b => Org == null || b.OrganizationId == Org).OrderBy(b => b.BranchId)
            .Select(b => new { b.BranchId, b.OrganizationId, b.BranchCode, b.BranchName, b.BranchType, b.City, b.StateCode }).ToListAsync(ct));

    /// <summary>Departments (mst.department).</summary>
    [HttpGet("departments")]
    public async Task<IActionResult> Departments(CancellationToken ct) =>
        Ok(await _db.Departments.Where(d => Org == null || d.OrganizationId == Org).OrderBy(d => d.DepartmentId)
            .Select(d => new { d.DepartmentId, d.OrganizationId, d.DeptCode, d.DeptName, d.DeptType }).ToListAsync(ct));

    /// <summary>Practitioner registry (hr.practitioner).</summary>
    [HttpGet("practitioners")]
    public async Task<IActionResult> Practitioners(CancellationToken ct) =>
        Ok(await _db.Practitioners.Where(p => Org == null || p.OrganizationId == Org).OrderBy(p => p.DisplayName)
            .Select(p => new { p.PractitionerId, p.OrganizationId, p.DisplayName, p.PractitionerType, p.PrimarySpecialtyId, p.Qualification, p.RegistrationNo, p.DefaultConsultFee }).ToListAsync(ct));
}
