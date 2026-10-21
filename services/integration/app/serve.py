"""
Starts the Integration Hub on HTTP and, when SSL_CERTFILE and SSL_KEYFILE are set, on HTTPS as well - both in ONE process, so
the background workers (outbox relay, device consumer, FHIR sync) run once. The HTTPS server skips the app lifespan for that reason.

    python -m app.serve

Env: HUB_HOST (default 0.0.0.0, reachable from WSL / WSO2 API Manager), HUB_PORT (5011), HUB_HTTPS_PORT (7011),
     SSL_CERTFILE / SSL_KEYFILE (PEM files; HTTPS is off when either is empty).
"""
import asyncio
import os

import uvicorn


def _servers() -> list:
    host = os.getenv("HUB_HOST", "0.0.0.0")
    # Both configs are built before the app is imported, like the uvicorn CLI does, so the hub's own logging setup wins.
    configs = [uvicorn.Config("app.main:app", host=host, port=int(os.getenv("HUB_PORT", "5011")))]
    certfile, keyfile = os.getenv("SSL_CERTFILE", ""), os.getenv("SSL_KEYFILE", "")
    if certfile and keyfile:
        configs.append(uvicorn.Config("app.main:app", host=host, port=int(os.getenv("HUB_HTTPS_PORT", "7011")),
                                      ssl_certfile=certfile, ssl_keyfile=keyfile, lifespan="off"))
    return [uvicorn.Server(c) for c in configs]


async def main() -> None:
    await asyncio.gather(*(s.serve() for s in _servers()))


if __name__ == "__main__":
    asyncio.run(main())
