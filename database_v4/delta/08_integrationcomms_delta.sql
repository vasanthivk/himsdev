/* =====================================================================================
   DR REDDIS HEALTHCARE - HIMS  database_v3 (7 services)  ->  database_v4 (9 services)
   Step 08 - Integration & Communications: column additions to existing tables + new FDS tables
   Run against an EXISTING himsdev database that was built from database_v3, in file-name order:
     00_restructure_7_to_9_services.sql  -> 01..09_<service>_delta.sql  -> 10_post_migration_housekeeping.sql -> ../full/roles.sql
   Every statement is idempotent where PostgreSQL allows it (IF NOT EXISTS / guarded DO blocks).
   ===================================================================================== */

BEGIN;

/* ---------- A. MODIFICATIONS TO EXISTING TABLES (ADD COLUMN) ---------- */

-- integrationcomms.core_document  (7 new columns)  FDS: UPL-001..004 (EHR), DOC-008, LAB-RPT-008
ALTER TABLE integrationcomms.core_document ADD COLUMN IF NOT EXISTS version_no SMALLINT NULL DEFAULT 1;
ALTER TABLE integrationcomms.core_document ADD COLUMN IF NOT EXISTS source VARCHAR(30) NULL;
ALTER TABLE integrationcomms.core_document ADD COLUMN IF NOT EXISTS ocr_text TEXT NULL;
ALTER TABLE integrationcomms.core_document ADD COLUMN IF NOT EXISTS malware_scan_status VARCHAR(20) NULL;
ALTER TABLE integrationcomms.core_document ADD COLUMN IF NOT EXISTS malware_scanned_at TIMESTAMPTZ(0) NULL;
ALTER TABLE integrationcomms.core_document ADD COLUMN IF NOT EXISTS retention_until DATE NULL;
ALTER TABLE integrationcomms.core_document ADD COLUMN IF NOT EXISTS is_duplicate_copy BOOLEAN NULL DEFAULT FALSE;
COMMENT ON COLUMN integrationcomms.core_document.version_no IS '[v4: UPL-001..004 (EHR), DOC-008, LAB-RPT-008]';
COMMENT ON COLUMN integrationcomms.core_document.source IS 'UPLOAD, SCAN, CAMERA, ABDM, SYSTEM_GENERATED, PATIENT_PORTAL [v4: UPL-001..004 (EHR), DOC-008, LAB-RPT-008]';
COMMENT ON COLUMN integrationcomms.core_document.ocr_text IS '[v4: UPL-001..004 (EHR), DOC-008, LAB-RPT-008]';
COMMENT ON COLUMN integrationcomms.core_document.malware_scan_status IS 'PENDING, CLEAN, INFECTED [v4: UPL-001..004 (EHR), DOC-008, LAB-RPT-008]';
COMMENT ON COLUMN integrationcomms.core_document.malware_scanned_at IS '[v4: UPL-001..004 (EHR), DOC-008, LAB-RPT-008]';
COMMENT ON COLUMN integrationcomms.core_document.retention_until IS '[v4: UPL-001..004 (EHR), DOC-008, LAB-RPT-008]';
COMMENT ON COLUMN integrationcomms.core_document.is_duplicate_copy IS '[v4: UPL-001..004 (EHR), DOC-008, LAB-RPT-008]';

-- integrationcomms.core_notification  (8 new columns)  FDS: REM-PAT-005, NOTIF entity (OPD 4.1)
ALTER TABLE integrationcomms.core_notification ADD COLUMN IF NOT EXISTS event_code VARCHAR(60) NULL;
ALTER TABLE integrationcomms.core_notification ADD COLUMN IF NOT EXISTS language_code VARCHAR(10) NULL;
ALTER TABLE integrationcomms.core_notification ADD COLUMN IF NOT EXISTS comm_reminder_rule_id INT NULL;
ALTER TABLE integrationcomms.core_notification ADD COLUMN IF NOT EXISTS retry_count SMALLINT NULL DEFAULT 0;
ALTER TABLE integrationcomms.core_notification ADD COLUMN IF NOT EXISTS error_message VARCHAR(1000) NULL;
ALTER TABLE integrationcomms.core_notification ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ(0) NULL;
ALTER TABLE integrationcomms.core_notification ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ(0) NULL;
ALTER TABLE integrationcomms.core_notification ADD COLUMN IF NOT EXISTS patient_response VARCHAR(30) NULL;
COMMENT ON COLUMN integrationcomms.core_notification.event_code IS '[v4: REM-PAT-005, NOTIF entity (OPD 4.1)]';
COMMENT ON COLUMN integrationcomms.core_notification.language_code IS '[v4: REM-PAT-005, NOTIF entity (OPD 4.1)]';
COMMENT ON COLUMN integrationcomms.core_notification.comm_reminder_rule_id IS '[v4: REM-PAT-005, NOTIF entity (OPD 4.1)]';
COMMENT ON COLUMN integrationcomms.core_notification.retry_count IS '[v4: REM-PAT-005, NOTIF entity (OPD 4.1)]';
COMMENT ON COLUMN integrationcomms.core_notification.error_message IS '[v4: REM-PAT-005, NOTIF entity (OPD 4.1)]';
COMMENT ON COLUMN integrationcomms.core_notification.delivered_at IS '[v4: REM-PAT-005, NOTIF entity (OPD 4.1)]';
COMMENT ON COLUMN integrationcomms.core_notification.read_at IS '[v4: REM-PAT-005, NOTIF entity (OPD 4.1)]';
COMMENT ON COLUMN integrationcomms.core_notification.patient_response IS 'CONFIRM, RESCHEDULE, CANCEL (REM-PAT-003) [v4: REM-PAT-005, NOTIF entity (OPD 4.1)]';

-- integrationcomms.intg_abdm_care_context  (3 new columns)  FDS: RPT-009, BAT-010
ALTER TABLE integrationcomms.intg_abdm_care_context ADD COLUMN IF NOT EXISTS last_shared_at TIMESTAMPTZ(0) NULL;
ALTER TABLE integrationcomms.intg_abdm_care_context ADD COLUMN IF NOT EXISTS source_service VARCHAR(30) NULL;
ALTER TABLE integrationcomms.intg_abdm_care_context ADD COLUMN IF NOT EXISTS display_name VARCHAR(200) NULL;
COMMENT ON COLUMN integrationcomms.intg_abdm_care_context.last_shared_at IS '[v4: RPT-009, BAT-010]';
COMMENT ON COLUMN integrationcomms.intg_abdm_care_context.source_service IS 'CLINICAL_CARE, LIMS, RIMS, PHARMACY [v4: RPT-009, BAT-010]';
COMMENT ON COLUMN integrationcomms.intg_abdm_care_context.display_name IS '[v4: RPT-009, BAT-010]';

-- integrationcomms.mst_report_letterhead  (8 new columns)  FDS: LAB-RPT-009/010, RAD-RPT-005/006, DOC-008, ORX-004
ALTER TABLE integrationcomms.mst_report_letterhead ADD COLUMN IF NOT EXISTS letterhead_name VARCHAR(100) NULL;
ALTER TABLE integrationcomms.mst_report_letterhead ADD COLUMN IF NOT EXISTS scope_level VARCHAR(20) NULL DEFAULT 'BRANCH';
ALTER TABLE integrationcomms.mst_report_letterhead ADD COLUMN IF NOT EXISTS provider_id BIGINT NULL;
ALTER TABLE integrationcomms.mst_report_letterhead ADD COLUMN IF NOT EXISTS customisation_json JSONB NULL;
ALTER TABLE integrationcomms.mst_report_letterhead ADD COLUMN IF NOT EXISTS show_qr_verification BOOLEAN NULL DEFAULT TRUE;
ALTER TABLE integrationcomms.mst_report_letterhead ADD COLUMN IF NOT EXISTS watermark_text VARCHAR(100) NULL;
ALTER TABLE integrationcomms.mst_report_letterhead ADD COLUMN IF NOT EXISTS valid_from DATE NULL;
ALTER TABLE integrationcomms.mst_report_letterhead ADD COLUMN IF NOT EXISTS valid_to DATE NULL;
COMMENT ON COLUMN integrationcomms.mst_report_letterhead.letterhead_name IS '[v4: LAB-RPT-009/010, RAD-RPT-005/006, DOC-008, ORX-004]';
COMMENT ON COLUMN integrationcomms.mst_report_letterhead.scope_level IS 'ORGANISATION, BRANCH, B2B_CLIENT, PARTNER [v4: LAB-RPT-009/010, RAD-RPT-005/006, DOC-008, ORX-004]';
COMMENT ON COLUMN integrationcomms.mst_report_letterhead.provider_id IS 'logical FK -> patientengagement.mkt_provider [Patient Access & Engagement] [v4: LAB-RPT-009/010, RAD-RPT-005/006, DOC-008, ORX-004]';
COMMENT ON COLUMN integrationcomms.mst_report_letterhead.customisation_json IS 'fonts, sections shown, signature placement, out-of-range highlight style [v4: LAB-RPT-009/010, RAD-RPT-005/006, DOC-008, ORX-004]';
COMMENT ON COLUMN integrationcomms.mst_report_letterhead.show_qr_verification IS '[v4: LAB-RPT-009/010, RAD-RPT-005/006, DOC-008, ORX-004]';
COMMENT ON COLUMN integrationcomms.mst_report_letterhead.watermark_text IS '[v4: LAB-RPT-009/010, RAD-RPT-005/006, DOC-008, ORX-004]';
COMMENT ON COLUMN integrationcomms.mst_report_letterhead.valid_from IS '[v4: LAB-RPT-009/010, RAD-RPT-005/006, DOC-008, ORX-004]';
COMMENT ON COLUMN integrationcomms.mst_report_letterhead.valid_to IS '[v4: LAB-RPT-009/010, RAD-RPT-005/006, DOC-008, ORX-004]';

/* ---------- B. NEW TABLES ---------- */

-- ===== OPD FDS (REG-ABDM, REM, RPT), Website FDS (PRP-002/007), EHR (MRV-005/006), Pharmacy (BAT-007..011) =====
-- [NEW v4] FDS ref: REG-ABDM-006, RPT-009, BAT-009
CREATE TABLE IF NOT EXISTS integrationcomms.intg_abdm_request_queue (         -- Queued / retried ABDM gateway calls (ABHA create/verify, care-context link, HIP push)
    abdm_request_queue_id      BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    request_type               VARCHAR(40) NOT NULL,                           -- ABHA_CREATE, ABHA_VERIFY, CARE_CONTEXT_LINK, HIP_PUSH, CONSENT_NOTIFY, ERX_DISPENSE
    patient_id                 BIGINT NULL,                                    -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    entity_type                VARCHAR(40) NULL,
    entity_id                  BIGINT NULL,
    request_payload_uri        VARCHAR(500) NULL,
    attempt_count              SMALLINT NOT NULL DEFAULT 0,
    next_attempt_at            TIMESTAMPTZ(0) NULL,
    last_error                 VARCHAR(1000) NULL,
    queue_status               VARCHAR(20) NOT NULL DEFAULT 'PENDING',         -- PENDING, IN_PROGRESS, DONE, FAILED, ABANDONED
    completed_at               TIMESTAMPTZ(0) NULL,
    gateway_request_id         VARCHAR(100) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: REG-ABDM-004, MRV-005, MRV-006, SEC-008 (EHR), BAT-010/011
CREATE TABLE IF NOT EXISTS integrationcomms.intg_abdm_consent_artefact (      -- ABDM consent artefacts (HIP / HIU) governing data sharing
    abdm_consent_artefact_id   BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    abha_address               VARCHAR(100) NULL,
    consent_artefact_id        VARCHAR(100) NOT NULL UNIQUE,
    role                       VARCHAR(10) NOT NULL,                           -- HIP, HIU
    purpose_code               VARCHAR(20) NULL,                               -- CAREMGT, BTG, PUBHLTH, PATRQT
    hi_types                   VARCHAR(300) NULL,                              -- Prescription, DiagnosticReport, OPConsultation, DischargeSummary ...
    date_range_from            TIMESTAMPTZ(0) NULL,
    date_range_to              TIMESTAMPTZ(0) NULL,
    expires_at                 TIMESTAMPTZ(0) NULL,
    consent_status             VARCHAR(20) NOT NULL,                           -- REQUESTED, GRANTED, DENIED, REVOKED, EXPIRED
    granted_at                 TIMESTAMPTZ(0) NULL,
    revoked_at                 TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: MRV-005, MRV-006, LAB-RPT-013, RAD-RPT-011
CREATE TABLE IF NOT EXISTS integrationcomms.intg_abdm_health_info_txn (       -- Health-information push / pull transactions with ABDM
    abdm_health_info_txn_id    BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    abdm_consent_artefact_id   BIGINT NULL,
    abdm_care_context_id       BIGINT NULL,
    direction                  VARCHAR(10) NOT NULL,                           -- PUSH, PULL
    hi_type                    VARCHAR(40) NOT NULL,
    fhir_bundle_uri            VARCHAR(500) NULL,
    transaction_ref            VARCHAR(100) NULL,
    txn_status                 VARCHAR(20) NOT NULL,                           -- REQUESTED, TRANSFERRED, ACKNOWLEDGED, FAILED
    requested_at               TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at               TIMESTAMPTZ(0) NULL,
    error_message              VARCHAR(1000) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: REM-PAT-002, REM-PAT-005 (OPD), PRP-001, CNS-002 (Pharmacy)
CREATE TABLE IF NOT EXISTS integrationcomms.comm_template (                   -- Versioned, multilingual notification / document templates (SMS, WhatsApp, e-mail, push, print)
    template_id                INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    template_code              VARCHAR(60) NOT NULL,
    channel                    VARCHAR(20) NOT NULL,                           -- SMS, WHATSAPP, EMAIL, PUSH, IN_APP, PRINT, IVR
    language_code              VARCHAR(10) NOT NULL DEFAULT 'en',
    version_no                 SMALLINT NOT NULL DEFAULT 1,
    subject                    VARCHAR(300) NULL,
    body_text                  TEXT NOT NULL,
    dlt_template_id            VARCHAR(50) NULL,                               -- TRAI DLT registration id for SMS
    whatsapp_template_name     VARCHAR(100) NULL,
    placeholders_json          JSONB NULL,
    approval_status            VARCHAR(20) NOT NULL DEFAULT 'APPROVED',
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT                 uq_comm_template_1 UNIQUE (organization_id, template_code, channel, language_code, version_no)
);

-- [NEW v4] FDS ref: REM-PAT-001, REM-DOC-001..004, RPT-010 (OPD); TSL-003, PBK-009, MBK-008 (Website); EXP-005 (Pharmacy)
CREATE TABLE IF NOT EXISTS integrationcomms.comm_reminder_rule (              -- Configurable reminder schedules (appointments, tele sessions, reports pending, refills, expiry)
    reminder_rule_id           INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    rule_code                  VARCHAR(60) NOT NULL,
    event_code                 VARCHAR(60) NOT NULL,                           -- APPOINTMENT_BOOKED, TELE_SESSION, REPORT_PENDING_COLLECTION, REFILL_DUE, NEAR_EXPIRY ...
    recipient_type             VARCHAR(20) NOT NULL,                           -- PATIENT, DOCTOR, STAFF, STORE_KEEPER
    offset_minutes             INT NOT NULL,                                   -- negative = before event, positive = after
    channels                   VARCHAR(100) NOT NULL,                          -- SMS,WHATSAPP,EMAIL,PUSH
    comm_template_code         VARCHAR(60) NOT NULL,
    respect_opt_out            BOOLEAN NOT NULL DEFAULT TRUE,
    quiet_hours_json           JSONB NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: RPT-005 (OPD), PRP-002, PRP-007, ORX-001 (Website), LAB-RPT-014, RAD-RPT-009
CREATE TABLE IF NOT EXISTS integrationcomms.comm_secure_link (                -- Time-limited, OTP / DOB-protected links to reports, prescriptions, invoices and images
    secure_link_id             BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    token_hash                 VARCHAR(128) NOT NULL UNIQUE,
    patient_id                 BIGINT NULL,                                    -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    document_id                BIGINT NULL,
    entity_type                VARCHAR(40) NOT NULL,                           -- LAB_REPORT, RAD_REPORT, PRESCRIPTION, INVOICE, DICOM_STUDY, DISCHARGE_SUMMARY
    entity_id                  BIGINT NOT NULL,
    recipient_type             VARCHAR(20) NULL,                               -- PATIENT, DOCTOR, THIRD_PARTY, CORPORATE
    recipient_address          VARCHAR(200) NULL,
    second_factor              VARCHAR(20) NOT NULL DEFAULT 'OTP',             -- OTP, DOB, PASSCODE, NONE
    passcode_hash              VARCHAR(128) NULL,
    expires_at                 TIMESTAMPTZ(0) NOT NULL,
    max_views                  SMALLINT NULL,
    view_count                 SMALLINT NOT NULL DEFAULT 0,
    failed_attempts            SMALLINT NOT NULL DEFAULT 0,
    locked_at                  TIMESTAMPTZ(0) NULL,
    revoked_at                 TIMESTAMPTZ(0) NULL,
    revoked_by                 BIGINT NULL,
    link_status                VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',          -- ACTIVE, EXPIRED, REVOKED, LOCKED
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: PRP-007, SHR-008
CREATE TABLE IF NOT EXISTS integrationcomms.comm_secure_link_access (         -- Access log of secure links (time, IP, device, download)
    secure_link_access_id      BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    secure_link_id             BIGINT NOT NULL,
    accessed_at                TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    client_ip                  VARCHAR(45) NULL,
    user_agent                 VARCHAR(300) NULL,
    action                     VARCHAR(20) NOT NULL,                           -- OPEN, OTP_SENT, OTP_OK, OTP_FAIL, DOWNLOAD
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TAR-002 (Billing), DRG-006, HSN-007, STK-003 (Pharmacy)
CREATE TABLE IF NOT EXISTS integrationcomms.intg_bulk_import_job (            -- Bulk upload jobs with validation and error report (tariffs, drug master, HSN, stock)
    bulk_import_job_id         BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    import_type                VARCHAR(40) NOT NULL,                           -- TARIFF, DRUG_MASTER, HSN, OPENING_STOCK, LAB_TEST, CODE_SET
    target_service             VARCHAR(30) NOT NULL,
    source_document_id         BIGINT NULL,
    total_rows                 INT NULL,
    valid_rows                 INT NULL,
    error_rows                 INT NULL,
    error_report_document_id   BIGINT NULL,
    job_status                 VARCHAR(20) NOT NULL DEFAULT 'UPLOADED',        -- UPLOADED, VALIDATED, PENDING_APPROVAL, APPROVED, APPLIED, REJECTED
    approved_by                BIGINT NULL,
    approved_at                TIMESTAMPTZ(0) NULL,
    applied_at                 TIMESTAMPTZ(0) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TAR-002, DRG-006
CREATE TABLE IF NOT EXISTS integrationcomms.intg_bulk_import_row (            -- Staged rows of a bulk import with validation result
    bulk_import_row_id         BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    bulk_import_job_id         BIGINT NOT NULL,
    row_no                     INT NOT NULL,
    row_data_json              JSONB NOT NULL,
    validation_status          VARCHAR(20) NOT NULL,                           -- VALID, ERROR, WARNING
    validation_message         VARCHAR(1000) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: MIS-001 (Billing), LAB-MIS-002, RAD-MIS-002, SRP-004
CREATE TABLE IF NOT EXISTS integrationcomms.rpt_report_definition (           -- Custom report builder definitions and saved / shared report templates
    report_definition_id       INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    report_code                VARCHAR(60) NOT NULL,
    report_name                VARCHAR(200) NOT NULL,
    module_code                VARCHAR(30) NOT NULL,
    data_source                VARCHAR(100) NOT NULL,                          -- analytics view / dataset name
    fields_json                JSONB NOT NULL,
    filters_json               JSONB NULL,
    grouping_json              JSONB NULL,
    owner_user_id              BIGINT NULL,                                    -- logical FK -> identityorg.sec_user_account [Identity & Organization]
    is_shared                  BOOLEAN NOT NULL DEFAULT FALSE,
    schedule_cron              VARCHAR(50) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: INT-001..004 (PACS), 5.1/6.1 external interfaces of all FDS
CREATE TABLE IF NOT EXISTS integrationcomms.intg_hl7_dicom_endpoint (         -- External interface endpoints (HL7 v2, FHIR, DICOM, analyzer engine, payment, SMS gateways)
    hl7_dicom_endpoint_id      INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    interface_code             VARCHAR(40) NOT NULL UNIQUE,
    interface_type             VARCHAR(20) NOT NULL,                           -- HL7V2, FHIR, DICOM, REST, SFTP, ASTM
    direction                  VARCHAR(10) NOT NULL,                           -- INBOUND, OUTBOUND, BOTH
    endpoint_uri               VARCHAR(500) NULL,
    auth_type                  VARCHAR(20) NULL,                               -- NONE, BASIC, OAUTH2, MTLS, API_KEY
    credential_ref             VARCHAR(200) NULL,                              -- key-vault reference, never the secret
    owning_service             VARCHAR(30) NULL,
    endpoint_status            VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    last_success_at            TIMESTAMPTZ(0) NULL,
    last_failure_at            TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);


/* ---------- C. FOREIGN KEYS (same service only) ---------- */
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'integrationcomms' AND c.conname = 'fk_intg_abdm_health_info_txn_abdm_consent_artefact_id') THEN
        ALTER TABLE integrationcomms.intg_abdm_health_info_txn ADD CONSTRAINT fk_intg_abdm_health_info_txn_abdm_consent_artefact_id FOREIGN KEY (abdm_consent_artefact_id) REFERENCES integrationcomms.intg_abdm_consent_artefact(abdm_consent_artefact_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'integrationcomms' AND c.conname = 'fk_intg_abdm_health_info_txn_abdm_care_context_id') THEN
        ALTER TABLE integrationcomms.intg_abdm_health_info_txn ADD CONSTRAINT fk_intg_abdm_health_info_txn_abdm_care_context_id FOREIGN KEY (abdm_care_context_id) REFERENCES integrationcomms.intg_abdm_care_context(abdm_care_context_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'integrationcomms' AND c.conname = 'fk_comm_secure_link_document_id') THEN
        ALTER TABLE integrationcomms.comm_secure_link ADD CONSTRAINT fk_comm_secure_link_document_id FOREIGN KEY (document_id) REFERENCES integrationcomms.core_document(document_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'integrationcomms' AND c.conname = 'fk_comm_secure_link_access_secure_link_id') THEN
        ALTER TABLE integrationcomms.comm_secure_link_access ADD CONSTRAINT fk_comm_secure_link_access_secure_link_id FOREIGN KEY (secure_link_id) REFERENCES integrationcomms.comm_secure_link(secure_link_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'integrationcomms' AND c.conname = 'fk_intg_bulk_import_job_source_document_id') THEN
        ALTER TABLE integrationcomms.intg_bulk_import_job ADD CONSTRAINT fk_intg_bulk_import_job_source_document_id FOREIGN KEY (source_document_id) REFERENCES integrationcomms.core_document(document_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'integrationcomms' AND c.conname = 'fk_intg_bulk_import_job_error_report_document_id') THEN
        ALTER TABLE integrationcomms.intg_bulk_import_job ADD CONSTRAINT fk_intg_bulk_import_job_error_report_document_id FOREIGN KEY (error_report_document_id) REFERENCES integrationcomms.core_document(document_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'integrationcomms' AND c.conname = 'fk_intg_bulk_import_row_bulk_import_job_id') THEN
        ALTER TABLE integrationcomms.intg_bulk_import_row ADD CONSTRAINT fk_intg_bulk_import_row_bulk_import_job_id FOREIGN KEY (bulk_import_job_id) REFERENCES integrationcomms.intg_bulk_import_job(bulk_import_job_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'integrationcomms' AND c.conname = 'fk_core_notification_comm_reminder_rule_id') THEN
        ALTER TABLE integrationcomms.core_notification ADD CONSTRAINT fk_core_notification_comm_reminder_rule_id FOREIGN KEY (comm_reminder_rule_id) REFERENCES integrationcomms.comm_reminder_rule(reminder_rule_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_core_notification_comm_reminder_rule_id ON integrationcomms.core_notification(comm_reminder_rule_id);

/* ---------- D. INDEXES ---------- */
CREATE INDEX IF NOT EXISTS ix_intg_abdm_request_queue_patient_id ON integrationcomms.intg_abdm_request_queue(patient_id);
CREATE INDEX IF NOT EXISTS ix_intg_abdm_consent_artefact_patient_id ON integrationcomms.intg_abdm_consent_artefact(patient_id);
CREATE INDEX IF NOT EXISTS ix_intg_abdm_health_info_txn_abdm_consent_artefact_id ON integrationcomms.intg_abdm_health_info_txn(abdm_consent_artefact_id);
CREATE INDEX IF NOT EXISTS ix_intg_abdm_health_info_txn_abdm_care_context_id ON integrationcomms.intg_abdm_health_info_txn(abdm_care_context_id);
CREATE INDEX IF NOT EXISTS ix_comm_secure_link_patient_id ON integrationcomms.comm_secure_link(patient_id);
CREATE INDEX IF NOT EXISTS ix_comm_secure_link_document_id ON integrationcomms.comm_secure_link(document_id);
CREATE INDEX IF NOT EXISTS ix_comm_secure_link_access_secure_link_id ON integrationcomms.comm_secure_link_access(secure_link_id);
CREATE INDEX IF NOT EXISTS ix_intg_bulk_import_job_source_document_id ON integrationcomms.intg_bulk_import_job(source_document_id);
CREATE INDEX IF NOT EXISTS ix_intg_bulk_import_job_error_report_document_id ON integrationcomms.intg_bulk_import_job(error_report_document_id);
CREATE INDEX IF NOT EXISTS ix_intg_bulk_import_row_bulk_import_job_id ON integrationcomms.intg_bulk_import_row(bulk_import_job_id);

/* ---------- E. TABLE COMMENTS (FDS traceability) ---------- */
COMMENT ON TABLE integrationcomms.intg_abdm_request_queue IS 'Queued / retried ABDM gateway calls (ABHA create/verify, care-context link, HIP push) [FDS: REG-ABDM-006, RPT-009, BAT-009]';
COMMENT ON TABLE integrationcomms.intg_abdm_consent_artefact IS 'ABDM consent artefacts (HIP / HIU) governing data sharing [FDS: REG-ABDM-004, MRV-005, MRV-006, SEC-008 (EHR), BAT-010/011]';
COMMENT ON TABLE integrationcomms.intg_abdm_health_info_txn IS 'Health-information push / pull transactions with ABDM [FDS: MRV-005, MRV-006, LAB-RPT-013, RAD-RPT-011]';
COMMENT ON TABLE integrationcomms.comm_template IS 'Versioned, multilingual notification / document templates (SMS, WhatsApp, e-mail, push, print) [FDS: REM-PAT-002, REM-PAT-005 (OPD), PRP-001, CNS-002 (Pharmacy)]';
COMMENT ON TABLE integrationcomms.comm_reminder_rule IS 'Configurable reminder schedules (appointments, tele sessions, reports pending, refills, expiry) [FDS: REM-PAT-001, REM-DOC-001..004, RPT-010 (OPD); TSL-003, PBK-009, MBK-008 (Website); EXP-005 (Pharmacy)]';
COMMENT ON TABLE integrationcomms.comm_secure_link IS 'Time-limited, OTP / DOB-protected links to reports, prescriptions, invoices and images [FDS: RPT-005 (OPD), PRP-002, PRP-007, ORX-001 (Website), LAB-RPT-014, RAD-RPT-009]';
COMMENT ON TABLE integrationcomms.comm_secure_link_access IS 'Access log of secure links (time, IP, device, download) [FDS: PRP-007, SHR-008]';
COMMENT ON TABLE integrationcomms.intg_bulk_import_job IS 'Bulk upload jobs with validation and error report (tariffs, drug master, HSN, stock) [FDS: TAR-002 (Billing), DRG-006, HSN-007, STK-003 (Pharmacy)]';
COMMENT ON TABLE integrationcomms.intg_bulk_import_row IS 'Staged rows of a bulk import with validation result [FDS: TAR-002, DRG-006]';
COMMENT ON TABLE integrationcomms.rpt_report_definition IS 'Custom report builder definitions and saved / shared report templates [FDS: MIS-001 (Billing), LAB-MIS-002, RAD-MIS-002, SRP-004]';
COMMENT ON TABLE integrationcomms.intg_hl7_dicom_endpoint IS 'External interface endpoints (HL7 v2, FHIR, DICOM, analyzer engine, payment, SMS gateways) [FDS: INT-001..004 (PACS), 5.1/6.1 external interfaces of all FDS]';

COMMIT;
