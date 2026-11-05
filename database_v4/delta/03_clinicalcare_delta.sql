/* =====================================================================================
   DR REDDIS HEALTHCARE - HIMS  database_v3 (7 services)  ->  database_v4 (9 services)
   Step 03 - Clinical Care: column additions to existing tables + new FDS tables
   Run against an EXISTING himsdev database that was built from database_v3, in file-name order:
     00_restructure_7_to_9_services.sql  -> 01..09_<service>_delta.sql  -> 10_post_migration_housekeeping.sql -> ../full/roles.sql
   Every statement is idempotent where PostgreSQL allows it (IF NOT EXISTS / guarded DO blocks).
   ===================================================================================== */

BEGIN;

/* ---------- A. MODIFICATIONS TO EXISTING TABLES (ADD COLUMN) ---------- */

-- clinicalcare.emr_allergy  (6 new columns)  FDS: HIS-004, ALG-001..004 (allergy & intolerance)
ALTER TABLE clinicalcare.emr_allergy ADD COLUMN IF NOT EXISTS certainty VARCHAR(20) NULL;
ALTER TABLE clinicalcare.emr_allergy ADD COLUMN IF NOT EXISTS onset_date DATE NULL;
ALTER TABLE clinicalcare.emr_allergy ADD COLUMN IF NOT EXISTS source VARCHAR(20) NULL;
ALTER TABLE clinicalcare.emr_allergy ADD COLUMN IF NOT EXISTS is_intolerance BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE clinicalcare.emr_allergy ADD COLUMN IF NOT EXISTS cross_reactive_class VARCHAR(100) NULL;
ALTER TABLE clinicalcare.emr_allergy ADD COLUMN IF NOT EXISTS entered_in_error BOOLEAN NULL DEFAULT FALSE;
COMMENT ON COLUMN clinicalcare.emr_allergy.certainty IS 'CONFIRMED, SUSPECTED, REFUTED [v4: HIS-004, ALG-001..004 (allergy & intolerance)]';
COMMENT ON COLUMN clinicalcare.emr_allergy.onset_date IS '[v4: HIS-004, ALG-001..004 (allergy & intolerance)]';
COMMENT ON COLUMN clinicalcare.emr_allergy.source IS 'PATIENT, RELATIVE, RECORDS, OBSERVED, ABDM [v4: HIS-004, ALG-001..004 (allergy & intolerance)]';
COMMENT ON COLUMN clinicalcare.emr_allergy.is_intolerance IS '[v4: HIS-004, ALG-001..004 (allergy & intolerance)]';
COMMENT ON COLUMN clinicalcare.emr_allergy.cross_reactive_class IS '[v4: HIS-004, ALG-001..004 (allergy & intolerance)]';
COMMENT ON COLUMN clinicalcare.emr_allergy.entered_in_error IS '[v4: HIS-004, ALG-001..004 (allergy & intolerance)]';

-- clinicalcare.emr_care_plan  (5 new columns)  FDS: CPL-001..004 (Care plan entity)
ALTER TABLE clinicalcare.emr_care_plan ADD COLUMN IF NOT EXISTS template_id INT NULL;
ALTER TABLE clinicalcare.emr_care_plan ADD COLUMN IF NOT EXISTS care_team_json JSONB NULL;
ALTER TABLE clinicalcare.emr_care_plan ADD COLUMN IF NOT EXISTS review_due_at DATE NULL;
ALTER TABLE clinicalcare.emr_care_plan ADD COLUMN IF NOT EXISTS shared_with_patient_at TIMESTAMPTZ(0) NULL;
ALTER TABLE clinicalcare.emr_care_plan ADD COLUMN IF NOT EXISTS patient_summary_text TEXT NULL;
COMMENT ON COLUMN clinicalcare.emr_care_plan.template_id IS '[v4: CPL-001..004 (Care plan entity)]';
COMMENT ON COLUMN clinicalcare.emr_care_plan.care_team_json IS '[v4: CPL-001..004 (Care plan entity)]';
COMMENT ON COLUMN clinicalcare.emr_care_plan.review_due_at IS '[v4: CPL-001..004 (Care plan entity)]';
COMMENT ON COLUMN clinicalcare.emr_care_plan.shared_with_patient_at IS '[v4: CPL-001..004 (Care plan entity)]';
COMMENT ON COLUMN clinicalcare.emr_care_plan.patient_summary_text IS '[v4: CPL-001..004 (Care plan entity)]';

-- clinicalcare.emr_care_plan_activity  (5 new columns)  FDS: CPL-001, CPL-003
ALTER TABLE clinicalcare.emr_care_plan_activity ADD COLUMN IF NOT EXISTS care_plan_goal_id BIGINT NULL;
ALTER TABLE clinicalcare.emr_care_plan_activity ADD COLUMN IF NOT EXISTS activity_type VARCHAR(20) NULL;
ALTER TABLE clinicalcare.emr_care_plan_activity ADD COLUMN IF NOT EXISTS due_at TIMESTAMPTZ(0) NULL;
ALTER TABLE clinicalcare.emr_care_plan_activity ADD COLUMN IF NOT EXISTS assigned_to VARCHAR(20) NULL;
ALTER TABLE clinicalcare.emr_care_plan_activity ADD COLUMN IF NOT EXISTS reminder_sent_at TIMESTAMPTZ(0) NULL;
COMMENT ON COLUMN clinicalcare.emr_care_plan_activity.care_plan_goal_id IS '[v4: CPL-001, CPL-003]';
COMMENT ON COLUMN clinicalcare.emr_care_plan_activity.activity_type IS 'MEDICATION, TEST, EDUCATION, LIFESTYLE, REVIEW, AYUSH_THERAPY [v4: CPL-001, CPL-003]';
COMMENT ON COLUMN clinicalcare.emr_care_plan_activity.due_at IS '[v4: CPL-001, CPL-003]';
COMMENT ON COLUMN clinicalcare.emr_care_plan_activity.assigned_to IS 'CLINICIAN, PATIENT, NURSE [v4: CPL-001, CPL-003]';
COMMENT ON COLUMN clinicalcare.emr_care_plan_activity.reminder_sent_at IS '[v4: CPL-001, CPL-003]';

-- clinicalcare.emr_clinical_document  (19 new columns)  FDS: DOC-001..008, CNS-003, CNS-007, DIT-001..006, MRV-008 (Clinical document entity)
ALTER TABLE clinicalcare.emr_clinical_document ADD COLUMN IF NOT EXISTS system_of_medicine VARCHAR(20) NULL DEFAULT 'ALLOPATHY';
ALTER TABLE clinicalcare.emr_clinical_document ADD COLUMN IF NOT EXISTS template_version SMALLINT NULL;
ALTER TABLE clinicalcare.emr_clinical_document ADD COLUMN IF NOT EXISTS parent_document_id BIGINT NULL;
ALTER TABLE clinicalcare.emr_clinical_document ADD COLUMN IF NOT EXISTS is_addendum BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE clinicalcare.emr_clinical_document ADD COLUMN IF NOT EXISTS amendment_reason VARCHAR(500) NULL;
ALTER TABLE clinicalcare.emr_clinical_document ADD COLUMN IF NOT EXISTS copied_from_document_id BIGINT NULL;
ALTER TABLE clinicalcare.emr_clinical_document ADD COLUMN IF NOT EXISTS cosign_required BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE clinicalcare.emr_clinical_document ADD COLUMN IF NOT EXISTS cosign_due_at TIMESTAMPTZ(0) NULL;
ALTER TABLE clinicalcare.emr_clinical_document ADD COLUMN IF NOT EXISTS cosigned_by BIGINT NULL;
ALTER TABLE clinicalcare.emr_clinical_document ADD COLUMN IF NOT EXISTS cosigned_at TIMESTAMPTZ(0) NULL;
ALTER TABLE clinicalcare.emr_clinical_document ADD COLUMN IF NOT EXISTS signer_registration_no VARCHAR(50) NULL;
ALTER TABLE clinicalcare.emr_clinical_document ADD COLUMN IF NOT EXISTS signature_method VARCHAR(20) NULL;
ALTER TABLE clinicalcare.emr_clinical_document ADD COLUMN IF NOT EXISTS digital_signature_ref VARCHAR(200) NULL;
ALTER TABLE clinicalcare.emr_clinical_document ADD COLUMN IF NOT EXISTS preliminary_at TIMESTAMPTZ(0) NULL;
ALTER TABLE clinicalcare.emr_clinical_document ADD COLUMN IF NOT EXISTS entered_in_error_reason VARCHAR(300) NULL;
ALTER TABLE clinicalcare.emr_clinical_document ADD COLUMN IF NOT EXISTS report_letterhead_id INT NULL;
ALTER TABLE clinicalcare.emr_clinical_document ADD COLUMN IF NOT EXISTS low_confidence_words_json JSONB NULL;
ALTER TABLE clinicalcare.emr_clinical_document ADD COLUMN IF NOT EXISTS is_sensitive BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE clinicalcare.emr_clinical_document ADD COLUMN IF NOT EXISTS sensitive_category VARCHAR(30) NULL;
COMMENT ON COLUMN clinicalcare.emr_clinical_document.system_of_medicine IS '[v4: DOC-001..008, CNS-003, CNS-007, DIT-001..006, MRV-008 (Clinical document entity)]';
COMMENT ON COLUMN clinicalcare.emr_clinical_document.template_version IS '[v4: DOC-001..008, CNS-003, CNS-007, DIT-001..006, MRV-008 (Clinical document entity)]';
COMMENT ON COLUMN clinicalcare.emr_clinical_document.parent_document_id IS 'addendum -> original [v4: DOC-001..008, CNS-003, CNS-007, DIT-001..006, MRV-008 (Clinical document entity)]';
COMMENT ON COLUMN clinicalcare.emr_clinical_document.is_addendum IS '[v4: DOC-001..008, CNS-003, CNS-007, DIT-001..006, MRV-008 (Clinical document entity)]';
COMMENT ON COLUMN clinicalcare.emr_clinical_document.amendment_reason IS '[v4: DOC-001..008, CNS-003, CNS-007, DIT-001..006, MRV-008 (Clinical document entity)]';
COMMENT ON COLUMN clinicalcare.emr_clinical_document.copied_from_document_id IS 'copy-forward (CNS-003) [v4: DOC-001..008, CNS-003, CNS-007, DIT-001..006, MRV-008 (Clinical document entity)]';
COMMENT ON COLUMN clinicalcare.emr_clinical_document.cosign_required IS '[v4: DOC-001..008, CNS-003, CNS-007, DIT-001..006, MRV-008 (Clinical document entity)]';
COMMENT ON COLUMN clinicalcare.emr_clinical_document.cosign_due_at IS '[v4: DOC-001..008, CNS-003, CNS-007, DIT-001..006, MRV-008 (Clinical document entity)]';
COMMENT ON COLUMN clinicalcare.emr_clinical_document.cosigned_by IS '[v4: DOC-001..008, CNS-003, CNS-007, DIT-001..006, MRV-008 (Clinical document entity)]';
COMMENT ON COLUMN clinicalcare.emr_clinical_document.cosigned_at IS '[v4: DOC-001..008, CNS-003, CNS-007, DIT-001..006, MRV-008 (Clinical document entity)]';
COMMENT ON COLUMN clinicalcare.emr_clinical_document.signer_registration_no IS '[v4: DOC-001..008, CNS-003, CNS-007, DIT-001..006, MRV-008 (Clinical document entity)]';
COMMENT ON COLUMN clinicalcare.emr_clinical_document.signature_method IS 'PASSWORD_REAUTH, DSC, ESIGN_AADHAAR [v4: DOC-001..008, CNS-003, CNS-007, DIT-001..006, MRV-008 (Clinical document entity)]';
COMMENT ON COLUMN clinicalcare.emr_clinical_document.digital_signature_ref IS '[v4: DOC-001..008, CNS-003, CNS-007, DIT-001..006, MRV-008 (Clinical document entity)]';
COMMENT ON COLUMN clinicalcare.emr_clinical_document.preliminary_at IS '[v4: DOC-001..008, CNS-003, CNS-007, DIT-001..006, MRV-008 (Clinical document entity)]';
COMMENT ON COLUMN clinicalcare.emr_clinical_document.entered_in_error_reason IS '[v4: DOC-001..008, CNS-003, CNS-007, DIT-001..006, MRV-008 (Clinical document entity)]';
COMMENT ON COLUMN clinicalcare.emr_clinical_document.report_letterhead_id IS 'logical FK -> integrationcomms.mst_report_letterhead [Integration & Communications] [v4: DOC-001..008, CNS-003, CNS-007, DIT-001..006, MRV-008 (Clinical document entity)]';
COMMENT ON COLUMN clinicalcare.emr_clinical_document.low_confidence_words_json IS 'VTX-003 voice-to-text review [v4: DOC-001..008, CNS-003, CNS-007, DIT-001..006, MRV-008 (Clinical document entity)]';
COMMENT ON COLUMN clinicalcare.emr_clinical_document.is_sensitive IS '[v4: DOC-001..008, CNS-003, CNS-007, DIT-001..006, MRV-008 (Clinical document entity)]';
COMMENT ON COLUMN clinicalcare.emr_clinical_document.sensitive_category IS 'PSYCHIATRY, HIV, SEXUAL_HEALTH, GENETICS, MLC [v4: DOC-001..008, CNS-003, CNS-007, DIT-001..006, MRV-008 (Clinical document entity)]';

-- clinicalcare.emr_complaint  (11 new columns)  FDS: SUB-001..004, HIS-006 (Symptoms and chief complaints)
ALTER TABLE clinicalcare.emr_complaint ADD COLUMN IF NOT EXISTS onset_type VARCHAR(20) NULL;
ALTER TABLE clinicalcare.emr_complaint ADD COLUMN IF NOT EXISTS onset_pattern VARCHAR(30) NULL;
ALTER TABLE clinicalcare.emr_complaint ADD COLUMN IF NOT EXISTS progression VARCHAR(30) NULL;
ALTER TABLE clinicalcare.emr_complaint ADD COLUMN IF NOT EXISTS patient_own_words VARCHAR(1000) NULL;
ALTER TABLE clinicalcare.emr_complaint ADD COLUMN IF NOT EXISTS frequency VARCHAR(50) NULL;
ALTER TABLE clinicalcare.emr_complaint ADD COLUMN IF NOT EXISTS aggravating_factors VARCHAR(300) NULL;
ALTER TABLE clinicalcare.emr_complaint ADD COLUMN IF NOT EXISTS relieving_factors VARCHAR(300) NULL;
ALTER TABLE clinicalcare.emr_complaint ADD COLUMN IF NOT EXISTS associated_symptoms VARCHAR(300) NULL;
ALTER TABLE clinicalcare.emr_complaint ADD COLUMN IF NOT EXISTS code_system_id INT NULL;
ALTER TABLE clinicalcare.emr_complaint ADD COLUMN IF NOT EXISTS captured_source VARCHAR(20) NULL;
ALTER TABLE clinicalcare.emr_complaint ADD COLUMN IF NOT EXISTS is_confirmed BOOLEAN NULL DEFAULT TRUE;
COMMENT ON COLUMN clinicalcare.emr_complaint.onset_type IS 'SUDDEN, GRADUAL [v4: SUB-001..004, HIS-006 (Symptoms and chief complaints)]';
COMMENT ON COLUMN clinicalcare.emr_complaint.onset_pattern IS '[v4: SUB-001..004, HIS-006 (Symptoms and chief complaints)]';
COMMENT ON COLUMN clinicalcare.emr_complaint.progression IS 'IMPROVING, WORSENING, STATIC [v4: SUB-001..004, HIS-006 (Symptoms and chief complaints)]';
COMMENT ON COLUMN clinicalcare.emr_complaint.patient_own_words IS '[v4: SUB-001..004, HIS-006 (Symptoms and chief complaints)]';
COMMENT ON COLUMN clinicalcare.emr_complaint.frequency IS '[v4: SUB-001..004, HIS-006 (Symptoms and chief complaints)]';
COMMENT ON COLUMN clinicalcare.emr_complaint.aggravating_factors IS '[v4: SUB-001..004, HIS-006 (Symptoms and chief complaints)]';
COMMENT ON COLUMN clinicalcare.emr_complaint.relieving_factors IS '[v4: SUB-001..004, HIS-006 (Symptoms and chief complaints)]';
COMMENT ON COLUMN clinicalcare.emr_complaint.associated_symptoms IS '[v4: SUB-001..004, HIS-006 (Symptoms and chief complaints)]';
COMMENT ON COLUMN clinicalcare.emr_complaint.code_system_id IS 'SNOMED, NAMSTP [v4: SUB-001..004, HIS-006 (Symptoms and chief complaints)]';
COMMENT ON COLUMN clinicalcare.emr_complaint.captured_source IS 'DOCTOR, NURSE_TRIAGE, PORTAL, BOOKING [v4: SUB-001..004, HIS-006 (Symptoms and chief complaints)]';
COMMENT ON COLUMN clinicalcare.emr_complaint.is_confirmed IS '[v4: SUB-001..004, HIS-006 (Symptoms and chief complaints)]';

-- clinicalcare.emr_diagnosis  (13 new columns)  FDS: DXL-001..005, ASM-002, AYU-008, ALO-007, TRM-005 (Diagnosis / problem entity)
ALTER TABLE clinicalcare.emr_diagnosis ADD COLUMN IF NOT EXISTS diagnosis_role VARCHAR(20) NULL;
ALTER TABLE clinicalcare.emr_diagnosis ADD COLUMN IF NOT EXISTS diagnosis_stage VARCHAR(20) NULL;
ALTER TABLE clinicalcare.emr_diagnosis ADD COLUMN IF NOT EXISTS certainty VARCHAR(20) NULL;
ALTER TABLE clinicalcare.emr_diagnosis ADD COLUMN IF NOT EXISTS laterality VARCHAR(10) NULL;
ALTER TABLE clinicalcare.emr_diagnosis ADD COLUMN IF NOT EXISTS likelihood_rank SMALLINT NULL;
ALTER TABLE clinicalcare.emr_diagnosis ADD COLUMN IF NOT EXISTS code_system_release_id INT NULL;
ALTER TABLE clinicalcare.emr_diagnosis ADD COLUMN IF NOT EXISTS dual_code_id BIGINT NULL;
ALTER TABLE clinicalcare.emr_diagnosis ADD COLUMN IF NOT EXISTS biomedical_code_id BIGINT NULL;
ALTER TABLE clinicalcare.emr_diagnosis ADD COLUMN IF NOT EXISTS assigned_by_type VARCHAR(20) NULL;
ALTER TABLE clinicalcare.emr_diagnosis ADD COLUMN IF NOT EXISTS present_on_admission VARCHAR(5) NULL;
ALTER TABLE clinicalcare.emr_diagnosis ADD COLUMN IF NOT EXISTS severity VARCHAR(20) NULL;
ALTER TABLE clinicalcare.emr_diagnosis ADD COLUMN IF NOT EXISTS system_of_medicine VARCHAR(20) NULL;
ALTER TABLE clinicalcare.emr_diagnosis ADD COLUMN IF NOT EXISTS entered_in_error BOOLEAN NULL DEFAULT FALSE;
COMMENT ON COLUMN clinicalcare.emr_diagnosis.diagnosis_role IS 'PROVISIONAL, DIFFERENTIAL, WORKING, FINAL [v4: DXL-001..005, ASM-002, AYU-008, ALO-007, TRM-005 (Diagnosis / problem entity)]';
COMMENT ON COLUMN clinicalcare.emr_diagnosis.diagnosis_stage IS 'ADMISSION, DISCHARGE, ENCOUNTER [v4: DXL-001..005, ASM-002, AYU-008, ALO-007, TRM-005 (Diagnosis / problem entity)]';
COMMENT ON COLUMN clinicalcare.emr_diagnosis.certainty IS 'CONFIRMED, PROBABLE, SUSPECTED, RULED_OUT [v4: DXL-001..005, ASM-002, AYU-008, ALO-007, TRM-005 (Diagnosis / problem entity)]';
COMMENT ON COLUMN clinicalcare.emr_diagnosis.laterality IS 'LEFT, RIGHT, BILATERAL, NA [v4: DXL-001..005, ASM-002, AYU-008, ALO-007, TRM-005 (Diagnosis / problem entity)]';
COMMENT ON COLUMN clinicalcare.emr_diagnosis.likelihood_rank IS 'differential ranking [v4: DXL-001..005, ASM-002, AYU-008, ALO-007, TRM-005 (Diagnosis / problem entity)]';
COMMENT ON COLUMN clinicalcare.emr_diagnosis.code_system_release_id IS 'identityorg.core_code_system_release [v4: DXL-001..005, ASM-002, AYU-008, ALO-007, TRM-005 (Diagnosis / problem entity)]';
COMMENT ON COLUMN clinicalcare.emr_diagnosis.dual_code_id IS 'mapped ICD-11 TM2 code for AYUSH diagnosis [v4: DXL-001..005, ASM-002, AYU-008, ALO-007, TRM-005 (Diagnosis / problem entity)]';
COMMENT ON COLUMN clinicalcare.emr_diagnosis.biomedical_code_id IS 'optional biomedical ICD code [v4: DXL-001..005, ASM-002, AYU-008, ALO-007, TRM-005 (Diagnosis / problem entity)]';
COMMENT ON COLUMN clinicalcare.emr_diagnosis.assigned_by_type IS 'CLINICIAN, CODER, AUTO_MAP [v4: DXL-001..005, ASM-002, AYU-008, ALO-007, TRM-005 (Diagnosis / problem entity)]';
COMMENT ON COLUMN clinicalcare.emr_diagnosis.present_on_admission IS 'Y, N, U, W [v4: DXL-001..005, ASM-002, AYU-008, ALO-007, TRM-005 (Diagnosis / problem entity)]';
COMMENT ON COLUMN clinicalcare.emr_diagnosis.severity IS '[v4: DXL-001..005, ASM-002, AYU-008, ALO-007, TRM-005 (Diagnosis / problem entity)]';
COMMENT ON COLUMN clinicalcare.emr_diagnosis.system_of_medicine IS '[v4: DXL-001..005, ASM-002, AYU-008, ALO-007, TRM-005 (Diagnosis / problem entity)]';
COMMENT ON COLUMN clinicalcare.emr_diagnosis.entered_in_error IS '[v4: DXL-001..005, ASM-002, AYU-008, ALO-007, TRM-005 (Diagnosis / problem entity)]';

-- clinicalcare.emr_examination_finding  (7 new columns)  FDS: VSE-006..008
ALTER TABLE clinicalcare.emr_examination_finding ADD COLUMN IF NOT EXISTS patient_id BIGINT NULL;
ALTER TABLE clinicalcare.emr_examination_finding ADD COLUMN IF NOT EXISTS system_of_medicine VARCHAR(20) NULL;
ALTER TABLE clinicalcare.emr_examination_finding ADD COLUMN IF NOT EXISTS examination_method VARCHAR(40) NULL;
ALTER TABLE clinicalcare.emr_examination_finding ADD COLUMN IF NOT EXISTS structured_json JSONB NULL;
ALTER TABLE clinicalcare.emr_examination_finding ADD COLUMN IF NOT EXISTS diagram_uri VARCHAR(500) NULL;
ALTER TABLE clinicalcare.emr_examination_finding ADD COLUMN IF NOT EXISTS photo_document_id BIGINT NULL;
ALTER TABLE clinicalcare.emr_examination_finding ADD COLUMN IF NOT EXISTS photo_consent_id BIGINT NULL;
COMMENT ON COLUMN clinicalcare.emr_examination_finding.patient_id IS 'logical FK -> patientengagement.pat_patient [Patient Access & Engagement] [v4: VSE-006..008]';
COMMENT ON COLUMN clinicalcare.emr_examination_finding.system_of_medicine IS '[v4: VSE-006..008]';
COMMENT ON COLUMN clinicalcare.emr_examination_finding.examination_method IS 'ASHTAVIDHA_PARIKSHA, NADI, ENVAGAI_THERVU, NABZ, MIZAJ ... [v4: VSE-006..008]';
COMMENT ON COLUMN clinicalcare.emr_examination_finding.structured_json IS '[v4: VSE-006..008]';
COMMENT ON COLUMN clinicalcare.emr_examination_finding.diagram_uri IS '[v4: VSE-006..008]';
COMMENT ON COLUMN clinicalcare.emr_examination_finding.photo_document_id IS 'logical FK -> integrationcomms.core_document [Integration & Communications] [v4: VSE-006..008]';
COMMENT ON COLUMN clinicalcare.emr_examination_finding.photo_consent_id IS 'logical FK -> patientengagement.pat_consent [Patient Access & Engagement] [v4: VSE-006..008]';

-- clinicalcare.emr_immunization  (4 new columns)  FDS: HIS-005
ALTER TABLE clinicalcare.emr_immunization ADD COLUMN IF NOT EXISTS schedule_code VARCHAR(20) NULL;
ALTER TABLE clinicalcare.emr_immunization ADD COLUMN IF NOT EXISTS given_by_name VARCHAR(150) NULL;
ALTER TABLE clinicalcare.emr_immunization ADD COLUMN IF NOT EXISTS adverse_event VARCHAR(500) NULL;
ALTER TABLE clinicalcare.emr_immunization ADD COLUMN IF NOT EXISTS route VARCHAR(20) NULL;
COMMENT ON COLUMN clinicalcare.emr_immunization.schedule_code IS 'NIS, IAP, ADULT [v4: HIS-005]';
COMMENT ON COLUMN clinicalcare.emr_immunization.given_by_name IS '[v4: HIS-005]';
COMMENT ON COLUMN clinicalcare.emr_immunization.adverse_event IS '[v4: HIS-005]';
COMMENT ON COLUMN clinicalcare.emr_immunization.route IS '[v4: HIS-005]';

-- clinicalcare.emr_patient_history  (13 new columns)  FDS: HIS-001..003, HIS-008 (History)
ALTER TABLE clinicalcare.emr_patient_history ADD COLUMN IF NOT EXISTS onset_year SMALLINT NULL;
ALTER TABLE clinicalcare.emr_patient_history ADD COLUMN IF NOT EXISTS history_status VARCHAR(20) NULL;
ALTER TABLE clinicalcare.emr_patient_history ADD COLUMN IF NOT EXISTS treatment_text VARCHAR(500) NULL;
ALTER TABLE clinicalcare.emr_patient_history ADD COLUMN IF NOT EXISTS hospital_name VARCHAR(200) NULL;
ALTER TABLE clinicalcare.emr_patient_history ADD COLUMN IF NOT EXISTS complications VARCHAR(500) NULL;
ALTER TABLE clinicalcare.emr_patient_history ADD COLUMN IF NOT EXISTS implants VARCHAR(300) NULL;
ALTER TABLE clinicalcare.emr_patient_history ADD COLUMN IF NOT EXISTS relative_age_at_onset SMALLINT NULL;
ALTER TABLE clinicalcare.emr_patient_history ADD COLUMN IF NOT EXISTS relative_living_status VARCHAR(20) NULL;
ALTER TABLE clinicalcare.emr_patient_history ADD COLUMN IF NOT EXISTS relative_cause_of_death VARCHAR(200) NULL;
ALTER TABLE clinicalcare.emr_patient_history ADD COLUMN IF NOT EXISTS consanguinity BOOLEAN NULL;
ALTER TABLE clinicalcare.emr_patient_history ADD COLUMN IF NOT EXISTS source VARCHAR(20) NULL;
ALTER TABLE clinicalcare.emr_patient_history ADD COLUMN IF NOT EXISTS last_reviewed_at TIMESTAMPTZ(0) NULL;
ALTER TABLE clinicalcare.emr_patient_history ADD COLUMN IF NOT EXISTS last_reviewed_by BIGINT NULL;
COMMENT ON COLUMN clinicalcare.emr_patient_history.onset_year IS '[v4: HIS-001..003, HIS-008 (History)]';
COMMENT ON COLUMN clinicalcare.emr_patient_history.history_status IS 'ACTIVE, RESOLVED, IN_REMISSION [v4: HIS-001..003, HIS-008 (History)]';
COMMENT ON COLUMN clinicalcare.emr_patient_history.treatment_text IS '[v4: HIS-001..003, HIS-008 (History)]';
COMMENT ON COLUMN clinicalcare.emr_patient_history.hospital_name IS '[v4: HIS-001..003, HIS-008 (History)]';
COMMENT ON COLUMN clinicalcare.emr_patient_history.complications IS '[v4: HIS-001..003, HIS-008 (History)]';
COMMENT ON COLUMN clinicalcare.emr_patient_history.implants IS '[v4: HIS-001..003, HIS-008 (History)]';
COMMENT ON COLUMN clinicalcare.emr_patient_history.relative_age_at_onset IS '[v4: HIS-001..003, HIS-008 (History)]';
COMMENT ON COLUMN clinicalcare.emr_patient_history.relative_living_status IS 'LIVING, DECEASED [v4: HIS-001..003, HIS-008 (History)]';
COMMENT ON COLUMN clinicalcare.emr_patient_history.relative_cause_of_death IS '[v4: HIS-001..003, HIS-008 (History)]';
COMMENT ON COLUMN clinicalcare.emr_patient_history.consanguinity IS '[v4: HIS-001..003, HIS-008 (History)]';
COMMENT ON COLUMN clinicalcare.emr_patient_history.source IS 'PATIENT, RELATIVE, RECORDS, ABDM [v4: HIS-001..003, HIS-008 (History)]';
COMMENT ON COLUMN clinicalcare.emr_patient_history.last_reviewed_at IS '[v4: HIS-001..003, HIS-008 (History)]';
COMMENT ON COLUMN clinicalcare.emr_patient_history.last_reviewed_by IS '[v4: HIS-001..003, HIS-008 (History)]';

-- clinicalcare.emr_vital_sign  (11 new columns)  FDS: VIT-001, VIT-002, VIT-005, VIT-007, VSE-001..004 (Vital sign / observation entity)
ALTER TABLE clinicalcare.emr_vital_sign ADD COLUMN IF NOT EXISTS vital_set_id BIGINT NULL;
ALTER TABLE clinicalcare.emr_vital_sign ADD COLUMN IF NOT EXISTS body_position VARCHAR(20) NULL;
ALTER TABLE clinicalcare.emr_vital_sign ADD COLUMN IF NOT EXISTS body_site VARCHAR(30) NULL;
ALTER TABLE clinicalcare.emr_vital_sign ADD COLUMN IF NOT EXISTS oxygen_support VARCHAR(20) NULL;
ALTER TABLE clinicalcare.emr_vital_sign ADD COLUMN IF NOT EXISTS oxygen_flow_lpm DECIMAL(5,2) NULL;
ALTER TABLE clinicalcare.emr_vital_sign ADD COLUMN IF NOT EXISTS rhythm VARCHAR(20) NULL;
ALTER TABLE clinicalcare.emr_vital_sign ADD COLUMN IF NOT EXISTS abnormal_flag VARCHAR(5) NULL;
ALTER TABLE clinicalcare.emr_vital_sign ADD COLUMN IF NOT EXISTS is_validated BOOLEAN NULL DEFAULT TRUE;
ALTER TABLE clinicalcare.emr_vital_sign ADD COLUMN IF NOT EXISTS entered_in_error BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE clinicalcare.emr_vital_sign ADD COLUMN IF NOT EXISTS error_reason VARCHAR(300) NULL;
ALTER TABLE clinicalcare.emr_vital_sign ADD COLUMN IF NOT EXISTS corrected_from_vital_sign_id BIGINT NULL;
COMMENT ON COLUMN clinicalcare.emr_vital_sign.vital_set_id IS '[v4: VIT-001, VIT-002, VIT-005, VIT-007, VSE-001..004 (Vital sign / observation entity)]';
COMMENT ON COLUMN clinicalcare.emr_vital_sign.body_position IS 'SITTING, STANDING, SUPINE [v4: VIT-001, VIT-002, VIT-005, VIT-007, VSE-001..004 (Vital sign / observation entity)]';
COMMENT ON COLUMN clinicalcare.emr_vital_sign.body_site IS 'LEFT_ARM, ORAL, AXILLARY, TYMPANIC ... [v4: VIT-001, VIT-002, VIT-005, VIT-007, VSE-001..004 (Vital sign / observation entity)]';
COMMENT ON COLUMN clinicalcare.emr_vital_sign.oxygen_support IS 'ROOM_AIR, NASAL_CANNULA, MASK, NRBM, VENTILATOR [v4: VIT-001, VIT-002, VIT-005, VIT-007, VSE-001..004 (Vital sign / observation entity)]';
COMMENT ON COLUMN clinicalcare.emr_vital_sign.oxygen_flow_lpm IS '[v4: VIT-001, VIT-002, VIT-005, VIT-007, VSE-001..004 (Vital sign / observation entity)]';
COMMENT ON COLUMN clinicalcare.emr_vital_sign.rhythm IS 'REGULAR, IRREGULAR [v4: VIT-001, VIT-002, VIT-005, VIT-007, VSE-001..004 (Vital sign / observation entity)]';
COMMENT ON COLUMN clinicalcare.emr_vital_sign.abnormal_flag IS 'N, L, H, LL, HH [v4: VIT-001, VIT-002, VIT-005, VIT-007, VSE-001..004 (Vital sign / observation entity)]';
COMMENT ON COLUMN clinicalcare.emr_vital_sign.is_validated IS '[v4: VIT-001, VIT-002, VIT-005, VIT-007, VSE-001..004 (Vital sign / observation entity)]';
COMMENT ON COLUMN clinicalcare.emr_vital_sign.entered_in_error IS '[v4: VIT-001, VIT-002, VIT-005, VIT-007, VSE-001..004 (Vital sign / observation entity)]';
COMMENT ON COLUMN clinicalcare.emr_vital_sign.error_reason IS '[v4: VIT-001, VIT-002, VIT-005, VIT-007, VSE-001..004 (Vital sign / observation entity)]';
COMMENT ON COLUMN clinicalcare.emr_vital_sign.corrected_from_vital_sign_id IS '[v4: VIT-001, VIT-002, VIT-005, VIT-007, VSE-001..004 (Vital sign / observation entity)]';

-- clinicalcare.mst_clinical_template  (9 new columns)  FDS: TPL-001/002/015, DIT-001 (Template / order set / rule entity)
ALTER TABLE clinicalcare.mst_clinical_template ADD COLUMN IF NOT EXISTS system_of_medicine VARCHAR(20) NULL DEFAULT 'ALLOPATHY';
ALTER TABLE clinicalcare.mst_clinical_template ADD COLUMN IF NOT EXISTS encounter_type VARCHAR(20) NULL;
ALTER TABLE clinicalcare.mst_clinical_template ADD COLUMN IF NOT EXISTS owner_practitioner_id BIGINT NULL;
ALTER TABLE clinicalcare.mst_clinical_template ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) NULL DEFAULT 'APPROVED';
ALTER TABLE clinicalcare.mst_clinical_template ADD COLUMN IF NOT EXISTS approved_by BIGINT NULL;
ALTER TABLE clinicalcare.mst_clinical_template ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ(0) NULL;
ALTER TABLE clinicalcare.mst_clinical_template ADD COLUMN IF NOT EXISTS valid_from DATE NULL;
ALTER TABLE clinicalcare.mst_clinical_template ADD COLUMN IF NOT EXISTS valid_to DATE NULL;
ALTER TABLE clinicalcare.mst_clinical_template ADD COLUMN IF NOT EXISTS is_reportable_fields BOOLEAN NULL DEFAULT FALSE;
COMMENT ON COLUMN clinicalcare.mst_clinical_template.system_of_medicine IS '[v4: TPL-001/002/015, DIT-001 (Template / order set / rule entity)]';
COMMENT ON COLUMN clinicalcare.mst_clinical_template.encounter_type IS '[v4: TPL-001/002/015, DIT-001 (Template / order set / rule entity)]';
COMMENT ON COLUMN clinicalcare.mst_clinical_template.owner_practitioner_id IS '[v4: TPL-001/002/015, DIT-001 (Template / order set / rule entity)]';
COMMENT ON COLUMN clinicalcare.mst_clinical_template.approval_status IS 'DRAFT, PENDING, APPROVED, RETIRED [v4: TPL-001/002/015, DIT-001 (Template / order set / rule entity)]';
COMMENT ON COLUMN clinicalcare.mst_clinical_template.approved_by IS '[v4: TPL-001/002/015, DIT-001 (Template / order set / rule entity)]';
COMMENT ON COLUMN clinicalcare.mst_clinical_template.approved_at IS '[v4: TPL-001/002/015, DIT-001 (Template / order set / rule entity)]';
COMMENT ON COLUMN clinicalcare.mst_clinical_template.valid_from IS '[v4: TPL-001/002/015, DIT-001 (Template / order set / rule entity)]';
COMMENT ON COLUMN clinicalcare.mst_clinical_template.valid_to IS '[v4: TPL-001/002/015, DIT-001 (Template / order set / rule entity)]';
COMMENT ON COLUMN clinicalcare.mst_clinical_template.is_reportable_fields IS 'TPL-016 [v4: TPL-001/002/015, DIT-001 (Template / order set / rule entity)]';

-- clinicalcare.mst_order_set  (7 new columns)  FDS: IVP-002..005, CPO-002
ALTER TABLE clinicalcare.mst_order_set ADD COLUMN IF NOT EXISTS department_id INT NULL;
ALTER TABLE clinicalcare.mst_order_set ADD COLUMN IF NOT EXISTS system_of_medicine VARCHAR(20) NULL;
ALTER TABLE clinicalcare.mst_order_set ADD COLUMN IF NOT EXISTS version_no SMALLINT NULL DEFAULT 1;
ALTER TABLE clinicalcare.mst_order_set ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) NULL DEFAULT 'APPROVED';
ALTER TABLE clinicalcare.mst_order_set ADD COLUMN IF NOT EXISTS valid_from DATE NULL;
ALTER TABLE clinicalcare.mst_order_set ADD COLUMN IF NOT EXISTS valid_to DATE NULL;
ALTER TABLE clinicalcare.mst_order_set ADD COLUMN IF NOT EXISTS is_personal_favourite BOOLEAN NULL DEFAULT FALSE;
COMMENT ON COLUMN clinicalcare.mst_order_set.department_id IS '[v4: IVP-002..005, CPO-002]';
COMMENT ON COLUMN clinicalcare.mst_order_set.system_of_medicine IS '[v4: IVP-002..005, CPO-002]';
COMMENT ON COLUMN clinicalcare.mst_order_set.version_no IS '[v4: IVP-002..005, CPO-002]';
COMMENT ON COLUMN clinicalcare.mst_order_set.approval_status IS '[v4: IVP-002..005, CPO-002]';
COMMENT ON COLUMN clinicalcare.mst_order_set.valid_from IS '[v4: IVP-002..005, CPO-002]';
COMMENT ON COLUMN clinicalcare.mst_order_set.valid_to IS '[v4: IVP-002..005, CPO-002]';
COMMENT ON COLUMN clinicalcare.mst_order_set.is_personal_favourite IS '[v4: IVP-002..005, CPO-002]';

-- clinicalcare.mst_order_set_item  (6 new columns)  FDS: IVP-002, RXM-006
ALTER TABLE clinicalcare.mst_order_set_item ADD COLUMN IF NOT EXISTS order_category VARCHAR(20) NULL;
ALTER TABLE clinicalcare.mst_order_set_item ADD COLUMN IF NOT EXISTS dose_unit VARCHAR(20) NULL;
ALTER TABLE clinicalcare.mst_order_set_item ADD COLUMN IF NOT EXISTS route VARCHAR(20) NULL;
ALTER TABLE clinicalcare.mst_order_set_item ADD COLUMN IF NOT EXISTS priority VARCHAR(10) NULL;
ALTER TABLE clinicalcare.mst_order_set_item ADD COLUMN IF NOT EXISTS anupana VARCHAR(100) NULL;
ALTER TABLE clinicalcare.mst_order_set_item ADD COLUMN IF NOT EXISTS display_order SMALLINT NULL;
COMMENT ON COLUMN clinicalcare.mst_order_set_item.order_category IS 'LAB, RADIOLOGY, PHARMACY, PROCEDURE, DIET, NURSING [v4: IVP-002, RXM-006]';
COMMENT ON COLUMN clinicalcare.mst_order_set_item.dose_unit IS '[v4: IVP-002, RXM-006]';
COMMENT ON COLUMN clinicalcare.mst_order_set_item.route IS '[v4: IVP-002, RXM-006]';
COMMENT ON COLUMN clinicalcare.mst_order_set_item.priority IS '[v4: IVP-002, RXM-006]';
COMMENT ON COLUMN clinicalcare.mst_order_set_item.anupana IS '[v4: IVP-002, RXM-006]';
COMMENT ON COLUMN clinicalcare.mst_order_set_item.display_order IS '[v4: IVP-002, RXM-006]';

-- clinicalcare.ord_cds_alert  (8 new columns)  FDS: CDS-003..005, DDI-001..004, ALG-001..004 (Alert instance entity)
ALTER TABLE clinicalcare.ord_cds_alert ADD COLUMN IF NOT EXISTS cds_rule_id INT NULL;
ALTER TABLE clinicalcare.ord_cds_alert ADD COLUMN IF NOT EXISTS rule_version SMALLINT NULL;
ALTER TABLE clinicalcare.ord_cds_alert ADD COLUMN IF NOT EXISTS check_type VARCHAR(30) NULL;
ALTER TABLE clinicalcare.ord_cds_alert ADD COLUMN IF NOT EXISTS alert_grade VARCHAR(10) NULL;
ALTER TABLE clinicalcare.ord_cds_alert ADD COLUMN IF NOT EXISTS shown_to_user_id BIGINT NULL;
ALTER TABLE clinicalcare.ord_cds_alert ADD COLUMN IF NOT EXISTS shown_at TIMESTAMPTZ(0) NULL;
ALTER TABLE clinicalcare.ord_cds_alert ADD COLUMN IF NOT EXISTS reference_url VARCHAR(500) NULL;
ALTER TABLE clinicalcare.ord_cds_alert ADD COLUMN IF NOT EXISTS source_service VARCHAR(20) NULL;
COMMENT ON COLUMN clinicalcare.ord_cds_alert.cds_rule_id IS '[v4: CDS-003..005, DDI-001..004, ALG-001..004 (Alert instance entity)]';
COMMENT ON COLUMN clinicalcare.ord_cds_alert.rule_version IS '[v4: CDS-003..005, DDI-001..004, ALG-001..004 (Alert instance entity)]';
COMMENT ON COLUMN clinicalcare.ord_cds_alert.check_type IS 'DDI, DRUG_DISEASE, DRUG_PREGNANCY, DRUG_AGE, DRUG_FOOD, DUPLICATE_THERAPY, ALLERGY, DOSE_RANGE, AYUSH_ALLOPATHIC, REMINDER [v4: CDS-003..005, DDI-001..004, ALG-001..004 (Alert instance entity)]';
COMMENT ON COLUMN clinicalcare.ord_cds_alert.alert_grade IS 'INFO, WARNING, HARD_STOP [v4: CDS-003..005, DDI-001..004, ALG-001..004 (Alert instance entity)]';
COMMENT ON COLUMN clinicalcare.ord_cds_alert.shown_to_user_id IS '[v4: CDS-003..005, DDI-001..004, ALG-001..004 (Alert instance entity)]';
COMMENT ON COLUMN clinicalcare.ord_cds_alert.shown_at IS '[v4: CDS-003..005, DDI-001..004, ALG-001..004 (Alert instance entity)]';
COMMENT ON COLUMN clinicalcare.ord_cds_alert.reference_url IS '[v4: CDS-003..005, DDI-001..004, ALG-001..004 (Alert instance entity)]';
COMMENT ON COLUMN clinicalcare.ord_cds_alert.source_service IS 'CLINICAL_CARE, PHARMACY [v4: CDS-003..005, DDI-001..004, ALG-001..004 (Alert instance entity)]';

-- clinicalcare.ord_clinical_order  (11 new columns)  FDS: CPO-001..006, RDO-002, PHO-001, Order entity (EHR 7.1.2)
ALTER TABLE clinicalcare.ord_clinical_order ADD COLUMN IF NOT EXISTS system_of_medicine VARCHAR(20) NULL;
ALTER TABLE clinicalcare.ord_clinical_order ADD COLUMN IF NOT EXISTS is_verbal_order BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE clinicalcare.ord_clinical_order ADD COLUMN IF NOT EXISTS verbal_order_entered_by BIGINT NULL;
ALTER TABLE clinicalcare.ord_clinical_order ADD COLUMN IF NOT EXISTS countersign_due_at TIMESTAMPTZ(0) NULL;
ALTER TABLE clinicalcare.ord_clinical_order ADD COLUMN IF NOT EXISTS countersigned_by BIGINT NULL;
ALTER TABLE clinicalcare.ord_clinical_order ADD COLUMN IF NOT EXISTS countersigned_at TIMESTAMPTZ(0) NULL;
ALTER TABLE clinicalcare.ord_clinical_order ADD COLUMN IF NOT EXISTS preauth_required BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE clinicalcare.ord_clinical_order ADD COLUMN IF NOT EXISTS safety_info_json JSONB NULL;
ALTER TABLE clinicalcare.ord_clinical_order ADD COLUMN IF NOT EXISTS source_order_set_id INT NULL;
ALTER TABLE clinicalcare.ord_clinical_order ADD COLUMN IF NOT EXISTS copied_from_order_id BIGINT NULL;
ALTER TABLE clinicalcare.ord_clinical_order ADD COLUMN IF NOT EXISTS online_order_id BIGINT NULL;
COMMENT ON COLUMN clinicalcare.ord_clinical_order.system_of_medicine IS '[v4: CPO-001..006, RDO-002, PHO-001, Order entity (EHR 7.1.2)]';
COMMENT ON COLUMN clinicalcare.ord_clinical_order.is_verbal_order IS '[v4: CPO-001..006, RDO-002, PHO-001, Order entity (EHR 7.1.2)]';
COMMENT ON COLUMN clinicalcare.ord_clinical_order.verbal_order_entered_by IS '[v4: CPO-001..006, RDO-002, PHO-001, Order entity (EHR 7.1.2)]';
COMMENT ON COLUMN clinicalcare.ord_clinical_order.countersign_due_at IS '[v4: CPO-001..006, RDO-002, PHO-001, Order entity (EHR 7.1.2)]';
COMMENT ON COLUMN clinicalcare.ord_clinical_order.countersigned_by IS '[v4: CPO-001..006, RDO-002, PHO-001, Order entity (EHR 7.1.2)]';
COMMENT ON COLUMN clinicalcare.ord_clinical_order.countersigned_at IS '[v4: CPO-001..006, RDO-002, PHO-001, Order entity (EHR 7.1.2)]';
COMMENT ON COLUMN clinicalcare.ord_clinical_order.preauth_required IS '[v4: CPO-001..006, RDO-002, PHO-001, Order entity (EHR 7.1.2)]';
COMMENT ON COLUMN clinicalcare.ord_clinical_order.safety_info_json IS 'pregnancy, eGFR/creatinine, implants / pacemaker, contrast allergy [v4: CPO-001..006, RDO-002, PHO-001, Order entity (EHR 7.1.2)]';
COMMENT ON COLUMN clinicalcare.ord_clinical_order.source_order_set_id IS '[v4: CPO-001..006, RDO-002, PHO-001, Order entity (EHR 7.1.2)]';
COMMENT ON COLUMN clinicalcare.ord_clinical_order.copied_from_order_id IS '[v4: CPO-001..006, RDO-002, PHO-001, Order entity (EHR 7.1.2)]';
COMMENT ON COLUMN clinicalcare.ord_clinical_order.online_order_id IS 'logical FK -> patientengagement.ecom_online_order [Patient Access & Engagement] [v4: CPO-001..006, RDO-002, PHO-001, Order entity (EHR 7.1.2)]';

-- clinicalcare.ord_order_item  (21 new columns)  FDS: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004
ALTER TABLE clinicalcare.ord_order_item ADD COLUMN IF NOT EXISTS priority VARCHAR(10) NULL;
ALTER TABLE clinicalcare.ord_order_item ADD COLUMN IF NOT EXISTS clinical_indication_code_id BIGINT NULL;
ALTER TABLE clinicalcare.ord_order_item ADD COLUMN IF NOT EXISTS specimen_type VARCHAR(30) NULL;
ALTER TABLE clinicalcare.ord_order_item ADD COLUMN IF NOT EXISTS collection_timing VARCHAR(20) NULL;
ALTER TABLE clinicalcare.ord_order_item ADD COLUMN IF NOT EXISTS laterality VARCHAR(10) NULL;
ALTER TABLE clinicalcare.ord_order_item ADD COLUMN IF NOT EXISTS body_part VARCHAR(50) NULL;
ALTER TABLE clinicalcare.ord_order_item ADD COLUMN IF NOT EXISTS with_contrast BOOLEAN NULL;
ALTER TABLE clinicalcare.ord_order_item ADD COLUMN IF NOT EXISTS home_collection_requested BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE clinicalcare.ord_order_item ADD COLUMN IF NOT EXISTS consent_id BIGINT NULL;
ALTER TABLE clinicalcare.ord_order_item ADD COLUMN IF NOT EXISTS procedure_code_id BIGINT NULL;
ALTER TABLE clinicalcare.ord_order_item ADD COLUMN IF NOT EXISTS performed_by BIGINT NULL;
ALTER TABLE clinicalcare.ord_order_item ADD COLUMN IF NOT EXISTS performed_at TIMESTAMPTZ(0) NULL;
ALTER TABLE clinicalcare.ord_order_item ADD COLUMN IF NOT EXISTS findings TEXT NULL;
ALTER TABLE clinicalcare.ord_order_item ADD COLUMN IF NOT EXISTS complications VARCHAR(500) NULL;
ALTER TABLE clinicalcare.ord_order_item ADD COLUMN IF NOT EXISTS diet_type VARCHAR(30) NULL;
ALTER TABLE clinicalcare.ord_order_item ADD COLUMN IF NOT EXISTS diet_restrictions VARCHAR(500) NULL;
ALTER TABLE clinicalcare.ord_order_item ADD COLUMN IF NOT EXISTS monitoring_parameter VARCHAR(50) NULL;
ALTER TABLE clinicalcare.ord_order_item ADD COLUMN IF NOT EXISTS monitoring_frequency VARCHAR(30) NULL;
ALTER TABLE clinicalcare.ord_order_item ADD COLUMN IF NOT EXISTS cancel_reason VARCHAR(300) NULL;
ALTER TABLE clinicalcare.ord_order_item ADD COLUMN IF NOT EXISTS performing_service VARCHAR(20) NULL;
ALTER TABLE clinicalcare.ord_order_item ADD COLUMN IF NOT EXISTS external_ref_id BIGINT NULL;
COMMENT ON COLUMN clinicalcare.ord_order_item.priority IS 'ROUTINE, URGENT, STAT [v4: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004]';
COMMENT ON COLUMN clinicalcare.ord_order_item.clinical_indication_code_id IS '[v4: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004]';
COMMENT ON COLUMN clinicalcare.ord_order_item.specimen_type IS '[v4: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004]';
COMMENT ON COLUMN clinicalcare.ord_order_item.collection_timing IS 'NOW, SCHEDULED, FASTING, TIMED [v4: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004]';
COMMENT ON COLUMN clinicalcare.ord_order_item.laterality IS '[v4: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004]';
COMMENT ON COLUMN clinicalcare.ord_order_item.body_part IS '[v4: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004]';
COMMENT ON COLUMN clinicalcare.ord_order_item.with_contrast IS '[v4: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004]';
COMMENT ON COLUMN clinicalcare.ord_order_item.home_collection_requested IS '[v4: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004]';
COMMENT ON COLUMN clinicalcare.ord_order_item.consent_id IS 'patientengagement.pat_consent [v4: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004]';
COMMENT ON COLUMN clinicalcare.ord_order_item.procedure_code_id IS '[v4: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004]';
COMMENT ON COLUMN clinicalcare.ord_order_item.performed_by IS '[v4: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004]';
COMMENT ON COLUMN clinicalcare.ord_order_item.performed_at IS '[v4: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004]';
COMMENT ON COLUMN clinicalcare.ord_order_item.findings IS '[v4: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004]';
COMMENT ON COLUMN clinicalcare.ord_order_item.complications IS '[v4: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004]';
COMMENT ON COLUMN clinicalcare.ord_order_item.diet_type IS '[v4: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004]';
COMMENT ON COLUMN clinicalcare.ord_order_item.diet_restrictions IS '[v4: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004]';
COMMENT ON COLUMN clinicalcare.ord_order_item.monitoring_parameter IS 'vitals monitoring orders [v4: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004]';
COMMENT ON COLUMN clinicalcare.ord_order_item.monitoring_frequency IS '[v4: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004]';
COMMENT ON COLUMN clinicalcare.ord_order_item.cancel_reason IS '[v4: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004]';
COMMENT ON COLUMN clinicalcare.ord_order_item.performing_service IS 'LIMS, RIMS, PHARMACY, NURSING, DIETARY, OT [v4: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004]';
COMMENT ON COLUMN clinicalcare.ord_order_item.external_ref_id IS 'sample / study / dispense id from performing service [v4: LBO-001..003, RDO-001..003, PRO-001..003, DTO-001..003, CPO-001/004]';

-- clinicalcare.ord_prescription  (14 new columns)  FDS: RXM-005/008, ERX-001..004, TC-008, OPI-007 (Prescription entity)
ALTER TABLE clinicalcare.ord_prescription ADD COLUMN IF NOT EXISTS system_of_medicine VARCHAR(20) NULL;
ALTER TABLE clinicalcare.ord_prescription ADD COLUMN IF NOT EXISTS is_teleconsult BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE clinicalcare.ord_prescription ADD COLUMN IF NOT EXISTS tele_guideline_list VARCHAR(10) NULL;
ALTER TABLE clinicalcare.ord_prescription ADD COLUMN IF NOT EXISTS version_no SMALLINT NULL DEFAULT 1;
ALTER TABLE clinicalcare.ord_prescription ADD COLUMN IF NOT EXISTS renewal_of_prescription_id BIGINT NULL;
ALTER TABLE clinicalcare.ord_prescription ADD COLUMN IF NOT EXISTS print_language VARCHAR(10) NULL;
ALTER TABLE clinicalcare.ord_prescription ADD COLUMN IF NOT EXISTS valid_until DATE NULL;
ALTER TABLE clinicalcare.ord_prescription ADD COLUMN IF NOT EXISTS refills_allowed SMALLINT NULL DEFAULT 0;
ALTER TABLE clinicalcare.ord_prescription ADD COLUMN IF NOT EXISTS qr_token VARCHAR(100) NULL;
ALTER TABLE clinicalcare.ord_prescription ADD COLUMN IF NOT EXISTS prescriber_reg_no VARCHAR(50) NULL;
ALTER TABLE clinicalcare.ord_prescription ADD COLUMN IF NOT EXISTS prescriber_council VARCHAR(100) NULL;
ALTER TABLE clinicalcare.ord_prescription ADD COLUMN IF NOT EXISTS abdm_shared_at TIMESTAMPTZ(0) NULL;
ALTER TABLE clinicalcare.ord_prescription ADD COLUMN IF NOT EXISTS dispensing_status VARCHAR(20) NULL;
ALTER TABLE clinicalcare.ord_prescription ADD COLUMN IF NOT EXISTS diet_advice VARCHAR(1000) NULL;
COMMENT ON COLUMN clinicalcare.ord_prescription.system_of_medicine IS '[v4: RXM-005/008, ERX-001..004, TC-008, OPI-007 (Prescription entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription.is_teleconsult IS '[v4: RXM-005/008, ERX-001..004, TC-008, OPI-007 (Prescription entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription.tele_guideline_list IS 'LIST_O, LIST_A, LIST_B (Telemedicine Practice Guidelines) [v4: RXM-005/008, ERX-001..004, TC-008, OPI-007 (Prescription entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription.version_no IS '[v4: RXM-005/008, ERX-001..004, TC-008, OPI-007 (Prescription entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription.renewal_of_prescription_id IS '[v4: RXM-005/008, ERX-001..004, TC-008, OPI-007 (Prescription entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription.print_language IS '[v4: RXM-005/008, ERX-001..004, TC-008, OPI-007 (Prescription entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription.valid_until IS '[v4: RXM-005/008, ERX-001..004, TC-008, OPI-007 (Prescription entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription.refills_allowed IS '[v4: RXM-005/008, ERX-001..004, TC-008, OPI-007 (Prescription entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription.qr_token IS '[v4: RXM-005/008, ERX-001..004, TC-008, OPI-007 (Prescription entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription.prescriber_reg_no IS '[v4: RXM-005/008, ERX-001..004, TC-008, OPI-007 (Prescription entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription.prescriber_council IS '[v4: RXM-005/008, ERX-001..004, TC-008, OPI-007 (Prescription entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription.abdm_shared_at IS '[v4: RXM-005/008, ERX-001..004, TC-008, OPI-007 (Prescription entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription.dispensing_status IS 'NOT_DISPENSED, PARTLY, FULLY [v4: RXM-005/008, ERX-001..004, TC-008, OPI-007 (Prescription entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription.diet_advice IS '[v4: RXM-005/008, ERX-001..004, TC-008, OPI-007 (Prescription entity)]';

-- clinicalcare.ord_prescription_item  (16 new columns)  FDS: RXM-001..007, AYU-023, SGM-002, PHO-003 (Prescription / medication order entity)
ALTER TABLE clinicalcare.ord_prescription_item ADD COLUMN IF NOT EXISTS strength VARCHAR(50) NULL;
ALTER TABLE clinicalcare.ord_prescription_item ADD COLUMN IF NOT EXISTS dosage_form VARCHAR(30) NULL;
ALTER TABLE clinicalcare.ord_prescription_item ADD COLUMN IF NOT EXISTS atc_code VARCHAR(10) NULL;
ALTER TABLE clinicalcare.ord_prescription_item ADD COLUMN IF NOT EXISTS ayush_classification VARCHAR(50) NULL;
ALTER TABLE clinicalcare.ord_prescription_item ADD COLUMN IF NOT EXISTS anupana VARCHAR(100) NULL;
ALTER TABLE clinicalcare.ord_prescription_item ADD COLUMN IF NOT EXISTS kala VARCHAR(50) NULL;
ALTER TABLE clinicalcare.ord_prescription_item ADD COLUMN IF NOT EXISTS potency VARCHAR(20) NULL;
ALTER TABLE clinicalcare.ord_prescription_item ADD COLUMN IF NOT EXISTS repetition VARCHAR(50) NULL;
ALTER TABLE clinicalcare.ord_prescription_item ADD COLUMN IF NOT EXISTS dose_calc_basis VARCHAR(10) NULL;
ALTER TABLE clinicalcare.ord_prescription_item ADD COLUMN IF NOT EXISTS dose_per_unit DECIMAL(10,4) NULL;
ALTER TABLE clinicalcare.ord_prescription_item ADD COLUMN IF NOT EXISTS taper_schedule_json JSONB NULL;
ALTER TABLE clinicalcare.ord_prescription_item ADD COLUMN IF NOT EXISTS is_schedule_drug BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE clinicalcare.ord_prescription_item ADD COLUMN IF NOT EXISTS suggested_by_cds BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE clinicalcare.ord_prescription_item ADD COLUMN IF NOT EXISTS dispensing_status VARCHAR(20) NULL;
ALTER TABLE clinicalcare.ord_prescription_item ADD COLUMN IF NOT EXISTS dispensed_qty DECIMAL(10,2) NULL;
ALTER TABLE clinicalcare.ord_prescription_item ADD COLUMN IF NOT EXISTS version_no SMALLINT NULL DEFAULT 1;
COMMENT ON COLUMN clinicalcare.ord_prescription_item.strength IS '[v4: RXM-001..007, AYU-023, SGM-002, PHO-003 (Prescription / medication order entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription_item.dosage_form IS '[v4: RXM-001..007, AYU-023, SGM-002, PHO-003 (Prescription / medication order entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription_item.atc_code IS '[v4: RXM-001..007, AYU-023, SGM-002, PHO-003 (Prescription / medication order entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription_item.ayush_classification IS '[v4: RXM-001..007, AYU-023, SGM-002, PHO-003 (Prescription / medication order entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription_item.anupana IS 'vehicle (Ayurveda) [v4: RXM-001..007, AYU-023, SGM-002, PHO-003 (Prescription / medication order entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription_item.kala IS 'timing (before/after food) [v4: RXM-001..007, AYU-023, SGM-002, PHO-003 (Prescription / medication order entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription_item.potency IS 'Homoeopathy [v4: RXM-001..007, AYU-023, SGM-002, PHO-003 (Prescription / medication order entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription_item.repetition IS '[v4: RXM-001..007, AYU-023, SGM-002, PHO-003 (Prescription / medication order entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription_item.dose_calc_basis IS 'FIXED, WEIGHT, BSA [v4: RXM-001..007, AYU-023, SGM-002, PHO-003 (Prescription / medication order entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription_item.dose_per_unit IS '[v4: RXM-001..007, AYU-023, SGM-002, PHO-003 (Prescription / medication order entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription_item.taper_schedule_json IS '[v4: RXM-001..007, AYU-023, SGM-002, PHO-003 (Prescription / medication order entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription_item.is_schedule_drug IS '[v4: RXM-001..007, AYU-023, SGM-002, PHO-003 (Prescription / medication order entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription_item.suggested_by_cds IS '[v4: RXM-001..007, AYU-023, SGM-002, PHO-003 (Prescription / medication order entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription_item.dispensing_status IS 'PENDING, PARTLY_DISPENSED, DISPENSED, SUBSTITUTED, NOT_DISPENSED [v4: RXM-001..007, AYU-023, SGM-002, PHO-003 (Prescription / medication order entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription_item.dispensed_qty IS '[v4: RXM-001..007, AYU-023, SGM-002, PHO-003 (Prescription / medication order entity)]';
COMMENT ON COLUMN clinicalcare.ord_prescription_item.version_no IS '[v4: RXM-001..007, AYU-023, SGM-002, PHO-003 (Prescription / medication order entity)]';

-- clinicalcare.ref_drug  (6 new columns)  FDS: SGM-001..004, RXM-007, ALG-003 (replica extended with new pharmacy.mst_drug attributes used by CDS)
ALTER TABLE clinicalcare.ref_drug ADD COLUMN IF NOT EXISTS formulary_status VARCHAR(20) NULL;
ALTER TABLE clinicalcare.ref_drug ADD COLUMN IF NOT EXISTS schedule_category VARCHAR(20) NULL;
ALTER TABLE clinicalcare.ref_drug ADD COLUMN IF NOT EXISTS is_controlled BOOLEAN NULL;
ALTER TABLE clinicalcare.ref_drug ADD COLUMN IF NOT EXISTS substitution_rule VARCHAR(20) NULL;
ALTER TABLE clinicalcare.ref_drug ADD COLUMN IF NOT EXISTS system_of_medicine VARCHAR(20) NULL;
ALTER TABLE clinicalcare.ref_drug ADD COLUMN IF NOT EXISTS counselling_mandatory BOOLEAN NULL;
COMMENT ON COLUMN clinicalcare.ref_drug.formulary_status IS '[v4: SGM-001..004, RXM-007, ALG-003 (replica extended with new pharmacy.mst_drug attributes used by CDS)]';
COMMENT ON COLUMN clinicalcare.ref_drug.schedule_category IS '[v4: SGM-001..004, RXM-007, ALG-003 (replica extended with new pharmacy.mst_drug attributes used by CDS)]';
COMMENT ON COLUMN clinicalcare.ref_drug.is_controlled IS '[v4: SGM-001..004, RXM-007, ALG-003 (replica extended with new pharmacy.mst_drug attributes used by CDS)]';
COMMENT ON COLUMN clinicalcare.ref_drug.substitution_rule IS '[v4: SGM-001..004, RXM-007, ALG-003 (replica extended with new pharmacy.mst_drug attributes used by CDS)]';
COMMENT ON COLUMN clinicalcare.ref_drug.system_of_medicine IS '[v4: SGM-001..004, RXM-007, ALG-003 (replica extended with new pharmacy.mst_drug attributes used by CDS)]';
COMMENT ON COLUMN clinicalcare.ref_drug.counselling_mandatory IS '[v4: SGM-001..004, RXM-007, ALG-003 (replica extended with new pharmacy.mst_drug attributes used by CDS)]';

/* ---------- B. NEW TABLES ---------- */

-- ===== FDS EHR / EMR =====
-- [NEW v4] FDS ref: DOC-003, DOC-004, SEC-004
CREATE TABLE IF NOT EXISTS clinicalcare.emr_document_signature (              -- Signatures on clinical documents (author, co-signer, verifier) with method and registration no
    document_signature_id      BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    clinical_document_id       BIGINT NOT NULL,
    signer_user_id             BIGINT NOT NULL,                                -- logical FK -> identityorg.sec_user_account [Identity & Organization]
    signer_practitioner_id     BIGINT NULL,                                    -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    signer_role                VARCHAR(20) NOT NULL,                           -- AUTHOR, COSIGNER, VERIFIER, WITNESS
    registration_no            VARCHAR(50) NULL,
    signature_method           VARCHAR(20) NOT NULL,
    signature_ref              VARCHAR(200) NULL,
    signed_at                  TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: DIT-001..006, VTX-001..004
CREATE TABLE IF NOT EXISTS clinicalcare.emr_dictation (                       -- Dictation audio and transcription workflow (recorded, in transcription, awaiting review, signed)
    dictation_id               BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    encounter_id               BIGINT NULL,                                    -- logical FK -> patientengagement.pat_encounter [Patient Access & Engagement]
    clinical_document_id       BIGINT NULL,
    dictation_template_id      INT NULL,
    author_practitioner_id     BIGINT NOT NULL,                                -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    recognition_mode           VARCHAR(20) NOT NULL,                           -- FRONT_END_REALTIME, BACK_END_QUEUED, TRANSCRIPTIONIST
    audio_uri                  VARCHAR(500) NULL,
    audio_duration_sec         INT NULL,
    language_code              VARCHAR(10) NULL,
    draft_text                 TEXT NULL,
    transcriptionist_id        BIGINT NULL,                                    -- logical FK -> identityorg.hr_employee [Identity & Organization]
    recorded_at                TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    transcription_started_at   TIMESTAMPTZ(0) NULL,
    returned_for_review_at     TIMESTAMPTZ(0) NULL,
    signed_at                  TIMESTAMPTZ(0) NULL,
    audio_purge_due_at         TIMESTAMPTZ(0) NULL,
    audio_purged_at            TIMESTAMPTZ(0) NULL,
    dictation_status           VARCHAR(20) NOT NULL DEFAULT 'RECORDED',        -- RECORDED, IN_TRANSCRIPTION, AWAITING_REVIEW, SIGNED, CANCELLED
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: CNS-006, RAD-STR-005-like
CREATE TABLE IF NOT EXISTS clinicalcare.emr_quick_text (                      -- Favourite phrases, smart texts and macros per doctor / specialty
    quick_text_id              INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    owner_practitioner_id      BIGINT NULL,                                    -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    specialty_id               INT NULL,                                       -- logical FK -> identityorg.mst_specialty [Identity & Organization]
    shortcut                   VARCHAR(30) NOT NULL,
    expansion_text             TEXT NOT NULL,
    applies_to_section         VARCHAR(30) NULL,                               -- COMPLAINT, HISTORY, EXAM, IMPRESSION, ADVICE, ANY
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: MRV-008, DXL-003
CREATE TABLE IF NOT EXISTS clinicalcare.emr_record_deficiency (               -- Record completeness deficiencies per encounter (unsigned notes, missing diagnosis / discharge summary)
    record_deficiency_id       BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    encounter_id               BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_encounter [Patient Access & Engagement]
    deficiency_type            VARCHAR(30) NOT NULL,                           -- UNSIGNED_NOTE, MISSING_DIAGNOSIS, MISSING_DISCHARGE_SUMMARY, PENDING_COSIGN
    clinical_document_id       BIGINT NULL,
    responsible_practitioner_id BIGINT NULL,                                   -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    detected_at                TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at                TIMESTAMPTZ(0) NULL,
    deficiency_status          VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: MRV-009
CREATE TABLE IF NOT EXISTS clinicalcare.emr_release_of_information (          -- Release of information requests (patient, insurer, court) with purpose and authoriser
    release_of_information_id  BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    request_no                 VARCHAR(30) NOT NULL UNIQUE,
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    requester_type             VARCHAR(20) NOT NULL,                           -- PATIENT, INSURER, COURT, POLICE, EMPLOYER, OTHER_HOSPITAL
    requester_name             VARCHAR(150) NOT NULL,
    purpose                    VARCHAR(300) NOT NULL,
    documents_json             JSONB NOT NULL,                                 -- list of clinical_document / report ids released
    authorised_by              BIGINT NULL,
    authorised_at              TIMESTAMPTZ(0) NULL,
    released_at                TIMESTAMPTZ(0) NULL,
    release_mode               VARCHAR(20) NULL,                               -- PRINT, PDF_EXPORT, SECURE_LINK
    request_document_id        BIGINT NULL,                                    -- logical FK -> integrationcomms.core_document [Integration & Communications]
    roi_status                 VARCHAR(20) NOT NULL DEFAULT 'REQUESTED',
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TML-001..005, VHX-001
CREATE TABLE IF NOT EXISTS clinicalcare.emr_timeline_event (                  -- Clinical timeline projection (encounters, diagnoses, orders, results, meds, documents, external events)
    timeline_event_id          BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    encounter_id               BIGINT NULL,                                    -- logical FK -> patientengagement.pat_encounter [Patient Access & Engagement]
    event_type                 VARCHAR(30) NOT NULL,                           -- ENCOUNTER, DIAGNOSIS, PROBLEM, PROCEDURE, ORDER, RESULT, REPORT, MED_START, MED_STOP, VITAL_ALERT, DOCUMENT, EXTERNAL
    lane                       VARCHAR(20) NULL,                               -- MEDICATIONS, RESULTS, PROBLEMS, ENCOUNTERS, DOCUMENTS
    event_at                   TIMESTAMPTZ(0) NOT NULL,
    title                      VARCHAR(300) NOT NULL,
    source_service             VARCHAR(30) NOT NULL,
    source_entity_type         VARCHAR(40) NOT NULL,
    source_entity_id           BIGINT NOT NULL,
    department_id              INT NULL,                                       -- logical FK -> identityorg.mst_department [Identity & Organization]
    practitioner_id            BIGINT NULL,                                    -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    system_of_medicine         VARCHAR(20) NULL,
    is_external                BOOLEAN NOT NULL DEFAULT FALSE,
    external_source            VARCHAR(50) NULL,                               -- ABDM, UPLOAD, TRANSCRIBED
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: VIT-001..007, VSE-001..005, TKN-ARR-003 (OPD)
CREATE TABLE IF NOT EXISTS clinicalcare.emr_vital_set (                       -- One vitals capture event (set) with early-warning score
    vital_set_id               BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    encounter_id               BIGINT NULL,                                    -- logical FK -> patientengagement.pat_encounter [Patient Access & Engagement]
    measured_at                TIMESTAMPTZ(0) NOT NULL,
    source                     VARCHAR(20) NOT NULL,                           -- MANUAL, DEVICE, KIOSK, PATIENT_REPORTED, TRIAGE
    device_id                  BIGINT NULL,
    recorded_by                BIGINT NULL,
    validated_by               BIGINT NULL,
    validated_at               TIMESTAMPTZ(0) NULL,
    ews_type                   VARCHAR(10) NULL,                               -- NEWS2, PEWS, MEOWS
    ews_total_score            SMALLINT NULL,
    ews_risk_level             VARCHAR(10) NULL,                               -- LOW, MEDIUM, HIGH
    ews_alert_sent_at          TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: OBS-001..004, PAN-002, VSE-006
CREATE TABLE IF NOT EXISTS clinicalcare.emr_observation (                     -- Coded observations, measures, clinical scores and point-of-care tests (LOINC / SNOMED)
    observation_id             BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    encounter_id               BIGINT NULL,                                    -- logical FK -> patientengagement.pat_encounter [Patient Access & Engagement]
    observation_category       VARCHAR(20) NOT NULL,                           -- FINDING, MEASURE, SCORE, POC_TEST, ANTHROPOMETRY
    code_id                    BIGINT NULL,                                    -- logical FK -> identityorg.core_clinical_code [Identity & Organization]
    loinc_code_id              BIGINT NULL,                                    -- logical FK -> identityorg.core_clinical_code [Identity & Organization]
    observation_name           VARCHAR(200) NOT NULL,
    value_numeric              DECIMAL(14,4) NULL,
    value_text                 VARCHAR(1000) NULL,
    unit                       VARCHAR(20) NULL,
    scale_name                 VARCHAR(30) NULL,                               -- GCS, MMSE, PHQ9, NRS, VAS, WONG_BAKER, FLACC, AUDIT_C
    interpretation             VARCHAR(30) NULL,
    device_or_kit              VARCHAR(100) NULL,
    performed_by               BIGINT NULL,
    observed_at                TIMESTAMPTZ(0) NOT NULL,
    is_external                BOOLEAN NOT NULL DEFAULT FALSE,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: PAN-001..003
CREATE TABLE IF NOT EXISTS clinicalcare.emr_pain_assessment (                 -- SOCRATES pain description with body-diagram sites and pain scores
    pain_assessment_id         BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    encounter_id               BIGINT NULL,                                    -- logical FK -> patientengagement.pat_encounter [Patient Access & Engagement]
    complaint_id               BIGINT NULL,
    site_text                  VARCHAR(200) NULL,
    body_diagram_json          JSONB NULL,
    onset                      VARCHAR(100) NULL,
    character                  VARCHAR(100) NULL,
    radiation                  VARCHAR(100) NULL,
    associations               VARCHAR(200) NULL,
    time_course                VARCHAR(100) NULL,
    exacerbating_factors       VARCHAR(200) NULL,
    relieving_factors          VARCHAR(200) NULL,
    scale_type                 VARCHAR(20) NULL,                               -- NRS, VAS, WONG_BAKER, FLACC
    score                      DECIMAL(4,1) NULL,
    assessed_at                TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assessed_by                BIGINT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: SUB-003
CREATE TABLE IF NOT EXISTS clinicalcare.emr_review_of_systems (               -- Review-of-systems checklist by specialty with "negative unless stated"
    review_of_systems_id       BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    encounter_id               BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_encounter [Patient Access & Engagement]
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    body_system                VARCHAR(30) NOT NULL,
    is_negative                BOOLEAN NOT NULL DEFAULT TRUE,
    positive_findings          VARCHAR(1000) NULL,
    recorded_by                BIGINT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: SOC-001..003
CREATE TABLE IF NOT EXISTS clinicalcare.emr_social_history (                  -- Alcohol, tobacco, substance use and lifestyle with screening scores
    social_history_id          BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    encounter_id               BIGINT NULL,                                    -- logical FK -> patientengagement.pat_encounter [Patient Access & Engagement]
    habit_type                 VARCHAR(20) NOT NULL,                           -- ALCOHOL, TOBACCO, SUBSTANCE, DIET, ACTIVITY, SLEEP, OCCUPATIONAL_EXPOSURE
    habit_status               VARCHAR(20) NULL,                               -- NEVER, CURRENT, FORMER
    form_or_type               VARCHAR(50) NULL,                               -- cigarettes, bidi, gutka, vaping, beer, spirits ...
    quantity_value             DECIMAL(8,2) NULL,
    quantity_unit              VARCHAR(30) NULL,                               -- units/week, per day
    frequency                  VARCHAR(50) NULL,
    duration_years             DECIMAL(5,1) NULL,
    quit_date                  DATE NULL,
    pack_years                 DECIMAL(6,2) NULL,                              -- calculated
    screening_tool             VARCHAR(20) NULL,                               -- AUDIT_C, FAGERSTROM
    screening_score            SMALLINT NULL,
    readiness_to_quit          VARCHAR(20) NULL,
    notes                      VARCHAR(1000) NULL,
    recorded_at                TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: HIS-007
CREATE TABLE IF NOT EXISTS clinicalcare.emr_obstetric_history (               -- Obstetric and menstrual history (gravida, para, LMP, cycles)
    obstetric_history_id       BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    encounter_id               BIGINT NULL,                                    -- logical FK -> patientengagement.pat_encounter [Patient Access & Engagement]
    gravida                    SMALLINT NULL,
    para                       SMALLINT NULL,
    living_children            SMALLINT NULL,
    abortions                  SMALLINT NULL,
    lmp_date                   DATE NULL,
    edd_date                   DATE NULL,
    cycle_length_days          SMALLINT NULL,
    cycle_regularity           VARCHAR(20) NULL,
    menarche_age               SMALLINT NULL,
    menopause_age              SMALLINT NULL,
    is_pregnant                BOOLEAN NULL,
    is_lactating               BOOLEAN NULL,
    notes                      VARCHAR(1000) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: MRV-002, ALG-002, SEC-003
CREATE TABLE IF NOT EXISTS clinicalcare.emr_patient_clinical_flag (           -- Patient-level clinical alerts & statuses shown on banner (allergy status NKA / not assessed, pregnancy, isolation, fall risk, DNR)
    patient_clinical_flag_id   BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    flag_type                  VARCHAR(30) NOT NULL,                           -- ALLERGY_STATUS, PREGNANCY, ISOLATION, FALL_RISK, DNR, MDRO, VIP, SENSITIVE
    flag_value                 VARCHAR(50) NOT NULL,                           -- NKA, NOT_ASSESSED, KNOWN; MRSA; ...
    valid_from                 TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to                   TIMESTAMPTZ(0) NULL,
    source_service             VARCHAR(30) NULL,
    recorded_by                BIGINT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: HIS-005
CREATE TABLE IF NOT EXISTS clinicalcare.mst_immunization_schedule (           -- National / IAP immunisation schedule for due / overdue vaccines
    immunization_schedule_id   INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    schedule_code              VARCHAR(20) NOT NULL,                           -- NIS, IAP, ADULT
    vaccine_code_id            BIGINT NULL,                                    -- logical FK -> identityorg.core_clinical_code [Identity & Organization]
    vaccine_name               VARCHAR(150) NOT NULL,
    dose_no                    SMALLINT NOT NULL,
    due_age_days               INT NOT NULL,
    max_age_days               INT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: MRV-005, UPL-001..004, RES-005, TML-005 (External document entity)
CREATE TABLE IF NOT EXISTS clinicalcare.emr_external_document (               -- External records (uploaded, scanned, ABDM-fetched) - read-only, with OCR text
    external_document_id       BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    encounter_id               BIGINT NULL,                                    -- logical FK -> patientengagement.pat_encounter [Patient Access & Engagement]
    document_type              VARCHAR(30) NOT NULL,                           -- PRESCRIPTION, LAB_REPORT, IMAGING_REPORT, FILM_PHOTO, REFERRAL_LETTER, DISCHARGE_SUMMARY
    source                     VARCHAR(20) NOT NULL,                           -- UPLOAD, SCAN, ABDM, PATIENT_PORTAL
    source_facility            VARCHAR(200) NULL,
    document_date              DATE NULL,
    document_id                BIGINT NULL,                                    -- logical FK -> integrationcomms.core_document [Integration & Communications]
    abdm_consent_artefact_id   BIGINT NULL,                                    -- logical FK -> integrationcomms.intg_abdm_consent_artefact [Integration & Communications]
    ocr_text                   TEXT NULL,
    uploaded_by                BIGINT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: UPL-002, RES-005
CREATE TABLE IF NOT EXISTS clinicalcare.emr_external_result (                 -- Values transcribed from external documents, labelled "external"
    external_result_id         BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    external_document_id       BIGINT NOT NULL,
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    parameter_name             VARCHAR(150) NOT NULL,
    loinc_code_id              BIGINT NULL,                                    -- logical FK -> identityorg.core_clinical_code [Identity & Organization]
    value_numeric              DECIMAL(14,4) NULL,
    value_text                 VARCHAR(500) NULL,
    unit                       VARCHAR(20) NULL,
    result_date                DATE NULL,
    transcribed_by             BIGINT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: RES-003
CREATE TABLE IF NOT EXISTS clinicalcare.emr_result_acknowledgement (          -- Doctor results inbox acknowledgement (new / abnormal / critical, reviewed by, action taken)
    result_acknowledgement_id  BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    practitioner_id            BIGINT NOT NULL,                                -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    result_source              VARCHAR(10) NOT NULL,                           -- LAB, RAD
    result_ref_id              BIGINT NOT NULL,                                -- lims.lab_result / lims.lab_report / rims.rad_report id
    inbox_flag                 VARCHAR(10) NOT NULL,                           -- NEW, ABNORMAL, CRITICAL
    received_at                TIMESTAMPTZ(0) NOT NULL,
    acknowledged_at            TIMESTAMPTZ(0) NULL,
    action_taken               VARCHAR(500) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: PRB-001..005
CREATE TABLE IF NOT EXISTS clinicalcare.emr_problem (                         -- Patient problem list (coded, onset, status, severity) with history
    problem_id                 BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    clinical_code_id           BIGINT NULL,                                    -- logical FK -> identityorg.core_clinical_code [Identity & Organization]
    problem_text               VARCHAR(500) NOT NULL,
    source_diagnosis_id        BIGINT NULL,
    onset_date                 DATE NULL,
    problem_status             VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',          -- ACTIVE, INACTIVE, RESOLVED, ENTERED_IN_ERROR
    severity                   VARCHAR(20) NULL,
    is_chronic                 BOOLEAN NOT NULL DEFAULT FALSE,
    system_of_medicine         VARCHAR(20) NULL,
    resolved_date              DATE NULL,
    recorded_by                BIGINT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: PRB-003
CREATE TABLE IF NOT EXISTS clinicalcare.emr_problem_history (                 -- Change history of a problem
    problem_history_id         BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    problem_id                 BIGINT NOT NULL,
    old_status                 VARCHAR(20) NULL,
    new_status                 VARCHAR(20) NOT NULL,
    changed_at                 TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by                 BIGINT NULL,
    reason                     VARCHAR(300) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: PRB-005, CPL-001
CREATE TABLE IF NOT EXISTS clinicalcare.emr_problem_link (                    -- Links problems to care plans, medications and orders
    problem_link_id            BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    problem_id                 BIGINT NOT NULL,
    linked_entity_type         VARCHAR(30) NOT NULL,                           -- CARE_PLAN, PRESCRIPTION_ITEM, ORDER_ITEM, MEDICATION
    linked_entity_id           BIGINT NOT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: RXM-004, DDI-001, PHO-003
CREATE TABLE IF NOT EXISTS clinicalcare.emr_medication_list (                 -- Current medication list (hospital and outside medicines)
    medication_list_id         BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    drug_id                    INT NULL,                                       -- logical FK -> pharmacy.mst_drug [Pharmacy]
    generic_id                 INT NULL,                                       -- logical FK -> pharmacy.mst_generic [Pharmacy]
    medication_text            VARCHAR(300) NOT NULL,
    dose_text                  VARCHAR(100) NULL,
    frequency                  VARCHAR(50) NULL,
    route                      VARCHAR(20) NULL,
    source                     VARCHAR(20) NOT NULL,                           -- HOSPITAL_RX, OUTSIDE, ABDM, PATIENT_REPORTED
    prescription_item_id       BIGINT NULL,
    start_date                 DATE NULL,
    stop_date                  DATE NULL,
    medication_status          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',          -- ACTIVE, STOPPED, ON_HOLD, COMPLETED
    last_dispensed_at          TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: RXM-004
CREATE TABLE IF NOT EXISTS clinicalcare.emr_medication_reconciliation (       -- Medication reconciliation decisions at each visit (continue / change / stop)
    medication_reconciliation_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    encounter_id               BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_encounter [Patient Access & Engagement]
    medication_list_id         BIGINT NOT NULL,
    decision                   VARCHAR(20) NOT NULL,                           -- CONTINUE, CHANGE, STOP, NEW
    reason                     VARCHAR(300) NULL,
    decided_by                 BIGINT NOT NULL,
    decided_at                 TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TPL-002, MRV-010
CREATE TABLE IF NOT EXISTS clinicalcare.mst_template_assignment (             -- Assignment of templates to specialty, doctor, encounter type and system of medicine
    template_assignment_id     INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    clinical_template_id       INT NOT NULL,
    specialty_id               INT NULL,                                       -- logical FK -> identityorg.mst_specialty [Identity & Organization]
    practitioner_id            BIGINT NULL,                                    -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    encounter_type             VARCHAR(20) NULL,
    system_of_medicine         VARCHAR(20) NULL,
    is_default                 BOOLEAN NOT NULL DEFAULT FALSE,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: PLN-005, ORX-003
CREATE TABLE IF NOT EXISTS clinicalcare.emr_followup_request (                -- Follow-up advised (after N days / on date, tests before visit) sent to Patient Administration
    followup_request_id        BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    encounter_id               BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_encounter [Patient Access & Engagement]
    practitioner_id            BIGINT NULL,                                    -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    followup_after_days        SMALLINT NULL,
    followup_date              DATE NULL,
    tests_before_visit         BOOLEAN NOT NULL DEFAULT FALSE,
    order_id                   BIGINT NULL,
    instructions               VARCHAR(500) NULL,
    appointment_id             BIGINT NULL,                                    -- logical FK -> patientengagement.sch_appointment [Patient Access & Engagement]
    request_status             VARCHAR(20) NOT NULL DEFAULT 'REQUESTED',       -- REQUESTED, BOOKED, COMPLETED, MISSED, CANCELLED
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: CPL-001, CPL-002, ASM-004
CREATE TABLE IF NOT EXISTS clinicalcare.emr_care_plan_goal (                  -- Measurable care-plan goals tracked against recorded data
    care_plan_goal_id          BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    care_plan_id               BIGINT NOT NULL,
    problem_id                 BIGINT NULL,
    goal_text                  VARCHAR(500) NOT NULL,
    metric_code_id             BIGINT NULL,                                    -- logical FK -> identityorg.core_clinical_code [Identity & Organization]
    target_operator            VARCHAR(5) NULL,                                -- <, <=, =, >=, >
    target_value               DECIMAL(14,4) NULL,
    target_unit                VARCHAR(20) NULL,
    target_date                DATE NULL,
    latest_value               DECIMAL(14,4) NULL,
    latest_value_at            TIMESTAMPTZ(0) NULL,
    goal_status                VARCHAR(20) NOT NULL DEFAULT 'ON_TRACK',        -- ON_TRACK, OFF_TRACK, ACHIEVED, CANCELLED
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LBO-003, RDO-003, PHO-001, 6.3.6 Order status lifecycle
CREATE TABLE IF NOT EXISTS clinicalcare.ord_order_status_history (            -- Order item status history (ordered, collected, received, in process, resulted, cancelled)
    order_status_history_id    BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    order_item_id              BIGINT NOT NULL,
    item_status                VARCHAR(20) NOT NULL,
    status_at                  TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source_service             VARCHAR(20) NULL,
    changed_by                 BIGINT NULL,
    remarks                    VARCHAR(300) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: CDS-001..005
CREATE TABLE IF NOT EXISTS clinicalcare.cds_rule (                            -- Clinical decision support rules (conditions, actions, severity, target users, validity, test mode)
    rule_id                    INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    rule_code                  VARCHAR(50) NOT NULL,
    rule_name                  VARCHAR(200) NOT NULL,
    rule_category              VARCHAR(30) NOT NULL,                           -- PREVENTIVE_REMINDER, DRUG_SAFETY, ORDER_SUGGESTION, DIAGNOSIS_SUGGESTION, CARE_GAP
    version_no                 SMALLINT NOT NULL DEFAULT 1,
    condition_json             JSONB NOT NULL,
    action_json                JSONB NOT NULL,
    severity_grade             VARCHAR(10) NOT NULL,                           -- INFO, WARNING, HARD_STOP
    override_roles             VARCHAR(200) NULL,
    target_roles               VARCHAR(200) NULL,
    reference_url              VARCHAR(500) NULL,
    rule_status                VARCHAR(20) NOT NULL DEFAULT 'DRAFT',           -- DRAFT, TEST, ACTIVE, RETIRED
    valid_from                 DATE NULL,
    valid_to                   DATE NULL,
    approved_by                BIGINT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT                 uq_cds_rule_1 UNIQUE (rule_code, version_no)
);

-- [NEW v4] FDS ref: SGM-001..003, IVP-005
CREATE TABLE IF NOT EXISTS clinicalcare.cds_medication_suggestion (           -- Suggested medicines per diagnosis code with default dose, frequency and duration (guideline ranking)
    medication_suggestion_id   INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    clinical_code_id           BIGINT NOT NULL,                                -- logical FK -> identityorg.core_clinical_code [Identity & Organization]
    system_of_medicine         VARCHAR(20) NOT NULL DEFAULT 'ALLOPATHY',
    drug_id                    INT NULL,                                       -- logical FK -> pharmacy.mst_drug [Pharmacy]
    generic_id                 INT NULL,                                       -- logical FK -> pharmacy.mst_generic [Pharmacy]
    default_dose               VARCHAR(50) NULL,
    default_frequency          VARCHAR(30) NULL,
    default_duration_days      SMALLINT NULL,
    rank_order                 SMALLINT NOT NULL DEFAULT 1,
    line_of_therapy            VARCHAR(20) NULL,                               -- FIRST_LINE, SECOND_LINE
    age_min_days               INT NULL,
    age_max_days               INT NULL,
    gender                     VARCHAR(10) NULL,
    avoid_in_pregnancy         BOOLEAN NOT NULL DEFAULT FALSE,
    source                     VARCHAR(50) NULL,                               -- guideline / formulary committee
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: SGM-005
CREATE TABLE IF NOT EXISTS clinicalcare.cds_prescriber_preference (           -- Learned doctor preferences (frequently prescribed per diagnosis) for ranking suggestions
    prescriber_preference_id   BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    practitioner_id            BIGINT NOT NULL,                                -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    clinical_code_id           BIGINT NOT NULL,                                -- logical FK -> identityorg.core_clinical_code [Identity & Organization]
    drug_id                    INT NULL,                                       -- logical FK -> pharmacy.mst_drug [Pharmacy]
    use_count                  INT NOT NULL DEFAULT 0,
    last_used_at               TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: AYU-013..019, PRO-001
CREATE TABLE IF NOT EXISTS clinicalcare.mst_external_therapy (                -- AYUSH external therapy master (Panchakarma, Varmam, Thokkanam, Suttigai, Hijamah ...)
    external_therapy_id        INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    therapy_code               VARCHAR(30) NOT NULL UNIQUE,
    therapy_name               VARCHAR(150) NOT NULL,
    system_of_medicine         VARCHAR(20) NOT NULL,
    therapy_type               VARCHAR(30) NULL,                               -- PANCHAKARMA, VARMAM, THOKKANAM, SUTTIGAI, SWASTHAVRITTA, REGIMENAL, HIJAMAH
    clinical_code_id           BIGINT NULL,                                    -- NAMASTE / ICHI / local mapped | logical FK -> identityorg.core_clinical_code [Identity & Organization]
    service_id                 INT NULL,                                       -- logical FK -> revenuefinance.mst_service [Revenue & Finance]
    duration_minutes           SMALLINT NULL,
    default_sessions           SMALLINT NULL,
    materials_text             VARCHAR(500) NULL,                              -- oils, decoctions
    contraindications          VARCHAR(500) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: YOG-001..004
CREATE TABLE IF NOT EXISTS clinicalcare.mst_yoga_protocol (                   -- Yoga protocol master (asanas, pranayama, kriya, meditation) mapped to ICHI
    yoga_protocol_id           INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    protocol_code              VARCHAR(30) NOT NULL UNIQUE,
    protocol_name              VARCHAR(150) NOT NULL,
    component_type             VARCHAR(20) NOT NULL,                           -- ASANA, PRANAYAMA, KRIYA, MEDITATION, RELAXATION, MODULE
    clinical_code_id           BIGINT NULL,                                    -- logical FK -> identityorg.core_clinical_code [Identity & Organization]
    duration_minutes           SMALLINT NULL,
    indications                VARCHAR(500) NULL,
    contraindications          VARCHAR(500) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);


-- ===== FDS EHR / EMR - Section 5 Clinical Coding =====
-- [NEW v4] FDS ref: CRD-001..005 (Coder credential entity)
CREATE TABLE IF NOT EXISTS clinicalcare.cod_coder_credential (                -- Coder credentials (COC, CIC, CPC, CCS, AYUSH) with expiry and allowed work types
    coder_credential_id        BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    user_id                    BIGINT NOT NULL,                                -- logical FK -> identityorg.sec_user_account [Identity & Organization]
    employee_id                BIGINT NULL,                                    -- logical FK -> identityorg.hr_employee [Identity & Organization]
    credential_type            VARCHAR(20) NOT NULL,                           -- COC, CIC, CPC, CCS, AYUSH, TRAINEE
    credential_no              VARCHAR(50) NULL,
    issuing_body               VARCHAR(50) NULL,                               -- AAPC, AHIMA, MINISTRY_OF_AYUSH
    issued_on                  DATE NULL,
    expires_on                 DATE NULL,
    work_types_allowed         VARCHAR(100) NOT NULL,                          -- OP, IP, PROFESSIONAL, AYUSH, AUDIT, TRIAL
    is_supervised              BOOLEAN NOT NULL DEFAULT FALSE,
    credential_status          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',          -- ACTIVE, EXPIRED, SUSPENDED
    document_id                BIGINT NULL,                                    -- logical FK -> integrationcomms.core_document [Integration & Communications]
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: ALO-001..010, CWF-001..006 (Coding task entity), INS-012 (Billing)
CREATE TABLE IF NOT EXISTS clinicalcare.cod_coding_task (                     -- Coding work queue item per encounter (OP / IP / AYUSH / trial)
    coding_task_id             BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    task_no                    VARCHAR(30) NOT NULL UNIQUE,
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    encounter_id               BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_encounter [Patient Access & Engagement]
    work_type                  VARCHAR(20) NOT NULL,                           -- OP, IP, AYUSH, PROFESSIONAL, TRIAL
    payer_id                   INT NULL,                                       -- logical FK -> revenuefinance.mst_payer [Revenue & Finance]
    priority                   SMALLINT NOT NULL DEFAULT 5,
    due_at                     TIMESTAMPTZ(0) NULL,
    assigned_coder_id          BIGINT NULL,                                    -- logical FK -> identityorg.sec_user_account [Identity & Organization]
    assigned_at                TIMESTAMPTZ(0) NULL,
    task_status                VARCHAR(20) NOT NULL DEFAULT 'NEW',             -- NEW, ASSIGNED, IN_PROGRESS, QUERY_PENDING, COMPLETED, AUDIT, LOCKED, REOPENED
    completed_at               TIMESTAMPTZ(0) NULL,
    locked_at                  TIMESTAMPTZ(0) NULL,
    unlock_approved_by         BIGINT NULL,
    audit_score                DECIMAL(5,2) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: ALO-002, ALO-003, ALO-007, ALO-008, TRM-005
CREATE TABLE IF NOT EXISTS clinicalcare.cod_coding_task_code (                -- Codes assigned in a coding task (principal / secondary, POA, procedure, sequence, code set)
    coding_task_code_id        BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    coding_task_id             BIGINT NOT NULL,
    code_role                  VARCHAR(20) NOT NULL,                           -- PRINCIPAL_DX, SECONDARY_DX, REASON_FOR_VISIT, PROCEDURE, EXTERNAL_CAUSE, CAUSE_OF_DEATH
    clinical_code_id           BIGINT NOT NULL,                                -- logical FK -> identityorg.core_clinical_code [Identity & Organization]
    code_system_release_id     INT NULL,                                       -- logical FK -> identityorg.core_code_system_release [Identity & Organization]
    sequence_no                SMALLINT NOT NULL,
    present_on_admission       VARCHAR(5) NULL,
    is_cc_mcc                  BOOLEAN NOT NULL DEFAULT FALSE,
    source                     VARCHAR(20) NOT NULL,                           -- CLINICIAN, BILLED_SERVICE, CODER, AUTO_MAP
    validation_status          VARCHAR(20) NULL,                               -- VALID, WARNING, ERROR
    validation_message         VARCHAR(500) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: CWF-003
CREATE TABLE IF NOT EXISTS clinicalcare.cod_coder_query (                     -- Coder queries to doctors (missing specificity, conflicting documentation) with responses
    coder_query_id             BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    coding_task_id             BIGINT NOT NULL,
    to_practitioner_id         BIGINT NOT NULL,                                -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    query_text                 VARCHAR(2000) NOT NULL,
    raised_at                  TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    response_text              VARCHAR(2000) NULL,
    responded_at               TIMESTAMPTZ(0) NULL,
    query_status               VARCHAR(20) NOT NULL DEFAULT 'OPEN',            -- OPEN, ANSWERED, CLOSED, ESCALATED
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: CWF-004, CWF-005, CRD-005
CREATE TABLE IF NOT EXISTS clinicalcare.cod_coding_audit (                    -- Coding audits (random / targeted), re-coding, accuracy score and feedback
    coding_audit_id            BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    coding_task_id             BIGINT NOT NULL,
    auditor_user_id            BIGINT NOT NULL,                                -- logical FK -> identityorg.sec_user_account [Identity & Organization]
    sample_type                VARCHAR(20) NOT NULL,                           -- RANDOM, TARGETED
    codes_reviewed             SMALLINT NULL,
    codes_changed              SMALLINT NULL,
    accuracy_score             DECIMAL(5,2) NULL,
    feedback                   VARCHAR(2000) NULL,
    audited_at                 TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: INT-007, ALO-010
CREATE TABLE IF NOT EXISTS clinicalcare.cod_drg_grouping (                    -- DRG / HCC grouping result of a coded IP episode
    drg_grouping_id            BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    coding_task_id             BIGINT NOT NULL,
    encounter_id               BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_encounter [Patient Access & Engagement]
    grouper_name               VARCHAR(50) NOT NULL,
    grouper_version            VARCHAR(20) NULL,
    drg_code                   VARCHAR(20) NOT NULL,
    drg_description            VARCHAR(300) NULL,
    relative_weight            DECIMAL(8,4) NULL,
    expected_los_days          DECIMAL(6,2) NULL,
    expected_amount            DECIMAL(14,2) NULL,
    hcc_codes                  VARCHAR(200) NULL,
    grouped_at                 TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: HOM-005..011 (Trial participant data entity)
CREATE TABLE IF NOT EXISTS clinicalcare.cod_trial_participant (               -- Clinical trial participants (trial id, arm)
    trial_participant_id       BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    trial_code                 VARCHAR(50) NOT NULL,
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    subject_no                 VARCHAR(50) NOT NULL,
    trial_arm                  VARCHAR(50) NULL,
    enrolled_on                DATE NULL,
    withdrawn_on               DATE NULL,
    consent_id                 BIGINT NULL,                                    -- logical FK -> patientengagement.pat_consent [Patient Access & Engagement]
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: HOM-006..011
CREATE TABLE IF NOT EXISTS clinicalcare.cod_trial_event (                     -- Trial AE / MH / CM entries coded with MedDRA / WHO-DDE
    trial_event_id             BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    trial_participant_id       BIGINT NOT NULL,
    event_category             VARCHAR(5) NOT NULL,                            -- AE, MH, CM
    verbatim_term              VARCHAR(500) NOT NULL,
    clinical_code_id           BIGINT NULL,                                    -- MedDRA LLT/PT or WHO-DDE | logical FK -> identityorg.core_clinical_code [Identity & Organization]
    code_system_release_id     INT NULL,                                       -- logical FK -> identityorg.core_code_system_release [Identity & Organization]
    onset_date                 DATE NULL,
    end_date                   DATE NULL,
    severity                   VARCHAR(20) NULL,
    seriousness                VARCHAR(20) NULL,
    causality                  VARCHAR(30) NULL,
    exported_at                TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] replica of identityorg.core_code_system_release, owned by Identity & Organization; used by: clinicalcare.emr_diagnosis, clinicalcare.cod_coding_task_code
CREATE TABLE IF NOT EXISTS clinicalcare.ref_code_system_release (
    code_system_release_id     INT PRIMARY KEY,
    organization_id            INT NULL,
    code_system_id             INT NULL,
    release_version            VARCHAR(30) NULL,
    release_date               DATE NULL,
    effective_from             DATE NULL,
    effective_to               DATE NULL,
    release_status             VARCHAR(20) NULL,                               -- DRAFT, ACTIVE, RETIRED
    licence_reference          VARCHAR(100) NULL,
    source_file_uri            VARCHAR(500) NULL,
    impact_report_uri          VARCHAR(500) NULL,                              -- codes retired / changed vs previous release
    loaded_at                  TIMESTAMPTZ(0) NULL,
    loaded_by                  BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    source_version             BIGINT NULL,                                    -- version / sequence from publisher (ignore stale events)
    replicated_at              TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);


/* ---------- C. FOREIGN KEYS (same service only) ---------- */
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_emr_document_signature_clinical_document_id') THEN
        ALTER TABLE clinicalcare.emr_document_signature ADD CONSTRAINT fk_emr_document_signature_clinical_document_id FOREIGN KEY (clinical_document_id) REFERENCES clinicalcare.emr_clinical_document(clinical_document_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_emr_dictation_clinical_document_id') THEN
        ALTER TABLE clinicalcare.emr_dictation ADD CONSTRAINT fk_emr_dictation_clinical_document_id FOREIGN KEY (clinical_document_id) REFERENCES clinicalcare.emr_clinical_document(clinical_document_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_emr_dictation_dictation_template_id') THEN
        ALTER TABLE clinicalcare.emr_dictation ADD CONSTRAINT fk_emr_dictation_dictation_template_id FOREIGN KEY (dictation_template_id) REFERENCES clinicalcare.mst_clinical_template(clinical_template_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_emr_record_deficiency_clinical_document_id') THEN
        ALTER TABLE clinicalcare.emr_record_deficiency ADD CONSTRAINT fk_emr_record_deficiency_clinical_document_id FOREIGN KEY (clinical_document_id) REFERENCES clinicalcare.emr_clinical_document(clinical_document_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_emr_pain_assessment_complaint_id') THEN
        ALTER TABLE clinicalcare.emr_pain_assessment ADD CONSTRAINT fk_emr_pain_assessment_complaint_id FOREIGN KEY (complaint_id) REFERENCES clinicalcare.emr_complaint(complaint_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_emr_external_result_external_document_id') THEN
        ALTER TABLE clinicalcare.emr_external_result ADD CONSTRAINT fk_emr_external_result_external_document_id FOREIGN KEY (external_document_id) REFERENCES clinicalcare.emr_external_document(external_document_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_emr_problem_source_diagnosis_id') THEN
        ALTER TABLE clinicalcare.emr_problem ADD CONSTRAINT fk_emr_problem_source_diagnosis_id FOREIGN KEY (source_diagnosis_id) REFERENCES clinicalcare.emr_diagnosis(diagnosis_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_emr_problem_history_problem_id') THEN
        ALTER TABLE clinicalcare.emr_problem_history ADD CONSTRAINT fk_emr_problem_history_problem_id FOREIGN KEY (problem_id) REFERENCES clinicalcare.emr_problem(problem_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_emr_problem_link_problem_id') THEN
        ALTER TABLE clinicalcare.emr_problem_link ADD CONSTRAINT fk_emr_problem_link_problem_id FOREIGN KEY (problem_id) REFERENCES clinicalcare.emr_problem(problem_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_emr_medication_list_prescription_item_id') THEN
        ALTER TABLE clinicalcare.emr_medication_list ADD CONSTRAINT fk_emr_medication_list_prescription_item_id FOREIGN KEY (prescription_item_id) REFERENCES clinicalcare.ord_prescription_item(prescription_item_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_emr_medication_reconciliation_medication_list_id') THEN
        ALTER TABLE clinicalcare.emr_medication_reconciliation ADD CONSTRAINT fk_emr_medication_reconciliation_medication_list_id FOREIGN KEY (medication_list_id) REFERENCES clinicalcare.emr_medication_list(medication_list_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_mst_template_assignment_clinical_template_id') THEN
        ALTER TABLE clinicalcare.mst_template_assignment ADD CONSTRAINT fk_mst_template_assignment_clinical_template_id FOREIGN KEY (clinical_template_id) REFERENCES clinicalcare.mst_clinical_template(clinical_template_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_emr_followup_request_order_id') THEN
        ALTER TABLE clinicalcare.emr_followup_request ADD CONSTRAINT fk_emr_followup_request_order_id FOREIGN KEY (order_id) REFERENCES clinicalcare.ord_clinical_order(order_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_emr_care_plan_goal_care_plan_id') THEN
        ALTER TABLE clinicalcare.emr_care_plan_goal ADD CONSTRAINT fk_emr_care_plan_goal_care_plan_id FOREIGN KEY (care_plan_id) REFERENCES clinicalcare.emr_care_plan(care_plan_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_emr_care_plan_goal_problem_id') THEN
        ALTER TABLE clinicalcare.emr_care_plan_goal ADD CONSTRAINT fk_emr_care_plan_goal_problem_id FOREIGN KEY (problem_id) REFERENCES clinicalcare.emr_problem(problem_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_ord_order_status_history_order_item_id') THEN
        ALTER TABLE clinicalcare.ord_order_status_history ADD CONSTRAINT fk_ord_order_status_history_order_item_id FOREIGN KEY (order_item_id) REFERENCES clinicalcare.ord_order_item(order_item_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_cod_coding_task_code_coding_task_id') THEN
        ALTER TABLE clinicalcare.cod_coding_task_code ADD CONSTRAINT fk_cod_coding_task_code_coding_task_id FOREIGN KEY (coding_task_id) REFERENCES clinicalcare.cod_coding_task(coding_task_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_cod_coder_query_coding_task_id') THEN
        ALTER TABLE clinicalcare.cod_coder_query ADD CONSTRAINT fk_cod_coder_query_coding_task_id FOREIGN KEY (coding_task_id) REFERENCES clinicalcare.cod_coding_task(coding_task_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_cod_coding_audit_coding_task_id') THEN
        ALTER TABLE clinicalcare.cod_coding_audit ADD CONSTRAINT fk_cod_coding_audit_coding_task_id FOREIGN KEY (coding_task_id) REFERENCES clinicalcare.cod_coding_task(coding_task_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_cod_drg_grouping_coding_task_id') THEN
        ALTER TABLE clinicalcare.cod_drg_grouping ADD CONSTRAINT fk_cod_drg_grouping_coding_task_id FOREIGN KEY (coding_task_id) REFERENCES clinicalcare.cod_coding_task(coding_task_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_cod_trial_event_trial_participant_id') THEN
        ALTER TABLE clinicalcare.cod_trial_event ADD CONSTRAINT fk_cod_trial_event_trial_participant_id FOREIGN KEY (trial_participant_id) REFERENCES clinicalcare.cod_trial_participant(trial_participant_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_emr_care_plan_template_id') THEN
        ALTER TABLE clinicalcare.emr_care_plan ADD CONSTRAINT fk_emr_care_plan_template_id FOREIGN KEY (template_id) REFERENCES clinicalcare.mst_clinical_template(clinical_template_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_emr_care_plan_template_id ON clinicalcare.emr_care_plan(template_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_emr_care_plan_activity_care_plan_goal_id') THEN
        ALTER TABLE clinicalcare.emr_care_plan_activity ADD CONSTRAINT fk_emr_care_plan_activity_care_plan_goal_id FOREIGN KEY (care_plan_goal_id) REFERENCES clinicalcare.emr_care_plan_goal(care_plan_goal_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_emr_care_plan_activity_care_plan_goal_id ON clinicalcare.emr_care_plan_activity(care_plan_goal_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_emr_clinical_document_parent_document_id') THEN
        ALTER TABLE clinicalcare.emr_clinical_document ADD CONSTRAINT fk_emr_clinical_document_parent_document_id FOREIGN KEY (parent_document_id) REFERENCES clinicalcare.emr_clinical_document(clinical_document_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_emr_clinical_document_parent_document_id ON clinicalcare.emr_clinical_document(parent_document_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_emr_clinical_document_copied_from_document_id') THEN
        ALTER TABLE clinicalcare.emr_clinical_document ADD CONSTRAINT fk_emr_clinical_document_copied_from_document_id FOREIGN KEY (copied_from_document_id) REFERENCES clinicalcare.emr_clinical_document(clinical_document_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_emr_clinical_document_copied_from_document_id ON clinicalcare.emr_clinical_document(copied_from_document_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_emr_vital_sign_vital_set_id') THEN
        ALTER TABLE clinicalcare.emr_vital_sign ADD CONSTRAINT fk_emr_vital_sign_vital_set_id FOREIGN KEY (vital_set_id) REFERENCES clinicalcare.emr_vital_set(vital_set_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_emr_vital_sign_vital_set_id ON clinicalcare.emr_vital_sign(vital_set_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_emr_vital_sign_corrected_from_vital_sign_id') THEN
        ALTER TABLE clinicalcare.emr_vital_sign ADD CONSTRAINT fk_emr_vital_sign_corrected_from_vital_sign_id FOREIGN KEY (corrected_from_vital_sign_id) REFERENCES clinicalcare.emr_vital_sign(vital_sign_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_emr_vital_sign_corrected_from_vital_sign_id ON clinicalcare.emr_vital_sign(corrected_from_vital_sign_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_ord_cds_alert_cds_rule_id') THEN
        ALTER TABLE clinicalcare.ord_cds_alert ADD CONSTRAINT fk_ord_cds_alert_cds_rule_id FOREIGN KEY (cds_rule_id) REFERENCES clinicalcare.cds_rule(rule_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_ord_cds_alert_cds_rule_id ON clinicalcare.ord_cds_alert(cds_rule_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_ord_clinical_order_source_order_set_id') THEN
        ALTER TABLE clinicalcare.ord_clinical_order ADD CONSTRAINT fk_ord_clinical_order_source_order_set_id FOREIGN KEY (source_order_set_id) REFERENCES clinicalcare.mst_order_set(order_set_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_ord_clinical_order_source_order_set_id ON clinicalcare.ord_clinical_order(source_order_set_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_ord_clinical_order_copied_from_order_id') THEN
        ALTER TABLE clinicalcare.ord_clinical_order ADD CONSTRAINT fk_ord_clinical_order_copied_from_order_id FOREIGN KEY (copied_from_order_id) REFERENCES clinicalcare.ord_clinical_order(order_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_ord_clinical_order_copied_from_order_id ON clinicalcare.ord_clinical_order(copied_from_order_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'clinicalcare' AND c.conname = 'fk_ord_prescription_renewal_of_prescription_id') THEN
        ALTER TABLE clinicalcare.ord_prescription ADD CONSTRAINT fk_ord_prescription_renewal_of_prescription_id FOREIGN KEY (renewal_of_prescription_id) REFERENCES clinicalcare.ord_prescription(prescription_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_ord_prescription_renewal_of_prescription_id ON clinicalcare.ord_prescription(renewal_of_prescription_id);

/* ---------- D. INDEXES ---------- */
CREATE INDEX IF NOT EXISTS ix_emr_document_signature_clinical_document_id ON clinicalcare.emr_document_signature(clinical_document_id);
CREATE INDEX IF NOT EXISTS ix_emr_dictation_patient_id ON clinicalcare.emr_dictation(patient_id);
CREATE INDEX IF NOT EXISTS ix_emr_dictation_encounter_id ON clinicalcare.emr_dictation(encounter_id);
CREATE INDEX IF NOT EXISTS ix_emr_dictation_clinical_document_id ON clinicalcare.emr_dictation(clinical_document_id);
CREATE INDEX IF NOT EXISTS ix_emr_dictation_dictation_template_id ON clinicalcare.emr_dictation(dictation_template_id);
CREATE INDEX IF NOT EXISTS ix_emr_record_deficiency_patient_id ON clinicalcare.emr_record_deficiency(patient_id);
CREATE INDEX IF NOT EXISTS ix_emr_record_deficiency_encounter_id ON clinicalcare.emr_record_deficiency(encounter_id);
CREATE INDEX IF NOT EXISTS ix_emr_record_deficiency_clinical_document_id ON clinicalcare.emr_record_deficiency(clinical_document_id);
CREATE INDEX IF NOT EXISTS ix_emr_release_of_information_patient_id ON clinicalcare.emr_release_of_information(patient_id);
CREATE INDEX IF NOT EXISTS ix_emr_timeline_event_patient_id ON clinicalcare.emr_timeline_event(patient_id);
CREATE INDEX IF NOT EXISTS ix_emr_timeline_event_encounter_id ON clinicalcare.emr_timeline_event(encounter_id);
CREATE INDEX IF NOT EXISTS ix_emr_vital_set_patient_id ON clinicalcare.emr_vital_set(patient_id);
CREATE INDEX IF NOT EXISTS ix_emr_vital_set_encounter_id ON clinicalcare.emr_vital_set(encounter_id);
CREATE INDEX IF NOT EXISTS ix_emr_observation_patient_id ON clinicalcare.emr_observation(patient_id);
CREATE INDEX IF NOT EXISTS ix_emr_observation_encounter_id ON clinicalcare.emr_observation(encounter_id);
CREATE INDEX IF NOT EXISTS ix_emr_pain_assessment_patient_id ON clinicalcare.emr_pain_assessment(patient_id);
CREATE INDEX IF NOT EXISTS ix_emr_pain_assessment_encounter_id ON clinicalcare.emr_pain_assessment(encounter_id);
CREATE INDEX IF NOT EXISTS ix_emr_pain_assessment_complaint_id ON clinicalcare.emr_pain_assessment(complaint_id);
CREATE INDEX IF NOT EXISTS ix_emr_review_of_systems_encounter_id ON clinicalcare.emr_review_of_systems(encounter_id);
CREATE INDEX IF NOT EXISTS ix_emr_review_of_systems_patient_id ON clinicalcare.emr_review_of_systems(patient_id);
CREATE INDEX IF NOT EXISTS ix_emr_social_history_patient_id ON clinicalcare.emr_social_history(patient_id);
CREATE INDEX IF NOT EXISTS ix_emr_social_history_encounter_id ON clinicalcare.emr_social_history(encounter_id);
CREATE INDEX IF NOT EXISTS ix_emr_obstetric_history_patient_id ON clinicalcare.emr_obstetric_history(patient_id);
CREATE INDEX IF NOT EXISTS ix_emr_obstetric_history_encounter_id ON clinicalcare.emr_obstetric_history(encounter_id);
CREATE INDEX IF NOT EXISTS ix_emr_patient_clinical_flag_patient_id ON clinicalcare.emr_patient_clinical_flag(patient_id);
CREATE INDEX IF NOT EXISTS ix_emr_external_document_patient_id ON clinicalcare.emr_external_document(patient_id);
CREATE INDEX IF NOT EXISTS ix_emr_external_document_encounter_id ON clinicalcare.emr_external_document(encounter_id);
CREATE INDEX IF NOT EXISTS ix_emr_external_result_external_document_id ON clinicalcare.emr_external_result(external_document_id);
CREATE INDEX IF NOT EXISTS ix_emr_external_result_patient_id ON clinicalcare.emr_external_result(patient_id);
CREATE INDEX IF NOT EXISTS ix_emr_result_acknowledgement_patient_id ON clinicalcare.emr_result_acknowledgement(patient_id);
CREATE INDEX IF NOT EXISTS ix_emr_problem_patient_id ON clinicalcare.emr_problem(patient_id);
CREATE INDEX IF NOT EXISTS ix_emr_problem_source_diagnosis_id ON clinicalcare.emr_problem(source_diagnosis_id);
CREATE INDEX IF NOT EXISTS ix_emr_problem_history_problem_id ON clinicalcare.emr_problem_history(problem_id);
CREATE INDEX IF NOT EXISTS ix_emr_problem_link_problem_id ON clinicalcare.emr_problem_link(problem_id);
CREATE INDEX IF NOT EXISTS ix_emr_medication_list_patient_id ON clinicalcare.emr_medication_list(patient_id);
CREATE INDEX IF NOT EXISTS ix_emr_medication_list_prescription_item_id ON clinicalcare.emr_medication_list(prescription_item_id);
CREATE INDEX IF NOT EXISTS ix_emr_medication_reconciliation_encounter_id ON clinicalcare.emr_medication_reconciliation(encounter_id);
CREATE INDEX IF NOT EXISTS ix_emr_medication_reconciliation_medication_list_id ON clinicalcare.emr_medication_reconciliation(medication_list_id);
CREATE INDEX IF NOT EXISTS ix_mst_template_assignment_clinical_template_id ON clinicalcare.mst_template_assignment(clinical_template_id);
CREATE INDEX IF NOT EXISTS ix_emr_followup_request_patient_id ON clinicalcare.emr_followup_request(patient_id);
CREATE INDEX IF NOT EXISTS ix_emr_followup_request_encounter_id ON clinicalcare.emr_followup_request(encounter_id);
CREATE INDEX IF NOT EXISTS ix_emr_followup_request_order_id ON clinicalcare.emr_followup_request(order_id);
CREATE INDEX IF NOT EXISTS ix_emr_care_plan_goal_care_plan_id ON clinicalcare.emr_care_plan_goal(care_plan_id);
CREATE INDEX IF NOT EXISTS ix_emr_care_plan_goal_problem_id ON clinicalcare.emr_care_plan_goal(problem_id);
CREATE INDEX IF NOT EXISTS ix_ord_order_status_history_order_item_id ON clinicalcare.ord_order_status_history(order_item_id);
CREATE INDEX IF NOT EXISTS ix_cod_coding_task_patient_id ON clinicalcare.cod_coding_task(patient_id);
CREATE INDEX IF NOT EXISTS ix_cod_coding_task_encounter_id ON clinicalcare.cod_coding_task(encounter_id);
CREATE INDEX IF NOT EXISTS ix_cod_coding_task_code_coding_task_id ON clinicalcare.cod_coding_task_code(coding_task_id);
CREATE INDEX IF NOT EXISTS ix_cod_coder_query_coding_task_id ON clinicalcare.cod_coder_query(coding_task_id);
CREATE INDEX IF NOT EXISTS ix_cod_coding_audit_coding_task_id ON clinicalcare.cod_coding_audit(coding_task_id);
CREATE INDEX IF NOT EXISTS ix_cod_drg_grouping_coding_task_id ON clinicalcare.cod_drg_grouping(coding_task_id);
CREATE INDEX IF NOT EXISTS ix_cod_drg_grouping_encounter_id ON clinicalcare.cod_drg_grouping(encounter_id);
CREATE INDEX IF NOT EXISTS ix_cod_trial_participant_patient_id ON clinicalcare.cod_trial_participant(patient_id);
CREATE INDEX IF NOT EXISTS ix_cod_trial_event_trial_participant_id ON clinicalcare.cod_trial_event(trial_participant_id);

/* ---------- E. TABLE COMMENTS (FDS traceability) ---------- */
COMMENT ON TABLE clinicalcare.emr_document_signature IS 'Signatures on clinical documents (author, co-signer, verifier) with method and registration no [FDS: DOC-003, DOC-004, SEC-004]';
COMMENT ON TABLE clinicalcare.emr_dictation IS 'Dictation audio and transcription workflow (recorded, in transcription, awaiting review, signed) [FDS: DIT-001..006, VTX-001..004]';
COMMENT ON TABLE clinicalcare.emr_quick_text IS 'Favourite phrases, smart texts and macros per doctor / specialty [FDS: CNS-006, RAD-STR-005-like]';
COMMENT ON TABLE clinicalcare.emr_record_deficiency IS 'Record completeness deficiencies per encounter (unsigned notes, missing diagnosis / discharge summary) [FDS: MRV-008, DXL-003]';
COMMENT ON TABLE clinicalcare.emr_release_of_information IS 'Release of information requests (patient, insurer, court) with purpose and authoriser [FDS: MRV-009]';
COMMENT ON TABLE clinicalcare.emr_timeline_event IS 'Clinical timeline projection (encounters, diagnoses, orders, results, meds, documents, external events) [FDS: TML-001..005, VHX-001]';
COMMENT ON TABLE clinicalcare.emr_vital_set IS 'One vitals capture event (set) with early-warning score [FDS: VIT-001..007, VSE-001..005, TKN-ARR-003 (OPD)]';
COMMENT ON TABLE clinicalcare.emr_observation IS 'Coded observations, measures, clinical scores and point-of-care tests (LOINC / SNOMED) [FDS: OBS-001..004, PAN-002, VSE-006]';
COMMENT ON TABLE clinicalcare.emr_pain_assessment IS 'SOCRATES pain description with body-diagram sites and pain scores [FDS: PAN-001..003]';
COMMENT ON TABLE clinicalcare.emr_review_of_systems IS 'Review-of-systems checklist by specialty with "negative unless stated" [FDS: SUB-003]';
COMMENT ON TABLE clinicalcare.emr_social_history IS 'Alcohol, tobacco, substance use and lifestyle with screening scores [FDS: SOC-001..003]';
COMMENT ON TABLE clinicalcare.emr_obstetric_history IS 'Obstetric and menstrual history (gravida, para, LMP, cycles) [FDS: HIS-007]';
COMMENT ON TABLE clinicalcare.emr_patient_clinical_flag IS 'Patient-level clinical alerts & statuses shown on banner (allergy status NKA / not assessed, pregnancy, isolation, fall risk, DNR) [FDS: MRV-002, ALG-002, SEC-003]';
COMMENT ON TABLE clinicalcare.mst_immunization_schedule IS 'National / IAP immunisation schedule for due / overdue vaccines [FDS: HIS-005]';
COMMENT ON TABLE clinicalcare.emr_external_document IS 'External records (uploaded, scanned, ABDM-fetched) - read-only, with OCR text [FDS: MRV-005, UPL-001..004, RES-005, TML-005 (External document entity)]';
COMMENT ON TABLE clinicalcare.emr_external_result IS 'Values transcribed from external documents, labelled "external" [FDS: UPL-002, RES-005]';
COMMENT ON TABLE clinicalcare.emr_result_acknowledgement IS 'Doctor results inbox acknowledgement (new / abnormal / critical, reviewed by, action taken) [FDS: RES-003]';
COMMENT ON TABLE clinicalcare.emr_problem IS 'Patient problem list (coded, onset, status, severity) with history [FDS: PRB-001..005]';
COMMENT ON TABLE clinicalcare.emr_problem_history IS 'Change history of a problem [FDS: PRB-003]';
COMMENT ON TABLE clinicalcare.emr_problem_link IS 'Links problems to care plans, medications and orders [FDS: PRB-005, CPL-001]';
COMMENT ON TABLE clinicalcare.emr_medication_list IS 'Current medication list (hospital and outside medicines) [FDS: RXM-004, DDI-001, PHO-003]';
COMMENT ON TABLE clinicalcare.emr_medication_reconciliation IS 'Medication reconciliation decisions at each visit (continue / change / stop) [FDS: RXM-004]';
COMMENT ON TABLE clinicalcare.mst_template_assignment IS 'Assignment of templates to specialty, doctor, encounter type and system of medicine [FDS: TPL-002, MRV-010]';
COMMENT ON TABLE clinicalcare.emr_followup_request IS 'Follow-up advised (after N days / on date, tests before visit) sent to Patient Administration [FDS: PLN-005, ORX-003]';
COMMENT ON TABLE clinicalcare.emr_care_plan_goal IS 'Measurable care-plan goals tracked against recorded data [FDS: CPL-001, CPL-002, ASM-004]';
COMMENT ON TABLE clinicalcare.ord_order_status_history IS 'Order item status history (ordered, collected, received, in process, resulted, cancelled) [FDS: LBO-003, RDO-003, PHO-001, 6.3.6 Order status lifecycle]';
COMMENT ON TABLE clinicalcare.cds_rule IS 'Clinical decision support rules (conditions, actions, severity, target users, validity, test mode) [FDS: CDS-001..005]';
COMMENT ON TABLE clinicalcare.cds_medication_suggestion IS 'Suggested medicines per diagnosis code with default dose, frequency and duration (guideline ranking) [FDS: SGM-001..003, IVP-005]';
COMMENT ON TABLE clinicalcare.cds_prescriber_preference IS 'Learned doctor preferences (frequently prescribed per diagnosis) for ranking suggestions [FDS: SGM-005]';
COMMENT ON TABLE clinicalcare.mst_external_therapy IS 'AYUSH external therapy master (Panchakarma, Varmam, Thokkanam, Suttigai, Hijamah ...) [FDS: AYU-013..019, PRO-001]';
COMMENT ON TABLE clinicalcare.mst_yoga_protocol IS 'Yoga protocol master (asanas, pranayama, kriya, meditation) mapped to ICHI [FDS: YOG-001..004]';
COMMENT ON TABLE clinicalcare.cod_coder_credential IS 'Coder credentials (COC, CIC, CPC, CCS, AYUSH) with expiry and allowed work types [FDS: CRD-001..005 (Coder credential entity)]';
COMMENT ON TABLE clinicalcare.cod_coding_task IS 'Coding work queue item per encounter (OP / IP / AYUSH / trial) [FDS: ALO-001..010, CWF-001..006 (Coding task entity), INS-012 (Billing)]';
COMMENT ON TABLE clinicalcare.cod_coding_task_code IS 'Codes assigned in a coding task (principal / secondary, POA, procedure, sequence, code set) [FDS: ALO-002, ALO-003, ALO-007, ALO-008, TRM-005]';
COMMENT ON TABLE clinicalcare.cod_coder_query IS 'Coder queries to doctors (missing specificity, conflicting documentation) with responses [FDS: CWF-003]';
COMMENT ON TABLE clinicalcare.cod_coding_audit IS 'Coding audits (random / targeted), re-coding, accuracy score and feedback [FDS: CWF-004, CWF-005, CRD-005]';
COMMENT ON TABLE clinicalcare.cod_drg_grouping IS 'DRG / HCC grouping result of a coded IP episode [FDS: INT-007, ALO-010]';
COMMENT ON TABLE clinicalcare.cod_trial_participant IS 'Clinical trial participants (trial id, arm) [FDS: HOM-005..011 (Trial participant data entity)]';
COMMENT ON TABLE clinicalcare.cod_trial_event IS 'Trial AE / MH / CM entries coded with MedDRA / WHO-DDE [FDS: HOM-006..011]';

COMMIT;
