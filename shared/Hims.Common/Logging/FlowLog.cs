using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;

namespace Hims.Common.Logging;

/// <summary>
/// End-to-end tracing for the event flow (HTTP request -> evt.outbox -> RabbitMQ -> consumers in other services).
///
/// Every HTTP request gets a correlation id: the caller's <c>X-Correlation-Id</c> header when it is a valid GUID, otherwise a
/// new one. It is echoed back in the response header, stored in <c>evt.outbox.correlation_id</c> by the controllers, carried
/// in the RabbitMQ envelope (<c>correlationId</c>) and written by every publisher/consumer into its log line as
/// <c>corr=&lt;guid&gt;</c>. To follow one patient registration across all services:
/// <code>grep -h "corr=&lt;guid&gt;" logs/*/dd-MM-yyyy.log | sort</code>
/// All flow lines start with <c>[FLOW]</c>, so <c>grep "\[FLOW\]"</c> shows the whole flow of every request.
/// </summary>
public static class FlowLog
{
    public const string HeaderName = "X-Correlation-Id";
    private const string ItemKey = "Hims.CorrelationId";

    /// <summary>Assigns the request's correlation id. Call early in the pipeline (UseHims does this).</summary>
    public static IApplicationBuilder UseHimsCorrelation(this IApplicationBuilder app) => app.Use(async (ctx, next) =>
    {
        var id = Guid.TryParse(ctx.Request.Headers[HeaderName].ToString(), out var incoming) && incoming != Guid.Empty
            ? incoming
            : Guid.NewGuid();
        ctx.Items[ItemKey] = id;
        ctx.Response.Headers[HeaderName] = id.ToString();
        await next();
    });

    /// <summary>The correlation id of the current request (a new one if the middleware did not run).</summary>
    public static Guid GetCorrelationId(this HttpContext ctx)
    {
        if (ctx.Items.TryGetValue(ItemKey, out var v) && v is Guid g) return g;
        var id = Guid.NewGuid();
        ctx.Items[ItemKey] = id;
        return id;
    }

    /// <summary>Text used in log lines for a missing correlation id.</summary>
    public static string Corr(Guid? id) => id?.ToString() ?? "none";

    /// <summary>Only the last 4 digits of a mobile number go into the logs.</summary>
    public static string MaskMobile(string? mobile)
    {
        if (string.IsNullOrEmpty(mobile)) return "-";
        return mobile.Length <= 4 ? new string('*', mobile.Length) : new string('*', mobile.Length - 4) + mobile[^4..];
    }
}
