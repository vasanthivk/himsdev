-- Removes every row of organization 1 (Dr Reddis HealthCare) from hims_apollo, a copy of hims_reddys.
-- Keeps Apollo (organization 2): organization, branch, departments, their ref copies, Apollo's identity events and their inbox rows,
-- and the organization-free service categories.
-- Usage: psql -d hims_apollo -v ON_ERROR_STOP=1 -v final=COMMIT -f remove_reddys_from_hims_apollo.sql   (final=ROLLBACK = dry run)
\set ON_ERROR_STOP 1
BEGIN;

-- Ids of Reddy's rows, taken before anything is deleted (several tables reach organization 1 only through these).
CREATE TEMP TABLE x_patient   AS SELECT patient_id   FROM patient_engagement.pat_patient    WHERE organization_id = 1;
CREATE TEMP TABLE x_encounter AS SELECT encounter_id FROM patient_engagement.pat_encounter  WHERE organization_id = 1;
CREATE TEMP TABLE x_user      AS SELECT user_id      FROM identity_org.sec_user_account     WHERE organization_id = 1;
CREATE TEMP TABLE x_role      AS SELECT role_id      FROM identity_org.sec_role             WHERE organization_id = 1;
CREATE TEMP TABLE x_dept      AS SELECT department_id FROM identity_org.mst_department      WHERE organization_id = 1;
CREATE TEMP TABLE x_pract     AS SELECT practitioner_id FROM identity_org.hr_practitioner   WHERE organization_id = 1;
CREATE TEMP TABLE x_service   AS SELECT service_id   FROM revenue_finance.mst_service       WHERE organization_id = 1;
CREATE TEMP TABLE x_lab_test  AS SELECT lab_test_id  FROM diagnostics.mst_lab_test          WHERE service_id IN (SELECT service_id FROM x_service);
-- Events to keep in the inboxes: those Apollo's own identity events.
CREATE TEMP TABLE keep_event  AS SELECT event_id::text AS id FROM identity_org.evt_outbox   WHERE organization_id = 2;

-- identity_org
DELETE FROM identity_org.sec_user_session WHERE user_id IN (SELECT user_id FROM x_user) OR branch_id = 1;
DELETE FROM identity_org.sec_user_role    WHERE user_id IN (SELECT user_id FROM x_user) OR role_id IN (SELECT role_id FROM x_role)
                                             OR branch_id = 1 OR department_id IN (SELECT department_id FROM x_dept);
DELETE FROM identity_org.sec_user_account WHERE organization_id = 1;
DELETE FROM identity_org.sec_role         WHERE organization_id = 1;
DELETE FROM identity_org.hr_practitioner  WHERE organization_id = 1;
DELETE FROM identity_org.hr_employee      WHERE organization_id = 1;
DELETE FROM identity_org.mst_specialty    WHERE department_id IN (SELECT department_id FROM x_dept);
DELETE FROM identity_org.mst_department   WHERE organization_id = 1;
DELETE FROM identity_org.evt_outbox       WHERE organization_id = 1;
DELETE FROM identity_org.core_branch      WHERE organization_id = 1;
DELETE FROM identity_org.core_organization WHERE organization_id = 1;

-- patient_engagement
DELETE FROM patient_engagement.pat_encounter        WHERE organization_id = 1;
DELETE FROM patient_engagement.pat_patient          WHERE organization_id = 1;
DELETE FROM patient_engagement.core_number_sequence WHERE organization_id = 1;
DELETE FROM patient_engagement.evt_outbox           WHERE organization_id = 1;
DELETE FROM patient_engagement.evt_inbox            WHERE message_id::text NOT IN (SELECT id FROM keep_event);
DELETE FROM patient_engagement.ref_practitioner     WHERE practitioner_id IN (SELECT practitioner_id FROM x_pract);
DELETE FROM patient_engagement.ref_department       WHERE organization_id = 1;
DELETE FROM patient_engagement.ref_branch           WHERE organization_id = 1;
DELETE FROM patient_engagement.ref_organization     WHERE organization_id = 1;

-- clinical_care
DELETE FROM clinical_care.ord_order_item        WHERE order_id IN (SELECT order_id FROM clinical_care.ord_clinical_order WHERE organization_id = 1);
DELETE FROM clinical_care.ord_clinical_order    WHERE organization_id = 1;
DELETE FROM clinical_care.ord_prescription_item WHERE prescription_id IN (SELECT prescription_id FROM clinical_care.ord_prescription WHERE organization_id = 1);
DELETE FROM clinical_care.ord_prescription      WHERE organization_id = 1;
DELETE FROM clinical_care.emr_diagnosis         WHERE encounter_id IN (SELECT encounter_id FROM x_encounter) OR patient_id IN (SELECT patient_id FROM x_patient);
DELETE FROM clinical_care.emr_complaint         WHERE encounter_id IN (SELECT encounter_id FROM x_encounter) OR patient_id IN (SELECT patient_id FROM x_patient);
DELETE FROM clinical_care.emr_clinical_document WHERE organization_id = 1;
DELETE FROM clinical_care.ref_lab_result_summary WHERE patient_id IN (SELECT patient_id FROM x_patient);
DELETE FROM clinical_care.ref_encounter         WHERE organization_id = 1;
DELETE FROM clinical_care.ref_patient           WHERE patient_id IN (SELECT patient_id FROM x_patient);
DELETE FROM clinical_care.ref_practitioner      WHERE practitioner_id IN (SELECT practitioner_id FROM x_pract);
DELETE FROM clinical_care.ref_service           WHERE organization_id = 1;
DELETE FROM clinical_care.ref_branch            WHERE organization_id = 1;
DELETE FROM clinical_care.ref_organization      WHERE organization_id = 1;
DELETE FROM clinical_care.core_number_sequence  WHERE organization_id = 1;
DELETE FROM clinical_care.evt_outbox            WHERE organization_id = 1;
DELETE FROM clinical_care.evt_inbox             WHERE message_id::text NOT IN (SELECT id FROM keep_event);

-- diagnostics
DELETE FROM diagnostics.lab_result            WHERE sample_id IN (SELECT sample_id FROM diagnostics.lab_sample WHERE organization_id = 1) OR patient_id IN (SELECT patient_id FROM x_patient);
DELETE FROM diagnostics.lab_sample_order_item WHERE sample_id IN (SELECT sample_id FROM diagnostics.lab_sample WHERE organization_id = 1);
DELETE FROM diagnostics.lab_sample            WHERE organization_id = 1;
DELETE FROM diagnostics.lab_report            WHERE organization_id = 1;
DELETE FROM diagnostics.mst_lab_parameter     WHERE lab_test_id IN (SELECT lab_test_id FROM x_lab_test);
DELETE FROM diagnostics.mst_lab_test          WHERE lab_test_id IN (SELECT lab_test_id FROM x_lab_test);
DELETE FROM diagnostics.ref_order_item        WHERE order_id IN (SELECT order_id FROM diagnostics.ref_clinical_order WHERE organization_id = 1);
DELETE FROM diagnostics.ref_clinical_order    WHERE organization_id = 1;
DELETE FROM diagnostics.ref_encounter         WHERE organization_id = 1;
DELETE FROM diagnostics.ref_patient           WHERE patient_id IN (SELECT patient_id FROM x_patient);
DELETE FROM diagnostics.ref_practitioner      WHERE practitioner_id IN (SELECT practitioner_id FROM x_pract);
DELETE FROM diagnostics.ref_service           WHERE organization_id = 1;
DELETE FROM diagnostics.ref_branch            WHERE organization_id = 1;
DELETE FROM diagnostics.ref_organization      WHERE organization_id = 1;
DELETE FROM diagnostics.core_number_sequence  WHERE organization_id = 1;
DELETE FROM diagnostics.evt_outbox            WHERE organization_id = 1;
DELETE FROM diagnostics.evt_inbox             WHERE message_id::text NOT IN (SELECT id FROM keep_event);

-- revenue_finance
DELETE FROM revenue_finance.bil_receipt_allocation WHERE receipt_id IN (SELECT receipt_id FROM revenue_finance.bil_receipt WHERE organization_id = 1)
                                                      OR bill_id IN (SELECT bill_id FROM revenue_finance.bil_bill WHERE organization_id = 1);
DELETE FROM revenue_finance.bil_receipt_tender     WHERE receipt_id IN (SELECT receipt_id FROM revenue_finance.bil_receipt WHERE organization_id = 1);
DELETE FROM revenue_finance.bil_receipt            WHERE organization_id = 1;
DELETE FROM revenue_finance.bil_bill_line          WHERE bill_id IN (SELECT bill_id FROM revenue_finance.bil_bill WHERE organization_id = 1);
DELETE FROM revenue_finance.bil_bill               WHERE organization_id = 1;
DELETE FROM revenue_finance.mst_tariff_rate        WHERE tariff_plan_id IN (SELECT tariff_plan_id FROM revenue_finance.mst_tariff_plan WHERE organization_id = 1)
                                                      OR service_id IN (SELECT service_id FROM x_service);
DELETE FROM revenue_finance.mst_tariff_plan        WHERE organization_id = 1;
DELETE FROM revenue_finance.mst_service            WHERE organization_id = 1;
DELETE FROM revenue_finance.ref_encounter          WHERE organization_id = 1;
DELETE FROM revenue_finance.ref_patient            WHERE patient_id IN (SELECT patient_id FROM x_patient);
DELETE FROM revenue_finance.ref_branch             WHERE organization_id = 1;
DELETE FROM revenue_finance.ref_organization       WHERE organization_id = 1;
DELETE FROM revenue_finance.core_number_sequence   WHERE organization_id = 1;
DELETE FROM revenue_finance.evt_outbox             WHERE organization_id = 1;
DELETE FROM revenue_finance.evt_inbox              WHERE message_id::text NOT IN (SELECT id FROM keep_event);

-- integration_comms (FHIR links, message log and analyzer events here are all for Reddy's patients and samples)
DELETE FROM integration_comms.intg_fhir_resource_map;
DELETE FROM integration_comms.intg_message_log;
DELETE FROM integration_comms.evt_outbox  WHERE organization_id = 1 OR organization_id IS NULL;
DELETE FROM integration_comms.ref_encounter WHERE organization_id = 1;
DELETE FROM integration_comms.ref_patient WHERE patient_id IN (SELECT patient_id FROM x_patient);
DELETE FROM integration_comms.evt_inbox   WHERE message_id::text NOT IN (SELECT id FROM keep_event);

:final;
