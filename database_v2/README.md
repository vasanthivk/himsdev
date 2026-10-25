# HIMS Database v2: 7 consolidated microservices

Database scripts for the consolidated architecture in `config/microservices_consolidation.xlsx`: 13 microservice databases become 7.
The scripts are **generated** from the per-service scripts in `database/` by `tools/gen_database_v2.py`. Change the generator or the
source scripts and regenerate, rather than editing these files by hand.

## Services and databases

| # | Consolidated service | Database | Script | Replaces (database/) |
|---|---|---|---|---|
| 1 | Identity & Organization | `new_hims_identity_org` | `01_identity_org.sql` | 10_identity_org |
| 2 | Patient Access & Engagement | `new_hims_patient_engagement` | `02_patient_engagement.sql` | 01_patient_access, 07_digital_engagement |
| 3 | Clinical Care | `new_hims_clinical_care` | `03_clinical_care.sql` | 02_clinical_care |
| 4 | Diagnostics (Lab + Imaging) | `new_hims_diagnostics` | `04_diagnostics.sql` | 03_laboratory (+ extensions/03_laboratory.ext.sql), 04_imaging |
| 5 | Revenue & Finance | `new_hims_revenue_finance` | `05_revenue_finance.sql` | 06_revenue_cycle, 13_back_office |
| 6 | Operations & Supply Chain | `new_hims_operations_supply` | `06_operations_supply.sql` | 05_pharmacy_supply, 09_hospital_ops, 08_field_ops |
| 7 | Integration & Communications | `new_hims_integration_comms` | `07_integration_comms.sql` | 11_integration, 12_comms_docs |

Seed data: `seed/01_identity_org.seed.sql`, `seed/04_diagnostics.seed.sql`, `seed/05_revenue_finance.seed.sql`, copied from
`database/seed/`.

## What changed, and what did not

**Unchanged, so existing code keeps working.** Every owned table keeps its schema, table and column names, types, defaults, constraints
and indexes. A consolidated database is the union of its parts, and every query the current services run still finds its tables.

**Duplication removed:**

| | database/ (13 databases) | database_v2/ (7 databases) |
|---|---|---|
| Tables | 488 | 428 |
| `ref.*` replica tables | 148 | 111 (+ 8 read-only views) |
| Outbox / inbox / saga / number-sequence tables | 49 | 26 |
| Patient table copies (`pat.patient` + `ref.patient`) | 11 | 7 |
| `ref.employee` copies | 10 | 5 |
| `ref.branch` copies | 11 | 6 |

1. **Infrastructure once per database.** `core.number_sequence`, `evt.outbox`, `evt.inbox`, `evt.saga_instance` and the `util` trigger
   functions are created once, not once per part.
2. **One copy of each shared replica.** A `ref.*` table that several parts had (for example `ref.patient` in Laboratory and Imaging) is
   created once. `ref.order_item` differed (Laboratory has `bill_no`, `bill_status` and `is_paid`), so the merged table has the union of
   the columns.
3. **Replicas of own data become views.** A part that kept an event-filled copy of a table now owned by the same service reads the
   owner table instead, through a **read-only view with the same name and columns**:

   | Database | View | Over the owner table |
   |---|---|---|
   | new_hims_patient_engagement | `ref.patient`, `ref.encounter`, `ref.appointment`, `ref.slot` | `pat.patient`, `pat.encounter`, `sch.appointment`, `sch.slot` |
   | new_hims_revenue_finance | `ref.receipt` | `bil.receipt` |
   | new_hims_operations_supply | `ref.item`, `ref.vendor`, `ref.grn` | `mst.item`, `mst.vendor`, `inv.grn` |

   `source_version` is the owner row's `row_ver`, and `replicated_at` is its `updated_at` (or `created_at`). Writing to a view raises an error
   (`util.reject_write`).
4. **Same-service references are real foreign keys (20).** The data model removed foreign keys between services ("logical FK") and keeps
   them inside a service. Columns that pointed to a table now owned by the same service get their foreign key back. For example,
   `tele.session.patient_id` references `pat.patient`, and `adm.asset.vendor_id` references `mst.vendor`. All 20 are on tables of parts
   that are scaffolds today (Digital Engagement, Back Office, Hospital Operations), pointing to the implemented parts.
5. **The row_ver trigger block** attaches `trg_row_ver` to base tables only, so it skips the views.

Patient data is now kept once per consolidated service that needs it. `pat.patient` (Patient Access & Engagement) is the master, and
each of the other services keeps one replica, `ref.patient`, as the database-per-service rule requires.

## Deploy

```bash
cd database_v2
PGHOST=localhost PGUSER=postgres PGPASSWORD=... ./deploy.sh              # creates the new_hims_* databases above
DB_PREFIX=v2test_ PGHOST=localhost PGUSER=postgres PGPASSWORD=... ./deploy.sh   # same, under other names
```

The order is identity first, then revenue & finance and operations & supply, then the rest. Re-running skips databases that are already
loaded.

## Verify

`tools/v2_verify.py` compares the 13 original databases with the 7 consolidated ones (tables, columns, types, defaults, constraints,
indexes and triggers). It reports anything missing or changed beyond the documented differences:

```bash
cd database && PGUSER=postgres ./deploy.sh                      # the original 13 (hims_patient_access, ...)
cd ../database_v2 && DB_PREFIX=v2test_ PGUSER=postgres ./deploy.sh
python tools/v2_verify.py "host=localhost user=postgres password=..." hims_ v2test_
```

Last run: **0 problems**. It also confirmed that the views return the owner rows, that writes to them are rejected, and that the new
foreign keys accept existing ids and reject unknown ones.

## When the services are merged (application side)

The databases keep every table the code uses, but the services must be pointed at them and merged:

- **Connection strings.** Point the merged parts at the new database: `ConnectionStrings:Default` in each service's `appsettings.json`
  and the `config/` copies. For the Integration Hub, change `DATABASE_URL` in `services/integration/.env` (the database is now
  `new_hims_integration_comms`). Every service gets a new database name, including Identity & Organization
  (`new_hims_identity_org`) and Clinical Care (`new_hims_clinical_care`), so the old and new databases can exist side by side on one server.
- **One consumer per database.** `evt.inbox` is keyed by the message id, so the parts of a consolidated service must consume events as one
  process and one queue. If they ran as separate processes against one database, the second process would skip messages the first one
  already recorded.
- **Drop self-subscriptions.** A part must no longer fill a replica that is now a view. For example, Digital Engagement should not upsert
  `ref.patient` from `PatientRegistered`, because the view already shows `pat.patient`. Writes to the views fail by design.
- **Events between merged parts** (for example Laboratory and Imaging both consuming `OrderPlaced`) still work through the shared outbox
  and inbox. Inside one service they can later be replaced by direct calls.
- **Data migration.** For existing data, copy each old database's owned tables into the new database (same table names), plus the
  `evt.*` and `core.number_sequence` rows. Skip the replicas that became views.
