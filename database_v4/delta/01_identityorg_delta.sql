/* =====================================================================================
   DR REDDIS HEALTHCARE - HIMS  database_v3 (7 services)  ->  database_v4 (9 services)
   Step 01 - Identity & Organization: column additions to existing tables + new FDS tables
   Run against an EXISTING himsdev database that was built from database_v3, in file-name order:
     00_restructure_7_to_9_services.sql  -> 01..09_<service>_delta.sql  -> 10_post_migration_housekeeping.sql -> ../full/roles.sql
   Every statement is idempotent where PostgreSQL allows it (IF NOT EXISTS / guarded DO blocks).
   ===================================================================================== */

BEGIN;

/* ---------- A. MODIFICATIONS TO EXISTING TABLES (ADD COLUMN) ---------- */

-- identityorg.core_audit_log  (5 new columns)  FDS: SEC-003 (OPD), SEC-002 (EHR), ACC-009 (Billing), VWR-SEC-002 (PACS), SEC-003 (Pharmacy)
ALTER TABLE identityorg.core_audit_log ADD COLUMN IF NOT EXISTS service_code VARCHAR(30) NULL;
ALTER TABLE identityorg.core_audit_log ADD COLUMN IF NOT EXISTS terminal_id VARCHAR(100) NULL;
ALTER TABLE identityorg.core_audit_log ADD COLUMN IF NOT EXISTS outcome VARCHAR(20) NULL;
ALTER TABLE identityorg.core_audit_log ADD COLUMN IF NOT EXISTS is_break_glass BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE identityorg.core_audit_log ADD COLUMN IF NOT EXISTS break_glass_access_id BIGINT NULL;
COMMENT ON COLUMN identityorg.core_audit_log.service_code IS 'owning microservice [v4: SEC-003 (OPD), SEC-002 (EHR), ACC-009 (Billing), VWR-SEC-002 (PACS), SEC-003 (Pharmacy)]';
COMMENT ON COLUMN identityorg.core_audit_log.terminal_id IS 'workstation / device id [v4: SEC-003 (OPD), SEC-002 (EHR), ACC-009 (Billing), VWR-SEC-002 (PACS), SEC-003 (Pharmacy)]';
COMMENT ON COLUMN identityorg.core_audit_log.outcome IS 'SUCCESS, DENIED, FAILED [v4: SEC-003 (OPD), SEC-002 (EHR), ACC-009 (Billing), VWR-SEC-002 (PACS), SEC-003 (Pharmacy)]';
COMMENT ON COLUMN identityorg.core_audit_log.is_break_glass IS '[v4: SEC-003 (OPD), SEC-002 (EHR), ACC-009 (Billing), VWR-SEC-002 (PACS), SEC-003 (Pharmacy)]';
COMMENT ON COLUMN identityorg.core_audit_log.break_glass_access_id IS '[v4: SEC-003 (OPD), SEC-002 (EHR), ACC-009 (Billing), VWR-SEC-002 (PACS), SEC-003 (Pharmacy)]';

-- identityorg.core_branch  (4 new columns)  FDS: LAB-MLM-001, MKT-007, STR-001
ALTER TABLE identityorg.core_branch ADD COLUMN IF NOT EXISTS is_processing_lab BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE identityorg.core_branch ADD COLUMN IF NOT EXISTS is_collection_centre BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE identityorg.core_branch ADD COLUMN IF NOT EXISTS operating_hours_json JSONB NULL;
ALTER TABLE identityorg.core_branch ADD COLUMN IF NOT EXISTS service_lines VARCHAR(100) NULL;
COMMENT ON COLUMN identityorg.core_branch.is_processing_lab IS '[v4: LAB-MLM-001, MKT-007, STR-001]';
COMMENT ON COLUMN identityorg.core_branch.is_collection_centre IS '[v4: LAB-MLM-001, MKT-007, STR-001]';
COMMENT ON COLUMN identityorg.core_branch.operating_hours_json IS '[v4: LAB-MLM-001, MKT-007, STR-001]';
COMMENT ON COLUMN identityorg.core_branch.service_lines IS 'LAB, RAD, PHARMACY, OPD, TELE [v4: LAB-MLM-001, MKT-007, STR-001]';

-- identityorg.core_clinical_code  (11 new columns)  FDS: TRM-002, TRM-005, TRM-008, ALO-005, INT-001
ALTER TABLE identityorg.core_clinical_code ADD COLUMN IF NOT EXISTS code_system_release_id INT NULL;
ALTER TABLE identityorg.core_clinical_code ADD COLUMN IF NOT EXISTS code_status VARCHAR(20) NULL DEFAULT 'ACTIVE';
ALTER TABLE identityorg.core_clinical_code ADD COLUMN IF NOT EXISTS is_billable BOOLEAN NULL DEFAULT TRUE;
ALTER TABLE identityorg.core_clinical_code ADD COLUMN IF NOT EXISTS is_local_extension BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE identityorg.core_clinical_code ADD COLUMN IF NOT EXISTS gender_applicable VARCHAR(10) NULL;
ALTER TABLE identityorg.core_clinical_code ADD COLUMN IF NOT EXISTS age_min_days INT NULL;
ALTER TABLE identityorg.core_clinical_code ADD COLUMN IF NOT EXISTS age_max_days INT NULL;
ALTER TABLE identityorg.core_clinical_code ADD COLUMN IF NOT EXISTS system_of_medicine VARCHAR(20) NULL;
ALTER TABLE identityorg.core_clinical_code ADD COLUMN IF NOT EXISTS native_script_term VARCHAR(300) NULL;
ALTER TABLE identityorg.core_clinical_code ADD COLUMN IF NOT EXISTS transliterated_term VARCHAR(300) NULL;
ALTER TABLE identityorg.core_clinical_code ADD COLUMN IF NOT EXISTS post_coordination_json JSONB NULL;
COMMENT ON COLUMN identityorg.core_clinical_code.code_system_release_id IS '[v4: TRM-002, TRM-005, TRM-008, ALO-005, INT-001]';
COMMENT ON COLUMN identityorg.core_clinical_code.code_status IS 'ACTIVE, RETIRED, DEPRECATED [v4: TRM-002, TRM-005, TRM-008, ALO-005, INT-001]';
COMMENT ON COLUMN identityorg.core_clinical_code.is_billable IS 'FALSE for header / category codes [v4: TRM-002, TRM-005, TRM-008, ALO-005, INT-001]';
COMMENT ON COLUMN identityorg.core_clinical_code.is_local_extension IS 'hospital-specific term mapped to a standard code [v4: TRM-002, TRM-005, TRM-008, ALO-005, INT-001]';
COMMENT ON COLUMN identityorg.core_clinical_code.gender_applicable IS 'M, F, ALL - age / gender edits [v4: TRM-002, TRM-005, TRM-008, ALO-005, INT-001]';
COMMENT ON COLUMN identityorg.core_clinical_code.age_min_days IS '[v4: TRM-002, TRM-005, TRM-008, ALO-005, INT-001]';
COMMENT ON COLUMN identityorg.core_clinical_code.age_max_days IS '[v4: TRM-002, TRM-005, TRM-008, ALO-005, INT-001]';
COMMENT ON COLUMN identityorg.core_clinical_code.system_of_medicine IS '[v4: TRM-002, TRM-005, TRM-008, ALO-005, INT-001]';
COMMENT ON COLUMN identityorg.core_clinical_code.native_script_term IS 'Sanskrit / Tamil / Urdu term for AYUSH codes [v4: TRM-002, TRM-005, TRM-008, ALO-005, INT-001]';
COMMENT ON COLUMN identityorg.core_clinical_code.transliterated_term IS '[v4: TRM-002, TRM-005, TRM-008, ALO-005, INT-001]';
COMMENT ON COLUMN identityorg.core_clinical_code.post_coordination_json IS 'ICD-11 extension codes [v4: TRM-002, TRM-005, TRM-008, ALO-005, INT-001]';

-- identityorg.core_code_map  (7 new columns)  FDS: TRM-003, AYU-008, AYU-011 (concept map)
ALTER TABLE identityorg.core_code_map ADD COLUMN IF NOT EXISTS map_source VARCHAR(20) NULL;
ALTER TABLE identityorg.core_code_map ADD COLUMN IF NOT EXISTS map_priority SMALLINT NULL;
ALTER TABLE identityorg.core_code_map ADD COLUMN IF NOT EXISTS map_rule VARCHAR(500) NULL;
ALTER TABLE identityorg.core_code_map ADD COLUMN IF NOT EXISTS review_status VARCHAR(20) NULL DEFAULT 'APPROVED';
ALTER TABLE identityorg.core_code_map ADD COLUMN IF NOT EXISTS reviewed_by BIGINT NULL;
ALTER TABLE identityorg.core_code_map ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ(0) NULL;
ALTER TABLE identityorg.core_code_map ADD COLUMN IF NOT EXISTS code_system_release_id INT NULL;
COMMENT ON COLUMN identityorg.core_code_map.map_source IS 'OFFICIAL, LOCAL, AUTO [v4: TRM-003, AYU-008, AYU-011 (concept map)]';
COMMENT ON COLUMN identityorg.core_code_map.map_priority IS '[v4: TRM-003, AYU-008, AYU-011 (concept map)]';
COMMENT ON COLUMN identityorg.core_code_map.map_rule IS 'map advice / rule (e.g. SNOMED-ICD map rules) [v4: TRM-003, AYU-008, AYU-011 (concept map)]';
COMMENT ON COLUMN identityorg.core_code_map.review_status IS 'PROPOSED, APPROVED, REJECTED [v4: TRM-003, AYU-008, AYU-011 (concept map)]';
COMMENT ON COLUMN identityorg.core_code_map.reviewed_by IS '[v4: TRM-003, AYU-008, AYU-011 (concept map)]';
COMMENT ON COLUMN identityorg.core_code_map.reviewed_at IS '[v4: TRM-003, AYU-008, AYU-011 (concept map)]';
COMMENT ON COLUMN identityorg.core_code_map.code_system_release_id IS '[v4: TRM-003, AYU-008, AYU-011 (concept map)]';

-- identityorg.core_code_system  (9 new columns)  FDS: TRM-001, TRM-004, TRM-006, SEC-007 (EHR)
ALTER TABLE identityorg.core_code_system ADD COLUMN IF NOT EXISTS code_set_category VARCHAR(30) NULL;
ALTER TABLE identityorg.core_code_system ADD COLUMN IF NOT EXISTS system_of_medicine VARCHAR(20) NULL;
ALTER TABLE identityorg.core_code_system ADD COLUMN IF NOT EXISTS licence_required BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE identityorg.core_code_system ADD COLUMN IF NOT EXISTS licence_no VARCHAR(100) NULL;
ALTER TABLE identityorg.core_code_system ADD COLUMN IF NOT EXISTS licence_valid_to DATE NULL;
ALTER TABLE identityorg.core_code_system ADD COLUMN IF NOT EXISTS licence_status VARCHAR(20) NULL;
ALTER TABLE identityorg.core_code_system ADD COLUMN IF NOT EXISTS is_export_allowed BOOLEAN NULL DEFAULT TRUE;
ALTER TABLE identityorg.core_code_system ADD COLUMN IF NOT EXISTS current_release_id INT NULL;
ALTER TABLE identityorg.core_code_system ADD COLUMN IF NOT EXISTS publisher VARCHAR(150) NULL;
COMMENT ON COLUMN identityorg.core_code_system.code_set_category IS 'DIAGNOSIS, PROCEDURE, SYMPTOM, LAB, DRUG, TRIAL, AYUSH, GROUPER [v4: TRM-001, TRM-004, TRM-006, SEC-007 (EHR)]';
COMMENT ON COLUMN identityorg.core_code_system.system_of_medicine IS 'ALLOPATHY, AYURVEDA, YOGA, UNANI, SIDDHA, HOMOEOPATHY, ALL [v4: TRM-001, TRM-004, TRM-006, SEC-007 (EHR)]';
COMMENT ON COLUMN identityorg.core_code_system.licence_required IS '[v4: TRM-001, TRM-004, TRM-006, SEC-007 (EHR)]';
COMMENT ON COLUMN identityorg.core_code_system.licence_no IS '[v4: TRM-001, TRM-004, TRM-006, SEC-007 (EHR)]';
COMMENT ON COLUMN identityorg.core_code_system.licence_valid_to IS '[v4: TRM-001, TRM-004, TRM-006, SEC-007 (EHR)]';
COMMENT ON COLUMN identityorg.core_code_system.licence_status IS 'VALID, EXPIRED, NOT_REQUIRED - code set disabled/export blocked when not valid [v4: TRM-001, TRM-004, TRM-006, SEC-007 (EHR)]';
COMMENT ON COLUMN identityorg.core_code_system.is_export_allowed IS '[v4: TRM-001, TRM-004, TRM-006, SEC-007 (EHR)]';
COMMENT ON COLUMN identityorg.core_code_system.current_release_id IS '-> core_code_system_release (latest active release) [v4: TRM-001, TRM-004, TRM-006, SEC-007 (EHR)]';
COMMENT ON COLUMN identityorg.core_code_system.publisher IS 'WHO, AMA, SNOMED Intl, Ministry of AYUSH, MSSO (MedDRA), UMC (WHO-DDE) [v4: TRM-001, TRM-004, TRM-006, SEC-007 (EHR)]';

-- identityorg.hr_practitioner  (12 new columns)  FDS: ENQ-003, APP-002 (OPD); MKT-008 (Website); ERX-001 (EHR)
ALTER TABLE identityorg.hr_practitioner ADD COLUMN IF NOT EXISTS system_of_medicine VARCHAR(20) NULL DEFAULT 'ALLOPATHY';
ALTER TABLE identityorg.hr_practitioner ADD COLUMN IF NOT EXISTS languages_spoken VARCHAR(200) NULL;
ALTER TABLE identityorg.hr_practitioner ADD COLUMN IF NOT EXISTS experience_years SMALLINT NULL;
ALTER TABLE identityorg.hr_practitioner ADD COLUMN IF NOT EXISTS photo_uri VARCHAR(500) NULL;
ALTER TABLE identityorg.hr_practitioner ADD COLUMN IF NOT EXISTS profile_summary VARCHAR(2000) NULL;
ALTER TABLE identityorg.hr_practitioner ADD COLUMN IF NOT EXISTS hpr_verified_at TIMESTAMPTZ(0) NULL;
ALTER TABLE identityorg.hr_practitioner ADD COLUMN IF NOT EXISTS consult_modes VARCHAR(50) NULL;
ALTER TABLE identityorg.hr_practitioner ADD COLUMN IF NOT EXISTS tele_consult_fee DECIMAL(12,2) NULL;
ALTER TABLE identityorg.hr_practitioner ADD COLUMN IF NOT EXISTS followup_validity_days SMALLINT NULL;
ALTER TABLE identityorg.hr_practitioner ADD COLUMN IF NOT EXISTS is_on_demand_enabled BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE identityorg.hr_practitioner ADD COLUMN IF NOT EXISTS can_prescribe_narcotics BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE identityorg.hr_practitioner ADD COLUMN IF NOT EXISTS seo_slug VARCHAR(200) NULL;
COMMENT ON COLUMN identityorg.hr_practitioner.system_of_medicine IS '[v4: ENQ-003, APP-002 (OPD); MKT-008 (Website); ERX-001 (EHR)]';
COMMENT ON COLUMN identityorg.hr_practitioner.languages_spoken IS 'comma separated ISO codes [v4: ENQ-003, APP-002 (OPD); MKT-008 (Website); ERX-001 (EHR)]';
COMMENT ON COLUMN identityorg.hr_practitioner.experience_years IS '[v4: ENQ-003, APP-002 (OPD); MKT-008 (Website); ERX-001 (EHR)]';
COMMENT ON COLUMN identityorg.hr_practitioner.photo_uri IS '[v4: ENQ-003, APP-002 (OPD); MKT-008 (Website); ERX-001 (EHR)]';
COMMENT ON COLUMN identityorg.hr_practitioner.profile_summary IS '[v4: ENQ-003, APP-002 (OPD); MKT-008 (Website); ERX-001 (EHR)]';
COMMENT ON COLUMN identityorg.hr_practitioner.hpr_verified_at IS '[v4: ENQ-003, APP-002 (OPD); MKT-008 (Website); ERX-001 (EHR)]';
COMMENT ON COLUMN identityorg.hr_practitioner.consult_modes IS 'IN_PERSON, TELE_VIDEO, TELE_AUDIO, HOME_VISIT [v4: ENQ-003, APP-002 (OPD); MKT-008 (Website); ERX-001 (EHR)]';
COMMENT ON COLUMN identityorg.hr_practitioner.tele_consult_fee IS '[v4: ENQ-003, APP-002 (OPD); MKT-008 (Website); ERX-001 (EHR)]';
COMMENT ON COLUMN identityorg.hr_practitioner.followup_validity_days IS '[v4: ENQ-003, APP-002 (OPD); MKT-008 (Website); ERX-001 (EHR)]';
COMMENT ON COLUMN identityorg.hr_practitioner.is_on_demand_enabled IS '[v4: ENQ-003, APP-002 (OPD); MKT-008 (Website); ERX-001 (EHR)]';
COMMENT ON COLUMN identityorg.hr_practitioner.can_prescribe_narcotics IS 'RXM-007 authorised NDPS prescriber [v4: ENQ-003, APP-002 (OPD); MKT-008 (Website); ERX-001 (EHR)]';
COMMENT ON COLUMN identityorg.hr_practitioner.seo_slug IS '[v4: ENQ-003, APP-002 (OPD); MKT-008 (Website); ERX-001 (EHR)]';

-- identityorg.mst_specialty  (4 new columns)  FDS: CNS-007, TRM-004 (EHR); APP-002 (OPD)
ALTER TABLE identityorg.mst_specialty ADD COLUMN IF NOT EXISTS system_of_medicine VARCHAR(20) NULL DEFAULT 'ALLOPATHY';
ALTER TABLE identityorg.mst_specialty ADD COLUMN IF NOT EXISTS sub_specialty_of_id INT NULL;
ALTER TABLE identityorg.mst_specialty ADD COLUMN IF NOT EXISTS display_order SMALLINT NULL;
ALTER TABLE identityorg.mst_specialty ADD COLUMN IF NOT EXISTS is_bookable_online BOOLEAN NULL DEFAULT TRUE;
COMMENT ON COLUMN identityorg.mst_specialty.system_of_medicine IS '[v4: CNS-007, TRM-004 (EHR); APP-002 (OPD)]';
COMMENT ON COLUMN identityorg.mst_specialty.sub_specialty_of_id IS '[v4: CNS-007, TRM-004 (EHR); APP-002 (OPD)]';
COMMENT ON COLUMN identityorg.mst_specialty.display_order IS '[v4: CNS-007, TRM-004 (EHR); APP-002 (OPD)]';
COMMENT ON COLUMN identityorg.mst_specialty.is_bookable_online IS '[v4: CNS-007, TRM-004 (EHR); APP-002 (OPD)]';

-- identityorg.sec_user_account  (5 new columns)  FDS: PWP-004 (partner users), APP-001, FAA-001
ALTER TABLE identityorg.sec_user_account ADD COLUMN IF NOT EXISTS provider_id BIGINT NULL;
ALTER TABLE identityorg.sec_user_account ADD COLUMN IF NOT EXISTS agent_id BIGINT NULL;
ALTER TABLE identityorg.sec_user_account ADD COLUMN IF NOT EXISTS mobile VARCHAR(15) NULL;
ALTER TABLE identityorg.sec_user_account ADD COLUMN IF NOT EXISTS mobile_verified_at TIMESTAMPTZ(0) NULL;
ALTER TABLE identityorg.sec_user_account ADD COLUMN IF NOT EXISTS mfa_last_verified_at TIMESTAMPTZ(0) NULL;
COMMENT ON COLUMN identityorg.sec_user_account.provider_id IS 'partner (e-WP) users | logical FK -> patientengagement.mkt_provider [Patient Access & Engagement] [v4: PWP-004 (partner users), APP-001, FAA-001]';
COMMENT ON COLUMN identityorg.sec_user_account.agent_id IS 'field agent app users | logical FK -> operationssupply.fld_agent [Operations & Supply Chain] [v4: PWP-004 (partner users), APP-001, FAA-001]';
COMMENT ON COLUMN identityorg.sec_user_account.mobile IS '[v4: PWP-004 (partner users), APP-001, FAA-001]';
COMMENT ON COLUMN identityorg.sec_user_account.mobile_verified_at IS '[v4: PWP-004 (partner users), APP-001, FAA-001]';
COMMENT ON COLUMN identityorg.sec_user_account.mfa_last_verified_at IS '[v4: PWP-004 (partner users), APP-001, FAA-001]';

-- identityorg.sec_user_session  (4 new columns)  FDS: SEC-005 (EHR), VWR-SEC-003
ALTER TABLE identityorg.sec_user_session ADD COLUMN IF NOT EXISTS terminal_id VARCHAR(100) NULL;
ALTER TABLE identityorg.sec_user_session ADD COLUMN IF NOT EXISTS user_device_id INT NULL;
ALTER TABLE identityorg.sec_user_session ADD COLUMN IF NOT EXISTS idle_timeout_minutes SMALLINT NULL;
ALTER TABLE identityorg.sec_user_session ADD COLUMN IF NOT EXISTS reauth_at TIMESTAMPTZ(0) NULL;
COMMENT ON COLUMN identityorg.sec_user_session.terminal_id IS '[v4: SEC-005 (EHR), VWR-SEC-003]';
COMMENT ON COLUMN identityorg.sec_user_session.user_device_id IS '[v4: SEC-005 (EHR), VWR-SEC-003]';
COMMENT ON COLUMN identityorg.sec_user_session.idle_timeout_minutes IS '[v4: SEC-005 (EHR), VWR-SEC-003]';
COMMENT ON COLUMN identityorg.sec_user_session.reauth_at IS 're-authentication for signing [v4: SEC-005 (EHR), VWR-SEC-003]';

/* ---------- B. NEW TABLES ---------- */

-- ===== EHR/EMR FDS (Terminology) + common Security sections of all FDS =====
-- [NEW v4] FDS ref: TRM-001, TRM-007 (EHR 7.1.3 Code set release)
CREATE TABLE IF NOT EXISTS identityorg.core_code_system_release (             -- Code set release / version (ICD-10, ICD-11 MMS, SNOMED-CT IN edition, NAMC, MedDRA ...)
    code_system_release_id     INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL REFERENCES identityorg.core_organization(organization_id),
    code_system_id             INT NOT NULL,
    release_version            VARCHAR(30) NOT NULL,
    release_date               DATE NULL,
    effective_from             DATE NOT NULL,
    effective_to               DATE NULL,
    release_status             VARCHAR(20) NOT NULL DEFAULT 'DRAFT',           -- DRAFT, ACTIVE, RETIRED
    licence_reference          VARCHAR(100) NULL,
    source_file_uri            VARCHAR(500) NULL,
    impact_report_uri          VARCHAR(500) NULL,                              -- codes retired / changed vs previous release
    loaded_at                  TIMESTAMPTZ(0) NULL,
    loaded_by                  BIGINT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT                 uq_core_code_system_release_1 UNIQUE (code_system_id, release_version)
);

-- [NEW v4] FDS ref: TRM-002, AYU-001
CREATE TABLE IF NOT EXISTS identityorg.core_clinical_code_synonym (           -- Synonyms, abbreviations and local / regional terms for type-ahead search
    clinical_code_synonym_id   INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL REFERENCES identityorg.core_organization(organization_id),
    clinical_code_id           BIGINT NOT NULL,
    synonym_text               VARCHAR(300) NOT NULL,
    synonym_type               VARCHAR(20) NOT NULL DEFAULT 'SYNONYM',         -- SYNONYM, ABBREVIATION, LOCAL_TERM, TRANSLITERATION
    language_code              VARCHAR(10) NULL DEFAULT 'en',
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TRM-004, CNS-007
CREATE TABLE IF NOT EXISTS identityorg.core_code_set_rule (                   -- Which code sets are offered by system of medicine, encounter type, purpose and payer
    code_set_rule_id           INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL REFERENCES identityorg.core_organization(organization_id),
    code_system_id             INT NOT NULL,
    system_of_medicine         VARCHAR(20) NOT NULL,                           -- ALLOPATHY, AYURVEDA, YOGA, UNANI, SIDDHA, HOMOEOPATHY
    encounter_type             VARCHAR(20) NULL,                               -- OP, IP, DAYCARE, ER, TELE, ALL
    purpose                    VARCHAR(20) NOT NULL,                           -- CLINICAL, BILLING, REPORTING, RESEARCH
    payer_id                   INT NULL,                                       -- logical FK -> revenuefinance.mst_payer [Revenue & Finance]
    is_mandatory               BOOLEAN NOT NULL DEFAULT FALSE,
    is_default                 BOOLEAN NOT NULL DEFAULT FALSE,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: SEC-004 (OPD), SEC-001/SEC-003 (EHR)
CREATE TABLE IF NOT EXISTS identityorg.sec_break_glass_access (               -- Break-the-glass access to restricted / VIP / sensitive records
    break_glass_access_id      BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL REFERENCES identityorg.core_organization(organization_id),
    branch_id                  INT NULL REFERENCES identityorg.core_branch(branch_id),
    user_id                    BIGINT NOT NULL,
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    access_scope               VARCHAR(30) NOT NULL,                           -- VIP_RECORD, SENSITIVE_CATEGORY, OUTSIDE_CARE_TEAM
    sensitive_category         VARCHAR(30) NULL,                               -- PSYCHIATRY, HIV, SEXUAL_HEALTH, GENETICS, MLC
    reason                     VARCHAR(500) NOT NULL,
    granted_at                 TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at                 TIMESTAMPTZ(0) NOT NULL,
    alert_sent_to              VARCHAR(300) NULL,
    reviewed_by                BIGINT NULL,
    reviewed_at                TIMESTAMPTZ(0) NULL,
    review_outcome             VARCHAR(20) NULL,                               -- APPROPRIATE, INAPPROPRIATE
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: FAA-001, FAA-008 (Website), WLK-002 (OPD)
CREATE TABLE IF NOT EXISTS identityorg.sec_user_device (                      -- Registered devices (field-agent apps, kiosks, shared workstations)
    user_device_id             INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL REFERENCES identityorg.core_organization(organization_id),
    branch_id                  INT NULL REFERENCES identityorg.core_branch(branch_id),
    user_id                    BIGINT NULL,
    device_type                VARCHAR(20) NOT NULL,                           -- AGENT_APP, KIOSK, WORKSTATION, DISPLAY_BOARD, HANDHELD
    device_identifier          VARCHAR(150) NOT NULL UNIQUE,
    device_name                VARCHAR(100) NULL,
    os_version                 VARCHAR(50) NULL,
    app_version                VARCHAR(30) NULL,
    push_token                 VARCHAR(500) NULL,
    registered_at              TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_seen_at               TIMESTAMPTZ(0) NULL,
    device_status              VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',          -- ACTIVE, BLOCKED, RETIRED
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: SEC-002 (Pharmacy), SCH-008
CREATE TABLE IF NOT EXISTS identityorg.sec_user_store_access (                -- Store-level access restriction for pharmacy / inventory users
    user_store_access_id       INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL REFERENCES identityorg.core_organization(organization_id),
    user_id                    BIGINT NOT NULL,
    store_id                   INT NOT NULL,                                   -- logical FK -> operationssupply.mst_store [Operations & Supply Chain]
    access_level               VARCHAR(20) NOT NULL DEFAULT 'OPERATE',         -- VIEW, OPERATE, APPROVE
    can_handle_controlled      BOOLEAN NOT NULL DEFAULT FALSE,
    valid_from                 DATE NULL,
    valid_to                   DATE NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT                 uq_sec_user_store_access_1 UNIQUE (user_id, store_id)
);

-- [NEW v4] FDS ref: CORE-004, TAR-012, ACC-004 (Billing); SEC-004, SEC-005, PUR-002, VCH-007 (Pharmacy)
CREATE TABLE IF NOT EXISTS identityorg.sec_approval_matrix (                  -- Approval limits by role, document type and value (maker-checker / segregation of duties)
    approval_matrix_id         INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL REFERENCES identityorg.core_organization(organization_id),
    branch_id                  INT NULL REFERENCES identityorg.core_branch(branch_id),
    module_code                VARCHAR(30) NOT NULL,                           -- BILLING, PHARMACY, INVENTORY, FINANCE, EMR
    document_type              VARCHAR(40) NOT NULL,                           -- DISCOUNT, WAIVER, REFUND, WRITE_OFF, PO, STOCK_ADJUSTMENT, VOUCHER, RETURN, CREDIT_NOTE
    approval_level             SMALLINT NOT NULL,
    role_id                    INT NOT NULL,
    min_amount                 DECIMAL(14,2) NOT NULL DEFAULT 0,
    max_amount                 DECIMAL(14,2) NULL,
    item_category              VARCHAR(30) NULL,
    store_id                   INT NULL,                                       -- logical FK -> operationssupply.mst_store [Operations & Supply Chain]
    maker_cannot_approve       BOOLEAN NOT NULL DEFAULT TRUE,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);


/* ---------- C. FOREIGN KEYS (same service only) ---------- */
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'identityorg' AND c.conname = 'fk_core_code_system_release_code_system_id') THEN
        ALTER TABLE identityorg.core_code_system_release ADD CONSTRAINT fk_core_code_system_release_code_system_id FOREIGN KEY (code_system_id) REFERENCES identityorg.core_code_system(code_system_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'identityorg' AND c.conname = 'fk_core_clinical_code_synonym_clinical_code_id') THEN
        ALTER TABLE identityorg.core_clinical_code_synonym ADD CONSTRAINT fk_core_clinical_code_synonym_clinical_code_id FOREIGN KEY (clinical_code_id) REFERENCES identityorg.core_clinical_code(clinical_code_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'identityorg' AND c.conname = 'fk_core_code_set_rule_code_system_id') THEN
        ALTER TABLE identityorg.core_code_set_rule ADD CONSTRAINT fk_core_code_set_rule_code_system_id FOREIGN KEY (code_system_id) REFERENCES identityorg.core_code_system(code_system_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'identityorg' AND c.conname = 'fk_sec_break_glass_access_user_id') THEN
        ALTER TABLE identityorg.sec_break_glass_access ADD CONSTRAINT fk_sec_break_glass_access_user_id FOREIGN KEY (user_id) REFERENCES identityorg.sec_user_account(user_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'identityorg' AND c.conname = 'fk_sec_user_device_user_id') THEN
        ALTER TABLE identityorg.sec_user_device ADD CONSTRAINT fk_sec_user_device_user_id FOREIGN KEY (user_id) REFERENCES identityorg.sec_user_account(user_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'identityorg' AND c.conname = 'fk_sec_user_store_access_user_id') THEN
        ALTER TABLE identityorg.sec_user_store_access ADD CONSTRAINT fk_sec_user_store_access_user_id FOREIGN KEY (user_id) REFERENCES identityorg.sec_user_account(user_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'identityorg' AND c.conname = 'fk_sec_approval_matrix_role_id') THEN
        ALTER TABLE identityorg.sec_approval_matrix ADD CONSTRAINT fk_sec_approval_matrix_role_id FOREIGN KEY (role_id) REFERENCES identityorg.sec_role(role_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'identityorg' AND c.conname = 'fk_core_clinical_code_code_system_release_id') THEN
        ALTER TABLE identityorg.core_clinical_code ADD CONSTRAINT fk_core_clinical_code_code_system_release_id FOREIGN KEY (code_system_release_id) REFERENCES identityorg.core_code_system_release(code_system_release_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_core_clinical_code_code_system_release_id ON identityorg.core_clinical_code(code_system_release_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'identityorg' AND c.conname = 'fk_core_code_map_code_system_release_id') THEN
        ALTER TABLE identityorg.core_code_map ADD CONSTRAINT fk_core_code_map_code_system_release_id FOREIGN KEY (code_system_release_id) REFERENCES identityorg.core_code_system_release(code_system_release_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_core_code_map_code_system_release_id ON identityorg.core_code_map(code_system_release_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'identityorg' AND c.conname = 'fk_mst_specialty_sub_specialty_of_id') THEN
        ALTER TABLE identityorg.mst_specialty ADD CONSTRAINT fk_mst_specialty_sub_specialty_of_id FOREIGN KEY (sub_specialty_of_id) REFERENCES identityorg.mst_specialty(specialty_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_mst_specialty_sub_specialty_of_id ON identityorg.mst_specialty(sub_specialty_of_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'identityorg' AND c.conname = 'fk_sec_user_session_user_device_id') THEN
        ALTER TABLE identityorg.sec_user_session ADD CONSTRAINT fk_sec_user_session_user_device_id FOREIGN KEY (user_device_id) REFERENCES identityorg.sec_user_device(user_device_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_sec_user_session_user_device_id ON identityorg.sec_user_session(user_device_id);

/* ---------- D. INDEXES ---------- */
CREATE INDEX IF NOT EXISTS ix_core_clinical_code_synonym_clinical_code_id ON identityorg.core_clinical_code_synonym(clinical_code_id);
CREATE INDEX IF NOT EXISTS ix_core_code_set_rule_code_system_id ON identityorg.core_code_set_rule(code_system_id);
CREATE INDEX IF NOT EXISTS ix_sec_break_glass_access_user_id ON identityorg.sec_break_glass_access(user_id);
CREATE INDEX IF NOT EXISTS ix_sec_break_glass_access_patient_id ON identityorg.sec_break_glass_access(patient_id);
CREATE INDEX IF NOT EXISTS ix_sec_user_device_user_id ON identityorg.sec_user_device(user_id);
CREATE INDEX IF NOT EXISTS ix_sec_approval_matrix_role_id ON identityorg.sec_approval_matrix(role_id);

/* ---------- E. TABLE COMMENTS (FDS traceability) ---------- */
COMMENT ON TABLE identityorg.core_code_system_release IS 'Code set release / version (ICD-10, ICD-11 MMS, SNOMED-CT IN edition, NAMC, MedDRA ...) [FDS: TRM-001, TRM-007 (EHR 7.1.3 Code set release)]';
COMMENT ON TABLE identityorg.core_clinical_code_synonym IS 'Synonyms, abbreviations and local / regional terms for type-ahead search [FDS: TRM-002, AYU-001]';
COMMENT ON TABLE identityorg.core_code_set_rule IS 'Which code sets are offered by system of medicine, encounter type, purpose and payer [FDS: TRM-004, CNS-007]';
COMMENT ON TABLE identityorg.sec_break_glass_access IS 'Break-the-glass access to restricted / VIP / sensitive records [FDS: SEC-004 (OPD), SEC-001/SEC-003 (EHR)]';
COMMENT ON TABLE identityorg.sec_user_device IS 'Registered devices (field-agent apps, kiosks, shared workstations) [FDS: FAA-001, FAA-008 (Website), WLK-002 (OPD)]';
COMMENT ON TABLE identityorg.sec_user_store_access IS 'Store-level access restriction for pharmacy / inventory users [FDS: SEC-002 (Pharmacy), SCH-008]';
COMMENT ON TABLE identityorg.sec_approval_matrix IS 'Approval limits by role, document type and value (maker-checker / segregation of duties) [FDS: CORE-004, TAR-012, ACC-004 (Billing); SEC-004, SEC-005, PUR-002, VCH-007 (Pharmacy)]';

COMMIT;
