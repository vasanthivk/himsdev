namespace Hims.Common.Events;

/// <summary>
/// Handles one event type. Resolved from a per-message DI scope, so it can take the service's DbContext; the consumer
/// wraps the handler and the evt.inbox insert in one database transaction (idempotent consumer).
/// </summary>
public interface IEventHandler
{
    string EventType { get; }
    Task HandleAsync(EventEnvelope envelope, CancellationToken ct);
}
