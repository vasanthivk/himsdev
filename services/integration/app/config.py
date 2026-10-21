"""All settings come from environment variables (services/integration/.env); defaults suit a local developer machine."""
import os
from dataclasses import dataclass


def _bool(name: str, default: bool) -> bool:
    return os.getenv(name, str(default)).strip().lower() in ("1", "true", "yes", "on")


@dataclass(frozen=True)
class Settings:
    database_url: str = os.getenv("DATABASE_URL", "postgresql://hims:hims@localhost:5432/hims_integration")
    rabbitmq_url: str = os.getenv("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/%2F")
    rabbitmq_enabled: bool = _bool("RABBITMQ_ENABLED", True)
    # RabbitMQ management (HTTP) API as the Open Integration Engine reaches it, e.g. http://rabbitmq:15672. Channels created for a
    # device publish through it, with the user/password of RABBITMQ_URL. Empty = channels cannot be created from the built-in templates.
    rabbitmq_api_url: str = os.getenv("RABBITMQ_API_URL", "").rstrip("/")

    # RabbitMQ topology (shared with the .NET services for hims.events)
    events_exchange: str = os.getenv("EVENTS_EXCHANGE", "hims.events")
    dead_letter_exchange: str = "hims.events.dlx"
    integration_exchange: str = os.getenv("INTEGRATION_EXCHANGE", "hims.integration")   # the engine publishes device messages here
    results_queue: str = os.getenv("RESULTS_QUEUE", "lab.results")
    events_queue: str = "integration.events"

    service_name: str = "integration"
    hapi_fhir_url: str = os.getenv("HAPI_FHIR_URL", "http://103.169.179.22:50060/fhir").rstrip("/")
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
    log_dir: str = os.getenv("LOG_DIR", "../../logs/integration")   # daily files dd-MM-yyyy.log; default = <repo>/logs/integration when run from services/integration
    device_timezone: str = os.getenv("DEVICE_TIMEZONE", "Asia/Kolkata")   # HL7 timestamps without an offset are in this zone
    enable_simulator: bool = _bool("ENABLE_SIMULATOR", True)
    cors_origins: tuple = tuple(o for o in os.getenv("CORS_ORIGINS", ",".join(["https://localhost:3000"] + ["http://localhost:%d" % p for p in [3000] + list(range(3001, 3014))])).split(",") if o)
    cors_origin_regex: str = os.getenv("CORS_ORIGIN_REGEX", r"https://[a-z0-9-]+\.localhost:3000")   # every tenant subdomain, e.g. https://apollo.localhost:3000


settings = Settings()
