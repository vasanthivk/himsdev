using System.Text.Json;
using Hims.Common.Events;
using Hims.Laboratory.Data;

namespace Hims.Laboratory.Handlers;

/// <summary>
/// Laboratory subscribes to <c>OrderPlaced</c>: for LAB orders it copies the order and its items into ref.clinical_order /
/// ref.order_item, which is what the worklist reads. Other categories (radiology, ...) are ignored.
/// </summary>
public class OrderPlacedLabHandler : IEventHandler
{
    private readonly LaboratoryDbContext _db;
    public OrderPlacedLabHandler(LaboratoryDbContext db) => _db = db;

    public string EventType => "OrderPlaced";

    public async Task HandleAsync(EventEnvelope envelope, CancellationToken ct)
    {
        if (envelope.Data.ValueKind != JsonValueKind.Object ||
            !envelope.Data.TryGetProperty("orderCategory", out var cat) || cat.GetString() != "LAB") return;

        await new RefUpsertHandler<LaboratoryDbContext, RefClinicalOrder>(_db, EventType).HandleAsync(envelope, ct);
        await new RefUpsertHandler<LaboratoryDbContext, RefOrderItem>(_db, EventType, "items").HandleAsync(envelope, ct);
    }
}
