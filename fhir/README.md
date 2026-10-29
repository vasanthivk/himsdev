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

## Test

```bash
# Capability statements
curl http://localhost:8080/reddys/fhir/metadata
curl http://localhost:8080/apollo/fhir/metadata

# Create a patient in Reddys only
curl -X POST http://localhost:8080/reddys/fhir/Patient \
  -H "Content-Type: application/fhir+json" \
  -d '{"resourceType":"Patient","name":[{"family":"Rao","given":["Kiran"]}]}'

# Should appear in Reddys, not in Apollo
curl "http://localhost:8080/reddys/fhir/Patient?family=Rao"
curl "http://localhost:8080/apollo/fhir/Patient?family=Rao"
```

Web test UI: `http://localhost:8080/reddys/` and `http://localhost:8080/apollo/`.

## Adding a tenant

1. Add `CREATE DATABASE fhir_<name> OWNER hims;` and run it.
2. Copy the `hapi-apollo` service in `docker-compose.yml`, renaming the service, DB name and URLs.
3. Add a `location /<name>/ { proxy_pass http://hapi-<name>:8080/; }` block to `nginx.conf`.
4. `docker compose up -d`.

## Production notes

- **Rotate the DB password** (it was shared in chat) and keep `.env` out of version control.
- Consider a separate DB user per tenant (`hims_reddys`, `hims_apollo`) for stronger isolation.
- Pin `HAPI_IMAGE` to a specific version instead of `latest`.
- Put TLS and authentication (e.g. OAuth2/SMART proxy or nginx auth) in front of the gateway —
  HAPI has no auth enabled by default.
- Each instance uses up to 20 DB connections (`SPRING_DATASOURCE_HIKARI_MAXIMUMPOOLSIZE`);
  check this against PostgreSQL `max_connections`.
