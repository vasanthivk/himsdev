# Database changes

## The original scripts
`database/01_patient_access.sql` ... `13_back_office.sql` are the scripts you supplied, **byte-for-byte unchanged**. Nothing was removed:
all 480 tables of the 12 .NET-backed services (plus the 8 tables of the Python Integration Hub) are created exactly as supplied,
including every `ref.*` read-model table and the `evt.outbox / evt.inbox / evt.saga_instance` tables.

## Columns added (the complete list)

Only one table needed extra columns. They are added by a **separate** script, `database/extensions/03_laboratory.ext.sql`
(`ALTER TABLE ... ADD COLUMN IF NOT EXISTS`, all nullable, safe to re-run), applied after `03_laboratory.sql` by `database/deploy.sh`.

| Database | Table | Column added | Type | Null | Purpose |
|---|---|---|---|---|---|
| `hims_laboratory` | `lab.analyzer` | `sending_application_id` | `VARCHAR(50)` | yes | What the device puts in HL7 `MSH-3` (or FHIR `Device` id). The hub's message carries it; Laboratory uses it to find the analyzer. |
| `hims_laboratory` | `lab.analyzer` | `integration_channel_id` | `VARCHAR(100)` | yes | Channel id returned by the Open Integration Engine when the device was provisioned. |
| `hims_laboratory` | `lab.analyzer` | `routing_key` | `VARCHAR(150)` | yes | RabbitMQ routing key (`lab.results.<code>`) the engine publishes this device's results under. |
| `hims_laboratory` | `lab.analyzer` | `channel_status` | `VARCHAR(20)` | yes | `PROVISIONED`, `PENDING` (engine not configured / hub down), `FAILED`, or `NOT_CREATED` (device added without asking for a channel). |
| `hims_laboratory` | `lab.analyzer` | `engine_url` | `VARCHAR(200)` | yes | Open Integration Engine REST API base for this device, entered on "Add a device". `NULL` here (and in the columns below) = the hub's own setting. |
| `hims_laboratory` | `lab.analyzer` | `engine_user` | `VARCHAR(100)` | yes | Engine login. |
| `hims_laboratory` | `lab.analyzer` | `engine_password` | `VARCHAR(200)` | yes | Engine password, kept for re-provisioning. Stored as entered; never returned by the Laboratory API. |
| `hims_laboratory` | `lab.analyzer` | `engine_verify_tls` | `BOOLEAN` | yes | Whether the engine's TLS certificate is verified. |
| `hims_laboratory` | `lab.analyzer` | `engine_first_listen_port` | `INT` | yes | Port the device's channel listens on inside the engine, used as entered. Empty = the hub picks one (`ENGINE_FIRST_LISTEN_PORT` + analyzer id). |
| `hims_laboratory` | `lab.analyzer` | `engine_channel_url` | `VARCHAR(200)` | yes | The deployed channel's own HTTP endpoint; device messages sent "via Open Integration Engine" go here. |

The generated C# entity `Analyzer` (services/laboratory/Data/Entities.g.cs) carries these ten properties, each marked
"Extension column" in its doc comment.

Check on a live database:

```sql
SELECT column_name, data_type, is_nullable FROM information_schema.columns
 WHERE table_schema = 'lab' AND table_name = 'analyzer'
   AND column_name IN ('sending_application_id','integration_channel_id','routing_key','channel_status',
                       'engine_url','engine_user','engine_password','engine_verify_tls',
                       'engine_first_listen_port','engine_channel_url');
```

## Why nothing else needed a column
* Idempotency of device messages: `intg.message_log.correlation_id` in the hub + a deterministic event id + `evt.inbox` in Laboratory.
* Billed flag: `ord.order_item.is_billed` already exists (set by a `ChargePosted` handler in Clinical Care).
* Protocols HL7V3 / FHIR: `lab.analyzer.interface_protocol` is an unconstrained `VARCHAR(20)` (the README lists ASTM, HL7V2, LIS2-A2, FILE only as a comment).
* Read models, outbox, inbox: already in every script.

## Seed data (rows, not schema)
`database/seed/` inserts the minimum reference rows so the workflow runs: organization DRR + branch HYD01, three departments, one specialty,
two employees/practitioners (`10_identity_org`); five service categories/services and a GEN-OPD tariff with rates (`06_revenue_cycle`);
four lab tests and 11 LOINC-coded parameters (`03_laboratory`). All inserts are `ON CONFLICT`/`NOT EXISTS`-guarded.

## Not deployed by default
Databases for services with no workflow code yet (imaging, pharmacy-supply, ...) are still created by `deploy.sh` from your unchanged scripts.
