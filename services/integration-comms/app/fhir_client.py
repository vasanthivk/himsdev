"""Minimal FHIR R4 REST client for the HAPI-FHIR server. Conditional updates make every write idempotent."""
import logging
from typing import Optional

import requests

from .config import settings

log = logging.getLogger("hub.fhir")
FHIR_JSON = "application/fhir+json"


class FhirError(RuntimeError):
    pass


class FhirClient:
    def __init__(self, base_url: Optional[str] = None, session: Optional[requests.Session] = None):
        self.base = (base_url or settings.hapi_fhir_url).rstrip("/")
        self.http = session or requests.Session()

    def conditional_put(self, resource_type: str, system: str, value: str, resource: dict) -> dict:
        """PUT [base]/Type?identifier=system|value  - creates the resource if none matches, updates it if one does.
        Returns {'id', 'versionId'}."""
        r = self.http.put(f"{self.base}/{resource_type}", params={"identifier": f"{system}|{value}"}, json=resource,
                          headers={"Content-Type": FHIR_JSON, "Accept": FHIR_JSON, "Prefer": "return=representation"}, timeout=20)
        if r.status_code not in (200, 201):
            raise FhirError(f"FHIR PUT {resource_type} failed: HTTP {r.status_code} {r.text[:300]}")
        body = r.json()
        return {"id": body["id"], "versionId": (body.get("meta") or {}).get("versionId")}

    def patch_status(self, resource_type: str, rid: str, status: str) -> None:
        r = self.http.patch(f"{self.base}/{resource_type}/{rid}", json=[{"op": "replace", "path": "/status", "value": status}],
                            headers={"Content-Type": "application/json-patch+json", "Accept": FHIR_JSON}, timeout=20)
        if r.status_code not in (200, 201, 204):
            raise FhirError(f"FHIR PATCH {resource_type}/{rid} failed: HTTP {r.status_code} {r.text[:300]}")

    def ping(self) -> bool:
        try:
            return self.http.get(f"{self.base}/metadata", params={"_summary": "true"}, headers={"Accept": FHIR_JSON}, timeout=5).status_code == 200
        except requests.RequestException:
            return False
