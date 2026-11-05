/* =====================================================================================
   DR REDDIS HEALTHCARE - HIMS  database_v3 (7 services)  ->  database_v4 (9 services)
   Step 02 - Patient Access & Engagement: column additions to existing tables + new FDS tables
   Run against an EXISTING himsdev database that was built from database_v3, in file-name order:
     00_restructure_7_to_9_services.sql  -> 01..09_<service>_delta.sql  -> 10_post_migration_housekeeping.sql -> ../full/roles.sql
   Every statement is idempotent where PostgreSQL allows it (IF NOT EXISTS / guarded DO blocks).
   ===================================================================================== */

BEGIN;

/* ---------- A. MODIFICATIONS TO EXISTING TABLES (ADD COLUMN) ---------- */

-- patientengagement.camp_camp_registration  (2 new columns)  FDS: LAB-COL-003 (camp collection)
ALTER TABLE patientengagement.camp_camp_registration ADD COLUMN IF NOT EXISTS sample_collected BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE patientengagement.camp_camp_registration ADD COLUMN IF NOT EXISTS lab_order_id BIGINT NULL;
COMMENT ON COLUMN patientengagement.camp_camp_registration.sample_collected IS '[v4: LAB-COL-003 (camp collection)]';
COMMENT ON COLUMN patientengagement.camp_camp_registration.lab_order_id IS 'logical FK -> clinicalcare.ord_clinical_order [Clinical Care] [v4: LAB-COL-003 (camp collection)]';

-- patientengagement.crm_enquiry  (9 new columns)  FDS: ENQ-001..009 (Enquiry entity)
ALTER TABLE patientengagement.crm_enquiry ADD COLUMN IF NOT EXISTS enquiry_type VARCHAR(30) NULL;
ALTER TABLE patientengagement.crm_enquiry ADD COLUMN IF NOT EXISTS department_id INT NULL;
ALTER TABLE patientengagement.crm_enquiry ADD COLUMN IF NOT EXISTS practitioner_id BIGINT NULL;
ALTER TABLE patientengagement.crm_enquiry ADD COLUMN IF NOT EXISTS patient_id BIGINT NULL;
ALTER TABLE patientengagement.crm_enquiry ADD COLUMN IF NOT EXISTS followup_date DATE NULL;
ALTER TABLE patientengagement.crm_enquiry ADD COLUMN IF NOT EXISTS identity_verified_at TIMESTAMPTZ(0) NULL;
ALTER TABLE patientengagement.crm_enquiry ADD COLUMN IF NOT EXISTS converted_appointment_id BIGINT NULL;
ALTER TABLE patientengagement.crm_enquiry ADD COLUMN IF NOT EXISTS closed_at TIMESTAMPTZ(0) NULL;
ALTER TABLE patientengagement.crm_enquiry ADD COLUMN IF NOT EXISTS first_response_at TIMESTAMPTZ(0) NULL;
COMMENT ON COLUMN patientengagement.crm_enquiry.enquiry_type IS 'DOCTOR, SERVICE_TARIFF, REPORT_STATUS, APPOINTMENT, ADMISSION, OTHER [v4: ENQ-001..009 (Enquiry entity)]';
COMMENT ON COLUMN patientengagement.crm_enquiry.department_id IS 'logical FK -> identityorg.mst_department [Identity & Organization] [v4: ENQ-001..009 (Enquiry entity)]';
COMMENT ON COLUMN patientengagement.crm_enquiry.practitioner_id IS 'logical FK -> identityorg.hr_practitioner [Identity & Organization] [v4: ENQ-001..009 (Enquiry entity)]';
COMMENT ON COLUMN patientengagement.crm_enquiry.patient_id IS '[v4: ENQ-001..009 (Enquiry entity)]';
COMMENT ON COLUMN patientengagement.crm_enquiry.followup_date IS '[v4: ENQ-001..009 (Enquiry entity)]';
COMMENT ON COLUMN patientengagement.crm_enquiry.identity_verified_at IS 'OTP verification before disclosure (ENQ-009) [v4: ENQ-001..009 (Enquiry entity)]';
COMMENT ON COLUMN patientengagement.crm_enquiry.converted_appointment_id IS '[v4: ENQ-001..009 (Enquiry entity)]';
COMMENT ON COLUMN patientengagement.crm_enquiry.closed_at IS '[v4: ENQ-001..009 (Enquiry entity)]';
COMMENT ON COLUMN patientengagement.crm_enquiry.first_response_at IS '[v4: ENQ-001..009 (Enquiry entity)]';

-- patientengagement.ecom_online_order  (38 new columns)  FDS: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS customer_account_id BIGINT NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS patient_profile_id BIGINT NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS provider_id BIGINT NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS service_line VARCHAR(20) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS source_channel VARCHAR(20) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS channel_partner_id INT NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS channel_order_ref VARCHAR(100) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS address_id BIGINT NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS pin_latitude DECIMAL(9,6) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS pin_longitude DECIMAL(9,6) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS pin_locked_at TIMESTAMPTZ(0) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS capacity_window_id BIGINT NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS item_amount DECIMAL(12,2) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS charges_amount DECIMAL(12,2) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS tax_amount DECIMAL(12,2) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS payment_mode VARCHAR(20) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS cod_collected_amount DECIMAL(12,2) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS partner_price_amount DECIMAL(12,2) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS platform_fee_amount DECIMAL(12,2) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS corporate_ref VARCHAR(100) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS insurance_ref VARCHAR(100) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS order_episode_id BIGINT NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS parent_order_id BIGINT NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS appointment_id BIGINT NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS encounter_id BIGINT NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS lims_order_ref BIGINT NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS rims_study_ref BIGINT NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS pharmacy_dispense_ref BIGINT NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS visit_mode VARCHAR(20) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS mobility_needs VARCHAR(100) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS attender_count SMALLINT NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS substitution_preference VARCHAR(20) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS expected_report_at TIMESTAMPTZ(0) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS reschedule_count SMALLINT NULL DEFAULT 0;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS cancel_reason VARCHAR(300) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ(0) NULL;
ALTER TABLE patientengagement.ecom_online_order ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ(0) NULL;
COMMENT ON COLUMN patientengagement.ecom_online_order.customer_account_id IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.patient_profile_id IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.provider_id IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.service_line IS 'LAB, RAD, PHARMACY, OPD, TELE [v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.source_channel IS 'WEBSITE, ANDROID, IOS, AGGREGATOR, CALL_CENTRE [v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.channel_partner_id IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.channel_order_ref IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.address_id IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.pin_latitude IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.pin_longitude IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.pin_locked_at IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.capacity_window_id IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.item_amount IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.charges_amount IS 'home collection / rider / delivery charges [v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.tax_amount IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.payment_mode IS 'PREPAID, PAY_AT_VISIT, COD [v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.payment_status IS 'PENDING, PAID, PARTIALLY_REFUNDED, REFUNDED, FAILED [v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.cod_collected_amount IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.partner_price_amount IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.platform_fee_amount IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.corporate_ref IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.insurance_ref IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.order_episode_id IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.parent_order_id IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.appointment_id IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.encounter_id IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.lims_order_ref IS 'clinicalcare.ord_clinical_order id (lab) [v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.rims_study_ref IS 'rims.rad_study id [v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.pharmacy_dispense_ref IS 'pharmacy.pha_dispense id [v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.visit_mode IS 'SELF_VISIT, PICKUP_DROP, HOME_VISIT, TELE [v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.mobility_needs IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.attender_count IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.substitution_preference IS 'ALLOW, DO_NOT_ALLOW [v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.expected_report_at IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.reschedule_count IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.cancel_reason IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.cancelled_at IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';
COMMENT ON COLUMN patientengagement.ecom_online_order.completed_at IS '[v4: Order entity (Website 8.1.2), CHK-001..010, ORD-001..010, PBK/RBK/MBK/OBK/TBK, TMD-005]';

-- patientengagement.ecom_online_order_item  (9 new columns)  FDS: CHK-001, PCS-005, MFF-003, MSH-004
ALTER TABLE patientengagement.ecom_online_order_item ADD COLUMN IF NOT EXISTS listing_id BIGINT NULL;
ALTER TABLE patientengagement.ecom_online_order_item ADD COLUMN IF NOT EXISTS patient_profile_id BIGINT NULL;
ALTER TABLE patientengagement.ecom_online_order_item ADD COLUMN IF NOT EXISTS offer_price DECIMAL(12,2) NULL;
ALTER TABLE patientengagement.ecom_online_order_item ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(12,2) NULL;
ALTER TABLE patientengagement.ecom_online_order_item ADD COLUMN IF NOT EXISTS tax_amount DECIMAL(12,2) NULL;
ALTER TABLE patientengagement.ecom_online_order_item ADD COLUMN IF NOT EXISTS item_status VARCHAR(20) NULL;
ALTER TABLE patientengagement.ecom_online_order_item ADD COLUMN IF NOT EXISTS substitute_item_id INT NULL;
ALTER TABLE patientengagement.ecom_online_order_item ADD COLUMN IF NOT EXISTS not_done_reason VARCHAR(300) NULL;
ALTER TABLE patientengagement.ecom_online_order_item ADD COLUMN IF NOT EXISTS requires_prescription BOOLEAN NULL DEFAULT FALSE;
COMMENT ON COLUMN patientengagement.ecom_online_order_item.listing_id IS '[v4: CHK-001, PCS-005, MFF-003, MSH-004]';
COMMENT ON COLUMN patientengagement.ecom_online_order_item.patient_profile_id IS '[v4: CHK-001, PCS-005, MFF-003, MSH-004]';
COMMENT ON COLUMN patientengagement.ecom_online_order_item.offer_price IS '[v4: CHK-001, PCS-005, MFF-003, MSH-004]';
COMMENT ON COLUMN patientengagement.ecom_online_order_item.discount_amount IS '[v4: CHK-001, PCS-005, MFF-003, MSH-004]';
COMMENT ON COLUMN patientengagement.ecom_online_order_item.tax_amount IS '[v4: CHK-001, PCS-005, MFF-003, MSH-004]';
COMMENT ON COLUMN patientengagement.ecom_online_order_item.item_status IS 'ORDERED, AVAILABLE, UNAVAILABLE, SUBSTITUTED, NOT_COLLECTED, DONE, CANCELLED [v4: CHK-001, PCS-005, MFF-003, MSH-004]';
COMMENT ON COLUMN patientengagement.ecom_online_order_item.substitute_item_id IS 'logical FK -> operationssupply.mst_item [Operations & Supply Chain] [v4: CHK-001, PCS-005, MFF-003, MSH-004]';
COMMENT ON COLUMN patientengagement.ecom_online_order_item.not_done_reason IS '[v4: CHK-001, PCS-005, MFF-003, MSH-004]';
COMMENT ON COLUMN patientengagement.ecom_online_order_item.requires_prescription IS '[v4: CHK-001, PCS-005, MFF-003, MSH-004]';

-- patientengagement.pat_consent  (5 new columns)  FDS: REG-DEM-005, TC-003, TBK-002, PRO-002 (EHR), RAD-TEC-003
ALTER TABLE patientengagement.pat_consent ADD COLUMN IF NOT EXISTS template_code VARCHAR(60) NULL;
ALTER TABLE patientengagement.pat_consent ADD COLUMN IF NOT EXISTS capture_mode VARCHAR(20) NULL;
ALTER TABLE patientengagement.pat_consent ADD COLUMN IF NOT EXISTS otp_verified_at TIMESTAMPTZ(0) NULL;
ALTER TABLE patientengagement.pat_consent ADD COLUMN IF NOT EXISTS procedure_order_item_id BIGINT NULL;
ALTER TABLE patientengagement.pat_consent ADD COLUMN IF NOT EXISTS withdrawn_reason VARCHAR(300) NULL;
COMMENT ON COLUMN patientengagement.pat_consent.template_code IS '[v4: REG-DEM-005, TC-003, TBK-002, PRO-002 (EHR), RAD-TEC-003]';
COMMENT ON COLUMN patientengagement.pat_consent.capture_mode IS 'E_SIGNATURE, SIGNATURE_PAD, OTP, PAPER_SCAN [v4: REG-DEM-005, TC-003, TBK-002, PRO-002 (EHR), RAD-TEC-003]';
COMMENT ON COLUMN patientengagement.pat_consent.otp_verified_at IS '[v4: REG-DEM-005, TC-003, TBK-002, PRO-002 (EHR), RAD-TEC-003]';
COMMENT ON COLUMN patientengagement.pat_consent.procedure_order_item_id IS 'logical FK -> clinicalcare.ord_order_item [Clinical Care] [v4: REG-DEM-005, TC-003, TBK-002, PRO-002 (EHR), RAD-TEC-003]';
COMMENT ON COLUMN patientengagement.pat_consent.withdrawn_reason IS '[v4: REG-DEM-005, TC-003, TBK-002, PRO-002 (EHR), RAD-TEC-003]';

-- patientengagement.pat_patient  (16 new columns)  FDS: REG-UHID-005, REG-DEM-001/002/007/008, REG-ID-006, REG-ABDM-003
ALTER TABLE patientengagement.pat_patient ADD COLUMN IF NOT EXISTS is_temporary BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE patientengagement.pat_patient ADD COLUMN IF NOT EXISTS temporary_converted_at TIMESTAMPTZ(0) NULL;
ALTER TABLE patientengagement.pat_patient ADD COLUMN IF NOT EXISTS name_local_language VARCHAR(200) NULL;
ALTER TABLE patientengagement.pat_patient ADD COLUMN IF NOT EXISTS father_spouse_guardian_name VARCHAR(150) NULL;
ALTER TABLE patientengagement.pat_patient ADD COLUMN IF NOT EXISTS age_years_estimated SMALLINT NULL;
ALTER TABLE patientengagement.pat_patient ADD COLUMN IF NOT EXISTS is_minor BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE patientengagement.pat_patient ADD COLUMN IF NOT EXISTS is_senior_citizen BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE patientengagement.pat_patient ADD COLUMN IF NOT EXISTS mobile_country_code VARCHAR(5) NULL DEFAULT '+91';
ALTER TABLE patientengagement.pat_patient ADD COLUMN IF NOT EXISTS mobile_verified_at TIMESTAMPTZ(0) NULL;
ALTER TABLE patientengagement.pat_patient ADD COLUMN IF NOT EXISTS mobile_owner VARCHAR(20) NULL;
ALTER TABLE patientengagement.pat_patient ADD COLUMN IF NOT EXISTS is_international BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE patientengagement.pat_patient ADD COLUMN IF NOT EXISTS referral_source VARCHAR(50) NULL;
ALTER TABLE patientengagement.pat_patient ADD COLUMN IF NOT EXISTS abha_verified_at TIMESTAMPTZ(0) NULL;
ALTER TABLE patientengagement.pat_patient ADD COLUMN IF NOT EXISTS abha_link_status VARCHAR(20) NULL;
ALTER TABLE patientengagement.pat_patient ADD COLUMN IF NOT EXISTS guardian_patient_id BIGINT NULL;
ALTER TABLE patientengagement.pat_patient ADD COLUMN IF NOT EXISTS duplicate_check_score DECIMAL(5,2) NULL;
COMMENT ON COLUMN patientengagement.pat_patient.is_temporary IS 'temporary UHID for unidentified patients [v4: REG-UHID-005, REG-DEM-001/002/007/008, REG-ID-006, REG-ABDM-003]';
COMMENT ON COLUMN patientengagement.pat_patient.temporary_converted_at IS '[v4: REG-UHID-005, REG-DEM-001/002/007/008, REG-ID-006, REG-ABDM-003]';
COMMENT ON COLUMN patientengagement.pat_patient.name_local_language IS 'optional regional-language name [v4: REG-UHID-005, REG-DEM-001/002/007/008, REG-ID-006, REG-ABDM-003]';
COMMENT ON COLUMN patientengagement.pat_patient.father_spouse_guardian_name IS '[v4: REG-UHID-005, REG-DEM-001/002/007/008, REG-ID-006, REG-ABDM-003]';
COMMENT ON COLUMN patientengagement.pat_patient.age_years_estimated IS 'when DOB unknown (is_dob_estimated = TRUE) [v4: REG-UHID-005, REG-DEM-001/002/007/008, REG-ID-006, REG-ABDM-003]';
COMMENT ON COLUMN patientengagement.pat_patient.is_minor IS '[v4: REG-UHID-005, REG-DEM-001/002/007/008, REG-ID-006, REG-ABDM-003]';
COMMENT ON COLUMN patientengagement.pat_patient.is_senior_citizen IS '[v4: REG-UHID-005, REG-DEM-001/002/007/008, REG-ID-006, REG-ABDM-003]';
COMMENT ON COLUMN patientengagement.pat_patient.mobile_country_code IS '[v4: REG-UHID-005, REG-DEM-001/002/007/008, REG-ID-006, REG-ABDM-003]';
COMMENT ON COLUMN patientengagement.pat_patient.mobile_verified_at IS '[v4: REG-UHID-005, REG-DEM-001/002/007/008, REG-ID-006, REG-ABDM-003]';
COMMENT ON COLUMN patientengagement.pat_patient.mobile_owner IS 'SELF, RELATIVE, GUARDIAN [v4: REG-UHID-005, REG-DEM-001/002/007/008, REG-ID-006, REG-ABDM-003]';
COMMENT ON COLUMN patientengagement.pat_patient.is_international IS '[v4: REG-UHID-005, REG-DEM-001/002/007/008, REG-ID-006, REG-ABDM-003]';
COMMENT ON COLUMN patientengagement.pat_patient.referral_source IS '[v4: REG-UHID-005, REG-DEM-001/002/007/008, REG-ID-006, REG-ABDM-003]';
COMMENT ON COLUMN patientengagement.pat_patient.abha_verified_at IS '[v4: REG-UHID-005, REG-DEM-001/002/007/008, REG-ID-006, REG-ABDM-003]';
COMMENT ON COLUMN patientengagement.pat_patient.abha_link_status IS 'NOT_LINKED, PENDING, LINKED, FAILED [v4: REG-UHID-005, REG-DEM-001/002/007/008, REG-ID-006, REG-ABDM-003]';
COMMENT ON COLUMN patientengagement.pat_patient.guardian_patient_id IS 'minor -> guardian (REG-FAM-002) [v4: REG-UHID-005, REG-DEM-001/002/007/008, REG-ID-006, REG-ABDM-003]';
COMMENT ON COLUMN patientengagement.pat_patient.duplicate_check_score IS '[v4: REG-UHID-005, REG-DEM-001/002/007/008, REG-ID-006, REG-ABDM-003]';

-- patientengagement.pat_patient_identifier  (9 new columns)  FDS: REG-ID-001..007
ALTER TABLE patientengagement.pat_patient_identifier ADD COLUMN IF NOT EXISTS id_value_masked VARCHAR(30) NULL;
ALTER TABLE patientengagement.pat_patient_identifier ADD COLUMN IF NOT EXISTS id_token VARCHAR(128) NULL;
ALTER TABLE patientengagement.pat_patient_identifier ADD COLUMN IF NOT EXISTS format_validated BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE patientengagement.pat_patient_identifier ADD COLUMN IF NOT EXISTS verification_status VARCHAR(20) NULL;
ALTER TABLE patientengagement.pat_patient_identifier ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ(0) NULL;
ALTER TABLE patientengagement.pat_patient_identifier ADD COLUMN IF NOT EXISTS verified_by BIGINT NULL;
ALTER TABLE patientengagement.pat_patient_identifier ADD COLUMN IF NOT EXISTS visa_type VARCHAR(30) NULL;
ALTER TABLE patientengagement.pat_patient_identifier ADD COLUMN IF NOT EXISTS visa_no VARCHAR(30) NULL;
ALTER TABLE patientengagement.pat_patient_identifier ADD COLUMN IF NOT EXISTS visa_valid_to DATE NULL;
COMMENT ON COLUMN patientengagement.pat_patient_identifier.id_value_masked IS 'e.g. XXXX-XXXX-1234 [v4: REG-ID-001..007]';
COMMENT ON COLUMN patientengagement.pat_patient_identifier.id_token IS 'vault token for Aadhaar / sensitive ids [v4: REG-ID-001..007]';
COMMENT ON COLUMN patientengagement.pat_patient_identifier.format_validated IS '[v4: REG-ID-001..007]';
COMMENT ON COLUMN patientengagement.pat_patient_identifier.verification_status IS 'UNVERIFIED, VERIFIED, FAILED [v4: REG-ID-001..007]';
COMMENT ON COLUMN patientengagement.pat_patient_identifier.verified_at IS '[v4: REG-ID-001..007]';
COMMENT ON COLUMN patientengagement.pat_patient_identifier.verified_by IS '[v4: REG-ID-001..007]';
COMMENT ON COLUMN patientengagement.pat_patient_identifier.visa_type IS 'foreign nationals [v4: REG-ID-001..007]';
COMMENT ON COLUMN patientengagement.pat_patient_identifier.visa_no IS '[v4: REG-ID-001..007]';
COMMENT ON COLUMN patientengagement.pat_patient_identifier.visa_valid_to IS '[v4: REG-ID-001..007]';

-- patientengagement.pat_patient_payer  (10 new columns)  FDS: REG-INS-001..005 (Insurance entity), INS-002/003 (Billing)
ALTER TABLE patientengagement.pat_patient_payer ADD COLUMN IF NOT EXISTS policy_type VARCHAR(20) NULL;
ALTER TABLE patientengagement.pat_patient_payer ADD COLUMN IF NOT EXISTS copay_pct DECIMAL(5,2) NULL;
ALTER TABLE patientengagement.pat_patient_payer ADD COLUMN IF NOT EXISTS copay_fixed_amount DECIMAL(12,2) NULL;
ALTER TABLE patientengagement.pat_patient_payer ADD COLUMN IF NOT EXISTS is_cashless BOOLEAN NULL DEFAULT TRUE;
ALTER TABLE patientengagement.pat_patient_payer ADD COLUMN IF NOT EXISTS plan_id INT NULL;
ALTER TABLE patientengagement.pat_patient_payer ADD COLUMN IF NOT EXISTS verification_status VARCHAR(20) NULL;
ALTER TABLE patientengagement.pat_patient_payer ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ(0) NULL;
ALTER TABLE patientengagement.pat_patient_payer ADD COLUMN IF NOT EXISTS verified_by BIGINT NULL;
ALTER TABLE patientengagement.pat_patient_payer ADD COLUMN IF NOT EXISTS verification_channel VARCHAR(20) NULL;
ALTER TABLE patientengagement.pat_patient_payer ADD COLUMN IF NOT EXISTS verification_remarks VARCHAR(500) NULL;
COMMENT ON COLUMN patientengagement.pat_patient_payer.policy_type IS 'INDIVIDUAL, FLOATER, GROUP, GOVT_SCHEME [v4: REG-INS-001..005 (Insurance entity), INS-002/003 (Billing)]';
COMMENT ON COLUMN patientengagement.pat_patient_payer.copay_pct IS '[v4: REG-INS-001..005 (Insurance entity), INS-002/003 (Billing)]';
COMMENT ON COLUMN patientengagement.pat_patient_payer.copay_fixed_amount IS '[v4: REG-INS-001..005 (Insurance entity), INS-002/003 (Billing)]';
COMMENT ON COLUMN patientengagement.pat_patient_payer.is_cashless IS '[v4: REG-INS-001..005 (Insurance entity), INS-002/003 (Billing)]';
COMMENT ON COLUMN patientengagement.pat_patient_payer.plan_id IS 'logical FK -> revenuefinance.mst_insurance_plan [Revenue & Finance] [v4: REG-INS-001..005 (Insurance entity), INS-002/003 (Billing)]';
COMMENT ON COLUMN patientengagement.pat_patient_payer.verification_status IS 'UNVERIFIED, VERIFIED, FAILED, EXPIRED [v4: REG-INS-001..005 (Insurance entity), INS-002/003 (Billing)]';
COMMENT ON COLUMN patientengagement.pat_patient_payer.verified_at IS '[v4: REG-INS-001..005 (Insurance entity), INS-002/003 (Billing)]';
COMMENT ON COLUMN patientengagement.pat_patient_payer.verified_by IS '[v4: REG-INS-001..005 (Insurance entity), INS-002/003 (Billing)]';
COMMENT ON COLUMN patientengagement.pat_patient_payer.verification_channel IS 'MANUAL, NHCX, PORTAL [v4: REG-INS-001..005 (Insurance entity), INS-002/003 (Billing)]';
COMMENT ON COLUMN patientengagement.pat_patient_payer.verification_remarks IS '[v4: REG-INS-001..005 (Insurance entity), INS-002/003 (Billing)]';

-- patientengagement.pat_patient_relation  (7 new columns)  FDS: REG-FAM-001/002/005
ALTER TABLE patientengagement.pat_patient_relation ADD COLUMN IF NOT EXISTS family_group_id BIGINT NULL;
ALTER TABLE patientengagement.pat_patient_relation ADD COLUMN IF NOT EXISTS is_guardian BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE patientengagement.pat_patient_relation ADD COLUMN IF NOT EXISTS can_book_for BOOLEAN NULL DEFAULT TRUE;
ALTER TABLE patientengagement.pat_patient_relation ADD COLUMN IF NOT EXISTS share_clinical_consent BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE patientengagement.pat_patient_relation ADD COLUMN IF NOT EXISTS unlinked_at TIMESTAMPTZ(0) NULL;
ALTER TABLE patientengagement.pat_patient_relation ADD COLUMN IF NOT EXISTS unlinked_by BIGINT NULL;
ALTER TABLE patientengagement.pat_patient_relation ADD COLUMN IF NOT EXISTS unlink_reason VARCHAR(300) NULL;
COMMENT ON COLUMN patientengagement.pat_patient_relation.family_group_id IS '[v4: REG-FAM-001/002/005]';
COMMENT ON COLUMN patientengagement.pat_patient_relation.is_guardian IS '[v4: REG-FAM-001/002/005]';
COMMENT ON COLUMN patientengagement.pat_patient_relation.can_book_for IS '[v4: REG-FAM-001/002/005]';
COMMENT ON COLUMN patientengagement.pat_patient_relation.share_clinical_consent IS 'REG-FAM-004 [v4: REG-FAM-001/002/005]';
COMMENT ON COLUMN patientengagement.pat_patient_relation.unlinked_at IS '[v4: REG-FAM-001/002/005]';
COMMENT ON COLUMN patientengagement.pat_patient_relation.unlinked_by IS '[v4: REG-FAM-001/002/005]';
COMMENT ON COLUMN patientengagement.pat_patient_relation.unlink_reason IS '[v4: REG-FAM-001/002/005]';

-- patientengagement.pat_referral  (13 new columns)  FDS: REF-001..005 (EHR Referral entity), PLN-004
ALTER TABLE patientengagement.pat_referral ADD COLUMN IF NOT EXISTS referral_type VARCHAR(20) NULL;
ALTER TABLE patientengagement.pat_referral ADD COLUMN IF NOT EXISTS to_system_of_medicine VARCHAR(20) NULL;
ALTER TABLE patientengagement.pat_referral ADD COLUMN IF NOT EXISTS external_doctor_name VARCHAR(150) NULL;
ALTER TABLE patientengagement.pat_referral ADD COLUMN IF NOT EXISTS external_contact VARCHAR(150) NULL;
ALTER TABLE patientengagement.pat_referral ADD COLUMN IF NOT EXISTS referral_letter_document_id BIGINT NULL;
ALTER TABLE patientengagement.pat_referral ADD COLUMN IF NOT EXISTS clinical_summary TEXT NULL;
ALTER TABLE patientengagement.pat_referral ADD COLUMN IF NOT EXISTS referral_date DATE NULL;
ALTER TABLE patientengagement.pat_referral ADD COLUMN IF NOT EXISTS appointment_id BIGINT NULL;
ALTER TABLE patientengagement.pat_referral ADD COLUMN IF NOT EXISTS reply_sent_at TIMESTAMPTZ(0) NULL;
ALTER TABLE patientengagement.pat_referral ADD COLUMN IF NOT EXISTS reply_document_id BIGINT NULL;
ALTER TABLE patientengagement.pat_referral ADD COLUMN IF NOT EXISTS consent_to_share BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE patientengagement.pat_referral ADD COLUMN IF NOT EXISTS decline_reason VARCHAR(300) NULL;
ALTER TABLE patientengagement.pat_referral ADD COLUMN IF NOT EXISTS closed_at TIMESTAMPTZ(0) NULL;
COMMENT ON COLUMN patientengagement.pat_referral.referral_type IS 'INTERNAL, EXTERNAL, CROSS_SYSTEM_OF_MEDICINE [v4: REF-001..005 (EHR Referral entity), PLN-004]';
COMMENT ON COLUMN patientengagement.pat_referral.to_system_of_medicine IS '[v4: REF-001..005 (EHR Referral entity), PLN-004]';
COMMENT ON COLUMN patientengagement.pat_referral.external_doctor_name IS '[v4: REF-001..005 (EHR Referral entity), PLN-004]';
COMMENT ON COLUMN patientengagement.pat_referral.external_contact IS '[v4: REF-001..005 (EHR Referral entity), PLN-004]';
COMMENT ON COLUMN patientengagement.pat_referral.referral_letter_document_id IS 'logical FK -> integrationcomms.core_document [Integration & Communications] [v4: REF-001..005 (EHR Referral entity), PLN-004]';
COMMENT ON COLUMN patientengagement.pat_referral.clinical_summary IS '[v4: REF-001..005 (EHR Referral entity), PLN-004]';
COMMENT ON COLUMN patientengagement.pat_referral.referral_date IS '[v4: REF-001..005 (EHR Referral entity), PLN-004]';
COMMENT ON COLUMN patientengagement.pat_referral.appointment_id IS '[v4: REF-001..005 (EHR Referral entity), PLN-004]';
COMMENT ON COLUMN patientengagement.pat_referral.reply_sent_at IS '[v4: REF-001..005 (EHR Referral entity), PLN-004]';
COMMENT ON COLUMN patientengagement.pat_referral.reply_document_id IS 'logical FK -> integrationcomms.core_document [Integration & Communications] [v4: REF-001..005 (EHR Referral entity), PLN-004]';
COMMENT ON COLUMN patientengagement.pat_referral.consent_to_share IS '[v4: REF-001..005 (EHR Referral entity), PLN-004]';
COMMENT ON COLUMN patientengagement.pat_referral.decline_reason IS '[v4: REF-001..005 (EHR Referral entity), PLN-004]';
COMMENT ON COLUMN patientengagement.pat_referral.closed_at IS '[v4: REF-001..005 (EHR Referral entity), PLN-004]';

-- patientengagement.sch_appointment  (24 new columns)  FDS: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS visit_type VARCHAR(20) NULL;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS is_any_doctor BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS doctor_assigned_at TIMESTAMPTZ(0) NULL;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS payer_type VARCHAR(20) NULL;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) NULL;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS payment_reference VARCHAR(100) NULL;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS bill_id BIGINT NULL;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS cancel_reason_code VARCHAR(30) NULL;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS cancelled_by_type VARCHAR(20) NULL;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS cancelled_by_user_id BIGINT NULL;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS is_late_cancellation BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS no_show_marked_at TIMESTAMPTZ(0) NULL;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS remote_checkin_at TIMESTAMPTZ(0) NULL;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS checkin_channel VARCHAR(20) NULL;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS override_reason VARCHAR(300) NULL;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS override_approved_by BIGINT NULL;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS waitlist_id BIGINT NULL;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS reschedule_count SMALLINT NULL DEFAULT 0;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS followup_of_appointment_id BIGINT NULL;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS is_free_followup BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS online_order_id BIGINT NULL;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS session_code VARCHAR(20) NULL;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS tele_consent_id BIGINT NULL;
ALTER TABLE patientengagement.sch_appointment ADD COLUMN IF NOT EXISTS preparation_instructions VARCHAR(1000) NULL;
COMMENT ON COLUMN patientengagement.sch_appointment.visit_type IS 'NEW, FOLLOW_UP, REVIEW, TELECONSULT, ON_DEMAND [v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.is_any_doctor IS 'specialty booking, doctor assigned later [v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.doctor_assigned_at IS '[v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.payer_type IS 'SELF, CORPORATE, INSURANCE, SCHEME [v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.payment_status IS 'NOT_REQUIRED, PENDING, PAID, PAY_AT_COUNTER, REFUNDED [v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.payment_reference IS 'gateway txn / receipt no [v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.bill_id IS 'logical FK -> revenuefinance.bil_bill [Revenue & Finance] [v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.cancel_reason_code IS '[v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.cancelled_by_type IS 'PATIENT, STAFF, DOCTOR, HOSPITAL, SYSTEM [v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.cancelled_by_user_id IS '[v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.is_late_cancellation IS '[v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.no_show_marked_at IS '[v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.remote_checkin_at IS '[v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.checkin_channel IS 'COUNTER, KIOSK, APP, QR [v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.override_reason IS 'full-schedule override [v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.override_approved_by IS '[v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.waitlist_id IS '[v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.reschedule_count IS '[v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.followup_of_appointment_id IS '[v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.is_free_followup IS '[v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.online_order_id IS '[v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.session_code IS 'OPU-003 consultation session code [v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.tele_consent_id IS '[v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';
COMMENT ON COLUMN patientengagement.sch_appointment.preparation_instructions IS '[v4: BKG-003..009, APP-006, WLK-004, DSC-CAN-001..006, SSC-CAL-002, TC-003/004 (Appointment entity)]';

-- patientengagement.sch_practitioner_schedule  (11 new columns)  FDS: DSC-CAL-001..004, DSC-REL-001/002, DSC-LAT-001, DSC-MUL-003, BKG-006
ALTER TABLE patientengagement.sch_practitioner_schedule ADD COLUMN IF NOT EXISTS session_name VARCHAR(50) NULL;
ALTER TABLE patientengagement.sch_practitioner_schedule ADD COLUMN IF NOT EXISTS recurrence_pattern VARCHAR(20) NULL DEFAULT 'WEEKLY';
ALTER TABLE patientengagement.sch_practitioner_schedule ADD COLUMN IF NOT EXISTS week_of_month SMALLINT NULL;
ALTER TABLE patientengagement.sch_practitioner_schedule ADD COLUMN IF NOT EXISTS overbook_limit SMALLINT NULL DEFAULT 0;
ALTER TABLE patientengagement.sch_practitioner_schedule ADD COLUMN IF NOT EXISTS release_window_days SMALLINT NULL DEFAULT 30;
ALTER TABLE patientengagement.sch_practitioner_schedule ADD COLUMN IF NOT EXISTS walkin_release_minutes SMALLINT NULL;
ALTER TABLE patientengagement.sch_practitioner_schedule ADD COLUMN IF NOT EXISTS late_grace_minutes SMALLINT NULL DEFAULT 15;
ALTER TABLE patientengagement.sch_practitioner_schedule ADD COLUMN IF NOT EXISTS queue_mode VARCHAR(20) NULL DEFAULT 'PER_DOCTOR';
ALTER TABLE patientengagement.sch_practitioner_schedule ADD COLUMN IF NOT EXISTS schedule_status VARCHAR(20) NULL DEFAULT 'ACTIVE';
ALTER TABLE patientengagement.sch_practitioner_schedule ADD COLUMN IF NOT EXISTS approved_by BIGINT NULL;
ALTER TABLE patientengagement.sch_practitioner_schedule ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ(0) NULL;
COMMENT ON COLUMN patientengagement.sch_practitioner_schedule.session_name IS 'MORNING, EVENING ... [v4: DSC-CAL-001..004, DSC-REL-001/002, DSC-LAT-001, DSC-MUL-003, BKG-006]';
COMMENT ON COLUMN patientengagement.sch_practitioner_schedule.recurrence_pattern IS 'WEEKLY, ALTERNATE_WEEK, MONTHLY_NTH, ONE_TIME [v4: DSC-CAL-001..004, DSC-REL-001/002, DSC-LAT-001, DSC-MUL-003, BKG-006]';
COMMENT ON COLUMN patientengagement.sch_practitioner_schedule.week_of_month IS '[v4: DSC-CAL-001..004, DSC-REL-001/002, DSC-LAT-001, DSC-MUL-003, BKG-006]';
COMMENT ON COLUMN patientengagement.sch_practitioner_schedule.overbook_limit IS '[v4: DSC-CAL-001..004, DSC-REL-001/002, DSC-LAT-001, DSC-MUL-003, BKG-006]';
COMMENT ON COLUMN patientengagement.sch_practitioner_schedule.release_window_days IS 'advance window [v4: DSC-CAL-001..004, DSC-REL-001/002, DSC-LAT-001, DSC-MUL-003, BKG-006]';
COMMENT ON COLUMN patientengagement.sch_practitioner_schedule.walkin_release_minutes IS 'unbooked slots released to walk-in X min before [v4: DSC-CAL-001..004, DSC-REL-001/002, DSC-LAT-001, DSC-MUL-003, BKG-006]';
COMMENT ON COLUMN patientengagement.sch_practitioner_schedule.late_grace_minutes IS '[v4: DSC-CAL-001..004, DSC-REL-001/002, DSC-LAT-001, DSC-MUL-003, BKG-006]';
COMMENT ON COLUMN patientengagement.sch_practitioner_schedule.queue_mode IS 'PER_DOCTOR, PER_ROOM [v4: DSC-CAL-001..004, DSC-REL-001/002, DSC-LAT-001, DSC-MUL-003, BKG-006]';
COMMENT ON COLUMN patientengagement.sch_practitioner_schedule.schedule_status IS 'DRAFT, PENDING_APPROVAL, ACTIVE, SUSPENDED [v4: DSC-CAL-001..004, DSC-REL-001/002, DSC-LAT-001, DSC-MUL-003, BKG-006]';
COMMENT ON COLUMN patientengagement.sch_practitioner_schedule.approved_by IS '[v4: DSC-CAL-001..004, DSC-REL-001/002, DSC-LAT-001, DSC-MUL-003, BKG-006]';
COMMENT ON COLUMN patientengagement.sch_practitioner_schedule.approved_at IS '[v4: DSC-CAL-001..004, DSC-REL-001/002, DSC-LAT-001, DSC-MUL-003, BKG-006]';

-- patientengagement.sch_queue_token  (14 new columns)  FDS: TKN-GEN-001..003, TKN-ARR-001..003, TKN-EXT-001..003, TKN-HRS-001..004 (Token entity)
ALTER TABLE patientengagement.sch_queue_token ADD COLUMN IF NOT EXISTS token_prefix VARCHAR(5) NULL;
ALTER TABLE patientengagement.sch_queue_token ADD COLUMN IF NOT EXISTS token_category VARCHAR(20) NULL;
ALTER TABLE patientengagement.sch_queue_token ADD COLUMN IF NOT EXISTS priority_category VARCHAR(30) NULL;
ALTER TABLE patientengagement.sch_queue_token ADD COLUMN IF NOT EXISTS sequence_no INT NULL;
ALTER TABLE patientengagement.sch_queue_token ADD COLUMN IF NOT EXISTS arrived_at TIMESTAMPTZ(0) NULL;
ALTER TABLE patientengagement.sch_queue_token ADD COLUMN IF NOT EXISTS arrival_status VARCHAR(20) NULL;
ALTER TABLE patientengagement.sch_queue_token ADD COLUMN IF NOT EXISTS ready_for_doctor_at TIMESTAMPTZ(0) NULL;
ALTER TABLE patientengagement.sch_queue_token ADD COLUMN IF NOT EXISTS hold_count SMALLINT NULL DEFAULT 0;
ALTER TABLE patientengagement.sch_queue_token ADD COLUMN IF NOT EXISTS call_count SMALLINT NULL DEFAULT 0;
ALTER TABLE patientengagement.sch_queue_token ADD COLUMN IF NOT EXISTS estimated_wait_minutes SMALLINT NULL;
ALTER TABLE patientengagement.sch_queue_token ADD COLUMN IF NOT EXISTS issue_mode VARCHAR(20) NULL;
ALTER TABLE patientengagement.sch_queue_token ADD COLUMN IF NOT EXISTS close_reason VARCHAR(30) NULL;
ALTER TABLE patientengagement.sch_queue_token ADD COLUMN IF NOT EXISTS next_step VARCHAR(30) NULL;
ALTER TABLE patientengagement.sch_queue_token ADD COLUMN IF NOT EXISTS service_end_at TIMESTAMPTZ(0) NULL;
COMMENT ON COLUMN patientengagement.sch_queue_token.token_prefix IS '[v4: TKN-GEN-001..003, TKN-ARR-001..003, TKN-EXT-001..003, TKN-HRS-001..004 (Token entity)]';
COMMENT ON COLUMN patientengagement.sch_queue_token.token_category IS 'APPOINTMENT, WALKIN, PRIORITY, ONLINE, REFERRAL [v4: TKN-GEN-001..003, TKN-ARR-001..003, TKN-EXT-001..003, TKN-HRS-001..004 (Token entity)]';
COMMENT ON COLUMN patientengagement.sch_queue_token.priority_category IS 'SENIOR_CITIZEN, DIFFERENTLY_ABLED, EMERGENCY_REFERRAL, PREGNANT [v4: TKN-GEN-001..003, TKN-ARR-001..003, TKN-EXT-001..003, TKN-HRS-001..004 (Token entity)]';
COMMENT ON COLUMN patientengagement.sch_queue_token.sequence_no IS '[v4: TKN-GEN-001..003, TKN-ARR-001..003, TKN-EXT-001..003, TKN-HRS-001..004 (Token entity)]';
COMMENT ON COLUMN patientengagement.sch_queue_token.arrived_at IS '[v4: TKN-GEN-001..003, TKN-ARR-001..003, TKN-EXT-001..003, TKN-HRS-001..004 (Token entity)]';
COMMENT ON COLUMN patientengagement.sch_queue_token.arrival_status IS 'EARLY, ON_TIME, LATE_IN_GRACE, LATE [v4: TKN-GEN-001..003, TKN-ARR-001..003, TKN-EXT-001..003, TKN-HRS-001..004 (Token entity)]';
COMMENT ON COLUMN patientengagement.sch_queue_token.ready_for_doctor_at IS 'vitals / triage done [v4: TKN-GEN-001..003, TKN-ARR-001..003, TKN-EXT-001..003, TKN-HRS-001..004 (Token entity)]';
COMMENT ON COLUMN patientengagement.sch_queue_token.hold_count IS '[v4: TKN-GEN-001..003, TKN-ARR-001..003, TKN-EXT-001..003, TKN-HRS-001..004 (Token entity)]';
COMMENT ON COLUMN patientengagement.sch_queue_token.call_count IS '[v4: TKN-GEN-001..003, TKN-ARR-001..003, TKN-EXT-001..003, TKN-HRS-001..004 (Token entity)]';
COMMENT ON COLUMN patientengagement.sch_queue_token.estimated_wait_minutes IS '[v4: TKN-GEN-001..003, TKN-ARR-001..003, TKN-EXT-001..003, TKN-HRS-001..004 (Token entity)]';
COMMENT ON COLUMN patientengagement.sch_queue_token.issue_mode IS 'PRINT, SMS, APP [v4: TKN-GEN-001..003, TKN-ARR-001..003, TKN-EXT-001..003, TKN-HRS-001..004 (Token entity)]';
COMMENT ON COLUMN patientengagement.sch_queue_token.close_reason IS 'SERVED, NO_SHOW, CANCELLED [v4: TKN-GEN-001..003, TKN-ARR-001..003, TKN-EXT-001..003, TKN-HRS-001..004 (Token entity)]';
COMMENT ON COLUMN patientengagement.sch_queue_token.next_step IS 'BILLING, PHARMACY, LAB, RADIOLOGY, FOLLOW_UP_BOOKING [v4: TKN-GEN-001..003, TKN-ARR-001..003, TKN-EXT-001..003, TKN-HRS-001..004 (Token entity)]';
COMMENT ON COLUMN patientengagement.sch_queue_token.service_end_at IS '[v4: TKN-GEN-001..003, TKN-ARR-001..003, TKN-EXT-001..003, TKN-HRS-001..004 (Token entity)]';

-- patientengagement.sch_schedule_exception  (4 new columns)  FDS: DSC-CAL-003, DSC-CNF-001
ALTER TABLE patientengagement.sch_schedule_exception ADD COLUMN IF NOT EXISTS consult_room_id INT NULL;
ALTER TABLE patientengagement.sch_schedule_exception ADD COLUMN IF NOT EXISTS practitioner_schedule_id BIGINT NULL;
ALTER TABLE patientengagement.sch_schedule_exception ADD COLUMN IF NOT EXISTS is_holiday BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE patientengagement.sch_schedule_exception ADD COLUMN IF NOT EXISTS schedule_change_request_id BIGINT NULL;
COMMENT ON COLUMN patientengagement.sch_schedule_exception.consult_room_id IS '[v4: DSC-CAL-003, DSC-CNF-001]';
COMMENT ON COLUMN patientengagement.sch_schedule_exception.practitioner_schedule_id IS '[v4: DSC-CAL-003, DSC-CNF-001]';
COMMENT ON COLUMN patientengagement.sch_schedule_exception.is_holiday IS '[v4: DSC-CAL-003, DSC-CNF-001]';
COMMENT ON COLUMN patientengagement.sch_schedule_exception.schedule_change_request_id IS '[v4: DSC-CAL-003, DSC-CNF-001]';

-- patientengagement.sch_slot  (4 new columns)  FDS: BKG-002, SLT-005
ALTER TABLE patientengagement.sch_slot ADD COLUMN IF NOT EXISTS held_by_session VARCHAR(100) NULL;
ALTER TABLE patientengagement.sch_slot ADD COLUMN IF NOT EXISTS held_channel VARCHAR(20) NULL;
ALTER TABLE patientengagement.sch_slot ADD COLUMN IF NOT EXISTS visit_type VARCHAR(20) NULL;
ALTER TABLE patientengagement.sch_slot ADD COLUMN IF NOT EXISTS capacity_window_id BIGINT NULL;
COMMENT ON COLUMN patientengagement.sch_slot.held_by_session IS '[v4: BKG-002, SLT-005]';
COMMENT ON COLUMN patientengagement.sch_slot.held_channel IS '[v4: BKG-002, SLT-005]';
COMMENT ON COLUMN patientengagement.sch_slot.visit_type IS '[v4: BKG-002, SLT-005]';
COMMENT ON COLUMN patientengagement.sch_slot.capacity_window_id IS '[v4: BKG-002, SLT-005]';

-- patientengagement.tele_session  (14 new columns)  FDS: TC-002..008 (OPD), TSL-003..005, TRX-003..006, TMD-004/005 (Website)
ALTER TABLE patientengagement.tele_session ADD COLUMN IF NOT EXISTS session_code VARCHAR(20) NULL;
ALTER TABLE patientengagement.tele_session ADD COLUMN IF NOT EXISTS join_link VARCHAR(500) NULL;
ALTER TABLE patientengagement.tele_session ADD COLUMN IF NOT EXISTS join_opens_at TIMESTAMPTZ(0) NULL;
ALTER TABLE patientengagement.tele_session ADD COLUMN IF NOT EXISTS consent_id BIGINT NULL;
ALTER TABLE patientengagement.tele_session ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) NULL;
ALTER TABLE patientengagement.tele_session ADD COLUMN IF NOT EXISTS audio_fallback_used BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE patientengagement.tele_session ADD COLUMN IF NOT EXISTS no_show_party VARCHAR(20) NULL;
ALTER TABLE patientengagement.tele_session ADD COLUMN IF NOT EXISTS failure_reason VARCHAR(300) NULL;
ALTER TABLE patientengagement.tele_session ADD COLUMN IF NOT EXISTS post_failure_action VARCHAR(20) NULL;
ALTER TABLE patientengagement.tele_session ADD COLUMN IF NOT EXISTS doctor_ended_at TIMESTAMPTZ(0) NULL;
ALTER TABLE patientengagement.tele_session ADD COLUMN IF NOT EXISTS close_reason VARCHAR(30) NULL;
ALTER TABLE patientengagement.tele_session ADD COLUMN IF NOT EXISTS advised_in_person BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE patientengagement.tele_session ADD COLUMN IF NOT EXISTS prescription_id BIGINT NULL;
ALTER TABLE patientengagement.tele_session ADD COLUMN IF NOT EXISTS online_order_id BIGINT NULL;
COMMENT ON COLUMN patientengagement.tele_session.session_code IS '[v4: TC-002..008 (OPD), TSL-003..005, TRX-003..006, TMD-004/005 (Website)]';
COMMENT ON COLUMN patientengagement.tele_session.join_link IS '[v4: TC-002..008 (OPD), TSL-003..005, TRX-003..006, TMD-004/005 (Website)]';
COMMENT ON COLUMN patientengagement.tele_session.join_opens_at IS '[v4: TC-002..008 (OPD), TSL-003..005, TRX-003..006, TMD-004/005 (Website)]';
COMMENT ON COLUMN patientengagement.tele_session.consent_id IS '[v4: TC-002..008 (OPD), TSL-003..005, TRX-003..006, TMD-004/005 (Website)]';
COMMENT ON COLUMN patientengagement.tele_session.payment_status IS '[v4: TC-002..008 (OPD), TSL-003..005, TRX-003..006, TMD-004/005 (Website)]';
COMMENT ON COLUMN patientengagement.tele_session.audio_fallback_used IS '[v4: TC-002..008 (OPD), TSL-003..005, TRX-003..006, TMD-004/005 (Website)]';
COMMENT ON COLUMN patientengagement.tele_session.no_show_party IS 'PATIENT, DOCTOR, BOTH [v4: TC-002..008 (OPD), TSL-003..005, TRX-003..006, TMD-004/005 (Website)]';
COMMENT ON COLUMN patientengagement.tele_session.failure_reason IS '[v4: TC-002..008 (OPD), TSL-003..005, TRX-003..006, TMD-004/005 (Website)]';
COMMENT ON COLUMN patientengagement.tele_session.post_failure_action IS 'RESCHEDULED, REFUNDED, NONE [v4: TC-002..008 (OPD), TSL-003..005, TRX-003..006, TMD-004/005 (Website)]';
COMMENT ON COLUMN patientengagement.tele_session.doctor_ended_at IS '"Doc End" [v4: TC-002..008 (OPD), TSL-003..005, TRX-003..006, TMD-004/005 (Website)]';
COMMENT ON COLUMN patientengagement.tele_session.close_reason IS 'PRESCRIPTION_SIGNED, DOCTOR_ENDED, AUTO_TIMEOUT, ADVISED_IN_PERSON [v4: TC-002..008 (OPD), TSL-003..005, TRX-003..006, TMD-004/005 (Website)]';
COMMENT ON COLUMN patientengagement.tele_session.advised_in_person IS '[v4: TC-002..008 (OPD), TSL-003..005, TRX-003..006, TMD-004/005 (Website)]';
COMMENT ON COLUMN patientengagement.tele_session.prescription_id IS 'logical FK -> clinicalcare.ord_prescription [Clinical Care] [v4: TC-002..008 (OPD), TSL-003..005, TRX-003..006, TMD-004/005 (Website)]';
COMMENT ON COLUMN patientengagement.tele_session.online_order_id IS '[v4: TC-002..008 (OPD), TSL-003..005, TRX-003..006, TMD-004/005 (Website)]';

/* ---------- B. NEW TABLES ---------- */

-- ===== OPD Functional Requirements Document v0.2 (Patient Administration Part 1) =====
-- [NEW v4] FDS ref: REG-DEM-004 (OPD 4.1 Address entity)
CREATE TABLE IF NOT EXISTS patientengagement.pat_patient_address (            -- Current / permanent addresses per patient (master-driven PIN, city, district, state)
    patient_address_id         BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    patient_id                 BIGINT NOT NULL,
    address_type               VARCHAR(20) NOT NULL,                           -- CURRENT, PERMANENT, OFFICE, OTHER
    line1                      VARCHAR(200) NOT NULL,
    line2                      VARCHAR(200) NULL,
    locality                   VARCHAR(150) NULL,
    city                       VARCHAR(100) NULL,
    district                   VARCHAR(100) NULL,
    state_code                 VARCHAR(5) NULL,
    pincode                    VARCHAR(10) NULL,
    country_code               VARCHAR(3) NOT NULL DEFAULT 'IN',
    latitude                   DECIMAL(9,6) NULL,
    longitude                  DECIMAL(9,6) NULL,
    is_primary                 BOOLEAN NOT NULL DEFAULT FALSE,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: REG-UHID-003, REG-UHID-004, STO-008 (PACS)
CREATE TABLE IF NOT EXISTS patientengagement.pat_patient_merge (              -- UHID merge requests with maker-checker approval and full audit
    patient_merge_id           BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    surviving_patient_id       BIGINT NOT NULL,
    merged_patient_id          BIGINT NOT NULL,
    match_score                DECIMAL(5,2) NULL,
    merge_reason               VARCHAR(500) NOT NULL,
    requested_by               BIGINT NOT NULL,
    requested_at               TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_by                BIGINT NULL,
    approved_at                TIMESTAMPTZ(0) NULL,
    merge_status               VARCHAR(20) NOT NULL DEFAULT 'PENDING',         -- PENDING, APPROVED, REJECTED, EXECUTED, REVERSED
    snapshot_json              JSONB NULL,                                     -- merged record before merge
    executed_at                TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: REG-DEM-009, REG-FAM-005
CREATE TABLE IF NOT EXISTS patientengagement.pat_demographic_change_log (     -- Field-level audit of demographic changes (old / new value, user, time)
    demographic_change_log_id  BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    patient_id                 BIGINT NOT NULL,
    field_name                 VARCHAR(60) NOT NULL,
    old_value                  VARCHAR(500) NULL,
    new_value                  VARCHAR(500) NULL,
    change_reason              VARCHAR(300) NULL,
    changed_by                 BIGINT NOT NULL,
    changed_at                 TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    terminal_id                VARCHAR(100) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: REG-FAM-001..005 (Family group entity)
CREATE TABLE IF NOT EXISTS patientengagement.pat_family_group (               -- Family group with head / guardian
    family_group_id            BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    family_group_no            VARCHAR(30) NOT NULL UNIQUE,
    group_name                 VARCHAR(150) NULL,
    head_patient_id            BIGINT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: REG-CORP-002..005 (Corporate tag entity)
CREATE TABLE IF NOT EXISTS patientengagement.pat_corporate_tag (              -- Patient tagged to corporate(s) with employee id, relationship, validity and authorisation
    corporate_tag_id           BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    patient_id                 BIGINT NOT NULL,
    corporate_payer_id         INT NOT NULL,                                   -- logical FK -> revenuefinance.mst_payer [Revenue & Finance]
    employee_code              VARCHAR(50) NULL,
    relationship_to_employee   VARCHAR(20) NULL,                               -- SELF, SPOUSE, CHILD, PARENT
    primary_employee_patient_id BIGINT NULL,
    valid_from                 DATE NOT NULL,
    valid_to                   DATE NULL,
    authorisation_ref          VARCHAR(100) NULL,
    authorisation_document_id  BIGINT NULL,                                    -- logical FK -> integrationcomms.core_document [Integration & Communications]
    eligibility_verified_at    TIMESTAMPTZ(0) NULL,
    tag_status                 VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',          -- ACTIVE, EXPIRED, SUSPENDED
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: REG-INS-004, GOV-001..003 (Billing)
CREATE TABLE IF NOT EXISTS patientengagement.pat_scheme_beneficiary (         -- Government scheme beneficiaries (PM-JAY / Ayushman Bharat, Aarogyasri, state schemes)
    scheme_beneficiary_id      BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    patient_id                 BIGINT NOT NULL,
    scheme_code                VARCHAR(30) NOT NULL,                           -- PMJAY, AAROGYASRI, CGHS, ECHS, STATE_xx
    beneficiary_id             VARCHAR(50) NOT NULL,
    family_id                  VARCHAR(50) NULL,
    ecard_no                   VARCHAR(50) NULL,
    eligibility_valid_to       DATE NULL,
    verification_mode          VARCHAR(20) NULL,                               -- AADHAAR_OTP, ECARD, BIOMETRIC, MANUAL
    verified_at                TIMESTAMPTZ(0) NULL,
    verified_by                BIGINT NULL,
    supporting_document_id     BIGINT NULL,                                    -- logical FK -> integrationcomms.core_document [Integration & Communications]
    verification_status        VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: REM-PAT-005 (OPD), ACC-007/008 (Website)
CREATE TABLE IF NOT EXISTS patientengagement.pat_communication_preference (   -- Per patient / customer channel opt-ins, language and quiet hours
    communication_preference_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    patient_id                 BIGINT NULL,
    customer_account_id        BIGINT NULL,
    channel                    VARCHAR(20) NOT NULL,                           -- SMS, WHATSAPP, EMAIL, PUSH, CALL
    purpose                    VARCHAR(20) NOT NULL DEFAULT 'TRANSACTIONAL',   -- TRANSACTIONAL, PROMOTIONAL, REMINDER
    is_opted_in                BOOLEAN NOT NULL DEFAULT TRUE,
    preferred_language         VARCHAR(10) NULL,
    changed_at                 TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: CC-001..004, OPS-009 (Website masked calling)
CREATE TABLE IF NOT EXISTS patientengagement.crm_call_log (                   -- Call centre inbound / outbound call log with outcome
    call_log_id                BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    call_direction             VARCHAR(10) NOT NULL,                           -- INBOUND, OUTBOUND
    caller_number              VARCHAR(20) NOT NULL,
    patient_id                 BIGINT NULL,
    agent_user_id              BIGINT NOT NULL,                                -- logical FK -> identityorg.sec_user_account [Identity & Organization]
    enquiry_id                 BIGINT NULL,
    appointment_id             BIGINT NULL,
    online_order_id            BIGINT NULL,
    call_started_at            TIMESTAMPTZ(0) NOT NULL,
    call_ended_at              TIMESTAMPTZ(0) NULL,
    call_outcome               VARCHAR(30) NULL,                               -- BOOKED, RESCHEDULED, CANCELLED, INFO_GIVEN, CALLBACK, NO_ANSWER
    payment_link_sent          BOOLEAN NOT NULL DEFAULT FALSE,
    recording_uri              VARCHAR(500) NULL,
    is_masked_call             BOOLEAN NOT NULL DEFAULT FALSE,
    notes                      VARCHAR(1000) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: RPT-007
CREATE TABLE IF NOT EXISTS patientengagement.pat_report_dispatch_batch (      -- Bulk dispatch / handover batch (e.g. corporate health-check) with consolidated acknowledgement
    report_dispatch_batch_id   BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    batch_no                   VARCHAR(30) NOT NULL UNIQUE,
    corporate_payer_id         INT NULL,                                       -- logical FK -> revenuefinance.mst_payer [Revenue & Finance]
    dispatch_mode              VARCHAR(20) NOT NULL,
    report_count               INT NOT NULL DEFAULT 0,
    handed_over_to             VARCHAR(150) NULL,
    acknowledgement_document_id BIGINT NULL,                                   -- logical FK -> integrationcomms.core_document [Integration & Communications]
    dispatched_by              BIGINT NULL,
    dispatched_at              TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: RPT-001..011 (Report dispatch entity), LAB-RPT-012, RAD-RPT-010
CREATE TABLE IF NOT EXISTS patientengagement.pat_report_dispatch (            -- Report dispatch log for lab, radiology and other reports (counter, e-mail, portal, WhatsApp, courier)
    report_dispatch_id         BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    patient_id                 BIGINT NOT NULL,
    source_service             VARCHAR(20) NOT NULL,                           -- LIMS, RIMS, CLINICAL_CARE, PHARMACY
    report_type                VARCHAR(30) NOT NULL,                           -- LAB_REPORT, RAD_REPORT, DISCHARGE_SUMMARY, PRESCRIPTION, FILM_CD
    report_ref_id              BIGINT NOT NULL,                                -- lims.lab_report / rims.rad_report id
    report_version             SMALLINT NULL,
    document_id                BIGINT NULL,                                    -- logical FK -> integrationcomms.core_document [Integration & Communications]
    dispatch_batch_id          BIGINT NULL,
    dispatch_mode              VARCHAR(20) NOT NULL,                           -- COUNTER, EMAIL, PORTAL, SMS_LINK, WHATSAPP, COURIER, CORPORATE, ABHA_LOCKER
    recipient_name             VARCHAR(150) NULL,
    recipient_relationship     VARCHAR(30) NULL,
    recipient_address          VARCHAR(200) NULL,
    identity_check_mode        VARCHAR(20) NULL,                               -- OTP, PHOTO_ID, UHID_MOBILE
    signature_uri              VARCHAR(500) NULL,
    secure_link_id             BIGINT NULL,                                    -- logical FK -> integrationcomms.comm_secure_link [Integration & Communications]
    is_duplicate               BOOLEAN NOT NULL DEFAULT FALSE,
    duplicate_reason           VARCHAR(300) NULL,
    dispatch_status            VARCHAR(20) NOT NULL DEFAULT 'READY',           -- READY, DISPATCHED, PENDING_COLLECTION, DELIVERED, RETURNED, FAILED
    dispatched_by              BIGINT NULL,
    dispatched_at              TIMESTAMPTZ(0) NULL,
    delivered_at               TIMESTAMPTZ(0) NULL,
    reminder_count             SMALLINT NOT NULL DEFAULT 0,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: DSC-CAL-002, BKG-003
CREATE TABLE IF NOT EXISTS patientengagement.sch_schedule_visit_type (        -- Slot duration / capacity / fee per visit type within a schedule
    schedule_visit_type_id     BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    practitioner_schedule_id   BIGINT NOT NULL,
    visit_type                 VARCHAR(20) NOT NULL,                           -- NEW, FOLLOW_UP, REVIEW, TELECONSULT, ON_DEMAND, PROCEDURE
    slot_minutes               SMALLINT NOT NULL,
    capacity_per_slot          SMALLINT NOT NULL DEFAULT 1,
    overbook_limit             SMALLINT NOT NULL DEFAULT 0,
    service_id                 INT NULL,                                       -- logical FK -> revenuefinance.mst_service [Revenue & Finance]
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: BKG-006, WLK-003, SLT-006 (Website)
CREATE TABLE IF NOT EXISTS patientengagement.sch_channel_quota (              -- Channel-wise slot quotas (walk-in, call centre, portal, app, aggregator, B2B)
    channel_quota_id           BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    practitioner_schedule_id   BIGINT NULL,
    resource_schedule_id       BIGINT NULL,
    channel                    VARCHAR(20) NOT NULL,                           -- WALKIN, CALL_CENTRE, PORTAL, APP, AGGREGATOR, B2B, KIOSK
    quota_type                 VARCHAR(10) NOT NULL DEFAULT 'COUNT',           -- COUNT, PERCENT
    quota_value                DECIMAL(6,2) NOT NULL,
    release_unused_minutes     SMALLINT NULL,                                  -- release unused quota before session
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: DSC-CAL-004, DSC-CNF-002, DSC-CAN-005
CREATE TABLE IF NOT EXISTS patientengagement.sch_schedule_change_request (    -- Doctor-requested schedule changes routed to scheduler for approval; bulk reschedule tracking
    schedule_change_request_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    practitioner_id            BIGINT NOT NULL,                                -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    practitioner_schedule_id   BIGINT NULL,
    change_type                VARCHAR(20) NOT NULL,                           -- NEW_SESSION, MODIFY, CANCEL_SESSION, LEAVE, EXTRA_SESSION
    effective_from             TIMESTAMPTZ(0) NOT NULL,
    effective_to               TIMESTAMPTZ(0) NULL,
    proposed_json              JSONB NULL,
    reason                     VARCHAR(500) NULL,
    affected_appointments      INT NULL,
    request_status             VARCHAR(20) NOT NULL DEFAULT 'PENDING',         -- PENDING, APPROVED, REJECTED, APPLIED
    decided_by                 BIGINT NULL,
    decided_at                 TIMESTAMPTZ(0) NULL,
    bulk_action                VARCHAR(20) NULL,                               -- RESCHEDULE, CANCEL, NONE
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: SSC-CAL-003 (OPD), RAD-SCH-001 (RIMS), SLT-002/007/008/009 (Website)
CREATE TABLE IF NOT EXISTS patientengagement.sch_resource_schedule (          -- Generic capacity templates for non-doctor resources: modality, phlebo zone, rider zone, provider, pharmacy delivery, specialty session
    resource_schedule_id       BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    resource_type              VARCHAR(20) NOT NULL,                           -- SPECIALTY, MODALITY, PHLEBO_ZONE, RIDER_ZONE, PROVIDER, PHARMACY_DELIVERY, OT, ROOM
    resource_id                BIGINT NOT NULL,
    specialty_id               INT NULL,                                       -- logical FK -> identityorg.mst_specialty [Identity & Organization]
    service_line               VARCHAR(20) NULL,                               -- LAB, RAD, PHARMACY, OPD, TELE
    day_of_week                SMALLINT NULL,                                  -- 0-6, NULL = every day
    window_start               TIME NOT NULL,
    window_end                 TIME NOT NULL,
    slot_minutes               SMALLINT NOT NULL,
    capacity_per_slot          SMALLINT NOT NULL DEFAULT 1,
    booking_cutoff_minutes     INT NULL,                                       -- e.g. same-day home collection cut-off
    slot_rule_json             JSONB NULL,                                     -- e.g. fasting tests only before 10:00
    release_window_days        SMALLINT NULL DEFAULT 30,
    effective_from             DATE NOT NULL,
    effective_to               DATE NULL,
    assignment_mode            VARCHAR(20) NULL,                               -- for SPECIALTY: AUTO_AT_BOOKING, AT_CHECKIN
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: SLT-001..010 (Website Slot / capacity entity), SSC-CAL-001/002, SSC-REL-002
CREATE TABLE IF NOT EXISTS patientengagement.sch_capacity_window (            -- Materialised capacity per resource / date / window with channel allotments, holds and blocks
    capacity_window_id         BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NOT NULL,                                   -- logical FK -> identityorg.core_branch [Identity & Organization]
    resource_schedule_id       BIGINT NULL,
    resource_type              VARCHAR(20) NOT NULL,
    resource_id                BIGINT NOT NULL,
    window_date                DATE NOT NULL,
    window_start               TIMESTAMPTZ(0) NOT NULL,
    window_end                 TIMESTAMPTZ(0) NOT NULL,
    capacity                   SMALLINT NOT NULL,
    booked_count               SMALLINT NOT NULL DEFAULT 0,
    held_count                 SMALLINT NOT NULL DEFAULT 0,
    blocked_count              SMALLINT NOT NULL DEFAULT 0,
    channel_booked_json        JSONB NULL,                                     -- {"APP":3,"AGGREGATOR":1}
    cutoff_at                  TIMESTAMPTZ(0) NULL,
    window_status              VARCHAR(20) NOT NULL DEFAULT 'OPEN',            -- OPEN, FULL, BLOCKED, CLOSED
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT                 uq_sch_capacity_window_1 UNIQUE (resource_type, resource_id, window_start)
);

-- [NEW v4] FDS ref: BKG-009, DSC-CAN-002
CREATE TABLE IF NOT EXISTS patientengagement.sch_waitlist (                   -- Waiting list for full sessions; cancelled slots offered to waiting patients
    waitlist_id                BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    patient_id                 BIGINT NULL,
    contact_mobile             VARCHAR(15) NULL,
    practitioner_id            BIGINT NULL,                                    -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    specialty_id               INT NULL,                                       -- logical FK -> identityorg.mst_specialty [Identity & Organization]
    preferred_date             DATE NOT NULL,
    preferred_session          VARCHAR(20) NULL,
    visit_type                 VARCHAR(20) NULL,
    channel                    VARCHAR(20) NULL,
    priority                   SMALLINT NOT NULL DEFAULT 5,
    offered_slot_id            BIGINT NULL,
    offered_at                 TIMESTAMPTZ(0) NULL,
    offer_expires_at           TIMESTAMPTZ(0) NULL,
    waitlist_status            VARCHAR(20) NOT NULL DEFAULT 'WAITING',         -- WAITING, OFFERED, BOOKED, EXPIRED, CANCELLED
    appointment_id             BIGINT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TKN-HRS-001..004, DSC-MUL-004
CREATE TABLE IF NOT EXISTS patientengagement.sch_queue_token_event (          -- Every call / hold / release / skip / recall / room change of a token with user and reason
    queue_token_event_id       BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    queue_token_id             BIGINT NOT NULL,
    event_type                 VARCHAR(20) NOT NULL,                           -- CALLED, HOLD, RELEASE, SKIP, RECALL, ROOM_CHANGE, NO_SHOW, CLOSE
    event_at                   TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    event_by                   BIGINT NULL,
    reason                     VARCHAR(300) NULL,
    release_position           VARCHAR(20) NULL,                               -- ORIGINAL, END_OF_QUEUE
    from_room_id               INT NULL,
    to_room_id                 INT NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TKN-DSP-001..003
CREATE TABLE IF NOT EXISTS patientengagement.sch_display_board (              -- Waiting-area display screens and audio announcement configuration
    display_board_id           INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    board_code                 VARCHAR(30) NOT NULL UNIQUE,
    board_name                 VARCHAR(100) NOT NULL,
    location_text              VARCHAR(150) NULL,
    user_device_id             INT NULL,                                       -- logical FK -> identityorg.sec_user_device [Identity & Organization]
    languages                  VARCHAR(50) NOT NULL DEFAULT 'en',
    audio_enabled              BOOLEAN NOT NULL DEFAULT TRUE,
    show_patient_name          BOOLEAN NOT NULL DEFAULT FALSE,
    rooms_json                 JSONB NULL,                                     -- consult rooms shown
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: ODB-001, DSC-CNF-003, TSL-002, REM-DOC-004
CREATE TABLE IF NOT EXISTS patientengagement.sch_practitioner_availability (  -- Real-time doctor availability ("Available now" / delay / break) for on-demand consults
    practitioner_availability_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    practitioner_id            BIGINT NOT NULL,                                -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    availability_status        VARCHAR(20) NOT NULL,                           -- AVAILABLE_NOW, BUSY, ON_BREAK, DELAYED, OFFLINE
    consult_mode               VARCHAR(20) NULL,                               -- TELE_VIDEO, TELE_AUDIO, IN_PERSON
    delay_minutes              SMALLINT NULL,
    status_from                TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status_to                  TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: ODB-002..005, TSL-002
CREATE TABLE IF NOT EXISTS patientengagement.sch_ondemand_request (           -- Doctor-on-demand consultation requests, auto-assignment and accept / decline
    ondemand_request_id        BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    request_no                 VARCHAR(30) NOT NULL UNIQUE,
    patient_id                 BIGINT NOT NULL,
    specialty_id               INT NULL,                                       -- logical FK -> identityorg.mst_specialty [Identity & Organization]
    requested_practitioner_id  BIGINT NULL,                                    -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    assigned_practitioner_id   BIGINT NULL,                                    -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    consult_mode               VARCHAR(20) NOT NULL,
    requested_at               TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estimated_wait_minutes     SMALLINT NULL,
    offered_at                 TIMESTAMPTZ(0) NULL,
    responded_at               TIMESTAMPTZ(0) NULL,
    decline_reason             VARCHAR(300) NULL,
    assignment_attempts        SMALLINT NOT NULL DEFAULT 0,
    payment_reference          VARCHAR(100) NULL,
    appointment_id             BIGINT NULL,
    tele_session_id            BIGINT NULL,
    request_status             VARCHAR(20) NOT NULL DEFAULT 'REQUESTED',       -- REQUESTED, OFFERED, ACCEPTED, DECLINED, TIMED_OUT, CONVERTED, CANCELLED
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TC-005, TBK-004 (tele pre-consult), PBK-005, RBK-004, OBK-004 (Website Safety / pre-visit answers entity), SUB-004 (EHR)
CREATE TABLE IF NOT EXISTS patientengagement.pat_questionnaire_response (     -- Pre-visit / safety / pre-collection questionnaire answers for appointments and online orders
    questionnaire_response_id  BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    questionnaire_id           INT NOT NULL,
    questionnaire_version      SMALLINT NOT NULL,
    patient_id                 BIGINT NULL,
    appointment_id             BIGINT NULL,
    online_order_id            BIGINT NULL,
    question_id                INT NOT NULL,
    answer_text                VARCHAR(1000) NULL,
    answer_json                JSONB NULL,
    is_blocking                BOOLEAN NOT NULL DEFAULT FALSE,
    answered_at                TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);


-- ===== FDS Website & E-commerce Portal - Part 1 (Marketplace, partner e-WP, i-WP) =====
-- [NEW v4] FDS ref: ACC-001..009 (Customer account entity)
CREATE TABLE IF NOT EXISTS patientengagement.ecom_customer_account (          -- Marketplace customer account (website / app login) separate from patient master
    customer_account_id        BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    account_no                 VARCHAR(30) NOT NULL UNIQUE,
    user_id                    BIGINT NULL,                                    -- logical FK -> identityorg.sec_user_account [Identity & Organization]
    mobile                     VARCHAR(15) NOT NULL,
    email                      VARCHAR(150) NULL,
    login_method               VARCHAR(20) NOT NULL DEFAULT 'OTP',             -- OTP, PASSWORD, SOCIAL
    account_status             VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',          -- ACTIVE, SUSPENDED, DELETION_REQUESTED, ANONYMISED
    referral_code              VARCHAR(20) NULL,
    registered_channel         VARCHAR(20) NULL,                               -- WEBSITE, ANDROID, IOS, AGGREGATOR
    deletion_requested_at      TIMESTAMPTZ(0) NULL,
    anonymised_at              TIMESTAMPTZ(0) NULL,
    last_login_at              TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: ACC-007, ACC-008, ACC-009
CREATE TABLE IF NOT EXISTS patientengagement.ecom_customer_consent (          -- Consents captured at sign-up / booking (terms, privacy, communication, tele, data sharing)
    customer_consent_id        BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    customer_account_id        BIGINT NOT NULL,
    consent_type               VARCHAR(30) NOT NULL,                           -- TERMS, PRIVACY, COMMUNICATION, TELECONSULT, DATA_SHARING, MARKETING
    consent_version            VARCHAR(20) NOT NULL,
    given_at                   TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    withdrawn_at               TIMESTAMPTZ(0) NULL,
    channel                    VARCHAR(20) NULL,
    client_ip                  VARCHAR(45) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: ACC-003..005 (Patient profile entity), PBK-006
CREATE TABLE IF NOT EXISTS patientengagement.ecom_patient_profile (           -- Patient profiles under a customer account (self / family) linked to UHID and ABHA
    patient_profile_id         BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    customer_account_id        BIGINT NOT NULL,
    relationship               VARCHAR(20) NOT NULL,                           -- SELF, SPOUSE, CHILD, PARENT, SIBLING, OTHER
    full_name                  VARCHAR(150) NOT NULL,
    date_of_birth              DATE NULL,
    age_years                  SMALLINT NULL,
    gender                     VARCHAR(10) NOT NULL,
    patient_id                 BIGINT NULL,                                    -- UHID link after verification
    uhid_linked_at             TIMESTAMPTZ(0) NULL,
    abha_address               VARCHAR(100) NULL,
    guardian_profile_id        BIGINT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: ACC-006, LOC-001..008 (Address entity)
CREATE TABLE IF NOT EXISTS patientengagement.ecom_customer_address (          -- Address book with map pin and access instructions
    customer_address_id        BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    customer_account_id        BIGINT NOT NULL,
    label                      VARCHAR(20) NOT NULL DEFAULT 'HOME',            -- HOME, OFFICE, OTHER
    latitude                   DECIMAL(9,6) NOT NULL,
    longitude                  DECIMAL(9,6) NOT NULL,
    house_flat                 VARCHAR(100) NOT NULL,
    street                     VARCHAR(200) NULL,
    landmark                   VARCHAR(150) NULL,
    area                       VARCHAR(150) NULL,
    city                       VARCHAR(100) NULL,
    pincode                    VARCHAR(10) NOT NULL,
    contact_person             VARCHAR(100) NULL,
    contact_mobile             VARCHAR(15) NULL,
    access_instructions        VARCHAR(500) NULL,                              -- gate, floor, lift, pets, parking
    is_default                 BOOLEAN NOT NULL DEFAULT FALSE,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: MKT-005/007, PWP-001..010 (Provider entity)
CREATE TABLE IF NOT EXISTS patientengagement.mkt_provider (                   -- Marketplace providers: internal centres, partner labs, hospitals, pharmacies, doctors
    provider_id                BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    provider_code              VARCHAR(30) NOT NULL UNIQUE,
    provider_type              VARCHAR(20) NOT NULL,                           -- INTERNAL_CENTRE, PARTNER_LAB, PARTNER_HOSPITAL, PHARMACY, DOCTOR, PARTNER_IMAGING
    is_internal                BOOLEAN NOT NULL DEFAULT FALSE,
    internal_branch_id         INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    practitioner_id            BIGINT NULL,                                    -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    display_name               VARCHAR(200) NOT NULL,
    legal_entity_name          VARCHAR(200) NULL,
    gstin                      VARCHAR(15) NULL,
    pan_no                     VARCHAR(10) NULL,
    accreditation              VARCHAR(100) NULL,                              -- NABL, NABH, CAP, ...
    rating_avg                 DECIMAL(3,2) NULL,
    rating_count               INT NOT NULL DEFAULT 0,
    commission_plan_id         INT NULL,
    integration_mode           VARCHAR(20) NULL,                               -- INTEGRATED, UPLOAD_MODE (e-WP manual)
    onboarding_status          VARCHAR(20) NOT NULL DEFAULT 'DRAFT',           -- DRAFT, SUBMITTED, VERIFIED, ACTIVE, SUSPENDED, DELISTED
    suspended_reason           VARCHAR(300) NULL,
    seo_slug                   VARCHAR(200) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: PWP-003, MKT-007
CREATE TABLE IF NOT EXISTS patientengagement.mkt_provider_location (          -- Provider service locations, timings and holidays
    provider_location_id       BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    provider_id                BIGINT NOT NULL,
    location_name              VARCHAR(150) NOT NULL,
    address_text               VARCHAR(500) NULL,
    latitude                   DECIMAL(9,6) NULL,
    longitude                  DECIMAL(9,6) NULL,
    pincode                    VARCHAR(10) NULL,
    timings_json               JSONB NULL,
    holidays_json              JSONB NULL,
    is_home_service_base       BOOLEAN NOT NULL DEFAULT FALSE,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: PWP-001, VEN-002-like controls for partners
CREATE TABLE IF NOT EXISTS patientengagement.mkt_provider_document (          -- Provider licences / agreements with expiry (drug licence, NABL, registration)
    provider_document_id       BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    provider_id                BIGINT NOT NULL,
    document_type              VARCHAR(30) NOT NULL,                           -- DRUG_LICENCE, NABL, NABH, CLINIC_REGISTRATION, AGREEMENT, GST
    document_no                VARCHAR(100) NULL,
    valid_from                 DATE NULL,
    valid_to                   DATE NULL,
    document_id                BIGINT NULL,                                    -- logical FK -> integrationcomms.core_document [Integration & Communications]
    verification_status        VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: CHK-008, PWP-008
CREATE TABLE IF NOT EXISTS patientengagement.mkt_commission_plan (            -- Partner commission / platform fee plans
    commission_plan_id         INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    plan_code                  VARCHAR(30) NOT NULL UNIQUE,
    plan_name                  VARCHAR(100) NOT NULL,
    service_line               VARCHAR(20) NULL,
    commission_type            VARCHAR(10) NOT NULL,                           -- PERCENT, FLAT
    commission_value           DECIMAL(10,2) NOT NULL,
    tds_applicable             BOOLEAN NOT NULL DEFAULT TRUE,
    valid_from                 DATE NOT NULL,
    valid_to                   DATE NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: MKT-002..004, MKT-009, MKT-013, MKT-014
CREATE TABLE IF NOT EXISTS patientengagement.mkt_catalogue_item (             -- Platform catalogue (tests, packages, scans, medicines, consult types) with SEO content
    catalogue_item_id          BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    item_type                  VARCHAR(20) NOT NULL,                           -- LAB_TEST, PACKAGE, SCAN, MEDICINE, CONSULTATION
    service_id                 INT NULL,                                       -- logical FK -> revenuefinance.mst_service [Revenue & Finance]
    item_id                    INT NULL,                                       -- logical FK -> operationssupply.mst_item [Operations & Supply Chain]
    display_name               VARCHAR(200) NOT NULL,
    also_known_as              VARCHAR(500) NULL,
    description                TEXT NULL,
    sample_type_or_body_part   VARCHAR(100) NULL,
    preparation_text           VARCHAR(1000) NULL,
    requires_prescription      BOOLEAN NOT NULL DEFAULT FALSE,
    home_service_allowed       BOOLEAN NOT NULL DEFAULT FALSE,
    is_bed_or_room             BOOLEAN NOT NULL DEFAULT FALSE,                 -- always FALSE - beds excluded from online booking (BED-001)
    seo_slug                   VARCHAR(200) NULL,
    meta_json                  JSONB NULL,
    translations_json          JSONB NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: MKT-005, MKT-010, PWP-002 (Listing entity)
CREATE TABLE IF NOT EXISTS patientengagement.mkt_listing (                    -- Provider offering of a catalogue item with price, offer price, TAT and approval
    listing_id                 BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    provider_id                BIGINT NOT NULL,
    catalogue_item_id          BIGINT NOT NULL,
    provider_item_code         VARCHAR(50) NULL,
    mrp_price                  DECIMAL(12,2) NOT NULL,
    offer_price                DECIMAL(12,2) NULL,
    partner_price              DECIMAL(12,2) NULL,                             -- agreed price payable to partner
    tat_hours                  SMALLINT NULL,
    service_options            VARCHAR(50) NULL,                               -- HOME_COLLECTION, PICKUP, WALKIN, DELIVERY, TELE
    preparation_override       VARCHAR(1000) NULL,
    approval_status            VARCHAR(20) NOT NULL DEFAULT 'PENDING',         -- PENDING, APPROVED, REJECTED, SUSPENDED
    valid_from                 DATE NOT NULL,
    valid_to                   DATE NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT                 uq_mkt_listing_1 UNIQUE (provider_id, catalogue_item_id, valid_from)
);

-- [NEW v4] FDS ref: LOC-003..005 (Service zone entity)
CREATE TABLE IF NOT EXISTS patientengagement.mkt_service_zone (               -- Serviceability zones per provider / agent pool and service line (PIN list, radius, polygon)
    service_zone_id            BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    provider_id                BIGINT NULL,
    zone_name                  VARCHAR(100) NOT NULL,
    service_line               VARCHAR(20) NOT NULL,                           -- LAB, RAD, PHARMACY, OPD, AGENT_POOL
    zone_type                  VARCHAR(10) NOT NULL,                           -- PIN_LIST, RADIUS, POLYGON
    pin_codes                  TEXT NULL,
    centre_lat                 DECIMAL(9,6) NULL,
    centre_lng                 DECIMAL(9,6) NULL,
    radius_km                  DECIMAL(6,2) NULL,
    polygon_geojson            JSONB NULL,
    charge_rule_json           JSONB NULL,                                     -- zone-based home collection / rider charges
    effective_from             DATE NOT NULL,
    effective_to               DATE NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: PBK-005, RBK-004, TBK-004, OBK-004
CREATE TABLE IF NOT EXISTS patientengagement.mkt_questionnaire (              -- Configurable questionnaires (pre-collection, modality safety, tele pre-consult, pre-visit)
    questionnaire_id           INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    questionnaire_code         VARCHAR(40) NOT NULL,
    questionnaire_name         VARCHAR(150) NOT NULL,
    purpose                    VARCHAR(30) NOT NULL,                           -- PRE_COLLECTION, MODALITY_SAFETY, TELE_PRECONSULT, PRE_VISIT
    applies_to_service_id      INT NULL,                                       -- logical FK -> revenuefinance.mst_service [Revenue & Finance]
    modality_type              VARCHAR(10) NULL,
    version_no                 SMALLINT NOT NULL DEFAULT 1,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: PBK-005, RBK-004
CREATE TABLE IF NOT EXISTS patientengagement.mkt_questionnaire_question (     -- Questions of a questionnaire with blocking answers
    questionnaire_question_id  INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    questionnaire_id           INT NOT NULL,
    question_code              VARCHAR(40) NOT NULL,
    question_text              VARCHAR(500) NOT NULL,
    answer_type                VARCHAR(20) NOT NULL,                           -- YES_NO, TEXT, NUMBER, DATE, OPTION
    options_json               JSONB NULL,
    blocking_answer_json       JSONB NULL,                                     -- answers that block booking / need review
    display_order              SMALLINT NOT NULL DEFAULT 1,
    is_mandatory               BOOLEAN NOT NULL DEFAULT TRUE,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: URS 162 Aggregator channel partner; CHK-008, SLT-006
CREATE TABLE IF NOT EXISTS patientengagement.mkt_channel_partner (            -- Aggregator / channel partners (RateTiger-like channel manager) with B2B mapping
    channel_partner_id         INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    channel_code               VARCHAR(30) NOT NULL UNIQUE,
    channel_name               VARCHAR(100) NOT NULL,
    payer_id                   INT NULL,                                       -- B2B payer for billing | logical FK -> revenuefinance.mst_payer [Revenue & Finance]
    integration_type           VARCHAR(20) NULL,                               -- API, WEBHOOK, SFTP
    endpoint_id                INT NULL,                                       -- logical FK -> integrationcomms.intg_hl7_dicom_endpoint [Integration & Communications]
    inventory_sync_mode        VARCHAR(20) NULL,                               -- REALTIME, PERIODIC
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: SLT-006, CHK-008
CREATE TABLE IF NOT EXISTS patientengagement.mkt_channel_listing_map (        -- Mapping of platform listings to channel partner product codes
    channel_listing_map_id     BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    channel_partner_id         INT NOT NULL,
    listing_id                 BIGINT NOT NULL,
    external_code              VARCHAR(100) NOT NULL,
    channel_price              DECIMAL(12,2) NULL,
    is_published               BOOLEAN NOT NULL DEFAULT TRUE,
    last_synced_at             TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: PWP-008
CREATE TABLE IF NOT EXISTS patientengagement.mkt_partner_settlement (         -- Periodic settlement statement per partner (gross, commission, TDS, refunds, net)
    partner_settlement_id      BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    provider_id                BIGINT NOT NULL,
    settlement_no              VARCHAR(30) NOT NULL UNIQUE,
    period_from                DATE NOT NULL,
    period_to                  DATE NOT NULL,
    order_count                INT NOT NULL DEFAULT 0,
    gross_amount               DECIMAL(14,2) NOT NULL DEFAULT 0,
    commission_amount          DECIMAL(14,2) NOT NULL DEFAULT 0,
    tax_amount                 DECIMAL(14,2) NOT NULL DEFAULT 0,
    tds_amount                 DECIMAL(14,2) NOT NULL DEFAULT 0,
    refund_amount              DECIMAL(14,2) NOT NULL DEFAULT 0,
    net_payable                DECIMAL(14,2) NOT NULL DEFAULT 0,
    settlement_status          VARCHAR(20) NOT NULL DEFAULT 'DRAFT',           -- DRAFT, SHARED, DISPUTED, APPROVED, PAID
    voucher_id                 BIGINT NULL,                                    -- logical FK -> revenuefinance.fin_voucher [Revenue & Finance]
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: PWP-008
CREATE TABLE IF NOT EXISTS patientengagement.mkt_partner_settlement_line (    -- Order-level lines of a partner settlement
    partner_settlement_line_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    partner_settlement_id      BIGINT NOT NULL,
    online_order_id            BIGINT NOT NULL,
    order_value                DECIMAL(12,2) NOT NULL,
    partner_price              DECIMAL(12,2) NULL,
    commission_amount          DECIMAL(12,2) NULL,
    refund_amount              DECIMAL(12,2) NULL,
    net_amount                 DECIMAL(12,2) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: MKT-011, ORD-011, PRP-008, TRX-005 (Rating / review entity)
CREATE TABLE IF NOT EXISTS patientengagement.ecom_rating_review (             -- Ratings and reviews for providers, doctors and field agents with moderation
    rating_review_id           BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    online_order_id            BIGINT NULL,
    appointment_id             BIGINT NULL,
    customer_account_id        BIGINT NULL,
    target_type                VARCHAR(20) NOT NULL,                           -- PROVIDER, DOCTOR, AGENT
    target_id                  BIGINT NOT NULL,
    stars                      SMALLINT NOT NULL,
    comment_text               VARCHAR(2000) NULL,
    moderation_status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',         -- PENDING, PUBLISHED, REJECTED
    moderated_by               BIGINT NULL,
    moderated_at               TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: CHK-001, CHK-002
CREATE TABLE IF NOT EXISTS patientengagement.ecom_cart (                      -- Customer cart grouped by vertical and provider
    cart_id                    BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    customer_account_id        BIGINT NOT NULL,
    patient_profile_id         BIGINT NULL,
    address_id                 BIGINT NULL,
    coupon_code                VARCHAR(30) NULL,
    cart_status                VARCHAR(20) NOT NULL DEFAULT 'OPEN',            -- OPEN, CHECKED_OUT, ABANDONED
    expires_at                 TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: CHK-001, SLT-005
CREATE TABLE IF NOT EXISTS patientengagement.ecom_cart_item (                 -- Cart lines with held slot
    cart_item_id               BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    cart_id                    BIGINT NOT NULL,
    listing_id                 BIGINT NOT NULL,
    patient_profile_id         BIGINT NULL,
    quantity                   DECIMAL(10,2) NOT NULL DEFAULT 1,
    unit_price                 DECIMAL(12,2) NOT NULL,
    offer_price                DECIMAL(12,2) NULL,
    capacity_window_id         BIGINT NULL,
    slot_held_until            TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: ORX-005, TRX-004, TMD-001..005
CREATE TABLE IF NOT EXISTS patientengagement.ecom_order_episode (             -- Linked-order episode / WP session (consult -> medicines, home collection, scan) until all linked orders close
    order_episode_id           BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    episode_no                 VARCHAR(30) NOT NULL UNIQUE,
    customer_account_id        BIGINT NOT NULL,
    root_order_id              BIGINT NULL,
    opened_at                  TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at                  TIMESTAMPTZ(0) NULL,
    episode_status             VARCHAR(20) NOT NULL DEFAULT 'OPEN',            -- OPEN, CLOSED
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: ORD-002, PLP-001, RLP-001
CREATE TABLE IF NOT EXISTS patientengagement.ecom_order_status_history (      -- Order timeline milestones with timestamps
    order_status_history_id    BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    online_order_id            BIGINT NOT NULL,
    order_status               VARCHAR(30) NOT NULL,
    status_at                  TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source                     VARCHAR(20) NULL,                               -- CUSTOMER, OPS, PARTNER, AGENT, LIMS, RIMS, PHARMACY, SYSTEM
    changed_by                 BIGINT NULL,
    remarks                    VARCHAR(500) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: PBK-003, RBK-003, MBK-002/003, MFF-002 (Prescription attachment entity)
CREATE TABLE IF NOT EXISTS patientengagement.ecom_prescription_attachment (   -- Prescription uploads / e-Rx linked to orders with pharmacist validation
    prescription_attachment_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    online_order_id            BIGINT NOT NULL,
    attachment_type            VARCHAR(10) NOT NULL,                           -- UPLOAD, ERX
    document_id                BIGINT NULL,                                    -- logical FK -> integrationcomms.core_document [Integration & Communications]
    prescription_id            BIGINT NULL,                                    -- logical FK -> clinicalcare.ord_prescription [Clinical Care]
    prescriber_name            VARCHAR(150) NULL,
    prescriber_reg_no          VARCHAR(50) NULL,
    prescription_date          DATE NULL,
    valid_until                DATE NULL,
    validated_by               BIGINT NULL,
    validated_at               TIMESTAMPTZ(0) NULL,
    validation_result          VARCHAR(20) NULL,                               -- PENDING, VALID, REJECTED
    rejection_reason           VARCHAR(30) NULL,                               -- ILLEGIBLE, EXPIRED, INCOMPLETE, NOT_MATCHING
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: ORD-005, PRP-003, PRP-009, RRP-002, MDL-007 (Report / document entity)
CREATE TABLE IF NOT EXISTS patientengagement.ecom_order_document (            -- Reports, prescriptions, invoices released against an order with version
    order_document_id          BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    online_order_id            BIGINT NOT NULL,
    document_type              VARCHAR(20) NOT NULL,                           -- LAB_REPORT, RAD_REPORT, PRESCRIPTION, INVOICE, RECEIPT, IMAGE_LINK
    version_no                 SMALLINT NOT NULL DEFAULT 1,
    document_id                BIGINT NULL,                                    -- logical FK -> integrationcomms.core_document [Integration & Communications]
    is_partial                 BOOLEAN NOT NULL DEFAULT FALSE,
    is_superseded              BOOLEAN NOT NULL DEFAULT FALSE,
    released_at                TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: REF-003
CREATE TABLE IF NOT EXISTS patientengagement.pat_referral_status_history (    -- Referral status history (created, sent, accepted, booked, seen, report returned, closed, declined)
    referral_status_history_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    referral_id                BIGINT NOT NULL,
    referral_status            VARCHAR(20) NOT NULL,
    status_at                  TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by                 BIGINT NULL,
    remarks                    VARCHAR(500) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] replica of operationssupply.fld_agent, owned by Operations & Supply Chain; used by: patientengagement.sch_capacity_window (agent capacity)
CREATE TABLE IF NOT EXISTS patientengagement.ref_capacity_agent (
    agent_id                   BIGINT PRIMARY KEY,
    organization_id            INT NULL,
    branch_id                  INT NULL,
    agent_code                 VARCHAR(30) NULL,
    employee_id                BIGINT NULL,
    provider_id                BIGINT NULL,                                    -- partner agent
    full_name                  VARCHAR(150) NULL,
    mobile                     VARCHAR(15) NULL,
    photo_uri                  VARCHAR(500) NULL,
    skills                     VARCHAR(100) NULL,                              -- PHLEBO, RIDER, PHARM, OPD_RIDER, DOCTOR
    authorised_provider_ids    VARCHAR(500) NULL,                              -- e-Phlebo / e-Rayd partner authorisation
    service_zone_ids           VARCHAR(500) NULL,                              -- patientengagement.mkt_service_zone
    vehicle_id                 INT NULL,
    has_cold_box               BOOLEAN NULL,
    user_device_id             INT NULL,
    duty_status                VARCHAR(20) NULL,                               -- ON_DUTY, OFF_DUTY, ON_TASK, ON_BREAK
    last_latitude              DECIMAL(9,6) NULL,
    last_longitude             DECIMAL(9,6) NULL,
    last_location_at           TIMESTAMPTZ(0) NULL,
    cash_in_hand               DECIMAL(12,2) NULL,
    agent_status               VARCHAR(20) NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    source_version             BIGINT NULL,                                    -- version / sequence from publisher (ignore stale events)
    replicated_at              TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);


/* ---------- C. FOREIGN KEYS (same service only) ---------- */
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_pat_patient_address_patient_id') THEN
        ALTER TABLE patientengagement.pat_patient_address ADD CONSTRAINT fk_pat_patient_address_patient_id FOREIGN KEY (patient_id) REFERENCES patientengagement.pat_patient(patient_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_pat_patient_merge_surviving_patient_id') THEN
        ALTER TABLE patientengagement.pat_patient_merge ADD CONSTRAINT fk_pat_patient_merge_surviving_patient_id FOREIGN KEY (surviving_patient_id) REFERENCES patientengagement.pat_patient(patient_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_pat_patient_merge_merged_patient_id') THEN
        ALTER TABLE patientengagement.pat_patient_merge ADD CONSTRAINT fk_pat_patient_merge_merged_patient_id FOREIGN KEY (merged_patient_id) REFERENCES patientengagement.pat_patient(patient_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_pat_demographic_change_log_patient_id') THEN
        ALTER TABLE patientengagement.pat_demographic_change_log ADD CONSTRAINT fk_pat_demographic_change_log_patient_id FOREIGN KEY (patient_id) REFERENCES patientengagement.pat_patient(patient_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_pat_family_group_head_patient_id') THEN
        ALTER TABLE patientengagement.pat_family_group ADD CONSTRAINT fk_pat_family_group_head_patient_id FOREIGN KEY (head_patient_id) REFERENCES patientengagement.pat_patient(patient_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_pat_corporate_tag_patient_id') THEN
        ALTER TABLE patientengagement.pat_corporate_tag ADD CONSTRAINT fk_pat_corporate_tag_patient_id FOREIGN KEY (patient_id) REFERENCES patientengagement.pat_patient(patient_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_pat_corporate_tag_primary_employee_patient_id') THEN
        ALTER TABLE patientengagement.pat_corporate_tag ADD CONSTRAINT fk_pat_corporate_tag_primary_employee_patient_id FOREIGN KEY (primary_employee_patient_id) REFERENCES patientengagement.pat_patient(patient_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_pat_scheme_beneficiary_patient_id') THEN
        ALTER TABLE patientengagement.pat_scheme_beneficiary ADD CONSTRAINT fk_pat_scheme_beneficiary_patient_id FOREIGN KEY (patient_id) REFERENCES patientengagement.pat_patient(patient_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_pat_communication_preference_patient_id') THEN
        ALTER TABLE patientengagement.pat_communication_preference ADD CONSTRAINT fk_pat_communication_preference_patient_id FOREIGN KEY (patient_id) REFERENCES patientengagement.pat_patient(patient_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_pat_communication_preference_customer_account_id') THEN
        ALTER TABLE patientengagement.pat_communication_preference ADD CONSTRAINT fk_pat_communication_preference_customer_account_id FOREIGN KEY (customer_account_id) REFERENCES patientengagement.ecom_customer_account(customer_account_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_crm_call_log_patient_id') THEN
        ALTER TABLE patientengagement.crm_call_log ADD CONSTRAINT fk_crm_call_log_patient_id FOREIGN KEY (patient_id) REFERENCES patientengagement.pat_patient(patient_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_crm_call_log_enquiry_id') THEN
        ALTER TABLE patientengagement.crm_call_log ADD CONSTRAINT fk_crm_call_log_enquiry_id FOREIGN KEY (enquiry_id) REFERENCES patientengagement.crm_enquiry(enquiry_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_crm_call_log_appointment_id') THEN
        ALTER TABLE patientengagement.crm_call_log ADD CONSTRAINT fk_crm_call_log_appointment_id FOREIGN KEY (appointment_id) REFERENCES patientengagement.sch_appointment(appointment_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_crm_call_log_online_order_id') THEN
        ALTER TABLE patientengagement.crm_call_log ADD CONSTRAINT fk_crm_call_log_online_order_id FOREIGN KEY (online_order_id) REFERENCES patientengagement.ecom_online_order(online_order_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_pat_report_dispatch_patient_id') THEN
        ALTER TABLE patientengagement.pat_report_dispatch ADD CONSTRAINT fk_pat_report_dispatch_patient_id FOREIGN KEY (patient_id) REFERENCES patientengagement.pat_patient(patient_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_pat_report_dispatch_dispatch_batch_id') THEN
        ALTER TABLE patientengagement.pat_report_dispatch ADD CONSTRAINT fk_pat_report_dispatch_dispatch_batch_id FOREIGN KEY (dispatch_batch_id) REFERENCES patientengagement.pat_report_dispatch_batch(report_dispatch_batch_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_schedule_visit_type_practitioner_schedule_id') THEN
        ALTER TABLE patientengagement.sch_schedule_visit_type ADD CONSTRAINT fk_sch_schedule_visit_type_practitioner_schedule_id FOREIGN KEY (practitioner_schedule_id) REFERENCES patientengagement.sch_practitioner_schedule(practitioner_schedule_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_channel_quota_practitioner_schedule_id') THEN
        ALTER TABLE patientengagement.sch_channel_quota ADD CONSTRAINT fk_sch_channel_quota_practitioner_schedule_id FOREIGN KEY (practitioner_schedule_id) REFERENCES patientengagement.sch_practitioner_schedule(practitioner_schedule_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_channel_quota_resource_schedule_id') THEN
        ALTER TABLE patientengagement.sch_channel_quota ADD CONSTRAINT fk_sch_channel_quota_resource_schedule_id FOREIGN KEY (resource_schedule_id) REFERENCES patientengagement.sch_resource_schedule(resource_schedule_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_schedule_change_request_practitioner_schedule_id') THEN
        ALTER TABLE patientengagement.sch_schedule_change_request ADD CONSTRAINT fk_sch_schedule_change_request_practitioner_schedule_id FOREIGN KEY (practitioner_schedule_id) REFERENCES patientengagement.sch_practitioner_schedule(practitioner_schedule_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_capacity_window_resource_schedule_id') THEN
        ALTER TABLE patientengagement.sch_capacity_window ADD CONSTRAINT fk_sch_capacity_window_resource_schedule_id FOREIGN KEY (resource_schedule_id) REFERENCES patientengagement.sch_resource_schedule(resource_schedule_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_waitlist_patient_id') THEN
        ALTER TABLE patientengagement.sch_waitlist ADD CONSTRAINT fk_sch_waitlist_patient_id FOREIGN KEY (patient_id) REFERENCES patientengagement.pat_patient(patient_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_waitlist_offered_slot_id') THEN
        ALTER TABLE patientengagement.sch_waitlist ADD CONSTRAINT fk_sch_waitlist_offered_slot_id FOREIGN KEY (offered_slot_id) REFERENCES patientengagement.sch_slot(slot_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_waitlist_appointment_id') THEN
        ALTER TABLE patientengagement.sch_waitlist ADD CONSTRAINT fk_sch_waitlist_appointment_id FOREIGN KEY (appointment_id) REFERENCES patientengagement.sch_appointment(appointment_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_queue_token_event_queue_token_id') THEN
        ALTER TABLE patientengagement.sch_queue_token_event ADD CONSTRAINT fk_sch_queue_token_event_queue_token_id FOREIGN KEY (queue_token_id) REFERENCES patientengagement.sch_queue_token(queue_token_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_queue_token_event_from_room_id') THEN
        ALTER TABLE patientengagement.sch_queue_token_event ADD CONSTRAINT fk_sch_queue_token_event_from_room_id FOREIGN KEY (from_room_id) REFERENCES patientengagement.sch_consult_room(consult_room_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_queue_token_event_to_room_id') THEN
        ALTER TABLE patientengagement.sch_queue_token_event ADD CONSTRAINT fk_sch_queue_token_event_to_room_id FOREIGN KEY (to_room_id) REFERENCES patientengagement.sch_consult_room(consult_room_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_ondemand_request_patient_id') THEN
        ALTER TABLE patientengagement.sch_ondemand_request ADD CONSTRAINT fk_sch_ondemand_request_patient_id FOREIGN KEY (patient_id) REFERENCES patientengagement.pat_patient(patient_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_ondemand_request_appointment_id') THEN
        ALTER TABLE patientengagement.sch_ondemand_request ADD CONSTRAINT fk_sch_ondemand_request_appointment_id FOREIGN KEY (appointment_id) REFERENCES patientengagement.sch_appointment(appointment_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_ondemand_request_tele_session_id') THEN
        ALTER TABLE patientengagement.sch_ondemand_request ADD CONSTRAINT fk_sch_ondemand_request_tele_session_id FOREIGN KEY (tele_session_id) REFERENCES patientengagement.tele_session(tele_session_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_pat_questionnaire_response_questionnaire_id') THEN
        ALTER TABLE patientengagement.pat_questionnaire_response ADD CONSTRAINT fk_pat_questionnaire_response_questionnaire_id FOREIGN KEY (questionnaire_id) REFERENCES patientengagement.mkt_questionnaire(questionnaire_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_pat_questionnaire_response_patient_id') THEN
        ALTER TABLE patientengagement.pat_questionnaire_response ADD CONSTRAINT fk_pat_questionnaire_response_patient_id FOREIGN KEY (patient_id) REFERENCES patientengagement.pat_patient(patient_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_pat_questionnaire_response_appointment_id') THEN
        ALTER TABLE patientengagement.pat_questionnaire_response ADD CONSTRAINT fk_pat_questionnaire_response_appointment_id FOREIGN KEY (appointment_id) REFERENCES patientengagement.sch_appointment(appointment_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_pat_questionnaire_response_online_order_id') THEN
        ALTER TABLE patientengagement.pat_questionnaire_response ADD CONSTRAINT fk_pat_questionnaire_response_online_order_id FOREIGN KEY (online_order_id) REFERENCES patientengagement.ecom_online_order(online_order_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_pat_questionnaire_response_question_id') THEN
        ALTER TABLE patientengagement.pat_questionnaire_response ADD CONSTRAINT fk_pat_questionnaire_response_question_id FOREIGN KEY (question_id) REFERENCES patientengagement.mkt_questionnaire_question(questionnaire_question_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_customer_consent_customer_account_id') THEN
        ALTER TABLE patientengagement.ecom_customer_consent ADD CONSTRAINT fk_ecom_customer_consent_customer_account_id FOREIGN KEY (customer_account_id) REFERENCES patientengagement.ecom_customer_account(customer_account_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_patient_profile_customer_account_id') THEN
        ALTER TABLE patientengagement.ecom_patient_profile ADD CONSTRAINT fk_ecom_patient_profile_customer_account_id FOREIGN KEY (customer_account_id) REFERENCES patientengagement.ecom_customer_account(customer_account_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_patient_profile_patient_id') THEN
        ALTER TABLE patientengagement.ecom_patient_profile ADD CONSTRAINT fk_ecom_patient_profile_patient_id FOREIGN KEY (patient_id) REFERENCES patientengagement.pat_patient(patient_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_patient_profile_guardian_profile_id') THEN
        ALTER TABLE patientengagement.ecom_patient_profile ADD CONSTRAINT fk_ecom_patient_profile_guardian_profile_id FOREIGN KEY (guardian_profile_id) REFERENCES patientengagement.ecom_patient_profile(patient_profile_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_customer_address_customer_account_id') THEN
        ALTER TABLE patientengagement.ecom_customer_address ADD CONSTRAINT fk_ecom_customer_address_customer_account_id FOREIGN KEY (customer_account_id) REFERENCES patientengagement.ecom_customer_account(customer_account_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_mkt_provider_commission_plan_id') THEN
        ALTER TABLE patientengagement.mkt_provider ADD CONSTRAINT fk_mkt_provider_commission_plan_id FOREIGN KEY (commission_plan_id) REFERENCES patientengagement.mkt_commission_plan(commission_plan_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_mkt_provider_location_provider_id') THEN
        ALTER TABLE patientengagement.mkt_provider_location ADD CONSTRAINT fk_mkt_provider_location_provider_id FOREIGN KEY (provider_id) REFERENCES patientengagement.mkt_provider(provider_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_mkt_provider_document_provider_id') THEN
        ALTER TABLE patientengagement.mkt_provider_document ADD CONSTRAINT fk_mkt_provider_document_provider_id FOREIGN KEY (provider_id) REFERENCES patientengagement.mkt_provider(provider_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_mkt_listing_provider_id') THEN
        ALTER TABLE patientengagement.mkt_listing ADD CONSTRAINT fk_mkt_listing_provider_id FOREIGN KEY (provider_id) REFERENCES patientengagement.mkt_provider(provider_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_mkt_listing_catalogue_item_id') THEN
        ALTER TABLE patientengagement.mkt_listing ADD CONSTRAINT fk_mkt_listing_catalogue_item_id FOREIGN KEY (catalogue_item_id) REFERENCES patientengagement.mkt_catalogue_item(catalogue_item_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_mkt_service_zone_provider_id') THEN
        ALTER TABLE patientengagement.mkt_service_zone ADD CONSTRAINT fk_mkt_service_zone_provider_id FOREIGN KEY (provider_id) REFERENCES patientengagement.mkt_provider(provider_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_mkt_questionnaire_question_questionnaire_id') THEN
        ALTER TABLE patientengagement.mkt_questionnaire_question ADD CONSTRAINT fk_mkt_questionnaire_question_questionnaire_id FOREIGN KEY (questionnaire_id) REFERENCES patientengagement.mkt_questionnaire(questionnaire_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_mkt_channel_listing_map_channel_partner_id') THEN
        ALTER TABLE patientengagement.mkt_channel_listing_map ADD CONSTRAINT fk_mkt_channel_listing_map_channel_partner_id FOREIGN KEY (channel_partner_id) REFERENCES patientengagement.mkt_channel_partner(channel_partner_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_mkt_channel_listing_map_listing_id') THEN
        ALTER TABLE patientengagement.mkt_channel_listing_map ADD CONSTRAINT fk_mkt_channel_listing_map_listing_id FOREIGN KEY (listing_id) REFERENCES patientengagement.mkt_listing(listing_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_mkt_partner_settlement_provider_id') THEN
        ALTER TABLE patientengagement.mkt_partner_settlement ADD CONSTRAINT fk_mkt_partner_settlement_provider_id FOREIGN KEY (provider_id) REFERENCES patientengagement.mkt_provider(provider_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_mkt_partner_settlement_line_partner_settlement_id') THEN
        ALTER TABLE patientengagement.mkt_partner_settlement_line ADD CONSTRAINT fk_mkt_partner_settlement_line_partner_settlement_id FOREIGN KEY (partner_settlement_id) REFERENCES patientengagement.mkt_partner_settlement(partner_settlement_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_mkt_partner_settlement_line_online_order_id') THEN
        ALTER TABLE patientengagement.mkt_partner_settlement_line ADD CONSTRAINT fk_mkt_partner_settlement_line_online_order_id FOREIGN KEY (online_order_id) REFERENCES patientengagement.ecom_online_order(online_order_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_rating_review_online_order_id') THEN
        ALTER TABLE patientengagement.ecom_rating_review ADD CONSTRAINT fk_ecom_rating_review_online_order_id FOREIGN KEY (online_order_id) REFERENCES patientengagement.ecom_online_order(online_order_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_rating_review_appointment_id') THEN
        ALTER TABLE patientengagement.ecom_rating_review ADD CONSTRAINT fk_ecom_rating_review_appointment_id FOREIGN KEY (appointment_id) REFERENCES patientengagement.sch_appointment(appointment_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_rating_review_customer_account_id') THEN
        ALTER TABLE patientengagement.ecom_rating_review ADD CONSTRAINT fk_ecom_rating_review_customer_account_id FOREIGN KEY (customer_account_id) REFERENCES patientengagement.ecom_customer_account(customer_account_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_cart_customer_account_id') THEN
        ALTER TABLE patientengagement.ecom_cart ADD CONSTRAINT fk_ecom_cart_customer_account_id FOREIGN KEY (customer_account_id) REFERENCES patientengagement.ecom_customer_account(customer_account_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_cart_patient_profile_id') THEN
        ALTER TABLE patientengagement.ecom_cart ADD CONSTRAINT fk_ecom_cart_patient_profile_id FOREIGN KEY (patient_profile_id) REFERENCES patientengagement.ecom_patient_profile(patient_profile_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_cart_address_id') THEN
        ALTER TABLE patientengagement.ecom_cart ADD CONSTRAINT fk_ecom_cart_address_id FOREIGN KEY (address_id) REFERENCES patientengagement.ecom_customer_address(customer_address_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_cart_item_cart_id') THEN
        ALTER TABLE patientengagement.ecom_cart_item ADD CONSTRAINT fk_ecom_cart_item_cart_id FOREIGN KEY (cart_id) REFERENCES patientengagement.ecom_cart(cart_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_cart_item_listing_id') THEN
        ALTER TABLE patientengagement.ecom_cart_item ADD CONSTRAINT fk_ecom_cart_item_listing_id FOREIGN KEY (listing_id) REFERENCES patientengagement.mkt_listing(listing_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_cart_item_patient_profile_id') THEN
        ALTER TABLE patientengagement.ecom_cart_item ADD CONSTRAINT fk_ecom_cart_item_patient_profile_id FOREIGN KEY (patient_profile_id) REFERENCES patientengagement.ecom_patient_profile(patient_profile_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_cart_item_capacity_window_id') THEN
        ALTER TABLE patientengagement.ecom_cart_item ADD CONSTRAINT fk_ecom_cart_item_capacity_window_id FOREIGN KEY (capacity_window_id) REFERENCES patientengagement.sch_capacity_window(capacity_window_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_order_episode_customer_account_id') THEN
        ALTER TABLE patientengagement.ecom_order_episode ADD CONSTRAINT fk_ecom_order_episode_customer_account_id FOREIGN KEY (customer_account_id) REFERENCES patientengagement.ecom_customer_account(customer_account_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_order_status_history_online_order_id') THEN
        ALTER TABLE patientengagement.ecom_order_status_history ADD CONSTRAINT fk_ecom_order_status_history_online_order_id FOREIGN KEY (online_order_id) REFERENCES patientengagement.ecom_online_order(online_order_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_prescription_attachment_online_order_id') THEN
        ALTER TABLE patientengagement.ecom_prescription_attachment ADD CONSTRAINT fk_ecom_prescription_attachment_online_order_id FOREIGN KEY (online_order_id) REFERENCES patientengagement.ecom_online_order(online_order_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_order_document_online_order_id') THEN
        ALTER TABLE patientengagement.ecom_order_document ADD CONSTRAINT fk_ecom_order_document_online_order_id FOREIGN KEY (online_order_id) REFERENCES patientengagement.ecom_online_order(online_order_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_pat_referral_status_history_referral_id') THEN
        ALTER TABLE patientengagement.pat_referral_status_history ADD CONSTRAINT fk_pat_referral_status_history_referral_id FOREIGN KEY (referral_id) REFERENCES patientengagement.pat_referral(referral_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_crm_enquiry_patient_id') THEN
        ALTER TABLE patientengagement.crm_enquiry ADD CONSTRAINT fk_crm_enquiry_patient_id FOREIGN KEY (patient_id) REFERENCES patientengagement.pat_patient(patient_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_crm_enquiry_patient_id ON patientengagement.crm_enquiry(patient_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_crm_enquiry_converted_appointment_id') THEN
        ALTER TABLE patientengagement.crm_enquiry ADD CONSTRAINT fk_crm_enquiry_converted_appointment_id FOREIGN KEY (converted_appointment_id) REFERENCES patientengagement.sch_appointment(appointment_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_crm_enquiry_converted_appointment_id ON patientengagement.crm_enquiry(converted_appointment_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_online_order_customer_account_id') THEN
        ALTER TABLE patientengagement.ecom_online_order ADD CONSTRAINT fk_ecom_online_order_customer_account_id FOREIGN KEY (customer_account_id) REFERENCES patientengagement.ecom_customer_account(customer_account_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_ecom_online_order_customer_account_id ON patientengagement.ecom_online_order(customer_account_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_online_order_patient_profile_id') THEN
        ALTER TABLE patientengagement.ecom_online_order ADD CONSTRAINT fk_ecom_online_order_patient_profile_id FOREIGN KEY (patient_profile_id) REFERENCES patientengagement.ecom_patient_profile(patient_profile_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_ecom_online_order_patient_profile_id ON patientengagement.ecom_online_order(patient_profile_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_online_order_provider_id') THEN
        ALTER TABLE patientengagement.ecom_online_order ADD CONSTRAINT fk_ecom_online_order_provider_id FOREIGN KEY (provider_id) REFERENCES patientengagement.mkt_provider(provider_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_ecom_online_order_provider_id ON patientengagement.ecom_online_order(provider_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_online_order_channel_partner_id') THEN
        ALTER TABLE patientengagement.ecom_online_order ADD CONSTRAINT fk_ecom_online_order_channel_partner_id FOREIGN KEY (channel_partner_id) REFERENCES patientengagement.mkt_channel_partner(channel_partner_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_ecom_online_order_channel_partner_id ON patientengagement.ecom_online_order(channel_partner_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_online_order_address_id') THEN
        ALTER TABLE patientengagement.ecom_online_order ADD CONSTRAINT fk_ecom_online_order_address_id FOREIGN KEY (address_id) REFERENCES patientengagement.ecom_customer_address(customer_address_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_ecom_online_order_address_id ON patientengagement.ecom_online_order(address_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_online_order_capacity_window_id') THEN
        ALTER TABLE patientengagement.ecom_online_order ADD CONSTRAINT fk_ecom_online_order_capacity_window_id FOREIGN KEY (capacity_window_id) REFERENCES patientengagement.sch_capacity_window(capacity_window_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_ecom_online_order_capacity_window_id ON patientengagement.ecom_online_order(capacity_window_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_online_order_order_episode_id') THEN
        ALTER TABLE patientengagement.ecom_online_order ADD CONSTRAINT fk_ecom_online_order_order_episode_id FOREIGN KEY (order_episode_id) REFERENCES patientengagement.ecom_order_episode(order_episode_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_ecom_online_order_order_episode_id ON patientengagement.ecom_online_order(order_episode_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_online_order_parent_order_id') THEN
        ALTER TABLE patientengagement.ecom_online_order ADD CONSTRAINT fk_ecom_online_order_parent_order_id FOREIGN KEY (parent_order_id) REFERENCES patientengagement.ecom_online_order(online_order_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_ecom_online_order_parent_order_id ON patientengagement.ecom_online_order(parent_order_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_online_order_appointment_id') THEN
        ALTER TABLE patientengagement.ecom_online_order ADD CONSTRAINT fk_ecom_online_order_appointment_id FOREIGN KEY (appointment_id) REFERENCES patientengagement.sch_appointment(appointment_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_ecom_online_order_appointment_id ON patientengagement.ecom_online_order(appointment_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_online_order_encounter_id') THEN
        ALTER TABLE patientengagement.ecom_online_order ADD CONSTRAINT fk_ecom_online_order_encounter_id FOREIGN KEY (encounter_id) REFERENCES patientengagement.pat_encounter(encounter_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_ecom_online_order_encounter_id ON patientengagement.ecom_online_order(encounter_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_online_order_item_listing_id') THEN
        ALTER TABLE patientengagement.ecom_online_order_item ADD CONSTRAINT fk_ecom_online_order_item_listing_id FOREIGN KEY (listing_id) REFERENCES patientengagement.mkt_listing(listing_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_ecom_online_order_item_listing_id ON patientengagement.ecom_online_order_item(listing_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_ecom_online_order_item_patient_profile_id') THEN
        ALTER TABLE patientengagement.ecom_online_order_item ADD CONSTRAINT fk_ecom_online_order_item_patient_profile_id FOREIGN KEY (patient_profile_id) REFERENCES patientengagement.ecom_patient_profile(patient_profile_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_ecom_online_order_item_patient_profile_id ON patientengagement.ecom_online_order_item(patient_profile_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_pat_patient_guardian_patient_id') THEN
        ALTER TABLE patientengagement.pat_patient ADD CONSTRAINT fk_pat_patient_guardian_patient_id FOREIGN KEY (guardian_patient_id) REFERENCES patientengagement.pat_patient(patient_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_pat_patient_guardian_patient_id ON patientengagement.pat_patient(guardian_patient_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_pat_patient_relation_family_group_id') THEN
        ALTER TABLE patientengagement.pat_patient_relation ADD CONSTRAINT fk_pat_patient_relation_family_group_id FOREIGN KEY (family_group_id) REFERENCES patientengagement.pat_family_group(family_group_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_pat_patient_relation_family_group_id ON patientengagement.pat_patient_relation(family_group_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_pat_referral_appointment_id') THEN
        ALTER TABLE patientengagement.pat_referral ADD CONSTRAINT fk_pat_referral_appointment_id FOREIGN KEY (appointment_id) REFERENCES patientengagement.sch_appointment(appointment_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_pat_referral_appointment_id ON patientengagement.pat_referral(appointment_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_appointment_waitlist_id') THEN
        ALTER TABLE patientengagement.sch_appointment ADD CONSTRAINT fk_sch_appointment_waitlist_id FOREIGN KEY (waitlist_id) REFERENCES patientengagement.sch_waitlist(waitlist_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_sch_appointment_waitlist_id ON patientengagement.sch_appointment(waitlist_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_appointment_followup_of_appointment_id') THEN
        ALTER TABLE patientengagement.sch_appointment ADD CONSTRAINT fk_sch_appointment_followup_of_appointment_id FOREIGN KEY (followup_of_appointment_id) REFERENCES patientengagement.sch_appointment(appointment_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_sch_appointment_followup_of_appointment_id ON patientengagement.sch_appointment(followup_of_appointment_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_appointment_online_order_id') THEN
        ALTER TABLE patientengagement.sch_appointment ADD CONSTRAINT fk_sch_appointment_online_order_id FOREIGN KEY (online_order_id) REFERENCES patientengagement.ecom_online_order(online_order_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_sch_appointment_online_order_id ON patientengagement.sch_appointment(online_order_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_appointment_tele_consent_id') THEN
        ALTER TABLE patientengagement.sch_appointment ADD CONSTRAINT fk_sch_appointment_tele_consent_id FOREIGN KEY (tele_consent_id) REFERENCES patientengagement.pat_consent(consent_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_sch_appointment_tele_consent_id ON patientengagement.sch_appointment(tele_consent_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_schedule_exception_consult_room_id') THEN
        ALTER TABLE patientengagement.sch_schedule_exception ADD CONSTRAINT fk_sch_schedule_exception_consult_room_id FOREIGN KEY (consult_room_id) REFERENCES patientengagement.sch_consult_room(consult_room_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_sch_schedule_exception_consult_room_id ON patientengagement.sch_schedule_exception(consult_room_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_schedule_exception_practitioner_schedule_id') THEN
        ALTER TABLE patientengagement.sch_schedule_exception ADD CONSTRAINT fk_sch_schedule_exception_practitioner_schedule_id FOREIGN KEY (practitioner_schedule_id) REFERENCES patientengagement.sch_practitioner_schedule(practitioner_schedule_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_sch_schedule_exception_practitioner_schedule_id ON patientengagement.sch_schedule_exception(practitioner_schedule_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_schedule_exception_schedule_change_request_id') THEN
        ALTER TABLE patientengagement.sch_schedule_exception ADD CONSTRAINT fk_sch_schedule_exception_schedule_change_request_id FOREIGN KEY (schedule_change_request_id) REFERENCES patientengagement.sch_schedule_change_request(schedule_change_request_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_sch_schedule_exception_schedule_change_request_id ON patientengagement.sch_schedule_exception(schedule_change_request_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_sch_slot_capacity_window_id') THEN
        ALTER TABLE patientengagement.sch_slot ADD CONSTRAINT fk_sch_slot_capacity_window_id FOREIGN KEY (capacity_window_id) REFERENCES patientengagement.sch_capacity_window(capacity_window_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_sch_slot_capacity_window_id ON patientengagement.sch_slot(capacity_window_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_tele_session_consent_id') THEN
        ALTER TABLE patientengagement.tele_session ADD CONSTRAINT fk_tele_session_consent_id FOREIGN KEY (consent_id) REFERENCES patientengagement.pat_consent(consent_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_tele_session_consent_id ON patientengagement.tele_session(consent_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'patientengagement' AND c.conname = 'fk_tele_session_online_order_id') THEN
        ALTER TABLE patientengagement.tele_session ADD CONSTRAINT fk_tele_session_online_order_id FOREIGN KEY (online_order_id) REFERENCES patientengagement.ecom_online_order(online_order_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_tele_session_online_order_id ON patientengagement.tele_session(online_order_id);

/* ---------- D. INDEXES ---------- */
CREATE INDEX IF NOT EXISTS ix_pat_patient_address_patient_id ON patientengagement.pat_patient_address(patient_id);
CREATE INDEX IF NOT EXISTS ix_pat_patient_merge_surviving_patient_id ON patientengagement.pat_patient_merge(surviving_patient_id);
CREATE INDEX IF NOT EXISTS ix_pat_patient_merge_merged_patient_id ON patientengagement.pat_patient_merge(merged_patient_id);
CREATE INDEX IF NOT EXISTS ix_pat_demographic_change_log_patient_id ON patientengagement.pat_demographic_change_log(patient_id);
CREATE INDEX IF NOT EXISTS ix_pat_family_group_head_patient_id ON patientengagement.pat_family_group(head_patient_id);
CREATE INDEX IF NOT EXISTS ix_pat_corporate_tag_patient_id ON patientengagement.pat_corporate_tag(patient_id);
CREATE INDEX IF NOT EXISTS ix_pat_corporate_tag_primary_employee_patient_id ON patientengagement.pat_corporate_tag(primary_employee_patient_id);
CREATE INDEX IF NOT EXISTS ix_pat_scheme_beneficiary_patient_id ON patientengagement.pat_scheme_beneficiary(patient_id);
CREATE INDEX IF NOT EXISTS ix_pat_communication_preference_patient_id ON patientengagement.pat_communication_preference(patient_id);
CREATE INDEX IF NOT EXISTS ix_pat_communication_preference_customer_account_id ON patientengagement.pat_communication_preference(customer_account_id);
CREATE INDEX IF NOT EXISTS ix_crm_call_log_patient_id ON patientengagement.crm_call_log(patient_id);
CREATE INDEX IF NOT EXISTS ix_crm_call_log_enquiry_id ON patientengagement.crm_call_log(enquiry_id);
CREATE INDEX IF NOT EXISTS ix_crm_call_log_appointment_id ON patientengagement.crm_call_log(appointment_id);
CREATE INDEX IF NOT EXISTS ix_crm_call_log_online_order_id ON patientengagement.crm_call_log(online_order_id);
CREATE INDEX IF NOT EXISTS ix_pat_report_dispatch_patient_id ON patientengagement.pat_report_dispatch(patient_id);
CREATE INDEX IF NOT EXISTS ix_pat_report_dispatch_dispatch_batch_id ON patientengagement.pat_report_dispatch(dispatch_batch_id);
CREATE INDEX IF NOT EXISTS ix_sch_schedule_visit_type_practitioner_schedule_id ON patientengagement.sch_schedule_visit_type(practitioner_schedule_id);
CREATE INDEX IF NOT EXISTS ix_sch_channel_quota_practitioner_schedule_id ON patientengagement.sch_channel_quota(practitioner_schedule_id);
CREATE INDEX IF NOT EXISTS ix_sch_channel_quota_resource_schedule_id ON patientengagement.sch_channel_quota(resource_schedule_id);
CREATE INDEX IF NOT EXISTS ix_sch_schedule_change_request_practitioner_schedule_id ON patientengagement.sch_schedule_change_request(practitioner_schedule_id);
CREATE INDEX IF NOT EXISTS ix_sch_capacity_window_resource_schedule_id ON patientengagement.sch_capacity_window(resource_schedule_id);
CREATE INDEX IF NOT EXISTS ix_sch_waitlist_patient_id ON patientengagement.sch_waitlist(patient_id);
CREATE INDEX IF NOT EXISTS ix_sch_waitlist_offered_slot_id ON patientengagement.sch_waitlist(offered_slot_id);
CREATE INDEX IF NOT EXISTS ix_sch_waitlist_appointment_id ON patientengagement.sch_waitlist(appointment_id);
CREATE INDEX IF NOT EXISTS ix_sch_queue_token_event_queue_token_id ON patientengagement.sch_queue_token_event(queue_token_id);
CREATE INDEX IF NOT EXISTS ix_sch_queue_token_event_from_room_id ON patientengagement.sch_queue_token_event(from_room_id);
CREATE INDEX IF NOT EXISTS ix_sch_queue_token_event_to_room_id ON patientengagement.sch_queue_token_event(to_room_id);
CREATE INDEX IF NOT EXISTS ix_sch_ondemand_request_patient_id ON patientengagement.sch_ondemand_request(patient_id);
CREATE INDEX IF NOT EXISTS ix_sch_ondemand_request_appointment_id ON patientengagement.sch_ondemand_request(appointment_id);
CREATE INDEX IF NOT EXISTS ix_sch_ondemand_request_tele_session_id ON patientengagement.sch_ondemand_request(tele_session_id);
CREATE INDEX IF NOT EXISTS ix_pat_questionnaire_response_questionnaire_id ON patientengagement.pat_questionnaire_response(questionnaire_id);
CREATE INDEX IF NOT EXISTS ix_pat_questionnaire_response_patient_id ON patientengagement.pat_questionnaire_response(patient_id);
CREATE INDEX IF NOT EXISTS ix_pat_questionnaire_response_appointment_id ON patientengagement.pat_questionnaire_response(appointment_id);
CREATE INDEX IF NOT EXISTS ix_pat_questionnaire_response_online_order_id ON patientengagement.pat_questionnaire_response(online_order_id);
CREATE INDEX IF NOT EXISTS ix_pat_questionnaire_response_question_id ON patientengagement.pat_questionnaire_response(question_id);
CREATE INDEX IF NOT EXISTS ix_ecom_customer_consent_customer_account_id ON patientengagement.ecom_customer_consent(customer_account_id);
CREATE INDEX IF NOT EXISTS ix_ecom_patient_profile_customer_account_id ON patientengagement.ecom_patient_profile(customer_account_id);
CREATE INDEX IF NOT EXISTS ix_ecom_patient_profile_patient_id ON patientengagement.ecom_patient_profile(patient_id);
CREATE INDEX IF NOT EXISTS ix_ecom_patient_profile_guardian_profile_id ON patientengagement.ecom_patient_profile(guardian_profile_id);
CREATE INDEX IF NOT EXISTS ix_ecom_customer_address_customer_account_id ON patientengagement.ecom_customer_address(customer_account_id);
CREATE INDEX IF NOT EXISTS ix_mkt_provider_commission_plan_id ON patientengagement.mkt_provider(commission_plan_id);
CREATE INDEX IF NOT EXISTS ix_mkt_provider_location_provider_id ON patientengagement.mkt_provider_location(provider_id);
CREATE INDEX IF NOT EXISTS ix_mkt_provider_document_provider_id ON patientengagement.mkt_provider_document(provider_id);
CREATE INDEX IF NOT EXISTS ix_mkt_listing_catalogue_item_id ON patientengagement.mkt_listing(catalogue_item_id);
CREATE INDEX IF NOT EXISTS ix_mkt_service_zone_provider_id ON patientengagement.mkt_service_zone(provider_id);
CREATE INDEX IF NOT EXISTS ix_mkt_questionnaire_question_questionnaire_id ON patientengagement.mkt_questionnaire_question(questionnaire_id);
CREATE INDEX IF NOT EXISTS ix_mkt_channel_listing_map_channel_partner_id ON patientengagement.mkt_channel_listing_map(channel_partner_id);
CREATE INDEX IF NOT EXISTS ix_mkt_channel_listing_map_listing_id ON patientengagement.mkt_channel_listing_map(listing_id);
CREATE INDEX IF NOT EXISTS ix_mkt_partner_settlement_provider_id ON patientengagement.mkt_partner_settlement(provider_id);
CREATE INDEX IF NOT EXISTS ix_mkt_partner_settlement_line_partner_settlement_id ON patientengagement.mkt_partner_settlement_line(partner_settlement_id);
CREATE INDEX IF NOT EXISTS ix_mkt_partner_settlement_line_online_order_id ON patientengagement.mkt_partner_settlement_line(online_order_id);
CREATE INDEX IF NOT EXISTS ix_ecom_rating_review_online_order_id ON patientengagement.ecom_rating_review(online_order_id);
CREATE INDEX IF NOT EXISTS ix_ecom_rating_review_appointment_id ON patientengagement.ecom_rating_review(appointment_id);
CREATE INDEX IF NOT EXISTS ix_ecom_rating_review_customer_account_id ON patientengagement.ecom_rating_review(customer_account_id);
CREATE INDEX IF NOT EXISTS ix_ecom_cart_customer_account_id ON patientengagement.ecom_cart(customer_account_id);
CREATE INDEX IF NOT EXISTS ix_ecom_cart_patient_profile_id ON patientengagement.ecom_cart(patient_profile_id);
CREATE INDEX IF NOT EXISTS ix_ecom_cart_address_id ON patientengagement.ecom_cart(address_id);
CREATE INDEX IF NOT EXISTS ix_ecom_cart_item_cart_id ON patientengagement.ecom_cart_item(cart_id);
CREATE INDEX IF NOT EXISTS ix_ecom_cart_item_listing_id ON patientengagement.ecom_cart_item(listing_id);
CREATE INDEX IF NOT EXISTS ix_ecom_cart_item_patient_profile_id ON patientengagement.ecom_cart_item(patient_profile_id);
CREATE INDEX IF NOT EXISTS ix_ecom_cart_item_capacity_window_id ON patientengagement.ecom_cart_item(capacity_window_id);
CREATE INDEX IF NOT EXISTS ix_ecom_order_episode_customer_account_id ON patientengagement.ecom_order_episode(customer_account_id);
CREATE INDEX IF NOT EXISTS ix_ecom_order_status_history_online_order_id ON patientengagement.ecom_order_status_history(online_order_id);
CREATE INDEX IF NOT EXISTS ix_ecom_prescription_attachment_online_order_id ON patientengagement.ecom_prescription_attachment(online_order_id);
CREATE INDEX IF NOT EXISTS ix_ecom_order_document_online_order_id ON patientengagement.ecom_order_document(online_order_id);
CREATE INDEX IF NOT EXISTS ix_pat_referral_status_history_referral_id ON patientengagement.pat_referral_status_history(referral_id);

/* ---------- E. TABLE COMMENTS (FDS traceability) ---------- */
COMMENT ON TABLE patientengagement.pat_patient_address IS 'Current / permanent addresses per patient (master-driven PIN, city, district, state) [FDS: REG-DEM-004 (OPD 4.1 Address entity)]';
COMMENT ON TABLE patientengagement.pat_patient_merge IS 'UHID merge requests with maker-checker approval and full audit [FDS: REG-UHID-003, REG-UHID-004, STO-008 (PACS)]';
COMMENT ON TABLE patientengagement.pat_demographic_change_log IS 'Field-level audit of demographic changes (old / new value, user, time) [FDS: REG-DEM-009, REG-FAM-005]';
COMMENT ON TABLE patientengagement.pat_family_group IS 'Family group with head / guardian [FDS: REG-FAM-001..005 (Family group entity)]';
COMMENT ON TABLE patientengagement.pat_corporate_tag IS 'Patient tagged to corporate(s) with employee id, relationship, validity and authorisation [FDS: REG-CORP-002..005 (Corporate tag entity)]';
COMMENT ON TABLE patientengagement.pat_scheme_beneficiary IS 'Government scheme beneficiaries (PM-JAY / Ayushman Bharat, Aarogyasri, state schemes) [FDS: REG-INS-004, GOV-001..003 (Billing)]';
COMMENT ON TABLE patientengagement.pat_communication_preference IS 'Per patient / customer channel opt-ins, language and quiet hours [FDS: REM-PAT-005 (OPD), ACC-007/008 (Website)]';
COMMENT ON TABLE patientengagement.crm_call_log IS 'Call centre inbound / outbound call log with outcome [FDS: CC-001..004, OPS-009 (Website masked calling)]';
COMMENT ON TABLE patientengagement.pat_report_dispatch_batch IS 'Bulk dispatch / handover batch (e.g. corporate health-check) with consolidated acknowledgement [FDS: RPT-007]';
COMMENT ON TABLE patientengagement.pat_report_dispatch IS 'Report dispatch log for lab, radiology and other reports (counter, e-mail, portal, WhatsApp, courier) [FDS: RPT-001..011 (Report dispatch entity), LAB-RPT-012, RAD-RPT-010]';
COMMENT ON TABLE patientengagement.sch_schedule_visit_type IS 'Slot duration / capacity / fee per visit type within a schedule [FDS: DSC-CAL-002, BKG-003]';
COMMENT ON TABLE patientengagement.sch_channel_quota IS 'Channel-wise slot quotas (walk-in, call centre, portal, app, aggregator, B2B) [FDS: BKG-006, WLK-003, SLT-006 (Website)]';
COMMENT ON TABLE patientengagement.sch_schedule_change_request IS 'Doctor-requested schedule changes routed to scheduler for approval; bulk reschedule tracking [FDS: DSC-CAL-004, DSC-CNF-002, DSC-CAN-005]';
COMMENT ON TABLE patientengagement.sch_resource_schedule IS 'Generic capacity templates for non-doctor resources: modality, phlebo zone, rider zone, provider, pharmacy delivery, specialty session [FDS: SSC-CAL-003 (OPD), RAD-SCH-001 (RIMS), SLT-002/007/008/009 (Website)]';
COMMENT ON TABLE patientengagement.sch_capacity_window IS 'Materialised capacity per resource / date / window with channel allotments, holds and blocks [FDS: SLT-001..010 (Website Slot / capacity entity), SSC-CAL-001/002, SSC-REL-002]';
COMMENT ON TABLE patientengagement.sch_waitlist IS 'Waiting list for full sessions; cancelled slots offered to waiting patients [FDS: BKG-009, DSC-CAN-002]';
COMMENT ON TABLE patientengagement.sch_queue_token_event IS 'Every call / hold / release / skip / recall / room change of a token with user and reason [FDS: TKN-HRS-001..004, DSC-MUL-004]';
COMMENT ON TABLE patientengagement.sch_display_board IS 'Waiting-area display screens and audio announcement configuration [FDS: TKN-DSP-001..003]';
COMMENT ON TABLE patientengagement.sch_practitioner_availability IS 'Real-time doctor availability ("Available now" / delay / break) for on-demand consults [FDS: ODB-001, DSC-CNF-003, TSL-002, REM-DOC-004]';
COMMENT ON TABLE patientengagement.sch_ondemand_request IS 'Doctor-on-demand consultation requests, auto-assignment and accept / decline [FDS: ODB-002..005, TSL-002]';
COMMENT ON TABLE patientengagement.pat_questionnaire_response IS 'Pre-visit / safety / pre-collection questionnaire answers for appointments and online orders [FDS: TC-005, TBK-004 (tele pre-consult), PBK-005, RBK-004, OBK-004 (Website Safety / pre-visit answers entity), SUB-004 (EHR)]';
COMMENT ON TABLE patientengagement.ecom_customer_account IS 'Marketplace customer account (website / app login) separate from patient master [FDS: ACC-001..009 (Customer account entity)]';
COMMENT ON TABLE patientengagement.ecom_customer_consent IS 'Consents captured at sign-up / booking (terms, privacy, communication, tele, data sharing) [FDS: ACC-007, ACC-008, ACC-009]';
COMMENT ON TABLE patientengagement.ecom_patient_profile IS 'Patient profiles under a customer account (self / family) linked to UHID and ABHA [FDS: ACC-003..005 (Patient profile entity), PBK-006]';
COMMENT ON TABLE patientengagement.ecom_customer_address IS 'Address book with map pin and access instructions [FDS: ACC-006, LOC-001..008 (Address entity)]';
COMMENT ON TABLE patientengagement.mkt_provider IS 'Marketplace providers: internal centres, partner labs, hospitals, pharmacies, doctors [FDS: MKT-005/007, PWP-001..010 (Provider entity)]';
COMMENT ON TABLE patientengagement.mkt_provider_location IS 'Provider service locations, timings and holidays [FDS: PWP-003, MKT-007]';
COMMENT ON TABLE patientengagement.mkt_provider_document IS 'Provider licences / agreements with expiry (drug licence, NABL, registration) [FDS: PWP-001, VEN-002-like controls for partners]';
COMMENT ON TABLE patientengagement.mkt_commission_plan IS 'Partner commission / platform fee plans [FDS: CHK-008, PWP-008]';
COMMENT ON TABLE patientengagement.mkt_catalogue_item IS 'Platform catalogue (tests, packages, scans, medicines, consult types) with SEO content [FDS: MKT-002..004, MKT-009, MKT-013, MKT-014]';
COMMENT ON TABLE patientengagement.mkt_listing IS 'Provider offering of a catalogue item with price, offer price, TAT and approval [FDS: MKT-005, MKT-010, PWP-002 (Listing entity)]';
COMMENT ON TABLE patientengagement.mkt_service_zone IS 'Serviceability zones per provider / agent pool and service line (PIN list, radius, polygon) [FDS: LOC-003..005 (Service zone entity)]';
COMMENT ON TABLE patientengagement.mkt_questionnaire IS 'Configurable questionnaires (pre-collection, modality safety, tele pre-consult, pre-visit) [FDS: PBK-005, RBK-004, TBK-004, OBK-004]';
COMMENT ON TABLE patientengagement.mkt_questionnaire_question IS 'Questions of a questionnaire with blocking answers [FDS: PBK-005, RBK-004]';
COMMENT ON TABLE patientengagement.mkt_channel_partner IS 'Aggregator / channel partners (RateTiger-like channel manager) with B2B mapping [FDS: URS 162 Aggregator channel partner; CHK-008, SLT-006]';
COMMENT ON TABLE patientengagement.mkt_channel_listing_map IS 'Mapping of platform listings to channel partner product codes [FDS: SLT-006, CHK-008]';
COMMENT ON TABLE patientengagement.mkt_partner_settlement IS 'Periodic settlement statement per partner (gross, commission, TDS, refunds, net) [FDS: PWP-008]';
COMMENT ON TABLE patientengagement.mkt_partner_settlement_line IS 'Order-level lines of a partner settlement [FDS: PWP-008]';
COMMENT ON TABLE patientengagement.ecom_rating_review IS 'Ratings and reviews for providers, doctors and field agents with moderation [FDS: MKT-011, ORD-011, PRP-008, TRX-005 (Rating / review entity)]';
COMMENT ON TABLE patientengagement.ecom_cart IS 'Customer cart grouped by vertical and provider [FDS: CHK-001, CHK-002]';
COMMENT ON TABLE patientengagement.ecom_cart_item IS 'Cart lines with held slot [FDS: CHK-001, SLT-005]';
COMMENT ON TABLE patientengagement.ecom_order_episode IS 'Linked-order episode / WP session (consult -> medicines, home collection, scan) until all linked orders close [FDS: ORX-005, TRX-004, TMD-001..005]';
COMMENT ON TABLE patientengagement.ecom_order_status_history IS 'Order timeline milestones with timestamps [FDS: ORD-002, PLP-001, RLP-001]';
COMMENT ON TABLE patientengagement.ecom_prescription_attachment IS 'Prescription uploads / e-Rx linked to orders with pharmacist validation [FDS: PBK-003, RBK-003, MBK-002/003, MFF-002 (Prescription attachment entity)]';
COMMENT ON TABLE patientengagement.ecom_order_document IS 'Reports, prescriptions, invoices released against an order with version [FDS: ORD-005, PRP-003, PRP-009, RRP-002, MDL-007 (Report / document entity)]';
COMMENT ON TABLE patientengagement.pat_referral_status_history IS 'Referral status history (created, sent, accepted, booked, seen, report returned, closed, declined) [FDS: REF-003]';

COMMIT;
