"""All settings come from environment variables (see .env.example); defaults suit a local developer machine."""
import os
from dataclasses import dataclass


def _bool(name: str, default: bool) -> bool:
    return os.getenv(name, str(default)).strip().lower() in ("1", "true", "yes", "on")


@dataclass(frozen=True)
class Settings:
    database_url: str = os.getenv("DATABASE_URL", "postgresql://hims:hims@localhost:5432/hims_integration")
    rabbitmq_url: str = os.getenv("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/%2F")
    rabbitmq_enabled: bool = _bool("RABBITMQ_ENABLED", True)

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
    engine_template_channel: str = os.getenv("ENGINE_TEMPLATE_CHANNEL", "HIMS-Analyzer-Template")   # channel cloned for every analyzer
    engine_first_listen_port: int = int(os.getenv("ENGINE_FIRST_LISTEN_PORT", "6661"))
    hub_public_url: str = os.getenv("HUB_PUBLIC_URL", "http://localhost:5011").rstrip("/")   # where the engine's HTTP Sender posts
    engine_channel_url: str = os.getenv("ENGINE_CHANNEL_URL", "").rstrip("/")  # the deployed channel's own HTTP endpoint, e.g. http://103.169.179.22:50057/hims-lab
    
    payload_dir: str = os.getenv("PAYLOAD_DIR", "./data/payloads")
    device_timezone: str = os.getenv("DEVICE_TIMEZONE", "Asia/Kolkata")   # HL7 timestamps without an offset are in this zone
    enable_simulator: bool = _bool("ENABLE_SIMULATOR", True)
    cors_origins: tuple = tuple(o for o in os.getenv("CORS_ORIGINS", ",".join("http://localhost:%d" % p for p in [3000] + list(range(3001, 3014)))).split(",") if o)


settings = Settings()
