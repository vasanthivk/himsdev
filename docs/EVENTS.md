# Event catalogue (RabbitMQ only)

Topic exchange **`hims.events`** (durable). Routing key = event type. Every service writes events to its own `evt.outbox` in the same
transaction as the business change; a relay publishes them. Consumers have a queue `<service>.events` (dead-letter queue
`<service>.events.dlq` via exchange `hims.events.dlx`), record every message in `evt.inbox` (idempotent) and retry 5 times.

Device messages travel separately: the Open Integration Engine publishes raw messages to topic exchange **`hims.integration`**,
routing key `lab.results.<analyzer>`; the Integration Hub reads queue `lab.results`.

Envelope (JSON): `specVersion, id, type, source, subject, time, data, organizationId, branchId, patientId, correlationId, aggregateType, aggregateId, eventVersion, sourceVersion`.
`data` is camelCase. `sourceVersion` = the publisher's `evt.outbox.outbox_id`; `ref.*` upserts ignore an event older than the stored `source_version`.

| Event | Published by | Consumed by (this project) | `data` |
|---|---|---|---|
| OrganizationUpdated* | identity-org | patient-access, clinical-care, laboratory, revenue-cycle | row of `core.organization` |
| BranchUpdated | identity-org | same four | row of `core.branch` |
| DepartmentUpdated | identity-org | patient-access | row of `mst.department` |
| PractitionerUpdated | identity-org | patient-access, clinical-care, laboratory | row of `hr.practitioner` |
| ServiceUpdated | revenue-cycle | clinical-care, laboratory | row of `mst.service` |
| PatientRegistered / PatientUpdated | patient-access | clinical-care, laboratory, revenue-cycle (`ref.patient`); integration (`ref.patient` + FHIR Patient) | row of `pat.patient` |
| EncounterStarted / EncounterClosed | patient-access | clinical-care, laboratory, revenue-cycle (`ref.encounter`); integration (`ref.encounter` + FHIR Encounter) | row of `pat.encounter` |
| OrderPlaced | clinical-care | laboratory (`ref.clinical_order`, `ref.order_item`, LAB only); revenue-cycle (raises the bill); integration* (FHIR ServiceRequest) | `OrderPlacedPayload`: order columns + `items[]` |
| ChargePosted | revenue-cycle | clinical-care* (sets `is_billed`) | `BillPayload` with `lines[]` (`orderItemId`) |
| BillFinalised | revenue-cycle | - | `BillPayload` |
| PaymentReceived | revenue-cycle | - | `PaymentReceivedPayload` |
| SampleCollected | laboratory | - | `SampleCollectedPayload` |
| AnalyzerResultReceived | integration | laboratory | `AnalyzerResultReceivedPayload`: `sampleBarcode, analyzerCode, sourceMessageId, messageType, resultedAt, messageLogId, analytes[]` |
| ResultVerified | laboratory | clinical-care | `ResultVerifiedPayload`: sample/order ids + `results[]` |
| CriticalValueDetected | laboratory | - | same shape, critical results only |
| LabReportReleased | laboratory | integration (FHIR Observation + DiagnosticReport) | `LabReportReleasedPayload` with `results[]` |
| PrescriptionIssued | clinical-care | integration (FHIR MedicationRequest) | `PrescriptionIssuedPayload` with `items[]` |
| ClinicalNoteSigned, DiagnosisRecorded | clinical-care | - | note / diagnosis row |

`*` = beyond the data-model README's Publishes/Subscribes lists (OrganizationUpdated is not listed for identity-org; integration's OrderPlaced and
EncounterStarted subscriptions and clinical-care's ChargePosted subscription are additions). No schema change was needed for any of them.
Payload record definitions: `shared/Hims.Common/Events/Contracts.cs`.
