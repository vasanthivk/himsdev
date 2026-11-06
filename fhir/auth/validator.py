"""Token check for the FHIR gateway. nginx sends every request here first (auth_request) and forwards it to HAPI only on 204.

The caller sends Authorization: Bearer <access token> from the tenant's WSO2 Identity Server (client credentials grant). The token
must be a JWT signed by that tenant's WSO2 IS (<TENANT>_JWKS_URL), issued by it (<TENANT>_ISSUER) and not expired. The tenant is the
first path segment (/reddys/fhir/... -> REDDYS_*), so a Reddys token is refused on /apollo/fhir. Reads (GET/HEAD) need
FHIR_READ_SCOPE, every other method FHIR_WRITE_SCOPE. A refusal is 401 (no / bad token) or 403 (wrong scope) with the reason in the
X-Auth-Error header, which nginx puts into an OperationOutcome.
"""
import json
import logging
import os
import ssl
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Optional

import jwt

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"), format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("fhir-auth")

READ_SCOPE = os.getenv("FHIR_READ_SCOPE", "fhir.read")
WRITE_SCOPE = os.getenv("FHIR_WRITE_SCOPE", "fhir.write")
AUDIENCE = os.getenv("FHIR_AUDIENCE", "").strip() or None   # empty = aud is not checked
READ_METHODS = {"GET", "HEAD", "OPTIONS"}

def _off(name: str, default: str = "true") -> bool:
    return os.getenv(name, default).strip().lower() in ("0", "false", "no", "off")


# WSO2 IS ships with a self-signed certificate: JWKS_CA_FILE trusts exactly that certificate (pinned) instead of the public CAs.
# Its default certificate names only localhost / 127.0.0.1, so when the JWKS URL uses another address, JWKS_CHECK_HOSTNAME=false
# skips the name check - the pinned certificate (and so the WSO2 private key) is still required.
_ca_file = os.getenv("JWKS_CA_FILE", "").strip() or None
_ssl = ssl.create_default_context(cafile=_ca_file)
if _ca_file:
    _ssl.verify_flags |= ssl.VERIFY_X509_PARTIAL_CHAIN   # accept the self-signed leaf itself as the trust anchor
    if _off("JWKS_CHECK_HOSTNAME"):
        _ssl.check_hostname = False
# Dev only: no certificate check at all.
if _off("JWKS_VERIFY_TLS"):
    _ssl.check_hostname = False
    _ssl.verify_mode = ssl.CERT_NONE

_jwks: dict = {}   # tenant -> PyJWKClient (keys are cached and refetched when a token names an unknown key id)
_lock = threading.Lock()


class Refused(Exception):
    def __init__(self, status: int, reason: str):
        super().__init__(reason)
        self.status = status


def tenant_settings(tenant: str) -> tuple:
    """(issuer, jwks client) of the tenant, from <TENANT>_ISSUER and <TENANT>_JWKS_URL."""
    prefix = tenant.upper().replace("-", "_")
    issuer, jwks_url = os.getenv(f"{prefix}_ISSUER", "").strip(), os.getenv(f"{prefix}_JWKS_URL", "").strip()
    if not issuer or not jwks_url:
        raise Refused(401, f"No identity provider is configured for tenant {tenant}")
    with _lock:
        if tenant not in _jwks:
            _jwks[tenant] = jwt.PyJWKClient(jwks_url, cache_keys=True, lifespan=3600, ssl_context=_ssl)
        return issuer, _jwks[tenant]


def check(method: str, uri: str, authorization: str) -> dict:
    """The token's claims when it may make this request; raises Refused otherwise."""
    tenant = uri.lstrip("/").split("/", 1)[0].split("?", 1)[0]
    if not tenant:
        raise Refused(401, "No tenant in the request path")
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token.strip():
        raise Refused(401, "Missing Authorization: Bearer token")
    token = token.strip()
    if token.count(".") != 2:
        raise Refused(401, "The access token is not a JWT - set Access Token Type to JWT on the WSO2 application")

    issuer, jwks = tenant_settings(tenant)
    try:
        key = jwks.get_signing_key_from_jwt(token)
        claims = jwt.decode(token, key.key, algorithms=["RS256", "RS384", "RS512", "PS256", "ES256"], issuer=issuer,
                            audience=AUDIENCE, options={"verify_aud": AUDIENCE is not None, "require": ["exp", "iss"]}, leeway=60)
    except jwt.InvalidIssuerError:
        actual = jwt.decode(token, options={"verify_signature": False}).get("iss")
        raise Refused(401, f"Token issuer {actual} is not {issuer} (tenant {tenant})")
    except jwt.ExpiredSignatureError:
        raise Refused(401, "The access token has expired")
    except jwt.PyJWKClientError as e:
        log.error("JWKS for %s: %s", tenant, e)
        raise Refused(401, f"Cannot verify the token signature for tenant {tenant}")
    except jwt.InvalidTokenError as e:
        raise Refused(401, f"Invalid access token: {e}")

    scopes = claims.get("scope", "")
    scopes = set(scopes.split() if isinstance(scopes, str) else scopes)
    needed = READ_SCOPE if method.upper() in READ_METHODS else WRITE_SCOPE
    if needed not in scopes:
        raise Refused(403, f"The token lacks scope {needed}")
    return claims


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            return self._reply(200)
        method, uri = self.headers.get("X-Original-Method", ""), self.headers.get("X-Original-URI", "")
        try:
            claims = check(method, uri, self.headers.get("Authorization", ""))
        except Refused as e:
            log.warning("%d %s %s: %s", e.status, method, uri, e)
            return self._reply(e.status, str(e))
        log.info("204 %s %s client=%s", method, uri, claims.get("client_id") or claims.get("azp") or claims.get("sub"))
        self._reply(204)

    def _reply(self, status: int, error: Optional[str] = None):
        self.send_response(status)
        if error:
            # Goes into the OperationOutcome nginx builds: keep it to a safe JSON string.
            self.send_header("X-Auth-Error", json.dumps(error)[1:-1].replace('\\"', "'"))
            self.send_header("WWW-Authenticate", 'Bearer error="invalid_token"' if status == 401 else 'Bearer error="insufficient_scope"')
        self.send_header("Content-Length", "0")
        self.end_headers()

    def log_message(self, *_):   # requests are logged in do_GET
        pass


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8000"))
    log.info("FHIR token check on :%d (read scope %s, write scope %s, audience %s)", port, READ_SCOPE, WRITE_SCOPE, AUDIENCE or "-")
    ThreadingHTTPServer(("0.0.0.0", port), Handler).serve_forever()
