using System.ComponentModel.DataAnnotations;
using Hims.RevenueCycle.Data;
using Hims.RevenueCycle.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.RevenueCycle.Controllers;

public class CreateBillLine
{
    /// <summary>Either serviceId or serviceCode (e.g. REG-FEE, CONS-GM).</summary>
    public int? ServiceId { get; set; }
    public string? ServiceCode { get; set; }
    public decimal Quantity { get; set; } = 1;
}

public class CreateBillRequest
{
    [Required] public long PatientId { get; set; }
    public long? EncounterId { get; set; }
    [Required] public int BranchId { get; set; }
    /// <summary>OPD, LAB, RADIOLOGY, PHARMACY, MISC ...</summary>
    public string BillType { get; set; } = "OPD";
    [Required, MinLength(1)] public List<CreateBillLine> Lines { get; set; } = new();
}

public class PayBillRequest
{
    /// <summary>Defaults to the full amount due.</summary>
    public decimal? Amount { get; set; }
    /// <summary>CASH, CARD, UPI, CHEQUE, NEFT, ...</summary>
    [Required] public string PaymentMode { get; set; } = "CASH";
    public string? ReferenceNo { get; set; }
    public long? CashierId { get; set; }
}

/// <summary>Bills and payments (bil.bill, bil.bill_line, bil.receipt).</summary>
[ApiController]
[Route("api/bills")]
public class BillsController : ControllerBase
{
    private readonly RevenueCycleDbContext _db;
    private readonly BillingService _billing;
    public BillsController(RevenueCycleDbContext db, BillingService billing) { _db = db; _billing = billing; }

    /// <summary>
    /// Raises a bill for services picked at the counter (registration fee, consultation fee, ...). Lab bills are raised
    /// automatically from the OrderPlaced event. Returns 409 while the patient is not yet replicated into ref.patient (retry shortly).
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateBillRequest req, CancellationToken ct)
    {
        var branch = await _db.RefBranches.FirstOrDefaultAsync(b => b.BranchId == req.BranchId, ct);
        if (branch?.OrganizationId is null) return BadRequest(new { error = $"Branch {req.BranchId} is unknown (load reference data first)" });
        if (!await _db.RefPatients.AnyAsync(p => p.PatientId == req.PatientId, ct))
            return Conflict(new { error = $"Patient {req.PatientId} has not been replicated into Revenue Cycle yet; retry in a moment." });

        try
        {
            var lines = req.Lines.Select(l => new BillLineRequest(l.ServiceId, l.ServiceCode, l.Quantity)).ToList();
            var bill = await _billing.CreateBillAsync(new BillRequest(branch.OrganizationId.Value, req.BranchId, req.PatientId, req.EncounterId, req.BillType, lines), ct);
            return CreatedAtAction(nameof(Get), new { id = bill.BillId }, bill);
        }
        catch (BillingException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>Takes a (full or part) payment against a bill.</summary>
    [HttpPost("{id:long}/pay")]
    public async Task<IActionResult> Pay(long id, [FromBody] PayBillRequest req, CancellationToken ct)
    {
        try
        {
            var (receipt, bill) = await _billing.PayAsync(id, new PayRequest(req.Amount, req.PaymentMode, req.ReferenceNo, req.CashierId), ct);
            return Ok(new { receipt.ReceiptId, receipt.ReceiptNo, receipt.Amount, bill.BillId, bill.BillNo, bill.BillStatus, bill.PaidAmount, bill.DueAmount });
        }
        catch (BillingException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>One bill with its lines and receipts.</summary>
    [HttpGet("{id:long}")]
    public async Task<IActionResult> Get(long id, CancellationToken ct)
    {
        var bill = await _db.Bills.FirstOrDefaultAsync(b => b.BillId == id, ct);
        if (bill is null) return NotFound();
        var lines = await _db.BillLines.Where(l => l.BillId == id).OrderBy(l => l.BillLineId).ToListAsync(ct);
        var receipts = await (from a in _db.ReceiptAllocations
                              join r in _db.Receipts on a.ReceiptId equals r.ReceiptId
                              where a.BillId == id
                              orderby r.ReceiptId
                              select new { r.ReceiptId, r.ReceiptNo, r.ReceiptAt, a.AllocatedAmount }).ToListAsync(ct);
        return Ok(new { bill, lines, receipts });
    }

    /// <summary>List bills, newest first. Filter by patientId, encounterId and/or status (FINALISED, PARTIALLY_PAID, SETTLED ...).</summary>
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] long? patientId, [FromQuery] long? encounterId, [FromQuery] string? status, CancellationToken ct)
    {
        var q = _db.Bills.AsQueryable();
        if (patientId is not null) q = q.Where(b => b.PatientId == patientId);
        if (encounterId is not null) q = q.Where(b => b.EncounterId == encounterId);
        if (!string.IsNullOrEmpty(status)) q = q.Where(b => b.BillStatus == status);
        var list = await q.OrderByDescending(b => b.BillId).Take(50).ToListAsync(ct);
        var pids = list.Where(b => b.PatientId != null).Select(b => b.PatientId!.Value).Distinct().ToList();
        var patients = await _db.RefPatients.Where(p => pids.Contains(p.PatientId)).ToListAsync(ct);
        return Ok(list.Select(b =>
        {
            var p = patients.FirstOrDefault(x => x.PatientId == b.PatientId);
            return new
            {
                b.BillId, b.BillNo, b.BillType, b.PatientId, PatientName = p is null ? null : $"{p.FirstName} {p.LastName}".Trim(), Uhid = p?.Uhid,
                b.EncounterId, b.BillDate, b.NetAmount, b.PaidAmount, b.DueAmount, b.BillStatus,
            };
        }));
    }

    /// <summary>Payment status of the bill that carries a clinical order item (used by the lab before collecting a sample).</summary>
    [HttpGet("by-order-item/{orderItemId:long}")]
    public async Task<IActionResult> ByOrderItem(long orderItemId, CancellationToken ct)
    {
        var line = await _db.BillLines.FirstOrDefaultAsync(l => l.OrderItemId == orderItemId, ct);
        if (line is null) return NotFound(new { error = "Not billed yet" });
        var b = await _db.Bills.FirstAsync(x => x.BillId == line.BillId, ct);
        return Ok(new { b.BillId, b.BillNo, b.BillStatus, b.NetAmount, b.PaidAmount, b.DueAmount, isPaid = b.BillStatus == "SETTLED" });
    }
}
