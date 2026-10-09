"""
Open Integration Engine (Mirth Connect compatible REST API) provisioning.

"Add a device" in Laboratory ends here. Instead of hand-building channel XML, the hub CLONES a template channel that you create
once in the engine (see docs/ENGINE_TEMPLATE.md), replaces the ${PLACEHOLDERS} in it, creates/updates the channel named
HIMS-<analyzer code> and deploys it. The channel listens for the instrument (HL7 v2 over MLLP, HL7 v3, FHIR ...) and publishes the
raw message to RabbitMQ (exchange hims.integration, routing key lab.results.<code>) where this hub's device consumer picks it up.
"""
import logging
import re
import uuid
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from typing import Optional
from xml.sax.saxutils import escape

import requests

from .config import settings

log = logging.getLogger("hub.engine")


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
    template_channel: str
    first_listen_port: int
    hub_public_url: str

    @classmethod
    def resolve(cls, *, url: Optional[str] = None, user: Optional[str] = None, password: Optional[str] = None,
                verify_tls: Optional[bool] = None, template_channel: Optional[str] = None, first_listen_port: Optional[int] = None,
                hub_public_url: Optional[str] = None) -> "EngineConfig":
        def text(value: Optional[str], default: str) -> str:
            return value.strip() if value and value.strip() else default
        return cls(url=text(url, settings.engine_url).rstrip("/"), user=text(user, settings.engine_user),
                   password=password if password else settings.engine_password,
                   verify_tls=settings.engine_verify_tls if verify_tls is None else verify_tls,
                   template_channel=text(template_channel, settings.engine_template_channel),
                   first_listen_port=first_listen_port or settings.engine_first_listen_port,
                   hub_public_url=text(hub_public_url, settings.hub_public_url).rstrip("/"))


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

    def get_channel_xml(self, channel_id: str) -> str:
        return self.request("GET", f"/channels/{channel_id}").text

    def create_channel(self, xml: str) -> None:
        self.request("POST", "/channels", data=xml.encode("utf-8"), headers={"Content-Type": "application/xml"})

    def update_channel(self, channel_id: str, xml: str) -> None:
        self.request("PUT", f"/channels/{channel_id}", params={"override": "true"}, data=xml.encode("utf-8"), headers={"Content-Type": "application/xml"})

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


def provision_interface(*, analyzer_id: int, code: str, name: str, protocol: str, sending_app: Optional[str], host: Optional[str],
                        port: Optional[int], engine: Optional[OpenIntegrationEngine] = None, config: Optional[EngineConfig] = None) -> dict:
    """Returns {channelId, routingKey, status: PROVISIONED|PENDING|FAILED, message}. Never raises: Laboratory stores the status."""
    routing_key = f"lab.results.{slug(code)}"
    config = config or (engine.config if engine else EngineConfig.resolve())
    if not config.url:
        return {"channelId": "", "routingKey": routing_key, "status": "PENDING",
                "message": "No engine URL was given for this device (and ENGINE_URL is not set), so no channel was created. Configure the "
                           f"engine channel manually to publish to exchange '{settings.integration_exchange}' with routing key "
                           f"'{routing_key}', or enter the engine URL and re-provision."}
    engine = engine or OpenIntegrationEngine(config=config)
    channel_name = f"HIMS-{code}"
    try:
        ids = engine.channel_ids_by_name()
        if config.template_channel not in ids:
            return {"channelId": "", "routingKey": routing_key, "status": "FAILED",
                    "message": f"Template channel '{config.template_channel}' was not found in the engine. Create it once (docs/ENGINE_TEMPLATE.md)."}
        template = engine.get_channel_xml(ids[config.template_channel])
        channel_id = ids.get(channel_name) or str(uuid.uuid4())
        xml = render_template(template, channel_id, channel_name, {
            "ANALYZER_ID": analyzer_id, "ANALYZER_CODE": code, "ANALYZER_NAME": name, "PROTOCOL": protocol,
            "SENDING_APPLICATION_ID": sending_app or code, "DEVICE_HOST": host or "", "LISTEN_PORT": port or config.first_listen_port + analyzer_id,
            "ROUTING_KEY": routing_key, "RABBITMQ_URI": settings.rabbitmq_url, "RABBITMQ_EXCHANGE": settings.integration_exchange,
            "HUB_INBOUND_URL": f"{config.hub_public_url}/api/inbound?analyzer={code}",
        })
        import pathlib
        pathlib.Path("data").mkdir(exist_ok=True)
        pathlib.Path(f"data/last_rendered_channel_{code}.xml").write_text(xml, encoding="utf-8")
        log.info("Wrote rendered channel XML to data/last_rendered_channel_%s.xml for inspection", code)
        if channel_name in ids:
            engine.update_channel(channel_id, xml)
        else:
            engine.create_channel(xml)
        engine.deploy(channel_id)
        log.info("Provisioned engine channel %s (%s)", channel_name, channel_id)
        return {"channelId": channel_id, "routingKey": routing_key, "status": "PROVISIONED", "message": f"Channel '{channel_name}' deployed"}
    except (EngineError, requests.RequestException, ET.ParseError) as e:
        log.warning("Engine provisioning failed for %s: %s", code, e)
        return {"channelId": "", "routingKey": routing_key, "status": "FAILED", "message": str(e)[:400]}
