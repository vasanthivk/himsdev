using System.Text.Json;
using Hims.Common.Events;
using Hims.Diagnostics.Services;

namespace Hims.Diagnostics.Handlers;

/// <summary>Laboratory subscribes to <c>AnalyzerResultReceived</c>, published by the Python Integration Hub for each device message.</summary>
public class AnalyzerResultReceivedHandler : IEventHandler
{
    private readonly ResultService _results;
    public AnalyzerResultReceivedHandler(ResultService results) => _results = results;

    public string EventType => "AnalyzerResultReceived";

    public async Task HandleAsync(EventEnvelope envelope, CancellationToken ct)
    {
        var msg = envelope.Data.Deserialize<AnalyzerResultReceivedPayload>(EventJson.Options)
            ?? throw new InvalidOperationException("Empty AnalyzerResultReceived payload");
        await _results.ApplyAnalyzerResultAsync(msg, ct);
    }
}
