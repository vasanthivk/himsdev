"""Minimal FHIR R4 REST client for the HAPI-FHIR server. Conditional updates make every write idempotent.
Authentication: a WSO2 IS access token of the tenant (client credentials grant), sent as Authorization: Bearer - see ClientCredentials."""
import logging
import threading
import time
from typing import Optional, Union

import requests

from .config import Tenant, settings

log = logging.getLogger("hub.fhir")
FHIR_JSON = "application/fhir+json"


class FhirError(RuntimeError):
    pass


class ClientCredentials(requests.auth.AuthBase):
    """Bearer token from the tenant's WSO2 IS token endpoint, fetched with the client credentials grant and reused until shortly
    before it expires. Shared by every FhirClient of the tenant; thread-safe (each tenant's consumer runs in its own thread)."""

    def __init__(self, token_url: str, client_id: str, client_secret: str, scope: str = "", verify_tls: Union[bool, str] = True):
        self.token_url, self.client_id, self.client_secret, self.scope, self.verify_tls = token_url, client_id, client_secret, scope, verify_tls
        self._token: Optional[str] = None
        self._expires_at = 0.0
        self._lock = threading.Lock()

    def token(self) -> str:
        with self._lock:
            if self._token is None or time.monotonic() >= self._expires_at:
                self._fetch()
            return self._token

    def invalidate(self) -> None:
        with self._lock:
            self._token = None

    def _fetch(self) -> None:
        data = {"grant_type": "client_credentials"}
        if self.scope:
            data["scope"] = self.scope
        try:
            r = requests.post(self.token_url, data=data, auth=(self.client_id, self.client_secret),
                              headers={"Accept": "application/json"}, timeout=15, verify=self.verify_tls)
        except requests.RequestException as e:
            raise FhirError(f"Cannot reach the FHIR token endpoint {self.token_url}: {e}") from e
        if r.status_code != 200:
            raise FhirError(f"FHIR token request failed: HTTP {r.status_code} {r.text[:300]}")
        body = r.json()
        granted = set(body.get("scope", "").split())
        missing = set(self.scope.split()) - granted
        if missing:
            log.warning("FHIR token for %s lacks scope(s) %s - authorize them on the WSO2 application", self.client_id, " ".join(sorted(missing)))
        self._token = body["access_token"]
        self._expires_at = time.monotonic() + max(int(body.get("expires_in", 3600)) - 60, 30)   # renew a minute early
        log.info("FHIR token for %s obtained (expires in %ss)", self.client_id, body.get("expires_in"))

    def __call__(self, r: requests.PreparedRequest) -> requests.PreparedRequest:
        r.headers["Authorization"] = f"Bearer {self.token()}"
        return r


_auth: dict = {}   # token URL + client id -> ClientCredentials
_auth_lock = threading.Lock()


def auth_for(tenant: Tenant) -> Optional[ClientCredentials]:
    """The tenant's FHIR credentials, or None when it has no <SUBDOMAIN>_FHIR_TOKEN_URL (FHIR called without a token)."""
    if not tenant.fhir_token_url:
        return None
    key = (tenant.fhir_token_url, tenant.fhir_client_id)
    with _auth_lock:
        if key not in _auth:
            _auth[key] = ClientCredentials(tenant.fhir_token_url, tenant.fhir_client_id, tenant.fhir_client_secret,
                                           settings.fhir_scope, settings.fhir_token_ca_file or settings.fhir_token_verify_tls)
        return _auth[key]


class FhirClient:
    def __init__(self, base_url: Optional[str] = None, session: Optional[requests.Session] = None, auth: Optional[ClientCredentials] = None):
        self.base = (base_url or settings.hapi_fhir_url).rstrip("/")
        self.http = session or requests.Session()
        self.auth = auth

    def _request(self, method: str, url: str, **kwargs) -> requests.Response:
        """Sends the request with the tenant's token; on 401 (token revoked or keys rotated) gets a new token and tries once more."""
        r = self.http.request(method, url, auth=self.auth, **kwargs)
        if r.status_code == 401 and self.auth is not None:
            log.warning("FHIR %s %s: 401, renewing the token", method, url)
            self.auth.invalidate()
            r = self.http.request(method, url, auth=self.auth, **kwargs)
        return r

    def conditional_put(self, resource_type: str, system: str, value: str, resource: dict) -> dict:
        """PUT [base]/Type?identifier=system|value  - creates the resource if none matches, updates it if one does.
        Returns {'id', 'versionId'}."""
        r = self._request("PUT", f"{self.base}/{resource_type}", params={"identifier": f"{system}|{value}"}, json=resource,
                          headers={"Content-Type": FHIR_JSON, "Accept": FHIR_JSON, "Prefer": "return=representation"}, timeout=20)
        if r.status_code not in (200, 201):
            raise FhirError(f"FHIR PUT {resource_type} failed: HTTP {r.status_code} {r.text[:300]}")
        body = r.json()
        return {"id": body["id"], "versionId": (body.get("meta") or {}).get("versionId")}

    def patch_status(self, resource_type: str, rid: str, status: str) -> None:
        r = self._request("PATCH", f"{self.base}/{resource_type}/{rid}", json=[{"op": "replace", "path": "/status", "value": status}],
                          headers={"Content-Type": "application/json-patch+json", "Accept": FHIR_JSON}, timeout=20)
        if r.status_code not in (200, 201, 204):
            raise FhirError(f"FHIR PATCH {resource_type}/{rid} failed: HTTP {r.status_code} {r.text[:300]}")

    def ping(self) -> bool:
        try:
            return self._request("GET", f"{self.base}/metadata", params={"_summary": "true"}, headers={"Accept": FHIR_JSON}, timeout=5).status_code == 200
        except (requests.RequestException, FhirError):
            return False
