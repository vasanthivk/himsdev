using Hims.Common.Data;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace Hims.Common.Events;

/// <summary>
/// Idempotent consumer. For every tenant, declares the queue <c>&lt;service&gt;.&lt;tenant&gt;.events</c> (e.g.
/// diagnostics.apollo.events), binds it on that tenant's exchange (hims.apollo.events) to exactly the event types that have a
/// registered <see cref="IEventHandler"/>, and for every message runs, in ONE database transaction of that tenant's database:
///   insert into evt.inbox (ON CONFLICT DO NOTHING)  ->  handlers  ->  mark inbox PROCESSED.
/// A redelivered event is detected by evt.inbox.message_id and skipped. Failures are retried a few times (a ref table may
/// not have caught up yet) and then dead-lettered to <c>&lt;service&gt;.&lt;tenant&gt;.events.dlq</c>.
/// If a service registers no handlers, this consumer does nothing.
/// </summary>
public sealed class EventConsumer<TDb> : BackgroundService where TDb : DbContext
{
    private const int MaxRetries = 5;
    private const string DeadLetterExchange = "hims.events.dlx";
    private readonly IServiceProvider _sp;
    private readonly EventBusOptions _bus;
    private readonly HimsServiceInfo _svc;
    private readonly ILogger<EventConsumer<TDb>> _log;
    private readonly object _publishLock = new();

    public EventConsumer(IServiceProvider sp, IOptions<EventBusOptions> bus, HimsServiceInfo svc, ILogger<EventConsumer<TDb>> log)
    {
        _sp = sp; _bus = bus.Value; _svc = svc; _log = log;
    }

    protected override Task ExecuteAsync(CancellationToken stoppingToken) => Task.Run(() => RunAsync(stoppingToken), stoppingToken);

    private async Task RunAsync(CancellationToken ct)
    {
        if (!_bus.Enabled) return;
        HashSet<string> types;
        using (var scope = _sp.CreateScope())
            types = scope.ServiceProvider.GetServices<IEventHandler>().Select(h => h.EventType).ToHashSet();
        if (types.Count == 0) { _log.LogInformation("{Service}: no event handlers registered; consumer idle", _svc.Name); return; }

        while (!ct.IsCancellationRequested)
        {
            try { await ConsumeAsync(types, ct); }
            catch (OperationCanceledException) { break; }
            catch (Exception ex)
            {
                _log.LogWarning(ex, "Event consumer connection lost; reconnecting in 5s");
                try { await Task.Delay(TimeSpan.FromSeconds(5), ct); } catch (OperationCanceledException) { break; }
            }
        }
    }

    private async Task ConsumeAsync(HashSet<string> types, CancellationToken ct)
    {
        var factory = new ConnectionFactory
        {
            HostName = _bus.Host, Port = _bus.Port, UserName = _bus.User, Password = _bus.Password,
            VirtualHost = _bus.VirtualHost, DispatchConsumersAsync = true,
        };
        using var connection = factory.CreateConnection($"{_svc.Name}-consumer");
        using var channel = connection.CreateModel();
        channel.ExchangeDeclare(DeadLetterExchange, ExchangeType.Direct, durable: true);
        channel.BasicQos(0, 10, false);

        foreach (var tenant in _sp.GetRequiredService<HimsTenants>().All)
        {
            var exchange = _bus.ExchangeFor(tenant.Name);
            var queue = $"{_svc.Name}.{tenant.Name}.events";
            var dlq = $"{queue}.dlq";
            channel.ExchangeDeclare(exchange, ExchangeType.Topic, durable: true);
            channel.QueueDeclare(dlq, durable: true, exclusive: false, autoDelete: false, arguments: null);
            channel.QueueBind(dlq, DeadLetterExchange, queue);
            channel.QueueDeclare(queue, durable: true, exclusive: false, autoDelete: false, arguments: new Dictionary<string, object>
            {
                ["x-dead-letter-exchange"] = DeadLetterExchange,
                ["x-dead-letter-routing-key"] = queue,
            });
            foreach (var t in types) channel.QueueBind(queue, exchange, t);

            var consumer = new AsyncEventingBasicConsumer(channel);
            consumer.Received += async (_, ea) => await OnMessageAsync(channel, queue, tenant, ea, ct);
            channel.BasicConsume(queue, false, consumer);
            _log.LogInformation("{Service} consuming {Queue} from {Exchange}, bound to: {Types}", _svc.Name, queue, exchange, string.Join(", ", types));
        }

        while (!ct.IsCancellationRequested && channel.IsOpen) await Task.Delay(1000, ct);
    }

    private async Task OnMessageAsync(IModel channel, string queue, HimsTenant queueTenant, BasicDeliverEventArgs ea, CancellationToken ct)
    {
        EventEnvelope? env = null;
        try
        {
            env = JsonSerializer.Deserialize<EventEnvelope>(ea.Body.Span, EventJson.Options);
            if (env is null || string.IsNullOrEmpty(env.Id)) { channel.BasicNack(ea.DeliveryTag, false, false); return; }
            await ProcessAsync(env, queueTenant, ct);
            channel.BasicAck(ea.DeliveryTag, false);
        }
        catch (Exception ex)
        {
            var retry = ReadRetry(ea.BasicProperties);
            _log.LogWarning(ex, "Failed handling {Type} {Id} (attempt {Attempt}/{Max})", env?.Type, env?.Id, retry + 1, MaxRetries);
            if (env is not null && retry < MaxRetries)
            {
                try { await Task.Delay(TimeSpan.FromSeconds(2 * (retry + 1)), ct); } catch (OperationCanceledException) { }
                lock (_publishLock)
                {
                    var props = channel.CreateBasicProperties();
                    props.Persistent = true;
                    props.ContentType = "application/json";
                    props.MessageId = ea.BasicProperties.MessageId;
                    props.Headers = new Dictionary<string, object> { ["x-retry"] = retry + 1 };
                    channel.BasicPublish("", queue, props, ea.Body);
                }
                channel.BasicAck(ea.DeliveryTag, false);
            }
            else
            {
                channel.BasicNack(ea.DeliveryTag, false, false); // -> <service>.events.dlq
            }
        }
    }

    /// <summary>
    /// The event is processed in the database of the tenant whose exchange it came from; its organizationId must agree. An event
    /// without one (AnalyzerResultReceived: the device sends only a sample barcode) is tried in that tenant's database first,
    /// then in the others; the first that accepts it keeps it.
    /// </summary>
    private async Task ProcessAsync(EventEnvelope env, HimsTenant queueTenant, CancellationToken ct)
    {
        var tenants = _sp.GetRequiredService<HimsTenants>();
        if (env.OrganizationId is int org)
        {
            if (org != queueTenant.OrganizationId)
                throw new InvalidOperationException($"{env.Type} {env.Id} is for organization {org} but came from {_bus.ExchangeFor(queueTenant.Name)} (organization {queueTenant.OrganizationId})");
            await ProcessInAsync(queueTenant, env, ct);
            return;
        }

        var errors = new List<string>();
        foreach (var tenant in tenants.All.OrderBy(t => t.Name == queueTenant.Name ? 0 : 1))
        {
            try { await ProcessInAsync(tenant, env, ct); return; }
            catch (Exception ex) when (ex is not OperationCanceledException) { errors.Add($"{tenant.Name}: {ex.Message}"); }
        }
        throw new InvalidOperationException($"{env.Type} {env.Id} has no organization and no tenant accepted it - {string.Join("; ", errors)}");
    }

    private async Task ProcessInAsync(HimsTenant tenant, EventEnvelope env, CancellationToken ct)
    {
        using var scope = _sp.CreateScope();
        scope.ServiceProvider.GetRequiredService<HimsTenantContext>().Use(tenant);
        var db = scope.ServiceProvider.GetRequiredService<TDb>();
        var inbox = scope.ServiceProvider.GetRequiredService<HimsDbNames>().Table("evt", "inbox");   // or <service schema>.evt_inbox
        await using var tx = await db.Database.BeginTransactionAsync(ct);

        // The table name is configuration (validated identifier); the values stay parameters ({0}..{2}).
        var inserted = await db.Database.ExecuteSqlRawAsync(
            $"INSERT INTO {inbox} (message_id, event_type, source_service) VALUES ({{0}}, {{1}}, {{2}}) ON CONFLICT (message_id) DO NOTHING",
            new object[] { env.Id, env.Type, env.Source }, ct);
        if (inserted == 0)
        {
            await tx.RollbackAsync(ct);
            _log.LogInformation("Duplicate {Type} {Id} ignored (already in the {Tenant} evt.inbox)", env.Type, env.Id, tenant.Name);
            return;
        }

        foreach (var handler in scope.ServiceProvider.GetServices<IEventHandler>().Where(h => h.EventType == env.Type))
            await handler.HandleAsync(env, ct);

        await db.Database.ExecuteSqlRawAsync(
            $"UPDATE {inbox} SET process_status = 'PROCESSED', processed_at = now() WHERE message_id = {{0}}", new object[] { env.Id }, ct);
        await tx.CommitAsync(ct);
    }

    private static int ReadRetry(IBasicProperties props)
    {
        if (props.Headers is not null && props.Headers.TryGetValue("x-retry", out var v) && v is not null)
        {
            try { return Convert.ToInt32(v); } catch { return 0; }
        }
        return 0;
    }
}
