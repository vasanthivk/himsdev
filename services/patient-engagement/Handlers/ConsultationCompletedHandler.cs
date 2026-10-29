using System.Text.Json;
using Hims.Common.Events;
using Hims.Common.Logging;
using Hims.PatientEngagement.Data;
using Microsoft.EntityFrameworkCore;

namespace Hims.PatientEngagement.Handlers;

/// <summary>
/// Patient Access owns the encounter. When the doctor finishes the visit, Clinical Care publishes <c>ConsultationCompleted</c>;
/// this closes the encounter exactly like POST /api/encounters/{id}/close and publishes <c>EncounterClosed</c>.
/// Idempotent: an encounter that is already COMPLETED is left as it is.
/// </summary>
public class ConsultationCompletedHandler : IEventHandler
{
    private readonly PatientEngagementDbContext _db;
    private readonly ILogger<ConsultationCompletedHandler> _log;
    public ConsultationCompletedHandler(PatientEngagementDbContext db, ILogger<ConsultationCompletedHandler> log) { _db = db; _log = log; }

    public string EventType => "ConsultationCompleted";

    public async Task HandleAsync(EventEnvelope envelope, CancellationToken ct)
    {
        var p = envelope.Data.Deserialize<ConsultationCompletedPayload>(EventJson.Options)
            ?? throw new InvalidOperationException("ConsultationCompleted payload is empty");
        var enc = await _db.Encounters.FirstOrDefaultAsync(e => e.EncounterId == p.EncounterId, ct);
        var corr = FlowLog.Corr(envelope.CorrelationId);
        if (enc is null)
        {
            _log.LogWarning("[FLOW] corr={Corr} event={EventId} step=CC-STOP ConsultationCompleted for unknown encounter {EncounterId}", corr, envelope.Id, p.EncounterId);
            return;
        }
        if (enc.EncounterStatus == "COMPLETED")
        {
            _log.LogInformation("[FLOW] corr={Corr} event={EventId} step=CC-STOP encounter {EncounterNo} already COMPLETED, nothing to do", corr, envelope.Id, enc.EncounterNo);
            return;
        }

        enc.EncounterStatus = "COMPLETED";
        enc.EndAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);
        // Same correlation id as the incoming event, so the chain doctor -> clinical-care -> here -> subscribers stays traceable.
        var outbox = _db.EnqueueEvent("EncounterClosed", "pat.encounter", enc.EncounterId, enc, enc.OrganizationId, enc.BranchId, enc.PatientId, envelope.CorrelationId);
        await _db.SaveChangesAsync(ct);
        _log.LogInformation("[FLOW] corr={Corr} event={EventId} step=CC-01 encounter {EncounterNo} closed after ConsultationCompleted; EncounterClosed queued in evt.outbox (outbox_id {OutboxId}, new event {NewEventId})",
            corr, envelope.Id, enc.EncounterNo, outbox.OutboxId, outbox.EventId);
    }
}
