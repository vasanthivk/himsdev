"""PostgreSQL access (psycopg 3 pool) plus the two pieces of the data model's evt schema this service uses."""
import json
import uuid
from contextlib import contextmanager
from typing import Any, Iterator, Optional

from psycopg.rows import dict_row
from psycopg.types.json import Jsonb
from psycopg_pool import ConnectionPool

from .config import settings

_pool: Optional[ConnectionPool] = None


def pool() -> ConnectionPool:
    global _pool
    if _pool is None:
        _pool = ConnectionPool(settings.database_url, min_size=1, max_size=8, kwargs={"row_factory": dict_row}, open=True)
    return _pool


def close_pool() -> None:
    global _pool
    if _pool is not None:
        _pool.close()
        _pool = None


@contextmanager
def tx() -> Iterator[Any]:
    """One database transaction: commits on success, rolls back on exception."""
    with pool().connection() as conn:
        with conn.transaction():
            yield conn


def enqueue_event(conn, event_type: str, aggregate_type: str, aggregate_id: int, payload: dict, *,
                  event_id: Optional[uuid.UUID] = None, patient_id: Optional[int] = None,
                  organization_id: Optional[int] = None, branch_id: Optional[int] = None) -> Optional[int]:
    """Transactional outbox: write the event in the caller's transaction; the relay publishes it to RabbitMQ.
    A repeated event_id is ignored (returns None), which makes re-processing an input message harmless."""
    row = conn.execute(
        """INSERT INTO evt.outbox (event_id, event_type, aggregate_type, aggregate_id, session_key, organization_id, branch_id, patient_id, payload_json)
           VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
           ON CONFLICT (event_id) DO NOTHING RETURNING outbox_id""",
        (event_id or uuid.uuid4(), event_type, aggregate_type, aggregate_id, str(patient_id or aggregate_id),
         organization_id, branch_id, patient_id, Jsonb(payload)),
    ).fetchone()
    return row["outbox_id"] if row else None


def log_message(conn, *, interface_code: str, direction: str, message_type: Optional[str], correlation_id: Optional[str],
                status: str, entity_type: Optional[str] = None, entity_id: Optional[int] = None,
                payload_uri: Optional[str] = None, error: Optional[str] = None) -> int:
    """intg.message_log: HL7 v2 / v3 / FHIR traffic, in or out."""
    row = conn.execute(
        """INSERT INTO intg.message_log (interface_code, direction, message_type, correlation_id, entity_type, entity_id, payload_uri, processing_status, error_message)
           VALUES (%s, %s, %s, %s, %s, %s, %s, %s, left(%s, 2000)) RETURNING message_log_id""",
        (interface_code, direction, message_type, correlation_id, entity_type, entity_id, payload_uri, status, error),
    ).fetchone()
    return row["message_log_id"]


def to_json(value: Any) -> str:
    return json.dumps(value, default=str)
