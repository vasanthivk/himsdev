using Hims.RevenueCycle.Data;
using Hims.RevenueCycle.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.RevenueCycle.Controllers;

/// <summary>Chargemaster: the service catalogue (mst.service) with the price from the default tariff.</summary>
[ApiController]
[Route("api/services")]
public class ServicesController : ControllerBase
{
    private readonly RevenueCycleDbContext _db;
    private readonly BillingService _billing;
    public ServicesController(RevenueCycleDbContext db, BillingService billing) { _db = db; _billing = billing; }

    /// <summary>Lists services with their current rate. Filter by category code (REGISTRATION, CONSULTATION, LABORATORY), service type (LAB_TEST, ...) or text.</summary>
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] string? category, [FromQuery] string? type, [FromQuery] string? q, CancellationToken ct)
    {
        var query = from s in _db.Services
                    join c in _db.ServiceCategories on s.ServiceCategoryId equals c.ServiceCategoryId
                    select new { s.ServiceId, s.OrganizationId, s.ServiceCode, s.ServiceName, s.ServiceType, CategoryCode = c.CategoryCode, s.GstRate, s.IsOrderable, s.IsBillable };
        if (!string.IsNullOrEmpty(category)) query = query.Where(x => x.CategoryCode == category);
        if (!string.IsNullOrEmpty(type)) query = query.Where(x => x.ServiceType == type);
        if (!string.IsNullOrEmpty(q)) { var l = q.ToLower(); query = query.Where(x => x.ServiceName.ToLower().Contains(l) || x.ServiceCode.ToLower().Contains(l)); }
        var services = await query.OrderBy(x => x.ServiceId).ToListAsync(ct);

        var result = new List<object>();
        foreach (var s in services)
        {
            decimal? rate = null;
            try { rate = await _billing.RateAsync(await _billing.ResolveTariffPlanAsync(s.OrganizationId, null, ct), s.ServiceId, ct); }
            catch (BillingException) { /* no rate configured: shown without a price */ }
            result.Add(new { s.ServiceId, s.ServiceCode, s.ServiceName, s.ServiceType, s.CategoryCode, s.GstRate, s.IsOrderable, s.IsBillable, rate });
        }
        return Ok(result);
    }
}
