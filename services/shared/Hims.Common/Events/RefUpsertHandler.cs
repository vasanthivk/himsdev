using System.ComponentModel.DataAnnotations;
using System.Reflection;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;

namespace Hims.Common.Events;

/// <summary>
/// Fills a <c>ref.*</c> read-model table from an event, exactly as the data model describes: "eventually consistent copies
/// of other services' data ... filled only by event handlers, carry source_version so stale events can be ignored".
/// Properties of <typeparamref name="TRef"/> are matched by name against the camelCase keys of the event payload; keys the
/// ref table does not have are ignored, so a publisher can send the full source row.
/// </summary>
public sealed class RefUpsertHandler<TDb, TRef> : IEventHandler where TDb : DbContext where TRef : class, new()
{
    private static readonly PropertyInfo[] Props = typeof(TRef).GetProperties(BindingFlags.Public | BindingFlags.Instance);
    private static readonly PropertyInfo KeyProp = Props.Single(p => p.GetCustomAttribute<KeyAttribute>() != null);
    private static readonly PropertyInfo? SourceVersionProp = Props.FirstOrDefault(p => p.Name == "SourceVersion");
    private static readonly PropertyInfo? ReplicatedAtProp = Props.FirstOrDefault(p => p.Name == "ReplicatedAt");

    private readonly TDb _db;
    private readonly string? _collectionProperty;

    /// <param name="collectionProperty">When set, the payload property of that name is an array and EACH element is
    /// upserted (used for e.g. OrderPlaced.items -> ref.order_item). When null the payload itself is the row.</param>
    public RefUpsertHandler(TDb db, string eventType, string? collectionProperty = null)
    {
        _db = db;
        EventType = eventType;
        _collectionProperty = collectionProperty;
    }

    public string EventType { get; }

    public async Task HandleAsync(EventEnvelope envelope, CancellationToken ct)
    {
        if (_collectionProperty is null)
        {
            await UpsertAsync(envelope.Data, envelope.SourceVersion, ct);
            return;
        }
        if (envelope.Data.ValueKind != JsonValueKind.Object ||
            !envelope.Data.TryGetProperty(_collectionProperty, out var items) || items.ValueKind != JsonValueKind.Array) return;
        foreach (var item in items.EnumerateArray()) await UpsertAsync(item, envelope.SourceVersion, ct);
    }

    private async Task UpsertAsync(JsonElement data, long sourceVersion, CancellationToken ct)
    {
        if (data.ValueKind != JsonValueKind.Object) return;

        if (!data.TryGetProperty(EventJson.CamelCase(KeyProp.Name), out var keyElement))
            throw new InvalidOperationException($"{EventType} payload has no '{EventJson.CamelCase(KeyProp.Name)}' for {typeof(TRef).Name}");
        var key = keyElement.Deserialize(KeyProp.PropertyType, EventJson.Options)!;

        var entity = await _db.Set<TRef>().FindAsync(new[] { key }, ct);
        var isNew = entity is null;

        if (!isNew && SourceVersionProp is not null && sourceVersion > 0)
        {
            var current = (long?)SourceVersionProp.GetValue(entity);
            if (current.HasValue && current.Value >= sourceVersion) return; // stale event
        }

        entity ??= new TRef();
        foreach (var p in Props)
        {
            if (!p.CanWrite || p == SourceVersionProp || p == ReplicatedAtProp) continue;
            if (!data.TryGetProperty(EventJson.CamelCase(p.Name), out var value)) continue;

            var underlying = Nullable.GetUnderlyingType(p.PropertyType);
            if (value.ValueKind == JsonValueKind.Null)
            {
                if (p.PropertyType.IsValueType && underlying is null) continue; // NOT NULL column: keep existing/default
                p.SetValue(entity, null);
            }
            else
            {
                p.SetValue(entity, value.Deserialize(p.PropertyType, EventJson.Options));
            }
        }
        SourceVersionProp?.SetValue(entity, sourceVersion);
        ReplicatedAtProp?.SetValue(entity, DateTime.UtcNow);

        if (isNew) _db.Set<TRef>().Add(entity);
        await _db.SaveChangesAsync(ct);
    }
}
