# Patient registration flow logs

Every step of a patient registration (and encounter start/close, patient update) is logged with the prefix `[FLOW]` and
two ids that follow the request across all services:

| Key | What it is | Where it comes from |
|---|---|---|
| `corr=` | correlation id of the HTTP request | `X-Correlation-Id` request header (or a new GUID); returned in the response header; stored in `evt.outbox.correlation_id`; carried in the RabbitMQ envelope (`correlationId`) |
| `event=` | id of one event | `evt.outbox.event_id` = envelope `id` = `evt.inbox.message_id` in every consumer |

## The path of one registration

```
patient-engagement   REG-01  POST /api/patients received (mobile masked to last 4 digits)
                     REG-02  branch resolved from ref.branch -> organization
                     REG-03  duplicate check passed (or REG-STOP -> 409 / 400)
                     REG-04  UHID allocated, pat.patient inserted
                     REG-05  PatientRegistered queued in evt.outbox
                     REG-06  committed, 201 returned to the screen
                     PUB-01  OutboxRelay picks the row (published_at IS NULL)
                     PUB-02  sent to exchange hims.events, routing key PatientRegistered
                     PUB-03  RabbitMQ confirmed, published_at stamped      (PUB-FAIL = will retry)

clinical-care,       SUB-01  received from queue <service>.events
diagnostics,         SUB-02  recorded in evt.inbox (SUB-DUP = redelivery ignored)
revenue-finance      SUB-03  running handler RefUpsertHandler<RefPatient>
                     REF-UPSERT  ref.patient row INSERTED / UPDATED (REF-SKIP = stale event)
                     SUB-04  PROCESSED and committed           (SUB-RETRY / SUB-DLQ on failure)

integration-comms    SUB-01 / SUB-02  received, recorded in evt.inbox
(Python)             REF-UPSERT       ref.patient
                     FHIR-01 / FHIR-02  PUT Patient to the FHIR server, intg.fhir_resource_map updated (FHIR-FAIL = retry)
                     SUB-04           PROCESSED and committed
```

Encounters use `ENC-01..03` (start) and `CLS-01..02` (close); `CC-01` is an encounter closed by Clinical Care's
`ConsultationCompleted`, which keeps the incoming event's `corr`. Patient update uses `UPD-01..02`.

## Following one patient

1. Find the correlation id: the browser's network tab shows it in the `X-Correlation-Id` response header, or search the
   registration log line: `grep "REG-04" logs/patient-engagement/27-10-2026.log`
2. Pull every line for it from all services, in time order:

```bash
# Git Bash
grep -h "corr=<guid>" logs/*/27-10-2026.log | sort
```
```powershell
# PowerShell
Get-ChildItem logs\*\27-10-2026.log | Select-String "corr=<guid>" | ForEach-Object { $_.Line } | Sort-Object
```

`grep -h "\[FLOW\]" logs/*/27-10-2026.log | sort` shows the flow of every request of the day.

Only events published after this change carry a correlation id; older ones log `corr=none` but still have `event=`.
