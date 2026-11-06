namespace Hims.Common.Events;

// Event payload contracts shared by the .NET services. The JSON is camelCase (see EventJson); docs/EVENTS.md lists the same
// shapes for the Python Integration Hub. Row-shaped events (PatientRegistered, EncounterStarted, *Updated) carry the full
// source table row instead, so that any ref.* table can copy the columns it needs by name.

public record OrderItemPayload(
    long OrderItemId, long OrderId, int ServiceId, string? ServiceCode, string? ServiceName, decimal Quantity,
    string ItemStatus, bool IsBilled, int? PerformingBranchId, int? PerformingDepartmentId, string? Instructions);

/// <summary>OrderPlaced (Clinical Care). Order columns are top-level so ref.clinical_order can be filled by name; items[] fills ref.order_item.</summary>
public record OrderPlacedPayload(
    long OrderId, int OrganizationId, int BranchId, string OrderNo, long PatientId, long? EncounterId, string OrderCategory,
    string Priority, long? OrderingPractitionerId, long? DiagnosisId, int? B2bPayerId, string OrderStatus, DateTime OrderedAt,
    IReadOnlyList<OrderItemPayload> Items);

public record BillLinePayload(long BillLineId, int? ServiceId, long? OrderItemId, string Description, decimal Quantity, decimal UnitRate, decimal NetAmount);

/// <summary>ChargePosted / BillFinalised (Revenue Cycle).</summary>
public record BillPayload(
    long BillId, string BillNo, string BillType, long? PatientId, long? EncounterId, decimal GrossAmount, decimal NetAmount,
    decimal PaidAmount, decimal DueAmount, string BillStatus, IReadOnlyList<BillLinePayload> Lines);

/// <summary>PaymentReceived (Revenue Cycle).</summary>
public record PaymentReceivedPayload(
    long ReceiptId, string ReceiptNo, long BillId, string BillNo, long? PatientId, long? EncounterId, decimal Amount,
    string PaymentMode, string BillStatus, decimal PaidAmount, decimal DueAmount, IReadOnlyList<long> OrderItemIds);

public record SampleCollectedPayload(long SampleId, string SampleBarcode, long OrderId, long PatientId, long? EncounterId, IReadOnlyList<long> OrderItemIds, DateTime CollectedAt);

public record AnalyteResult(
    string ParameterCode, string? MachineTestCode, string? ParameterName, decimal? ValueNumeric, string? ValueText,
    string? Unit, string? ReferenceRangeText, string? AbnormalFlag, bool IsCritical);

/// <summary>AnalyzerResultReceived (published by the Python Integration Hub after it parses an HL7 v2/v3 or FHIR message from a device).</summary>
public record AnalyzerResultReceivedPayload(
    string SampleBarcode, string? AnalyzerCode, string? SourceMessageId, string? MessageType, DateTime? ResultedAt,
    long? MessageLogId, IReadOnlyList<AnalyteResult> Analytes);

public record LabResultPayload(
    long ResultId, long OrderItemId, int ParameterId, string ParameterCode, string ParameterName, decimal? ValueNumeric,
    string? ValueText, string? Unit, string? ReferenceRangeText, string? AbnormalFlag, bool IsCritical, DateTime? ResultedAt, string? AnalyzerCode);

/// <summary>ResultVerified (Laboratory).</summary>
public record ResultVerifiedPayload(
    long SampleId, string SampleBarcode, long OrderId, long PatientId, long? EncounterId,
    IReadOnlyList<long> OrderItemIds, IReadOnlyList<LabResultPayload> Results);

/// <summary>
/// ConsultationCompleted (Clinical Care): the doctor finished the visit. Patient Access, which owns the encounter, closes it and
/// publishes EncounterClosed.
/// </summary>
public record ConsultationCompletedPayload(long EncounterId, long? PatientId, long? PractitionerId, DateTime CompletedAt);

/// <summary>LabReportReleased / CriticalValueDetected (Laboratory).</summary>
public record LabReportReleasedPayload(
    long LabReportId, long OrderId, long PatientId, long? EncounterId, long SampleId, string SampleBarcode,
    DateTime ReleasedAt, IReadOnlyList<LabResultPayload> Results);

public record PrescriptionItemPayload(
    long PrescriptionItemId, string? DrugText, decimal? Dose, string? DoseUnit, string? Route, string Frequency, string? Timing,
    int? DurationValue, string? DurationUnit, decimal? Quantity, string? Instructions);

/// <summary>PrescriptionIssued (Clinical Care).</summary>
public record PrescriptionIssuedPayload(
    long PrescriptionId, string PrescriptionNo, long PatientId, long? EncounterId, long PractitionerId, DateTime PrescribedAt,
    string? Advice, DateOnly? FollowupDate, IReadOnlyList<PrescriptionItemPayload> Items);
