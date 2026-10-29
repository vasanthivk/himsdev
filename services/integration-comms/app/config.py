"""All settings come from environment variables (services/integration-comms/.env); defaults suit a local developer machine."""
import os
from dataclasses import dataclass


def _bool(name: str, default: bool) -> bool:
    return os.getenv(name, str(default)).strip().lower() in ("1", "true", "yes", "on")


@dataclass(frozen=True)
class Settings:
    # Databases: one per tenant, <SUBDOMAIN>_DATABASE_URL (see load_tenants()).
    # Schema of this service in the shared database (himsdev: integration_comms) - tables are <schema>.<old schema>_<table>.
    # Empty = a database of its own with the original schemas (intg.message_log, evt.outbox, ...).
    db_schema: str = os.getenv("DB_SCHEMA", "").strip()
    rabbitmq_url: str = os.getenv("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/%2F")
    rabbitmq_enabled: bool = _bool("RABBITMQ_ENABLED", True)
    # RabbitMQ management (HTTP) API as the Open Integration Engine reaches it, e.g. http://rabbitmq:15672. Channels created for a
    # device publish through it, with the user/password of RABBITMQ_URL. Empty = channels cannot be created from the built-in templates.
    rabbitmq_api_url: str = os.getenv("RABBITMQ_API_URL", "").rstrip("/")

    # RabbitMQ topology (shared with the .NET services): one topic exchange per tenant, {tenant} = tenant name
    # (hims.reddys.events, hims.apollo.events), and one queue per tenant for this hub (integration-comms.reddys.events, ...).
    events_exchange: str = os.getenv("EVENTS_EXCHANGE", "hims.{tenant}.events")
    dead_letter_exchange: str = "hims.events.dlx"
    integration_exchange: str = os.getenv("INTEGRATION_EXCHANGE", "hims.integration")   # the engine publishes device messages here
    results_queue: str = os.getenv("RESULTS_QUEUE", "lab.results")
    events_queue: str = "integration-comms.{tenant}.events"

    service_name: str = "integration-comms"
    # FHIR server per tenant: <SUBDOMAIN>_FHIR_URL (see load_tenants()). HAPI_FHIR_URL is only a
    # fallback for an event whose organization has no tenant entry; empty = such an event fails instead of going to a shared server.
    hapi_fhir_url: str = os.getenv("HAPI_FHIR_URL", "").rstrip("/")
    fhir_sync_enabled: bool = _bool("FHIR_SYNC_ENABLED", True)

    # Open Integration Engine (Mirth-compatible REST API). Empty ENGINE_URL = engine provisioning disabled.
    engine_url: str = os.getenv("ENGINE_URL", "").rstrip("/")
    engine_user: str = os.getenv("ENGINE_USER", "admin")
    engine_password: str = os.getenv("ENGINE_PASSWORD", "admin")
    engine_verify_tls: bool = _bool("ENGINE_VERIFY_TLS", False)
    engine_first_listen_port: int = int(os.getenv("ENGINE_FIRST_LISTEN_PORT", "6661"))   # + analyzer id, when no listen port is entered for the device
    hub_public_url: str = os.getenv("HUB_PUBLIC_URL", "http://localhost:5011").rstrip("/")   # where the engine's HTTP Sender posts
    engine_channel_url: str = os.getenv("ENGINE_CHANNEL_URL", "").rstrip("/")  # the deployed channel's own HTTP endpoint, e.g. http://103.169.179.22:50057/hims-lab
    
    payload_dir: str = os.getenv("PAYLOAD_DIR", "./data/payloads")
    log_dir: str = os.getenv("LOG_DIR", "../../logs/integration-comms")   # daily files dd-MM-yyyy.log; default = <repo>/logs/integration-comms when run from services/integration-comms
    device_timezone: str = os.getenv("DEVICE_TIMEZONE", "Asia/Kolkata")   # HL7 timestamps without an offset are in this zone
    enable_simulator: bool = _bool("ENABLE_SIMULATOR", True)
    cors_origins: tuple = tuple(o for o in os.getenv("CORS_ORIGINS", ",".join(["https://localhost:3000"] + ["http://localhost:%d" % p for p in [3000] + list(range(3001, 3014))])).split(",") if o)
    cors_origin_regex: str = os.getenv("CORS_ORIGIN_REGEX", r"https://[a-z0-9-]+\.localhost:3000")   # every tenant subdomain, e.g. https://apollo.localhost:3000

    def exchange_for(self, tenant: str) -> str:
        """The tenant's events exchange: "apollo" -> hims.apollo.events."""
        return self.events_exchange.replace("{tenant}", tenant)

    def queue_for(self, tenant: str) -> str:
        """This hub's queue on the tenant's exchange: "apollo" -> integration-comms.apollo.events."""
        return self.events_queue.replace("{tenant}", tenant)


settings = Settings()


@dataclass(frozen=True)
class Tenant:
    subdomain: str        # e.g. "reddys" (https://reddys.localhost:3000)
    organization_id: int  # HIMS core.organization of the tenant
    database_url: str     # the tenant's own database, e.g. .../hims_reddys
    fhir_url: str         # e.g. http://localhost:8080/reddys/fhir; empty = HAPI_FHIR_URL


def load_tenants() -> list:
    """Every tenant, from <SUBDOMAIN>_ORGANIZATION_ID with its <SUBDOMAIN>_DATABASE_URL and <SUBDOMAIN>_FHIR_URL, e.g.
    REDDYS_ORGANIZATION_ID=1, REDDYS_DATABASE_URL=postgresql://.../hims_reddys, REDDYS_FHIR_URL=http://localhost:8080/reddys/fhir.
    Ordered by organization id; the first is the default (a request or device message that names no organization)."""
    tenants = []
    for key, org in os.environ.items():
        if not key.endswith("_ORGANIZATION_ID") or not org.strip():
            continue
        prefix = key[: -len("_ORGANIZATION_ID")]
        if not org.strip().isdigit():
            raise RuntimeError(f"{key} is not a number")
        database_url = os.getenv(f"{prefix}_DATABASE_URL", "").strip()
        if not database_url:
            raise RuntimeError(f"{key} is set but {prefix}_DATABASE_URL is missing")
        tenants.append(Tenant(prefix.lower(), int(org), database_url, os.getenv(f"{prefix}_FHIR_URL", "").strip().rstrip("/")))
    if not tenants:
        raise RuntimeError("No tenant configured: set <SUBDOMAIN>_ORGANIZATION_ID and <SUBDOMAIN>_DATABASE_URL (e.g. REDDYS_...)")
    return sorted(tenants, key=lambda t: t.organization_id)
