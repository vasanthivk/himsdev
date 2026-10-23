using System.Text.Json;
using Hims.Common.Events;
using Hims.PatientAccess.Data;
using Microsoft.EntityFrameworkCore;

namespace Hims.PatientAccess.Handlers;

/// <summary>
/// Patient Access owns the encounter. When the doctor finishes the visit, Clinical Care publishes <c>ConsultationCompleted</c>;
/// this closes the encounter exactly like POST /api/encounters/{id}/close and publishes <c>EncounterClosed</c>.
/// Idempotent: an encounter that is already COMPLETED is left as it is.
/// </summary>
public class ConsultationCompletedHandler : IEventHandler
{
    private readonly PatientAccessDbContext _db;
    private readonly ILogger<ConsultationCompletedHandler> _log;
    public ConsultationCompletedHandler(PatientAccessDbContext db, ILogger<ConsultationCompletedHandler> log) { _db = db; _log = log; }

    public string EventType => "ConsultationCompleted";

    public async Task HandleAsync(EventEnvelope envelope, CancellationToken ct)
    {
        var p = envelope.Data.Deserialize<ConsultationCompletedPayload>(EventJson.Options)
            ?? throw new InvalidOperationException("ConsultationCompleted payload is empty");
        var enc = await _db.Encounters.FirstOrDefaultAsync(e => e.EncounterId == p.EncounterId, ct);
        if (enc is null) { _log.LogWarning("ConsultationCompleted for unknown encounter {EncounterId}", p.EncounterId); return; }
        if (enc.EncounterStatus == "COMPLETED") return;

        enc.EncounterStatus = "COMPLETED";
        enc.EndAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);
        _db.EnqueueEvent("EncounterClosed", "pat.encounter", enc.EncounterId, enc, enc.OrganizationId, enc.BranchId, enc.PatientId);
        await _db.SaveChangesAsync(ct);
        _log.LogInformation("Encounter {EncounterId} closed after the consultation was completed", enc.EncounterId);
    }
}
