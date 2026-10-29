using Hims.Common.Data;
using Hims.Common.Logging;
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
/// Idempotent consumer. Declares the queue <c>&lt;service&gt;.events</c>, binds it to exactly the event types that have a
/// registered <see cref="IEventHandler"/>, and for every message runs, in ONE database transaction:
///   insert into evt.inbox (ON CONFLICT DO NOTHING)  ->  handlers  ->  mark inbox PROCESSED.
/// A redelivered event is detected by evt.inbox.message_id and skipped. Failures are retried a few times (a ref table may
/// not have caught up yet) and then dead-lettered to <c>&lt;service&gt;.events.dlq</c>.
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

        var queue = $"{_svc.Name}.events";
        var dlq = $"{queue}.dlq";
        channel.ExchangeDeclare(_bus.Exchange, ExchangeType.Topic, durable: true);
        channel.ExchangeDeclare(DeadLetterExchange, ExchangeType.Direct, durable: true);
        channel.QueueDeclare(dlq, durable: true, exclusive: false, autoDelete: false, arguments: null);
        channel.QueueBind(dlq, DeadLetterExchange, queue);
        channel.QueueDeclare(queue, durable: true, exclusive: false, autoDelete: false, arguments: new Dictionary<string, object>
        {
            ["x-dead-letter-exchange"] = DeadLetterExchange,
            ["x-dead-letter-routing-key"] = queue,
        });
        foreach (var t in types) channel.QueueBind(queue, _bus.Exchange, t);
        channel.BasicQos(0, 10, false);

        var consumer = new AsyncEventingBasicConsumer(channel);
        consumer.Received += async (_, ea) => await OnMessageAsync(channel, queue, ea, ct);
        channel.BasicConsume(queue, false, consumer);
        _log.LogInformation("{Service} consuming {Queue}, bound to: {Types}", _svc.Name, queue, string.Join(", ", types));

        while (!ct.IsCancellationRequested && channel.IsOpen) await Task.Delay(1000, ct);
    }

    private async Task OnMessageAsync(IModel channel, string queue, BasicDeliverEventArgs ea, CancellationToken ct)
    {
        EventEnvelope? env = null;
        try
        {
            env = JsonSerializer.Deserialize<EventEnvelope>(ea.Body.Span, EventJson.Options);
            if (env is null || string.IsNullOrEmpty(env.Id))
            {
                _log.LogWarning("[FLOW] corr=none event=none step=SUB-REJECT {Service}: unreadable message on {Queue} (routing key '{Key}') sent to the DLQ", _svc.Name, queue, ea.RoutingKey);
                channel.BasicNack(ea.DeliveryTag, false, false);
                return;
            }
            _log.LogInformation("[FLOW] corr={Corr} event={EventId} step=SUB-01 {Service}: received {Type} for {Subject} from {Source} on queue {Queue} (attempt {Attempt})",
                FlowLog.Corr(env.CorrelationId), env.Id, _svc.Name, env.Type, env.Subject, env.Source, queue, ReadRetry(ea.BasicProperties) + 1);
            await ProcessAsync(env, ct);
            channel.BasicAck(ea.DeliveryTag, false);
        }
        catch (Exception ex)
        {
            var retry = ReadRetry(ea.BasicProperties);
            _log.LogWarning(ex, "Failed handling {Type} {Id} (attempt {Attempt}/{Max})", env?.Type, env?.Id, retry + 1, MaxRetries);
            _log.LogWarning("[FLOW] corr={Corr} event={EventId} step={Step} {Service}: {Type} failed (attempt {Attempt}/{Max}): {Error}",
                FlowLog.Corr(env?.CorrelationId), env?.Id ?? "none", env is not null && retry < MaxRetries ? "SUB-RETRY" : "SUB-DLQ",
                _svc.Name, env?.Type, retry + 1, MaxRetries, ex.Message);
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

    private async Task ProcessAsync(EventEnvelope env, CancellationToken ct)
    {
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<TDb>();
        var inbox = scope.ServiceProvider.GetRequiredService<HimsDbNames>().Table("evt", "inbox");   // or <service schema>.evt_inbox
        await using var tx = await db.Database.BeginTransactionAsync(ct);
        var corr = FlowLog.Corr(env.CorrelationId);
        var started = System.Diagnostics.Stopwatch.StartNew();

        // The table name is configuration (validated identifier); the values stay parameters ({0}..{2}).
        var inserted = await db.Database.ExecuteSqlRawAsync(
            $"INSERT INTO {inbox} (message_id, event_type, source_service) VALUES ({{0}}, {{1}}, {{2}}) ON CONFLICT (message_id) DO NOTHING",
            new object[] { env.Id, env.Type, env.Source }, ct);
        if (inserted == 0)
        {
            await tx.RollbackAsync(ct);
            _log.LogInformation("[FLOW] corr={Corr} event={EventId} step=SUB-DUP {Service}: {Type} already in {Inbox}, ignored (redelivery)", corr, env.Id, _svc.Name, env.Type, inbox);
            return;
        }
        _log.LogInformation("[FLOW] corr={Corr} event={EventId} step=SUB-02 {Service}: recorded in {Inbox} (idempotency check passed)", corr, env.Id, _svc.Name, inbox);

        foreach (var handler in scope.ServiceProvider.GetServices<IEventHandler>().Where(h => h.EventType == env.Type))
        {
            var handlerName = handler.GetType().IsGenericType
                ? $"{handler.GetType().Name.Split('`')[0]}<{handler.GetType().GetGenericArguments().Last().Name}>"
                : handler.GetType().Name;
            _log.LogInformation("[FLOW] corr={Corr} event={EventId} step=SUB-03 {Service}: running handler {Handler} for {Type}", corr, env.Id, _svc.Name, handlerName, env.Type);
            await handler.HandleAsync(env, ct);
        }

        await db.Database.ExecuteSqlRawAsync(
            $"UPDATE {inbox} SET process_status = 'PROCESSED', processed_at = now() WHERE message_id = {{0}}", new object[] { env.Id }, ct);
        await tx.CommitAsync(ct);
        _log.LogInformation("[FLOW] corr={Corr} event={EventId} step=SUB-04 {Service}: {Type} PROCESSED and committed in {Ms} ms", corr, env.Id, _svc.Name, env.Type, started.ElapsedMilliseconds);
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
