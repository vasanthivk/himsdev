namespace Hims.Common.Events;

/// <summary>Bound from the "RabbitMq" configuration section.</summary>
public sealed class EventBusOptions
{
    public string Host { get; set; } = "localhost";
    public int Port { get; set; } = 5672;
    public string User { get; set; } = "guest";
    public string Password { get; set; } = "guest";
    public string VirtualHost { get; set; } = "/";

    /// <summary>Topic exchange all HIMS services publish to. The Python Integration Hub uses the same name.</summary>
    public string Exchange { get; set; } = "hims.events";

    /// <summary>Set false to run a service without a broker (the outbox simply accumulates).</summary>
    public bool Enabled { get; set; } = true;
}

/// <summary>Identity of the running microservice (name used for queue names and as event source).</summary>
public sealed record HimsServiceInfo(string Name, string Title, string Description);
