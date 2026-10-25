"""CloudEvents-style envelope: identical JSON to the one the .NET services publish (Hims.Common EventEnvelope)."""
from datetime import datetime, timezone
from typing import Any, Optional


def iso(dt: datetime) -> str:
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"


def build_envelope(*, event_id: str, event_type: str, source: str, aggregate_type: str, aggregate_id: int, data: Any,
                   time: datetime, source_version: int, organization_id: Optional[int] = None, branch_id: Optional[int] = None,
                   patient_id: Optional[int] = None, correlation_id: Optional[str] = None, event_version: int = 1) -> dict:
    return {
        "specVersion": "1.0", "id": event_id, "type": event_type, "source": source,
        "subject": f"{aggregate_type}/{aggregate_id}", "time": iso(time), "data": data,
        "organizationId": organization_id, "branchId": branch_id, "patientId": patient_id, "correlationId": correlation_id,
        "aggregateType": aggregate_type, "aggregateId": aggregate_id, "eventVersion": event_version, "sourceVersion": source_version,
    }
