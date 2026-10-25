using System.Text;
using System.Text.Json;
using Hims.Common.Data;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Npgsql;
using RabbitMQ.Client;

namespace Hims.Common.Events;

/// <summary>
/// Transactional-outbox relay. Polls <c>evt.outbox</c> for rows with <c>published_at IS NULL</c>, publishes each to the
/// <c>hims.events</c> topic exchange (routing key = event_type) with publisher confirms, then stamps
/// <c>published_at</c>. This replaces the "relay to Azure Service Bus" mentioned in the data model with RabbitMQ.
/// Uses SELECT ... FOR UPDATE SKIP LOCKED so several instances of a service can run safely.
/// </summary>
public sealed class OutboxRelay : BackgroundService
{
    private const int MaxAttempts = 20;
    private readonly ILogger<OutboxRelay> _log;
    private readonly EventBusOptions _bus;
    private readonly HimsServiceInfo _svc;
    private readonly string _connectionString;
    private readonly string _outbox;   // evt.outbox, or <service schema>.evt_outbox in the shared database

    public OutboxRelay(IConfiguration config, IOptions<EventBusOptions> bus, HimsServiceInfo svc, HimsDbNames names, ILogger<OutboxRelay> log)
    {
        _log = log;
        _outbox = names.Table("evt", "outbox");
        _bus = bus.Value;
        _svc = svc;
        _connectionString = config.GetConnectionString("Default") ?? throw new InvalidOperationException("ConnectionStrings:Default is not configured");
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!_bus.Enabled) { _log.LogInformation("Event bus disabled; outbox relay not started"); return; }
        await using var dataSource = NpgsqlDataSource.Create(_connectionString);
        IConnection? connection = null;
        IModel? channel = null;

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                if (channel is null || !channel.IsOpen)
                {
                    channel?.Dispose(); connection?.Dispose();
                    var factory = new ConnectionFactory { HostName = _bus.Host, Port = _bus.Port, UserName = _bus.User, Password = _bus.Password, VirtualHost = _bus.VirtualHost };
                    connection = factory.CreateConnection($"{_svc.Name}-outbox");
                    channel = connection.CreateModel();
                    channel.ExchangeDeclare(_bus.Exchange, ExchangeType.Topic, durable: true);
                    channel.ConfirmSelect();
                }

                var published = await RelayBatchAsync(dataSource, channel, stoppingToken);
                if (published == 0) await Task.Delay(TimeSpan.FromMilliseconds(700), stoppingToken);
            }
            catch (OperationCanceledException) { break; }
            catch (Exception ex)
            {
                _log.LogWarning(ex, "Outbox relay error; retrying in 5s");
                channel?.Dispose(); connection?.Dispose(); channel = null; connection = null;
                try { await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken); } catch (OperationCanceledException) { break; }
            }
        }
        channel?.Dispose(); connection?.Dispose();
    }

    private async Task<int> RelayBatchAsync(NpgsqlDataSource ds, IModel channel, CancellationToken ct)
    {
        await using var conn = await ds.OpenConnectionAsync(ct);
        await using var tx = await conn.BeginTransactionAsync(ct);

        var ids = new List<long>();
        var messages = new List<(long OutboxId, Guid EventId, string Type, byte[] Body)>();

        var select = $@"SELECT outbox_id, event_id, event_type, event_version, aggregate_type, aggregate_id, session_key,
                                       organization_id, branch_id, patient_id, correlation_id, payload_json::text, occurred_at
                                  FROM {_outbox}
                                 WHERE published_at IS NULL AND publish_attempts < @max
                                 ORDER BY outbox_id
                                 LIMIT 50
                                 FOR UPDATE SKIP LOCKED";
        await using (var cmd = new NpgsqlCommand(select, conn, tx))
        {
            cmd.Parameters.AddWithValue("max", MaxAttempts);
            await using var r = await cmd.ExecuteReaderAsync(ct);
            while (await r.ReadAsync(ct))
            {
                var outboxId = r.GetInt64(0);
                var eventId = r.GetGuid(1);
                var type = r.GetString(2);
                var envelope = new EventEnvelope
                {
                    Id = eventId.ToString(),
                    Type = type,
                    Source = _svc.Name,
                    EventVersion = r.GetInt16(3),
                    AggregateType = r.GetString(4),
                    AggregateId = r.GetInt64(5),
                    Subject = $"{r.GetString(4)}/{r.GetInt64(5)}",
                    OrganizationId = r.IsDBNull(7) ? null : r.GetInt32(7),
                    BranchId = r.IsDBNull(8) ? null : r.GetInt32(8),
                    PatientId = r.IsDBNull(9) ? null : r.GetInt64(9),
                    CorrelationId = r.IsDBNull(10) ? null : r.GetGuid(10),
                    Data = JsonDocument.Parse(r.GetString(11)).RootElement.Clone(),
                    Time = r.GetFieldValue<DateTime>(12).ToUniversalTime(),
                    SourceVersion = outboxId,
                };
                ids.Add(outboxId);
                messages.Add((outboxId, eventId, type, Encoding.UTF8.GetBytes(EventJson.Serialize(envelope))));
            }
        }

        if (messages.Count == 0) { await tx.CommitAsync(ct); return 0; }

        try
        {
            foreach (var m in messages)
            {
                var props = channel.CreateBasicProperties();
                props.Persistent = true;
                props.ContentType = "application/json";
                props.MessageId = m.EventId.ToString();
                props.Type = m.Type;
                props.AppId = _svc.Name;
                channel.BasicPublish(_bus.Exchange, m.Type, props, m.Body);
            }
            channel.WaitForConfirmsOrDie(TimeSpan.FromSeconds(10));
        }
        catch (Exception ex)
        {
            await tx.RollbackAsync(ct);
            await RecordFailureAsync(ds, ids, ex.Message, ct);
            throw;
        }

        await using (var upd = new NpgsqlCommand($"UPDATE {_outbox} SET published_at = now(), last_error = NULL WHERE outbox_id = ANY(@ids)", conn, tx))
        {
            upd.Parameters.AddWithValue("ids", ids.ToArray());
            await upd.ExecuteNonQueryAsync(ct);
        }
        await tx.CommitAsync(ct);
        _log.LogInformation("Published {Count} event(s) from outbox", messages.Count);
        return messages.Count;
    }

    private async Task RecordFailureAsync(NpgsqlDataSource ds, List<long> ids, string error, CancellationToken ct)
    {
        await using var conn = await ds.OpenConnectionAsync(ct);
        await using var cmd = new NpgsqlCommand(
            $"UPDATE {_outbox} SET publish_attempts = publish_attempts + 1, last_error = left(@err, 1000) WHERE outbox_id = ANY(@ids)", conn);
        cmd.Parameters.AddWithValue("err", error);
        cmd.Parameters.AddWithValue("ids", ids.ToArray());
        await cmd.ExecuteNonQueryAsync(ct);
    }
}
