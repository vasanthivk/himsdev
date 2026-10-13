# HIMS - Dr Reddis HealthCare (reference implementation)

Microservices named exactly as in your data model (`database/DATA_MODEL_README.md`), one PostgreSQL database each, events over
**RabbitMQ only**. .NET 8 backends, one Python backend (Integration Hub), Next.js multi-zone frontends.

## The workflow
1. **Add a device** - Laboratory > Analyzers. Laboratory saves `lab.analyzer`; when asked to, the Python Integration Hub creates the device's channel in the Open Integration Engine from the template for its protocol (`docs/ENGINE_TEMPLATE.md`).
2. **Register the patient** - Patient Access. UHID from `core.number_sequence`; `PatientRegistered` published.
3. **OP visit + registration/consultation bill** - Patient Access (encounter), Billing (bill, payment).
4. **Doctor consultation** - Clinical Care: complaint, SOAP note, diagnoses, prescription (`PrescriptionIssued`), lab order (`OrderPlaced`).
5. **Bill the lab test** - Revenue Cycle raises the bill from `OrderPlaced`; the counter takes payment.
6. **Lab test** - Laboratory: worklist (paid status shown), barcoded sample; the device sends HL7 v2 / v3 / FHIR -> engine -> RabbitMQ -> Integration Hub -> `AnalyzerResultReceived` -> Laboratory stores `lab.result`, verifies, releases the report.
7. **Result flows back** - `ResultVerified` updates the doctor's order; `LabReportReleased` makes the hub write FHIR Observation + DiagnosticReport to HAPI (`intg.fhir_resource_map` tracks each link).

## Layout
| Path | What |
|---|---|
| `database/` | your 13 scripts (unchanged), `extensions/` (6 columns on `lab.analyzer`), `seed/`, `deploy.sh`; see `docs/DATABASE_CHANGES.md` |
| `services/<name>/` | 12 .NET services + `integration/` (Python). Names: patient-access, clinical-care, laboratory, imaging, pharmacy-supply, revenue-cycle, digital-engagement, field-ops, hospital-ops, identity-org, comms-docs, back-office |
| `shared/Hims.Common/` | outbox relay, idempotent inbox consumer, `ref.*` replication, number sequences, Swagger, health |
| `frontend/` | shell (3000) + patient-access (3001), clinical-care (3002), laboratory (3003), revenue-cycle (3006) |
| `tools/` | `gen_entities.py` (SQL -> C# entities for every table), `gen_scaffold.py` |
| `docs/` | `DATABASE_CHANGES.md`, `EVENTS.md`, `ENGINE_TEMPLATE.md` |

**Workflow code (backend + frontend):** Patient Access, Clinical Care, Revenue Cycle, Laboratory (+ Identity/Org reference data, Integration Hub).
**Data model + API host only** (every table mapped, Swagger, health, event plumbing; no business endpoints yet): imaging, pharmacy-supply,
digital-engagement, field-ops, hospital-ops, comms-docs, back-office.

## Run it
```bash
# 1. databases (original scripts + extension + seed)
cd database && PGHOST=localhost PGUSER=hims PGPassword=xv7o4aPKUqR6oEf5 ./deploy.sh && cd ..
# 2. RabbitMQ, HAPI-FHIR, Open Integration Engine: yours (edit appsettings.json "RabbitMq", hub env vars)
# 3. backends
./scripts/run-dotnet-services.sh                       # Swagger at http://localhost:<port>/swagger
cd services/integration && pip install -r requirements.txt && uvicorn app.main:app --port 5011   # http://localhost:5011/docs
# 4. frontends (one terminal each)   cd frontend/<zone> && npm install && npm run dev
# 5. open http://localhost:3000  ->  "Load reference data"  ->  follow the workflow
```
Or `docker compose up --build` (see the comments at the top of `docker-compose.yml` for using your own RabbitMQ/HAPI/engine).

Without a physical analyzer, Laboratory > "Send device result" plays the device (hub simulator, HL7 v2/v3/FHIR, optional abnormal/critical values).

## Behaviours worth knowing
* **Eventual consistency.** A service answers 409 while a needed `ref.*` row has not arrived yet; the frontends retry for ~9 s.
* **Duplicates are harmless.** `evt.inbox` (.NET and hub) plus a deterministic id for device messages.
* **Failures.** Handlers retry 5 times, then the message goes to `<service>.events.dlq` (RabbitMQ management UI, port 15672).
* **Payment gate.** The lab UI disables "Collect sample" until the bill is paid (tick "collect even if unpaid" to override). The backend does not enforce it.
* **Auto-verification.** `Laboratory:AutoVerify` (default true) verifies device results immediately; set false for manual `POST /api/samples/{id}/verify`.

## Verification status (honest)
Done in the sandbox: all 13 scripts run on PostgreSQL 16; `deploy.sh` idempotent; generated entities match the live catalog (480 tables, 0 mismatches);
the C# compiled against hand-written stubs of the EF Core/Npgsql/RabbitMQ/Swashbuckle APIs (NuGet was blocked); the SQL used by the sequence, outbox
and inbox code ran against real PostgreSQL; the Python HL7 v2/v3/FHIR parsers have 11 passing tests.
**Not run:** the .NET services against the real packages, RabbitMQ end to end, HAPI, the Open Integration Engine, `npm install/build` of the frontends,
and the Python FHIR mappers/consumers/engine client (syntax-checked only). Expect a few small fixes on first run.
