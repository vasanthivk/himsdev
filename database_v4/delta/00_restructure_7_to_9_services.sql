/* =====================================================================================
   DR REDDIS HEALTHCARE - HIMS  database_v3 (7 services)  ->  database_v4 (9 services)
   Step 00 - restructure schemas: diagnostics -> lims + rims, operationssupply -> operationssupply + pharmacy
   Run against an EXISTING himsdev database that was built from database_v3, in file-name order:
     00_restructure_7_to_9_services.sql  -> 01..09_<service>_delta.sql  -> 10_post_migration_housekeeping.sql -> ../full/roles.sql
   Every statement is idempotent where PostgreSQL allows it (IF NOT EXISTS / guarded DO blocks).
   ===================================================================================== */

BEGIN;

-- 1. Schemas -------------------------------------------------------------------------
-- v4 schema names carry no underscore.
ALTER SCHEMA identity_org RENAME TO identityorg;
ALTER SCHEMA patient_engagement RENAME TO patientengagement;
ALTER SCHEMA clinical_care RENAME TO clinicalcare;
ALTER SCHEMA revenue_finance RENAME TO revenuefinance;
ALTER SCHEMA operations_supply RENAME TO operationssupply;
ALTER SCHEMA integration_comms RENAME TO integrationcomms;
-- The LIMS keeps every laboratory / blood-centre object, so the old schema is simply renamed.
ALTER SCHEMA diagnostics RENAME TO lims;
CREATE SCHEMA IF NOT EXISTS rims;
CREATE SCHEMA IF NOT EXISTS pharmacy;


CREATE OR REPLACE FUNCTION rims.util_reject_write() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION '% is a read-only view of a table owned by this service; write to the owner table instead', TG_TABLE_NAME;
END $$;

CREATE OR REPLACE FUNCTION rims.util_bump_row_ver() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver := COALESCE(OLD.row_ver, 0) + 1;
    RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION rims.util_touch_audit() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver    := COALESCE(OLD.row_ver, 0) + 1;
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END $$;


CREATE OR REPLACE FUNCTION pharmacy.util_reject_write() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION '% is a read-only view of a table owned by this service; write to the owner table instead', TG_TABLE_NAME;
END $$;

CREATE OR REPLACE FUNCTION pharmacy.util_bump_row_ver() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver := COALESCE(OLD.row_ver, 0) + 1;
    RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION pharmacy.util_touch_audit() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver    := COALESCE(OLD.row_ver, 0) + 1;
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END $$;


-- 2. Move tables owned by the new services (data, identity sequences, indexes and same-schema triggers move with the table)
ALTER TABLE operationssupply.mst_allergen SET SCHEMA pharmacy;
ALTER TABLE operationssupply.mst_drug SET SCHEMA pharmacy;
ALTER TABLE operationssupply.mst_drug_contraindication SET SCHEMA pharmacy;
ALTER TABLE operationssupply.mst_drug_generic SET SCHEMA pharmacy;
ALTER TABLE operationssupply.mst_drug_interaction SET SCHEMA pharmacy;
ALTER TABLE operationssupply.mst_drug_substitute SET SCHEMA pharmacy;
ALTER TABLE operationssupply.mst_generic SET SCHEMA pharmacy;
ALTER TABLE operationssupply.pha_counseling_note SET SCHEMA pharmacy;
ALTER TABLE operationssupply.pha_dispense SET SCHEMA pharmacy;
ALTER TABLE operationssupply.pha_dispense_item SET SCHEMA pharmacy;
ALTER TABLE operationssupply.pha_dispense_return SET SCHEMA pharmacy;
ALTER TABLE operationssupply.pha_dispense_return_item SET SCHEMA pharmacy;
ALTER TABLE operationssupply.pha_narcotic_register SET SCHEMA pharmacy;
ALTER TABLE operationssupply.ref_clinical_code SET SCHEMA pharmacy;
ALTER TABLE operationssupply.ref_practitioner SET SCHEMA pharmacy;
ALTER TABLE operationssupply.ref_prescription SET SCHEMA pharmacy;
ALTER TABLE operationssupply.ref_prescription_item SET SCHEMA pharmacy;
ALTER TABLE lims.mst_rad_procedure SET SCHEMA rims;
ALTER TABLE lims.pacs_ai_finding SET SCHEMA rims;
ALTER TABLE lims.pacs_annotation SET SCHEMA rims;
ALTER TABLE lims.pacs_dicom_node SET SCHEMA rims;
ALTER TABLE lims.pacs_dicom_series SET SCHEMA rims;
ALTER TABLE lims.pacs_dicom_study SET SCHEMA rims;
ALTER TABLE lims.pacs_reading_assignment SET SCHEMA rims;
ALTER TABLE lims.pacs_share_link SET SCHEMA rims;
ALTER TABLE lims.rad_modality SET SCHEMA rims;
ALTER TABLE lims.rad_report SET SCHEMA rims;
ALTER TABLE lims.rad_report_template SET SCHEMA rims;
ALTER TABLE lims.rad_study SET SCHEMA rims;
ALTER TABLE lims.ref_room SET SCHEMA rims;
ALTER TABLE lims.ref_slot SET SCHEMA rims;

-- 3. Shared infrastructure / replicas needed by BOTH halves of a split service: create a copy in the new schema
CREATE TABLE IF NOT EXISTS pharmacy.core_number_sequence (LIKE operationssupply.core_number_sequence INCLUDING ALL);
CREATE TABLE IF NOT EXISTS pharmacy.evt_inbox (LIKE operationssupply.evt_inbox INCLUDING ALL);
CREATE TABLE IF NOT EXISTS pharmacy.evt_outbox (LIKE operationssupply.evt_outbox INCLUDING ALL);
CREATE TABLE IF NOT EXISTS pharmacy.evt_saga_instance (LIKE operationssupply.evt_saga_instance INCLUDING ALL);
CREATE TABLE IF NOT EXISTS pharmacy.ref_branch (LIKE operationssupply.ref_branch INCLUDING ALL);
CREATE TABLE IF NOT EXISTS pharmacy.ref_employee (LIKE operationssupply.ref_employee INCLUDING ALL);
CREATE TABLE IF NOT EXISTS pharmacy.ref_encounter (LIKE operationssupply.ref_encounter INCLUDING ALL);
CREATE TABLE IF NOT EXISTS pharmacy.ref_organization (LIKE operationssupply.ref_organization INCLUDING ALL);
CREATE TABLE IF NOT EXISTS pharmacy.ref_patient (LIKE operationssupply.ref_patient INCLUDING ALL);
CREATE TABLE IF NOT EXISTS rims.core_number_sequence (LIKE lims.core_number_sequence INCLUDING ALL);
CREATE TABLE IF NOT EXISTS rims.evt_inbox (LIKE lims.evt_inbox INCLUDING ALL);
CREATE TABLE IF NOT EXISTS rims.evt_outbox (LIKE lims.evt_outbox INCLUDING ALL);
CREATE TABLE IF NOT EXISTS rims.evt_saga_instance (LIKE lims.evt_saga_instance INCLUDING ALL);
CREATE TABLE IF NOT EXISTS rims.ref_branch (LIKE lims.ref_branch INCLUDING ALL);
CREATE TABLE IF NOT EXISTS rims.ref_employee (LIKE lims.ref_employee INCLUDING ALL);
CREATE TABLE IF NOT EXISTS rims.ref_item (LIKE lims.ref_item INCLUDING ALL);
CREATE TABLE IF NOT EXISTS rims.ref_order_item (LIKE lims.ref_order_item INCLUDING ALL);
CREATE TABLE IF NOT EXISTS rims.ref_organization (LIKE lims.ref_organization INCLUDING ALL);
CREATE TABLE IF NOT EXISTS rims.ref_patient (LIKE lims.ref_patient INCLUDING ALL);
CREATE TABLE IF NOT EXISTS rims.ref_practitioner (LIKE lims.ref_practitioner INCLUDING ALL);
CREATE TABLE IF NOT EXISTS rims.ref_report_letterhead (LIKE lims.ref_report_letterhead INCLUDING ALL);
CREATE TABLE IF NOT EXISTS rims.ref_service (LIKE lims.ref_service INCLUDING ALL);

-- copy data of replicas and number sequences (outbox / inbox / saga start empty in the new schema)
INSERT INTO pharmacy.core_number_sequence (number_sequence_id, organization_id, branch_id, sequence_code, prefix, fiscal_year, next_value, pad_length, is_active, created_at, created_by, updated_at, updated_by, row_ver) SELECT number_sequence_id, organization_id, branch_id, sequence_code, prefix, fiscal_year, next_value, pad_length, is_active, created_at, created_by, updated_at, updated_by, row_ver FROM operationssupply.core_number_sequence ON CONFLICT DO NOTHING;
SELECT setval(pg_get_serial_sequence('pharmacy.core_number_sequence', 'number_sequence_id'), COALESCE((SELECT MAX(number_sequence_id) FROM pharmacy.core_number_sequence), 0) + 1, false);
INSERT INTO pharmacy.ref_branch (branch_id, organization_id, branch_code, branch_name, branch_type, state_code, gstin, abdm_hfr_id, source_version, replicated_at) SELECT branch_id, organization_id, branch_code, branch_name, branch_type, state_code, gstin, abdm_hfr_id, source_version, replicated_at FROM operationssupply.ref_branch ON CONFLICT DO NOTHING;
INSERT INTO pharmacy.ref_employee (employee_id, branch_id, employee_code, first_name, last_name, department_id, designation_id, employee_status, source_version, replicated_at) SELECT employee_id, branch_id, employee_code, first_name, last_name, department_id, designation_id, employee_status, source_version, replicated_at FROM operationssupply.ref_employee ON CONFLICT DO NOTHING;
INSERT INTO pharmacy.ref_encounter (encounter_id, organization_id, branch_id, encounter_no, patient_id, encounter_type, department_id, specialty_id, attending_practitioner_id, tariff_plan_id, primary_patient_payer_id, financial_class, is_mlc, start_at, end_at, encounter_status, source_version, replicated_at) SELECT encounter_id, organization_id, branch_id, encounter_no, patient_id, encounter_type, department_id, specialty_id, attending_practitioner_id, tariff_plan_id, primary_patient_payer_id, financial_class, is_mlc, start_at, end_at, encounter_status, source_version, replicated_at FROM operationssupply.ref_encounter ON CONFLICT DO NOTHING;
INSERT INTO pharmacy.ref_organization (organization_id, org_code, org_name, source_version, replicated_at) SELECT organization_id, org_code, org_name, source_version, replicated_at FROM operationssupply.ref_organization ON CONFLICT DO NOTHING;
INSERT INTO pharmacy.ref_patient (patient_id, uhid, abha_number, title, first_name, middle_name, last_name, date_of_birth, gender, blood_group, mobile, is_vip, is_confidential, is_deceased, merged_into_patient_id, source_version, replicated_at) SELECT patient_id, uhid, abha_number, title, first_name, middle_name, last_name, date_of_birth, gender, blood_group, mobile, is_vip, is_confidential, is_deceased, merged_into_patient_id, source_version, replicated_at FROM operationssupply.ref_patient ON CONFLICT DO NOTHING;
INSERT INTO rims.core_number_sequence (number_sequence_id, organization_id, branch_id, sequence_code, prefix, fiscal_year, next_value, pad_length, is_active, created_at, created_by, updated_at, updated_by, row_ver) SELECT number_sequence_id, organization_id, branch_id, sequence_code, prefix, fiscal_year, next_value, pad_length, is_active, created_at, created_by, updated_at, updated_by, row_ver FROM lims.core_number_sequence ON CONFLICT DO NOTHING;
SELECT setval(pg_get_serial_sequence('rims.core_number_sequence', 'number_sequence_id'), COALESCE((SELECT MAX(number_sequence_id) FROM rims.core_number_sequence), 0) + 1, false);
INSERT INTO rims.ref_branch (branch_id, organization_id, branch_code, branch_name, branch_type, state_code, gstin, abdm_hfr_id, source_version, replicated_at) SELECT branch_id, organization_id, branch_code, branch_name, branch_type, state_code, gstin, abdm_hfr_id, source_version, replicated_at FROM lims.ref_branch ON CONFLICT DO NOTHING;
INSERT INTO rims.ref_employee (employee_id, branch_id, employee_code, first_name, last_name, department_id, designation_id, employee_status, source_version, replicated_at) SELECT employee_id, branch_id, employee_code, first_name, last_name, department_id, designation_id, employee_status, source_version, replicated_at FROM lims.ref_employee ON CONFLICT DO NOTHING;
INSERT INTO rims.ref_item (item_id, organization_id, item_category_id, item_code, item_name, item_type, hsn_code, gst_rate, is_batch_tracked, is_expiry_tracked, is_serial_tracked, is_billable, is_cold_chain, barcode, updated_at, updated_by, source_version, replicated_at) SELECT item_id, organization_id, item_category_id, item_code, item_name, item_type, hsn_code, gst_rate, is_batch_tracked, is_expiry_tracked, is_serial_tracked, is_billable, is_cold_chain, barcode, updated_at, updated_by, source_version, replicated_at FROM lims.ref_item ON CONFLICT DO NOTHING;
INSERT INTO rims.ref_order_item (order_item_id, order_id, service_id, performing_branch_id, performing_department_id, item_status, is_billed, bill_no, bill_status, is_paid, updated_at, updated_by, source_version, replicated_at) SELECT order_item_id, order_id, service_id, performing_branch_id, performing_department_id, item_status, is_billed, bill_no, bill_status, is_paid, updated_at, updated_by, source_version, replicated_at FROM lims.ref_order_item ON CONFLICT DO NOTHING;
INSERT INTO rims.ref_organization (organization_id, org_code, org_name, source_version, replicated_at) SELECT organization_id, org_code, org_name, source_version, replicated_at FROM lims.ref_organization ON CONFLICT DO NOTHING;
INSERT INTO rims.ref_patient (patient_id, uhid, abha_number, title, first_name, middle_name, last_name, date_of_birth, gender, blood_group, mobile, is_vip, is_confidential, is_deceased, merged_into_patient_id, source_version, replicated_at) SELECT patient_id, uhid, abha_number, title, first_name, middle_name, last_name, date_of_birth, gender, blood_group, mobile, is_vip, is_confidential, is_deceased, merged_into_patient_id, source_version, replicated_at FROM lims.ref_patient ON CONFLICT DO NOTHING;
INSERT INTO rims.ref_practitioner (practitioner_id, employee_id, practitioner_type, display_name, primary_specialty_id, qualification, registration_no, abdm_hpr_id, signature_uri, source_version, replicated_at) SELECT practitioner_id, employee_id, practitioner_type, display_name, primary_specialty_id, qualification, registration_no, abdm_hpr_id, signature_uri, source_version, replicated_at FROM lims.ref_practitioner ON CONFLICT DO NOTHING;
INSERT INTO rims.ref_report_letterhead (report_letterhead_id, organization_id, branch_id, payer_id, report_type, updated_at, updated_by, source_version, replicated_at) SELECT report_letterhead_id, organization_id, branch_id, payer_id, report_type, updated_at, updated_by, source_version, replicated_at FROM lims.ref_report_letterhead ON CONFLICT DO NOTHING;
INSERT INTO rims.ref_service (service_id, organization_id, service_category_id, department_id, service_code, service_name, service_type, clinical_code_id, sac_code, gst_rate, is_orderable, is_billable, is_doctor_payout, updated_at, updated_by, source_version, replicated_at) SELECT service_id, organization_id, service_category_id, department_id, service_code, service_name, service_type, clinical_code_id, sac_code, gst_rate, is_orderable, is_billable, is_doctor_payout, updated_at, updated_by, source_version, replicated_at FROM lims.ref_service ON CONFLICT DO NOTHING;

-- 4. Physical FKs that now cross a service boundary become logical FKs (v4 convention: no FK between service schemas)
DO $$
DECLARE r record;
BEGIN
    FOR r IN
        SELECT n.nspname AS sch, cl.relname AS tbl, c.conname, fn.nspname AS ref_sch, fr.relname AS ref_tbl
          FROM pg_constraint c
          JOIN pg_class cl      ON cl.oid = c.conrelid
          JOIN pg_namespace n   ON n.oid  = cl.relnamespace
          JOIN pg_class fr      ON fr.oid = c.confrelid
          JOIN pg_namespace fn  ON fn.oid = fr.relnamespace
         WHERE c.contype = 'f' AND n.nspname <> fn.nspname
           AND n.nspname IN ('identityorg', 'patientengagement', 'clinicalcare', 'lims', 'rims', 'revenuefinance', 'operationssupply', 'integrationcomms', 'pharmacy')
    LOOP
        EXECUTE format('ALTER TABLE %I.%I DROP CONSTRAINT %I', r.sch, r.tbl, r.conname);
        RAISE NOTICE 'dropped cross-service FK %.%.% -> %.%', r.sch, r.tbl, r.conname, r.ref_sch, r.ref_tbl;
    END LOOP;
END $$;

-- 5. Re-point read-only view triggers / row_ver triggers of moved objects is done in step 10.
COMMIT;
