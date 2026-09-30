using System.Text.Json;

namespace Hims.Common.Events;

/// <summary>
/// The message published to the <c>hims.events</c> RabbitMQ topic exchange (CloudEvents-style, as the data model's
/// <c>evt.outbox</c> comment describes). The routing key is <see cref="Type"/>.
/// </summary>
public sealed class EventEnvelope
{
    public string SpecVersion { get; set; } = "1.0";

    /// <summary>Unique event id (= evt.outbox.event_id). Consumers use it as evt.inbox.message_id for idempotency.</summary>
    public string Id { get; set; } = string.Empty;

    /// <summary>Event name from the data model, e.g. PatientRegistered, OrderPlaced. Also the routing key.</summary>
    public string Type { get; set; } = string.Empty;

    /// <summary>Publishing service, e.g. patient-access.</summary>
    public string Source { get; set; } = string.Empty;

    /// <summary>aggregate_type/aggregate_id, e.g. pat.patient/42.</summary>
    public string? Subject { get; set; }

    public DateTime Time { get; set; }

    /// <summary>Event body (evt.outbox.payload_json).</summary>
    public JsonElement Data { get; set; }

    public int? OrganizationId { get; set; }
    public int? BranchId { get; set; }
    public long? PatientId { get; set; }
    public Guid? CorrelationId { get; set; }
    public string AggregateType { get; set; } = string.Empty;
    public long AggregateId { get; set; }
    public int EventVersion { get; set; } = 1;

    /// <summary>evt.outbox.outbox_id: monotonically increasing per publisher, used to ignore stale ref updates.</summary>
    public long SourceVersion { get; set; }
}
