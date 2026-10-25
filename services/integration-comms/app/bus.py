"""RabbitMQ plumbing: topology, the outbox relay (evt.outbox -> hims.events) and a resilient consumer thread."""
import json
import logging
import threading
import time
from datetime import datetime, timezone
from typing import Callable, Iterable, Optional

import pika

from . import db
from .config import settings
from .envelope import build_envelope

log = logging.getLogger("hub.bus")


def connect() -> pika.BlockingConnection:
    params = pika.URLParameters(settings.rabbitmq_url)
    params.heartbeat = 15
    params.blocked_connection_timeout = 30
    return pika.BlockingConnection(params)


def declare_events_topology(ch) -> None:
    ch.exchange_declare(settings.events_exchange, exchange_type="topic", durable=True)
    ch.exchange_declare(settings.dead_letter_exchange, exchange_type="direct", durable=True)


def declare_queue(ch, queue: str, bindings: Iterable[tuple]) -> None:
    """Durable queue with a dead-letter queue '<queue>.dlq'; bindings are (exchange, routing_key)."""
    dlq = f"{queue}.dlq"
    ch.queue_declare(dlq, durable=True)
    ch.queue_bind(dlq, settings.dead_letter_exchange, routing_key=queue)
    ch.queue_declare(queue, durable=True, arguments={"x-dead-letter-exchange": settings.dead_letter_exchange, "x-dead-letter-routing-key": queue})
    for exchange, key in bindings:
        ch.queue_bind(queue, exchange, routing_key=key)


def declare_device_topology(ch) -> None:
    """Exchange the Open Integration Engine publishes device messages to, and the queue this hub reads them from."""
    ch.exchange_declare(settings.integration_exchange, exchange_type="topic", durable=True)
    declare_queue(ch, settings.results_queue, [(settings.integration_exchange, "lab.results.#")])


# ------------------------------------------------------------------------------------------ outbox relay

class OutboxRelay(threading.Thread):
    """Publishes evt.outbox rows to the hims.events exchange (routing key = event type), then stamps published_at."""

    def __init__(self, stop: threading.Event):
        super().__init__(name="outbox-relay", daemon=True)
        self.stop_event = stop

    def run(self) -> None:
        conn = ch = None
        while not self.stop_event.is_set():
            try:
                if ch is None or ch.is_closed or conn is None or conn.is_closed:
                    conn = connect()
                    ch = conn.channel()
                    declare_events_topology(ch)
                    ch.confirm_delivery()
                else:
                    conn.process_data_events(time_limit=0)   # pump the ioloop so a dead socket is noticed now, not later
                n = self.relay_batch(ch)
                if n == 0:
                    time.sleep(0.7)
            except Exception as e:                                        # broker or database hiccup: reconnect
                log.warning("Outbox relay error: %s; retrying in 5s", e)
                try:
                    if conn is not None and conn.is_open:
                        conn.close()
                except Exception:
                    pass
                conn = ch = None
                self.stop_event.wait(5)

    @staticmethod
    def relay_batch(ch) -> int:
        with db.tx() as conn:
            rows = conn.execute(
                f"""SELECT outbox_id, event_id, event_type, event_version, aggregate_type, aggregate_id, organization_id, branch_id,
                          patient_id, correlation_id, payload_json, occurred_at
                     FROM {db.table('evt', 'outbox')} WHERE published_at IS NULL AND publish_attempts < 20
                    ORDER BY outbox_id LIMIT 50 FOR UPDATE SKIP LOCKED""").fetchall()
            if not rows:
                return 0
            try:
                for r in rows:
                    env = build_envelope(event_id=str(r["event_id"]), event_type=r["event_type"], source=settings.service_name,
                                         aggregate_type=r["aggregate_type"], aggregate_id=r["aggregate_id"], data=r["payload_json"],
                                         time=r["occurred_at"], source_version=r["outbox_id"], organization_id=r["organization_id"],
                                         branch_id=r["branch_id"], patient_id=r["patient_id"],
                                         correlation_id=str(r["correlation_id"]) if r["correlation_id"] else None, event_version=r["event_version"])
                    ch.basic_publish(settings.events_exchange, r["event_type"], json.dumps(env).encode(),
                                     pika.BasicProperties(content_type="application/json", delivery_mode=2, message_id=str(r["event_id"]),
                                                          type=r["event_type"], app_id=settings.service_name))
            except Exception as e:
                ids = [r["outbox_id"] for r in rows]
                with db.pool().connection() as c2:                        # separate connection: the batch transaction is rolled back
                    c2.execute(f"UPDATE {db.table('evt', 'outbox')} SET publish_attempts = publish_attempts + 1, last_error = left(%s, 1000) WHERE outbox_id = ANY(%s)", (str(e), ids))
                raise
            conn.execute(f"UPDATE {db.table('evt', 'outbox')} SET published_at = now(), last_error = NULL WHERE outbox_id = ANY(%s)", ([r["outbox_id"] for r in rows],))
            log.info("Published %d event(s) from outbox", len(rows))
            return len(rows)


# ------------------------------------------------------------------------------------------ consumer

class Consumer(threading.Thread):
    """Consumes a queue and calls handler(body: bytes, routing_key: str). A failing message is retried (x-retry header) up to
    MAX_RETRIES times with a short delay, then dead-lettered to '<queue>.dlq'."""

    MAX_RETRIES = 5

    def __init__(self, name: str, queue: str, bindings: list, handler: Callable[[bytes, str], None], stop: threading.Event,
                 topology: Optional[Callable] = None):
        super().__init__(name=name, daemon=True)
        self.queue, self.bindings, self.handler, self.stop_event, self.topology = queue, bindings, handler, stop, topology
        self.connected = False

    def run(self) -> None:
        while not self.stop_event.is_set():
            conn = None
            try:
                conn = connect()
                ch = conn.channel()
                declare_events_topology(ch)
                if self.topology:
                    self.topology(ch)
                declare_queue(ch, self.queue, self.bindings)
                ch.basic_qos(prefetch_count=5)
                ch.basic_consume(self.queue, lambda c, m, p, b: self._on_message(c, m, p, b))
                self.connected = True
                log.info("%s consuming %s", self.name, self.queue)
                while not self.stop_event.is_set() and conn.is_open:
                    conn.process_data_events(time_limit=1)
                    if ch.is_closed:
                        raise pika.exceptions.ChannelWrongStateError("channel closed unexpectedly")
            except Exception as e:
                log.warning("%s connection lost: %s; reconnecting in 5s", self.name, e)
            finally:
                self.connected = False
                try:
                    if conn is not None and conn.is_open:
                        conn.close()
                except Exception:
                    pass
            self.stop_event.wait(5)

    def _on_message(self, ch, method, props, body: bytes) -> None:
        try:
            self.handler(body, method.routing_key)
            ch.basic_ack(method.delivery_tag)
        except Exception as e:
            retry = int((props.headers or {}).get("x-retry", 0))
            log.warning("%s failed on message (attempt %d/%d): %s", self.name, retry + 1, self.MAX_RETRIES, e)
            try:
                if retry < self.MAX_RETRIES:
                    time.sleep(min(2 * (retry + 1), 8))
                    ch.basic_publish("", self.queue, body, pika.BasicProperties(content_type=props.content_type, delivery_mode=2,
                                                                              message_id=props.message_id, headers={"x-retry": retry + 1}))
                    ch.basic_ack(method.delivery_tag)
                else:
                    ch.basic_nack(method.delivery_tag, requeue=False)     # -> <queue>.dlq
            except Exception as ack_err:
                # The channel/connection is likely already dead - force the outer loop to reconnect
                # instead of leaving this thread in a state where it looks alive but never recovers.
                log.error("%s could not ack/nack/requeue (connection likely dead): %s - forcing reconnect", self.name, ack_err)
                try:
                    ch.connection.close()
                except Exception:
                    pass


# def publish_device_message(raw: str, analyzer_code: str) -> None:
#     """Puts a raw device message on the integration exchange, exactly as the Open Integration Engine would."""
#     conn = connect()
#     try:
#         ch = conn.channel()
#         declare_device_topology(ch)
#         key = f"lab.results.{analyzer_code.lower()}"
#         ch.basic_publish(settings.integration_exchange, key, raw.encode("utf-8"), pika.BasicProperties(delivery_mode=2, content_type="text/plain"))
#     finally:
#         conn.close()


_publish_conn = None
_publish_channel = None
_publish_lock = threading.Lock()


def publish_device_message(raw: str, analyzer_code: str) -> None:
    """Puts a raw device message on the integration exchange, exactly as the Open Integration Engine would.
    Reuses one long-lived connection across calls to avoid the connection churn that was triggering resets."""
    global _publish_conn, _publish_channel
    with _publish_lock:
        for attempt in (1, 2):
            try:
                if _publish_conn is None or _publish_conn.is_closed:
                    _publish_conn = connect()
                    _publish_channel = _publish_conn.channel()
                    declare_device_topology(_publish_channel)
                key = f"lab.results.{analyzer_code.lower()}"
                _publish_channel.basic_publish(settings.integration_exchange, key, raw.encode("utf-8"),
                                               pika.BasicProperties(delivery_mode=2, content_type="text/plain"))
                return
            except (pika.exceptions.AMQPConnectionError, pika.exceptions.StreamLostError, pika.exceptions.ChannelWrongStateError) as e:
                log.warning("publish_device_message attempt %d failed: %s", attempt, e)
                try:
                    if _publish_conn is not None:
                        _publish_conn.close()
                except Exception:
                    pass
                _publish_conn = None
                _publish_channel = None
                if attempt == 2:
                    raise