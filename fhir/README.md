# Multi-tenant HAPI FHIR (Reddys, Apollo)

Each tenant gets its own HAPI FHIR instance and its own PostgreSQL database on
`192.168.7.164:50085`, so data is physically separated. An nginx gateway routes by URL prefix.

| Tenant | FHIR base URL                         | Database      |
|--------|---------------------------------------|---------------|
| Reddys | `http://<host>:8080/reddys/fhir`      | `hims_fhir_reddys` |
| Apollo | `http://<host>:8080/apollo/fhir`      | `hims_fhir_apollo` |

> Why not HAPI's built-in multitenancy? HAPI's "partitioning" keeps all tenants in **one**
> database (rows tagged by partition). Separate databases per tenant require separate instances,
> which is what this setup does.

## Setup

1. **Create the databases** (once, as a superuser or a role with CREATEDB):
   ```bash
   psql -h 192.168.7.164 -p 50085 -U postgres -f 01-create-tenant-databases.sql
   ```
   If `hims` already has CREATEDB, you can run it as `hims` (drop the `OWNER hims` clause if needed).

2. **Set the public URL** in `.env` — `PUBLIC_BASE_URL` must be the address clients use
   (e.g. `http://192.168.7.50:8080` or `https://fhir.example.com`), otherwise links in
   Bundles will point to the wrong place.

3. **Start**:
   ```bash
   docker compose up -d
   docker compose logs -f hapi-reddys hapi-apollo
   ```
   First startup takes 1–3 minutes while HAPI creates its schema in each database.

## Authentication

Every request needs `Authorization: Bearer <token>`, where the token is a WSO2 Identity Server access token (JWT) of the tenant in
the path. nginx asks `fhir-auth` ([auth/validator.py](auth/validator.py)) before forwarding anything to HAPI:

| Check | Refused with |
|-------|--------------|
| Signature (tenant's `<TENANT>_JWKS_URL`), expiry, issuer = `<TENANT>_ISSUER` | 401 |
| A Reddys token used on `/apollo/fhir` (the issuer is the tenant's) | 401 |
| `fhir.read` for GET/HEAD, `fhir.write` for POST/PUT/PATCH/DELETE | 403 |

In each WSO2 IS tenant: an API resource "HIMS FHIR" with the scopes `fhir.read` and `fhir.write`, and a Machine-to-Machine
application per caller (client credentials grant, access token type **JWT**) authorized for it. The Integration Hub takes its
credentials from `<SUBDOMAIN>_FHIR_TOKEN_URL / _FHIR_CLIENT_ID / _FHIR_CLIENT_SECRET` in `services/integration-comms/.env`.

The HAPI web test UI (`/reddys/`, `/apollo/`) is behind the same check, so it is not usable from a browser any more.

## Test

```bash
# A token of the Reddys tenant
TOKEN=$(curl -sk -u "<CLIENT_ID>:<CLIENT_SECRET>" -d "grant_type=client_credentials&scope=fhir.read fhir.write" \
  https://localhost:9443/t/newmeksolutions.com/oauth2/token | jq -r .access_token)

# Capability statement (401 without the token)
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/reddys/fhir/metadata

# Create a patient in Reddys only
curl -X POST http://localhost:8080/reddys/fhir/Patient -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/fhir+json" \
  -d '{"resourceType":"Patient","name":[{"family":"Rao","given":["Kiran"]}]}'

# Found in Reddys; the same token is refused on Apollo (401)
curl -H "Authorization: Bearer $TOKEN" "http://localhost:8080/reddys/fhir/Patient?family=Rao"
curl -H "Authorization: Bearer $TOKEN" "http://localhost:8080/apollo/fhir/Patient?family=Rao"
```

## Adding a tenant

1. Add `CREATE DATABASE fhir_<name> OWNER hims;` and run it.
2. Copy the `hapi-apollo` service in `docker-compose.yml`, renaming the service, DB name and URLs.
3. Add a `location /<name>/ { proxy_pass http://hapi-<name>:8080/; }` block to `nginx.conf`.
4. `docker compose up -d`.

## Production notes

- **Rotate the DB password** (it was shared in chat) and keep `.env` out of version control.
- Consider a separate DB user per tenant (`hims_reddys`, `hims_apollo`) for stronger isolation.
- Pin `HAPI_IMAGE` to a specific version instead of `latest`.
- Put TLS in front of the gateway: bearer tokens must not travel over plain HTTP.
- Each instance uses up to 20 DB connections (`SPRING_DATASOURCE_HIKARI_MAXIMUMPOOLSIZE`);
  check this against PostgreSQL `max_connections`.
