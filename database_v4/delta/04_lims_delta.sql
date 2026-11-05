/* =====================================================================================
   DR REDDIS HEALTHCARE - HIMS  database_v3 (7 services)  ->  database_v4 (9 services)
   Step 04 - LIMS (Laboratory & Blood Centre): column additions to existing tables + new FDS tables
   Run against an EXISTING himsdev database that was built from database_v3, in file-name order:
     00_restructure_7_to_9_services.sql  -> 01..09_<service>_delta.sql  -> 10_post_migration_housekeeping.sql -> ../full/roles.sql
   Every statement is idempotent where PostgreSQL allows it (IF NOT EXISTS / guarded DO blocks).
   ===================================================================================== */

BEGIN;

/* ---------- A. MODIFICATIONS TO EXISTING TABLES (ADD COLUMN) ---------- */

-- lims.bb_blood_unit  (5 new columns)  FDS: LAB-BB-006, LAB-BB-010..013
ALTER TABLE lims.bb_blood_unit ADD COLUMN IF NOT EXISTS parent_blood_unit_id BIGINT NULL;
ALTER TABLE lims.bb_blood_unit ADD COLUMN IF NOT EXISTS external_blood_centre VARCHAR(200) NULL;
ALTER TABLE lims.bb_blood_unit ADD COLUMN IF NOT EXISTS external_bag_no VARCHAR(50) NULL;
ALTER TABLE lims.bb_blood_unit ADD COLUMN IF NOT EXISTS quarantine_released_at TIMESTAMPTZ(0) NULL;
ALTER TABLE lims.bb_blood_unit ADD COLUMN IF NOT EXISTS reserved_for_request_id BIGINT NULL;
COMMENT ON COLUMN lims.bb_blood_unit.parent_blood_unit_id IS 'component prepared from whole blood [v4: LAB-BB-006, LAB-BB-010..013]';
COMMENT ON COLUMN lims.bb_blood_unit.external_blood_centre IS '[v4: LAB-BB-006, LAB-BB-010..013]';
COMMENT ON COLUMN lims.bb_blood_unit.external_bag_no IS '[v4: LAB-BB-006, LAB-BB-010..013]';
COMMENT ON COLUMN lims.bb_blood_unit.quarantine_released_at IS '[v4: LAB-BB-006, LAB-BB-010..013]';
COMMENT ON COLUMN lims.bb_blood_unit.reserved_for_request_id IS '[v4: LAB-BB-006, LAB-BB-010..013]';

-- lims.bb_donation  (9 new columns)  FDS: LAB-BB-002, LAB-BB-003
ALTER TABLE lims.bb_donation ADD COLUMN IF NOT EXISTS hb_g_dl DECIMAL(4,1) NULL;
ALTER TABLE lims.bb_donation ADD COLUMN IF NOT EXISTS bp_systolic SMALLINT NULL;
ALTER TABLE lims.bb_donation ADD COLUMN IF NOT EXISTS bp_diastolic SMALLINT NULL;
ALTER TABLE lims.bb_donation ADD COLUMN IF NOT EXISTS weight_kg DECIMAL(5,1) NULL;
ALTER TABLE lims.bb_donation ADD COLUMN IF NOT EXISTS pulse_bpm SMALLINT NULL;
ALTER TABLE lims.bb_donation ADD COLUMN IF NOT EXISTS questionnaire_json JSONB NULL;
ALTER TABLE lims.bb_donation ADD COLUMN IF NOT EXISTS is_eligible BOOLEAN NULL;
ALTER TABLE lims.bb_donation ADD COLUMN IF NOT EXISTS deferral_reason VARCHAR(300) NULL;
ALTER TABLE lims.bb_donation ADD COLUMN IF NOT EXISTS deferred_until DATE NULL;
COMMENT ON COLUMN lims.bb_donation.hb_g_dl IS '[v4: LAB-BB-002, LAB-BB-003]';
COMMENT ON COLUMN lims.bb_donation.bp_systolic IS '[v4: LAB-BB-002, LAB-BB-003]';
COMMENT ON COLUMN lims.bb_donation.bp_diastolic IS '[v4: LAB-BB-002, LAB-BB-003]';
COMMENT ON COLUMN lims.bb_donation.weight_kg IS '[v4: LAB-BB-002, LAB-BB-003]';
COMMENT ON COLUMN lims.bb_donation.pulse_bpm IS '[v4: LAB-BB-002, LAB-BB-003]';
COMMENT ON COLUMN lims.bb_donation.questionnaire_json IS '[v4: LAB-BB-002, LAB-BB-003]';
COMMENT ON COLUMN lims.bb_donation.is_eligible IS '[v4: LAB-BB-002, LAB-BB-003]';
COMMENT ON COLUMN lims.bb_donation.deferral_reason IS '[v4: LAB-BB-002, LAB-BB-003]';
COMMENT ON COLUMN lims.bb_donation.deferred_until IS '[v4: LAB-BB-002, LAB-BB-003]';

-- lims.bb_donor  (4 new columns)  FDS: LAB-BB-001, LAB-BB-003
ALTER TABLE lims.bb_donor ADD COLUMN IF NOT EXISTS donor_category VARCHAR(20) NULL;
ALTER TABLE lims.bb_donor ADD COLUMN IF NOT EXISTS id_proof_type VARCHAR(30) NULL;
ALTER TABLE lims.bb_donor ADD COLUMN IF NOT EXISTS id_proof_no_masked VARCHAR(30) NULL;
ALTER TABLE lims.bb_donor ADD COLUMN IF NOT EXISTS total_donations SMALLINT NULL DEFAULT 0;
COMMENT ON COLUMN lims.bb_donor.donor_category IS 'VOLUNTARY, REPLACEMENT, AUTOLOGOUS, DIRECTED [v4: LAB-BB-001, LAB-BB-003]';
COMMENT ON COLUMN lims.bb_donor.id_proof_type IS '[v4: LAB-BB-001, LAB-BB-003]';
COMMENT ON COLUMN lims.bb_donor.id_proof_no_masked IS '[v4: LAB-BB-001, LAB-BB-003]';
COMMENT ON COLUMN lims.bb_donor.total_donations IS '[v4: LAB-BB-001, LAB-BB-003]';

-- lims.lab_analyzer  (4 new columns)  FDS: LAB-INT-001/008/011 (Analyzer entity)
ALTER TABLE lims.lab_analyzer ADD COLUMN IF NOT EXISTS analyzer_type VARCHAR(20) NULL;
ALTER TABLE lims.lab_analyzer ADD COLUMN IF NOT EXISTS status_changed_at TIMESTAMPTZ(0) NULL;
ALTER TABLE lims.lab_analyzer ADD COLUMN IF NOT EXISTS status_reason VARCHAR(300) NULL;
ALTER TABLE lims.lab_analyzer ADD COLUMN IF NOT EXISTS qc_lock_active BOOLEAN NULL DEFAULT FALSE;
COMMENT ON COLUMN lims.lab_analyzer.analyzer_type IS 'ANALYZER, POC, MANUAL_BENCH [v4: LAB-INT-001/008/011 (Analyzer entity)]';
COMMENT ON COLUMN lims.lab_analyzer.status_changed_at IS '[v4: LAB-INT-001/008/011 (Analyzer entity)]';
COMMENT ON COLUMN lims.lab_analyzer.status_reason IS '[v4: LAB-INT-001/008/011 (Analyzer entity)]';
COMMENT ON COLUMN lims.lab_analyzer.qc_lock_active IS '[v4: LAB-INT-001/008/011 (Analyzer entity)]';

-- lims.lab_analyzer_parameter_map  (2 new columns)  FDS: LAB-INT-002
ALTER TABLE lims.lab_analyzer_parameter_map ADD COLUMN IF NOT EXISTS machine_unit VARCHAR(20) NULL;
ALTER TABLE lims.lab_analyzer_parameter_map ADD COLUMN IF NOT EXISTS is_active_for_download BOOLEAN NULL DEFAULT TRUE;
COMMENT ON COLUMN lims.lab_analyzer_parameter_map.machine_unit IS '[v4: LAB-INT-002]';
COMMENT ON COLUMN lims.lab_analyzer_parameter_map.is_active_for_download IS '[v4: LAB-INT-002]';

-- lims.lab_calibration_log  (2 new columns)  FDS: LAB-QC-005/006
ALTER TABLE lims.lab_calibration_log ADD COLUMN IF NOT EXISTS is_locked BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE lims.lab_calibration_log ADD COLUMN IF NOT EXISTS corrects_calibration_log_id BIGINT NULL;
COMMENT ON COLUMN lims.lab_calibration_log.is_locked IS '[v4: LAB-QC-005/006]';
COMMENT ON COLUMN lims.lab_calibration_log.corrects_calibration_log_id IS '[v4: LAB-QC-005/006]';

-- lims.lab_critical_value_alert  (5 new columns)  FDS: LAB-CVA-002..006 (Critical value alert entity)
ALTER TABLE lims.lab_critical_value_alert ADD COLUMN IF NOT EXISTS escalation_level SMALLINT NULL DEFAULT 0;
ALTER TABLE lims.lab_critical_value_alert ADD COLUMN IF NOT EXISTS escalated_at TIMESTAMPTZ(0) NULL;
ALTER TABLE lims.lab_critical_value_alert ADD COLUMN IF NOT EXISTS escalated_to VARCHAR(150) NULL;
ALTER TABLE lims.lab_critical_value_alert ADD COLUMN IF NOT EXISTS acknowledged_by_name VARCHAR(150) NULL;
ALTER TABLE lims.lab_critical_value_alert ADD COLUMN IF NOT EXISTS alert_channel_detail VARCHAR(100) NULL;
COMMENT ON COLUMN lims.lab_critical_value_alert.escalation_level IS '[v4: LAB-CVA-002..006 (Critical value alert entity)]';
COMMENT ON COLUMN lims.lab_critical_value_alert.escalated_at IS '[v4: LAB-CVA-002..006 (Critical value alert entity)]';
COMMENT ON COLUMN lims.lab_critical_value_alert.escalated_to IS '[v4: LAB-CVA-002..006 (Critical value alert entity)]';
COMMENT ON COLUMN lims.lab_critical_value_alert.acknowledged_by_name IS '[v4: LAB-CVA-002..006 (Critical value alert entity)]';
COMMENT ON COLUMN lims.lab_critical_value_alert.alert_channel_detail IS '[v4: LAB-CVA-002..006 (Critical value alert entity)]';

-- lims.lab_micro_culture  (7 new columns)  FDS: LAB-MIC-001/004/005
ALTER TABLE lims.lab_micro_culture ADD COLUMN IF NOT EXISTS culture_setup_at TIMESTAMPTZ(0) NULL;
ALTER TABLE lims.lab_micro_culture ADD COLUMN IF NOT EXISTS culture_media VARCHAR(200) NULL;
ALTER TABLE lims.lab_micro_culture ADD COLUMN IF NOT EXISTS incubation_conditions VARCHAR(100) NULL;
ALTER TABLE lims.lab_micro_culture ADD COLUMN IF NOT EXISTS report_stage VARCHAR(20) NULL;
ALTER TABLE lims.lab_micro_culture ADD COLUMN IF NOT EXISTS preliminary_released_at TIMESTAMPTZ(0) NULL;
ALTER TABLE lims.lab_micro_culture ADD COLUMN IF NOT EXISTS final_released_at TIMESTAMPTZ(0) NULL;
ALTER TABLE lims.lab_micro_culture ADD COLUMN IF NOT EXISTS mdro_type VARCHAR(20) NULL;
COMMENT ON COLUMN lims.lab_micro_culture.culture_setup_at IS '[v4: LAB-MIC-001/004/005]';
COMMENT ON COLUMN lims.lab_micro_culture.culture_media IS '[v4: LAB-MIC-001/004/005]';
COMMENT ON COLUMN lims.lab_micro_culture.incubation_conditions IS '[v4: LAB-MIC-001/004/005]';
COMMENT ON COLUMN lims.lab_micro_culture.report_stage IS 'PRELIMINARY, FINAL [v4: LAB-MIC-001/004/005]';
COMMENT ON COLUMN lims.lab_micro_culture.preliminary_released_at IS '[v4: LAB-MIC-001/004/005]';
COMMENT ON COLUMN lims.lab_micro_culture.final_released_at IS '[v4: LAB-MIC-001/004/005]';
COMMENT ON COLUMN lims.lab_micro_culture.mdro_type IS 'MRSA, ESBL, CRE, VRE ... [v4: LAB-MIC-001/004/005]';

-- lims.lab_outsource_dispatch  (5 new columns)  FDS: LAB-OUT-002..006 (Outsource dispatch entity)
ALTER TABLE lims.lab_outsource_dispatch ADD COLUMN IF NOT EXISTS outsource_manifest_id BIGINT NULL;
ALTER TABLE lims.lab_outsource_dispatch ADD COLUMN IF NOT EXISTS vendor_tat_due_at TIMESTAMPTZ(0) NULL;
ALTER TABLE lims.lab_outsource_dispatch ADD COLUMN IF NOT EXISTS result_receipt_mode VARCHAR(20) NULL;
ALTER TABLE lims.lab_outsource_dispatch ADD COLUMN IF NOT EXISTS delay_alert_sent_at TIMESTAMPTZ(0) NULL;
ALTER TABLE lims.lab_outsource_dispatch ADD COLUMN IF NOT EXISTS dispatch_status VARCHAR(20) NULL;
COMMENT ON COLUMN lims.lab_outsource_dispatch.outsource_manifest_id IS '[v4: LAB-OUT-002..006 (Outsource dispatch entity)]';
COMMENT ON COLUMN lims.lab_outsource_dispatch.vendor_tat_due_at IS '[v4: LAB-OUT-002..006 (Outsource dispatch entity)]';
COMMENT ON COLUMN lims.lab_outsource_dispatch.result_receipt_mode IS 'MANUAL, FILE_UPLOAD, INTERFACE [v4: LAB-OUT-002..006 (Outsource dispatch entity)]';
COMMENT ON COLUMN lims.lab_outsource_dispatch.delay_alert_sent_at IS '[v4: LAB-OUT-002..006 (Outsource dispatch entity)]';
COMMENT ON COLUMN lims.lab_outsource_dispatch.dispatch_status IS 'DISPATCHED, RESULT_RECEIVED, DELAYED, CANCELLED [v4: LAB-OUT-002..006 (Outsource dispatch entity)]';

-- lims.lab_qc_run  (4 new columns)  FDS: LAB-QC-002/004/005
ALTER TABLE lims.lab_qc_run ADD COLUMN IF NOT EXISTS qc_lot_id INT NULL;
ALTER TABLE lims.lab_qc_run ADD COLUMN IF NOT EXISTS westgard_rules_checked VARCHAR(100) NULL;
ALTER TABLE lims.lab_qc_run ADD COLUMN IF NOT EXISTS is_locked BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE lims.lab_qc_run ADD COLUMN IF NOT EXISTS corrects_qc_run_id BIGINT NULL;
COMMENT ON COLUMN lims.lab_qc_run.qc_lot_id IS '[v4: LAB-QC-002/004/005]';
COMMENT ON COLUMN lims.lab_qc_run.westgard_rules_checked IS '[v4: LAB-QC-002/004/005]';
COMMENT ON COLUMN lims.lab_qc_run.is_locked IS '[v4: LAB-QC-002/004/005]';
COMMENT ON COLUMN lims.lab_qc_run.corrects_qc_run_id IS '[v4: LAB-QC-002/004/005]';

-- lims.lab_reagent_load  (7 new columns)  FDS: LAB-INT-009/010/012 (Reagent load entity)
ALTER TABLE lims.lab_reagent_load ADD COLUMN IF NOT EXISTS item_batch_id BIGINT NULL;
ALTER TABLE lims.lab_reagent_load ADD COLUMN IF NOT EXISTS expiry_date DATE NULL;
ALTER TABLE lims.lab_reagent_load ADD COLUMN IF NOT EXISTS tests_run_count INT NULL DEFAULT 0;
ALTER TABLE lims.lab_reagent_load ADD COLUMN IF NOT EXISTS low_alert_threshold INT NULL;
ALTER TABLE lims.lab_reagent_load ADD COLUMN IF NOT EXISTS low_alert_sent_at TIMESTAMPTZ(0) NULL;
ALTER TABLE lims.lab_reagent_load ADD COLUMN IF NOT EXISTS expired_override_reason VARCHAR(300) NULL;
ALTER TABLE lims.lab_reagent_load ADD COLUMN IF NOT EXISTS unloaded_at TIMESTAMPTZ(0) NULL;
COMMENT ON COLUMN lims.lab_reagent_load.item_batch_id IS 'operationssupply.inv_item_batch [v4: LAB-INT-009/010/012 (Reagent load entity)]';
COMMENT ON COLUMN lims.lab_reagent_load.expiry_date IS '[v4: LAB-INT-009/010/012 (Reagent load entity)]';
COMMENT ON COLUMN lims.lab_reagent_load.tests_run_count IS '[v4: LAB-INT-009/010/012 (Reagent load entity)]';
COMMENT ON COLUMN lims.lab_reagent_load.low_alert_threshold IS '[v4: LAB-INT-009/010/012 (Reagent load entity)]';
COMMENT ON COLUMN lims.lab_reagent_load.low_alert_sent_at IS '[v4: LAB-INT-009/010/012 (Reagent load entity)]';
COMMENT ON COLUMN lims.lab_reagent_load.expired_override_reason IS '[v4: LAB-INT-009/010/012 (Reagent load entity)]';
COMMENT ON COLUMN lims.lab_reagent_load.unloaded_at IS '[v4: LAB-INT-009/010/012 (Reagent load entity)]';

-- lims.lab_reflex_rule  (4 new columns)  FDS: LAB-RES-015/016
ALTER TABLE lims.lab_reflex_rule ADD COLUMN IF NOT EXISTS condition_operator VARCHAR(10) NULL;
ALTER TABLE lims.lab_reflex_rule ADD COLUMN IF NOT EXISTS condition_value DECIMAL(14,4) NULL;
ALTER TABLE lims.lab_reflex_rule ADD COLUMN IF NOT EXISTS requires_approval BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE lims.lab_reflex_rule ADD COLUMN IF NOT EXISTS notify_ordering_doctor BOOLEAN NULL DEFAULT TRUE;
COMMENT ON COLUMN lims.lab_reflex_rule.condition_operator IS '[v4: LAB-RES-015/016]';
COMMENT ON COLUMN lims.lab_reflex_rule.condition_value IS '[v4: LAB-RES-015/016]';
COMMENT ON COLUMN lims.lab_reflex_rule.requires_approval IS '[v4: LAB-RES-015/016]';
COMMENT ON COLUMN lims.lab_reflex_rule.notify_ordering_doctor IS '[v4: LAB-RES-015/016]';

-- lims.lab_report  (9 new columns)  FDS: LAB-RPT-001..014 (Lab report entity)
ALTER TABLE lims.lab_report ADD COLUMN IF NOT EXISTS report_no VARCHAR(30) NULL;
ALTER TABLE lims.lab_report ADD COLUMN IF NOT EXISTS is_partial BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE lims.lab_report ADD COLUMN IF NOT EXISTS release_hold_reason VARCHAR(30) NULL;
ALTER TABLE lims.lab_report ADD COLUMN IF NOT EXISTS verification_token VARCHAR(100) NULL;
ALTER TABLE lims.lab_report ADD COLUMN IF NOT EXISTS amendment_note VARCHAR(500) NULL;
ALTER TABLE lims.lab_report ADD COLUMN IF NOT EXISTS b2b_payer_id INT NULL;
ALTER TABLE lims.lab_report ADD COLUMN IF NOT EXISTS referral_lab_note VARCHAR(300) NULL;
ALTER TABLE lims.lab_report ADD COLUMN IF NOT EXISTS abdm_shared_at TIMESTAMPTZ(0) NULL;
ALTER TABLE lims.lab_report ADD COLUMN IF NOT EXISTS patient_notified_at TIMESTAMPTZ(0) NULL;
COMMENT ON COLUMN lims.lab_report.report_no IS '[v4: LAB-RPT-001..014 (Lab report entity)]';
COMMENT ON COLUMN lims.lab_report.is_partial IS '[v4: LAB-RPT-001..014 (Lab report entity)]';
COMMENT ON COLUMN lims.lab_report.release_hold_reason IS 'PAYMENT_PENDING, PENDING_VALIDATION [v4: LAB-RPT-001..014 (Lab report entity)]';
COMMENT ON COLUMN lims.lab_report.verification_token IS 'QR / verification link [v4: LAB-RPT-001..014 (Lab report entity)]';
COMMENT ON COLUMN lims.lab_report.amendment_note IS '[v4: LAB-RPT-001..014 (Lab report entity)]';
COMMENT ON COLUMN lims.lab_report.b2b_payer_id IS '[v4: LAB-RPT-001..014 (Lab report entity)]';
COMMENT ON COLUMN lims.lab_report.referral_lab_note IS '[v4: LAB-RPT-001..014 (Lab report entity)]';
COMMENT ON COLUMN lims.lab_report.abdm_shared_at IS '[v4: LAB-RPT-001..014 (Lab report entity)]';
COMMENT ON COLUMN lims.lab_report.patient_notified_at IS '[v4: LAB-RPT-001..014 (Lab report entity)]';

-- lims.lab_result  (18 new columns)  FDS: LAB-RES-001..014, LAB-INT-007, LAB-SEC-002/004 (Result entity)
ALTER TABLE lims.lab_result ADD COLUMN IF NOT EXISTS run_no SMALLINT NULL DEFAULT 1;
ALTER TABLE lims.lab_result ADD COLUMN IF NOT EXISTS is_reportable BOOLEAN NULL DEFAULT TRUE;
ALTER TABLE lims.lab_result ADD COLUMN IF NOT EXISTS analyzer_flags VARCHAR(100) NULL;
ALTER TABLE lims.lab_result ADD COLUMN IF NOT EXISTS analyzer_error_code VARCHAR(30) NULL;
ALTER TABLE lims.lab_result ADD COLUMN IF NOT EXISTS dilution_factor DECIMAL(8,2) NULL;
ALTER TABLE lims.lab_result ADD COLUMN IF NOT EXISTS method VARCHAR(100) NULL;
ALTER TABLE lims.lab_result ADD COLUMN IF NOT EXISTS is_auto_verified BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE lims.lab_result ADD COLUMN IF NOT EXISTS autoverify_rule_id INT NULL;
ALTER TABLE lims.lab_result ADD COLUMN IF NOT EXISTS tech_verified_by BIGINT NULL;
ALTER TABLE lims.lab_result ADD COLUMN IF NOT EXISTS tech_verified_at TIMESTAMPTZ(0) NULL;
ALTER TABLE lims.lab_result ADD COLUMN IF NOT EXISTS path_validated_by BIGINT NULL;
ALTER TABLE lims.lab_result ADD COLUMN IF NOT EXISTS path_validated_at TIMESTAMPTZ(0) NULL;
ALTER TABLE lims.lab_result ADD COLUMN IF NOT EXISTS delta_ack_by BIGINT NULL;
ALTER TABLE lims.lab_result ADD COLUMN IF NOT EXISTS delta_ack_at TIMESTAMPTZ(0) NULL;
ALTER TABLE lims.lab_result ADD COLUMN IF NOT EXISTS delta_ack_comment VARCHAR(300) NULL;
ALTER TABLE lims.lab_result ADD COLUMN IF NOT EXISTS released_at TIMESTAMPTZ(0) NULL;
ALTER TABLE lims.lab_result ADD COLUMN IF NOT EXISTS lab_report_id BIGINT NULL;
ALTER TABLE lims.lab_result ADD COLUMN IF NOT EXISTS is_outsourced_result BOOLEAN NULL DEFAULT FALSE;
COMMENT ON COLUMN lims.lab_result.run_no IS '[v4: LAB-RES-001..014, LAB-INT-007, LAB-SEC-002/004 (Result entity)]';
COMMENT ON COLUMN lims.lab_result.is_reportable IS '[v4: LAB-RES-001..014, LAB-INT-007, LAB-SEC-002/004 (Result entity)]';
COMMENT ON COLUMN lims.lab_result.analyzer_flags IS '[v4: LAB-RES-001..014, LAB-INT-007, LAB-SEC-002/004 (Result entity)]';
COMMENT ON COLUMN lims.lab_result.analyzer_error_code IS '[v4: LAB-RES-001..014, LAB-INT-007, LAB-SEC-002/004 (Result entity)]';
COMMENT ON COLUMN lims.lab_result.dilution_factor IS '[v4: LAB-RES-001..014, LAB-INT-007, LAB-SEC-002/004 (Result entity)]';
COMMENT ON COLUMN lims.lab_result.method IS '[v4: LAB-RES-001..014, LAB-INT-007, LAB-SEC-002/004 (Result entity)]';
COMMENT ON COLUMN lims.lab_result.is_auto_verified IS '[v4: LAB-RES-001..014, LAB-INT-007, LAB-SEC-002/004 (Result entity)]';
COMMENT ON COLUMN lims.lab_result.autoverify_rule_id IS '[v4: LAB-RES-001..014, LAB-INT-007, LAB-SEC-002/004 (Result entity)]';
COMMENT ON COLUMN lims.lab_result.tech_verified_by IS '[v4: LAB-RES-001..014, LAB-INT-007, LAB-SEC-002/004 (Result entity)]';
COMMENT ON COLUMN lims.lab_result.tech_verified_at IS '[v4: LAB-RES-001..014, LAB-INT-007, LAB-SEC-002/004 (Result entity)]';
COMMENT ON COLUMN lims.lab_result.path_validated_by IS '[v4: LAB-RES-001..014, LAB-INT-007, LAB-SEC-002/004 (Result entity)]';
COMMENT ON COLUMN lims.lab_result.path_validated_at IS '[v4: LAB-RES-001..014, LAB-INT-007, LAB-SEC-002/004 (Result entity)]';
COMMENT ON COLUMN lims.lab_result.delta_ack_by IS '[v4: LAB-RES-001..014, LAB-INT-007, LAB-SEC-002/004 (Result entity)]';
COMMENT ON COLUMN lims.lab_result.delta_ack_at IS '[v4: LAB-RES-001..014, LAB-INT-007, LAB-SEC-002/004 (Result entity)]';
COMMENT ON COLUMN lims.lab_result.delta_ack_comment IS '[v4: LAB-RES-001..014, LAB-INT-007, LAB-SEC-002/004 (Result entity)]';
COMMENT ON COLUMN lims.lab_result.released_at IS '[v4: LAB-RES-001..014, LAB-INT-007, LAB-SEC-002/004 (Result entity)]';
COMMENT ON COLUMN lims.lab_result.lab_report_id IS '[v4: LAB-RES-001..014, LAB-INT-007, LAB-SEC-002/004 (Result entity)]';
COMMENT ON COLUMN lims.lab_result.is_outsourced_result IS '[v4: LAB-RES-001..014, LAB-INT-007, LAB-SEC-002/004 (Result entity)]';

-- lims.lab_sample  (25 new columns)  FDS: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS accession_no VARCHAR(30) NULL;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS collecting_branch_id INT NULL;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS collection_location_type VARCHAR(20) NULL;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS camp_id BIGINT NULL;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS b2b_payer_id INT NULL;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS online_order_id BIGINT NULL;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS field_task_id BIGINT NULL;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS is_stat BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS label_print_count SMALLINT NULL DEFAULT 0;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS preparation_confirmed BOOLEAN NULL;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS preparation_notes VARCHAR(300) NULL;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS timed_group_ref VARCHAR(30) NULL;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS timed_sequence_no SMALLINT NULL;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS scheduled_collection_at TIMESTAMPTZ(0) NULL;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS is_partial_collection BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS partial_reason VARCHAR(300) NULL;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS transport_batch_id BIGINT NULL;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS storage_rack VARCHAR(30) NULL;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS storage_position VARCHAR(30) NULL;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS disposed_by BIGINT NULL;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS transit_deadline_at TIMESTAMPTZ(0) NULL;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS is_medico_legal BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS custody_form_document_id BIGINT NULL;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS collection_consent_id BIGINT NULL;
ALTER TABLE lims.lab_sample ADD COLUMN IF NOT EXISTS condition_on_receipt VARCHAR(20) NULL;
COMMENT ON COLUMN lims.lab_sample.accession_no IS '[v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.collecting_branch_id IS '[v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.collection_location_type IS 'CENTRE, WARD, HOME, CAMP, B2B [v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.camp_id IS 'patientengagement.camp_camp [v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.b2b_payer_id IS 'revenuefinance.mst_payer (B2B client) [v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.online_order_id IS 'patientengagement.ecom_online_order [v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.field_task_id IS 'operationssupply.fld_task [v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.is_stat IS '[v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.label_print_count IS '[v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.preparation_confirmed IS '[v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.preparation_notes IS '[v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.timed_group_ref IS 'links serial samples (GTT) [v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.timed_sequence_no IS '[v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.scheduled_collection_at IS '[v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.is_partial_collection IS '[v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.partial_reason IS '[v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.transport_batch_id IS '[v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.storage_rack IS '[v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.storage_position IS '[v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.disposed_by IS '[v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.transit_deadline_at IS '[v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.is_medico_legal IS '[v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.custody_form_document_id IS '[v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.collection_consent_id IS 'patientengagement.pat_consent [v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';
COMMENT ON COLUMN lims.lab_sample.condition_on_receipt IS 'INTACT, LEAKED, HAEMOLYSED, INSUFFICIENT, CLOTTED [v4: LAB-MLM-001, LAB-BAR-*, LAB-COL-001..008, LAB-TRK-*, LAB-SEC-003 (Sample entity)]';

-- lims.lab_sample_custody_event  (5 new columns)  FDS: LAB-TRK-001, LAB-TRK-008/009
ALTER TABLE lims.lab_sample_custody_event ADD COLUMN IF NOT EXISTS transport_batch_id BIGINT NULL;
ALTER TABLE lims.lab_sample_custody_event ADD COLUMN IF NOT EXISTS from_branch_id INT NULL;
ALTER TABLE lims.lab_sample_custody_event ADD COLUMN IF NOT EXISTS to_branch_id INT NULL;
ALTER TABLE lims.lab_sample_custody_event ADD COLUMN IF NOT EXISTS is_excursion BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE lims.lab_sample_custody_event ADD COLUMN IF NOT EXISTS remarks VARCHAR(300) NULL;
COMMENT ON COLUMN lims.lab_sample_custody_event.transport_batch_id IS '[v4: LAB-TRK-001, LAB-TRK-008/009]';
COMMENT ON COLUMN lims.lab_sample_custody_event.from_branch_id IS '[v4: LAB-TRK-001, LAB-TRK-008/009]';
COMMENT ON COLUMN lims.lab_sample_custody_event.to_branch_id IS '[v4: LAB-TRK-001, LAB-TRK-008/009]';
COMMENT ON COLUMN lims.lab_sample_custody_event.is_excursion IS '[v4: LAB-TRK-001, LAB-TRK-008/009]';
COMMENT ON COLUMN lims.lab_sample_custody_event.remarks IS '[v4: LAB-TRK-001, LAB-TRK-008/009]';

-- lims.lab_worklist  (4 new columns)  FDS: LAB-WKL-001..006
ALTER TABLE lims.lab_worklist ADD COLUMN IF NOT EXISTS worklist_no VARCHAR(30) NULL;
ALTER TABLE lims.lab_worklist ADD COLUMN IF NOT EXISTS worklist_type VARCHAR(10) NULL DEFAULT 'ANALYZER';
ALTER TABLE lims.lab_worklist ADD COLUMN IF NOT EXISTS closed_at TIMESTAMPTZ(0) NULL;
ALTER TABLE lims.lab_worklist ADD COLUMN IF NOT EXISTS closed_by BIGINT NULL;
COMMENT ON COLUMN lims.lab_worklist.worklist_no IS '[v4: LAB-WKL-001..006]';
COMMENT ON COLUMN lims.lab_worklist.worklist_type IS 'ANALYZER, MANUAL [v4: LAB-WKL-001..006]';
COMMENT ON COLUMN lims.lab_worklist.closed_at IS '[v4: LAB-WKL-001..006]';
COMMENT ON COLUMN lims.lab_worklist.closed_by IS '[v4: LAB-WKL-001..006]';

-- lims.lab_worklist_item  (4 new columns)  FDS: LAB-WKL-002..004
ALTER TABLE lims.lab_worklist_item ADD COLUMN IF NOT EXISTS rack_no VARCHAR(20) NULL;
ALTER TABLE lims.lab_worklist_item ADD COLUMN IF NOT EXISTS sort_seq INT NULL;
ALTER TABLE lims.lab_worklist_item ADD COLUMN IF NOT EXISTS is_stat BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE lims.lab_worklist_item ADD COLUMN IF NOT EXISTS item_status VARCHAR(20) NULL DEFAULT 'PENDING';
COMMENT ON COLUMN lims.lab_worklist_item.rack_no IS '[v4: LAB-WKL-002..004]';
COMMENT ON COLUMN lims.lab_worklist_item.sort_seq IS '[v4: LAB-WKL-002..004]';
COMMENT ON COLUMN lims.lab_worklist_item.is_stat IS '[v4: LAB-WKL-002..004]';
COMMENT ON COLUMN lims.lab_worklist_item.item_status IS 'PENDING, SENT, RESULTED, RERUN, RESCHEDULED [v4: LAB-WKL-002..004]';

-- lims.mst_lab_parameter  (8 new columns)  FDS: LAB-CAT-004/005, LAB-RES-005 (Lab parameter entity)
ALTER TABLE lims.mst_lab_parameter ADD COLUMN IF NOT EXISTS is_calculated BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE lims.mst_lab_parameter ADD COLUMN IF NOT EXISTS min_valid_value DECIMAL(14,4) NULL;
ALTER TABLE lims.mst_lab_parameter ADD COLUMN IF NOT EXISTS max_valid_value DECIMAL(14,4) NULL;
ALTER TABLE lims.mst_lab_parameter ADD COLUMN IF NOT EXISTS option_list_json JSONB NULL;
ALTER TABLE lims.mst_lab_parameter ADD COLUMN IF NOT EXISTS method VARCHAR(100) NULL;
ALTER TABLE lims.mst_lab_parameter ADD COLUMN IF NOT EXISTS is_reportable BOOLEAN NULL DEFAULT TRUE;
ALTER TABLE lims.mst_lab_parameter ADD COLUMN IF NOT EXISTS print_bold_if_abnormal BOOLEAN NULL DEFAULT TRUE;
ALTER TABLE lims.mst_lab_parameter ADD COLUMN IF NOT EXISTS default_comment VARCHAR(500) NULL;
COMMENT ON COLUMN lims.mst_lab_parameter.is_calculated IS '[v4: LAB-CAT-004/005, LAB-RES-005 (Lab parameter entity)]';
COMMENT ON COLUMN lims.mst_lab_parameter.min_valid_value IS 'plausibility (reject impossible values) [v4: LAB-CAT-004/005, LAB-RES-005 (Lab parameter entity)]';
COMMENT ON COLUMN lims.mst_lab_parameter.max_valid_value IS '[v4: LAB-CAT-004/005, LAB-RES-005 (Lab parameter entity)]';
COMMENT ON COLUMN lims.mst_lab_parameter.option_list_json IS '[v4: LAB-CAT-004/005, LAB-RES-005 (Lab parameter entity)]';
COMMENT ON COLUMN lims.mst_lab_parameter.method IS '[v4: LAB-CAT-004/005, LAB-RES-005 (Lab parameter entity)]';
COMMENT ON COLUMN lims.mst_lab_parameter.is_reportable IS '[v4: LAB-CAT-004/005, LAB-RES-005 (Lab parameter entity)]';
COMMENT ON COLUMN lims.mst_lab_parameter.print_bold_if_abnormal IS '[v4: LAB-CAT-004/005, LAB-RES-005 (Lab parameter entity)]';
COMMENT ON COLUMN lims.mst_lab_parameter.default_comment IS '[v4: LAB-CAT-004/005, LAB-RES-005 (Lab parameter entity)]';

-- lims.mst_lab_reference_range  (6 new columns)  FDS: LAB-CAT-006 (Reference range entity)
ALTER TABLE lims.mst_lab_reference_range ADD COLUMN IF NOT EXISTS is_pregnancy_range BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE lims.mst_lab_reference_range ADD COLUMN IF NOT EXISTS method VARCHAR(100) NULL;
ALTER TABLE lims.mst_lab_reference_range ADD COLUMN IF NOT EXISTS analyzer_id INT NULL;
ALTER TABLE lims.mst_lab_reference_range ADD COLUMN IF NOT EXISTS unit VARCHAR(20) NULL;
ALTER TABLE lims.mst_lab_reference_range ADD COLUMN IF NOT EXISTS effective_from DATE NULL;
ALTER TABLE lims.mst_lab_reference_range ADD COLUMN IF NOT EXISTS effective_to DATE NULL;
COMMENT ON COLUMN lims.mst_lab_reference_range.is_pregnancy_range IS '[v4: LAB-CAT-006 (Reference range entity)]';
COMMENT ON COLUMN lims.mst_lab_reference_range.method IS '[v4: LAB-CAT-006 (Reference range entity)]';
COMMENT ON COLUMN lims.mst_lab_reference_range.analyzer_id IS '[v4: LAB-CAT-006 (Reference range entity)]';
COMMENT ON COLUMN lims.mst_lab_reference_range.unit IS '[v4: LAB-CAT-006 (Reference range entity)]';
COMMENT ON COLUMN lims.mst_lab_reference_range.effective_from IS '[v4: LAB-CAT-006 (Reference range entity)]';
COMMENT ON COLUMN lims.mst_lab_reference_range.effective_to IS '[v4: LAB-CAT-006 (Reference range entity)]';

-- lims.mst_lab_test  (15 new columns)  FDS: LAB-CAT-001/002/007/008/009, LAB-SEC-001..008 (Lab test entity)
ALTER TABLE lims.mst_lab_test ADD COLUMN IF NOT EXISTS test_code VARCHAR(30) NULL;
ALTER TABLE lims.mst_lab_test ADD COLUMN IF NOT EXISTS specimen_type_id INT NULL;
ALTER TABLE lims.mst_lab_test ADD COLUMN IF NOT EXISTS container_id INT NULL;
ALTER TABLE lims.mst_lab_test ADD COLUMN IF NOT EXISTS min_volume_ml DECIMAL(6,2) NULL;
ALTER TABLE lims.mst_lab_test ADD COLUMN IF NOT EXISTS report_format VARCHAR(20) NULL DEFAULT 'TABULAR';
ALTER TABLE lims.mst_lab_test ADD COLUMN IF NOT EXISTS requires_consent BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE lims.mst_lab_test ADD COLUMN IF NOT EXISTS is_long_tat BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE lims.mst_lab_test ADD COLUMN IF NOT EXISTS gender_applicable VARCHAR(10) NULL;
ALTER TABLE lims.mst_lab_test ADD COLUMN IF NOT EXISTS is_timed_test BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE lims.mst_lab_test ADD COLUMN IF NOT EXISTS timed_sample_count SMALLINT NULL;
ALTER TABLE lims.mst_lab_test ADD COLUMN IF NOT EXISTS home_collection_allowed BOOLEAN NULL DEFAULT TRUE;
ALTER TABLE lims.mst_lab_test ADD COLUMN IF NOT EXISTS is_medico_legal_capable BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE lims.mst_lab_test ADD COLUMN IF NOT EXISTS collection_instructions VARCHAR(1000) NULL;
ALTER TABLE lims.mst_lab_test ADD COLUMN IF NOT EXISTS default_processing_branch_id INT NULL;
ALTER TABLE lims.mst_lab_test ADD COLUMN IF NOT EXISTS loinc_code_id BIGINT NULL;
COMMENT ON COLUMN lims.mst_lab_test.test_code IS '[v4: LAB-CAT-001/002/007/008/009, LAB-SEC-001..008 (Lab test entity)]';
COMMENT ON COLUMN lims.mst_lab_test.specimen_type_id IS '[v4: LAB-CAT-001/002/007/008/009, LAB-SEC-001..008 (Lab test entity)]';
COMMENT ON COLUMN lims.mst_lab_test.container_id IS '[v4: LAB-CAT-001/002/007/008/009, LAB-SEC-001..008 (Lab test entity)]';
COMMENT ON COLUMN lims.mst_lab_test.min_volume_ml IS '[v4: LAB-CAT-001/002/007/008/009, LAB-SEC-001..008 (Lab test entity)]';
COMMENT ON COLUMN lims.mst_lab_test.report_format IS 'TABULAR, NARRATIVE, CULTURE, HISTOPATH, VARIANT [v4: LAB-CAT-001/002/007/008/009, LAB-SEC-001..008 (Lab test entity)]';
COMMENT ON COLUMN lims.mst_lab_test.requires_consent IS 'genetics / HIV [v4: LAB-CAT-001/002/007/008/009, LAB-SEC-001..008 (Lab test entity)]';
COMMENT ON COLUMN lims.mst_lab_test.is_long_tat IS '[v4: LAB-CAT-001/002/007/008/009, LAB-SEC-001..008 (Lab test entity)]';
COMMENT ON COLUMN lims.mst_lab_test.gender_applicable IS '[v4: LAB-CAT-001/002/007/008/009, LAB-SEC-001..008 (Lab test entity)]';
COMMENT ON COLUMN lims.mst_lab_test.is_timed_test IS 'GTT, PP [v4: LAB-CAT-001/002/007/008/009, LAB-SEC-001..008 (Lab test entity)]';
COMMENT ON COLUMN lims.mst_lab_test.timed_sample_count IS '[v4: LAB-CAT-001/002/007/008/009, LAB-SEC-001..008 (Lab test entity)]';
COMMENT ON COLUMN lims.mst_lab_test.home_collection_allowed IS '[v4: LAB-CAT-001/002/007/008/009, LAB-SEC-001..008 (Lab test entity)]';
COMMENT ON COLUMN lims.mst_lab_test.is_medico_legal_capable IS '[v4: LAB-CAT-001/002/007/008/009, LAB-SEC-001..008 (Lab test entity)]';
COMMENT ON COLUMN lims.mst_lab_test.collection_instructions IS '[v4: LAB-CAT-001/002/007/008/009, LAB-SEC-001..008 (Lab test entity)]';
COMMENT ON COLUMN lims.mst_lab_test.default_processing_branch_id IS '[v4: LAB-CAT-001/002/007/008/009, LAB-SEC-001..008 (Lab test entity)]';
COMMENT ON COLUMN lims.mst_lab_test.loinc_code_id IS '[v4: LAB-CAT-001/002/007/008/009, LAB-SEC-001..008 (Lab test entity)]';

/* ---------- B. NEW TABLES ---------- */

-- ===== Diagnostics LIMS & RIMS FRD - Section 3 (LIMS) =====
-- [NEW v4] FDS ref: LAB-CAT-003
CREATE TABLE IF NOT EXISTS lims.mst_lab_specimen_type (                        -- Specimen types (blood, serum, plasma, urine, stool, CSF, tissue, swab ...)
    lab_specimen_type_id       INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    specimen_code              VARCHAR(20) NOT NULL UNIQUE,
    specimen_name              VARCHAR(100) NOT NULL,
    snomed_code_id             BIGINT NULL,                                    -- logical FK -> identityorg.core_clinical_code [Identity & Organization]
    stability_hours_ambient    SMALLINT NULL,
    stability_hours_refrigerated SMALLINT NULL,
    retention_days             SMALLINT NULL,                                  -- sample retention before disposal
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-CAT-003, LAB-BAR-001, PHA-002
CREATE TABLE IF NOT EXISTS lims.mst_lab_container (                            -- Container / tube types with cap colour, additive and volume
    lab_container_id           INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    container_code             VARCHAR(20) NOT NULL UNIQUE,
    container_name             VARCHAR(100) NOT NULL,
    cap_colour                 VARCHAR(20) NULL,
    additive                   VARCHAR(50) NULL,                               -- EDTA, FLUORIDE, CITRATE, SST, HEPARIN, PLAIN
    volume_ml                  DECIMAL(6,2) NULL,
    item_id                    INT NULL,                                       -- consumable for stock deduction | logical FK -> operationssupply.mst_item [Operations & Supply Chain]
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-MLM-002
CREATE TABLE IF NOT EXISTS lims.mst_lab_test_routing (                         -- Which tests are processed at which branch (collecting branch -> processing branch)
    lab_test_routing_id        INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    lab_test_id                INT NOT NULL,
    collecting_branch_id       INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    processing_branch_id       INT NOT NULL,                                   -- logical FK -> identityorg.core_branch [Identity & Organization]
    is_outsourced              BOOLEAN NOT NULL DEFAULT FALSE,
    outsource_vendor_id        INT NULL,                                       -- logical FK -> operationssupply.mst_vendor [Operations & Supply Chain]
    priority_order             SMALLINT NOT NULL DEFAULT 1,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-RES-003, LAB-SEC-005, LAB-SEC-007
CREATE TABLE IF NOT EXISTS lims.mst_lab_comment_template (                     -- Standard comments and narrative result templates
    lab_comment_template_id    INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    lab_test_id                INT NULL,
    template_type              VARCHAR(20) NOT NULL,                           -- COMMENT, NARRATIVE_TEMPLATE, INTERPRETATION
    template_code              VARCHAR(30) NOT NULL,
    template_text              TEXT NOT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-CAT-010, RAD-MST-007
CREATE TABLE IF NOT EXISTS lims.lab_master_change_log (                        -- Audit of changes to tests, parameters, ranges (user, reason, old / new)
    master_change_log_id       BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    entity_type                VARCHAR(30) NOT NULL,                           -- LAB_TEST, LAB_PARAMETER, REFERENCE_RANGE, REFLEX_RULE, AUTOVERIFY_RULE
    entity_id                  BIGINT NOT NULL,
    change_reason              VARCHAR(500) NOT NULL,
    old_values_json            JSONB NULL,
    new_values_json            JSONB NULL,
    changed_by                 BIGINT NOT NULL,
    changed_at                 TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-TRK-002, LAB-MLM-005, PCS-007, PLB-001..006 (Sample / bag entity)
CREATE TABLE IF NOT EXISTS lims.lab_transport_batch (                          -- Transport box / sealed bag for home collection, inter-branch transfer and B2B pick-up
    transport_batch_id         BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    batch_no                   VARCHAR(30) NOT NULL UNIQUE,                    -- bag ID / box ID
    batch_type                 VARCHAR(20) NOT NULL,                           -- HOME_BAG, INTER_BRANCH_BOX, B2B_PICKUP, OUTSOURCE
    from_branch_id             INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    to_branch_id               INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    field_task_id              BIGINT NULL,                                    -- logical FK -> operationssupply.fld_task [Operations & Supply Chain]
    trip_id                    BIGINT NULL,                                    -- logical FK -> operationssupply.fld_trip [Operations & Supply Chain]
    transport_condition        VARCHAR(20) NULL,                               -- AMBIENT, COOL_BOX, FROZEN
    logger_id                  VARCHAR(50) NULL,
    sealed_at                  TIMESTAMPTZ(0) NULL,
    sealed_by                  BIGINT NULL,
    dispatched_at              TIMESTAMPTZ(0) NULL,
    received_at                TIMESTAMPTZ(0) NULL,
    received_by                BIGINT NULL,
    receipt_code               VARCHAR(10) NULL,                               -- lab receipt code given to phlebo (PLB-005)
    expected_count             SMALLINT NULL,
    received_count             SMALLINT NULL,
    discrepancy_json           JSONB NULL,                                     -- missing / unexpected barcodes
    batch_status               VARCHAR(20) NOT NULL DEFAULT 'OPEN',            -- OPEN, SEALED, IN_TRANSIT, RECEIVED, RECEIVED_WITH_DISCREPANCY
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-BAR-002, LAB-BAR-003, LAB-MIS-006
CREATE TABLE IF NOT EXISTS lims.lab_label_print_log (                          -- Barcode label print / re-print log with reason
    label_print_log_id         BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    sample_id                  BIGINT NOT NULL,
    print_type                 VARCHAR(10) NOT NULL,                           -- ORIGINAL, REPRINT
    reason                     VARCHAR(300) NULL,
    printed_by                 BIGINT NOT NULL,
    printed_at                 TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    printer_name               VARCHAR(100) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-TRK-005, PLP-003
CREATE TABLE IF NOT EXISTS lims.lab_recollection_request (                     -- Re-collection requests raised on sample rejection / partial collection
    recollection_request_id    BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    original_sample_id         BIGINT NOT NULL,
    new_sample_id              BIGINT NULL,
    reason                     VARCHAR(300) NOT NULL,
    requested_by               BIGINT NOT NULL,
    requested_at               TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notified_to                VARCHAR(200) NULL,
    home_visit_required        BOOLEAN NOT NULL DEFAULT FALSE,
    field_task_id              BIGINT NULL,                                    -- logical FK -> operationssupply.fld_task [Operations & Supply Chain]
    request_status             VARCHAR(20) NOT NULL DEFAULT 'OPEN',            -- OPEN, SCHEDULED, COLLECTED, CANCELLED
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-INT-003, LAB-INT-004
CREATE TABLE IF NOT EXISTS lims.lab_analyzer_message_log (                     -- Every message sent to / received from analyzers
    analyzer_message_log_id    BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    analyzer_id                INT NOT NULL,
    direction                  VARCHAR(5) NOT NULL,                            -- IN, OUT
    message_type               VARCHAR(20) NOT NULL,                           -- QUERY, ORDER, RESULT, ACK, QC, ERROR
    sample_barcode             VARCHAR(50) NULL,
    raw_message                TEXT NULL,
    parse_status               VARCHAR(20) NULL,
    logged_at                  TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-INT-006
CREATE TABLE IF NOT EXISTS lims.lab_result_exception (                         -- Unmatched / unknown-code analyzer results awaiting manual resolution
    result_exception_id        BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    analyzer_id                INT NOT NULL,
    analyzer_message_log_id    BIGINT NULL,
    sample_barcode             VARCHAR(50) NULL,
    machine_test_code          VARCHAR(30) NULL,
    value_text                 VARCHAR(200) NULL,
    exception_type             VARCHAR(20) NOT NULL,                           -- NO_SAMPLE, UNKNOWN_CODE, NO_ORDER, DUPLICATE
    received_at                TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_result_id         BIGINT NULL,
    resolved_by                BIGINT NULL,
    resolved_at                TIMESTAMPTZ(0) NULL,
    exception_status           VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-SEC-004, LAB-SEC-001
CREATE TABLE IF NOT EXISTS lims.lab_result_attachment (                        -- Result images / attachments (histogram, scattergram, gel images, microscopy)
    result_attachment_id       BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    result_id                  BIGINT NOT NULL,
    attachment_type            VARCHAR(20) NOT NULL,                           -- HISTOGRAM, SCATTERGRAM, MICROSCOPY, GEL, OTHER
    document_id                BIGINT NULL,                                    -- logical FK -> integrationcomms.core_document [Integration & Communications]
    caption                    VARCHAR(200) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-RES-008
CREATE TABLE IF NOT EXISTS lims.lab_autoverify_rule (                          -- Auto-verification rules per parameter
    autoverify_rule_id         INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    lab_parameter_id           INT NOT NULL,
    rule_name                  VARCHAR(100) NOT NULL,
    range_low                  DECIMAL(14,4) NULL,
    range_high                 DECIMAL(14,4) NULL,
    max_delta_pct              DECIMAL(6,2) NULL,
    block_on_flags             VARCHAR(200) NULL,
    require_qc_pass            BOOLEAN NOT NULL DEFAULT TRUE,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-QC-001..003
CREATE TABLE IF NOT EXISTS lims.lab_qc_lot (                                   -- QC control material lots with level, expiry and target mean / SD per parameter
    qc_lot_id                  INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    lot_no                     VARCHAR(50) NOT NULL,
    qc_material                VARCHAR(100) NOT NULL,
    qc_level                   VARCHAR(10) NOT NULL,
    manufacturer               VARCHAR(100) NULL,
    expiry_date                DATE NOT NULL,
    analyzer_id                INT NULL,
    lab_parameter_id           INT NOT NULL,
    target_mean                DECIMAL(14,4) NOT NULL,
    target_sd                  DECIMAL(14,4) NOT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-QC-007, LAB-QC-008
CREATE TABLE IF NOT EXISTS lims.lab_eqas_result (                              -- External quality assessment / proficiency testing results
    eqas_result_id             BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    eqas_programme             VARCHAR(100) NOT NULL,
    cycle_ref                  VARCHAR(50) NOT NULL,
    lab_parameter_id           INT NOT NULL,
    analyzer_id                INT NULL,
    reported_value             DECIMAL(14,4) NULL,
    target_value               DECIMAL(14,4) NULL,
    sdi                        DECIMAL(6,2) NULL,
    performance                VARCHAR(20) NULL,                               -- ACCEPTABLE, WARNING, UNACCEPTABLE
    corrective_action          VARCHAR(1000) NULL,
    reported_at                TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-OUT-001..002
CREATE TABLE IF NOT EXISTS lims.lab_outsource_manifest (                       -- Outsource dispatch manifest (vendor, transport, samples)
    outsource_manifest_id      BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    manifest_no                VARCHAR(30) NOT NULL UNIQUE,
    vendor_id                  INT NOT NULL,                                   -- logical FK -> operationssupply.mst_vendor [Operations & Supply Chain]
    transport_batch_id         BIGINT NULL,
    courier_name               VARCHAR(100) NULL,
    dispatched_at              TIMESTAMPTZ(0) NULL,
    dispatched_by              BIGINT NULL,
    sample_count               SMALLINT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-MIC-002, LAB-MIC-003, LAB-MIC-006
CREATE TABLE IF NOT EXISTS lims.mst_lab_antibiotic_panel (                     -- Antibiotic panels per organism group with cascade (selective) reporting tiers
    lab_antibiotic_panel_id    INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    organism_group             VARCHAR(50) NOT NULL,
    generic_id                 INT NOT NULL,                                   -- logical FK -> pharmacy.mst_generic [Pharmacy]
    tier_no                    SMALLINT NOT NULL DEFAULT 1,
    report_if_resistant_tier   SMALLINT NULL,
    breakpoint_standard        VARCHAR(20) NULL,                               -- CLSI, EUCAST
    display_order              SMALLINT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-SEC-005, LAB-SEC-007
CREATE TABLE IF NOT EXISTS lims.lab_histo_case (                               -- Histopathology / cytology case with gross description
    histo_case_id              BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    case_no                    VARCHAR(30) NOT NULL UNIQUE,
    sample_id                  BIGINT NOT NULL,
    order_item_id              BIGINT NULL,                                    -- logical FK -> clinicalcare.ord_order_item [Clinical Care]
    specimen_description       VARCHAR(500) NULL,
    gross_description          TEXT NULL,
    microscopic_description    TEXT NULL,
    diagnosis_text             TEXT NULL,
    synoptic_json              JSONB NULL,
    grossed_by                 BIGINT NULL,
    reported_by                BIGINT NULL,
    case_status                VARCHAR(20) NOT NULL DEFAULT 'RECEIVED',        -- RECEIVED, GROSSED, PROCESSING, SLIDES_READY, REPORTED
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-SEC-007
CREATE TABLE IF NOT EXISTS lims.lab_histo_block (                              -- Tissue blocks of a histopathology case
    histo_block_id             BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    histo_case_id              BIGINT NOT NULL,
    block_no                   VARCHAR(20) NOT NULL,
    tissue_description         VARCHAR(300) NULL,
    storage_location           VARCHAR(100) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-SEC-007
CREATE TABLE IF NOT EXISTS lims.lab_histo_slide (                              -- Slides (H&E, special stains, IHC) cut from blocks
    histo_slide_id             BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    histo_block_id             BIGINT NOT NULL,
    slide_no                   VARCHAR(20) NOT NULL,
    stain                      VARCHAR(50) NULL,
    prepared_at                TIMESTAMPTZ(0) NULL,
    storage_location           VARCHAR(100) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-BB-011
CREATE TABLE IF NOT EXISTS lims.bb_component_preparation (                     -- Component separation runs (PRBC, FFP, platelets RDP/SDP, cryo)
    component_preparation_id   BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    source_blood_unit_id       BIGINT NOT NULL,
    prepared_at                TIMESTAMPTZ(0) NOT NULL,
    prepared_by                BIGINT NULL,
    centrifuge_program         VARCHAR(50) NULL,
    components_json            JSONB NULL,                                     -- produced unit ids / types
    remarks                    VARCHAR(300) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-BB-008
CREATE TABLE IF NOT EXISTS lims.bb_patient_grouping (                          -- Patient blood grouping and antibody screen
    patient_grouping_id        BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    blood_request_id           BIGINT NULL,
    sample_id                  BIGINT NULL,
    abo_group                  VARCHAR(5) NOT NULL,
    rh_type                    VARCHAR(5) NOT NULL,
    antibody_screen            VARCHAR(20) NULL,
    method                     VARCHAR(30) NULL,
    performed_by               BIGINT NULL,
    performed_at               TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-BB-013
CREATE TABLE IF NOT EXISTS lims.bb_stock_level (                               -- Minimum stock level by blood group and component
    stock_level_id             INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    blood_group                VARCHAR(5) NOT NULL,
    component_type             VARCHAR(20) NOT NULL,
    min_units                  SMALLINT NOT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] replica of operationssupply.fld_trip, owned by Operations & Supply Chain; used by: lims.lab_transport_batch
CREATE TABLE IF NOT EXISTS lims.ref_transport_trip (
    trip_id                    BIGINT PRIMARY KEY,
    vehicle_id                 INT NULL,
    service_request_id         BIGINT NULL,
    driver_employee_id         BIGINT NULL,
    crew_json                  JSONB NULL,
    dispatched_at              TIMESTAMPTZ(0) NULL,
    reached_pickup_at          TIMESTAMPTZ(0) NULL,
    departed_pickup_at         TIMESTAMPTZ(0) NULL,
    reached_drop_at            TIMESTAMPTZ(0) NULL,
    start_odometer_km          DECIMAL(10,1) NULL,
    end_odometer_km            DECIMAL(10,1) NULL,
    trip_status                VARCHAR(20) NULL,
    is_active                  BOOLEAN NULL,
    agent_id                   BIGINT NULL,
    route_json                 JSONB NULL,
    planned_distance_km        DECIMAL(8,2) NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    source_version             BIGINT NULL,                                    -- version / sequence from publisher (ignore stale events)
    replicated_at              TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);


/* ---------- C. FOREIGN KEYS (same service only) ---------- */
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_mst_lab_test_routing_lab_test_id') THEN
        ALTER TABLE lims.mst_lab_test_routing ADD CONSTRAINT fk_mst_lab_test_routing_lab_test_id FOREIGN KEY (lab_test_id) REFERENCES lims.mst_lab_test(lab_test_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_mst_lab_comment_template_lab_test_id') THEN
        ALTER TABLE lims.mst_lab_comment_template ADD CONSTRAINT fk_mst_lab_comment_template_lab_test_id FOREIGN KEY (lab_test_id) REFERENCES lims.mst_lab_test(lab_test_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_label_print_log_sample_id') THEN
        ALTER TABLE lims.lab_label_print_log ADD CONSTRAINT fk_lab_label_print_log_sample_id FOREIGN KEY (sample_id) REFERENCES lims.lab_sample(sample_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_recollection_request_original_sample_id') THEN
        ALTER TABLE lims.lab_recollection_request ADD CONSTRAINT fk_lab_recollection_request_original_sample_id FOREIGN KEY (original_sample_id) REFERENCES lims.lab_sample(sample_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_recollection_request_new_sample_id') THEN
        ALTER TABLE lims.lab_recollection_request ADD CONSTRAINT fk_lab_recollection_request_new_sample_id FOREIGN KEY (new_sample_id) REFERENCES lims.lab_sample(sample_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_analyzer_message_log_analyzer_id') THEN
        ALTER TABLE lims.lab_analyzer_message_log ADD CONSTRAINT fk_lab_analyzer_message_log_analyzer_id FOREIGN KEY (analyzer_id) REFERENCES lims.lab_analyzer(analyzer_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_result_exception_analyzer_id') THEN
        ALTER TABLE lims.lab_result_exception ADD CONSTRAINT fk_lab_result_exception_analyzer_id FOREIGN KEY (analyzer_id) REFERENCES lims.lab_analyzer(analyzer_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_result_exception_analyzer_message_log_id') THEN
        ALTER TABLE lims.lab_result_exception ADD CONSTRAINT fk_lab_result_exception_analyzer_message_log_id FOREIGN KEY (analyzer_message_log_id) REFERENCES lims.lab_analyzer_message_log(analyzer_message_log_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_result_exception_resolved_result_id') THEN
        ALTER TABLE lims.lab_result_exception ADD CONSTRAINT fk_lab_result_exception_resolved_result_id FOREIGN KEY (resolved_result_id) REFERENCES lims.lab_result(result_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_result_attachment_result_id') THEN
        ALTER TABLE lims.lab_result_attachment ADD CONSTRAINT fk_lab_result_attachment_result_id FOREIGN KEY (result_id) REFERENCES lims.lab_result(result_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_autoverify_rule_lab_parameter_id') THEN
        ALTER TABLE lims.lab_autoverify_rule ADD CONSTRAINT fk_lab_autoverify_rule_lab_parameter_id FOREIGN KEY (lab_parameter_id) REFERENCES lims.mst_lab_parameter(lab_parameter_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_qc_lot_analyzer_id') THEN
        ALTER TABLE lims.lab_qc_lot ADD CONSTRAINT fk_lab_qc_lot_analyzer_id FOREIGN KEY (analyzer_id) REFERENCES lims.lab_analyzer(analyzer_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_qc_lot_lab_parameter_id') THEN
        ALTER TABLE lims.lab_qc_lot ADD CONSTRAINT fk_lab_qc_lot_lab_parameter_id FOREIGN KEY (lab_parameter_id) REFERENCES lims.mst_lab_parameter(lab_parameter_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_eqas_result_lab_parameter_id') THEN
        ALTER TABLE lims.lab_eqas_result ADD CONSTRAINT fk_lab_eqas_result_lab_parameter_id FOREIGN KEY (lab_parameter_id) REFERENCES lims.mst_lab_parameter(lab_parameter_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_eqas_result_analyzer_id') THEN
        ALTER TABLE lims.lab_eqas_result ADD CONSTRAINT fk_lab_eqas_result_analyzer_id FOREIGN KEY (analyzer_id) REFERENCES lims.lab_analyzer(analyzer_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_outsource_manifest_transport_batch_id') THEN
        ALTER TABLE lims.lab_outsource_manifest ADD CONSTRAINT fk_lab_outsource_manifest_transport_batch_id FOREIGN KEY (transport_batch_id) REFERENCES lims.lab_transport_batch(transport_batch_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_histo_case_sample_id') THEN
        ALTER TABLE lims.lab_histo_case ADD CONSTRAINT fk_lab_histo_case_sample_id FOREIGN KEY (sample_id) REFERENCES lims.lab_sample(sample_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_histo_block_histo_case_id') THEN
        ALTER TABLE lims.lab_histo_block ADD CONSTRAINT fk_lab_histo_block_histo_case_id FOREIGN KEY (histo_case_id) REFERENCES lims.lab_histo_case(histo_case_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_histo_slide_histo_block_id') THEN
        ALTER TABLE lims.lab_histo_slide ADD CONSTRAINT fk_lab_histo_slide_histo_block_id FOREIGN KEY (histo_block_id) REFERENCES lims.lab_histo_block(histo_block_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_bb_component_preparation_source_blood_unit_id') THEN
        ALTER TABLE lims.bb_component_preparation ADD CONSTRAINT fk_bb_component_preparation_source_blood_unit_id FOREIGN KEY (source_blood_unit_id) REFERENCES lims.bb_blood_unit(blood_unit_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_bb_patient_grouping_blood_request_id') THEN
        ALTER TABLE lims.bb_patient_grouping ADD CONSTRAINT fk_bb_patient_grouping_blood_request_id FOREIGN KEY (blood_request_id) REFERENCES lims.bb_blood_request(blood_request_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_bb_patient_grouping_sample_id') THEN
        ALTER TABLE lims.bb_patient_grouping ADD CONSTRAINT fk_bb_patient_grouping_sample_id FOREIGN KEY (sample_id) REFERENCES lims.lab_sample(sample_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_bb_blood_unit_parent_blood_unit_id') THEN
        ALTER TABLE lims.bb_blood_unit ADD CONSTRAINT fk_bb_blood_unit_parent_blood_unit_id FOREIGN KEY (parent_blood_unit_id) REFERENCES lims.bb_blood_unit(blood_unit_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bb_blood_unit_parent_blood_unit_id ON lims.bb_blood_unit(parent_blood_unit_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_bb_blood_unit_reserved_for_request_id') THEN
        ALTER TABLE lims.bb_blood_unit ADD CONSTRAINT fk_bb_blood_unit_reserved_for_request_id FOREIGN KEY (reserved_for_request_id) REFERENCES lims.bb_blood_request(blood_request_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bb_blood_unit_reserved_for_request_id ON lims.bb_blood_unit(reserved_for_request_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_calibration_log_corrects_calibration_log_id') THEN
        ALTER TABLE lims.lab_calibration_log ADD CONSTRAINT fk_lab_calibration_log_corrects_calibration_log_id FOREIGN KEY (corrects_calibration_log_id) REFERENCES lims.lab_calibration_log(calibration_log_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_lab_calibration_log_corrects_calibration_log_id ON lims.lab_calibration_log(corrects_calibration_log_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_outsource_dispatch_outsource_manifest_id') THEN
        ALTER TABLE lims.lab_outsource_dispatch ADD CONSTRAINT fk_lab_outsource_dispatch_outsource_manifest_id FOREIGN KEY (outsource_manifest_id) REFERENCES lims.lab_outsource_manifest(outsource_manifest_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_lab_outsource_dispatch_outsource_manifest_id ON lims.lab_outsource_dispatch(outsource_manifest_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_qc_run_qc_lot_id') THEN
        ALTER TABLE lims.lab_qc_run ADD CONSTRAINT fk_lab_qc_run_qc_lot_id FOREIGN KEY (qc_lot_id) REFERENCES lims.lab_qc_lot(qc_lot_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_lab_qc_run_qc_lot_id ON lims.lab_qc_run(qc_lot_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_qc_run_corrects_qc_run_id') THEN
        ALTER TABLE lims.lab_qc_run ADD CONSTRAINT fk_lab_qc_run_corrects_qc_run_id FOREIGN KEY (corrects_qc_run_id) REFERENCES lims.lab_qc_run(qc_run_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_lab_qc_run_corrects_qc_run_id ON lims.lab_qc_run(corrects_qc_run_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_result_autoverify_rule_id') THEN
        ALTER TABLE lims.lab_result ADD CONSTRAINT fk_lab_result_autoverify_rule_id FOREIGN KEY (autoverify_rule_id) REFERENCES lims.lab_autoverify_rule(autoverify_rule_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_lab_result_autoverify_rule_id ON lims.lab_result(autoverify_rule_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_result_lab_report_id') THEN
        ALTER TABLE lims.lab_result ADD CONSTRAINT fk_lab_result_lab_report_id FOREIGN KEY (lab_report_id) REFERENCES lims.lab_report(lab_report_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_lab_result_lab_report_id ON lims.lab_result(lab_report_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_sample_transport_batch_id') THEN
        ALTER TABLE lims.lab_sample ADD CONSTRAINT fk_lab_sample_transport_batch_id FOREIGN KEY (transport_batch_id) REFERENCES lims.lab_transport_batch(transport_batch_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_lab_sample_transport_batch_id ON lims.lab_sample(transport_batch_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_lab_sample_custody_event_transport_batch_id') THEN
        ALTER TABLE lims.lab_sample_custody_event ADD CONSTRAINT fk_lab_sample_custody_event_transport_batch_id FOREIGN KEY (transport_batch_id) REFERENCES lims.lab_transport_batch(transport_batch_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_lab_sample_custody_event_transport_batch_id ON lims.lab_sample_custody_event(transport_batch_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_mst_lab_reference_range_analyzer_id') THEN
        ALTER TABLE lims.mst_lab_reference_range ADD CONSTRAINT fk_mst_lab_reference_range_analyzer_id FOREIGN KEY (analyzer_id) REFERENCES lims.lab_analyzer(analyzer_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_mst_lab_reference_range_analyzer_id ON lims.mst_lab_reference_range(analyzer_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_mst_lab_test_specimen_type_id') THEN
        ALTER TABLE lims.mst_lab_test ADD CONSTRAINT fk_mst_lab_test_specimen_type_id FOREIGN KEY (specimen_type_id) REFERENCES lims.mst_lab_specimen_type(lab_specimen_type_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_mst_lab_test_specimen_type_id ON lims.mst_lab_test(specimen_type_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'lims' AND c.conname = 'fk_mst_lab_test_container_id') THEN
        ALTER TABLE lims.mst_lab_test ADD CONSTRAINT fk_mst_lab_test_container_id FOREIGN KEY (container_id) REFERENCES lims.mst_lab_container(lab_container_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_mst_lab_test_container_id ON lims.mst_lab_test(container_id);

/* ---------- D. INDEXES ---------- */
CREATE INDEX IF NOT EXISTS ix_mst_lab_test_routing_lab_test_id ON lims.mst_lab_test_routing(lab_test_id);
CREATE INDEX IF NOT EXISTS ix_mst_lab_comment_template_lab_test_id ON lims.mst_lab_comment_template(lab_test_id);
CREATE INDEX IF NOT EXISTS ix_lab_label_print_log_sample_id ON lims.lab_label_print_log(sample_id);
CREATE INDEX IF NOT EXISTS ix_lab_recollection_request_original_sample_id ON lims.lab_recollection_request(original_sample_id);
CREATE INDEX IF NOT EXISTS ix_lab_recollection_request_new_sample_id ON lims.lab_recollection_request(new_sample_id);
CREATE INDEX IF NOT EXISTS ix_lab_analyzer_message_log_analyzer_id ON lims.lab_analyzer_message_log(analyzer_id);
CREATE INDEX IF NOT EXISTS ix_lab_result_exception_analyzer_id ON lims.lab_result_exception(analyzer_id);
CREATE INDEX IF NOT EXISTS ix_lab_result_exception_analyzer_message_log_id ON lims.lab_result_exception(analyzer_message_log_id);
CREATE INDEX IF NOT EXISTS ix_lab_result_exception_resolved_result_id ON lims.lab_result_exception(resolved_result_id);
CREATE INDEX IF NOT EXISTS ix_lab_result_attachment_result_id ON lims.lab_result_attachment(result_id);
CREATE INDEX IF NOT EXISTS ix_lab_autoverify_rule_lab_parameter_id ON lims.lab_autoverify_rule(lab_parameter_id);
CREATE INDEX IF NOT EXISTS ix_lab_qc_lot_analyzer_id ON lims.lab_qc_lot(analyzer_id);
CREATE INDEX IF NOT EXISTS ix_lab_qc_lot_lab_parameter_id ON lims.lab_qc_lot(lab_parameter_id);
CREATE INDEX IF NOT EXISTS ix_lab_eqas_result_lab_parameter_id ON lims.lab_eqas_result(lab_parameter_id);
CREATE INDEX IF NOT EXISTS ix_lab_eqas_result_analyzer_id ON lims.lab_eqas_result(analyzer_id);
CREATE INDEX IF NOT EXISTS ix_lab_outsource_manifest_transport_batch_id ON lims.lab_outsource_manifest(transport_batch_id);
CREATE INDEX IF NOT EXISTS ix_lab_histo_case_sample_id ON lims.lab_histo_case(sample_id);
CREATE INDEX IF NOT EXISTS ix_lab_histo_case_order_item_id ON lims.lab_histo_case(order_item_id);
CREATE INDEX IF NOT EXISTS ix_lab_histo_block_histo_case_id ON lims.lab_histo_block(histo_case_id);
CREATE INDEX IF NOT EXISTS ix_lab_histo_slide_histo_block_id ON lims.lab_histo_slide(histo_block_id);
CREATE INDEX IF NOT EXISTS ix_bb_component_preparation_source_blood_unit_id ON lims.bb_component_preparation(source_blood_unit_id);
CREATE INDEX IF NOT EXISTS ix_bb_patient_grouping_patient_id ON lims.bb_patient_grouping(patient_id);
CREATE INDEX IF NOT EXISTS ix_bb_patient_grouping_blood_request_id ON lims.bb_patient_grouping(blood_request_id);
CREATE INDEX IF NOT EXISTS ix_bb_patient_grouping_sample_id ON lims.bb_patient_grouping(sample_id);

/* ---------- E. TABLE COMMENTS (FDS traceability) ---------- */
COMMENT ON TABLE lims.mst_lab_specimen_type IS 'Specimen types (blood, serum, plasma, urine, stool, CSF, tissue, swab ...) [FDS: LAB-CAT-003]';
COMMENT ON TABLE lims.mst_lab_container IS 'Container / tube types with cap colour, additive and volume [FDS: LAB-CAT-003, LAB-BAR-001, PHA-002]';
COMMENT ON TABLE lims.mst_lab_test_routing IS 'Which tests are processed at which branch (collecting branch -> processing branch) [FDS: LAB-MLM-002]';
COMMENT ON TABLE lims.mst_lab_comment_template IS 'Standard comments and narrative result templates [FDS: LAB-RES-003, LAB-SEC-005, LAB-SEC-007]';
COMMENT ON TABLE lims.lab_master_change_log IS 'Audit of changes to tests, parameters, ranges (user, reason, old / new) [FDS: LAB-CAT-010, RAD-MST-007]';
COMMENT ON TABLE lims.lab_transport_batch IS 'Transport box / sealed bag for home collection, inter-branch transfer and B2B pick-up [FDS: LAB-TRK-002, LAB-MLM-005, PCS-007, PLB-001..006 (Sample / bag entity)]';
COMMENT ON TABLE lims.lab_label_print_log IS 'Barcode label print / re-print log with reason [FDS: LAB-BAR-002, LAB-BAR-003, LAB-MIS-006]';
COMMENT ON TABLE lims.lab_recollection_request IS 'Re-collection requests raised on sample rejection / partial collection [FDS: LAB-TRK-005, PLP-003]';
COMMENT ON TABLE lims.lab_analyzer_message_log IS 'Every message sent to / received from analyzers [FDS: LAB-INT-003, LAB-INT-004]';
COMMENT ON TABLE lims.lab_result_exception IS 'Unmatched / unknown-code analyzer results awaiting manual resolution [FDS: LAB-INT-006]';
COMMENT ON TABLE lims.lab_result_attachment IS 'Result images / attachments (histogram, scattergram, gel images, microscopy) [FDS: LAB-SEC-004, LAB-SEC-001]';
COMMENT ON TABLE lims.lab_autoverify_rule IS 'Auto-verification rules per parameter [FDS: LAB-RES-008]';
COMMENT ON TABLE lims.lab_qc_lot IS 'QC control material lots with level, expiry and target mean / SD per parameter [FDS: LAB-QC-001..003]';
COMMENT ON TABLE lims.lab_eqas_result IS 'External quality assessment / proficiency testing results [FDS: LAB-QC-007, LAB-QC-008]';
COMMENT ON TABLE lims.lab_outsource_manifest IS 'Outsource dispatch manifest (vendor, transport, samples) [FDS: LAB-OUT-001..002]';
COMMENT ON TABLE lims.mst_lab_antibiotic_panel IS 'Antibiotic panels per organism group with cascade (selective) reporting tiers [FDS: LAB-MIC-002, LAB-MIC-003, LAB-MIC-006]';
COMMENT ON TABLE lims.lab_histo_case IS 'Histopathology / cytology case with gross description [FDS: LAB-SEC-005, LAB-SEC-007]';
COMMENT ON TABLE lims.lab_histo_block IS 'Tissue blocks of a histopathology case [FDS: LAB-SEC-007]';
COMMENT ON TABLE lims.lab_histo_slide IS 'Slides (H&E, special stains, IHC) cut from blocks [FDS: LAB-SEC-007]';
COMMENT ON TABLE lims.bb_component_preparation IS 'Component separation runs (PRBC, FFP, platelets RDP/SDP, cryo) [FDS: LAB-BB-011]';
COMMENT ON TABLE lims.bb_patient_grouping IS 'Patient blood grouping and antibody screen [FDS: LAB-BB-008]';
COMMENT ON TABLE lims.bb_stock_level IS 'Minimum stock level by blood group and component [FDS: LAB-BB-013]';

COMMIT;
