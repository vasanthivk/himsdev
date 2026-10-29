"""
Open Integration Engine (Mirth Connect compatible REST API) provisioning.

"Add a device" in Laboratory ends here when "create channel" is ticked. The hub takes the channel template for the device's
protocol (app/channel_templates: HL7 v2, HL7 v3, FHIR), replaces the ${PLACEHOLDERS} in it, creates/updates the channel named HIMS-<analyzer code> and deploys it (docs/ENGINE_TEMPLATE.md).
The channel listens for the instrument (HL7 v2 over MLLP; HL7 v3 and FHIR over HTTP) and publishes the raw message to RabbitMQ
(exchange hims.integration, routing key lab.results.<code>) where this hub's device consumer picks it up.
"""
import logging
import pathlib
import re
import uuid
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from typing import Optional
from urllib.parse import unquote, urlparse
from xml.sax.saxutils import escape

import requests

from .config import settings

log = logging.getLogger("hub.engine")

# One channel template per protocol, made from the working channels in oie_channels/ (see docs/ENGINE_TEMPLATE.md).
TEMPLATE_DIR = pathlib.Path(__file__).parent / "channel_templates"
BUILT_IN_TEMPLATES = {"HL7V2": "hl7v2.xml", "HL7V3": "hl7v3.xml", "FHIR": "fhir.xml"}
HTTP_PROTOCOLS = ("HL7V3", "FHIR")      # these channels are HTTP Listeners (port + context path); HL7 v2 is a TCP/MLLP listener (port only)


class EngineError(RuntimeError):
    pass


def slug(code: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", code.lower()).strip("-") or "analyzer"


@dataclass(frozen=True)
class EngineConfig:
    """Connection to one Open Integration Engine. Entered per device on Laboratory's "Add a device" form; anything left empty
    there falls back to this hub's own setting (.env)."""
    url: str
    user: str
    password: str
    verify_tls: bool
    listen_port: Optional[int]      # the port the device's channel listens on; None = ENGINE_FIRST_LISTEN_PORT + analyzer id

    @classmethod
    def resolve(cls, *, url: Optional[str] = None, user: Optional[str] = None, password: Optional[str] = None,
                verify_tls: Optional[bool] = None, listen_port: Optional[int] = None) -> "EngineConfig":
        def text(value: Optional[str], default: str) -> str:
            return value.strip() if value and value.strip() else default
        return cls(url=text(url, settings.engine_url).rstrip("/"), user=text(user, settings.engine_user),
                   password=password if password else settings.engine_password,
                   verify_tls=settings.engine_verify_tls if verify_tls is None else verify_tls, listen_port=listen_port or None)


class OpenIntegrationEngine:
    def __init__(self, session: Optional[requests.Session] = None, config: Optional[EngineConfig] = None):
        self.http = session or requests.Session()
        self.config = config or EngineConfig.resolve()
        self.logged_in = False

    def _url(self, path: str) -> str:
        return f"{self.config.url}/api{path}"

    def login(self) -> None:
        r = self.http.post(self._url("/users/_login"), data={"username": self.config.user, "password": self.config.password},
                           headers={"X-Requested-With": "OpenAPI", "Accept": "application/xml"}, verify=self.config.verify_tls, timeout=15)
        if r.status_code != 200 or "SUCCESS" not in r.text.upper():
            raise EngineError(f"Engine login failed: HTTP {r.status_code} {r.text[:200]}")
        self.logged_in = True

    def request(self, method: str, path: str, **kw) -> requests.Response:
        if not self.logged_in:
            self.login()
        headers = {"X-Requested-With": "OpenAPI", "Accept": "application/xml", **kw.pop("headers", {})}
        for attempt in (1, 2):
            r = self.http.request(method, self._url(path), headers=headers, verify=self.config.verify_tls, timeout=30, **kw)
            if r.status_code == 401 and attempt == 1:       # session expired
                self.logged_in = False
                self.login()
                continue
            break
        if r.status_code >= 400:
            raise EngineError(f"{method} {path} -> HTTP {r.status_code}: {r.text[:300]}")
        return r

    def channel_ids_by_name(self) -> dict:
        root = ET.fromstring(self.request("GET", "/channels/idsAndNames").text)
        out = {}
        for entry in root.iter("entry"):
            strings = [s.text for s in entry.findall("string")]
            if len(strings) == 2 and strings[0] and strings[1]:
                out[strings[1]] = strings[0]
        return out

    def listen_ports(self) -> dict:
        """{listen port: channel name} of every channel in the engine, so a new channel is not put on a port that is taken."""
        root = ET.fromstring(self.request("GET", "/channels").text)
        out = {}
        for channel in root.iter("channel"):
            port = channel.findtext("sourceConnector/properties/listenerConnectorProperties/port")
            if port and port.strip().isdigit():
                out[int(port)] = channel.findtext("name") or ""
        return out

    # Creating/updating a channel takes XML but answers "true"/"false" as text/plain or JSON only (asking for XML gets HTTP 406).
    def create_channel(self, xml: str) -> None:
        r = self.request("POST", "/channels", data=xml.encode("utf-8"), headers={"Content-Type": "application/xml", "Accept": "text/plain"})
        if r.text.strip().lower() == "false":
            raise EngineError("The engine refused to create the channel (it answered false)")

    def update_channel(self, channel_id: str, xml: str) -> None:
        r = self.request("PUT", f"/channels/{channel_id}", params={"override": "true"}, data=xml.encode("utf-8"),
                         headers={"Content-Type": "application/xml", "Accept": "text/plain"})
        if r.text.strip().lower() == "false":
            raise EngineError("The engine refused to update the channel (it answered false)")

    def deploy(self, channel_id: str) -> None:
        self.request("POST", f"/channels/{channel_id}/_deploy", params={"returnErrors": "true"})


def render_template(template_xml: str, channel_id: str, channel_name: str, values: dict) -> str:
    """Fills ${KEY} placeholders and gives the clone its own id and name (the first <id>/<name> in a channel are the channel's own)."""
    xml = template_xml
    for key, value in values.items():
        xml = xml.replace("${" + key + "}", escape(str(value)))
    xml = re.sub(r"<id>[^<]*</id>", f"<id>{channel_id}</id>", xml, count=1)
    xml = re.sub(r"<name>[^<]*</name>", f"<name>{escape(channel_name)}</name>", xml, count=1)
    return xml


def rabbitmq_publish_target() -> Optional[dict]:
    """Where a channel's HTTP Sender publishes: RabbitMQ's management API as the engine reaches it. None when RABBITMQ_API_URL is not set."""
    if not settings.rabbitmq_api_url:
        return None
    amqp = urlparse(settings.rabbitmq_url)
    vhost = amqp.path.lstrip("/") or "%2F"       # already percent-encoded in the AMQP URL ("/" is %2F)
    return {"RABBITMQ_PUBLISH_URL": f"{settings.rabbitmq_api_url}/api/exchanges/{vhost}/{settings.integration_exchange}/publish",
            "RABBITMQ_USER": unquote(amqp.username or "guest"), "RABBITMQ_PASSWORD": unquote(amqp.password or "guest")}


def provision_interface(*, analyzer_id: int, code: str, name: str, protocol: str, sending_app: Optional[str], tenant: str,
                        engine: Optional[OpenIntegrationEngine] = None, config: Optional[EngineConfig] = None) -> dict:
    """Returns {channelId, routingKey, status: PROVISIONED|PENDING|FAILED, message}. Never raises: Laboratory stores the status.
    The routing key names the tenant (lab.results.<tenant>.<analyzer>), so the device's results stay in that tenant's database."""
    routing_key = f"lab.results.{tenant}.{slug(code)}"
    config = config or (engine.config if engine else EngineConfig.resolve())

    def result(status: str, message: str, channel_id: str = "") -> dict:
        return {"channelId": channel_id, "routingKey": routing_key, "status": status, "message": message}

    if not config.url:
        return result("PENDING", "No engine URL was given for this device (and ENGINE_URL is not set), so no channel was created. Configure the "
                                 f"engine channel manually to publish to exchange '{settings.integration_exchange}' with routing key "
                                 f"'{routing_key}', or enter the engine URL and re-provision.")
    engine = engine or OpenIntegrationEngine(config=config)
    channel_name = f"HIMS-{code}"
    listen_port = config.listen_port or settings.engine_first_listen_port + analyzer_id
    context_path = f"/{slug(code)}"
    values = {
        "ANALYZER_ID": analyzer_id, "ANALYZER_CODE": code, "ANALYZER_NAME": name, "PROTOCOL": protocol,
        "SENDING_APPLICATION_ID": sending_app or code, "LISTEN_PORT": listen_port, "CONTEXT_PATH": context_path,
        "ROUTING_KEY": routing_key, "RABBITMQ_URI": settings.rabbitmq_url, "RABBITMQ_EXCHANGE": settings.integration_exchange,
        "HUB_INBOUND_URL": f"{settings.hub_public_url}/api/inbound?analyzer={code}&tenant={tenant}", "CHANNEL_NAME": channel_name,
    }
    try:
        ids = engine.channel_ids_by_name()
        if protocol not in BUILT_IN_TEMPLATES:
            return result("FAILED", f"There is no built-in channel template for protocol {protocol} (available: "
                                    f"{', '.join(BUILT_IN_TEMPLATES)}). Create the channel in the engine yourself.")
        target = rabbitmq_publish_target()
        if target is None:
            return result("FAILED", "RABBITMQ_API_URL is not set for the Integration Hub, so the channel would have nowhere to publish. "
                                    "Set it to RabbitMQ's management API address as the engine reaches it (services/integration-comms/.env).")
        values.update(target)
        template = (TEMPLATE_DIR / BUILT_IN_TEMPLATES[protocol]).read_text(encoding="utf-8")
        channel_id = ids.get(channel_name) or str(uuid.uuid4())
        values["CHANNEL_ID"] = channel_id
        xml = render_template(template, channel_id, channel_name, values)
        taken_by = engine.listen_ports().get(listen_port)
        if taken_by and taken_by != channel_name:
            return result("FAILED", f"Port {listen_port} is already used by channel '{taken_by}' in the engine. Enter a free listen port.")
        pathlib.Path("data").mkdir(exist_ok=True)
        pathlib.Path(f"data/last_rendered_channel_{code}.xml").write_text(xml, encoding="utf-8")
        log.info("Wrote rendered channel XML to data/last_rendered_channel_%s.xml for inspection", code)
        if channel_name in ids:
            engine.update_channel(channel_id, xml)
        else:
            engine.create_channel(xml)
        engine.deploy(channel_id)
        log.info("Provisioned engine channel %s (%s) on port %s", channel_name, channel_id, listen_port)
        where = f"port {listen_port}" + (f", path {context_path}" if protocol in HTTP_PROTOCOLS else "")
        return result("PROVISIONED", f"Channel '{channel_name}' {'updated' if channel_name in ids else 'created'} and deployed, listening on {where} "
                                     "inside the engine", channel_id)
    except (EngineError, requests.RequestException, ET.ParseError, OSError) as e:
        log.warning("Engine provisioning failed for %s: %s", code, e)
        return result("FAILED", str(e)[:400])
