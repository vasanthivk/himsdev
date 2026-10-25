"""
HIMS Integration Hub (data-model service 11) - FastAPI app + background workers.

Workers (started with the app when RABBITMQ_ENABLED=true):
  * outbox relay    evt.outbox -> RabbitMQ exchange hims.events            (publishes AnalyzerResultReceived)
  * device consumer RabbitMQ queue lab.results  -> parse HL7 v2/v3/FHIR -> message_log + outbox
  * FHIR sync       RabbitMQ queue integration.events (domain events) -> ref.* + HAPI FHIR + intg.fhir_resource_map
HTTP API: provision a device channel in the Open Integration Engine, HTTP inbound for engines that POST, message log, FHIR map, simulator.
"""
import asyncio
import logging
import os
import threading
from contextlib import asynccontextmanager
from typing import Optional
from urllib.parse import urlparse, unquote

from fastapi import FastAPI, HTTPException, Query, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import PlainTextResponse, RedirectResponse
from pydantic import BaseModel

from . import bus, db, fhir_sync, simulator
from .config import settings
from .engine import EngineConfig, provision_interface
from .fhir_client import FhirClient
from .inbound import process_inbound
from .logging_setup import configure_logging
from .parsers import build_hl7v2_ack
import httpx

configure_logging(settings.log_dir)
log = logging.getLogger("hub")

stop_event = threading.Event()
workers: dict = {}


def handle_device_message(body: bytes, routing_key: str) -> None:
    """Message from the Open Integration Engine. Routing key lab.results.<analyzer> is only a fallback id; the device's own id wins."""
    raw = body.decode("utf-8", errors="replace")
    hint = routing_key.rsplit(".", 1)[-1] if routing_key.startswith("lab.results.") else None
    process_inbound(raw, analyzer_hint=hint, source="ENGINE")   # parse errors are logged as FAILED (no retry); DB errors raise -> retried


def handle_domain_event(body: bytes, routing_key: str) -> None:
    fhir_sync.handle_event(body, routing_key)


@asynccontextmanager
async def lifespan(app: FastAPI):
    if settings.rabbitmq_enabled:
        workers["relay"] = bus.OutboxRelay(stop_event)
        workers["device"] = bus.Consumer("device-results", settings.results_queue, [(settings.integration_exchange, "lab.results.#")],
                                         handle_device_message, stop_event, topology=bus.declare_device_topology)
        workers["fhir"] = bus.Consumer("fhir-sync", settings.events_queue, [(settings.events_exchange, t) for t in fhir_sync.SUBSCRIBED],
                                       handle_domain_event, stop_event)
        for w in workers.values():
            w.start()
    else:
        log.info("RABBITMQ_ENABLED=false: workers not started (HTTP API only)")
    yield
    stop_event.set()
    db.close_pool()


app = FastAPI(title="HIMS Integration Hub", version="1.0",
              description="Anti-corruption layer: device interfaces (HL7 v2/v3, FHIR) via the Open Integration Engine, RabbitMQ events, FHIR R4 sync to HAPI.",
              lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=list(settings.cors_origins), allow_origin_regex=settings.cors_origin_regex or None, allow_methods=["*"], allow_headers=["*"])


@app.get("/", include_in_schema=False)
def root():
    return RedirectResponse("/docs")


@app.get("/health")
def health(deep: bool = False):
    db_ok = False
    try:
        with db.pool().connection() as c:
            c.execute("SELECT 1")
        db_ok = True
    except Exception:
        pass
    return {
        "service": "integration", "status": "healthy" if db_ok else "degraded", "database": db_ok,
        "workers": {name: (w.connected if hasattr(w, "connected") else w.is_alive()) for name, w in workers.items()},
        "fhir": (FhirClient().ping() if deep and settings.fhir_sync_enabled else None),
    }


# ------------------------------------------------------------------------------------------ device interfaces

class InterfaceRequest(BaseModel):
    analyzerId: int
    analyzerCode: str
    analyzerName: str
    protocol: str = "HL7V2"
    sendingApplicationId: Optional[str] = None
    isBidirectional: bool = False
    # Open Integration Engine connection for this device (entered on "Add a device"). Empty = this hub's own setting (.env).
    engineUrl: Optional[str] = None
    engineUser: Optional[str] = None
    enginePassword: Optional[str] = None
    engineVerifyTls: Optional[bool] = None
    engineFirstListenPort: Optional[int] = None      # the port the device's channel listens on, used as entered
    engineChannelUrl: Optional[str] = None      # not needed to provision; Laboratory keeps it for sending messages to the channel


class InterfaceResponse(BaseModel):
    channelId: str
    routingKey: str
    status: str
    message: Optional[str] = None


@app.post("/api/interfaces", response_model=InterfaceResponse, tags=["Devices"])
def create_interface(req: InterfaceRequest):
    """Called by Laboratory when a device (lab.analyzer) is added with "create channel". Creates the device's channel in the Open Integration
    Engine from the template for its protocol and deploys it. Always answers 200 with status PROVISIONED, PENDING (engine not configured) or FAILED (+ message)."""
    config = EngineConfig.resolve(url=req.engineUrl, user=req.engineUser, password=req.enginePassword, verify_tls=req.engineVerifyTls,
                                  listen_port=req.engineFirstListenPort)
    result = provision_interface(analyzer_id=req.analyzerId, code=req.analyzerCode, name=req.analyzerName, protocol=req.protocol.upper(),
                                 sending_app=req.sendingApplicationId, config=config)
    with db.tx() as conn:
        db.log_message(conn, interface_code=req.protocol.upper()[:30], direction="OUT", message_type="CHANNEL_PROVISION", correlation_id=req.analyzerCode[:100],
                       entity_type="lab.analyzer", entity_id=req.analyzerId, status="PROCESSED" if result["status"] == "PROVISIONED" else result["status"],
                       error=None if result["status"] == "PROVISIONED" else result["message"])
    return result


@app.post("/api/inbound", tags=["Devices"])
async def inbound(request: Request, analyzer: Optional[str] = None):
    """HTTP alternative to RabbitMQ: the engine's HTTP Sender (or curl) posts the raw HL7 v2 / HL7 v3 / FHIR message as the body.
    HL7 v2 gets an HL7 ACK (AA/AE) back; other formats get JSON."""
    raw = (await request.body()).decode("utf-8", errors="replace")
    result = process_inbound(raw, analyzer_hint=analyzer, source="HTTP")
    if raw.lstrip("\x0b\ufeff \r\n").startswith("MSH"):
        return PlainTextResponse(build_hl7v2_ack(raw, result.ok, result.error or ""), media_type="text/plain")
    if not result.ok:
        raise HTTPException(422, result.error)
    return {"accepted": True, "duplicate": result.duplicate, "messageLogId": result.message_log_id}


# ------------------------------------------------------------------------------------------ observability

@app.get("/api/messages", tags=["Monitoring"])
def messages(direction: Optional[str] = None, status: Optional[str] = None, limit: int = Query(50, ge=1, le=200)):
    """intg.message_log, newest first."""
    sql = ("SELECT message_log_id, interface_code, direction, message_type, correlation_id, entity_type, entity_id, "
           f"processing_status, error_message, logged_at, payload_uri FROM {db.table('intg', 'message_log')} WHERE 1=1")
    params: list = []
    if direction:
        sql += " AND direction = %s"; params.append(direction.upper())
    if status:
        sql += " AND processing_status = %s"; params.append(status.upper())
    with db.pool().connection() as c:
        return c.execute(sql + " ORDER BY message_log_id DESC LIMIT %s", params + [limit]).fetchall()


@app.get("/api/messages/{message_log_id}/payload", response_class=PlainTextResponse, tags=["Monitoring"])
def message_payload(message_log_id: int):
    """The raw message kept behind payload_uri (PHI stays out of the table)."""
    with db.pool().connection() as c:
        row = c.execute(f"SELECT payload_uri FROM {db.table('intg', 'message_log')} WHERE message_log_id = %s", (message_log_id,)).fetchone()
    if not row or not row["payload_uri"]:
        raise HTTPException(404, "No payload stored for this message")
    path = unquote(urlparse(row["payload_uri"]).path)
    root = os.path.abspath(settings.payload_dir)
    if not os.path.abspath(path).startswith(root + os.sep) or not os.path.exists(path):
        raise HTTPException(404, "Payload file not available")
    with open(path, encoding="utf-8") as f:
        return f.read()


@app.get("/api/fhir-map", tags=["Monitoring"])
def fhir_map(entity_type: Optional[str] = None, entity_id: Optional[int] = None, limit: int = Query(100, ge=1, le=500)):
    """intg.fhir_resource_map: which FHIR resource each relational row became."""
    sql = f"SELECT * FROM {db.table('intg', 'fhir_resource_map')} WHERE 1=1"
    params: list = []
    if entity_type:
        sql += " AND entity_type = %s"; params.append(entity_type)
    if entity_id is not None:
        sql += " AND entity_id = %s"; params.append(entity_id)
    with db.pool().connection() as c:
        return c.execute(sql + " ORDER BY fhir_resource_map_id DESC LIMIT %s", params + [limit]).fetchall()


# ------------------------------------------------------------------------------------------ simulator

# class SimulateRequest(BaseModel):
#     sampleBarcode: str
#     serviceCodes: list[str]
#     analyzerCode: str = "SIMULATOR"
#     format: str = "HL7V2"
#     abnormal: bool = False
#     critical: bool = False
#     via: Optional[str] = None      # "rabbitmq" (as the engine would) or "direct"; default rabbitmq when enabled


# @app.post("/api/simulator/send", tags=["Simulator"])
# def simulate(req: SimulateRequest):
#     """Generates a device result message for the given sample and delivers it exactly like a real analyzer would (via RabbitMQ)."""
#     if not settings.enable_simulator:
#         raise HTTPException(404, "Simulator disabled (ENABLE_SIMULATOR=false)")
#     if not req.serviceCodes:
#         raise HTTPException(422, "serviceCodes is empty")
#     try:
#         raw, message_id = simulator.build_message(req.format, req.sampleBarcode, req.analyzerCode, req.serviceCodes, req.abnormal, req.critical)
#     except ValueError as e:
#         raise HTTPException(422, str(e))
#     via = (req.via or ("rabbitmq" if settings.rabbitmq_enabled else "direct")).lower()
#     if via == "rabbitmq":
#         bus.publish_device_message(raw, req.analyzerCode)
#         return {"delivered": "rabbitmq", "messageId": message_id, "format": req.format.upper(), "preview": raw[:600]}
#     result = process_inbound(raw, source="SIMULATOR")
#     return {"delivered": "direct", "messageId": message_id, "accepted": result.ok, "error": result.error, "messageLogId": result.message_log_id}


class SimulateRequest(BaseModel):
    sampleBarcode: str
    serviceCodes: list[str]
    analyzerCode: str = "SIMULATOR"
    format: str = "HL7V2"
    abnormal: bool = False
    critical: bool = False
    via: Optional[str] = None      # "rabbitmq" (direct to RabbitMQ), "engine" (through the deployed channel), or "direct" (skip transport, parse immediately)
    engineChannelUrl: Optional[str] = None      # the device's own channel endpoint for via="engine" (http://host:port/path, or mllp://host:port for a TCP Listener); empty = ENGINE_CHANNEL_URL


async def send_mllp(host: str, port: int, raw: str) -> str:
    """Sends one message framed for MLLP (<VT> message <FS><CR>) and returns the engine's reply (the HL7 ACK) without its framing."""
    reader, writer = await asyncio.open_connection(host, port)
    try:
        writer.write(b"\x0b" + raw.encode("utf-8") + b"\x1c\r")
        await writer.drain()
        reply = b""
        while b"\x1c" not in reply:
            chunk = await reader.read(4096)
            if not chunk:
                break
            reply += chunk
        return reply.split(b"\x1c")[0].lstrip(b"\x0b").decode("utf-8", errors="replace")
    finally:
        writer.close()


@app.post("/api/simulator/send", tags=["Simulator"])
async def simulate(req: SimulateRequest):
    """Generates a device result message for the given sample and delivers it exactly like a real analyzer would."""
    if not settings.enable_simulator:
        raise HTTPException(404, "Simulator disabled (ENABLE_SIMULATOR=false)")
    if not req.serviceCodes:
        raise HTTPException(422, "serviceCodes is empty")
    try:
        raw, message_id = simulator.build_message(req.format, req.sampleBarcode, req.analyzerCode, req.serviceCodes, req.abnormal, req.critical)
    except ValueError as e:
        raise HTTPException(422, str(e))

    via = (req.via or ("rabbitmq" if settings.rabbitmq_enabled else "direct")).lower()

    if via == "engine":
        channel_url = (req.engineChannelUrl or "").strip().rstrip("/") or settings.engine_channel_url
        if not channel_url:
            raise HTTPException(422, "No engine channel URL for this device - enter it when adding the device, or set ENGINE_CHANNEL_URL in .env "
                                     "to the deployed channel's HTTP endpoint")
        target = urlparse(channel_url)
        if target.scheme in ("mllp", "tcp"):        # the channel is a TCP Listener (HL7 v2 over MLLP), as a real analyzer would use
            if not target.hostname or not target.port:
                raise HTTPException(422, f"Engine channel URL '{channel_url}' must look like mllp://host:port")
            try:
                ack = await asyncio.wait_for(send_mllp(target.hostname, target.port, raw), timeout=15)
            except (OSError, asyncio.TimeoutError) as e:
                raise HTTPException(502, f"Could not deliver to the engine channel at {channel_url}: {e or 'timed out'}")
            return {"delivered": "engine", "messageId": message_id, "format": req.format.upper(), "engineAck": ack[:600], "preview": raw[:600]}
        if target.scheme not in ("http", "https"):
            raise HTTPException(422, f"Engine channel URL '{channel_url}' must start with http://, https:// or mllp://")
        content_type = "application/json" if req.format.upper() == "FHIR" else "text/plain"
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.post(channel_url + "/", content=raw.encode("utf-8"), headers={"Content-Type": content_type})
        except httpx.RequestError as e:
            raise HTTPException(502, f"Could not reach the engine channel at {channel_url}: {e}")
        return {"delivered": "engine", "messageId": message_id, "format": req.format.upper(),
                "engineHttpStatus": resp.status_code, "preview": raw[:600]}

    if via == "rabbitmq":
        bus.publish_device_message(raw, req.analyzerCode)
        return {"delivered": "rabbitmq", "messageId": message_id, "format": req.format.upper(), "preview": raw[:600]}

    result = process_inbound(raw, source="SIMULATOR")
    return {"delivered": "direct", "messageId": message_id, "accepted": result.ok, "error": result.error, "messageLogId": result.message_log_id}

