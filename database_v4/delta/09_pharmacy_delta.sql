/* =====================================================================================
   DR REDDIS HEALTHCARE - HIMS  database_v3 (7 services)  ->  database_v4 (9 services)
   Step 09 - Pharmacy: column additions to existing tables + new FDS tables
   Run against an EXISTING himsdev database that was built from database_v3, in file-name order:
     00_restructure_7_to_9_services.sql  -> 01..09_<service>_delta.sql  -> 10_post_migration_housekeeping.sql -> ../full/roles.sql
   Every statement is idempotent where PostgreSQL allows it (IF NOT EXISTS / guarded DO blocks).
   ===================================================================================== */

BEGIN;

/* ---------- A. MODIFICATIONS TO EXISTING TABLES (ADD COLUMN) ---------- */

-- pharmacy.mst_drug  (27 new columns)  FDS: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS composition VARCHAR(500) NULL;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS pack_size VARCHAR(50) NULL;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS manufacturer VARCHAR(150) NULL;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS therapeutic_class VARCHAR(100) NULL;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS formulary_status VARCHAR(20) NULL DEFAULT 'FORMULARY';
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS requires_nf_approval BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS schedule_category VARCHAR(20) NULL;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS is_controlled BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS is_antibiotic_restricted BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS is_cold_chain BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS counselling_mandatory BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS pregnancy_category VARCHAR(5) NULL;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS lactation_risk VARCHAR(20) NULL;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS renal_adjustment_note VARCHAR(500) NULL;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS hepatic_adjustment_note VARCHAR(500) NULL;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS substitution_rule VARCHAR(20) NULL DEFAULT 'ALLOWED';
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS tall_man_name VARCHAR(150) NULL;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS system_of_medicine VARCHAR(20) NULL DEFAULT 'ALLOPATHY';
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS ayush_formulation_type VARCHAR(50) NULL;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS classical_or_proprietary VARCHAR(20) NULL;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS who_dde_code VARCHAR(30) NULL;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS max_qty_per_order DECIMAL(10,2) NULL;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS online_sale_blocked BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS version_no SMALLINT NULL DEFAULT 1;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS effective_from DATE NULL;
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) NULL DEFAULT 'APPROVED';
ALTER TABLE pharmacy.mst_drug ADD COLUMN IF NOT EXISTS merged_into_drug_id INT NULL;
COMMENT ON COLUMN pharmacy.mst_drug.composition IS '[v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.pack_size IS '[v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.manufacturer IS '[v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.therapeutic_class IS '[v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.formulary_status IS 'FORMULARY, NON_FORMULARY, RESTRICTED [v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.requires_nf_approval IS '[v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.schedule_category IS 'H, H1, X, NDPS, PSYCHOTROPIC, OTC, G [v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.is_controlled IS '[v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.is_antibiotic_restricted IS '[v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.is_cold_chain IS '[v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.counselling_mandatory IS '[v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.pregnancy_category IS '[v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.lactation_risk IS '[v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.renal_adjustment_note IS '[v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.hepatic_adjustment_note IS '[v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.substitution_rule IS 'ALLOWED, WITH_PRESCRIBER_CONSENT, NOT_ALLOWED [v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.tall_man_name IS '[v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.system_of_medicine IS '[v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.ayush_formulation_type IS 'Kashaya, Churna, Vati, Ghrita, Taila, Asava ... [v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.classical_or_proprietary IS '[v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.who_dde_code IS '[v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.max_qty_per_order IS 'online quantity limits (MBK-005) [v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.online_sale_blocked IS 'Schedule X / NDPS [v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.version_no IS '[v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.effective_from IS '[v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.approval_status IS '[v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';
COMMENT ON COLUMN pharmacy.mst_drug.merged_into_drug_id IS '[v4: DRG-001..007, SUB-003/004, SCH-001, AYU-020, HOM-010 (Item / drug entity)]';

-- pharmacy.mst_drug_interaction  (3 new columns)  FDS: DDI-001..003
ALTER TABLE pharmacy.mst_drug_interaction ADD COLUMN IF NOT EXISTS mechanism VARCHAR(500) NULL;
ALTER TABLE pharmacy.mst_drug_interaction ADD COLUMN IF NOT EXISTS management VARCHAR(500) NULL;
ALTER TABLE pharmacy.mst_drug_interaction ADD COLUMN IF NOT EXISTS interaction_type VARCHAR(20) NULL;
COMMENT ON COLUMN pharmacy.mst_drug_interaction.mechanism IS '[v4: DDI-001..003]';
COMMENT ON COLUMN pharmacy.mst_drug_interaction.management IS '[v4: DDI-001..003]';
COMMENT ON COLUMN pharmacy.mst_drug_interaction.interaction_type IS 'DRUG_DRUG, AYUSH_ALLOPATHIC, DRUG_FOOD [v4: DDI-001..003]';

-- pharmacy.mst_drug_substitute  (2 new columns)  FDS: SUB-001..003
ALTER TABLE pharmacy.mst_drug_substitute ADD COLUMN IF NOT EXISTS is_therapeutic_equivalent BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE pharmacy.mst_drug_substitute ADD COLUMN IF NOT EXISTS requires_prescriber_consent BOOLEAN NULL DEFAULT FALSE;
COMMENT ON COLUMN pharmacy.mst_drug_substitute.is_therapeutic_equivalent IS '[v4: SUB-001..003]';
COMMENT ON COLUMN pharmacy.mst_drug_substitute.requires_prescriber_consent IS '[v4: SUB-001..003]';

-- pharmacy.mst_generic  (4 new columns)  FDS: DRG-004, INT-006, DDI-002
ALTER TABLE pharmacy.mst_generic ADD COLUMN IF NOT EXISTS pregnancy_category VARCHAR(5) NULL;
ALTER TABLE pharmacy.mst_generic ADD COLUMN IF NOT EXISTS is_high_alert BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE pharmacy.mst_generic ADD COLUMN IF NOT EXISTS beers_criteria BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE pharmacy.mst_generic ADD COLUMN IF NOT EXISTS food_interactions VARCHAR(500) NULL;
COMMENT ON COLUMN pharmacy.mst_generic.pregnancy_category IS '[v4: DRG-004, INT-006, DDI-002]';
COMMENT ON COLUMN pharmacy.mst_generic.is_high_alert IS '[v4: DRG-004, INT-006, DDI-002]';
COMMENT ON COLUMN pharmacy.mst_generic.beers_criteria IS '[v4: DRG-004, INT-006, DDI-002]';
COMMENT ON COLUMN pharmacy.mst_generic.food_interactions IS '[v4: DRG-004, INT-006, DDI-002]';

-- pharmacy.pha_counseling_note  (11 new columns)  FDS: CNS-001..006 (Counselling note entity)
ALTER TABLE pharmacy.pha_counseling_note ADD COLUMN IF NOT EXISTS counseling_template_id INT NULL;
ALTER TABLE pharmacy.pha_counseling_note ADD COLUMN IF NOT EXISTS topics_json JSONB NULL;
ALTER TABLE pharmacy.pha_counseling_note ADD COLUMN IF NOT EXISTS language_code VARCHAR(10) NULL;
ALTER TABLE pharmacy.pha_counseling_note ADD COLUMN IF NOT EXISTS acknowledged_by_name VARCHAR(150) NULL;
ALTER TABLE pharmacy.pha_counseling_note ADD COLUMN IF NOT EXISTS acknowledged_relation VARCHAR(30) NULL;
ALTER TABLE pharmacy.pha_counseling_note ADD COLUMN IF NOT EXISTS acknowledged_at TIMESTAMPTZ(0) NULL;
ALTER TABLE pharmacy.pha_counseling_note ADD COLUMN IF NOT EXISTS is_mandatory BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE pharmacy.pha_counseling_note ADD COLUMN IF NOT EXISTS adherence_concern VARCHAR(500) NULL;
ALTER TABLE pharmacy.pha_counseling_note ADD COLUMN IF NOT EXISTS followup_required BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE pharmacy.pha_counseling_note ADD COLUMN IF NOT EXISTS care_team_notified_at TIMESTAMPTZ(0) NULL;
ALTER TABLE pharmacy.pha_counseling_note ADD COLUMN IF NOT EXISTS shared_to_portal BOOLEAN NULL DEFAULT FALSE;
COMMENT ON COLUMN pharmacy.pha_counseling_note.counseling_template_id IS '[v4: CNS-001..006 (Counselling note entity)]';
COMMENT ON COLUMN pharmacy.pha_counseling_note.topics_json IS '[v4: CNS-001..006 (Counselling note entity)]';
COMMENT ON COLUMN pharmacy.pha_counseling_note.language_code IS '[v4: CNS-001..006 (Counselling note entity)]';
COMMENT ON COLUMN pharmacy.pha_counseling_note.acknowledged_by_name IS '[v4: CNS-001..006 (Counselling note entity)]';
COMMENT ON COLUMN pharmacy.pha_counseling_note.acknowledged_relation IS '[v4: CNS-001..006 (Counselling note entity)]';
COMMENT ON COLUMN pharmacy.pha_counseling_note.acknowledged_at IS '[v4: CNS-001..006 (Counselling note entity)]';
COMMENT ON COLUMN pharmacy.pha_counseling_note.is_mandatory IS '[v4: CNS-001..006 (Counselling note entity)]';
COMMENT ON COLUMN pharmacy.pha_counseling_note.adherence_concern IS '[v4: CNS-001..006 (Counselling note entity)]';
COMMENT ON COLUMN pharmacy.pha_counseling_note.followup_required IS '[v4: CNS-001..006 (Counselling note entity)]';
COMMENT ON COLUMN pharmacy.pha_counseling_note.care_team_notified_at IS '[v4: CNS-001..006 (Counselling note entity)]';
COMMENT ON COLUMN pharmacy.pha_counseling_note.shared_to_portal IS '[v4: CNS-001..006 (Counselling note entity)]';

-- pharmacy.pha_dispense  (26 new columns)  FDS: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS order_source VARCHAR(20) NULL;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS admission_id BIGINT NULL;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS indent_id BIGINT NULL;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS is_emergency_issue BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS regularise_due_at TIMESTAMPTZ(0) NULL;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS regularised_prescription_id BIGINT NULL;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS days_supply SMALLINT NULL;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS receiver_name VARCHAR(150) NULL;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS receiver_ack_at TIMESTAMPTZ(0) NULL;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS wristband_verified BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS bill_id BIGINT NULL;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS payer_type VARCHAR(20) NULL;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS token_no VARCHAR(10) NULL;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS queue_status VARCHAR(20) NULL;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS is_home_delivery BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS delivery_address VARCHAR(500) NULL;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS delivery_status VARCHAR(20) NULL;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS delivery_proof_document_id BIGINT NULL;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS online_order_id BIGINT NULL;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS eprescription_link_id BIGINT NULL;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS abdm_shared_at TIMESTAMPTZ(0) NULL;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS is_discharge_medication BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS gross_amount DECIMAL(12,2) NULL;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(12,2) NULL;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS tax_amount DECIMAL(12,2) NULL;
ALTER TABLE pharmacy.pha_dispense ADD COLUMN IF NOT EXISTS net_amount DECIMAL(12,2) NULL;
COMMENT ON COLUMN pharmacy.pha_dispense.order_source IS 'DOCTOR_ORDER, WARD_INDENT, NURSE_REQUEST, EMERGENCY, OTC, ONLINE_ORDER, DISCHARGE [v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.admission_id IS '[v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.indent_id IS 'operationssupply.inv_indent [v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.is_emergency_issue IS '[v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.regularise_due_at IS '[v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.regularised_prescription_id IS '[v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.days_supply IS '[v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.receiver_name IS '[v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.receiver_ack_at IS '[v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.wristband_verified IS '[v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.bill_id IS 'revenuefinance.bil_bill [v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.payer_type IS '[v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.token_no IS '[v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.queue_status IS 'RECEIVED, PREPARING, READY, DISPENSED [v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.is_home_delivery IS '[v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.delivery_address IS '[v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.delivery_status IS '[v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.delivery_proof_document_id IS '[v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.online_order_id IS 'patientengagement.ecom_online_order [v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.eprescription_link_id IS '[v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.abdm_shared_at IS '[v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.is_discharge_medication IS '[v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.gross_amount IS '[v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.discount_amount IS '[v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.tax_amount IS '[v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense.net_amount IS '[v4: IPI-001..012, OPI-001..011, MBK-009, MFF-005 (Issue / dispense entity)]';

-- pharmacy.pha_dispense_item  (14 new columns)  FDS: IPI-003/004, OPI-002/003/008, PHB-002/005 (FEFO, partial, labels)
ALTER TABLE pharmacy.pha_dispense_item ADD COLUMN IF NOT EXISTS fefo_override_reason VARCHAR(300) NULL;
ALTER TABLE pharmacy.pha_dispense_item ADD COLUMN IF NOT EXISTS line_status VARCHAR(20) NULL;
ALTER TABLE pharmacy.pha_dispense_item ADD COLUMN IF NOT EXISTS ordered_qty DECIMAL(10,2) NULL;
ALTER TABLE pharmacy.pha_dispense_item ADD COLUMN IF NOT EXISTS pending_qty DECIMAL(10,2) NULL;
ALTER TABLE pharmacy.pha_dispense_item ADD COLUMN IF NOT EXISTS discount_pct DECIMAL(5,2) NULL;
ALTER TABLE pharmacy.pha_dispense_item ADD COLUMN IF NOT EXISTS gst_rate DECIMAL(5,2) NULL;
ALTER TABLE pharmacy.pha_dispense_item ADD COLUMN IF NOT EXISTS tax_amount DECIMAL(12,2) NULL;
ALTER TABLE pharmacy.pha_dispense_item ADD COLUMN IF NOT EXISTS line_amount DECIMAL(12,2) NULL;
ALTER TABLE pharmacy.pha_dispense_item ADD COLUMN IF NOT EXISTS expiry_date DATE NULL;
ALTER TABLE pharmacy.pha_dispense_item ADD COLUMN IF NOT EXISTS batch_no VARCHAR(50) NULL;
ALTER TABLE pharmacy.pha_dispense_item ADD COLUMN IF NOT EXISTS label_printed_at TIMESTAMPTZ(0) NULL;
ALTER TABLE pharmacy.pha_dispense_item ADD COLUMN IF NOT EXISTS label_language VARCHAR(10) NULL;
ALTER TABLE pharmacy.pha_dispense_item ADD COLUMN IF NOT EXISTS substitution_consent BOOLEAN NULL;
ALTER TABLE pharmacy.pha_dispense_item ADD COLUMN IF NOT EXISTS returnable_balance_qty DECIMAL(10,2) NULL;
COMMENT ON COLUMN pharmacy.pha_dispense_item.fefo_override_reason IS '[v4: IPI-003/004, OPI-002/003/008, PHB-002/005 (FEFO, partial, labels)]';
COMMENT ON COLUMN pharmacy.pha_dispense_item.line_status IS 'DISPENSED, PARTLY_DISPENSED, NOT_DISPENSED, SUBSTITUTED [v4: IPI-003/004, OPI-002/003/008, PHB-002/005 (FEFO, partial, labels)]';
COMMENT ON COLUMN pharmacy.pha_dispense_item.ordered_qty IS '[v4: IPI-003/004, OPI-002/003/008, PHB-002/005 (FEFO, partial, labels)]';
COMMENT ON COLUMN pharmacy.pha_dispense_item.pending_qty IS '[v4: IPI-003/004, OPI-002/003/008, PHB-002/005 (FEFO, partial, labels)]';
COMMENT ON COLUMN pharmacy.pha_dispense_item.discount_pct IS '[v4: IPI-003/004, OPI-002/003/008, PHB-002/005 (FEFO, partial, labels)]';
COMMENT ON COLUMN pharmacy.pha_dispense_item.gst_rate IS '[v4: IPI-003/004, OPI-002/003/008, PHB-002/005 (FEFO, partial, labels)]';
COMMENT ON COLUMN pharmacy.pha_dispense_item.tax_amount IS '[v4: IPI-003/004, OPI-002/003/008, PHB-002/005 (FEFO, partial, labels)]';
COMMENT ON COLUMN pharmacy.pha_dispense_item.line_amount IS '[v4: IPI-003/004, OPI-002/003/008, PHB-002/005 (FEFO, partial, labels)]';
COMMENT ON COLUMN pharmacy.pha_dispense_item.expiry_date IS '[v4: IPI-003/004, OPI-002/003/008, PHB-002/005 (FEFO, partial, labels)]';
COMMENT ON COLUMN pharmacy.pha_dispense_item.batch_no IS '[v4: IPI-003/004, OPI-002/003/008, PHB-002/005 (FEFO, partial, labels)]';
COMMENT ON COLUMN pharmacy.pha_dispense_item.label_printed_at IS '[v4: IPI-003/004, OPI-002/003/008, PHB-002/005 (FEFO, partial, labels)]';
COMMENT ON COLUMN pharmacy.pha_dispense_item.label_language IS '[v4: IPI-003/004, OPI-002/003/008, PHB-002/005 (FEFO, partial, labels)]';
COMMENT ON COLUMN pharmacy.pha_dispense_item.substitution_consent IS '[v4: IPI-003/004, OPI-002/003/008, PHB-002/005 (FEFO, partial, labels)]';
COMMENT ON COLUMN pharmacy.pha_dispense_item.returnable_balance_qty IS '[v4: IPI-003/004, OPI-002/003/008, PHB-002/005 (FEFO, partial, labels)]';

-- pharmacy.pha_dispense_return  (10 new columns)  FDS: RET-001..008, RET-010 (Return entity)
ALTER TABLE pharmacy.pha_dispense_return ADD COLUMN IF NOT EXISTS reason_code VARCHAR(30) NULL;
ALTER TABLE pharmacy.pha_dispense_return ADD COLUMN IF NOT EXISTS original_bill_id BIGINT NULL;
ALTER TABLE pharmacy.pha_dispense_return ADD COLUMN IF NOT EXISTS department_id INT NULL;
ALTER TABLE pharmacy.pha_dispense_return ADD COLUMN IF NOT EXISTS policy_check_json JSONB NULL;
ALTER TABLE pharmacy.pha_dispense_return ADD COLUMN IF NOT EXISTS needs_approval BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE pharmacy.pha_dispense_return ADD COLUMN IF NOT EXISTS approved_by BIGINT NULL;
ALTER TABLE pharmacy.pha_dispense_return ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ(0) NULL;
ALTER TABLE pharmacy.pha_dispense_return ADD COLUMN IF NOT EXISTS credit_note_id BIGINT NULL;
ALTER TABLE pharmacy.pha_dispense_return ADD COLUMN IF NOT EXISTS refund_request_id BIGINT NULL;
ALTER TABLE pharmacy.pha_dispense_return ADD COLUMN IF NOT EXISTS return_value DECIMAL(12,2) NULL;
COMMENT ON COLUMN pharmacy.pha_dispense_return.reason_code IS 'EXCESS, DISCONTINUED, ADVERSE_REACTION, WRONG_ITEM, DAMAGED, NEAR_EXPIRY [v4: RET-001..008, RET-010 (Return entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense_return.original_bill_id IS '[v4: RET-001..008, RET-010 (Return entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense_return.department_id IS '[v4: RET-001..008, RET-010 (Return entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense_return.policy_check_json IS '[v4: RET-001..008, RET-010 (Return entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense_return.needs_approval IS '[v4: RET-001..008, RET-010 (Return entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense_return.approved_by IS '[v4: RET-001..008, RET-010 (Return entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense_return.approved_at IS '[v4: RET-001..008, RET-010 (Return entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense_return.credit_note_id IS 'revenuefinance.bil_credit_note [v4: RET-001..008, RET-010 (Return entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense_return.refund_request_id IS 'revenuefinance.bil_refund_request [v4: RET-001..008, RET-010 (Return entity)]';
COMMENT ON COLUMN pharmacy.pha_dispense_return.return_value IS '[v4: RET-001..008, RET-010 (Return entity)]';

-- pharmacy.pha_dispense_return_item  (4 new columns)  FDS: RET-004, RET-006
ALTER TABLE pharmacy.pha_dispense_return_item ADD COLUMN IF NOT EXISTS decision VARCHAR(20) NULL;
ALTER TABLE pharmacy.pha_dispense_return_item ADD COLUMN IF NOT EXISTS decision_reason VARCHAR(300) NULL;
ALTER TABLE pharmacy.pha_dispense_return_item ADD COLUMN IF NOT EXISTS rate DECIMAL(12,2) NULL;
ALTER TABLE pharmacy.pha_dispense_return_item ADD COLUMN IF NOT EXISTS tax_amount DECIMAL(12,2) NULL;
COMMENT ON COLUMN pharmacy.pha_dispense_return_item.decision IS 'RESTOCK, QUARANTINE, DISPOSE [v4: RET-004, RET-006]';
COMMENT ON COLUMN pharmacy.pha_dispense_return_item.decision_reason IS '[v4: RET-004, RET-006]';
COMMENT ON COLUMN pharmacy.pha_dispense_return_item.rate IS '[v4: RET-004, RET-006]';
COMMENT ON COLUMN pharmacy.pha_dispense_return_item.tax_amount IS '[v4: RET-004, RET-006]';

-- pharmacy.pha_narcotic_register  (20 new columns)  FDS: SCH-002..006, SCH-009, SCH-011, PHB-004 (Controlled drug register entity)
ALTER TABLE pharmacy.pha_narcotic_register ADD COLUMN IF NOT EXISTS register_type VARCHAR(20) NULL DEFAULT 'NARCOTIC';
ALTER TABLE pharmacy.pha_narcotic_register ADD COLUMN IF NOT EXISTS drug_id INT NULL;
ALTER TABLE pharmacy.pha_narcotic_register ADD COLUMN IF NOT EXISTS opening_qty DECIMAL(10,2) NULL;
ALTER TABLE pharmacy.pha_narcotic_register ADD COLUMN IF NOT EXISTS receipt_qty DECIMAL(10,2) NULL;
ALTER TABLE pharmacy.pha_narcotic_register ADD COLUMN IF NOT EXISTS issue_qty DECIMAL(10,2) NULL;
ALTER TABLE pharmacy.pha_narcotic_register ADD COLUMN IF NOT EXISTS return_qty DECIMAL(10,2) NULL;
ALTER TABLE pharmacy.pha_narcotic_register ADD COLUMN IF NOT EXISTS wastage_qty DECIMAL(10,2) NULL;
ALTER TABLE pharmacy.pha_narcotic_register ADD COLUMN IF NOT EXISTS wastage_reason VARCHAR(300) NULL;
ALTER TABLE pharmacy.pha_narcotic_register ADD COLUMN IF NOT EXISTS patient_name VARCHAR(150) NULL;
ALTER TABLE pharmacy.pha_narcotic_register ADD COLUMN IF NOT EXISTS patient_address VARCHAR(300) NULL;
ALTER TABLE pharmacy.pha_narcotic_register ADD COLUMN IF NOT EXISTS patient_age SMALLINT NULL;
ALTER TABLE pharmacy.pha_narcotic_register ADD COLUMN IF NOT EXISTS prescriber_name VARCHAR(150) NULL;
ALTER TABLE pharmacy.pha_narcotic_register ADD COLUMN IF NOT EXISTS prescriber_reg_no VARCHAR(50) NULL;
ALTER TABLE pharmacy.pha_narcotic_register ADD COLUMN IF NOT EXISTS prescription_ref VARCHAR(50) NULL;
ALTER TABLE pharmacy.pha_narcotic_register ADD COLUMN IF NOT EXISTS dispense_id BIGINT NULL;
ALTER TABLE pharmacy.pha_narcotic_register ADD COLUMN IF NOT EXISTS second_verifier_by BIGINT NULL;
ALTER TABLE pharmacy.pha_narcotic_register ADD COLUMN IF NOT EXISTS verifier_esign_ref VARCHAR(200) NULL;
ALTER TABLE pharmacy.pha_narcotic_register ADD COLUMN IF NOT EXISTS reversal_of_register_id BIGINT NULL;
ALTER TABLE pharmacy.pha_narcotic_register ADD COLUMN IF NOT EXISTS row_hash VARCHAR(128) NULL;
ALTER TABLE pharmacy.pha_narcotic_register ADD COLUMN IF NOT EXISTS prev_row_hash VARCHAR(128) NULL;
COMMENT ON COLUMN pharmacy.pha_narcotic_register.register_type IS 'NARCOTIC, PSYCHOTROPIC, SCHEDULE_H1, SCHEDULE_X [v4: SCH-002..006, SCH-009, SCH-011, PHB-004 (Controlled drug register entity)]';
COMMENT ON COLUMN pharmacy.pha_narcotic_register.drug_id IS '[v4: SCH-002..006, SCH-009, SCH-011, PHB-004 (Controlled drug register entity)]';
COMMENT ON COLUMN pharmacy.pha_narcotic_register.opening_qty IS '[v4: SCH-002..006, SCH-009, SCH-011, PHB-004 (Controlled drug register entity)]';
COMMENT ON COLUMN pharmacy.pha_narcotic_register.receipt_qty IS '[v4: SCH-002..006, SCH-009, SCH-011, PHB-004 (Controlled drug register entity)]';
COMMENT ON COLUMN pharmacy.pha_narcotic_register.issue_qty IS '[v4: SCH-002..006, SCH-009, SCH-011, PHB-004 (Controlled drug register entity)]';
COMMENT ON COLUMN pharmacy.pha_narcotic_register.return_qty IS '[v4: SCH-002..006, SCH-009, SCH-011, PHB-004 (Controlled drug register entity)]';
COMMENT ON COLUMN pharmacy.pha_narcotic_register.wastage_qty IS '[v4: SCH-002..006, SCH-009, SCH-011, PHB-004 (Controlled drug register entity)]';
COMMENT ON COLUMN pharmacy.pha_narcotic_register.wastage_reason IS '[v4: SCH-002..006, SCH-009, SCH-011, PHB-004 (Controlled drug register entity)]';
COMMENT ON COLUMN pharmacy.pha_narcotic_register.patient_name IS '[v4: SCH-002..006, SCH-009, SCH-011, PHB-004 (Controlled drug register entity)]';
COMMENT ON COLUMN pharmacy.pha_narcotic_register.patient_address IS '[v4: SCH-002..006, SCH-009, SCH-011, PHB-004 (Controlled drug register entity)]';
COMMENT ON COLUMN pharmacy.pha_narcotic_register.patient_age IS '[v4: SCH-002..006, SCH-009, SCH-011, PHB-004 (Controlled drug register entity)]';
COMMENT ON COLUMN pharmacy.pha_narcotic_register.prescriber_name IS '[v4: SCH-002..006, SCH-009, SCH-011, PHB-004 (Controlled drug register entity)]';
COMMENT ON COLUMN pharmacy.pha_narcotic_register.prescriber_reg_no IS '[v4: SCH-002..006, SCH-009, SCH-011, PHB-004 (Controlled drug register entity)]';
COMMENT ON COLUMN pharmacy.pha_narcotic_register.prescription_ref IS '[v4: SCH-002..006, SCH-009, SCH-011, PHB-004 (Controlled drug register entity)]';
COMMENT ON COLUMN pharmacy.pha_narcotic_register.dispense_id IS '[v4: SCH-002..006, SCH-009, SCH-011, PHB-004 (Controlled drug register entity)]';
COMMENT ON COLUMN pharmacy.pha_narcotic_register.second_verifier_by IS '[v4: SCH-002..006, SCH-009, SCH-011, PHB-004 (Controlled drug register entity)]';
COMMENT ON COLUMN pharmacy.pha_narcotic_register.verifier_esign_ref IS '[v4: SCH-002..006, SCH-009, SCH-011, PHB-004 (Controlled drug register entity)]';
COMMENT ON COLUMN pharmacy.pha_narcotic_register.reversal_of_register_id IS '[v4: SCH-002..006, SCH-009, SCH-011, PHB-004 (Controlled drug register entity)]';
COMMENT ON COLUMN pharmacy.pha_narcotic_register.row_hash IS 'tamper-evident hash chain [v4: SCH-002..006, SCH-009, SCH-011, PHB-004 (Controlled drug register entity)]';
COMMENT ON COLUMN pharmacy.pha_narcotic_register.prev_row_hash IS '[v4: SCH-002..006, SCH-009, SCH-011, PHB-004 (Controlled drug register entity)]';

/* ---------- B. NEW TABLES ---------- */

-- ===== Pharmacy Functional Requirements Document - dispensing, drug database, controlled drugs, e-Rx =====
-- [NEW v4] FDS ref: DRG-004, IPI-005, OPI-006, CPO-003
CREATE TABLE IF NOT EXISTS pharmacy.mst_drug_dose_range (                      -- Dose ranges by age / weight band and route for dose-range checks
    drug_dose_range_id         INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    generic_id                 INT NOT NULL,
    route                      VARCHAR(20) NULL,
    age_min_days               INT NULL,
    age_max_days               INT NULL,
    weight_min_kg              DECIMAL(6,2) NULL,
    weight_max_kg              DECIMAL(6,2) NULL,
    min_single_dose            DECIMAL(12,4) NULL,
    max_single_dose            DECIMAL(12,4) NULL,
    max_daily_dose             DECIMAL(12,4) NULL,
    dose_unit                  VARCHAR(20) NOT NULL,
    per_kg                     BOOLEAN NOT NULL DEFAULT FALSE,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: DRG-005, DRG-007
CREATE TABLE IF NOT EXISTS pharmacy.mst_drug_change_request (                  -- Maker-checker changes to drug master with version history and effective dates
    drug_change_request_id     BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    drug_id                    INT NULL,
    change_type                VARCHAR(20) NOT NULL,                           -- CREATE, UPDATE, MERGE, RETIRE
    proposed_json              JSONB NOT NULL,
    previous_json              JSONB NULL,
    effective_from             DATE NULL,
    requested_by               BIGINT NOT NULL,
    approved_by                BIGINT NULL,
    approved_at                TIMESTAMPTZ(0) NULL,
    request_status             VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    bulk_import_job_id         BIGINT NULL,                                    -- logical FK -> integrationcomms.intg_bulk_import_job [Integration & Communications]
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: SUB-004, SUB-005, IPI-006
CREATE TABLE IF NOT EXISTS pharmacy.mst_lasa_pair (                            -- Look-alike / sound-alike drug pairs with Tall Man lettering
    lasa_pair_id               INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    drug_id_a                  INT NOT NULL,
    drug_id_b                  INT NOT NULL,
    confusion_type             VARCHAR(20) NOT NULL,                           -- LOOK_ALIKE, SOUND_ALIKE, PACK_ALIKE
    alert_text                 VARCHAR(300) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: DRG-008, BAT-004
CREATE TABLE IF NOT EXISTS pharmacy.pha_drug_recall (                          -- Product recalls / drug alerts by batch with quarantine and notifications
    drug_recall_id             BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    recall_no                  VARCHAR(30) NOT NULL UNIQUE,
    drug_id                    INT NOT NULL,
    recall_source              VARCHAR(30) NULL,                               -- CDSCO, MANUFACTURER, INTERNAL
    recall_class               VARCHAR(10) NULL,
    batch_nos                  VARCHAR(500) NOT NULL,
    reason                     VARCHAR(1000) NOT NULL,
    announced_on               DATE NOT NULL,
    quarantined_at             TIMESTAMPTZ(0) NULL,
    notified_at                TIMESTAMPTZ(0) NULL,
    recall_status              VARCHAR(20) NOT NULL DEFAULT 'OPEN',            -- OPEN, QUARANTINED, RETURNED, CLOSED
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: IPI-005, OPI-006, DDI-004
CREATE TABLE IF NOT EXISTS pharmacy.pha_dispense_alert (                       -- Safety checks at issue (allergy, interaction, duplicate, dose, LASA) and pharmacist action
    dispense_alert_id          BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    dispense_id                BIGINT NOT NULL,
    dispense_item_id           BIGINT NULL,
    check_type                 VARCHAR(20) NOT NULL,                           -- ALLERGY, INTERACTION, DUPLICATE, DOSE_RANGE, LASA, SCHEDULE
    severity                   VARCHAR(10) NOT NULL,
    alert_message              VARCHAR(1000) NOT NULL,
    pharmacist_action          VARCHAR(20) NOT NULL,                           -- ACKNOWLEDGED, OVERRIDDEN, STOPPED, CLARIFIED
    override_reason            VARCHAR(300) NULL,
    acted_by                   BIGINT NOT NULL,
    acted_at                   TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: PHO-002 (EHR), MFF-002
CREATE TABLE IF NOT EXISTS pharmacy.pha_prescription_clarification (           -- Pharmacist clarification requests to the prescriber with response
    prescription_clarification_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    prescription_id            BIGINT NOT NULL,                                -- logical FK -> clinicalcare.ord_prescription [Clinical Care]
    prescription_item_id       BIGINT NULL,                                    -- logical FK -> clinicalcare.ord_prescription_item [Clinical Care]
    online_order_id            BIGINT NULL,                                    -- logical FK -> patientengagement.ecom_online_order [Patient Access & Engagement]
    query_text                 VARCHAR(1000) NOT NULL,
    raised_by                  BIGINT NOT NULL,
    raised_at                  TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    response_text              VARCHAR(1000) NULL,
    responded_by               BIGINT NULL,
    responded_at               TIMESTAMPTZ(0) NULL,
    clarification_status       VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: OPI-007, MBK-008
CREATE TABLE IF NOT EXISTS pharmacy.pha_prescription_refill (                  -- Prescription validity and refill tracking
    prescription_refill_id     BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    prescription_id            BIGINT NOT NULL,                                -- logical FK -> clinicalcare.ord_prescription [Clinical Care]
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    valid_until                DATE NULL,
    refills_allowed            SMALLINT NOT NULL DEFAULT 0,
    refills_used               SMALLINT NOT NULL DEFAULT 0,
    last_dispense_id           BIGINT NULL,
    next_refill_due            DATE NULL,
    reminder_sent_at           TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: CNS-002
CREATE TABLE IF NOT EXISTS pharmacy.pha_counseling_template (                  -- Counselling templates per drug / drug class, multilingual
    counseling_template_id     INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    drug_id                    INT NULL,
    generic_id                 INT NULL,
    drug_class                 VARCHAR(100) NULL,
    language_code              VARCHAR(10) NOT NULL DEFAULT 'en',
    template_text              TEXT NOT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: SCH-007, SCH-010
CREATE TABLE IF NOT EXISTS pharmacy.pha_controlled_count (                     -- Shift / periodic reconciliation of controlled-drug physical count vs register
    controlled_count_id        BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    store_id                   INT NOT NULL,                                   -- logical FK -> operationssupply.mst_store [Operations & Supply Chain]
    count_at                   TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    shift_code                 VARCHAR(20) NULL,
    item_batch_id              BIGINT NOT NULL,                                -- logical FK -> operationssupply.inv_item_batch [Operations & Supply Chain]
    register_balance           DECIMAL(10,2) NOT NULL,
    physical_count             DECIMAL(10,2) NOT NULL,
    discrepancy                DECIMAL(10,2) NULL,
    counted_by                 BIGINT NOT NULL,
    verified_by                BIGINT NULL,
    explanation                VARCHAR(500) NULL,
    alert_sent_at              TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: BAT-007..010 (E-prescription link entity)
CREATE TABLE IF NOT EXISTS pharmacy.pha_eprescription_link (                   -- E-prescription link (HIS / ABDM): ABHA reference, consent, dispensing status
    eprescription_link_id      BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    prescription_id            BIGINT NULL,                                    -- logical FK -> clinicalcare.ord_prescription [Clinical Care]
    external_prescription_ref  VARCHAR(100) NULL,                              -- other ABDM facility e-Rx id
    abha_reference             VARCHAR(100) NULL,
    qr_payload_hash            VARCHAR(128) NULL,
    source_facility_hfr        VARCHAR(50) NULL,
    prescriber_name            VARCHAR(150) NULL,
    prescribed_on              DATE NULL,
    valid_until                DATE NULL,
    abdm_consent_artefact_id   BIGINT NULL,                                    -- logical FK -> integrationcomms.intg_abdm_consent_artefact [Integration & Communications]
    dispensing_status          VARCHAR(20) NOT NULL DEFAULT 'NOT_DISPENSED',   -- NOT_DISPENSED, PARTLY, FULLY, SUBSTITUTED, INVALID, EXPIRED
    fetched_at                 TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dispensing_record_sent_at  TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: BAT-011
CREATE TABLE IF NOT EXISTS pharmacy.pha_eprescription_access_log (             -- Consent, access and sharing audit of e-prescription data
    eprescription_access_log_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    eprescription_link_id      BIGINT NOT NULL,
    action                     VARCHAR(20) NOT NULL,                           -- FETCH, VIEW, DISPENSE_UPDATE, SHARE
    user_id                    BIGINT NULL,
    accessed_at                TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    outcome                    VARCHAR(10) NOT NULL DEFAULT 'SUCCESS',
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] replica of operationssupply.mst_item, owned by Operations & Supply Chain; used by: pharmacy.pha_dispense_item, pharmacy.mst_drug
CREATE TABLE IF NOT EXISTS pharmacy.ref_item (
    item_id                    INT PRIMARY KEY,
    organization_id            INT NULL,
    item_category_id           INT NULL,
    item_code                  VARCHAR(30) NULL,
    item_name                  VARCHAR(250) NULL,
    item_type                  VARCHAR(20) NULL,
    manufacturer               VARCHAR(150) NULL,
    purchase_uom               VARCHAR(20) NULL,
    issue_uom                  VARCHAR(20) NULL,
    conversion_factor          DECIMAL(12,3) NULL,
    hsn_code                   VARCHAR(10) NULL,
    gst_rate                   DECIMAL(5,2) NULL,
    is_batch_tracked           BOOLEAN NULL,
    is_expiry_tracked          BOOLEAN NULL,
    is_serial_tracked          BOOLEAN NULL,
    is_billable                BOOLEAN NULL,
    is_cold_chain              BOOLEAN NULL,
    barcode                    VARCHAR(50) NULL,
    is_active                  BOOLEAN NULL,
    gs1_gtin                   VARCHAR(20) NULL,
    hsn_sac_id                 INT NULL,                                       -- revenuefinance.mst_hsn_sac
    pack_size                  VARCHAR(50) NULL,
    abc_class                  CHAR(1) NULL,
    ved_class                  CHAR(1) NULL,
    is_returnable              BOOLEAN NULL,
    min_shelf_life_days        SMALLINT NULL,                                  -- GRN-003 short-expiry block
    updated_at                 TIMESTAMPTZ(3) NULL,
    source_version             BIGINT NULL,                                    -- version / sequence from publisher (ignore stale events)
    replicated_at              TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- [NEW v4] replica of operationssupply.inv_item_batch, owned by Operations & Supply Chain; used by: pharmacy.pha_dispense_item, pharmacy.pha_narcotic_register, pharmacy.pha_controlled_count
CREATE TABLE IF NOT EXISTS pharmacy.ref_item_batch (
    item_batch_id              BIGINT PRIMARY KEY,
    item_id                    INT NULL,
    batch_no                   VARCHAR(30) NULL,
    serial_no                  VARCHAR(50) NULL,
    mfg_date                   DATE NULL,
    expiry_date                DATE NULL,
    mrp                        DECIMAL(14,2) NULL,
    purchase_rate              DECIMAL(14,4) NULL,
    sale_rate                  DECIMAL(14,2) NULL,
    barcode                    VARCHAR(50) NULL,
    vendor_id                  INT NULL,
    is_active                  BOOLEAN NULL,
    batch_status               VARCHAR(20) NULL,                               -- AVAILABLE, QUARANTINED, EXPIRED, RECALLED, BLOCKED
    gs1_serial                 VARCHAR(50) NULL,
    internal_barcode           VARCHAR(50) NULL,
    grn_item_id                BIGINT NULL,
    manufacturer               VARCHAR(150) NULL,
    recall_id                  BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    source_version             BIGINT NULL,                                    -- version / sequence from publisher (ignore stale events)
    replicated_at              TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- [NEW v4] replica of operationssupply.mst_store, owned by Operations & Supply Chain; used by: pharmacy.pha_dispense, pharmacy.pha_narcotic_register
CREATE TABLE IF NOT EXISTS pharmacy.ref_store (
    store_id                   INT PRIMARY KEY,
    organization_id            INT NULL,
    branch_id                  INT NULL,
    parent_store_id            INT NULL,
    department_id              INT NULL,
    store_code                 VARCHAR(20) NULL,
    store_name                 VARCHAR(150) NULL,
    store_type                 VARCHAR(20) NULL,
    is_sale_point              BOOLEAN NULL,
    drug_licence_no            VARCHAR(50) NULL,
    is_active                  BOOLEAN NULL,
    store_category             VARCHAR(20) NULL,                               -- CENTRAL, SUB_BRANCH, DEPARTMENTAL, WARD_FLOOR, PHARMACY_OUTLET
    drug_licence_valid_to      DATE NULL,
    in_charge_employee_id      BIGINT NULL,
    store_status               VARCHAR(20) NULL,
    allow_negative_stock       BOOLEAN NULL,
    is_controlled_drug_store   BOOLEAN NULL,
    has_cold_chain             BOOLEAN NULL,
    sync_mode                  VARCHAR(20) NULL,                               -- REALTIME, INTERVAL
    sync_interval_minutes      SMALLINT NULL,
    is_frozen_for_count        BOOLEAN NULL,
    gstin                      VARCHAR(15) NULL,
    state_code                 VARCHAR(5) NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    source_version             BIGINT NULL,                                    -- version / sequence from publisher (ignore stale events)
    replicated_at              TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- [NEW v4] replica of operationssupply.inv_stock, owned by Operations & Supply Chain; used by: pharmacy.pha_dispense_item (FEFO batch suggestion / availability)
CREATE TABLE IF NOT EXISTS pharmacy.ref_stock (
    stock_id                   BIGINT PRIMARY KEY,
    store_id                   INT NULL,
    item_id                    INT NULL,
    item_batch_id              BIGINT NULL,
    qty_on_hand                DECIMAL(14,3) NULL,
    qty_reserved               DECIMAL(14,3) NULL,
    last_txn_at                TIMESTAMPTZ(0) NULL,
    qty_in_transit             DECIMAL(12,2) NULL,
    qty_quarantined            DECIMAL(12,2) NULL,
    store_location_id          INT NULL,
    last_synced_at             TIMESTAMPTZ(0) NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    source_version             BIGINT NULL,                                    -- version / sequence from publisher (ignore stale events)
    replicated_at              TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- [NEW v4] replica of revenuefinance.mst_hsn_sac, owned by Revenue & Finance; used by: pharmacy.pha_dispense_item
CREATE TABLE IF NOT EXISTS pharmacy.ref_hsn_sac (
    hsn_sac_id                 INT PRIMARY KEY,
    organization_id            INT NULL,
    code                       VARCHAR(10) NULL,
    code_type                  VARCHAR(5) NULL,                                -- HSN, SAC
    description                VARCHAR(500) NULL,
    gst_rate                   DECIMAL(5,2) NULL,
    cgst_rate                  DECIMAL(5,2) NULL,
    sgst_rate                  DECIMAL(5,2) NULL,
    igst_rate                  DECIMAL(5,2) NULL,
    cess_rate                  DECIMAL(5,2) NULL,
    tax_category               VARCHAR(20) NULL,                               -- TAXABLE, EXEMPT, NIL_RATED, NON_GST
    effective_from             DATE NULL,
    effective_to               DATE NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    source_version             BIGINT NULL,                                    -- version / sequence from publisher (ignore stale events)
    replicated_at              TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);


/* ---------- C. FOREIGN KEYS (same service only) ---------- */
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'pharmacy' AND c.conname = 'fk_mst_drug_dose_range_generic_id') THEN
        ALTER TABLE pharmacy.mst_drug_dose_range ADD CONSTRAINT fk_mst_drug_dose_range_generic_id FOREIGN KEY (generic_id) REFERENCES pharmacy.mst_generic(generic_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'pharmacy' AND c.conname = 'fk_mst_drug_change_request_drug_id') THEN
        ALTER TABLE pharmacy.mst_drug_change_request ADD CONSTRAINT fk_mst_drug_change_request_drug_id FOREIGN KEY (drug_id) REFERENCES pharmacy.mst_drug(drug_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'pharmacy' AND c.conname = 'fk_mst_lasa_pair_drug_id_a') THEN
        ALTER TABLE pharmacy.mst_lasa_pair ADD CONSTRAINT fk_mst_lasa_pair_drug_id_a FOREIGN KEY (drug_id_a) REFERENCES pharmacy.mst_drug(drug_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'pharmacy' AND c.conname = 'fk_mst_lasa_pair_drug_id_b') THEN
        ALTER TABLE pharmacy.mst_lasa_pair ADD CONSTRAINT fk_mst_lasa_pair_drug_id_b FOREIGN KEY (drug_id_b) REFERENCES pharmacy.mst_drug(drug_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'pharmacy' AND c.conname = 'fk_pha_drug_recall_drug_id') THEN
        ALTER TABLE pharmacy.pha_drug_recall ADD CONSTRAINT fk_pha_drug_recall_drug_id FOREIGN KEY (drug_id) REFERENCES pharmacy.mst_drug(drug_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'pharmacy' AND c.conname = 'fk_pha_dispense_alert_dispense_id') THEN
        ALTER TABLE pharmacy.pha_dispense_alert ADD CONSTRAINT fk_pha_dispense_alert_dispense_id FOREIGN KEY (dispense_id) REFERENCES pharmacy.pha_dispense(dispense_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'pharmacy' AND c.conname = 'fk_pha_dispense_alert_dispense_item_id') THEN
        ALTER TABLE pharmacy.pha_dispense_alert ADD CONSTRAINT fk_pha_dispense_alert_dispense_item_id FOREIGN KEY (dispense_item_id) REFERENCES pharmacy.pha_dispense_item(dispense_item_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'pharmacy' AND c.conname = 'fk_pha_prescription_refill_last_dispense_id') THEN
        ALTER TABLE pharmacy.pha_prescription_refill ADD CONSTRAINT fk_pha_prescription_refill_last_dispense_id FOREIGN KEY (last_dispense_id) REFERENCES pharmacy.pha_dispense(dispense_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'pharmacy' AND c.conname = 'fk_pha_counseling_template_drug_id') THEN
        ALTER TABLE pharmacy.pha_counseling_template ADD CONSTRAINT fk_pha_counseling_template_drug_id FOREIGN KEY (drug_id) REFERENCES pharmacy.mst_drug(drug_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'pharmacy' AND c.conname = 'fk_pha_counseling_template_generic_id') THEN
        ALTER TABLE pharmacy.pha_counseling_template ADD CONSTRAINT fk_pha_counseling_template_generic_id FOREIGN KEY (generic_id) REFERENCES pharmacy.mst_generic(generic_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'pharmacy' AND c.conname = 'fk_pha_eprescription_access_log_eprescription_link_id') THEN
        ALTER TABLE pharmacy.pha_eprescription_access_log ADD CONSTRAINT fk_pha_eprescription_access_log_eprescription_link_id FOREIGN KEY (eprescription_link_id) REFERENCES pharmacy.pha_eprescription_link(eprescription_link_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'pharmacy' AND c.conname = 'fk_mst_drug_merged_into_drug_id') THEN
        ALTER TABLE pharmacy.mst_drug ADD CONSTRAINT fk_mst_drug_merged_into_drug_id FOREIGN KEY (merged_into_drug_id) REFERENCES pharmacy.mst_drug(drug_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_mst_drug_merged_into_drug_id ON pharmacy.mst_drug(merged_into_drug_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'pharmacy' AND c.conname = 'fk_pha_counseling_note_counseling_template_id') THEN
        ALTER TABLE pharmacy.pha_counseling_note ADD CONSTRAINT fk_pha_counseling_note_counseling_template_id FOREIGN KEY (counseling_template_id) REFERENCES pharmacy.pha_counseling_template(counseling_template_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_pha_counseling_note_counseling_template_id ON pharmacy.pha_counseling_note(counseling_template_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'pharmacy' AND c.conname = 'fk_pha_dispense_eprescription_link_id') THEN
        ALTER TABLE pharmacy.pha_dispense ADD CONSTRAINT fk_pha_dispense_eprescription_link_id FOREIGN KEY (eprescription_link_id) REFERENCES pharmacy.pha_eprescription_link(eprescription_link_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_pha_dispense_eprescription_link_id ON pharmacy.pha_dispense(eprescription_link_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'pharmacy' AND c.conname = 'fk_pha_narcotic_register_drug_id') THEN
        ALTER TABLE pharmacy.pha_narcotic_register ADD CONSTRAINT fk_pha_narcotic_register_drug_id FOREIGN KEY (drug_id) REFERENCES pharmacy.mst_drug(drug_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_pha_narcotic_register_drug_id ON pharmacy.pha_narcotic_register(drug_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'pharmacy' AND c.conname = 'fk_pha_narcotic_register_dispense_id') THEN
        ALTER TABLE pharmacy.pha_narcotic_register ADD CONSTRAINT fk_pha_narcotic_register_dispense_id FOREIGN KEY (dispense_id) REFERENCES pharmacy.pha_dispense(dispense_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_pha_narcotic_register_dispense_id ON pharmacy.pha_narcotic_register(dispense_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'pharmacy' AND c.conname = 'fk_pha_narcotic_register_reversal_of_register_id') THEN
        ALTER TABLE pharmacy.pha_narcotic_register ADD CONSTRAINT fk_pha_narcotic_register_reversal_of_register_id FOREIGN KEY (reversal_of_register_id) REFERENCES pharmacy.pha_narcotic_register(narcotic_register_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_pha_narcotic_register_reversal_of_register_id ON pharmacy.pha_narcotic_register(reversal_of_register_id);

/* ---------- D. INDEXES ---------- */
CREATE INDEX IF NOT EXISTS ix_mst_drug_dose_range_generic_id ON pharmacy.mst_drug_dose_range(generic_id);
CREATE INDEX IF NOT EXISTS ix_mst_drug_change_request_drug_id ON pharmacy.mst_drug_change_request(drug_id);
CREATE INDEX IF NOT EXISTS ix_mst_lasa_pair_drug_id_a ON pharmacy.mst_lasa_pair(drug_id_a);
CREATE INDEX IF NOT EXISTS ix_mst_lasa_pair_drug_id_b ON pharmacy.mst_lasa_pair(drug_id_b);
CREATE INDEX IF NOT EXISTS ix_pha_drug_recall_drug_id ON pharmacy.pha_drug_recall(drug_id);
CREATE INDEX IF NOT EXISTS ix_pha_dispense_alert_dispense_id ON pharmacy.pha_dispense_alert(dispense_id);
CREATE INDEX IF NOT EXISTS ix_pha_dispense_alert_dispense_item_id ON pharmacy.pha_dispense_alert(dispense_item_id);
CREATE INDEX IF NOT EXISTS ix_pha_prescription_clarification_online_order_id ON pharmacy.pha_prescription_clarification(online_order_id);
CREATE INDEX IF NOT EXISTS ix_pha_prescription_refill_patient_id ON pharmacy.pha_prescription_refill(patient_id);
CREATE INDEX IF NOT EXISTS ix_pha_prescription_refill_last_dispense_id ON pharmacy.pha_prescription_refill(last_dispense_id);
CREATE INDEX IF NOT EXISTS ix_pha_counseling_template_drug_id ON pharmacy.pha_counseling_template(drug_id);
CREATE INDEX IF NOT EXISTS ix_pha_counseling_template_generic_id ON pharmacy.pha_counseling_template(generic_id);
CREATE INDEX IF NOT EXISTS ix_pha_eprescription_access_log_eprescription_link_id ON pharmacy.pha_eprescription_access_log(eprescription_link_id);

/* ---------- E. TABLE COMMENTS (FDS traceability) ---------- */
COMMENT ON TABLE pharmacy.mst_drug_dose_range IS 'Dose ranges by age / weight band and route for dose-range checks [FDS: DRG-004, IPI-005, OPI-006, CPO-003]';
COMMENT ON TABLE pharmacy.mst_drug_change_request IS 'Maker-checker changes to drug master with version history and effective dates [FDS: DRG-005, DRG-007]';
COMMENT ON TABLE pharmacy.mst_lasa_pair IS 'Look-alike / sound-alike drug pairs with Tall Man lettering [FDS: SUB-004, SUB-005, IPI-006]';
COMMENT ON TABLE pharmacy.pha_drug_recall IS 'Product recalls / drug alerts by batch with quarantine and notifications [FDS: DRG-008, BAT-004]';
COMMENT ON TABLE pharmacy.pha_dispense_alert IS 'Safety checks at issue (allergy, interaction, duplicate, dose, LASA) and pharmacist action [FDS: IPI-005, OPI-006, DDI-004]';
COMMENT ON TABLE pharmacy.pha_prescription_clarification IS 'Pharmacist clarification requests to the prescriber with response [FDS: PHO-002 (EHR), MFF-002]';
COMMENT ON TABLE pharmacy.pha_prescription_refill IS 'Prescription validity and refill tracking [FDS: OPI-007, MBK-008]';
COMMENT ON TABLE pharmacy.pha_counseling_template IS 'Counselling templates per drug / drug class, multilingual [FDS: CNS-002]';
COMMENT ON TABLE pharmacy.pha_controlled_count IS 'Shift / periodic reconciliation of controlled-drug physical count vs register [FDS: SCH-007, SCH-010]';
COMMENT ON TABLE pharmacy.pha_eprescription_link IS 'E-prescription link (HIS / ABDM): ABHA reference, consent, dispensing status [FDS: BAT-007..010 (E-prescription link entity)]';
COMMENT ON TABLE pharmacy.pha_eprescription_access_log IS 'Consent, access and sharing audit of e-prescription data [FDS: BAT-011]';

COMMIT;
