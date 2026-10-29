"""PostgreSQL access (psycopg 3 pool per tenant database) plus the two pieces of the data model's evt schema this service uses.

Every tenant has its own database (<SUBDOMAIN>_DATABASE_URL). The tenant of the current unit of work is a context variable:
using(tenant) sets it (event handlers, outbox relay, HTTP requests); pool() and tx() then open that tenant's database.
"""
import json
import threading
import uuid
from contextlib import contextmanager
from contextvars import ContextVar
from typing import Any, Iterator, Optional

from psycopg.rows import dict_row
from psycopg.types.json import Jsonb
from psycopg_pool import ConnectionPool

from .config import Tenant, load_tenants, settings

_pools: dict = {}                    # subdomain -> ConnectionPool
_pools_lock = threading.Lock()       # the workers are threads
_tenants: Optional[list] = None
_current: ContextVar[Optional[Tenant]] = ContextVar("tenant", default=None)


def tenants() -> list:
    """All tenants, ordered by organization id (the first is the default)."""
    global _tenants
    if _tenants is None:
        _tenants = load_tenants()
    return _tenants


def tenant_for_organization(organization_id: Optional[int]) -> Optional[Tenant]:
    return next((t for t in tenants() if t.organization_id == organization_id), None)


def tenant_for_subdomain(subdomain: Optional[str]) -> Optional[Tenant]:
    return next((t for t in tenants() if subdomain and t.subdomain == subdomain.lower()), None)


def current() -> Tenant:
    """The tenant of this unit of work; the default tenant when none was set (e.g. a device message, a call from curl)."""
    return _current.get() or tenants()[0]


@contextmanager
def using(tenant: Tenant) -> Iterator[Tenant]:
    """Runs the block against this tenant's database."""
    token = _current.set(tenant)
    try:
        yield tenant
    finally:
        _current.reset(token)


def pool(tenant: Optional[Tenant] = None) -> ConnectionPool:
    t = tenant or current()
    with _pools_lock:
        if t.subdomain not in _pools:
            _pools[t.subdomain] = ConnectionPool(t.database_url, min_size=1, max_size=8, kwargs={"row_factory": dict_row}, open=True)
        return _pools[t.subdomain]


def table(schema: str, name: str) -> str:
    """("evt", "outbox") -> evt.outbox, or integration_comms.evt_outbox when DB_SCHEMA is set (the shared database himsdev)."""
    return f"{settings.db_schema}.{schema}_{name}" if settings.db_schema else f"{schema}.{name}"


def close_pool() -> None:
    with _pools_lock:
        for p in _pools.values():
            p.close()
        _pools.clear()


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
        f"""INSERT INTO {table('evt', 'outbox')} (event_id, event_type, aggregate_type, aggregate_id, session_key, organization_id, branch_id, patient_id, payload_json)
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
        f"""INSERT INTO {table('intg', 'message_log')} (interface_code, direction, message_type, correlation_id, entity_type, entity_id, payload_uri, processing_status, error_message)
           VALUES (%s, %s, %s, %s, %s, %s, %s, %s, left(%s, 2000)) RETURNING message_log_id""",
        (interface_code, direction, message_type, correlation_id, entity_type, entity_id, payload_uri, status, error),
    ).fetchone()
    return row["message_log_id"]


def to_json(value: Any) -> str:
    return json.dumps(value, default=str)
