using Hims.Common.Data;
using Hims.Common.Events;
using Hims.RevenueCycle.Data;
using Microsoft.EntityFrameworkCore;

namespace Hims.RevenueCycle.Services;

/// <summary>Business-rule failure that maps to HTTP 400.</summary>
public class BillingException : Exception { public BillingException(string message) : base(message) { } }

public record BillLineRequest(int? ServiceId, string? ServiceCode, decimal Quantity = 1, long? OrderItemId = null, long? PerformingPractitionerId = null);
public record BillRequest(int OrganizationId, int BranchId, long PatientId, long? EncounterId, string BillType, IReadOnlyList<BillLineRequest> Lines);
public record PayRequest(decimal? Amount, string PaymentMode, string? ReferenceNo, long? CashierId);

/// <summary>Charge capture, tariff pricing, billing and receipts (bil.bill, bil.bill_line, bil.receipt*).</summary>
public class BillingService
{
    private readonly RevenueCycleDbContext _db;
    private readonly ISequenceService _seq;
    public BillingService(RevenueCycleDbContext db, ISequenceService seq) { _db = db; _seq = seq; }

    /// <summary>The tariff plan that prices this encounter: the encounter's own plan, else the organization's active GENERAL plan.</summary>
    public async Task<int> ResolveTariffPlanAsync(int organizationId, long? encounterId, CancellationToken ct)
    {
        if (encounterId is not null)
        {
            var enc = await _db.RefEncounters.FirstOrDefaultAsync(e => e.EncounterId == encounterId, ct);
            if (enc?.TariffPlanId is int own) return own;
        }
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var plan = await _db.TariffPlans
            .Where(p => p.OrganizationId == organizationId && p.PlanType == "GENERAL" && p.ValidFrom <= today && (p.ValidTo == null || p.ValidTo >= today))
            .OrderBy(p => p.TariffPlanId).Select(p => (int?)p.TariffPlanId).FirstOrDefaultAsync(ct);
        return plan ?? throw new BillingException($"No active GENERAL tariff plan for organization {organizationId}. Run database/deploy.sh (seed) first.");
    }

    public async Task<decimal> RateAsync(int tariffPlanId, int serviceId, CancellationToken ct)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var rate = await _db.TariffRates
            .Where(r => r.TariffPlanId == tariffPlanId && r.ServiceId == serviceId && r.ValidFrom <= today && (r.ValidTo == null || r.ValidTo >= today))
            .OrderByDescending(r => r.ValidFrom).Select(r => (decimal?)r.Rate).FirstOrDefaultAsync(ct);
        return rate ?? throw new BillingException($"No tariff rate for service {serviceId} in plan {tariffPlanId}");
    }

    /// <summary>
    /// Prices the lines from mst.tariff_rate, writes bil.bill + bil.bill_line (status FINALISED = charges final, awaiting payment)
    /// and publishes BillFinalised (plus ChargePosted when lines come from clinical orders). Joins the caller's transaction if any.
    /// </summary>
    public async Task<Bill> CreateBillAsync(BillRequest req, CancellationToken ct)
    {
        if (req.Lines.Count == 0) throw new BillingException("A bill needs at least one line");
        await using var own = _db.Database.CurrentTransaction is null ? await _db.Database.BeginTransactionAsync(ct) : null;

        var planId = await ResolveTariffPlanAsync(req.OrganizationId, req.EncounterId, ct);
        var now = DateTime.UtcNow;
        var lines = new List<BillLine>();
        foreach (var l in req.Lines)
        {
            var svc = l.ServiceId is not null
                ? await _db.Services.FirstOrDefaultAsync(s => s.ServiceId == l.ServiceId, ct)
                : await _db.Services.FirstOrDefaultAsync(s => s.OrganizationId == req.OrganizationId && s.ServiceCode == l.ServiceCode, ct);
            if (svc is null) throw new BillingException($"Unknown service {(l.ServiceId?.ToString() ?? l.ServiceCode)}");
            if (!svc.IsBillable) throw new BillingException($"Service {svc.ServiceCode} is not billable");
            if (l.Quantity <= 0) throw new BillingException("Quantity must be positive");

            var rate = await RateAsync(planId, svc.ServiceId, ct);
            var gross = Math.Round(l.Quantity * rate, 2);
            var tax = Math.Round(gross * svc.GstRate / 100m, 2);
            lines.Add(new BillLine
            {
                LineSource = "SERVICE", ServiceId = svc.ServiceId, OrderItemId = l.OrderItemId, DepartmentId = svc.DepartmentId,
                PerformingPractitionerId = l.PerformingPractitionerId, ServiceDate = now, Description = svc.ServiceName,
                Quantity = l.Quantity, UnitRate = rate, GrossAmount = gross, HsnSacCode = svc.SacCode, GstRate = svc.GstRate,
                TaxAmount = tax, NetAmount = gross + tax, PatientShare = gross + tax,
            });
        }

        var totalGross = lines.Sum(x => x.GrossAmount);
        var totalTax = lines.Sum(x => x.TaxAmount);
        var exact = totalGross + totalTax;
        var net = Math.Round(exact, 0, MidpointRounding.AwayFromZero);
        var (seqCode, prefix) = req.BillType switch { "LAB" => ("LAB_BILL", "LAB"), "RADIOLOGY" => ("RAD_BILL", "RAD"), _ => ("OP_BILL", "OPB") };

        var bill = new Bill
        {
            OrganizationId = req.OrganizationId, BranchId = req.BranchId,
            BillNo = await _seq.NextAsync(_db, req.OrganizationId, req.BranchId, seqCode, prefix, ct),
            BillType = req.BillType, PatientId = req.PatientId, EncounterId = req.EncounterId, TariffPlanId = planId, BillDate = now,
            GrossAmount = totalGross, TaxableAmount = totalGross, CgstAmount = Math.Round(totalTax / 2, 2), SgstAmount = totalTax - Math.Round(totalTax / 2, 2),
            RoundOff = net - exact, NetAmount = net, PatientAmount = net, PaidAmount = 0, DueAmount = net,
            BillStatus = "FINALISED", FinalisedAt = now,
        };
        _db.Bills.Add(bill);
        await _db.SaveChangesAsync(ct);

        foreach (var line in lines) { line.BillId = bill.BillId; _db.BillLines.Add(line); }
        await _db.SaveChangesAsync(ct);

        var payload = ToPayload(bill, lines);
        if (lines.Any(x => x.OrderItemId is not null))
            _db.EnqueueEvent("ChargePosted", "bil.bill", bill.BillId, payload, bill.OrganizationId, bill.BranchId, bill.PatientId);
        _db.EnqueueEvent("BillFinalised", "bil.bill", bill.BillId, payload, bill.OrganizationId, bill.BranchId, bill.PatientId);
        await _db.SaveChangesAsync(ct);

        if (own is not null) await own.CommitAsync(ct);
        return bill;
    }

    /// <summary>Takes a payment: bil.receipt + bil.receipt_tender + bil.receipt_allocation, updates the bill, publishes PaymentReceived.</summary>
    public async Task<(Receipt Receipt, Bill Bill)> PayAsync(long billId, PayRequest req, CancellationToken ct)
    {
        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        var bill = await _db.Bills.FirstOrDefaultAsync(b => b.BillId == billId, ct) ?? throw new BillingException($"Bill {billId} not found");
        if (bill.BillStatus is "SETTLED" or "CANCELLED" or "REFUNDED") throw new BillingException($"Bill {bill.BillNo} is {bill.BillStatus}");

        var amount = req.Amount ?? bill.DueAmount;
        if (amount <= 0) throw new BillingException("Payment amount must be positive");
        if (amount > bill.DueAmount) throw new BillingException($"Amount {amount} exceeds the amount due {bill.DueAmount}");

        var receipt = new Receipt
        {
            OrganizationId = bill.OrganizationId, BranchId = bill.BranchId,
            ReceiptNo = await _seq.NextAsync(_db, bill.OrganizationId, bill.BranchId, "RECEIPT", "RCT", ct),
            ReceiptType = "PAYMENT", PatientId = bill.PatientId, EncounterId = bill.EncounterId, ReceiptAt = DateTime.UtcNow,
            Amount = amount, CashierId = req.CashierId, ReceiptStatus = "POSTED",
        };
        _db.Receipts.Add(receipt);
        await _db.SaveChangesAsync(ct);

        _db.ReceiptTenders.Add(new ReceiptTender { ReceiptId = receipt.ReceiptId, PaymentMode = req.PaymentMode, Amount = amount, ReferenceNo = req.ReferenceNo });
        _db.ReceiptAllocations.Add(new ReceiptAllocation { ReceiptId = receipt.ReceiptId, BillId = bill.BillId, AllocatedAmount = amount });

        bill.PaidAmount += amount;
        bill.DueAmount -= amount;
        bill.BillStatus = bill.DueAmount == 0 ? "SETTLED" : "PARTIALLY_PAID";
        await _db.SaveChangesAsync(ct);

        var orderItemIds = await _db.BillLines.Where(l => l.BillId == bill.BillId && l.OrderItemId != null).Select(l => l.OrderItemId!.Value).ToListAsync(ct);
        _db.EnqueueEvent("PaymentReceived", "bil.receipt", receipt.ReceiptId,
            new PaymentReceivedPayload(receipt.ReceiptId, receipt.ReceiptNo, bill.BillId, bill.BillNo, bill.PatientId, bill.EncounterId, amount,
                req.PaymentMode, bill.BillStatus, bill.PaidAmount, bill.DueAmount, orderItemIds),
            bill.OrganizationId, bill.BranchId, bill.PatientId);
        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        return (receipt, bill);
    }

    public static BillPayload ToPayload(Bill b, IEnumerable<BillLine> lines) =>
        new(b.BillId, b.BillNo, b.BillType, b.PatientId, b.EncounterId, b.GrossAmount, b.NetAmount, b.PaidAmount, b.DueAmount, b.BillStatus,
            lines.Select(l => new BillLinePayload(l.BillLineId, l.ServiceId, l.OrderItemId, l.Description, l.Quantity, l.UnitRate, l.NetAmount)).ToList());
}
