-- 29-10-2026 17:06: Apollo's simulator result for sample SMP26000001 was filed against Reddy's sample SMP26000001 (patient 1),
-- because device messages carried no tenant and both hospitals number samples alike. Reverts exactly what that message did in
-- hims_reddys. Usage: psql -d hims_reddys -v ON_ERROR_STOP=1 -v final=COMMIT -f this.sql   (final=ROLLBACK = dry run)
\set ON_ERROR_STOP 1
BEGIN;

-- diagnostics: the new results and report, and the original results it marked AMENDED
DELETE FROM diagnostics.lab_result WHERE result_id IN (19, 20, 21, 22, 23) AND sample_id = 1 AND created_at >= '2026-10-29 17:06:00+05:30';
UPDATE diagnostics.lab_result SET result_status = 'RELEASED' WHERE result_id IN (1, 2, 3, 4, 5) AND result_status = 'AMENDED';
DELETE FROM diagnostics.lab_report WHERE lab_report_id = 7 AND patient_id = 1 AND version_no = 2;
DELETE FROM diagnostics.evt_outbox WHERE event_id IN ('e5645b2f-576d-475f-a7fa-8bebfb279b18', '5da87adf-8262-42fe-a6f4-32b4ae262805');
DELETE FROM diagnostics.evt_inbox WHERE message_id = 'ea4090f6-4f6a-5fdc-b254-060965b9e7db';

-- clinical_care: the ResultVerified copies of the results
DELETE FROM clinical_care.ref_lab_result_summary WHERE result_id IN (19, 20, 21, 22, 23) AND patient_id = 1;
DELETE FROM clinical_care.evt_inbox WHERE message_id = 'e5645b2f-576d-475f-a7fa-8bebfb279b18';

-- integration_comms: the device message, its event and the failed FHIR attempts
DELETE FROM integration_comms.evt_outbox WHERE event_id = 'ea4090f6-4f6a-5fdc-b254-060965b9e7db';
DELETE FROM integration_comms.intg_message_log WHERE message_log_id BETWEEN 74 AND 80 AND logged_at >= '2026-10-29 17:06:00+05:30';

SELECT 'results on SMP26000001: ' || count(*) || ' (' || string_agg(DISTINCT result_status, ',') || ')' FROM diagnostics.lab_result WHERE sample_id = 1;
:final;
