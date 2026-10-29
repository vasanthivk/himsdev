"""Inbound device messages: parse -> intg.message_log + evt.outbox('AnalyzerResultReceived') in ONE transaction.

A device message names only the sample barcode, so the tenant comes from how it arrived: the routing key
lab.results.<tenant>.<analyzer> of the device's channel, the ?tenant= of /api/inbound, or the frontend's subdomain (simulator).
The message is then logged in that tenant's database and published with its organizationId, on that tenant's exchange only.
Without a tenant (a channel provisioned before tenants, lab.results.<analyzer>) it is logged in the default tenant's database
and published without organizationId; Laboratory then files it in whichever tenant has the sample barcode."""
import logging
import os
import uuid
from dataclasses import dataclass
from typing import Optional

from . import db
from .config import Tenant, settings
from .parsers import ParseError, ParsedMessage, parse_message

log = logging.getLogger("hub.inbound")


@dataclass
class InboundResult:
    ok: bool
    message_log_id: Optional[int] = None
    duplicate: bool = False
    error: Optional[str] = None
    parsed: Optional[ParsedMessage] = None


def store_payload(text: str, suffix: str = "txt") -> str:
    """The data model says message payloads (PHI) are kept outside the table (payload_uri). Local folder here; swap for Blob storage."""
    os.makedirs(settings.payload_dir, exist_ok=True)
    path = os.path.abspath(os.path.join(settings.payload_dir, f"{uuid.uuid4()}.{suffix}"))
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    return "file://" + path


def process_inbound(raw: str, *, analyzer_hint: Optional[str] = None, source: str = "ENGINE", tenant: Optional[Tenant] = None) -> InboundResult:
    """Handles one message from a device (via the engine) of this tenant (None = not known). Safe to call twice with the same
    message: the second call is a no-op."""
    if tenant is not None:
        with db.using(tenant):
            return _process(raw, analyzer_hint, source, tenant.organization_id)
    return _process(raw, analyzer_hint, source, None)


def _process(raw: str, analyzer_hint: Optional[str], source: str, organization_id: Optional[int]) -> InboundResult:
    uri = store_payload(raw)
    try:
        parsed = parse_message(raw)
    except ParseError as e:
        with db.tx() as conn:
            log_id = db.log_message(conn, interface_code=source[:30], direction="IN", message_type=None, correlation_id=None,
                                    status="FAILED", payload_uri=uri, error=str(e))
        log.warning("Rejected device message (log %s): %s", log_id, e)
        return InboundResult(ok=False, message_log_id=log_id, error=str(e))

    analyzer = parsed.analyzer_code or analyzer_hint
    correlation = f"{analyzer or 'unknown'}:{parsed.message_id}"[:100]
    with db.tx() as conn:
        dup = conn.execute(
            f"SELECT message_log_id FROM {db.table('intg', 'message_log')} WHERE direction = 'IN' AND correlation_id = %s AND processing_status = 'PROCESSED' LIMIT 1",
            (correlation,)).fetchone()
        if dup:
            log.info("Duplicate device message %s ignored", correlation)
            return InboundResult(ok=True, message_log_id=dup["message_log_id"], duplicate=True, parsed=parsed)

        log_id = db.log_message(conn, interface_code=parsed.format, direction="IN", message_type=parsed.message_type, correlation_id=correlation,
                                status="PROCESSED", entity_type="lab.sample", payload_uri=uri)
        event_id = uuid.uuid5(uuid.NAMESPACE_URL, f"hims:analyzer-result:{correlation}")     # deterministic: redelivery cannot create a second event
        db.enqueue_event(conn, "AnalyzerResultReceived", "intg.message_log", log_id, parsed.to_event_payload(log_id, analyzer), event_id=event_id,
                         organization_id=organization_id)
    log.info("Device message %s (%s, %d analytes, sample %s) queued as AnalyzerResultReceived for %s", correlation, parsed.format, len(parsed.analytes),
             parsed.sample_barcode, db.current().subdomain if organization_id is not None else "an unknown tenant")
    return InboundResult(ok=True, message_log_id=log_id, parsed=parsed)
