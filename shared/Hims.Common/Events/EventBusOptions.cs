namespace Hims.Common.Events;

/// <summary>Bound from the "RabbitMq" configuration section.</summary>
public sealed class EventBusOptions
{
    public string Host { get; set; } = "localhost";
    public int Port { get; set; } = 5672;
    public string User { get; set; } = "guest";
    public string Password { get; set; } = "guest";
    public string VirtualHost { get; set; } = "/";

    /// <summary>
    /// Topic exchange per tenant; {tenant} is replaced by the tenant name (hims.reddys.events, hims.apollo.events). A tenant's
    /// events are published to its exchange only. The Python Integration Hub uses the same names.
    /// </summary>
    public string Exchange { get; set; } = "hims.{tenant}.events";

    /// <summary>The exchange of one tenant, e.g. "reddys" -> hims.reddys.events.</summary>
    public string ExchangeFor(string tenant) => Exchange.Replace("{tenant}", tenant);

    /// <summary>Set false to run a service without a broker (the outbox simply accumulates).</summary>
    public bool Enabled { get; set; } = true;
}

/// <summary>Identity of the running microservice (name used for queue names and as event source).</summary>
public sealed record HimsServiceInfo(string Name, string Title, string Description);
