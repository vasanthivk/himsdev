# tenant.sh — onboard a new tenant (hospital group)

Creates everything a new tenant needs on the database_v3 model:

1. **its own PostgreSQL database**, with the 7 service schemas from `database_v3/`
2. **its organization** in `identity_org.core_organization`
3. **an `OrganizationUpdated` event on RabbitMQ**, so the other microservices copy the organization into their
   `ref_organization` tables

No application code changes are needed — only each service's configuration (see [After running it](#after-running-it)).

```bash
cd hims
sed -i 's/\r$//' scripts/tenant.sh   # only needed once, if the file has Windows line endings
chmod +x scripts/tenant.sh           # only needed once
```

## Prerequisites

| Tool | Why |
|---|---|
| `psql`, `createdb` (PostgreSQL client 15+) | create the database, load the schemas, write the organization |
| `curl` 7.76+ | call the RabbitMQ management API (`--fail-with-body`) |
| RabbitMQ **management plugin** (port 15672) | publishing goes through its HTTP API; the `rabbitmq:3.13-management` image in `docker-compose.yml` has it |
| A database login with `CREATEDB` | only the first time, to create the database |

## Commands

```bash
./scripts/tenant.sh database <db options>                    # 1. create the database and load the schemas
./scripts/tenant.sh tenant   <db options> <tenant options>   # 2. create the organization and sync it over RabbitMQ
./scripts/tenant.sh all      <db options> <tenant options>   # 1 + 2 (the default when no command is given)
./scripts/tenant.sh --help
```

### Example

```bash
./scripts/tenant.sh all \
  --db-host 103.169.179.22 --db-port 50085 --db-user hims --db-password '...' \
  --org-id 3 --org-name "Care Hospitals" --org-code CARE --tenant care \
  --mq-url http://103.169.179.22:15672 --mq-user guest --mq-password guest
```

Result: database `hims_care`, organization 3 `CARE`, event published to `hims.care.events`.

## Options

### Database connection

| Option | Default | Meaning |
|---|---|---|
| `--db-host` | `localhost` | PostgreSQL server |
| `--db-port` | `5432` | port |
| `--db-user` | `hims` | login (needs `CREATEDB` the first time) |
| `--db-password` | `$PGPASSWORD` | password of that login — **required** |
| `--db-name` | `hims_<tenant>` | the tenant's database |
| `--app-db-password` | — | optional: password for the services' login `hims`; runs `database_v3/roles.sql` (grants on all schemas). Not needed when `--db-user` is already `hims` |

### Tenant (required for `tenant` and `all`)

| Option | Example | Meaning |
|---|---|---|
| `--org-id` | `3` | `organization_id`; must be unique across all tenants |
| `--org-name` | `"Care Hospitals"` | organization name |
| `--org-code` | `CARE` | `org_code`, unique, at most 20 characters |
| `--tenant` | `care` | tenant name — see below. Default: the org code in lower case |
| `--legal-name` | `"Care Hospitals Pvt Ltd"` | optional |

**`--tenant`** is the one name the whole system uses for the tenant, so it must be the same everywhere:

| Used as | For `--tenant care` |
|---|---|
| frontend subdomain | `https://care.localhost:3000` |
| tenant name in each service's `Tenants` config and its connection-string key | `"Name": "care"`, `ConnectionStrings:care` |
| RabbitMQ exchange | `hims.care.events` |
| RabbitMQ queues | `clinical-care.care.events`, `diagnostics.care.events`, … |
| default database name | `hims_care` |

It must be a subdomain label: lower-case letters, digits and `-`.

### RabbitMQ

| Option | Default | Meaning |
|---|---|---|
| `--mq-url` | `http://localhost:15672` | management API (not the AMQP port 5672) |
| `--mq-user` / `--mq-password` | `guest` / `guest` | management login |
| `--mq-vhost` | `/` | virtual host |
| `--services` | `"patient-engagement clinical-care diagnostics revenue-finance"` | services that replicate organizations (the ones with `AddRefReplica<…, RefOrganization>("OrganizationUpdated")`) |
| `--no-publish` | — | only write the outbox row; identity-org's outbox relay publishes it once the tenant is in its config |

## What it does

### `database`

Same steps as `database_v3/deploy.sh`:

1. Creates the database if it doesn't exist (`UTF8`, `template0`).
2. Applies the schema files in this order, skipping any schema that's already loaded:
   `01_identity_org → 05_revenue_finance → 06_operations_supply → 02_patient_engagement → 03_clinical_care → 04_diagnostics → 07_integration_comms`
3. With `--app-db-password`: applies `roles.sql`.

The `database_v3/seed/` files are **not** applied — they belong to Dr Reddis (organization 1) and Apollo (organization 2).
Add the new tenant's reference data (branches, departments, doctors, service catalogue) separately, as `apollo.seed.sql`
does for Apollo.

### `tenant`

1. In **one transaction** in the tenant database:
   - inserts the organization with the given `organization_id` (or updates it if it exists) and moves the id sequence past it;
   - writes an `OrganizationUpdated` row to `identity_org.evt_outbox` — the same event `POST /api/admin/republish` writes.
2. Declares on RabbitMQ, with exactly the arguments the services' `EventConsumer` uses:
   - exchange `hims.<tenant>.events` (topic) and `hims.events.dlx` (direct);
   - for each service in `--services`: queue `<service>.<tenant>.events` (dead-lettered to `<service>.<tenant>.events.dlq`),
     bound to `OrganizationUpdated`.
3. Publishes the event (the same envelope the outbox relay builds, with the outbox `event_id` as the message id) and stamps
   the outbox row `published_at`.

Because the queues exist before the services know about the tenant, the event **waits in the queues** until each service
starts with the new tenant configured.

## After running it

Add the tenant to the configuration of **every** service (identity-org, patient-engagement, clinical-care, diagnostics,
revenue-finance, operations-supply, integration-comms) and restart them:

```json
"ConnectionStrings": {
  "reddys": "...Database=hims_reddys...",
  "apollo": "...Database=hims_apollo...",
  "care":   "Host=...;Port=...;Database=hims_care;Username=hims;Password=..."
},
"Tenants": [
  { "Name": "reddys", "OrganizationId": 1 },
  { "Name": "apollo", "OrganizationId": 2 },
  { "Name": "care",   "OrganizationId": 3 }
]
```

integration-comms (Python) reads its tenants from environment variables in `services/integration-comms/.env` instead,
named after the subdomain in upper case:

```bash
CARE_ORGANIZATION_ID=3
CARE_DATABASE_URL=postgresql://hims:...@host:port/hims_care
CARE_FHIR_URL=http://.../fhir        # the tenant's FHIR server
```

The `Name` must equal `--tenant` and `OrganizationId` must equal `--org-id` — a consumer rejects an event whose
organization doesn't match the tenant of the exchange it came from. Sign-in (WSO2 tenant, `Wso2UserManagement:Tenants`)
and the frontend subdomain are set up as for Apollo.

## Checking it worked

```bash
# the organization and its event
psql -d hims_care -c "select organization_id, org_code, org_name from identity_org.core_organization"
psql -d hims_care -c "select outbox_id, event_type, published_at, last_error from identity_org.evt_outbox order by outbox_id desc limit 5"

# waiting messages (before the services are restarted), or 0 once they've consumed them
curl -s -u guest:guest http://localhost:15672/api/queues/%2F | grep -o '"name":"[^"]*\.care\.events","[^}]*' | head

# after the restart: each service's copy
psql -d hims_care -c "select * from clinical_care.ref_organization"
```

## Re-running

Safe to re-run. Loaded schemas are skipped; an existing organization is updated (`row_ver` + 1) and announced again with
a new event. Services ignore a message they have already processed (`evt_inbox`), and upserting the same
organization row twice changes nothing.

## Troubleshooting

| Message | Cause / fix |
|---|---|
| `give --db-password` | pass `--db-password` or set `PGPASSWORD` |
| `permission denied to create database` | the login lacks `CREATEDB`; create the database as a superuser, or use another `--db-user` |
| `... has no identity_org schema - run ./tenant.sh database first` | `tenant` was run before `database` against this `--db-name` |
| `duplicate key ... org_code` | another organization in this database already has that code |
| `curl: (7) Failed to connect` | wrong `--mq-url`, or the management plugin isn't enabled (`rabbitmq-plugins enable rabbitmq_management`) |
| HTTP `401` | wrong `--mq-user` / `--mq-password` |
| HTTP `400 ... inequivalent arg` | a queue with that name already exists with different arguments — delete it in the management UI, then re-run |
| `publish ... was not routed` | no queue is bound — check `--services`. The outbox row stays unpublished, so identity-org's relay sends it once configured |
| messages go to `<service>.<tenant>.events.dlq` | the service's `Tenants` entry is missing or its `OrganizationId` differs from `--org-id`; check the service log |
