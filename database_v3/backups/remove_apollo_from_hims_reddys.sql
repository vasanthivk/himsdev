-- Removes every row of organization 2 (Apollo Hospitals) from hims_reddys.
-- Encounter OP26000005 (Reddy's) was saved with Apollo's GENMED department (4); it is moved to Reddy's GENMED (1) first.
-- Usage: psql -d hims_reddys -v ON_ERROR_STOP=1 -v final=COMMIT -f remove_apollo_from_hims_reddys.sql   (final=ROLLBACK = dry run)
\set ON_ERROR_STOP 1
BEGIN;

CREATE TEMP TABLE apollo_event AS SELECT event_id::text AS id FROM identity_org.evt_outbox WHERE organization_id = 2;

-- Reddy's encounters that point at an Apollo department -> the Reddy's department with the same code.
CREATE TEMP TABLE dept_map AS
  SELECT a.department_id AS apollo_id, r.department_id AS reddys_id
  FROM identity_org.mst_department a JOIN identity_org.mst_department r ON r.dept_code = a.dept_code AND r.organization_id = 1
  WHERE a.organization_id = 2;
UPDATE patient_engagement.pat_encounter e SET department_id = m.reddys_id FROM dept_map m WHERE e.department_id = m.apollo_id AND e.organization_id = 1;
UPDATE patient_engagement.ref_encounter e SET department_id = m.reddys_id FROM dept_map m WHERE e.department_id = m.apollo_id AND e.organization_id = 1;
UPDATE clinical_care.ref_encounter      e SET department_id = m.reddys_id FROM dept_map m WHERE e.department_id = m.apollo_id AND e.organization_id = 1;
UPDATE diagnostics.ref_encounter        e SET department_id = m.reddys_id FROM dept_map m WHERE e.department_id = m.apollo_id AND e.organization_id = 1;
UPDATE revenue_finance.ref_encounter    e SET department_id = m.reddys_id FROM dept_map m WHERE e.department_id = m.apollo_id AND e.organization_id = 1;
UPDATE integration_comms.ref_encounter  e SET department_id = m.reddys_id FROM dept_map m WHERE e.department_id = m.apollo_id AND e.organization_id = 1;

-- identity_org
DELETE FROM identity_org.mst_department    WHERE organization_id = 2;
DELETE FROM identity_org.evt_outbox        WHERE organization_id = 2;
DELETE FROM identity_org.core_branch       WHERE organization_id = 2;
DELETE FROM identity_org.core_organization WHERE organization_id = 2;

-- read-model copies and the inbox records of Apollo's events in the other services
DELETE FROM patient_engagement.ref_department   WHERE organization_id = 2;
DELETE FROM patient_engagement.ref_branch       WHERE organization_id = 2;
DELETE FROM patient_engagement.ref_organization WHERE organization_id = 2;
DELETE FROM patient_engagement.evt_inbox        WHERE message_id::text IN (SELECT id FROM apollo_event);
DELETE FROM clinical_care.ref_branch            WHERE organization_id = 2;
DELETE FROM clinical_care.ref_organization      WHERE organization_id = 2;
DELETE FROM clinical_care.evt_inbox             WHERE message_id::text IN (SELECT id FROM apollo_event);
DELETE FROM diagnostics.ref_branch              WHERE organization_id = 2;
DELETE FROM diagnostics.ref_organization        WHERE organization_id = 2;
DELETE FROM diagnostics.evt_inbox               WHERE message_id::text IN (SELECT id FROM apollo_event);
DELETE FROM revenue_finance.ref_branch          WHERE organization_id = 2;
DELETE FROM revenue_finance.ref_organization    WHERE organization_id = 2;
DELETE FROM revenue_finance.evt_inbox           WHERE message_id::text IN (SELECT id FROM apollo_event);
DELETE FROM integration_comms.evt_inbox         WHERE message_id::text IN (SELECT id FROM apollo_event);

:final;
