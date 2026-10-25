# HIMS Database v3: one database (`himsdev`), one schema per service

The 7 consolidated services of `database_v2/` in a single PostgreSQL database, `himsdev`. Each service has one schema, and each
table carries its former schema as a name prefix. The scripts are **generated** from `database_v2/` (which is only read) by
`tools/gen_database_v3.py`, so regenerate them rather than editing by hand.

## Naming convention

```
database_v2:  new_hims_<service>.<schema>.<table>
database_v3:  himsdev.<service>.<schema>_<table>

new_hims_identity_org.core.organization   ->  himsdev.identity_org.core_organization
new_hims_diagnostics.lab.sample           ->  himsdev.diagnostics.lab_sample
new_hims_diagnostics.evt.outbox           ->  himsdev.diagnostics.evt_outbox
new_hims_patient_engagement.ref.patient   ->  himsdev.patient_engagement.ref_patient      (view)
util.touch_audit()  (in each database)    ->  himsdev.<service>.util_touch_audit()
```

| # | Service | Schema in himsdev | Script | Former schemas (now table prefixes) |
|---|---|---|---|---|
| 1 | Identity & Organization | `identity_org` | `01_identity_org.sql` | core, hr, mst, sec, ref, evt, util |
| 2 | Patient Access & Engagement | `patient_engagement` | `02_patient_engagement.sql` | adt, core, mst, pat, sch, camp, crm, ecom, tele, ref, evt, util |
| 3 | Clinical Care | `clinical_care` | `03_clinical_care.sql` | bb, core, diet, emr, er, icu, mst, nur, ord, ot, ref, evt, util |
| 4 | Diagnostics (Lab + Imaging) | `diagnostics` | `04_diagnostics.sql` | bb, core, lab, mst, pacs, rad, ref, evt, util |
| 5 | Revenue & Finance | `revenue_finance` | `05_revenue_finance.sql` | bil, core, ins, mst, adm, edu, fin, hr, it, ref, evt, util |
| 6 | Operations & Supply Chain | `operations_supply` | `06_operations_supply.sql` | core, cssd, inv, mst, pha, adm, diet, fld, ref, evt, util |
| 7 | Integration & Communications | `integration_comms` | `07_integration_comms.sql` | intg, core, mst, ref, evt, util |

Seed data: `seed/01_identity_org.seed.sql`, `seed/04_diagnostics.seed.sql` and `seed/05_revenue_finance.seed.sql` (the v2 seeds with
the names converted).

## What changed from database_v2

- **Names only.** Tables, views and functions are renamed as above. References to them are converted too: foreign keys, view bodies,
  triggers and the seed statements.
- **Comments follow the convention.** The "logical FK" notes name the owner's new table, e.g.
  `logical FK -> identity_org.core_organization [Identity, Organization & Reference Data]`.
- **Everything else is identical:** columns, types, defaults, identity columns, constraints, indexes, the 8 read-only `ref_*` views and the
  20 same-service foreign keys.
- **Services stay separate inside the shared database.**
  - Each service has its own outbox and inbox (`<service>.evt_outbox`, `<service>.evt_inbox`) and its own copies of other services' data
    (`<service>.ref_*`).
  - References to another service's tables stay logical, with no foreign key across schemas, so each schema can later move to its own
    database again.
  - The row-version trigger block of each script attaches triggers only to its own schema.

## Deploy

```bash
cd database_v3
PGHOST=localhost PGUSER=postgres PGPASSWORD=... ./deploy.sh                  # into himsdev (created if missing)
DB_NAME=himsdev_test PGHOST=localhost PGUSER=postgres PGPASSWORD=... ./deploy.sh   # into another database
```

The order is identity first, then revenue & finance and operations & supply, then the rest. Re-running skips services whose schema
is already loaded.

## Verify

`tools/v3_verify.py` maps every object of the 7 `database_v2` databases to its `himsdev` name. It then compares columns (type,
nullability, default, identity and generated), constraints, indexes, triggers, view definitions and seed rows:

```bash
cd database_v2 && DB_PREFIX=v2test_ PGUSER=postgres ./deploy.sh
cd ../database_v3 && DB_NAME=himsdev_v3test PGUSER=postgres ./deploy.sh
python tools/v3_verify.py "host=localhost user=postgres password=..." v2test_ himsdev_v3test
```

Last run: **0 problems**. It checked 428 tables, 8 views, 6,388 columns, 3,789 constraints, 532 indexes, 292 triggers and 46 seed rows.

It also confirmed that the seed data loads, that `ref_patient` shows `pat_patient` rows (with `source_version` following the row-version
trigger), that writes to the view are rejected, that the new foreign keys reject unknown ids, and that each service's outbox is separate.

## How the services use himsdev

The services in `services/` are configured for `himsdev`:

| What | Where | How |
|---|---|---|
| Connection | `ConnectionStrings:Default` in each .NET service's `appsettings.json` (and `config/`); `DATABASE_URL` in `services/integration-comms/.env` (and `config/`) | `Host=localhost;Port=5432;Database=himsdev;Username=hims` |
| Service schema | `"Database": { "Schema": "<schema>" }` in `appsettings.json`; `DB_SCHEMA` in the Integration Hub's `.env` | identity-org: `identity_org`; patient-engagement: `patient_engagement`; clinical-care: `clinical_care`; diagnostics: `diagnostics`; revenue-finance: `revenue_finance`; operations-supply: `operations_supply`; integration-comms: `integration_comms` |
| EF entities (480) | `shared/Hims.Common/Data/HimsDbNames.cs`: `HimsModelCustomizer` | Maps the generated `[Table("organization", Schema = "core")]` to `identity_org.core_organization` at runtime. `Entities.g.cs` is unchanged. |
| Outbox, inbox, sequences | `OutboxRelay.cs`, `EventConsumer.cs`, `SequenceService.cs` in `shared/Hims.Common` | Table names from `HimsDbNames` (`<schema>.evt_outbox`, `<schema>.evt_inbox`, `<schema>.core_number_sequence`) |
| Raw SQL in Identity & Org | `UsersController.cs` (employee code) | Table name from the EF mapping |
| Integration Hub | `app/db.py` `table()`, used by `bus.py`, `fhir_sync.py`, `inbound.py` and `main.py` | `integration_comms.intg_*`, `evt_*` and `ref_*` |
| Login | `roles.sql` (run by `deploy.sh` when `HIMS_DB_PASSWORD` is set) | User `hims`: read/write on the 7 schemas |

Leaving `Database:Schema` (or `DB_SCHEMA`) empty switches a service back to a database of its own with the original schema names
(`database/` or `database_v2/`), so the same code runs on either layout.

Event payloads, `aggregate_type` values (e.g. `"hr.employee"`) and FHIR entity types (`"pat.patient"`) are data, not table names, and are
unchanged.

**One service per schema.** The services in `services/` are the 7 consolidated microservices, so each schema's outbox, inbox and
number sequences belong to exactly one process.
