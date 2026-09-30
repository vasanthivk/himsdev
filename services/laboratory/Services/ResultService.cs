using Hims.Common.Events;
using Hims.Laboratory.Data;
using Microsoft.EntityFrameworkCore;

namespace Hims.Laboratory.Services;

/// <summary>
/// Turns analyzer messages into lab.result rows, verifies them and releases the report:
///   AnalyzerResultReceived -> lab.result (ENTERED) -> VERIFIED (auto, or manual) -> ResultVerified event
///   -> when every ordered test of the order has a result: lab.report (RELEASED) + LabReportReleased event
///   (+ CriticalValueDetected when a critical result is present).
/// Everything is written in the caller's transaction together with the outbox rows.
/// </summary>
public class ResultService
{
    private readonly LaboratoryDbContext _db;
    private readonly IConfiguration _config;
    private readonly ILogger<ResultService> _log;
    public ResultService(LaboratoryDbContext db, IConfiguration config, ILogger<ResultService> log) { _db = db; _config = config; _log = log; }

    public bool AutoVerify => _config.GetValue("Laboratory:AutoVerify", true);

    /// <summary>Stores the analytes of one instrument message against the sample's ordered tests. Returns how many results were stored.</summary>
    public async Task<int> ApplyAnalyzerResultAsync(AnalyzerResultReceivedPayload msg, CancellationToken ct)
    {
        var sample = await _db.Samples.FirstOrDefaultAsync(s => s.SampleBarcode == msg.SampleBarcode, ct)
            ?? throw new InvalidOperationException($"Unknown sample barcode '{msg.SampleBarcode}'");

        // The device identifies itself with HL7 MSH-3 / FHIR Device id = lab.analyzer.sending_application_id (extension column),
        // or simply the analyzer code. Match either, ignoring case (the RabbitMQ routing key is lower-case).
        Analyzer? analyzer = null;
        var deviceId = msg.AnalyzerCode?.Trim().ToLower();
        if (!string.IsNullOrEmpty(deviceId))
            analyzer = await _db.Analyzers.FirstOrDefaultAsync(a => a.OrganizationId == sample.OrganizationId
                && (a.AnalyzerCode.ToLower() == deviceId || (a.SendingApplicationId != null && a.SendingApplicationId.ToLower() == deviceId)), ct);

        var orderItemIds = await _db.SampleOrderItems.Where(x => x.SampleId == sample.SampleId).Select(x => x.OrderItemId).ToListAsync(ct);
        var orderItems = await _db.RefOrderItems.Where(i => orderItemIds.Contains(i.OrderItemId)).ToListAsync(ct);
        var serviceIds = orderItems.Where(i => i.ServiceId != null).Select(i => i.ServiceId!.Value).Distinct().ToList();
        var tests = await _db.LabTests.Where(t => serviceIds.Contains(t.ServiceId)).ToListAsync(ct);
        var testIds = tests.Select(t => t.LabTestId).ToList();
        var parameters = await _db.LabParameters.Where(x => testIds.Contains(x.LabTestId)).ToListAsync(ct);
        var maps = analyzer is null
            ? new List<AnalyzerParameterMap>()
            : await _db.AnalyzerParameterMaps.Where(m => m.AnalyzerId == analyzer.AnalyzerId).ToListAsync(ct);

        var resultedAt = msg.ResultedAt ?? DateTime.UtcNow;
        var stored = 0;
        var unmatched = new List<string>();
        foreach (var a in msg.Analytes)
        {
            // 1) analyzer-specific machine code mapping, 2) otherwise the parameter code (LOINC) itself
            var machineCode = a.MachineTestCode ?? a.ParameterCode;
            var map = maps.FirstOrDefault(m => m.MachineTestCode == machineCode);
            var parameter = map is not null
                ? parameters.FirstOrDefault(x => x.LabParameterId == map.LabParameterId)
                : parameters.FirstOrDefault(x => x.ParameterCode == a.ParameterCode);
            var test = parameter is null ? null : tests.FirstOrDefault(t => t.LabTestId == parameter.LabTestId);
            var item = test is null ? null : orderItems.FirstOrDefault(i => i.ServiceId == test.ServiceId);
            if (parameter is null || item is null) { unmatched.Add(machineCode); continue; }

            var value = a.ValueNumeric;
            if (value.HasValue && map?.ConversionFactor is decimal factor && factor != 0) value = value.Value * factor;

            var previous = await _db.Results
                .Where(r => r.SampleId == sample.SampleId && r.LabParameterId == parameter.LabParameterId && r.OrderItemId == item.OrderItemId)
                .OrderByDescending(r => r.VersionNo).FirstOrDefaultAsync(ct);
            if (previous is not null) previous.ResultStatus = "AMENDED"; // a re-run supersedes the earlier value

            _db.Results.Add(new Result
            {
                OrderItemId = item.OrderItemId, SampleId = sample.SampleId, LabParameterId = parameter.LabParameterId, PatientId = sample.PatientId,
                VersionNo = (previous?.VersionNo ?? 0) + 1, ValueNumeric = value, ValueText = a.ValueText, Unit = a.Unit ?? parameter.Unit,
                ReferenceRangeText = a.ReferenceRangeText, AbnormalFlag = a.AbnormalFlag, IsCritical = a.IsCritical, ResultSource = "ANALYZER",
                AnalyzerId = analyzer?.AnalyzerId, ResultedAt = resultedAt, ResultStatus = "ENTERED",
            });
            stored++;
        }

        if (stored == 0)
            throw new InvalidOperationException($"None of the analytes ({string.Join(", ", unmatched)}) match the tests ordered on sample {msg.SampleBarcode}");
        if (unmatched.Count > 0) _log.LogWarning("Sample {Barcode}: ignored analytes not ordered/mapped: {Codes}", msg.SampleBarcode, string.Join(", ", unmatched));

        sample.SampleStatus = "IN_PROCESS";
        await _db.SaveChangesAsync(ct);
        if (AutoVerify) await VerifyAndReleaseAsync(sample.SampleId, null, ct);
        return stored;
    }

    /// <summary>Verifies the entered results of a sample, publishes ResultVerified, and releases the order's report when complete.</summary>
    public async Task VerifyAndReleaseAsync(long sampleId, long? verifiedBy, CancellationToken ct)
    {
        var sample = await _db.Samples.FirstOrDefaultAsync(s => s.SampleId == sampleId, ct) ?? throw new InvalidOperationException($"Sample {sampleId} not found");
        var now = DateTime.UtcNow;

        var current = await _db.Results.Where(r => r.SampleId == sampleId && r.ResultStatus != "AMENDED" && r.ResultStatus != "CANCELLED").ToListAsync(ct);
        if (current.Count == 0) throw new InvalidOperationException($"Sample {sample.SampleBarcode} has no results to verify");
        foreach (var r in current.Where(r => r.ResultStatus == "ENTERED")) { r.ResultStatus = "VERIFIED"; r.VerifiedAt = now; r.VerifiedBy = verifiedBy; }

        var sampleItemIds = await _db.SampleOrderItems.Where(x => x.SampleId == sampleId).Select(x => x.OrderItemId).ToListAsync(ct);
        var resultedItemIds = current.Select(r => r.OrderItemId).Distinct().ToList();
        sample.SampleStatus = sampleItemIds.All(id => resultedItemIds.Contains(id)) ? "COMPLETED" : "IN_PROCESS";
        await _db.SaveChangesAsync(ct);

        var order = await _db.RefClinicalOrders.FirstOrDefaultAsync(o => o.OrderId == sample.OrderId, ct);
        var results = await ToPayloadAsync(current, ct);
        _db.EnqueueEvent("ResultVerified", "lab.sample", sample.SampleId,
            new ResultVerifiedPayload(sample.SampleId, sample.SampleBarcode, sample.OrderId, sample.PatientId, order?.EncounterId, resultedItemIds, results),
            sample.OrganizationId, sample.BranchId, sample.PatientId);

        var critical = results.Where(r => r.IsCritical).ToList();
        if (critical.Count > 0)
            _db.EnqueueEvent("CriticalValueDetected", "lab.sample", sample.SampleId,
                new ResultVerifiedPayload(sample.SampleId, sample.SampleBarcode, sample.OrderId, sample.PatientId, order?.EncounterId, resultedItemIds, critical),
                sample.OrganizationId, sample.BranchId, sample.PatientId);

        await ReleaseReportIfCompleteAsync(sample, order?.EncounterId, now, verifiedBy, ct);
        await _db.SaveChangesAsync(ct);
    }

    /// <summary>The order's report is released once every (non-cancelled) ordered test has a current result.</summary>
    private async Task ReleaseReportIfCompleteAsync(Sample sample, long? encounterId, DateTime now, long? signedBy, CancellationToken ct)
    {
        var orderItemIds = await _db.RefOrderItems.Where(i => i.OrderId == sample.OrderId && i.ItemStatus != "CANCELLED").Select(i => i.OrderItemId).ToListAsync(ct);
        var sampleIds = await _db.Samples.Where(s => s.OrderId == sample.OrderId).Select(s => s.SampleId).ToListAsync(ct);
        var orderResults = await _db.Results.Where(r => r.SampleId != null && sampleIds.Contains(r.SampleId.Value) && (r.ResultStatus == "VERIFIED" || r.ResultStatus == "RELEASED")).ToListAsync(ct);
        var covered = orderResults.Select(r => r.OrderItemId).Distinct().ToList();
        if (orderItemIds.Count == 0 || !orderItemIds.All(id => covered.Contains(id))) return;

        var firstCollected = await _db.Samples.Where(s => s.OrderId == sample.OrderId && s.CollectedAt != null).Select(s => s.CollectedAt).OrderBy(x => x).FirstOrDefaultAsync(ct);
        var version = await _db.Reports.CountAsync(r => r.OrderId == sample.OrderId, ct) + 1;
        var report = new Report
        {
            OrganizationId = sample.OrganizationId, BranchId = sample.BranchId, OrderId = sample.OrderId, PatientId = sample.PatientId,
            VersionNo = version, TechnicianSignedBy = signedBy, SignedAt = now, ReleasedAt = now,
            TatMinutes = firstCollected is null ? null : (int)Math.Round((now - firstCollected.Value).TotalMinutes),
            DispatchStatus = "PENDING", ReportStatus = "RELEASED",
        };
        _db.Reports.Add(report);
        foreach (var r in orderResults.Where(r => r.ResultStatus == "VERIFIED")) r.ResultStatus = "RELEASED";
        await _db.SaveChangesAsync(ct);

        var payload = new LabReportReleasedPayload(report.LabReportId, sample.OrderId, sample.PatientId, encounterId, sample.SampleId, sample.SampleBarcode, now,
            await ToPayloadAsync(orderResults, ct));
        _db.EnqueueEvent("LabReportReleased", "lab.report", report.LabReportId, payload, sample.OrganizationId, sample.BranchId, sample.PatientId);
    }

    private async Task<List<LabResultPayload>> ToPayloadAsync(List<Result> results, CancellationToken ct)
    {
        var paramIds = results.Select(r => r.LabParameterId).Distinct().ToList();
        var parameters = await _db.LabParameters.Where(p => paramIds.Contains(p.LabParameterId)).ToListAsync(ct);
        var analyzerIds = results.Where(r => r.AnalyzerId != null).Select(r => r.AnalyzerId!.Value).Distinct().ToList();
        var analyzers = await _db.Analyzers.Where(a => analyzerIds.Contains(a.AnalyzerId)).ToListAsync(ct);
        return results.Select(r =>
        {
            var p = parameters.First(x => x.LabParameterId == r.LabParameterId);
            return new LabResultPayload(r.ResultId, r.OrderItemId, r.LabParameterId, p.ParameterCode, p.ParameterName, r.ValueNumeric, r.ValueText, r.Unit,
                r.ReferenceRangeText, r.AbnormalFlag, r.IsCritical, r.ResultedAt, analyzers.FirstOrDefault(a => a.AnalyzerId == r.AnalyzerId)?.AnalyzerCode);
        }).ToList();
    }
}
