/* =====================================================================================
   DR REDDIS HEALTHCARE - HIMS  database_v3 (7 services)  ->  database_v4 (9 services)
   Step 05 - RIMS (Radiology + PACS): column additions to existing tables + new FDS tables
   Run against an EXISTING himsdev database that was built from database_v3, in file-name order:
     00_restructure_7_to_9_services.sql  -> 01..09_<service>_delta.sql  -> 10_post_migration_housekeeping.sql -> ../full/roles.sql
   Every statement is idempotent where PostgreSQL allows it (IF NOT EXISTS / guarded DO blocks).
   ===================================================================================== */

BEGIN;

/* ---------- A. MODIFICATIONS TO EXISTING TABLES (ADD COLUMN) ---------- */

-- rims.mst_rad_procedure  (10 new columns)  FDS: RAD-MST-001/003/006, RAD-ORD-006 (Radiology procedure entity)
ALTER TABLE rims.mst_rad_procedure ADD COLUMN IF NOT EXISTS procedure_code VARCHAR(30) NULL;
ALTER TABLE rims.mst_rad_procedure ADD COLUMN IF NOT EXISTS laterality_applicable BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE rims.mst_rad_procedure ADD COLUMN IF NOT EXISTS sub_specialty VARCHAR(30) NULL;
ALTER TABLE rims.mst_rad_procedure ADD COLUMN IF NOT EXISTS requires_radiologist_review BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE rims.mst_rad_procedure ADD COLUMN IF NOT EXISTS requires_prescription BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE rims.mst_rad_procedure ADD COLUMN IF NOT EXISTS is_pcpndt_applicable BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE rims.mst_rad_procedure ADD COLUMN IF NOT EXISTS drl_ctdivol_mgy DECIMAL(10,2) NULL;
ALTER TABLE rims.mst_rad_procedure ADD COLUMN IF NOT EXISTS drl_dlp_mgy_cm DECIMAL(10,2) NULL;
ALTER TABLE rims.mst_rad_procedure ADD COLUMN IF NOT EXISTS drl_dap_gy_cm2 DECIMAL(10,2) NULL;
ALTER TABLE rims.mst_rad_procedure ADD COLUMN IF NOT EXISTS default_tat_minutes INT NULL;
COMMENT ON COLUMN rims.mst_rad_procedure.procedure_code IS '[v4: RAD-MST-001/003/006, RAD-ORD-006 (Radiology procedure entity)]';
COMMENT ON COLUMN rims.mst_rad_procedure.laterality_applicable IS '[v4: RAD-MST-001/003/006, RAD-ORD-006 (Radiology procedure entity)]';
COMMENT ON COLUMN rims.mst_rad_procedure.sub_specialty IS 'NEURO, MSK, CHEST, BREAST, ABDOMEN, CARDIAC [v4: RAD-MST-001/003/006, RAD-ORD-006 (Radiology procedure entity)]';
COMMENT ON COLUMN rims.mst_rad_procedure.requires_radiologist_review IS '[v4: RAD-MST-001/003/006, RAD-ORD-006 (Radiology procedure entity)]';
COMMENT ON COLUMN rims.mst_rad_procedure.requires_prescription IS '[v4: RAD-MST-001/003/006, RAD-ORD-006 (Radiology procedure entity)]';
COMMENT ON COLUMN rims.mst_rad_procedure.is_pcpndt_applicable IS 'obstetric USG -> Form F [v4: RAD-MST-001/003/006, RAD-ORD-006 (Radiology procedure entity)]';
COMMENT ON COLUMN rims.mst_rad_procedure.drl_ctdivol_mgy IS '[v4: RAD-MST-001/003/006, RAD-ORD-006 (Radiology procedure entity)]';
COMMENT ON COLUMN rims.mst_rad_procedure.drl_dlp_mgy_cm IS '[v4: RAD-MST-001/003/006, RAD-ORD-006 (Radiology procedure entity)]';
COMMENT ON COLUMN rims.mst_rad_procedure.drl_dap_gy_cm2 IS '[v4: RAD-MST-001/003/006, RAD-ORD-006 (Radiology procedure entity)]';
COMMENT ON COLUMN rims.mst_rad_procedure.default_tat_minutes IS '[v4: RAD-MST-001/003/006, RAD-ORD-006 (Radiology procedure entity)]';

-- rims.pacs_ai_finding  (17 new columns)  FDS: AI-OVL-001..006, AI-TMR-001..005 (AI result entity)
ALTER TABLE rims.pacs_ai_finding ADD COLUMN IF NOT EXISTS ai_model_id INT NULL;
ALTER TABLE rims.pacs_ai_finding ADD COLUMN IF NOT EXISTS ai_job_id BIGINT NULL;
ALTER TABLE rims.pacs_ai_finding ADD COLUMN IF NOT EXISTS finding_label VARCHAR(100) NULL;
ALTER TABLE rims.pacs_ai_finding ADD COLUMN IF NOT EXISTS series_instance_uid VARCHAR(100) NULL;
ALTER TABLE rims.pacs_ai_finding ADD COLUMN IF NOT EXISTS sop_instance_uid VARCHAR(100) NULL;
ALTER TABLE rims.pacs_ai_finding ADD COLUMN IF NOT EXISTS slice_index INT NULL;
ALTER TABLE rims.pacs_ai_finding ADD COLUMN IF NOT EXISTS location_json JSONB NULL;
ALTER TABLE rims.pacs_ai_finding ADD COLUMN IF NOT EXISTS size_long_axis_mm DECIMAL(8,2) NULL;
ALTER TABLE rims.pacs_ai_finding ADD COLUMN IF NOT EXISTS size_short_axis_mm DECIMAL(8,2) NULL;
ALTER TABLE rims.pacs_ai_finding ADD COLUMN IF NOT EXISTS volume_mm3 DECIMAL(12,2) NULL;
ALTER TABLE rims.pacs_ai_finding ADD COLUMN IF NOT EXISTS density_hu DECIMAL(8,2) NULL;
ALTER TABLE rims.pacs_ai_finding ADD COLUMN IF NOT EXISTS prior_ai_finding_id BIGINT NULL;
ALTER TABLE rims.pacs_ai_finding ADD COLUMN IF NOT EXISTS growth_rate_pct DECIMAL(8,2) NULL;
ALTER TABLE rims.pacs_ai_finding ADD COLUMN IF NOT EXISTS decision VARCHAR(20) NULL;
ALTER TABLE rims.pacs_ai_finding ADD COLUMN IF NOT EXISTS edited_json JSONB NULL;
ALTER TABLE rims.pacs_ai_finding ADD COLUMN IF NOT EXISTS dicom_object_uid VARCHAR(100) NULL;
ALTER TABLE rims.pacs_ai_finding ADD COLUMN IF NOT EXISTS is_critical BOOLEAN NULL DEFAULT FALSE;
COMMENT ON COLUMN rims.pacs_ai_finding.ai_model_id IS '[v4: AI-OVL-001..006, AI-TMR-001..005 (AI result entity)]';
COMMENT ON COLUMN rims.pacs_ai_finding.ai_job_id IS '[v4: AI-OVL-001..006, AI-TMR-001..005 (AI result entity)]';
COMMENT ON COLUMN rims.pacs_ai_finding.finding_label IS '[v4: AI-OVL-001..006, AI-TMR-001..005 (AI result entity)]';
COMMENT ON COLUMN rims.pacs_ai_finding.series_instance_uid IS '[v4: AI-OVL-001..006, AI-TMR-001..005 (AI result entity)]';
COMMENT ON COLUMN rims.pacs_ai_finding.sop_instance_uid IS '[v4: AI-OVL-001..006, AI-TMR-001..005 (AI result entity)]';
COMMENT ON COLUMN rims.pacs_ai_finding.slice_index IS '[v4: AI-OVL-001..006, AI-TMR-001..005 (AI result entity)]';
COMMENT ON COLUMN rims.pacs_ai_finding.location_json IS '[v4: AI-OVL-001..006, AI-TMR-001..005 (AI result entity)]';
COMMENT ON COLUMN rims.pacs_ai_finding.size_long_axis_mm IS '[v4: AI-OVL-001..006, AI-TMR-001..005 (AI result entity)]';
COMMENT ON COLUMN rims.pacs_ai_finding.size_short_axis_mm IS '[v4: AI-OVL-001..006, AI-TMR-001..005 (AI result entity)]';
COMMENT ON COLUMN rims.pacs_ai_finding.volume_mm3 IS '[v4: AI-OVL-001..006, AI-TMR-001..005 (AI result entity)]';
COMMENT ON COLUMN rims.pacs_ai_finding.density_hu IS '[v4: AI-OVL-001..006, AI-TMR-001..005 (AI result entity)]';
COMMENT ON COLUMN rims.pacs_ai_finding.prior_ai_finding_id IS '[v4: AI-OVL-001..006, AI-TMR-001..005 (AI result entity)]';
COMMENT ON COLUMN rims.pacs_ai_finding.growth_rate_pct IS '[v4: AI-OVL-001..006, AI-TMR-001..005 (AI result entity)]';
COMMENT ON COLUMN rims.pacs_ai_finding.decision IS 'ACCEPTED, REJECTED, EDITED [v4: AI-OVL-001..006, AI-TMR-001..005 (AI result entity)]';
COMMENT ON COLUMN rims.pacs_ai_finding.edited_json IS '[v4: AI-OVL-001..006, AI-TMR-001..005 (AI result entity)]';
COMMENT ON COLUMN rims.pacs_ai_finding.dicom_object_uid IS '[v4: AI-OVL-001..006, AI-TMR-001..005 (AI result entity)]';
COMMENT ON COLUMN rims.pacs_ai_finding.is_critical IS '[v4: AI-OVL-001..006, AI-TMR-001..005 (AI result entity)]';

-- rims.pacs_annotation  (6 new columns)  FDS: VWR-MEA-001..009, AI-OVL-006 (Markup entity)
ALTER TABLE rims.pacs_annotation ADD COLUMN IF NOT EXISTS version_no SMALLINT NULL DEFAULT 1;
ALTER TABLE rims.pacs_annotation ADD COLUMN IF NOT EXISTS is_key_image BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE rims.pacs_annotation ADD COLUMN IF NOT EXISTS dicom_object_uid VARCHAR(100) NULL;
ALTER TABLE rims.pacs_annotation ADD COLUMN IF NOT EXISTS style_json JSONB NULL;
ALTER TABLE rims.pacs_annotation ADD COLUMN IF NOT EXISTS is_visible BOOLEAN NULL DEFAULT TRUE;
ALTER TABLE rims.pacs_annotation ADD COLUMN IF NOT EXISTS ai_finding_id BIGINT NULL;
COMMENT ON COLUMN rims.pacs_annotation.version_no IS '[v4: VWR-MEA-001..009, AI-OVL-006 (Markup entity)]';
COMMENT ON COLUMN rims.pacs_annotation.is_key_image IS '[v4: VWR-MEA-001..009, AI-OVL-006 (Markup entity)]';
COMMENT ON COLUMN rims.pacs_annotation.dicom_object_uid IS 'stored as SR / GSPS [v4: VWR-MEA-001..009, AI-OVL-006 (Markup entity)]';
COMMENT ON COLUMN rims.pacs_annotation.style_json IS '[v4: VWR-MEA-001..009, AI-OVL-006 (Markup entity)]';
COMMENT ON COLUMN rims.pacs_annotation.is_visible IS '[v4: VWR-MEA-001..009, AI-OVL-006 (Markup entity)]';
COMMENT ON COLUMN rims.pacs_annotation.ai_finding_id IS '[v4: VWR-MEA-001..009, AI-OVL-006 (Markup entity)]';

-- rims.pacs_dicom_node  (13 new columns)  FDS: DCM-ING-006/010/011/013/014, DCM-PRT-002, DCM-RTE-001, RAD-PAC-003 (Node entity)
ALTER TABLE rims.pacs_dicom_node ADD COLUMN IF NOT EXISTS node_name VARCHAR(100) NULL;
ALTER TABLE rims.pacs_dicom_node ADD COLUMN IF NOT EXISTS description VARCHAR(300) NULL;
ALTER TABLE rims.pacs_dicom_node ADD COLUMN IF NOT EXISTS tls_enabled BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE rims.pacs_dicom_node ADD COLUMN IF NOT EXISTS node_status VARCHAR(20) NULL DEFAULT 'ACTIVE';
ALTER TABLE rims.pacs_dicom_node ADD COLUMN IF NOT EXISTS max_associations SMALLINT NULL;
ALTER TABLE rims.pacs_dicom_node ADD COLUMN IF NOT EXISTS tag_morphing_rules_json JSONB NULL;
ALTER TABLE rims.pacs_dicom_node ADD COLUMN IF NOT EXISTS no_data_alert_minutes INT NULL;
ALTER TABLE rims.pacs_dicom_node ADD COLUMN IF NOT EXISTS last_echo_at TIMESTAMPTZ(0) NULL;
ALTER TABLE rims.pacs_dicom_node ADD COLUMN IF NOT EXISTS last_received_at TIMESTAMPTZ(0) NULL;
ALTER TABLE rims.pacs_dicom_node ADD COLUMN IF NOT EXISTS film_sizes VARCHAR(200) NULL;
ALTER TABLE rims.pacs_dicom_node ADD COLUMN IF NOT EXISTS media_type VARCHAR(30) NULL;
ALTER TABLE rims.pacs_dicom_node ADD COLUMN IF NOT EXISTS default_print_settings_json JSONB NULL;
ALTER TABLE rims.pacs_dicom_node ADD COLUMN IF NOT EXISTS modality_id INT NULL;
COMMENT ON COLUMN rims.pacs_dicom_node.node_name IS '[v4: DCM-ING-006/010/011/013/014, DCM-PRT-002, DCM-RTE-001, RAD-PAC-003 (Node entity)]';
COMMENT ON COLUMN rims.pacs_dicom_node.description IS '[v4: DCM-ING-006/010/011/013/014, DCM-PRT-002, DCM-RTE-001, RAD-PAC-003 (Node entity)]';
COMMENT ON COLUMN rims.pacs_dicom_node.tls_enabled IS '[v4: DCM-ING-006/010/011/013/014, DCM-PRT-002, DCM-RTE-001, RAD-PAC-003 (Node entity)]';
COMMENT ON COLUMN rims.pacs_dicom_node.node_status IS '[v4: DCM-ING-006/010/011/013/014, DCM-PRT-002, DCM-RTE-001, RAD-PAC-003 (Node entity)]';
COMMENT ON COLUMN rims.pacs_dicom_node.max_associations IS '[v4: DCM-ING-006/010/011/013/014, DCM-PRT-002, DCM-RTE-001, RAD-PAC-003 (Node entity)]';
COMMENT ON COLUMN rims.pacs_dicom_node.tag_morphing_rules_json IS '[v4: DCM-ING-006/010/011/013/014, DCM-PRT-002, DCM-RTE-001, RAD-PAC-003 (Node entity)]';
COMMENT ON COLUMN rims.pacs_dicom_node.no_data_alert_minutes IS '[v4: DCM-ING-006/010/011/013/014, DCM-PRT-002, DCM-RTE-001, RAD-PAC-003 (Node entity)]';
COMMENT ON COLUMN rims.pacs_dicom_node.last_echo_at IS '[v4: DCM-ING-006/010/011/013/014, DCM-PRT-002, DCM-RTE-001, RAD-PAC-003 (Node entity)]';
COMMENT ON COLUMN rims.pacs_dicom_node.last_received_at IS '[v4: DCM-ING-006/010/011/013/014, DCM-PRT-002, DCM-RTE-001, RAD-PAC-003 (Node entity)]';
COMMENT ON COLUMN rims.pacs_dicom_node.film_sizes IS 'printers [v4: DCM-ING-006/010/011/013/014, DCM-PRT-002, DCM-RTE-001, RAD-PAC-003 (Node entity)]';
COMMENT ON COLUMN rims.pacs_dicom_node.media_type IS '[v4: DCM-ING-006/010/011/013/014, DCM-PRT-002, DCM-RTE-001, RAD-PAC-003 (Node entity)]';
COMMENT ON COLUMN rims.pacs_dicom_node.default_print_settings_json IS '[v4: DCM-ING-006/010/011/013/014, DCM-PRT-002, DCM-RTE-001, RAD-PAC-003 (Node entity)]';
COMMENT ON COLUMN rims.pacs_dicom_node.modality_id IS '[v4: DCM-ING-006/010/011/013/014, DCM-PRT-002, DCM-RTE-001, RAD-PAC-003 (Node entity)]';

-- rims.pacs_dicom_series  (5 new columns)  FDS: Series / Instance entity (PACS 4.1)
ALTER TABLE rims.pacs_dicom_series ADD COLUMN IF NOT EXISTS series_number INT NULL;
ALTER TABLE rims.pacs_dicom_series ADD COLUMN IF NOT EXISTS pixel_spacing VARCHAR(50) NULL;
ALTER TABLE rims.pacs_dicom_series ADD COLUMN IF NOT EXISTS transfer_syntax_uid VARCHAR(100) NULL;
ALTER TABLE rims.pacs_dicom_series ADD COLUMN IF NOT EXISTS storage_tier VARCHAR(20) NULL;
ALTER TABLE rims.pacs_dicom_series ADD COLUMN IF NOT EXISTS is_ai_generated BOOLEAN NULL DEFAULT FALSE;
COMMENT ON COLUMN rims.pacs_dicom_series.series_number IS '[v4: Series / Instance entity (PACS 4.1)]';
COMMENT ON COLUMN rims.pacs_dicom_series.pixel_spacing IS '[v4: Series / Instance entity (PACS 4.1)]';
COMMENT ON COLUMN rims.pacs_dicom_series.transfer_syntax_uid IS '[v4: Series / Instance entity (PACS 4.1)]';
COMMENT ON COLUMN rims.pacs_dicom_series.storage_tier IS '[v4: Series / Instance entity (PACS 4.1)]';
COMMENT ON COLUMN rims.pacs_dicom_series.is_ai_generated IS '[v4: Series / Instance entity (PACS 4.1)]';

-- rims.pacs_dicom_study  (14 new columns)  FDS: STO-002..008, TRK-001, AI-PIP-004 (Study entity)
ALTER TABLE rims.pacs_dicom_study ADD COLUMN IF NOT EXISTS referring_physician VARCHAR(150) NULL;
ALTER TABLE rims.pacs_dicom_study ADD COLUMN IF NOT EXISTS institution_name VARCHAR(200) NULL;
ALTER TABLE rims.pacs_dicom_study ADD COLUMN IF NOT EXISTS priority VARCHAR(10) NULL;
ALTER TABLE rims.pacs_dicom_study ADD COLUMN IF NOT EXISTS study_status VARCHAR(20) NULL;
ALTER TABLE rims.pacs_dicom_study ADD COLUMN IF NOT EXISTS ai_status VARCHAR(20) NULL;
ALTER TABLE rims.pacs_dicom_study ADD COLUMN IF NOT EXISTS storage_policy_id INT NULL;
ALTER TABLE rims.pacs_dicom_study ADD COLUMN IF NOT EXISTS retention_until DATE NULL;
ALTER TABLE rims.pacs_dicom_study ADD COLUMN IF NOT EXISTS legal_hold BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE rims.pacs_dicom_study ADD COLUMN IF NOT EXISTS last_checksum_verified_at TIMESTAMPTZ(0) NULL;
ALTER TABLE rims.pacs_dicom_study ADD COLUMN IF NOT EXISTS last_accessed_at TIMESTAMPTZ(0) NULL;
ALTER TABLE rims.pacs_dicom_study ADD COLUMN IF NOT EXISTS merged_into_dicom_study_id BIGINT NULL;
ALTER TABLE rims.pacs_dicom_study ADD COLUMN IF NOT EXISTS deletion_requested_by BIGINT NULL;
ALTER TABLE rims.pacs_dicom_study ADD COLUMN IF NOT EXISTS deletion_approved_by BIGINT NULL;
ALTER TABLE rims.pacs_dicom_study ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ(0) NULL;
COMMENT ON COLUMN rims.pacs_dicom_study.referring_physician IS '[v4: STO-002..008, TRK-001, AI-PIP-004 (Study entity)]';
COMMENT ON COLUMN rims.pacs_dicom_study.institution_name IS '[v4: STO-002..008, TRK-001, AI-PIP-004 (Study entity)]';
COMMENT ON COLUMN rims.pacs_dicom_study.priority IS '[v4: STO-002..008, TRK-001, AI-PIP-004 (Study entity)]';
COMMENT ON COLUMN rims.pacs_dicom_study.study_status IS 'RECEIVED, ASSIGNED, IN_REPORTING, REPORTED, ON_HOLD, REJECTED, CANCELLED [v4: STO-002..008, TRK-001, AI-PIP-004 (Study entity)]';
COMMENT ON COLUMN rims.pacs_dicom_study.ai_status IS 'NOT_ELIGIBLE, QUEUED, RUNNING, COMPLETED, FAILED [v4: STO-002..008, TRK-001, AI-PIP-004 (Study entity)]';
COMMENT ON COLUMN rims.pacs_dicom_study.storage_policy_id IS '[v4: STO-002..008, TRK-001, AI-PIP-004 (Study entity)]';
COMMENT ON COLUMN rims.pacs_dicom_study.retention_until IS '[v4: STO-002..008, TRK-001, AI-PIP-004 (Study entity)]';
COMMENT ON COLUMN rims.pacs_dicom_study.legal_hold IS '[v4: STO-002..008, TRK-001, AI-PIP-004 (Study entity)]';
COMMENT ON COLUMN rims.pacs_dicom_study.last_checksum_verified_at IS '[v4: STO-002..008, TRK-001, AI-PIP-004 (Study entity)]';
COMMENT ON COLUMN rims.pacs_dicom_study.last_accessed_at IS '[v4: STO-002..008, TRK-001, AI-PIP-004 (Study entity)]';
COMMENT ON COLUMN rims.pacs_dicom_study.merged_into_dicom_study_id IS '[v4: STO-002..008, TRK-001, AI-PIP-004 (Study entity)]';
COMMENT ON COLUMN rims.pacs_dicom_study.deletion_requested_by IS '[v4: STO-002..008, TRK-001, AI-PIP-004 (Study entity)]';
COMMENT ON COLUMN rims.pacs_dicom_study.deletion_approved_by IS '[v4: STO-002..008, TRK-001, AI-PIP-004 (Study entity)]';
COMMENT ON COLUMN rims.pacs_dicom_study.deleted_at IS '[v4: STO-002..008, TRK-001, AI-PIP-004 (Study entity)]';

-- rims.pacs_reading_assignment  (10 new columns)  FDS: TEL-001..006, RAD-WRK-002..005 (Worklist item entity)
ALTER TABLE rims.pacs_reading_assignment ADD COLUMN IF NOT EXISTS priority VARCHAR(10) NULL;
ALTER TABLE rims.pacs_reading_assignment ADD COLUMN IF NOT EXISTS sla_target_at TIMESTAMPTZ(0) NULL;
ALTER TABLE rims.pacs_reading_assignment ADD COLUMN IF NOT EXISTS assignment_method VARCHAR(20) NULL;
ALTER TABLE rims.pacs_reading_assignment ADD COLUMN IF NOT EXISTS distribution_rule_id INT NULL;
ALTER TABLE rims.pacs_reading_assignment ADD COLUMN IF NOT EXISTS reassigned_from_id BIGINT NULL;
ALTER TABLE rims.pacs_reading_assignment ADD COLUMN IF NOT EXISTS reassign_reason VARCHAR(300) NULL;
ALTER TABLE rims.pacs_reading_assignment ADD COLUMN IF NOT EXISTS tele_centre VARCHAR(150) NULL;
ALTER TABLE rims.pacs_reading_assignment ADD COLUMN IF NOT EXISTS referring_site VARCHAR(150) NULL;
ALTER TABLE rims.pacs_reading_assignment ADD COLUMN IF NOT EXISTS locked_by BIGINT NULL;
ALTER TABLE rims.pacs_reading_assignment ADD COLUMN IF NOT EXISTS locked_at TIMESTAMPTZ(0) NULL;
COMMENT ON COLUMN rims.pacs_reading_assignment.priority IS '[v4: TEL-001..006, RAD-WRK-002..005 (Worklist item entity)]';
COMMENT ON COLUMN rims.pacs_reading_assignment.sla_target_at IS '[v4: TEL-001..006, RAD-WRK-002..005 (Worklist item entity)]';
COMMENT ON COLUMN rims.pacs_reading_assignment.assignment_method IS 'RULE, MANUAL, CLAIM, REASSIGN [v4: TEL-001..006, RAD-WRK-002..005 (Worklist item entity)]';
COMMENT ON COLUMN rims.pacs_reading_assignment.distribution_rule_id IS '[v4: TEL-001..006, RAD-WRK-002..005 (Worklist item entity)]';
COMMENT ON COLUMN rims.pacs_reading_assignment.reassigned_from_id IS '[v4: TEL-001..006, RAD-WRK-002..005 (Worklist item entity)]';
COMMENT ON COLUMN rims.pacs_reading_assignment.reassign_reason IS '[v4: TEL-001..006, RAD-WRK-002..005 (Worklist item entity)]';
COMMENT ON COLUMN rims.pacs_reading_assignment.tele_centre IS '[v4: TEL-001..006, RAD-WRK-002..005 (Worklist item entity)]';
COMMENT ON COLUMN rims.pacs_reading_assignment.referring_site IS '[v4: TEL-001..006, RAD-WRK-002..005 (Worklist item entity)]';
COMMENT ON COLUMN rims.pacs_reading_assignment.locked_by IS '[v4: TEL-001..006, RAD-WRK-002..005 (Worklist item entity)]';
COMMENT ON COLUMN rims.pacs_reading_assignment.locked_at IS '[v4: TEL-001..006, RAD-WRK-002..005 (Worklist item entity)]';

-- rims.pacs_share_link  (11 new columns)  FDS: SHR-001..011 (Share link entity)
ALTER TABLE rims.pacs_share_link ADD COLUMN IF NOT EXISTS scope_level VARCHAR(10) NULL DEFAULT 'STUDY';
ALTER TABLE rims.pacs_share_link ADD COLUMN IF NOT EXISTS series_instance_uid VARCHAR(100) NULL;
ALTER TABLE rims.pacs_share_link ADD COLUMN IF NOT EXISTS permissions_json JSONB NULL;
ALTER TABLE rims.pacs_share_link ADD COLUMN IF NOT EXISTS passcode_hash VARCHAR(128) NULL;
ALTER TABLE rims.pacs_share_link ADD COLUMN IF NOT EXISTS max_views SMALLINT NULL;
ALTER TABLE rims.pacs_share_link ADD COLUMN IF NOT EXISTS is_anonymised BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE rims.pacs_share_link ADD COLUMN IF NOT EXISTS consent_id BIGINT NULL;
ALTER TABLE rims.pacs_share_link ADD COLUMN IF NOT EXISTS failed_attempts SMALLINT NULL DEFAULT 0;
ALTER TABLE rims.pacs_share_link ADD COLUMN IF NOT EXISTS locked_at TIMESTAMPTZ(0) NULL;
ALTER TABLE rims.pacs_share_link ADD COLUMN IF NOT EXISTS notify_on_first_access BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE rims.pacs_share_link ADD COLUMN IF NOT EXISTS link_status VARCHAR(20) NULL DEFAULT 'ACTIVE';
COMMENT ON COLUMN rims.pacs_share_link.scope_level IS 'PATIENT, STUDY, SERIES [v4: SHR-001..011 (Share link entity)]';
COMMENT ON COLUMN rims.pacs_share_link.series_instance_uid IS '[v4: SHR-001..011 (Share link entity)]';
COMMENT ON COLUMN rims.pacs_share_link.permissions_json IS 'view, view+report, download, measure [v4: SHR-001..011 (Share link entity)]';
COMMENT ON COLUMN rims.pacs_share_link.passcode_hash IS '[v4: SHR-001..011 (Share link entity)]';
COMMENT ON COLUMN rims.pacs_share_link.max_views IS '[v4: SHR-001..011 (Share link entity)]';
COMMENT ON COLUMN rims.pacs_share_link.is_anonymised IS '[v4: SHR-001..011 (Share link entity)]';
COMMENT ON COLUMN rims.pacs_share_link.consent_id IS '[v4: SHR-001..011 (Share link entity)]';
COMMENT ON COLUMN rims.pacs_share_link.failed_attempts IS '[v4: SHR-001..011 (Share link entity)]';
COMMENT ON COLUMN rims.pacs_share_link.locked_at IS '[v4: SHR-001..011 (Share link entity)]';
COMMENT ON COLUMN rims.pacs_share_link.notify_on_first_access IS '[v4: SHR-001..011 (Share link entity)]';
COMMENT ON COLUMN rims.pacs_share_link.link_status IS '[v4: SHR-001..011 (Share link entity)]';

-- rims.rad_modality  (7 new columns)  FDS: RAD-MST-004, RAD-SCH-008/010 (Modality entity)
ALTER TABLE rims.rad_modality ADD COLUMN IF NOT EXISTS manufacturer VARCHAR(100) NULL;
ALTER TABLE rims.rad_modality ADD COLUMN IF NOT EXISTS model VARCHAR(100) NULL;
ALTER TABLE rims.rad_modality ADD COLUMN IF NOT EXISTS mwl_enabled BOOLEAN NULL DEFAULT TRUE;
ALTER TABLE rims.rad_modality ADD COLUMN IF NOT EXISTS mpps_enabled BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE rims.rad_modality ADD COLUMN IF NOT EXISTS rdsr_enabled BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE rims.rad_modality ADD COLUMN IF NOT EXISTS daily_capacity SMALLINT NULL;
ALTER TABLE rims.rad_modality ADD COLUMN IF NOT EXISTS dicom_node_id INT NULL;
COMMENT ON COLUMN rims.rad_modality.manufacturer IS '[v4: RAD-MST-004, RAD-SCH-008/010 (Modality entity)]';
COMMENT ON COLUMN rims.rad_modality.model IS '[v4: RAD-MST-004, RAD-SCH-008/010 (Modality entity)]';
COMMENT ON COLUMN rims.rad_modality.mwl_enabled IS '[v4: RAD-MST-004, RAD-SCH-008/010 (Modality entity)]';
COMMENT ON COLUMN rims.rad_modality.mpps_enabled IS '[v4: RAD-MST-004, RAD-SCH-008/010 (Modality entity)]';
COMMENT ON COLUMN rims.rad_modality.rdsr_enabled IS '[v4: RAD-MST-004, RAD-SCH-008/010 (Modality entity)]';
COMMENT ON COLUMN rims.rad_modality.daily_capacity IS '[v4: RAD-MST-004, RAD-SCH-008/010 (Modality entity)]';
COMMENT ON COLUMN rims.rad_modality.dicom_node_id IS '[v4: RAD-MST-004, RAD-SCH-008/010 (Modality entity)]';

-- rims.rad_report  (12 new columns)  FDS: RAD-WRK-008/010, RAD-DIC-001..007, RAD-RPT-001..004 (Radiology report entity)
ALTER TABLE rims.rad_report ADD COLUMN IF NOT EXISTS report_no VARCHAR(30) NULL;
ALTER TABLE rims.rad_report ADD COLUMN IF NOT EXISTS recommendations TEXT NULL;
ALTER TABLE rims.rad_report ADD COLUMN IF NOT EXISTS is_addendum BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE rims.rad_report ADD COLUMN IF NOT EXISTS parent_rad_report_id BIGINT NULL;
ALTER TABLE rims.rad_report ADD COLUMN IF NOT EXISTS technician_signed_by BIGINT NULL;
ALTER TABLE rims.rad_report ADD COLUMN IF NOT EXISTS preliminary_at TIMESTAMPTZ(0) NULL;
ALTER TABLE rims.rad_report ADD COLUMN IF NOT EXISTS finalised_at TIMESTAMPTZ(0) NULL;
ALTER TABLE rims.rad_report ADD COLUMN IF NOT EXISTS verification_token VARCHAR(100) NULL;
ALTER TABLE rims.rad_report ADD COLUMN IF NOT EXISTS ai_draft_used BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE rims.rad_report ADD COLUMN IF NOT EXISTS ai_impression_draft_id BIGINT NULL;
ALTER TABLE rims.rad_report ADD COLUMN IF NOT EXISTS key_images_json JSONB NULL;
ALTER TABLE rims.rad_report ADD COLUMN IF NOT EXISTS abdm_shared_at TIMESTAMPTZ(0) NULL;
COMMENT ON COLUMN rims.rad_report.report_no IS '[v4: RAD-WRK-008/010, RAD-DIC-001..007, RAD-RPT-001..004 (Radiology report entity)]';
COMMENT ON COLUMN rims.rad_report.recommendations IS '[v4: RAD-WRK-008/010, RAD-DIC-001..007, RAD-RPT-001..004 (Radiology report entity)]';
COMMENT ON COLUMN rims.rad_report.is_addendum IS '[v4: RAD-WRK-008/010, RAD-DIC-001..007, RAD-RPT-001..004 (Radiology report entity)]';
COMMENT ON COLUMN rims.rad_report.parent_rad_report_id IS '[v4: RAD-WRK-008/010, RAD-DIC-001..007, RAD-RPT-001..004 (Radiology report entity)]';
COMMENT ON COLUMN rims.rad_report.technician_signed_by IS '[v4: RAD-WRK-008/010, RAD-DIC-001..007, RAD-RPT-001..004 (Radiology report entity)]';
COMMENT ON COLUMN rims.rad_report.preliminary_at IS '[v4: RAD-WRK-008/010, RAD-DIC-001..007, RAD-RPT-001..004 (Radiology report entity)]';
COMMENT ON COLUMN rims.rad_report.finalised_at IS '[v4: RAD-WRK-008/010, RAD-DIC-001..007, RAD-RPT-001..004 (Radiology report entity)]';
COMMENT ON COLUMN rims.rad_report.verification_token IS '[v4: RAD-WRK-008/010, RAD-DIC-001..007, RAD-RPT-001..004 (Radiology report entity)]';
COMMENT ON COLUMN rims.rad_report.ai_draft_used IS '[v4: RAD-WRK-008/010, RAD-DIC-001..007, RAD-RPT-001..004 (Radiology report entity)]';
COMMENT ON COLUMN rims.rad_report.ai_impression_draft_id IS '[v4: RAD-WRK-008/010, RAD-DIC-001..007, RAD-RPT-001..004 (Radiology report entity)]';
COMMENT ON COLUMN rims.rad_report.key_images_json IS '[v4: RAD-WRK-008/010, RAD-DIC-001..007, RAD-RPT-001..004 (Radiology report entity)]';
COMMENT ON COLUMN rims.rad_report.abdm_shared_at IS '[v4: RAD-WRK-008/010, RAD-DIC-001..007, RAD-RPT-001..004 (Radiology report entity)]';

-- rims.rad_report_template  (4 new columns)  FDS: RAD-STR-001..004 (Report template entity)
ALTER TABLE rims.rad_report_template ADD COLUMN IF NOT EXISTS is_personal BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE rims.rad_report_template ADD COLUMN IF NOT EXISTS structured_standard VARCHAR(30) NULL;
ALTER TABLE rims.rad_report_template ADD COLUMN IF NOT EXISTS version_no SMALLINT NULL DEFAULT 1;
ALTER TABLE rims.rad_report_template ADD COLUMN IF NOT EXISTS modality_type VARCHAR(10) NULL;
COMMENT ON COLUMN rims.rad_report_template.is_personal IS '[v4: RAD-STR-001..004 (Report template entity)]';
COMMENT ON COLUMN rims.rad_report_template.structured_standard IS 'BI_RADS, LI_RADS, PI_RADS, TI_RADS, LUNG_RADS, NONE [v4: RAD-STR-001..004 (Report template entity)]';
COMMENT ON COLUMN rims.rad_report_template.version_no IS '[v4: RAD-STR-001..004 (Report template entity)]';
COMMENT ON COLUMN rims.rad_report_template.modality_type IS '[v4: RAD-STR-001..004 (Report template entity)]';

-- rims.rad_study  (30 new columns)  FDS: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS priority VARCHAR(10) NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS laterality VARCHAR(10) NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS clinical_history TEXT NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS provisional_diagnosis VARCHAR(500) NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS referring_practitioner_id BIGINT NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS b2b_payer_id INT NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS appointment_id BIGINT NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS online_order_id BIGINT NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS pickup_required BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS order_review_status VARCHAR(20) NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS order_reviewed_by BIGINT NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS order_reviewed_at TIMESTAMPTZ(0) NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS order_review_comment VARCHAR(500) NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS protocol_set_by BIGINT NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS protocol_set_at TIMESTAMPTZ(0) NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS identity_confirmed_by BIGINT NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS consent_id BIGINT NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS contrast_route VARCHAR(20) NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS contrast_batch_no VARCHAR(50) NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS contrast_reaction_id BIGINT NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS dose_source VARCHAR(10) NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS dose_exceeds_drl BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS films_count SMALLINT NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS exposures_count SMALLINT NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS image_quality VARCHAR(20) NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS technician_notes VARCHAR(1000) NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS mpps_status VARCHAR(20) NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ(0) NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS cancel_reason VARCHAR(300) NULL;
ALTER TABLE rims.rad_study ADD COLUMN IF NOT EXISTS acquired_at TIMESTAMPTZ(0) NULL;
COMMENT ON COLUMN rims.rad_study.priority IS 'ROUTINE, URGENT, STAT, EMERGENCY [v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.laterality IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.clinical_history IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.provisional_diagnosis IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.referring_practitioner_id IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.b2b_payer_id IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.appointment_id IS 'patientengagement.sch_appointment [v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.online_order_id IS 'patientengagement.ecom_online_order [v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.pickup_required IS 'rider pick-up / drop (RAD-SCH-007) [v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.order_review_status IS 'NOT_REQUIRED, PENDING, APPROVED, REJECTED, MODIFIED [v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.order_reviewed_by IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.order_reviewed_at IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.order_review_comment IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.protocol_set_by IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.protocol_set_at IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.identity_confirmed_by IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.consent_id IS 'patientengagement.pat_consent [v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.contrast_route IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.contrast_batch_no IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.contrast_reaction_id IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.dose_source IS 'MANUAL, RDSR [v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.dose_exceeds_drl IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.films_count IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.exposures_count IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.image_quality IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.technician_notes IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.mpps_status IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.cancelled_at IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.cancel_reason IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';
COMMENT ON COLUMN rims.rad_study.acquired_at IS '[v4: RAD-ORD-*, RAD-SCH-*, RAD-CON-*, RAD-DOS-*, RAD-TEC-* (Study / exam entity)]';

/* ---------- B. NEW TABLES ---------- */

-- ===== Diagnostics LIMS & RIMS FRD - Section 4 (RIMS) =====
-- [NEW v4] FDS ref: RAD-MST-005
CREATE TABLE IF NOT EXISTS rims.mst_rad_procedure_modality (                   -- Procedure-to-modality mapping (which machines can perform a procedure)
    rad_procedure_modality_id  INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    rad_procedure_id           INT NOT NULL,
    modality_id                INT NOT NULL,
    duration_minutes           SMALLINT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT                 uq_mst_rad_procedure_modality_1 UNIQUE (rad_procedure_id, modality_id)
);

-- [NEW v4] FDS ref: RAD-SCH-003, RAD-SCH-006
CREATE TABLE IF NOT EXISTS rims.rad_modality_downtime (                        -- Modality downtime with affected appointments rescheduled
    modality_downtime_id       BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    modality_id                INT NOT NULL,
    downtime_from              TIMESTAMPTZ(0) NOT NULL,
    downtime_to                TIMESTAMPTZ(0) NULL,
    reason                     VARCHAR(300) NOT NULL,
    maintenance_log_id         BIGINT NULL,                                    -- logical FK -> operationssupply.adm_maintenance_log [Operations & Supply Chain]
    affected_study_count       SMALLINT NULL,
    reschedule_status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: RAD-TEC-002, RAD-SCH-013, RAD-CON-003
CREATE TABLE IF NOT EXISTS rims.rad_study_checklist (                          -- Pre-procedure checklist responses by modality (pregnancy, implants, MRI safety, allergy, renal function)
    study_checklist_id         BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    study_id                   BIGINT NOT NULL,
    checklist_item             VARCHAR(100) NOT NULL,
    response                   VARCHAR(100) NOT NULL,
    is_risk                    BOOLEAN NOT NULL DEFAULT FALSE,
    recorded_by                BIGINT NULL,
    recorded_at                TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: RAD-CON-002, RAD-CON-005
CREATE TABLE IF NOT EXISTS rims.rad_contrast_reaction (                        -- Contrast reactions (type, severity, treatment) - also updates patient allergy
    contrast_reaction_id       BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    study_id                   BIGINT NOT NULL,
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    contrast_item_id           INT NULL,                                       -- logical FK -> operationssupply.mst_item [Operations & Supply Chain]
    reaction_type              VARCHAR(50) NOT NULL,
    severity                   VARCHAR(20) NOT NULL,                           -- MILD, MODERATE, SEVERE
    treatment_given            VARCHAR(1000) NULL,
    onset_at                   TIMESTAMPTZ(0) NULL,
    recorded_by                BIGINT NULL,
    allergy_updated            BOOLEAN NOT NULL DEFAULT FALSE,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: RAD-TEC-008
CREATE TABLE IF NOT EXISTS rims.rad_exposure_reject (                          -- Repeated / rejected exposures with reason (image quality analysis)
    exposure_reject_id         BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    study_id                   BIGINT NOT NULL,
    exposure_count             SMALLINT NOT NULL DEFAULT 1,
    reason                     VARCHAR(50) NOT NULL,                           -- POSITIONING, MOTION, EXPOSURE, ARTEFACT, EQUIPMENT
    technician_id              BIGINT NULL,
    recorded_at                TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: RAD-TEC-004
CREATE TABLE IF NOT EXISTS rims.rad_pcpndt_form_f (                            -- PC-PNDT Form F for obstetric ultrasound
    pcpndt_form_f_id           BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    study_id                   BIGINT NOT NULL,
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    form_no                    VARCHAR(30) NOT NULL UNIQUE,
    referral_by                VARCHAR(150) NULL,
    lmp_date                   DATE NULL,
    indication                 VARCHAR(500) NOT NULL,
    declaration_signed_at      TIMESTAMPTZ(0) NULL,
    doctor_declaration_at      TIMESTAMPTZ(0) NULL,
    form_json                  JSONB NOT NULL,
    document_id                BIGINT NULL,                                    -- logical FK -> integrationcomms.core_document [Integration & Communications]
    submitted_to_authority_at  TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: RAD-STR-005
CREATE TABLE IF NOT EXISTS rims.rad_macro (                                    -- Radiology macros / quick text for normal findings
    macro_id                   INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    owner_practitioner_id      BIGINT NULL,                                    -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    modality_type              VARCHAR(10) NULL,
    shortcut                   VARCHAR(30) NOT NULL,
    expansion_text             TEXT NOT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: RAD-DIC-005, RAD-DIC-006
CREATE TABLE IF NOT EXISTS rims.rad_dictation_job (                            -- Radiology dictation audio routed to transcription queue
    dictation_job_id           BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    study_id                   BIGINT NOT NULL,
    rad_report_id              BIGINT NULL,
    radiologist_id             BIGINT NOT NULL,                                -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    audio_uri                  VARCHAR(500) NOT NULL,
    transcriptionist_id        BIGINT NULL,                                    -- logical FK -> identityorg.hr_employee [Identity & Organization]
    queued_at                  TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    transcribed_at             TIMESTAMPTZ(0) NULL,
    job_status                 VARCHAR(20) NOT NULL DEFAULT 'QUEUED',          -- QUEUED, IN_PROGRESS, RETURNED, SIGNED
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: RAD-WRK-009, TEL-010
CREATE TABLE IF NOT EXISTS rims.rad_peer_review (                              -- Second reading / peer review / discrepancy outcome
    peer_review_id             BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    rad_report_id              BIGINT NOT NULL,
    reviewer_id                BIGINT NOT NULL,                                -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    review_type                VARCHAR(20) NOT NULL,                           -- SECOND_OPINION, PEER_REVIEW, DISCREPANCY
    outcome                    VARCHAR(20) NULL,                               -- AGREE, MINOR_DISCREPANCY, MAJOR_DISCREPANCY
    comments                   VARCHAR(2000) NULL,
    reviewed_at                TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: RAD-CRT-001..005, TRK-007
CREATE TABLE IF NOT EXISTS rims.rad_critical_finding_alert (                   -- Critical finding notifications with read-back and escalation
    critical_finding_alert_id  BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    rad_report_id              BIGINT NOT NULL,
    study_id                   BIGINT NOT NULL,
    finding_text               VARCHAR(1000) NOT NULL,
    source                     VARCHAR(10) NOT NULL DEFAULT 'HUMAN',           -- HUMAN, AI
    notified_to_name           VARCHAR(150) NULL,
    notified_to_practitioner_id BIGINT NULL,                                   -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    notified_via               VARCHAR(20) NULL,
    notified_at                TIMESTAMPTZ(0) NULL,
    notified_by                BIGINT NULL,
    read_back_confirmed        BOOLEAN NOT NULL DEFAULT FALSE,
    acknowledged_at            TIMESTAMPTZ(0) NULL,
    escalation_level           SMALLINT NOT NULL DEFAULT 0,
    escalated_at               TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: RAD-RPT-008, SHR-012
CREATE TABLE IF NOT EXISTS rims.rad_media_issue (                              -- Film / CD / DVD issue with embedded viewer
    media_issue_id             BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    study_id                   BIGINT NOT NULL,
    media_type                 VARCHAR(10) NOT NULL,                           -- FILM, CD, DVD, USB, ZIP_PACKAGE
    quantity                   SMALLINT NOT NULL DEFAULT 1,
    film_size                  VARCHAR(20) NULL,
    issued_to_name             VARCHAR(150) NULL,
    issued_by                  BIGINT NULL,
    issued_at                  TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_billable                BOOLEAN NOT NULL DEFAULT TRUE,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);


-- ===== PACS Functional Requirements Document =====
-- [NEW v4] FDS ref: STO-001, STO-002, STO-007, STO-010
CREATE TABLE IF NOT EXISTS rims.pacs_dicom_instance (                          -- DICOM instance index (SOP Instance UID, transfer syntax, checksum, object type)
    dicom_instance_id          BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    dicom_series_id            BIGINT NOT NULL,
    sop_instance_uid           VARCHAR(100) NOT NULL UNIQUE,
    sop_class_uid              VARCHAR(100) NULL,
    instance_number            INT NULL,
    object_type                VARCHAR(20) NULL,                               -- IMAGE, GSPS, SR, KOS, ENCAPSULATED_PDF, SEG
    transfer_syntax_uid        VARCHAR(100) NULL,
    number_of_frames           INT NULL,
    size_bytes                 BIGINT NULL,
    sha256_hash                VARCHAR(64) NULL,
    storage_uri                VARCHAR(500) NULL,
    version_no                 SMALLINT NOT NULL DEFAULT 1,
    received_at                TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: DCM-ING-001..013
CREATE TABLE IF NOT EXISTS rims.pacs_ingestion_log (                           -- Ingestion events (C-STORE / STOW-RS / manual import) with result
    ingestion_log_id           BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    source_node_id             INT NULL,
    ingestion_channel          VARCHAR(20) NOT NULL,                           -- C_STORE, STOW_RS, MANUAL_IMPORT, DICOMDIR
    study_instance_uid         VARCHAR(100) NULL,
    instance_count             INT NULL,
    result                     VARCHAR(20) NOT NULL,                           -- SUCCESS, PARTIAL, REJECTED, QUARANTINED, DUPLICATE
    error_message              VARCHAR(1000) NULL,
    started_at                 TIMESTAMPTZ(0) NOT NULL,
    finished_at                TIMESTAMPTZ(0) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: DCM-ING-007..009, RAD-PAC-002
CREATE TABLE IF NOT EXISTS rims.pacs_quarantine_item (                         -- Non-conforming / duplicate objects held for review and reconciliation queue for unmatched studies
    quarantine_item_id         BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    item_type                  VARCHAR(20) NOT NULL,                           -- NON_CONFORMING, DUPLICATE_SOP, UNMATCHED_STUDY
    study_instance_uid         VARCHAR(100) NULL,
    sop_instance_uid           VARCHAR(100) NULL,
    accession_no               VARCHAR(30) NULL,
    patient_id_in_dicom        VARCHAR(64) NULL,
    issue_description          VARCHAR(1000) NULL,
    dicom_study_id             BIGINT NULL,
    resolution_action          VARCHAR(20) NULL,                               -- LINKED, CORRECTED, DISCARDED, OVERWRITTEN, NEW_VERSION
    resolved_study_id          BIGINT NULL,
    resolved_by                BIGINT NULL,
    resolved_at                TIMESTAMPTZ(0) NULL,
    item_status                VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: STO-008, VWR-CMP-005
CREATE TABLE IF NOT EXISTS rims.pacs_correction_log (                          -- Patient / study merge, split and demographic corrections with original values
    correction_log_id          BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    correction_type            VARCHAR(20) NOT NULL,                           -- MERGE, SPLIT, DEMOGRAPHIC_FIX, MOVE_SERIES
    dicom_study_id             BIGINT NOT NULL,
    original_values_json       JSONB NOT NULL,
    new_values_json            JSONB NOT NULL,
    reason                     VARCHAR(500) NOT NULL,
    performed_by               BIGINT NOT NULL,
    approved_by                BIGINT NULL,
    performed_at               TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: DCM-RTE-002, DCM-RTE-005, DCM-RTE-007 (Routing rule entity)
CREATE TABLE IF NOT EXISTS rims.pacs_routing_rule (                            -- Auto-routing rules on study arrival (conditions -> target node)
    routing_rule_id            INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    rule_name                  VARCHAR(100) NOT NULL,
    conditions_json            JSONB NOT NULL,                                 -- modality, body part, source AE, referring physician, institution
    target_node_id             INT NOT NULL,
    deid_profile_id            INT NULL,
    is_prefetch_rule           BOOLEAN NOT NULL DEFAULT FALSE,
    schedule_json              JSONB NULL,
    priority_order             SMALLINT NOT NULL DEFAULT 1,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: DCM-RTE-007, SHR-007, AI-GOV-003
CREATE TABLE IF NOT EXISTS rims.pacs_deid_profile (                            -- De-identification profiles for routing / sharing / AI
    deid_profile_id            INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    profile_name               VARCHAR(100) NOT NULL UNIQUE,
    tag_actions_json           JSONB NOT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: DCM-RTE-003..008 (Routing job entity)
CREATE TABLE IF NOT EXISTS rims.pacs_routing_job (                             -- Routing / forward / retrieve jobs with retry and status
    routing_job_id             BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    routing_rule_id            INT NULL,
    job_type                   VARCHAR(20) NOT NULL,                           -- AUTO_ROUTE, MANUAL_FORWARD, PREFETCH, C_MOVE, C_GET
    target_node_id             INT NOT NULL,
    dicom_study_id             BIGINT NULL,
    scope_level                VARCHAR(10) NOT NULL DEFAULT 'STUDY',           -- PATIENT, STUDY, SERIES, INSTANCE
    scope_uid                  VARCHAR(100) NULL,
    retry_count                SMALLINT NOT NULL DEFAULT 0,
    max_retries                SMALLINT NOT NULL DEFAULT 3,
    next_retry_at              TIMESTAMPTZ(0) NULL,
    last_error                 VARCHAR(1000) NULL,
    job_status                 VARCHAR(20) NOT NULL DEFAULT 'PENDING',         -- PENDING, IN_PROGRESS, COMPLETED, FAILED, CANCELLED
    requested_by               BIGINT NULL,
    completed_at               TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: DCM-PRT-001..007 (Print job entity)
CREATE TABLE IF NOT EXISTS rims.pacs_print_job (                               -- DICOM print queue
    print_job_id               BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    printer_node_id            INT NOT NULL,
    dicom_study_id             BIGINT NOT NULL,
    film_size                  VARCHAR(20) NULL,
    orientation                VARCHAR(10) NULL,
    layout                     VARCHAR(10) NULL,
    copies                     SMALLINT NOT NULL DEFAULT 1,
    images_json                JSONB NULL,
    include_annotations        BOOLEAN NOT NULL DEFAULT TRUE,
    print_status               VARCHAR(20) NOT NULL DEFAULT 'QUEUED',          -- QUEUED, SENDING, PRINTED, FAILED, CANCELLED
    requested_by               BIGINT NOT NULL,
    requested_at               TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    retry_count                SMALLINT NOT NULL DEFAULT 0,
    error_message              VARCHAR(500) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: STO-003..006 (Storage policy entity)
CREATE TABLE IF NOT EXISTS rims.pacs_storage_policy (                          -- Storage tier, compression, retention, legal hold and migration rules
    storage_policy_id          INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    policy_name                VARCHAR(100) NOT NULL UNIQUE,
    applies_to_json            JSONB NULL,                                     -- modality / study type / paediatric
    tier                       VARCHAR(20) NOT NULL,                           -- ONLINE, NEARLINE, ARCHIVE
    compression                VARCHAR(20) NOT NULL DEFAULT 'LOSSLESS',
    lossy_allowed              BOOLEAN NOT NULL DEFAULT FALSE,
    retention_years            SMALLINT NOT NULL,
    paediatric_rule            VARCHAR(200) NULL,
    migrate_after_days         INT NULL,
    migrate_to_tier            VARCHAR(20) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: VWR-GEN-004
CREATE TABLE IF NOT EXISTS rims.pacs_hanging_protocol (                        -- Hanging protocols by modality, body part and user
    hanging_protocol_id        INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    protocol_name              VARCHAR(100) NOT NULL,
    modality_type              VARCHAR(10) NULL,
    body_part                  VARCHAR(50) NULL,
    owner_user_id              BIGINT NULL,                                    -- logical FK -> identityorg.sec_user_account [Identity & Organization]
    layout_json                JSONB NOT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: VWR-GEN-008, TEL-007
CREATE TABLE IF NOT EXISTS rims.pacs_user_viewer_pref (                        -- Per-user viewer preferences, keyboard shortcuts and saved worklist filters
    user_viewer_pref_id        INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    user_id                    BIGINT NOT NULL UNIQUE,                         -- logical FK -> identityorg.sec_user_account [Identity & Organization]
    shortcuts_json             JSONB NULL,
    window_presets_json        JSONB NULL,
    saved_filters_json         JSONB NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TEL-002, RAD-WRK-002/003
CREATE TABLE IF NOT EXISTS rims.pacs_distribution_rule (                       -- Worklist distribution rules (round-robin, load, subspecialty, site, credential, shift)
    distribution_rule_id       INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    rule_name                  VARCHAR(100) NOT NULL,
    method                     VARCHAR(20) NOT NULL,                           -- ROUND_ROBIN, LOAD_BALANCE, SUBSPECIALTY, SITE, LANGUAGE
    conditions_json            JSONB NULL,
    target_pool_json           JSONB NULL,                                     -- radiologist ids / tele centres
    priority_order             SMALLINT NOT NULL DEFAULT 1,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TEL-006
CREATE TABLE IF NOT EXISTS rims.pacs_radiologist_shift (                       -- Radiologist availability and shift calendar for routing
    radiologist_shift_id       BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    radiologist_id             BIGINT NOT NULL,                                -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    shift_start                TIMESTAMPTZ(0) NOT NULL,
    shift_end                  TIMESTAMPTZ(0) NOT NULL,
    subspecialties             VARCHAR(200) NULL,
    max_concurrent             SMALLINT NULL,
    availability_status        VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TRK-002, TRK-003
CREATE TABLE IF NOT EXISTS rims.pacs_worklist_event (                          -- Time-stamped history of status changes, assignments and user actions
    worklist_event_id          BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    dicom_study_id             BIGINT NULL,
    rad_study_id               BIGINT NULL,
    reading_assignment_id      BIGINT NULL,
    event_type                 VARCHAR(30) NOT NULL,
    from_status                VARCHAR(20) NULL,
    to_status                  VARCHAR(20) NULL,
    event_by                   BIGINT NULL,
    event_at                   TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remarks                    VARCHAR(500) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TEL-012
CREATE TABLE IF NOT EXISTS rims.pacs_study_comment (                           -- Study-linked channel between referring site and radiologist (comments, call-back)
    study_comment_id           BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    dicom_study_id             BIGINT NOT NULL,
    author_user_id             BIGINT NOT NULL,                                -- logical FK -> identityorg.sec_user_account [Identity & Organization]
    comment_type               VARCHAR(20) NOT NULL DEFAULT 'COMMENT',         -- COMMENT, CALLBACK_REQUEST
    comment_text               VARCHAR(2000) NOT NULL,
    created_on                 TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at                TIMESTAMPTZ(0) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: SHR-008, SHR-011
CREATE TABLE IF NOT EXISTS rims.pacs_share_link_access (                       -- Share-link access log (time, IP, device, downloads)
    share_link_access_id       BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    share_link_id              BIGINT NOT NULL,
    accessed_at                TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    client_ip                  VARCHAR(45) NULL,
    device_info                VARCHAR(300) NULL,
    action                     VARCHAR(20) NOT NULL,                           -- OPEN, DOWNLOAD, FAILED_PASSCODE
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: VWR-SEC-002 (Audit event entity)
CREATE TABLE IF NOT EXISTS rims.pacs_access_audit (                            -- Viewer audit: study open, export, print, annotate (user, time, IP)
    access_audit_id            BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    user_id                    BIGINT NOT NULL,                                -- logical FK -> identityorg.sec_user_account [Identity & Organization]
    dicom_study_id             BIGINT NULL,
    action                     VARCHAR(20) NOT NULL,                           -- OPEN, EXPORT, PRINT, ANNOTATE, DELETE, SHARE
    object_ref                 VARCHAR(150) NULL,
    client_ip                  VARCHAR(45) NULL,
    outcome                    VARCHAR(10) NOT NULL DEFAULT 'SUCCESS',
    event_at                   TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: AI-PIP-002, AI-TMR-006, AI-GOV-001/002
CREATE TABLE IF NOT EXISTS rims.pacs_ai_model (                                -- AI model registry (vendor, version, intended use, regulatory status, thresholds)
    ai_model_id                INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    model_name                 VARCHAR(100) NOT NULL,
    model_version              VARCHAR(30) NOT NULL,
    vendor                     VARCHAR(100) NULL,
    intended_use               VARCHAR(500) NULL,
    regulatory_status          VARCHAR(50) NULL,                               -- CDSCO, CE, FDA, RESEARCH_ONLY
    validation_date            DATE NULL,
    interface_type             VARCHAR(20) NULL,                               -- DICOM, DICOMWEB, REST
    endpoint_id                INT NULL,                                       -- logical FK -> integrationcomms.intg_hl7_dicom_endpoint [Integration & Communications]
    sensitivity_threshold      DECIMAL(5,4) NULL,
    is_approved                BOOLEAN NOT NULL DEFAULT FALSE,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT                 uq_pacs_ai_model_1 UNIQUE (model_name, model_version)
);

-- [NEW v4] FDS ref: AI-PIP-001, AI-PIP-005
CREATE TABLE IF NOT EXISTS rims.pacs_ai_routing_rule (                         -- Rules sending eligible studies to AI models
    ai_routing_rule_id         INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    ai_model_id                INT NOT NULL,
    conditions_json            JSONB NOT NULL,                                 -- modality, body part, protocol, priority
    allow_triage_priority_raise BOOLEAN NOT NULL DEFAULT FALSE,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: AI-PIP-004, AI-PIP-006
CREATE TABLE IF NOT EXISTS rims.pacs_ai_job (                                  -- AI processing job per study (queued, running, completed, failed)
    ai_job_id                  BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    dicom_study_id             BIGINT NOT NULL,
    ai_model_id                INT NOT NULL,
    queued_at                  TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    started_at                 TIMESTAMPTZ(0) NULL,
    completed_at               TIMESTAMPTZ(0) NULL,
    job_status                 VARCHAR(20) NOT NULL DEFAULT 'QUEUED',
    error_message              VARCHAR(1000) NULL,
    priority_raised            BOOLEAN NOT NULL DEFAULT FALSE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: AI-IMP-001..005, RAD-DIC-007
CREATE TABLE IF NOT EXISTS rims.pacs_ai_impression_draft (                     -- AI-generated draft findings / impression with final signed text and edits
    ai_impression_draft_id     BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    dicom_study_id             BIGINT NOT NULL,
    ai_model_id                INT NOT NULL,
    draft_text                 TEXT NOT NULL,
    source_links_json          JSONB NULL,                                     -- statement -> finding ids
    structured_score_json      JSONB NULL,                                     -- BI-RADS / Lung-RADS ...
    final_text                 TEXT NULL,
    edit_diff_json             JSONB NULL,
    reviewed_by                BIGINT NULL,
    reviewed_at                TIMESTAMPTZ(0) NULL,
    draft_status               VARCHAR(20) NOT NULL DEFAULT 'DRAFT',           -- DRAFT, ACCEPTED_WITH_EDITS, REJECTED
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] replica of patientengagement.sch_appointment, owned by Patient Access & Engagement; used by: rims.rad_study
CREATE TABLE IF NOT EXISTS rims.ref_appointment (
    appointment_id             BIGINT PRIMARY KEY,
    organization_id            INT NULL,
    branch_id                  INT NULL,
    appointment_no             VARCHAR(25) NULL,
    patient_id                 BIGINT NULL,
    provisional_name           VARCHAR(150) NULL,
    provisional_mobile         VARCHAR(15) NULL,
    appointment_type           VARCHAR(20) NULL,
    practitioner_id            BIGINT NULL,
    specialty_id               INT NULL,
    service_id                 INT NULL,
    slot_id                    BIGINT NULL,
    scheduled_start            TIMESTAMPTZ(0) NULL,
    scheduled_end              TIMESTAMPTZ(0) NULL,
    booking_channel            VARCHAR(20) NULL,
    booked_by_user_id          BIGINT NULL,
    appointment_status         VARCHAR(20) NULL,
    arrived_at                 TIMESTAMPTZ(0) NULL,
    is_late_arrival            BOOLEAN NULL,
    cancelled_at               TIMESTAMPTZ(0) NULL,
    cancel_reason              VARCHAR(300) NULL,
    rescheduled_from_id        BIGINT NULL,
    encounter_id               BIGINT NULL,
    prepaid_amount             DECIMAL(14,2) NULL,
    reminder_sent_at           TIMESTAMPTZ(0) NULL,
    notes                      VARCHAR(500) NULL,
    is_active                  BOOLEAN NULL,
    visit_type                 VARCHAR(20) NULL,                               -- NEW, FOLLOW_UP, REVIEW, TELECONSULT, ON_DEMAND
    is_any_doctor              BOOLEAN NULL,                                   -- specialty booking, doctor assigned later
    doctor_assigned_at         TIMESTAMPTZ(0) NULL,
    payer_type                 VARCHAR(20) NULL,                               -- SELF, CORPORATE, INSURANCE, SCHEME
    payment_status             VARCHAR(20) NULL,                               -- NOT_REQUIRED, PENDING, PAID, PAY_AT_COUNTER, REFUNDED
    payment_reference          VARCHAR(100) NULL,                              -- gateway txn / receipt no
    bill_id                    BIGINT NULL,
    cancel_reason_code         VARCHAR(30) NULL,
    cancelled_by_type          VARCHAR(20) NULL,                               -- PATIENT, STAFF, DOCTOR, HOSPITAL, SYSTEM
    cancelled_by_user_id       BIGINT NULL,
    is_late_cancellation       BOOLEAN NULL,
    no_show_marked_at          TIMESTAMPTZ(0) NULL,
    remote_checkin_at          TIMESTAMPTZ(0) NULL,
    checkin_channel            VARCHAR(20) NULL,                               -- COUNTER, KIOSK, APP, QR
    override_reason            VARCHAR(300) NULL,                              -- full-schedule override
    override_approved_by       BIGINT NULL,
    waitlist_id                BIGINT NULL,
    reschedule_count           SMALLINT NULL,
    followup_of_appointment_id BIGINT NULL,
    is_free_followup           BOOLEAN NULL,
    online_order_id            BIGINT NULL,
    session_code               VARCHAR(20) NULL,                               -- OPU-003 consultation session code
    tele_consent_id            BIGINT NULL,
    preparation_instructions   VARCHAR(1000) NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    source_version             BIGINT NULL,                                    -- version / sequence from publisher (ignore stale events)
    replicated_at              TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);


/* ---------- C. FOREIGN KEYS (same service only) ---------- */
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_mst_rad_procedure_modality_rad_procedure_id') THEN
        ALTER TABLE rims.mst_rad_procedure_modality ADD CONSTRAINT fk_mst_rad_procedure_modality_rad_procedure_id FOREIGN KEY (rad_procedure_id) REFERENCES rims.mst_rad_procedure(rad_procedure_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_mst_rad_procedure_modality_modality_id') THEN
        ALTER TABLE rims.mst_rad_procedure_modality ADD CONSTRAINT fk_mst_rad_procedure_modality_modality_id FOREIGN KEY (modality_id) REFERENCES rims.rad_modality(modality_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_rad_modality_downtime_modality_id') THEN
        ALTER TABLE rims.rad_modality_downtime ADD CONSTRAINT fk_rad_modality_downtime_modality_id FOREIGN KEY (modality_id) REFERENCES rims.rad_modality(modality_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_rad_study_checklist_study_id') THEN
        ALTER TABLE rims.rad_study_checklist ADD CONSTRAINT fk_rad_study_checklist_study_id FOREIGN KEY (study_id) REFERENCES rims.rad_study(study_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_rad_contrast_reaction_study_id') THEN
        ALTER TABLE rims.rad_contrast_reaction ADD CONSTRAINT fk_rad_contrast_reaction_study_id FOREIGN KEY (study_id) REFERENCES rims.rad_study(study_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_rad_exposure_reject_study_id') THEN
        ALTER TABLE rims.rad_exposure_reject ADD CONSTRAINT fk_rad_exposure_reject_study_id FOREIGN KEY (study_id) REFERENCES rims.rad_study(study_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_rad_pcpndt_form_f_study_id') THEN
        ALTER TABLE rims.rad_pcpndt_form_f ADD CONSTRAINT fk_rad_pcpndt_form_f_study_id FOREIGN KEY (study_id) REFERENCES rims.rad_study(study_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_rad_dictation_job_study_id') THEN
        ALTER TABLE rims.rad_dictation_job ADD CONSTRAINT fk_rad_dictation_job_study_id FOREIGN KEY (study_id) REFERENCES rims.rad_study(study_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_rad_dictation_job_rad_report_id') THEN
        ALTER TABLE rims.rad_dictation_job ADD CONSTRAINT fk_rad_dictation_job_rad_report_id FOREIGN KEY (rad_report_id) REFERENCES rims.rad_report(rad_report_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_rad_peer_review_rad_report_id') THEN
        ALTER TABLE rims.rad_peer_review ADD CONSTRAINT fk_rad_peer_review_rad_report_id FOREIGN KEY (rad_report_id) REFERENCES rims.rad_report(rad_report_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_rad_critical_finding_alert_rad_report_id') THEN
        ALTER TABLE rims.rad_critical_finding_alert ADD CONSTRAINT fk_rad_critical_finding_alert_rad_report_id FOREIGN KEY (rad_report_id) REFERENCES rims.rad_report(rad_report_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_rad_critical_finding_alert_study_id') THEN
        ALTER TABLE rims.rad_critical_finding_alert ADD CONSTRAINT fk_rad_critical_finding_alert_study_id FOREIGN KEY (study_id) REFERENCES rims.rad_study(study_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_rad_media_issue_study_id') THEN
        ALTER TABLE rims.rad_media_issue ADD CONSTRAINT fk_rad_media_issue_study_id FOREIGN KEY (study_id) REFERENCES rims.rad_study(study_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_dicom_instance_dicom_series_id') THEN
        ALTER TABLE rims.pacs_dicom_instance ADD CONSTRAINT fk_pacs_dicom_instance_dicom_series_id FOREIGN KEY (dicom_series_id) REFERENCES rims.pacs_dicom_series(dicom_series_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_ingestion_log_source_node_id') THEN
        ALTER TABLE rims.pacs_ingestion_log ADD CONSTRAINT fk_pacs_ingestion_log_source_node_id FOREIGN KEY (source_node_id) REFERENCES rims.pacs_dicom_node(dicom_node_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_quarantine_item_dicom_study_id') THEN
        ALTER TABLE rims.pacs_quarantine_item ADD CONSTRAINT fk_pacs_quarantine_item_dicom_study_id FOREIGN KEY (dicom_study_id) REFERENCES rims.pacs_dicom_study(dicom_study_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_quarantine_item_resolved_study_id') THEN
        ALTER TABLE rims.pacs_quarantine_item ADD CONSTRAINT fk_pacs_quarantine_item_resolved_study_id FOREIGN KEY (resolved_study_id) REFERENCES rims.rad_study(study_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_correction_log_dicom_study_id') THEN
        ALTER TABLE rims.pacs_correction_log ADD CONSTRAINT fk_pacs_correction_log_dicom_study_id FOREIGN KEY (dicom_study_id) REFERENCES rims.pacs_dicom_study(dicom_study_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_routing_rule_target_node_id') THEN
        ALTER TABLE rims.pacs_routing_rule ADD CONSTRAINT fk_pacs_routing_rule_target_node_id FOREIGN KEY (target_node_id) REFERENCES rims.pacs_dicom_node(dicom_node_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_routing_rule_deid_profile_id') THEN
        ALTER TABLE rims.pacs_routing_rule ADD CONSTRAINT fk_pacs_routing_rule_deid_profile_id FOREIGN KEY (deid_profile_id) REFERENCES rims.pacs_deid_profile(deid_profile_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_routing_job_routing_rule_id') THEN
        ALTER TABLE rims.pacs_routing_job ADD CONSTRAINT fk_pacs_routing_job_routing_rule_id FOREIGN KEY (routing_rule_id) REFERENCES rims.pacs_routing_rule(routing_rule_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_routing_job_target_node_id') THEN
        ALTER TABLE rims.pacs_routing_job ADD CONSTRAINT fk_pacs_routing_job_target_node_id FOREIGN KEY (target_node_id) REFERENCES rims.pacs_dicom_node(dicom_node_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_routing_job_dicom_study_id') THEN
        ALTER TABLE rims.pacs_routing_job ADD CONSTRAINT fk_pacs_routing_job_dicom_study_id FOREIGN KEY (dicom_study_id) REFERENCES rims.pacs_dicom_study(dicom_study_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_print_job_printer_node_id') THEN
        ALTER TABLE rims.pacs_print_job ADD CONSTRAINT fk_pacs_print_job_printer_node_id FOREIGN KEY (printer_node_id) REFERENCES rims.pacs_dicom_node(dicom_node_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_print_job_dicom_study_id') THEN
        ALTER TABLE rims.pacs_print_job ADD CONSTRAINT fk_pacs_print_job_dicom_study_id FOREIGN KEY (dicom_study_id) REFERENCES rims.pacs_dicom_study(dicom_study_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_worklist_event_dicom_study_id') THEN
        ALTER TABLE rims.pacs_worklist_event ADD CONSTRAINT fk_pacs_worklist_event_dicom_study_id FOREIGN KEY (dicom_study_id) REFERENCES rims.pacs_dicom_study(dicom_study_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_worklist_event_rad_study_id') THEN
        ALTER TABLE rims.pacs_worklist_event ADD CONSTRAINT fk_pacs_worklist_event_rad_study_id FOREIGN KEY (rad_study_id) REFERENCES rims.rad_study(study_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_worklist_event_reading_assignment_id') THEN
        ALTER TABLE rims.pacs_worklist_event ADD CONSTRAINT fk_pacs_worklist_event_reading_assignment_id FOREIGN KEY (reading_assignment_id) REFERENCES rims.pacs_reading_assignment(reading_assignment_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_study_comment_dicom_study_id') THEN
        ALTER TABLE rims.pacs_study_comment ADD CONSTRAINT fk_pacs_study_comment_dicom_study_id FOREIGN KEY (dicom_study_id) REFERENCES rims.pacs_dicom_study(dicom_study_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_share_link_access_share_link_id') THEN
        ALTER TABLE rims.pacs_share_link_access ADD CONSTRAINT fk_pacs_share_link_access_share_link_id FOREIGN KEY (share_link_id) REFERENCES rims.pacs_share_link(share_link_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_access_audit_dicom_study_id') THEN
        ALTER TABLE rims.pacs_access_audit ADD CONSTRAINT fk_pacs_access_audit_dicom_study_id FOREIGN KEY (dicom_study_id) REFERENCES rims.pacs_dicom_study(dicom_study_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_ai_routing_rule_ai_model_id') THEN
        ALTER TABLE rims.pacs_ai_routing_rule ADD CONSTRAINT fk_pacs_ai_routing_rule_ai_model_id FOREIGN KEY (ai_model_id) REFERENCES rims.pacs_ai_model(ai_model_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_ai_job_dicom_study_id') THEN
        ALTER TABLE rims.pacs_ai_job ADD CONSTRAINT fk_pacs_ai_job_dicom_study_id FOREIGN KEY (dicom_study_id) REFERENCES rims.pacs_dicom_study(dicom_study_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_ai_job_ai_model_id') THEN
        ALTER TABLE rims.pacs_ai_job ADD CONSTRAINT fk_pacs_ai_job_ai_model_id FOREIGN KEY (ai_model_id) REFERENCES rims.pacs_ai_model(ai_model_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_ai_impression_draft_dicom_study_id') THEN
        ALTER TABLE rims.pacs_ai_impression_draft ADD CONSTRAINT fk_pacs_ai_impression_draft_dicom_study_id FOREIGN KEY (dicom_study_id) REFERENCES rims.pacs_dicom_study(dicom_study_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_ai_impression_draft_ai_model_id') THEN
        ALTER TABLE rims.pacs_ai_impression_draft ADD CONSTRAINT fk_pacs_ai_impression_draft_ai_model_id FOREIGN KEY (ai_model_id) REFERENCES rims.pacs_ai_model(ai_model_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_ai_finding_ai_model_id') THEN
        ALTER TABLE rims.pacs_ai_finding ADD CONSTRAINT fk_pacs_ai_finding_ai_model_id FOREIGN KEY (ai_model_id) REFERENCES rims.pacs_ai_model(ai_model_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_pacs_ai_finding_ai_model_id ON rims.pacs_ai_finding(ai_model_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_ai_finding_ai_job_id') THEN
        ALTER TABLE rims.pacs_ai_finding ADD CONSTRAINT fk_pacs_ai_finding_ai_job_id FOREIGN KEY (ai_job_id) REFERENCES rims.pacs_ai_job(ai_job_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_pacs_ai_finding_ai_job_id ON rims.pacs_ai_finding(ai_job_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_ai_finding_prior_ai_finding_id') THEN
        ALTER TABLE rims.pacs_ai_finding ADD CONSTRAINT fk_pacs_ai_finding_prior_ai_finding_id FOREIGN KEY (prior_ai_finding_id) REFERENCES rims.pacs_ai_finding(ai_finding_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_pacs_ai_finding_prior_ai_finding_id ON rims.pacs_ai_finding(prior_ai_finding_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_annotation_ai_finding_id') THEN
        ALTER TABLE rims.pacs_annotation ADD CONSTRAINT fk_pacs_annotation_ai_finding_id FOREIGN KEY (ai_finding_id) REFERENCES rims.pacs_ai_finding(ai_finding_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_pacs_annotation_ai_finding_id ON rims.pacs_annotation(ai_finding_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_dicom_node_modality_id') THEN
        ALTER TABLE rims.pacs_dicom_node ADD CONSTRAINT fk_pacs_dicom_node_modality_id FOREIGN KEY (modality_id) REFERENCES rims.rad_modality(modality_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_pacs_dicom_node_modality_id ON rims.pacs_dicom_node(modality_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_dicom_study_storage_policy_id') THEN
        ALTER TABLE rims.pacs_dicom_study ADD CONSTRAINT fk_pacs_dicom_study_storage_policy_id FOREIGN KEY (storage_policy_id) REFERENCES rims.pacs_storage_policy(storage_policy_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_pacs_dicom_study_storage_policy_id ON rims.pacs_dicom_study(storage_policy_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_dicom_study_merged_into_dicom_study_id') THEN
        ALTER TABLE rims.pacs_dicom_study ADD CONSTRAINT fk_pacs_dicom_study_merged_into_dicom_study_id FOREIGN KEY (merged_into_dicom_study_id) REFERENCES rims.pacs_dicom_study(dicom_study_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_pacs_dicom_study_merged_into_dicom_study_id ON rims.pacs_dicom_study(merged_into_dicom_study_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_reading_assignment_distribution_rule_id') THEN
        ALTER TABLE rims.pacs_reading_assignment ADD CONSTRAINT fk_pacs_reading_assignment_distribution_rule_id FOREIGN KEY (distribution_rule_id) REFERENCES rims.pacs_distribution_rule(distribution_rule_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_pacs_reading_assignment_distribution_rule_id ON rims.pacs_reading_assignment(distribution_rule_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_pacs_reading_assignment_reassigned_from_id') THEN
        ALTER TABLE rims.pacs_reading_assignment ADD CONSTRAINT fk_pacs_reading_assignment_reassigned_from_id FOREIGN KEY (reassigned_from_id) REFERENCES rims.pacs_reading_assignment(reading_assignment_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_pacs_reading_assignment_reassigned_from_id ON rims.pacs_reading_assignment(reassigned_from_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_rad_modality_dicom_node_id') THEN
        ALTER TABLE rims.rad_modality ADD CONSTRAINT fk_rad_modality_dicom_node_id FOREIGN KEY (dicom_node_id) REFERENCES rims.pacs_dicom_node(dicom_node_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_rad_modality_dicom_node_id ON rims.rad_modality(dicom_node_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_rad_report_parent_rad_report_id') THEN
        ALTER TABLE rims.rad_report ADD CONSTRAINT fk_rad_report_parent_rad_report_id FOREIGN KEY (parent_rad_report_id) REFERENCES rims.rad_report(rad_report_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_rad_report_parent_rad_report_id ON rims.rad_report(parent_rad_report_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_rad_report_ai_impression_draft_id') THEN
        ALTER TABLE rims.rad_report ADD CONSTRAINT fk_rad_report_ai_impression_draft_id FOREIGN KEY (ai_impression_draft_id) REFERENCES rims.pacs_ai_impression_draft(ai_impression_draft_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_rad_report_ai_impression_draft_id ON rims.rad_report(ai_impression_draft_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'rims' AND c.conname = 'fk_rad_study_contrast_reaction_id') THEN
        ALTER TABLE rims.rad_study ADD CONSTRAINT fk_rad_study_contrast_reaction_id FOREIGN KEY (contrast_reaction_id) REFERENCES rims.rad_contrast_reaction(contrast_reaction_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_rad_study_contrast_reaction_id ON rims.rad_study(contrast_reaction_id);

/* ---------- D. INDEXES ---------- */
CREATE INDEX IF NOT EXISTS ix_mst_rad_procedure_modality_modality_id ON rims.mst_rad_procedure_modality(modality_id);
CREATE INDEX IF NOT EXISTS ix_rad_modality_downtime_modality_id ON rims.rad_modality_downtime(modality_id);
CREATE INDEX IF NOT EXISTS ix_rad_study_checklist_study_id ON rims.rad_study_checklist(study_id);
CREATE INDEX IF NOT EXISTS ix_rad_contrast_reaction_study_id ON rims.rad_contrast_reaction(study_id);
CREATE INDEX IF NOT EXISTS ix_rad_contrast_reaction_patient_id ON rims.rad_contrast_reaction(patient_id);
CREATE INDEX IF NOT EXISTS ix_rad_exposure_reject_study_id ON rims.rad_exposure_reject(study_id);
CREATE INDEX IF NOT EXISTS ix_rad_pcpndt_form_f_study_id ON rims.rad_pcpndt_form_f(study_id);
CREATE INDEX IF NOT EXISTS ix_rad_pcpndt_form_f_patient_id ON rims.rad_pcpndt_form_f(patient_id);
CREATE INDEX IF NOT EXISTS ix_rad_dictation_job_study_id ON rims.rad_dictation_job(study_id);
CREATE INDEX IF NOT EXISTS ix_rad_dictation_job_rad_report_id ON rims.rad_dictation_job(rad_report_id);
CREATE INDEX IF NOT EXISTS ix_rad_peer_review_rad_report_id ON rims.rad_peer_review(rad_report_id);
CREATE INDEX IF NOT EXISTS ix_rad_critical_finding_alert_rad_report_id ON rims.rad_critical_finding_alert(rad_report_id);
CREATE INDEX IF NOT EXISTS ix_rad_critical_finding_alert_study_id ON rims.rad_critical_finding_alert(study_id);
CREATE INDEX IF NOT EXISTS ix_rad_media_issue_study_id ON rims.rad_media_issue(study_id);
CREATE INDEX IF NOT EXISTS ix_pacs_dicom_instance_dicom_series_id ON rims.pacs_dicom_instance(dicom_series_id);
CREATE INDEX IF NOT EXISTS ix_pacs_ingestion_log_source_node_id ON rims.pacs_ingestion_log(source_node_id);
CREATE INDEX IF NOT EXISTS ix_pacs_quarantine_item_dicom_study_id ON rims.pacs_quarantine_item(dicom_study_id);
CREATE INDEX IF NOT EXISTS ix_pacs_quarantine_item_resolved_study_id ON rims.pacs_quarantine_item(resolved_study_id);
CREATE INDEX IF NOT EXISTS ix_pacs_correction_log_dicom_study_id ON rims.pacs_correction_log(dicom_study_id);
CREATE INDEX IF NOT EXISTS ix_pacs_routing_rule_target_node_id ON rims.pacs_routing_rule(target_node_id);
CREATE INDEX IF NOT EXISTS ix_pacs_routing_rule_deid_profile_id ON rims.pacs_routing_rule(deid_profile_id);
CREATE INDEX IF NOT EXISTS ix_pacs_routing_job_routing_rule_id ON rims.pacs_routing_job(routing_rule_id);
CREATE INDEX IF NOT EXISTS ix_pacs_routing_job_target_node_id ON rims.pacs_routing_job(target_node_id);
CREATE INDEX IF NOT EXISTS ix_pacs_routing_job_dicom_study_id ON rims.pacs_routing_job(dicom_study_id);
CREATE INDEX IF NOT EXISTS ix_pacs_print_job_printer_node_id ON rims.pacs_print_job(printer_node_id);
CREATE INDEX IF NOT EXISTS ix_pacs_print_job_dicom_study_id ON rims.pacs_print_job(dicom_study_id);
CREATE INDEX IF NOT EXISTS ix_pacs_worklist_event_dicom_study_id ON rims.pacs_worklist_event(dicom_study_id);
CREATE INDEX IF NOT EXISTS ix_pacs_worklist_event_rad_study_id ON rims.pacs_worklist_event(rad_study_id);
CREATE INDEX IF NOT EXISTS ix_pacs_worklist_event_reading_assignment_id ON rims.pacs_worklist_event(reading_assignment_id);
CREATE INDEX IF NOT EXISTS ix_pacs_study_comment_dicom_study_id ON rims.pacs_study_comment(dicom_study_id);
CREATE INDEX IF NOT EXISTS ix_pacs_share_link_access_share_link_id ON rims.pacs_share_link_access(share_link_id);
CREATE INDEX IF NOT EXISTS ix_pacs_access_audit_dicom_study_id ON rims.pacs_access_audit(dicom_study_id);
CREATE INDEX IF NOT EXISTS ix_pacs_ai_routing_rule_ai_model_id ON rims.pacs_ai_routing_rule(ai_model_id);
CREATE INDEX IF NOT EXISTS ix_pacs_ai_job_dicom_study_id ON rims.pacs_ai_job(dicom_study_id);
CREATE INDEX IF NOT EXISTS ix_pacs_ai_job_ai_model_id ON rims.pacs_ai_job(ai_model_id);
CREATE INDEX IF NOT EXISTS ix_pacs_ai_impression_draft_dicom_study_id ON rims.pacs_ai_impression_draft(dicom_study_id);
CREATE INDEX IF NOT EXISTS ix_pacs_ai_impression_draft_ai_model_id ON rims.pacs_ai_impression_draft(ai_model_id);

/* ---------- E. TABLE COMMENTS (FDS traceability) ---------- */
COMMENT ON TABLE rims.mst_rad_procedure_modality IS 'Procedure-to-modality mapping (which machines can perform a procedure) [FDS: RAD-MST-005]';
COMMENT ON TABLE rims.rad_modality_downtime IS 'Modality downtime with affected appointments rescheduled [FDS: RAD-SCH-003, RAD-SCH-006]';
COMMENT ON TABLE rims.rad_study_checklist IS 'Pre-procedure checklist responses by modality (pregnancy, implants, MRI safety, allergy, renal function) [FDS: RAD-TEC-002, RAD-SCH-013, RAD-CON-003]';
COMMENT ON TABLE rims.rad_contrast_reaction IS 'Contrast reactions (type, severity, treatment) - also updates patient allergy [FDS: RAD-CON-002, RAD-CON-005]';
COMMENT ON TABLE rims.rad_exposure_reject IS 'Repeated / rejected exposures with reason (image quality analysis) [FDS: RAD-TEC-008]';
COMMENT ON TABLE rims.rad_pcpndt_form_f IS 'PC-PNDT Form F for obstetric ultrasound [FDS: RAD-TEC-004]';
COMMENT ON TABLE rims.rad_macro IS 'Radiology macros / quick text for normal findings [FDS: RAD-STR-005]';
COMMENT ON TABLE rims.rad_dictation_job IS 'Radiology dictation audio routed to transcription queue [FDS: RAD-DIC-005, RAD-DIC-006]';
COMMENT ON TABLE rims.rad_peer_review IS 'Second reading / peer review / discrepancy outcome [FDS: RAD-WRK-009, TEL-010]';
COMMENT ON TABLE rims.rad_critical_finding_alert IS 'Critical finding notifications with read-back and escalation [FDS: RAD-CRT-001..005, TRK-007]';
COMMENT ON TABLE rims.rad_media_issue IS 'Film / CD / DVD issue with embedded viewer [FDS: RAD-RPT-008, SHR-012]';
COMMENT ON TABLE rims.pacs_dicom_instance IS 'DICOM instance index (SOP Instance UID, transfer syntax, checksum, object type) [FDS: STO-001, STO-002, STO-007, STO-010]';
COMMENT ON TABLE rims.pacs_ingestion_log IS 'Ingestion events (C-STORE / STOW-RS / manual import) with result [FDS: DCM-ING-001..013]';
COMMENT ON TABLE rims.pacs_quarantine_item IS 'Non-conforming / duplicate objects held for review and reconciliation queue for unmatched studies [FDS: DCM-ING-007..009, RAD-PAC-002]';
COMMENT ON TABLE rims.pacs_correction_log IS 'Patient / study merge, split and demographic corrections with original values [FDS: STO-008, VWR-CMP-005]';
COMMENT ON TABLE rims.pacs_routing_rule IS 'Auto-routing rules on study arrival (conditions -> target node) [FDS: DCM-RTE-002, DCM-RTE-005, DCM-RTE-007 (Routing rule entity)]';
COMMENT ON TABLE rims.pacs_deid_profile IS 'De-identification profiles for routing / sharing / AI [FDS: DCM-RTE-007, SHR-007, AI-GOV-003]';
COMMENT ON TABLE rims.pacs_routing_job IS 'Routing / forward / retrieve jobs with retry and status [FDS: DCM-RTE-003..008 (Routing job entity)]';
COMMENT ON TABLE rims.pacs_print_job IS 'DICOM print queue [FDS: DCM-PRT-001..007 (Print job entity)]';
COMMENT ON TABLE rims.pacs_storage_policy IS 'Storage tier, compression, retention, legal hold and migration rules [FDS: STO-003..006 (Storage policy entity)]';
COMMENT ON TABLE rims.pacs_hanging_protocol IS 'Hanging protocols by modality, body part and user [FDS: VWR-GEN-004]';
COMMENT ON TABLE rims.pacs_user_viewer_pref IS 'Per-user viewer preferences, keyboard shortcuts and saved worklist filters [FDS: VWR-GEN-008, TEL-007]';
COMMENT ON TABLE rims.pacs_distribution_rule IS 'Worklist distribution rules (round-robin, load, subspecialty, site, credential, shift) [FDS: TEL-002, RAD-WRK-002/003]';
COMMENT ON TABLE rims.pacs_radiologist_shift IS 'Radiologist availability and shift calendar for routing [FDS: TEL-006]';
COMMENT ON TABLE rims.pacs_worklist_event IS 'Time-stamped history of status changes, assignments and user actions [FDS: TRK-002, TRK-003]';
COMMENT ON TABLE rims.pacs_study_comment IS 'Study-linked channel between referring site and radiologist (comments, call-back) [FDS: TEL-012]';
COMMENT ON TABLE rims.pacs_share_link_access IS 'Share-link access log (time, IP, device, downloads) [FDS: SHR-008, SHR-011]';
COMMENT ON TABLE rims.pacs_access_audit IS 'Viewer audit: study open, export, print, annotate (user, time, IP) [FDS: VWR-SEC-002 (Audit event entity)]';
COMMENT ON TABLE rims.pacs_ai_model IS 'AI model registry (vendor, version, intended use, regulatory status, thresholds) [FDS: AI-PIP-002, AI-TMR-006, AI-GOV-001/002]';
COMMENT ON TABLE rims.pacs_ai_routing_rule IS 'Rules sending eligible studies to AI models [FDS: AI-PIP-001, AI-PIP-005]';
COMMENT ON TABLE rims.pacs_ai_job IS 'AI processing job per study (queued, running, completed, failed) [FDS: AI-PIP-004, AI-PIP-006]';
COMMENT ON TABLE rims.pacs_ai_impression_draft IS 'AI-generated draft findings / impression with final signed text and edits [FDS: AI-IMP-001..005, RAD-DIC-007]';

COMMIT;
