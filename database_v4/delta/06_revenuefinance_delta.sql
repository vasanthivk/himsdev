/* =====================================================================================
   DR REDDIS HEALTHCARE - HIMS  database_v3 (7 services)  ->  database_v4 (9 services)
   Step 06 - Revenue & Finance: column additions to existing tables + new FDS tables
   Run against an EXISTING himsdev database that was built from database_v3, in file-name order:
     00_restructure_7_to_9_services.sql  -> 01..09_<service>_delta.sql  -> 10_post_migration_housekeeping.sql -> ../full/roles.sql
   Every statement is idempotent where PostgreSQL allows it (IF NOT EXISTS / guarded DO blocks).
   ===================================================================================== */

BEGIN;

/* ---------- A. MODIFICATIONS TO EXISTING TABLES (ADD COLUMN) ---------- */

-- revenuefinance.bil_bill  (15 new columns)  FDS: CORE-002..009, IPB-006/008/009, TAR-010, GOV-007 (Bill / invoice entity)
ALTER TABLE revenuefinance.bil_bill ADD COLUMN IF NOT EXISTS patient_account_id BIGINT NULL;
ALTER TABLE revenuefinance.bil_bill ADD COLUMN IF NOT EXISTS is_interim BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE revenuefinance.bil_bill ADD COLUMN IF NOT EXISTS consolidated_bill_id BIGINT NULL;
ALTER TABLE revenuefinance.bil_bill ADD COLUMN IF NOT EXISTS split_group_ref VARCHAR(30) NULL;
ALTER TABLE revenuefinance.bil_bill ADD COLUMN IF NOT EXISTS revision_no SMALLINT NULL DEFAULT 0;
ALTER TABLE revenuefinance.bil_bill ADD COLUMN IF NOT EXISTS revised_from_bill_id BIGINT NULL;
ALTER TABLE revenuefinance.bil_bill ADD COLUMN IF NOT EXISTS locked_at TIMESTAMPTZ(0) NULL;
ALTER TABLE revenuefinance.bil_bill ADD COLUMN IF NOT EXISTS place_of_supply_state VARCHAR(5) NULL;
ALTER TABLE revenuefinance.bil_bill ADD COLUMN IF NOT EXISTS cost_center_id INT NULL;
ALTER TABLE revenuefinance.bil_bill ADD COLUMN IF NOT EXISTS b2b_payer_id INT NULL;
ALTER TABLE revenuefinance.bil_bill ADD COLUMN IF NOT EXISTS scheme_code VARCHAR(30) NULL;
ALTER TABLE revenuefinance.bil_bill ADD COLUMN IF NOT EXISTS print_count SMALLINT NULL DEFAULT 0;
ALTER TABLE revenuefinance.bil_bill ADD COLUMN IF NOT EXISTS e_invoice_ack_no VARCHAR(50) NULL;
ALTER TABLE revenuefinance.bil_bill ADD COLUMN IF NOT EXISTS e_way_bill_no VARCHAR(30) NULL;
ALTER TABLE revenuefinance.bil_bill ADD COLUMN IF NOT EXISTS corporate_invoice_id BIGINT NULL;
COMMENT ON COLUMN revenuefinance.bil_bill.patient_account_id IS '[v4: CORE-002..009, IPB-006/008/009, TAR-010, GOV-007 (Bill / invoice entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill.is_interim IS '[v4: CORE-002..009, IPB-006/008/009, TAR-010, GOV-007 (Bill / invoice entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill.consolidated_bill_id IS '[v4: CORE-002..009, IPB-006/008/009, TAR-010, GOV-007 (Bill / invoice entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill.split_group_ref IS 'payer-split invoices of one episode [v4: CORE-002..009, IPB-006/008/009, TAR-010, GOV-007 (Bill / invoice entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill.revision_no IS '[v4: CORE-002..009, IPB-006/008/009, TAR-010, GOV-007 (Bill / invoice entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill.revised_from_bill_id IS '[v4: CORE-002..009, IPB-006/008/009, TAR-010, GOV-007 (Bill / invoice entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill.locked_at IS '[v4: CORE-002..009, IPB-006/008/009, TAR-010, GOV-007 (Bill / invoice entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill.place_of_supply_state IS '[v4: CORE-002..009, IPB-006/008/009, TAR-010, GOV-007 (Bill / invoice entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill.cost_center_id IS '[v4: CORE-002..009, IPB-006/008/009, TAR-010, GOV-007 (Bill / invoice entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill.b2b_payer_id IS '[v4: CORE-002..009, IPB-006/008/009, TAR-010, GOV-007 (Bill / invoice entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill.scheme_code IS '[v4: CORE-002..009, IPB-006/008/009, TAR-010, GOV-007 (Bill / invoice entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill.print_count IS '[v4: CORE-002..009, IPB-006/008/009, TAR-010, GOV-007 (Bill / invoice entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill.e_invoice_ack_no IS '[v4: CORE-002..009, IPB-006/008/009, TAR-010, GOV-007 (Bill / invoice entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill.e_way_bill_no IS '[v4: CORE-002..009, IPB-006/008/009, TAR-010, GOV-007 (Bill / invoice entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill.corporate_invoice_id IS '[v4: CORE-002..009, IPB-006/008/009, TAR-010, GOV-007 (Bill / invoice entity)]';

-- revenuefinance.bil_bill_line  (14 new columns)  FDS: CORE-006/008, TAR-004/009/010, DOC-005, LAB-004 (Charge line entity)
ALTER TABLE revenuefinance.bil_bill_line ADD COLUMN IF NOT EXISTS source_module VARCHAR(20) NULL;
ALTER TABLE revenuefinance.bil_bill_line ADD COLUMN IF NOT EXISTS cost_center_id INT NULL;
ALTER TABLE revenuefinance.bil_bill_line ADD COLUMN IF NOT EXISTS is_package_extra BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE revenuefinance.bil_bill_line ADD COLUMN IF NOT EXISTS package_episode_id BIGINT NULL;
ALTER TABLE revenuefinance.bil_bill_line ADD COLUMN IF NOT EXISTS kit_id INT NULL;
ALTER TABLE revenuefinance.bil_bill_line ADD COLUMN IF NOT EXISTS discount_borne_by VARCHAR(10) NULL;
ALTER TABLE revenuefinance.bil_bill_line ADD COLUMN IF NOT EXISTS referring_practitioner_id BIGINT NULL;
ALTER TABLE revenuefinance.bil_bill_line ADD COLUMN IF NOT EXISTS outsource_cost DECIMAL(12,2) NULL;
ALTER TABLE revenuefinance.bil_bill_line ADD COLUMN IF NOT EXISTS batch_no VARCHAR(50) NULL;
ALTER TABLE revenuefinance.bil_bill_line ADD COLUMN IF NOT EXISTS expiry_date DATE NULL;
ALTER TABLE revenuefinance.bil_bill_line ADD COLUMN IF NOT EXISTS mrp DECIMAL(12,2) NULL;
ALTER TABLE revenuefinance.bil_bill_line ADD COLUMN IF NOT EXISTS copay_amount DECIMAL(12,2) NULL;
ALTER TABLE revenuefinance.bil_bill_line ADD COLUMN IF NOT EXISTS deductible_amount DECIMAL(12,2) NULL;
ALTER TABLE revenuefinance.bil_bill_line ADD COLUMN IF NOT EXISTS room_rent_proportionate_deduction DECIMAL(12,2) NULL;
COMMENT ON COLUMN revenuefinance.bil_bill_line.source_module IS 'OPD, IPD, OT, ER, LAB, RAD, PHARMACY, TELE, DIET, KIT [v4: CORE-006/008, TAR-004/009/010, DOC-005, LAB-004 (Charge line entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill_line.cost_center_id IS '[v4: CORE-006/008, TAR-004/009/010, DOC-005, LAB-004 (Charge line entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill_line.is_package_extra IS '[v4: CORE-006/008, TAR-004/009/010, DOC-005, LAB-004 (Charge line entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill_line.package_episode_id IS '[v4: CORE-006/008, TAR-004/009/010, DOC-005, LAB-004 (Charge line entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill_line.kit_id IS '[v4: CORE-006/008, TAR-004/009/010, DOC-005, LAB-004 (Charge line entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill_line.discount_borne_by IS 'HOSPITAL, DOCTOR, SHARED [v4: CORE-006/008, TAR-004/009/010, DOC-005, LAB-004 (Charge line entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill_line.referring_practitioner_id IS '[v4: CORE-006/008, TAR-004/009/010, DOC-005, LAB-004 (Charge line entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill_line.outsource_cost IS '[v4: CORE-006/008, TAR-004/009/010, DOC-005, LAB-004 (Charge line entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill_line.batch_no IS '[v4: CORE-006/008, TAR-004/009/010, DOC-005, LAB-004 (Charge line entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill_line.expiry_date IS '[v4: CORE-006/008, TAR-004/009/010, DOC-005, LAB-004 (Charge line entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill_line.mrp IS '[v4: CORE-006/008, TAR-004/009/010, DOC-005, LAB-004 (Charge line entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill_line.copay_amount IS '[v4: CORE-006/008, TAR-004/009/010, DOC-005, LAB-004 (Charge line entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill_line.deductible_amount IS '[v4: CORE-006/008, TAR-004/009/010, DOC-005, LAB-004 (Charge line entity)]';
COMMENT ON COLUMN revenuefinance.bil_bill_line.room_rent_proportionate_deduction IS '[v4: CORE-006/008, TAR-004/009/010, DOC-005, LAB-004 (Charge line entity)]';

-- revenuefinance.bil_credit_note  (7 new columns)  FDS: CORE-004/005, IPB-009, PHB-006, TAX-004
ALTER TABLE revenuefinance.bil_credit_note ADD COLUMN IF NOT EXISTS reason_code VARCHAR(30) NULL;
ALTER TABLE revenuefinance.bil_credit_note ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) NULL DEFAULT 'APPROVED';
ALTER TABLE revenuefinance.bil_credit_note ADD COLUMN IF NOT EXISTS requested_by BIGINT NULL;
ALTER TABLE revenuefinance.bil_credit_note ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ(0) NULL;
ALTER TABLE revenuefinance.bil_credit_note ADD COLUMN IF NOT EXISTS receipt_id BIGINT NULL;
ALTER TABLE revenuefinance.bil_credit_note ADD COLUMN IF NOT EXISTS document_id BIGINT NULL;
ALTER TABLE revenuefinance.bil_credit_note ADD COLUMN IF NOT EXISTS gst_reversal_amount DECIMAL(12,2) NULL;
COMMENT ON COLUMN revenuefinance.bil_credit_note.reason_code IS '[v4: CORE-004/005, IPB-009, PHB-006, TAX-004]';
COMMENT ON COLUMN revenuefinance.bil_credit_note.approval_status IS 'PENDING, APPROVED, REJECTED [v4: CORE-004/005, IPB-009, PHB-006, TAX-004]';
COMMENT ON COLUMN revenuefinance.bil_credit_note.requested_by IS '[v4: CORE-004/005, IPB-009, PHB-006, TAX-004]';
COMMENT ON COLUMN revenuefinance.bil_credit_note.approved_at IS '[v4: CORE-004/005, IPB-009, PHB-006, TAX-004]';
COMMENT ON COLUMN revenuefinance.bil_credit_note.receipt_id IS '[v4: CORE-004/005, IPB-009, PHB-006, TAX-004]';
COMMENT ON COLUMN revenuefinance.bil_credit_note.document_id IS '[v4: CORE-004/005, IPB-009, PHB-006, TAX-004]';
COMMENT ON COLUMN revenuefinance.bil_credit_note.gst_reversal_amount IS '[v4: CORE-004/005, IPB-009, PHB-006, TAX-004]';

-- revenuefinance.bil_doctor_payout  (5 new columns)  FDS: DOC-007..010
ALTER TABLE revenuefinance.bil_doctor_payout ADD COLUMN IF NOT EXISTS eligible_at TIMESTAMPTZ(0) NULL;
ALTER TABLE revenuefinance.bil_doctor_payout ADD COLUMN IF NOT EXISTS reversal_of_payout_id BIGINT NULL;
ALTER TABLE revenuefinance.bil_doctor_payout ADD COLUMN IF NOT EXISTS reversal_reason VARCHAR(300) NULL;
ALTER TABLE revenuefinance.bil_doctor_payout ADD COLUMN IF NOT EXISTS doctor_statement_id BIGINT NULL;
ALTER TABLE revenuefinance.bil_doctor_payout ADD COLUMN IF NOT EXISTS gl_accrual_voucher_id BIGINT NULL;
COMMENT ON COLUMN revenuefinance.bil_doctor_payout.eligible_at IS '[v4: DOC-007..010]';
COMMENT ON COLUMN revenuefinance.bil_doctor_payout.reversal_of_payout_id IS '[v4: DOC-007..010]';
COMMENT ON COLUMN revenuefinance.bil_doctor_payout.reversal_reason IS '[v4: DOC-007..010]';
COMMENT ON COLUMN revenuefinance.bil_doctor_payout.doctor_statement_id IS '[v4: DOC-007..010]';
COMMENT ON COLUMN revenuefinance.bil_doctor_payout.gl_accrual_voucher_id IS '[v4: DOC-007..010]';

-- revenuefinance.bil_doctor_payout_rule  (7 new columns)  FDS: DOC-002..006
ALTER TABLE revenuefinance.bil_doctor_payout_rule ADD COLUMN IF NOT EXISTS doctor_contract_id INT NULL;
ALTER TABLE revenuefinance.bil_doctor_payout_rule ADD COLUMN IF NOT EXISTS team_role VARCHAR(20) NULL;
ALTER TABLE revenuefinance.bil_doctor_payout_rule ADD COLUMN IF NOT EXISTS slab_from DECIMAL(14,2) NULL;
ALTER TABLE revenuefinance.bil_doctor_payout_rule ADD COLUMN IF NOT EXISTS slab_to DECIMAL(14,2) NULL;
ALTER TABLE revenuefinance.bil_doctor_payout_rule ADD COLUMN IF NOT EXISTS package_id INT NULL;
ALTER TABLE revenuefinance.bil_doctor_payout_rule ADD COLUMN IF NOT EXISTS is_referral_fee BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE revenuefinance.bil_doctor_payout_rule ADD COLUMN IF NOT EXISTS referral_agent_id INT NULL;
COMMENT ON COLUMN revenuefinance.bil_doctor_payout_rule.doctor_contract_id IS '[v4: DOC-002..006]';
COMMENT ON COLUMN revenuefinance.bil_doctor_payout_rule.team_role IS 'PRIMARY, SURGEON, ASSISTANT, ANAESTHETIST, REPORTING_RADIOLOGIST, TECHNICIAN [v4: DOC-002..006]';
COMMENT ON COLUMN revenuefinance.bil_doctor_payout_rule.slab_from IS '[v4: DOC-002..006]';
COMMENT ON COLUMN revenuefinance.bil_doctor_payout_rule.slab_to IS '[v4: DOC-002..006]';
COMMENT ON COLUMN revenuefinance.bil_doctor_payout_rule.package_id IS '[v4: DOC-002..006]';
COMMENT ON COLUMN revenuefinance.bil_doctor_payout_rule.is_referral_fee IS '[v4: DOC-002..006]';
COMMENT ON COLUMN revenuefinance.bil_doctor_payout_rule.referral_agent_id IS '[v4: DOC-002..006]';

-- revenuefinance.bil_loyalty_account  (5 new columns)  FDS: LOY-001, LOY-006, LOY-007 (Loyalty ledger entity)
ALTER TABLE revenuefinance.bil_loyalty_account ADD COLUMN IF NOT EXISTS member_no VARCHAR(30) NULL;
ALTER TABLE revenuefinance.bil_loyalty_account ADD COLUMN IF NOT EXISTS loyalty_tier_id INT NULL;
ALTER TABLE revenuefinance.bil_loyalty_account ADD COLUMN IF NOT EXISTS enrolled_at TIMESTAMPTZ(0) NULL;
ALTER TABLE revenuefinance.bil_loyalty_account ADD COLUMN IF NOT EXISTS enrol_channel VARCHAR(20) NULL;
ALTER TABLE revenuefinance.bil_loyalty_account ADD COLUMN IF NOT EXISTS points_liability_amount DECIMAL(14,2) NULL;
COMMENT ON COLUMN revenuefinance.bil_loyalty_account.member_no IS '[v4: LOY-001, LOY-006, LOY-007 (Loyalty ledger entity)]';
COMMENT ON COLUMN revenuefinance.bil_loyalty_account.loyalty_tier_id IS '[v4: LOY-001, LOY-006, LOY-007 (Loyalty ledger entity)]';
COMMENT ON COLUMN revenuefinance.bil_loyalty_account.enrolled_at IS '[v4: LOY-001, LOY-006, LOY-007 (Loyalty ledger entity)]';
COMMENT ON COLUMN revenuefinance.bil_loyalty_account.enrol_channel IS 'MANUAL, AUTO_FIRST_VISIT, APP [v4: LOY-001, LOY-006, LOY-007 (Loyalty ledger entity)]';
COMMENT ON COLUMN revenuefinance.bil_loyalty_account.points_liability_amount IS '[v4: LOY-001, LOY-006, LOY-007 (Loyalty ledger entity)]';

-- revenuefinance.bil_loyalty_txn  (5 new columns)  FDS: LOY-003, LOY-005, LOY-006
ALTER TABLE revenuefinance.bil_loyalty_txn ADD COLUMN IF NOT EXISTS loyalty_rule_id INT NULL;
ALTER TABLE revenuefinance.bil_loyalty_txn ADD COLUMN IF NOT EXISTS receipt_id BIGINT NULL;
ALTER TABLE revenuefinance.bil_loyalty_txn ADD COLUMN IF NOT EXISTS reversal_of_txn_id BIGINT NULL;
ALTER TABLE revenuefinance.bil_loyalty_txn ADD COLUMN IF NOT EXISTS balance_after INT NULL;
ALTER TABLE revenuefinance.bil_loyalty_txn ADD COLUMN IF NOT EXISTS otp_verified BOOLEAN NULL DEFAULT FALSE;
COMMENT ON COLUMN revenuefinance.bil_loyalty_txn.loyalty_rule_id IS '[v4: LOY-003, LOY-005, LOY-006]';
COMMENT ON COLUMN revenuefinance.bil_loyalty_txn.receipt_id IS '[v4: LOY-003, LOY-005, LOY-006]';
COMMENT ON COLUMN revenuefinance.bil_loyalty_txn.reversal_of_txn_id IS '[v4: LOY-003, LOY-005, LOY-006]';
COMMENT ON COLUMN revenuefinance.bil_loyalty_txn.balance_after IS '[v4: LOY-003, LOY-005, LOY-006]';
COMMENT ON COLUMN revenuefinance.bil_loyalty_txn.otp_verified IS '[v4: LOY-003, LOY-005, LOY-006]';

-- revenuefinance.bil_receipt  (6 new columns)  FDS: PAY-004/006/008/009, ACC-001
ALTER TABLE revenuefinance.bil_receipt ADD COLUMN IF NOT EXISTS cashier_shift_id BIGINT NULL;
ALTER TABLE revenuefinance.bil_receipt ADD COLUMN IF NOT EXISTS patient_account_id BIGINT NULL;
ALTER TABLE revenuefinance.bil_receipt ADD COLUMN IF NOT EXISTS payer_pan_no VARCHAR(10) NULL;
ALTER TABLE revenuefinance.bil_receipt ADD COLUMN IF NOT EXISTS print_count SMALLINT NULL DEFAULT 0;
ALTER TABLE revenuefinance.bil_receipt ADD COLUMN IF NOT EXISTS delivery_channels VARCHAR(50) NULL;
ALTER TABLE revenuefinance.bil_receipt ADD COLUMN IF NOT EXISTS tds_deducted_by_payer DECIMAL(12,2) NULL;
COMMENT ON COLUMN revenuefinance.bil_receipt.cashier_shift_id IS '[v4: PAY-004/006/008/009, ACC-001]';
COMMENT ON COLUMN revenuefinance.bil_receipt.patient_account_id IS '[v4: PAY-004/006/008/009, ACC-001]';
COMMENT ON COLUMN revenuefinance.bil_receipt.payer_pan_no IS 'PAN capture above cash threshold [v4: PAY-004/006/008/009, ACC-001]';
COMMENT ON COLUMN revenuefinance.bil_receipt.print_count IS '[v4: PAY-004/006/008/009, ACC-001]';
COMMENT ON COLUMN revenuefinance.bil_receipt.delivery_channels IS 'PRINT, PDF, SMS, EMAIL, WHATSAPP [v4: PAY-004/006/008/009, ACC-001]';
COMMENT ON COLUMN revenuefinance.bil_receipt.tds_deducted_by_payer IS 'TAX-006 TDS receivable [v4: PAY-004/006/008/009, ACC-001]';

-- revenuefinance.bil_receipt_tender  (9 new columns)  FDS: PAY-001..003 (mode-specific details, cheque lifecycle), LOY-005
ALTER TABLE revenuefinance.bil_receipt_tender ADD COLUMN IF NOT EXISTS auth_code VARCHAR(30) NULL;
ALTER TABLE revenuefinance.bil_receipt_tender ADD COLUMN IF NOT EXISTS upi_txn_id VARCHAR(50) NULL;
ALTER TABLE revenuefinance.bil_receipt_tender ADD COLUMN IF NOT EXISTS cheque_status VARCHAR(20) NULL;
ALTER TABLE revenuefinance.bil_receipt_tender ADD COLUMN IF NOT EXISTS deposited_at TIMESTAMPTZ(0) NULL;
ALTER TABLE revenuefinance.bil_receipt_tender ADD COLUMN IF NOT EXISTS cleared_at TIMESTAMPTZ(0) NULL;
ALTER TABLE revenuefinance.bil_receipt_tender ADD COLUMN IF NOT EXISTS bounced_at TIMESTAMPTZ(0) NULL;
ALTER TABLE revenuefinance.bil_receipt_tender ADD COLUMN IF NOT EXISTS bounce_charge DECIMAL(10,2) NULL;
ALTER TABLE revenuefinance.bil_receipt_tender ADD COLUMN IF NOT EXISTS loyalty_points_redeemed INT NULL;
ALTER TABLE revenuefinance.bil_receipt_tender ADD COLUMN IF NOT EXISTS pos_terminal_id VARCHAR(30) NULL;
COMMENT ON COLUMN revenuefinance.bil_receipt_tender.auth_code IS '[v4: PAY-001..003 (mode-specific details, cheque lifecycle), LOY-005]';
COMMENT ON COLUMN revenuefinance.bil_receipt_tender.upi_txn_id IS '[v4: PAY-001..003 (mode-specific details, cheque lifecycle), LOY-005]';
COMMENT ON COLUMN revenuefinance.bil_receipt_tender.cheque_status IS 'RECEIVED, DEPOSITED, CLEARED, BOUNCED [v4: PAY-001..003 (mode-specific details, cheque lifecycle), LOY-005]';
COMMENT ON COLUMN revenuefinance.bil_receipt_tender.deposited_at IS '[v4: PAY-001..003 (mode-specific details, cheque lifecycle), LOY-005]';
COMMENT ON COLUMN revenuefinance.bil_receipt_tender.cleared_at IS '[v4: PAY-001..003 (mode-specific details, cheque lifecycle), LOY-005]';
COMMENT ON COLUMN revenuefinance.bil_receipt_tender.bounced_at IS '[v4: PAY-001..003 (mode-specific details, cheque lifecycle), LOY-005]';
COMMENT ON COLUMN revenuefinance.bil_receipt_tender.bounce_charge IS '[v4: PAY-001..003 (mode-specific details, cheque lifecycle), LOY-005]';
COMMENT ON COLUMN revenuefinance.bil_receipt_tender.loyalty_points_redeemed IS '[v4: PAY-001..003 (mode-specific details, cheque lifecycle), LOY-005]';
COMMENT ON COLUMN revenuefinance.bil_receipt_tender.pos_terminal_id IS '[v4: PAY-001..003 (mode-specific details, cheque lifecycle), LOY-005]';

-- revenuefinance.fin_budget  (5 new columns)  FDS: MIS-004, CON-004
ALTER TABLE revenuefinance.fin_budget ADD COLUMN IF NOT EXISTS department_id INT NULL;
ALTER TABLE revenuefinance.fin_budget ADD COLUMN IF NOT EXISTS revision_no SMALLINT NULL DEFAULT 0;
ALTER TABLE revenuefinance.fin_budget ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) NULL DEFAULT 'APPROVED';
ALTER TABLE revenuefinance.fin_budget ADD COLUMN IF NOT EXISTS approved_by BIGINT NULL;
ALTER TABLE revenuefinance.fin_budget ADD COLUMN IF NOT EXISTS budget_type VARCHAR(20) NULL DEFAULT 'EXPENSE';
COMMENT ON COLUMN revenuefinance.fin_budget.department_id IS '[v4: MIS-004, CON-004]';
COMMENT ON COLUMN revenuefinance.fin_budget.revision_no IS '[v4: MIS-004, CON-004]';
COMMENT ON COLUMN revenuefinance.fin_budget.approval_status IS '[v4: MIS-004, CON-004]';
COMMENT ON COLUMN revenuefinance.fin_budget.approved_by IS '[v4: MIS-004, CON-004]';
COMMENT ON COLUMN revenuefinance.fin_budget.budget_type IS 'REVENUE, EXPENSE, CONSUMPTION, CAPEX [v4: MIS-004, CON-004]';

-- revenuefinance.fin_voucher  (10 new columns)  FDS: VCH-001..007 (Voucher entity), ACC-007, DOC-008
ALTER TABLE revenuefinance.fin_voucher ADD COLUMN IF NOT EXISTS store_id INT NULL;
ALTER TABLE revenuefinance.fin_voucher ADD COLUMN IF NOT EXISTS cost_center_id INT NULL;
ALTER TABLE revenuefinance.fin_voucher ADD COLUMN IF NOT EXISTS party_type VARCHAR(20) NULL;
ALTER TABLE revenuefinance.fin_voucher ADD COLUMN IF NOT EXISTS party_id BIGINT NULL;
ALTER TABLE revenuefinance.fin_voucher ADD COLUMN IF NOT EXISTS payment_mode VARCHAR(20) NULL;
ALTER TABLE revenuefinance.fin_voucher ADD COLUMN IF NOT EXISTS bank_account_id INT NULL;
ALTER TABLE revenuefinance.fin_voucher ADD COLUMN IF NOT EXISTS instrument_no VARCHAR(30) NULL;
ALTER TABLE revenuefinance.fin_voucher ADD COLUMN IF NOT EXISTS posting_status VARCHAR(20) NULL DEFAULT 'POSTED';
ALTER TABLE revenuefinance.fin_voucher ADD COLUMN IF NOT EXISTS cancelled_by_voucher_id BIGINT NULL;
ALTER TABLE revenuefinance.fin_voucher ADD COLUMN IF NOT EXISTS prepared_by BIGINT NULL;
COMMENT ON COLUMN revenuefinance.fin_voucher.store_id IS 'operationssupply.mst_store / pharmacy store series [v4: VCH-001..007 (Voucher entity), ACC-007, DOC-008]';
COMMENT ON COLUMN revenuefinance.fin_voucher.cost_center_id IS '[v4: VCH-001..007 (Voucher entity), ACC-007, DOC-008]';
COMMENT ON COLUMN revenuefinance.fin_voucher.party_type IS '[v4: VCH-001..007 (Voucher entity), ACC-007, DOC-008]';
COMMENT ON COLUMN revenuefinance.fin_voucher.party_id IS '[v4: VCH-001..007 (Voucher entity), ACC-007, DOC-008]';
COMMENT ON COLUMN revenuefinance.fin_voucher.payment_mode IS '[v4: VCH-001..007 (Voucher entity), ACC-007, DOC-008]';
COMMENT ON COLUMN revenuefinance.fin_voucher.bank_account_id IS '[v4: VCH-001..007 (Voucher entity), ACC-007, DOC-008]';
COMMENT ON COLUMN revenuefinance.fin_voucher.instrument_no IS '[v4: VCH-001..007 (Voucher entity), ACC-007, DOC-008]';
COMMENT ON COLUMN revenuefinance.fin_voucher.posting_status IS 'DRAFT, PENDING_APPROVAL, POSTED, CANCELLED [v4: VCH-001..007 (Voucher entity), ACC-007, DOC-008]';
COMMENT ON COLUMN revenuefinance.fin_voucher.cancelled_by_voucher_id IS '[v4: VCH-001..007 (Voucher entity), ACC-007, DOC-008]';
COMMENT ON COLUMN revenuefinance.fin_voucher.prepared_by IS '[v4: VCH-001..007 (Voucher entity), ACC-007, DOC-008]';

-- revenuefinance.ins_claim  (10 new columns)  FDS: INS-008..015, GOV-002/005 (Claim entity)
ALTER TABLE revenuefinance.ins_claim ADD COLUMN IF NOT EXISTS acknowledged_at TIMESTAMPTZ(0) NULL;
ALTER TABLE revenuefinance.ins_claim ADD COLUMN IF NOT EXISTS sla_due_at TIMESTAMPTZ(0) NULL;
ALTER TABLE revenuefinance.ins_claim ADD COLUMN IF NOT EXISTS escalated_at TIMESTAMPTZ(0) NULL;
ALTER TABLE revenuefinance.ins_claim ADD COLUMN IF NOT EXISTS short_paid_amount DECIMAL(14,2) NULL;
ALTER TABLE revenuefinance.ins_claim ADD COLUMN IF NOT EXISTS patient_share_amount DECIMAL(14,2) NULL;
ALTER TABLE revenuefinance.ins_claim ADD COLUMN IF NOT EXISTS patient_share_collected DECIMAL(14,2) NULL;
ALTER TABLE revenuefinance.ins_claim ADD COLUMN IF NOT EXISTS coding_task_id BIGINT NULL;
ALTER TABLE revenuefinance.ins_claim ADD COLUMN IF NOT EXISTS coding_status VARCHAR(20) NULL;
ALTER TABLE revenuefinance.ins_claim ADD COLUMN IF NOT EXISTS claim_pack_document_id BIGINT NULL;
ALTER TABLE revenuefinance.ins_claim ADD COLUMN IF NOT EXISTS checklist_complete BOOLEAN NULL DEFAULT FALSE;
COMMENT ON COLUMN revenuefinance.ins_claim.acknowledged_at IS '[v4: INS-008..015, GOV-002/005 (Claim entity)]';
COMMENT ON COLUMN revenuefinance.ins_claim.sla_due_at IS '[v4: INS-008..015, GOV-002/005 (Claim entity)]';
COMMENT ON COLUMN revenuefinance.ins_claim.escalated_at IS '[v4: INS-008..015, GOV-002/005 (Claim entity)]';
COMMENT ON COLUMN revenuefinance.ins_claim.short_paid_amount IS '[v4: INS-008..015, GOV-002/005 (Claim entity)]';
COMMENT ON COLUMN revenuefinance.ins_claim.patient_share_amount IS '[v4: INS-008..015, GOV-002/005 (Claim entity)]';
COMMENT ON COLUMN revenuefinance.ins_claim.patient_share_collected IS '[v4: INS-008..015, GOV-002/005 (Claim entity)]';
COMMENT ON COLUMN revenuefinance.ins_claim.coding_task_id IS 'clinicalcare.cod_coding_task [v4: INS-008..015, GOV-002/005 (Claim entity)]';
COMMENT ON COLUMN revenuefinance.ins_claim.coding_status IS '[v4: INS-008..015, GOV-002/005 (Claim entity)]';
COMMENT ON COLUMN revenuefinance.ins_claim.claim_pack_document_id IS '[v4: INS-008..015, GOV-002/005 (Claim entity)]';
COMMENT ON COLUMN revenuefinance.ins_claim.checklist_complete IS '[v4: INS-008..015, GOV-002/005 (Claim entity)]';

-- revenuefinance.ins_claim_denial  (3 new columns)  FDS: INS-014, INS-015
ALTER TABLE revenuefinance.ins_claim_denial ADD COLUMN IF NOT EXISTS denial_category VARCHAR(20) NULL;
ALTER TABLE revenuefinance.ins_claim_denial ADD COLUMN IF NOT EXISTS department_id INT NULL;
ALTER TABLE revenuefinance.ins_claim_denial ADD COLUMN IF NOT EXISTS practitioner_id BIGINT NULL;
COMMENT ON COLUMN revenuefinance.ins_claim_denial.denial_category IS 'MEDICAL, DOCUMENTATION, ELIGIBILITY, CODING, TARIFF [v4: INS-014, INS-015]';
COMMENT ON COLUMN revenuefinance.ins_claim_denial.department_id IS '[v4: INS-014, INS-015]';
COMMENT ON COLUMN revenuefinance.ins_claim_denial.practitioner_id IS '[v4: INS-014, INS-015]';

-- revenuefinance.ins_preauth  (10 new columns)  FDS: INS-006..007, GOV-002/003 (Pre-auth entity)
ALTER TABLE revenuefinance.ins_preauth ADD COLUMN IF NOT EXISTS claim_mode VARCHAR(20) NULL;
ALTER TABLE revenuefinance.ins_preauth ADD COLUMN IF NOT EXISTS procedure_code_id BIGINT NULL;
ALTER TABLE revenuefinance.ins_preauth ADD COLUMN IF NOT EXISTS treating_practitioner_id BIGINT NULL;
ALTER TABLE revenuefinance.ins_preauth ADD COLUMN IF NOT EXISTS estimated_cost DECIMAL(14,2) NULL;
ALTER TABLE revenuefinance.ins_preauth ADD COLUMN IF NOT EXISTS expected_los_days SMALLINT NULL;
ALTER TABLE revenuefinance.ins_preauth ADD COLUMN IF NOT EXISTS enhancement_of_preauth_id BIGINT NULL;
ALTER TABLE revenuefinance.ins_preauth ADD COLUMN IF NOT EXISTS query_text VARCHAR(2000) NULL;
ALTER TABLE revenuefinance.ins_preauth ADD COLUMN IF NOT EXISTS query_response VARCHAR(2000) NULL;
ALTER TABLE revenuefinance.ins_preauth ADD COLUMN IF NOT EXISTS sla_due_at TIMESTAMPTZ(0) NULL;
ALTER TABLE revenuefinance.ins_preauth ADD COLUMN IF NOT EXISTS scheme_case_no VARCHAR(50) NULL;
COMMENT ON COLUMN revenuefinance.ins_preauth.claim_mode IS 'CASHLESS, REIMBURSEMENT [v4: INS-006..007, GOV-002/003 (Pre-auth entity)]';
COMMENT ON COLUMN revenuefinance.ins_preauth.procedure_code_id IS '[v4: INS-006..007, GOV-002/003 (Pre-auth entity)]';
COMMENT ON COLUMN revenuefinance.ins_preauth.treating_practitioner_id IS '[v4: INS-006..007, GOV-002/003 (Pre-auth entity)]';
COMMENT ON COLUMN revenuefinance.ins_preauth.estimated_cost IS '[v4: INS-006..007, GOV-002/003 (Pre-auth entity)]';
COMMENT ON COLUMN revenuefinance.ins_preauth.expected_los_days IS '[v4: INS-006..007, GOV-002/003 (Pre-auth entity)]';
COMMENT ON COLUMN revenuefinance.ins_preauth.enhancement_of_preauth_id IS '[v4: INS-006..007, GOV-002/003 (Pre-auth entity)]';
COMMENT ON COLUMN revenuefinance.ins_preauth.query_text IS '[v4: INS-006..007, GOV-002/003 (Pre-auth entity)]';
COMMENT ON COLUMN revenuefinance.ins_preauth.query_response IS '[v4: INS-006..007, GOV-002/003 (Pre-auth entity)]';
COMMENT ON COLUMN revenuefinance.ins_preauth.sla_due_at IS '[v4: INS-006..007, GOV-002/003 (Pre-auth entity)]';
COMMENT ON COLUMN revenuefinance.ins_preauth.scheme_case_no IS 'Aarogyasri / PM-JAY case registration [v4: INS-006..007, GOV-002/003 (Pre-auth entity)]';

-- revenuefinance.mst_coupon  (4 new columns)  FDS: TAR-006, TAR-007, CHK-003
ALTER TABLE revenuefinance.mst_coupon ADD COLUMN IF NOT EXISTS book_no VARCHAR(30) NULL;
ALTER TABLE revenuefinance.mst_coupon ADD COLUMN IF NOT EXISTS issued_to_patient_id BIGINT NULL;
ALTER TABLE revenuefinance.mst_coupon ADD COLUMN IF NOT EXISTS issued_channel VARCHAR(20) NULL;
ALTER TABLE revenuefinance.mst_coupon ADD COLUMN IF NOT EXISTS coupon_status VARCHAR(20) NULL DEFAULT 'ACTIVE';
COMMENT ON COLUMN revenuefinance.mst_coupon.book_no IS '[v4: TAR-006, TAR-007, CHK-003]';
COMMENT ON COLUMN revenuefinance.mst_coupon.issued_to_patient_id IS '[v4: TAR-006, TAR-007, CHK-003]';
COMMENT ON COLUMN revenuefinance.mst_coupon.issued_channel IS '[v4: TAR-006, TAR-007, CHK-003]';
COMMENT ON COLUMN revenuefinance.mst_coupon.coupon_status IS 'ACTIVE, REDEEMED, EXPIRED, CANCELLED [v4: TAR-006, TAR-007, CHK-003]';

-- revenuefinance.mst_discount_scheme  (5 new columns)  FDS: TAR-006, TAR-008, MKT-012
ALTER TABLE revenuefinance.mst_discount_scheme ADD COLUMN IF NOT EXISTS series_prefix VARCHAR(10) NULL;
ALTER TABLE revenuefinance.mst_discount_scheme ADD COLUMN IF NOT EXISTS per_patient_limit SMALLINT NULL;
ALTER TABLE revenuefinance.mst_discount_scheme ADD COLUMN IF NOT EXISTS per_channel_limit_json JSONB NULL;
ALTER TABLE revenuefinance.mst_discount_scheme ADD COLUMN IF NOT EXISTS applicable_channels VARCHAR(100) NULL;
ALTER TABLE revenuefinance.mst_discount_scheme ADD COLUMN IF NOT EXISTS campaign_id BIGINT NULL;
COMMENT ON COLUMN revenuefinance.mst_discount_scheme.series_prefix IS '[v4: TAR-006, TAR-008, MKT-012]';
COMMENT ON COLUMN revenuefinance.mst_discount_scheme.per_patient_limit IS '[v4: TAR-006, TAR-008, MKT-012]';
COMMENT ON COLUMN revenuefinance.mst_discount_scheme.per_channel_limit_json IS '[v4: TAR-006, TAR-008, MKT-012]';
COMMENT ON COLUMN revenuefinance.mst_discount_scheme.applicable_channels IS '[v4: TAR-006, TAR-008, MKT-012]';
COMMENT ON COLUMN revenuefinance.mst_discount_scheme.campaign_id IS '[v4: TAR-006, TAR-008, MKT-012]';

-- revenuefinance.mst_package  (7 new columns)  FDS: TAR-003..005, GOV-002/004
ALTER TABLE revenuefinance.mst_package ADD COLUMN IF NOT EXISTS package_name VARCHAR(200) NULL;
ALTER TABLE revenuefinance.mst_package ADD COLUMN IF NOT EXISTS inclusions_text TEXT NULL;
ALTER TABLE revenuefinance.mst_package ADD COLUMN IF NOT EXISTS exclusions_text TEXT NULL;
ALTER TABLE revenuefinance.mst_package ADD COLUMN IF NOT EXISTS copay_rule_id INT NULL;
ALTER TABLE revenuefinance.mst_package ADD COLUMN IF NOT EXISTS allows_upgrade BOOLEAN NULL DEFAULT TRUE;
ALTER TABLE revenuefinance.mst_package ADD COLUMN IF NOT EXISTS max_extension_days SMALLINT NULL;
ALTER TABLE revenuefinance.mst_package ADD COLUMN IF NOT EXISTS is_rate_locked BOOLEAN NULL DEFAULT FALSE;
COMMENT ON COLUMN revenuefinance.mst_package.package_name IS '[v4: TAR-003..005, GOV-002/004]';
COMMENT ON COLUMN revenuefinance.mst_package.inclusions_text IS '[v4: TAR-003..005, GOV-002/004]';
COMMENT ON COLUMN revenuefinance.mst_package.exclusions_text IS '[v4: TAR-003..005, GOV-002/004]';
COMMENT ON COLUMN revenuefinance.mst_package.copay_rule_id IS '[v4: TAR-003..005, GOV-002/004]';
COMMENT ON COLUMN revenuefinance.mst_package.allows_upgrade IS '[v4: TAR-003..005, GOV-002/004]';
COMMENT ON COLUMN revenuefinance.mst_package.max_extension_days IS '[v4: TAR-003..005, GOV-002/004]';
COMMENT ON COLUMN revenuefinance.mst_package.is_rate_locked IS 'scheme package rates [v4: TAR-003..005, GOV-002/004]';

-- revenuefinance.mst_tariff_plan  (6 new columns)  FDS: TAR-001, TAR-002
ALTER TABLE revenuefinance.mst_tariff_plan ADD COLUMN IF NOT EXISTS payer_class VARCHAR(20) NULL;
ALTER TABLE revenuefinance.mst_tariff_plan ADD COLUMN IF NOT EXISTS bed_category VARCHAR(30) NULL;
ALTER TABLE revenuefinance.mst_tariff_plan ADD COLUMN IF NOT EXISTS version_no SMALLINT NULL DEFAULT 1;
ALTER TABLE revenuefinance.mst_tariff_plan ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) NULL DEFAULT 'APPROVED';
ALTER TABLE revenuefinance.mst_tariff_plan ADD COLUMN IF NOT EXISTS approved_by BIGINT NULL;
ALTER TABLE revenuefinance.mst_tariff_plan ADD COLUMN IF NOT EXISTS bulk_import_job_id BIGINT NULL;
COMMENT ON COLUMN revenuefinance.mst_tariff_plan.payer_class IS '[v4: TAR-001, TAR-002]';
COMMENT ON COLUMN revenuefinance.mst_tariff_plan.bed_category IS '[v4: TAR-001, TAR-002]';
COMMENT ON COLUMN revenuefinance.mst_tariff_plan.version_no IS '[v4: TAR-001, TAR-002]';
COMMENT ON COLUMN revenuefinance.mst_tariff_plan.approval_status IS '[v4: TAR-001, TAR-002]';
COMMENT ON COLUMN revenuefinance.mst_tariff_plan.approved_by IS '[v4: TAR-001, TAR-002]';
COMMENT ON COLUMN revenuefinance.mst_tariff_plan.bulk_import_job_id IS '[v4: TAR-001, TAR-002]';

-- revenuefinance.mst_tariff_rate  (2 new columns)  FDS: TAR-001
ALTER TABLE revenuefinance.mst_tariff_rate ADD COLUMN IF NOT EXISTS version_no SMALLINT NULL DEFAULT 1;
ALTER TABLE revenuefinance.mst_tariff_rate ADD COLUMN IF NOT EXISTS previous_rate DECIMAL(12,2) NULL;
COMMENT ON COLUMN revenuefinance.mst_tariff_rate.version_no IS '[v4: TAR-001]';
COMMENT ON COLUMN revenuefinance.mst_tariff_rate.previous_rate IS '[v4: TAR-001]';

/* ---------- B. NEW TABLES ---------- */

-- ===== HIS Billing & RCM FRD v0.2 =====
-- [NEW v4] FDS ref: CORE-001, CORE-003, IPB-001 (Patient account entity)
CREATE TABLE IF NOT EXISTS revenuefinance.bil_patient_account (               -- Visit-level patient account to which all modules post charges (UHID, visit, payer class, status, balance)
    patient_account_id         BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    account_no                 VARCHAR(30) NOT NULL UNIQUE,
    patient_id                 BIGINT NOT NULL,                                -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    encounter_id               BIGINT NULL,                                    -- logical FK -> patientengagement.pat_encounter [Patient Access & Engagement]
    admission_id               BIGINT NULL,                                    -- logical FK -> patientengagement.adt_admission [Patient Access & Engagement]
    payer_class                VARCHAR(20) NOT NULL,                           -- SELF, CORPORATE, INSURANCE, SCHEME, B2B
    primary_payer_id           INT NULL,
    tariff_plan_id             INT NULL,
    estimate_id                BIGINT NULL,
    total_charges              DECIMAL(14,2) NOT NULL DEFAULT 0,
    total_payer_share          DECIMAL(14,2) NOT NULL DEFAULT 0,
    total_patient_share        DECIMAL(14,2) NOT NULL DEFAULT 0,
    deposit_balance            DECIMAL(14,2) NOT NULL DEFAULT 0,
    balance_due                DECIMAL(14,2) NOT NULL DEFAULT 0,
    authorised_limit           DECIMAL(14,2) NULL,
    is_mlc                     BOOLEAN NOT NULL DEFAULT FALSE,
    hold_status                VARCHAR(20) NULL,                               -- NONE, INSURANCE_HOLD, CORPORATE_HOLD, PROVISIONAL_DISCHARGE
    account_status             VARCHAR(20) NOT NULL DEFAULT 'OPEN',            -- OPEN, INTERIM_BILLED, FINAL_BILLED, SETTLED, CLOSED, WRITTEN_OFF
    opened_at                  TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at                  TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: CORE-009
CREATE TABLE IF NOT EXISTS revenuefinance.bil_bill_number_void (              -- Gaps in bill / receipt number series with recorded reason
    bill_number_void_id        BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    document_type              VARCHAR(20) NOT NULL,                           -- BILL, RECEIPT, CREDIT_NOTE, VOUCHER
    number_value               VARCHAR(30) NOT NULL,
    reason                     VARCHAR(300) NOT NULL,
    voided_by                  BIGINT NOT NULL,
    voided_at                  TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: PAY-004, PAY-007
CREATE TABLE IF NOT EXISTS revenuefinance.bil_cashier_shift (                 -- Cashier shifts: opening float, mode-wise collections, handover, closing, variance approval
    cashier_shift_id           BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    counter_code               VARCHAR(20) NOT NULL,
    cashier_id                 BIGINT NOT NULL,                                -- logical FK -> identityorg.hr_employee [Identity & Organization]
    opened_at                  TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    opening_float              DECIMAL(12,2) NOT NULL DEFAULT 0,
    closed_at                  TIMESTAMPTZ(0) NULL,
    collections_json           JSONB NULL,                                     -- amount by payment mode
    system_total               DECIMAL(14,2) NULL,
    declared_total             DECIMAL(14,2) NULL,
    variance_amount            DECIMAL(12,2) NULL,
    handed_over_to             BIGINT NULL,
    supervisor_approved_by     BIGINT NULL,
    shift_status               VARCHAR(20) NOT NULL DEFAULT 'OPEN',            -- OPEN, CLOSED, APPROVED
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: ACC-001, IPB-001
CREATE TABLE IF NOT EXISTS revenuefinance.bil_deposit_request (               -- Deposit top-up requests and minimum-deposit alerts
    deposit_request_id         BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    patient_account_id         BIGINT NOT NULL,
    requested_amount           DECIMAL(12,2) NOT NULL,
    reason                     VARCHAR(300) NULL,
    requested_by               BIGINT NULL,
    requested_at               TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    receipt_id                 BIGINT NULL,
    request_status             VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: ACC-002..005, ORD-008, MFF-004, DSC-CAN-004, LAB-006, OPB-003/004
CREATE TABLE IF NOT EXISTS revenuefinance.bil_refund_request (                -- Refund requests linked to bill / receipt with approval by amount hierarchy (includes gateway refunds)
    refund_request_id          BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    refund_no                  VARCHAR(30) NOT NULL UNIQUE,
    patient_id                 BIGINT NULL,                                    -- logical FK -> patientengagement.pat_patient [Patient Access & Engagement]
    bill_id                    BIGINT NULL,
    receipt_id                 BIGINT NULL,
    payment_gateway_txn_id     BIGINT NULL,
    source_type                VARCHAR(20) NOT NULL,                           -- DEPOSIT, CANCELLATION, RETURN, OVERPAYMENT, ONLINE_ORDER, TELE_FAILURE
    source_ref_id              BIGINT NULL,
    reason_code                VARCHAR(30) NOT NULL,
    requested_amount           DECIMAL(12,2) NOT NULL,
    approved_amount            DECIMAL(12,2) NULL,
    refund_mode                VARCHAR(20) NULL,                               -- ORIGINAL_MODE, CASH, NEFT, UPI
    gateway_refund_id          VARCHAR(100) NULL,
    requested_by               BIGINT NOT NULL,
    approved_by                BIGINT NULL,
    approved_at                TIMESTAMPTZ(0) NULL,
    refunded_at                TIMESTAMPTZ(0) NULL,
    refund_status              VARCHAR(20) NOT NULL DEFAULT 'REQUESTED',       -- REQUESTED, APPROVED, REJECTED, PROCESSING, REFUNDED, FAILED
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: PAY-005, CHK-005
CREATE TABLE IF NOT EXISTS revenuefinance.bil_payment_gateway_event (         -- Gateway callbacks / polling results (server-to-server verification)
    payment_gateway_event_id   BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    payment_gateway_txn_id     BIGINT NOT NULL,
    event_type                 VARCHAR(20) NOT NULL,                           -- CALLBACK, POLL, WEBHOOK, REFUND_CALLBACK
    gateway_status             VARCHAR(30) NULL,
    signature_valid            BOOLEAN NULL,
    payload_json               JSONB NULL,
    received_at                TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LAB-006, OPB-003, ORD-006, DSC-CAN-004, TSL-005
CREATE TABLE IF NOT EXISTS revenuefinance.bil_cancellation_policy (           -- Cancellation / refund policy by service category and order stage
    cancellation_policy_id     INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    service_category_id        INT NULL,
    service_line               VARCHAR(20) NULL,
    order_stage                VARCHAR(30) NOT NULL,                           -- BEFORE_CUTOFF, AFTER_CUTOFF, BEFORE_COLLECTION, AFTER_COLLECTION, AFTER_RESULT, NO_SHOW
    refund_pct                 DECIMAL(5,2) NOT NULL,
    fixed_deduction            DECIMAL(10,2) NULL,
    needs_approval             BOOLEAN NOT NULL DEFAULT FALSE,
    cutoff_minutes             INT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: OPB-002, OBK-008, BKG-003
CREATE TABLE IF NOT EXISTS revenuefinance.bil_followup_rule (                 -- Free follow-up validity window per doctor / specialty
    followup_rule_id           INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    practitioner_id            BIGINT NULL,                                    -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    specialty_id               INT NULL,                                       -- logical FK -> identityorg.mst_specialty [Identity & Organization]
    validity_days              SMALLINT NOT NULL,
    free_visits                SMALLINT NOT NULL DEFAULT 1,
    applies_to_visit_types     VARCHAR(100) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: IPB-002
CREATE TABLE IF NOT EXISTS revenuefinance.bil_recurring_charge_rule (         -- Recurring IP charges (bed rent, nursing, monitoring) with day cut-off and prorating
    recurring_charge_rule_id   INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    service_id                 INT NOT NULL,
    room_category              VARCHAR(30) NULL,
    charge_basis               VARCHAR(20) NOT NULL,                           -- PER_DAY, PER_HOUR, PER_SHIFT
    day_cutoff_time            TIME NULL,
    prorate_on_transfer        BOOLEAN NOT NULL DEFAULT TRUE,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: IPB-004, DOC-006
CREATE TABLE IF NOT EXISTS revenuefinance.bil_surgery_fee_rule (              -- OT fee rules: surgeon / anaesthetist / assistant shares and multiple-procedure rules
    surgery_fee_rule_id        INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    rule_name                  VARCHAR(100) NOT NULL,
    team_role                  VARCHAR(20) NOT NULL,                           -- SURGEON, ASSISTANT, ANAESTHETIST, THEATRE
    calc_type                  VARCHAR(10) NOT NULL,                           -- PERCENT, FIXED
    calc_value                 DECIMAL(10,2) NOT NULL,
    procedure_sequence         SMALLINT NULL,                                  -- 1 = primary, 2 = second procedure ...
    sequence_pct               DECIMAL(5,2) NULL,                              -- e.g. 50% for second procedure
    payer_type                 VARCHAR(20) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TAR-003
CREATE TABLE IF NOT EXISTS revenuefinance.mst_package_payer (                 -- Applicable payers for a package
    package_payer_id           INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    package_id                 INT NOT NULL,
    payer_id                   INT NOT NULL,
    payer_price                DECIMAL(12,2) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT                 uq_mst_package_payer_1 UNIQUE (package_id, payer_id)
);

-- [NEW v4] FDS ref: TAR-004, TAR-005, IPB-006
CREATE TABLE IF NOT EXISTS revenuefinance.bil_package_episode (               -- Package applied to an episode: consumption vs inclusions, upgrade / downgrade / extension
    package_episode_id         BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    patient_account_id         BIGINT NOT NULL,
    package_id                 INT NOT NULL,
    applied_at                 TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    package_amount             DECIMAL(12,2) NOT NULL,
    consumed_amount            DECIMAL(12,2) NOT NULL DEFAULT 0,
    extras_amount              DECIMAL(12,2) NOT NULL DEFAULT 0,
    changed_from_package_id    INT NULL,
    change_type                VARCHAR(20) NULL,                               -- UPGRADE, DOWNGRADE, EXTENSION
    change_reason              VARCHAR(300) NULL,
    episode_status             VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TAR-007, TAR-008
CREATE TABLE IF NOT EXISTS revenuefinance.bil_coupon_redemption (             -- Coupon validation, redemption and reversal with audit
    coupon_redemption_id       BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    coupon_id                  INT NOT NULL,
    bill_id                    BIGINT NULL,
    online_order_id            BIGINT NULL,                                    -- logical FK -> patientengagement.ecom_online_order [Patient Access & Engagement]
    patient_id                 BIGINT NULL,
    discount_amount            DECIMAL(12,2) NOT NULL,
    redeemed_at                TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reversed_at                TIMESTAMPTZ(0) NULL,
    reversal_reason            VARCHAR(300) NULL,
    coupon_restored            BOOLEAN NOT NULL DEFAULT FALSE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TAR-009
CREATE TABLE IF NOT EXISTS revenuefinance.mst_kit (                           -- KIT definitions (procedure / OT kits) with price
    kit_id                     INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    kit_code                   VARCHAR(30) NOT NULL UNIQUE,
    kit_name                   VARCHAR(150) NOT NULL,
    service_id                 INT NULL,
    kit_price                  DECIMAL(12,2) NOT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TAR-009
CREATE TABLE IF NOT EXISTS revenuefinance.mst_kit_item (                      -- KIT component items and quantities (stock deducted by component and batch)
    kit_item_id                INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    kit_id                     INT NOT NULL,
    item_id                    INT NOT NULL,                                   -- logical FK -> operationssupply.mst_item [Operations & Supply Chain]
    quantity                   DECIMAL(10,2) NOT NULL,
    is_returnable              BOOLEAN NOT NULL DEFAULT TRUE,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TAR-010, TAR-011, INS-005
CREATE TABLE IF NOT EXISTS revenuefinance.bil_payer_split (                   -- Split of an episode across payers (insurer, corporate, patient, scheme) by item / category / percentage
    payer_split_id             BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    patient_account_id         BIGINT NOT NULL,
    payer_id                   INT NULL,
    payer_role                 VARCHAR(20) NOT NULL,                           -- PRIMARY_INSURER, SECONDARY_INSURER, CORPORATE, SCHEME, PATIENT
    split_basis                VARCHAR(20) NOT NULL,                           -- ITEM, CATEGORY, PERCENT, CAP
    split_value                DECIMAL(10,2) NULL,
    cap_amount                 DECIMAL(14,2) NULL,
    priority_order             SMALLINT NOT NULL DEFAULT 1,
    effective_from             TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    superseded_at              TIMESTAMPTZ(0) NULL,
    resplit_reason             VARCHAR(300) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TAR-012
CREATE TABLE IF NOT EXISTS revenuefinance.bil_waiver_request (                -- Waiver requests (separate from discounts) with documents and multi-level approval
    waiver_request_id          BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    waiver_no                  VARCHAR(30) NOT NULL UNIQUE,
    bill_id                    BIGINT NULL,
    patient_account_id         BIGINT NULL,
    requested_amount           DECIMAL(12,2) NOT NULL,
    approved_amount            DECIMAL(12,2) NULL,
    reason                     VARCHAR(500) NOT NULL,
    document_id                BIGINT NULL,                                    -- logical FK -> integrationcomms.core_document [Integration & Communications]
    current_level              SMALLINT NOT NULL DEFAULT 1,
    requested_by               BIGINT NOT NULL,
    waiver_status              VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: CORE-004, TAR-012, ACC-004, DOC-003
CREATE TABLE IF NOT EXISTS revenuefinance.bil_approval_step (                 -- Generic multi-level approval steps for discounts, waivers, refunds, write-offs, credit notes
    approval_step_id           BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    document_type              VARCHAR(30) NOT NULL,                           -- DISCOUNT, WAIVER, REFUND, WRITE_OFF, CREDIT_NOTE, DOCTOR_PAYOUT, REFERRAL_FEE
    document_id                BIGINT NOT NULL,
    approval_level             SMALLINT NOT NULL,
    approver_id                BIGINT NOT NULL,
    decision                   VARCHAR(20) NOT NULL,                           -- APPROVED, REJECTED, RETURNED
    decided_at                 TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remarks                    VARCHAR(500) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LOY-001
CREATE TABLE IF NOT EXISTS revenuefinance.mst_loyalty_tier (                  -- Loyalty membership tiers
    loyalty_tier_id            INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    tier_code                  VARCHAR(20) NOT NULL UNIQUE,
    tier_name                  VARCHAR(50) NOT NULL,
    min_annual_spend           DECIMAL(12,2) NULL,
    earn_multiplier            DECIMAL(5,2) NOT NULL DEFAULT 1,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: LOY-002, LOY-004, LOY-005
CREATE TABLE IF NOT EXISTS revenuefinance.mst_loyalty_rule (                  -- Points earning / redemption rules (spend, service type, campaign multipliers, birthday / referral bonus, limits)
    loyalty_rule_id            INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    rule_code                  VARCHAR(30) NOT NULL UNIQUE,
    rule_type                  VARCHAR(20) NOT NULL,                           -- EARN_SPEND, EARN_SERVICE, BONUS_BIRTHDAY, BONUS_REFERRAL, CAMPAIGN, REDEEM_LIMIT
    service_category_id        INT NULL,
    points_per_unit            DECIMAL(10,4) NULL,
    unit_amount                DECIMAL(10,2) NULL,
    multiplier                 DECIMAL(5,2) NULL,
    min_redeem_points          INT NULL,
    max_redeem_points          INT NULL,
    point_value                DECIMAL(10,4) NULL,
    expiry_months              SMALLINT NULL,
    exclude_payer_types        VARCHAR(100) NULL DEFAULT 'INSURANCE,SCHEME,CORPORATE',
    valid_from                 DATE NOT NULL,
    valid_to                   DATE NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: INS-001, INS-004
CREATE TABLE IF NOT EXISTS revenuefinance.mst_insurance_plan (                -- Insurer plans / policies: sum insured, room-rent limit, sub-limits, exclusions
    insurance_plan_id          INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    payer_id                   INT NOT NULL,
    plan_code                  VARCHAR(30) NOT NULL,
    plan_name                  VARCHAR(150) NOT NULL,
    sum_insured_options        VARCHAR(200) NULL,
    room_rent_limit_type       VARCHAR(10) NULL,                               -- PERCENT_SI, FIXED, NONE
    room_rent_limit_value      DECIMAL(12,2) NULL,
    icu_rent_limit_value       DECIMAL(12,2) NULL,
    proportionate_deduction    BOOLEAN NOT NULL DEFAULT TRUE,
    exclusions_text            TEXT NULL,
    waiting_periods_json       JSONB NULL,
    tariff_plan_id             INT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT                 uq_mst_insurance_plan_1 UNIQUE (payer_id, plan_code)
);

-- [NEW v4] FDS ref: INS-001, INS-004
CREATE TABLE IF NOT EXISTS revenuefinance.mst_insurance_sublimit (            -- Plan sub-limits by service category / procedure / disease
    insurance_sublimit_id      INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    insurance_plan_id          INT NOT NULL,
    service_category_id        INT NULL,
    clinical_code_id           BIGINT NULL,                                    -- logical FK -> identityorg.core_clinical_code [Identity & Organization]
    limit_type                 VARCHAR(10) NOT NULL,                           -- FIXED, PERCENT_SI
    limit_value                DECIMAL(12,2) NOT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: INS-001, GOV-003
CREATE TABLE IF NOT EXISTS revenuefinance.mst_payer_network (                 -- Insurer-TPA mappings and hospital network empanelment
    payer_network_id           INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    insurer_payer_id           INT NOT NULL,
    tpa_payer_id               INT NULL,
    network_type               VARCHAR(20) NULL,                               -- PPN, GIPSA, PREFERRED, SCHEME_EMPANELLED
    empanelled_from            DATE NULL,
    empanelled_to              DATE NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: INS-004, INS-013, TAR-003
CREATE TABLE IF NOT EXISTS revenuefinance.mst_copay_rule (                    -- Co-pay / deductible rules by payer, plan, service category and room category
    copay_rule_id              INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    payer_id                   INT NULL,
    insurance_plan_id          INT NULL,
    service_category_id        INT NULL,
    room_category              VARCHAR(30) NULL,
    copay_type                 VARCHAR(10) NOT NULL,                           -- PERCENT, FIXED
    copay_value                DECIMAL(10,2) NOT NULL,
    deductible_amount          DECIMAL(12,2) NULL,
    valid_from                 DATE NOT NULL,
    valid_to                   DATE NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: INS-009, INS-008
CREATE TABLE IF NOT EXISTS revenuefinance.ins_document_checklist (            -- Mandatory document checklist per insurer / scheme and stage
    document_checklist_id      INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    payer_id                   INT NULL,
    scheme_code                VARCHAR(30) NULL,
    stage                      VARCHAR(20) NOT NULL,                           -- PREAUTH, ENHANCEMENT, CLAIM, QUERY
    document_type              VARCHAR(50) NOT NULL,
    is_mandatory               BOOLEAN NOT NULL DEFAULT TRUE,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: INS-006, INS-008, INS-009
CREATE TABLE IF NOT EXISTS revenuefinance.ins_claim_document (                -- Documents attached to pre-auth / claim against the checklist
    claim_document_id          BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    preauth_id                 BIGINT NULL,
    claim_id                   BIGINT NULL,
    document_type              VARCHAR(50) NOT NULL,
    document_id                BIGINT NULL,                                    -- logical FK -> integrationcomms.core_document [Integration & Communications]
    attached_by                BIGINT NULL,
    attached_at                TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: INS-014, INS-015
CREATE TABLE IF NOT EXISTS revenuefinance.ins_claim_appeal (                  -- Denial appeals with owner, due date, outcome and write-off approval
    claim_appeal_id            BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    claim_denial_id            BIGINT NOT NULL,
    owner_user_id              BIGINT NOT NULL,
    due_date                   DATE NULL,
    appeal_text                TEXT NULL,
    submitted_at               TIMESTAMPTZ(0) NULL,
    outcome                    VARCHAR(20) NULL,                               -- PENDING, ACCEPTED, PARTIAL, REJECTED
    recovered_amount           DECIMAL(14,2) NULL,
    write_off_amount           DECIMAL(14,2) NULL,
    write_off_approved_by      BIGINT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: GOV-007, ACC-010
CREATE TABLE IF NOT EXISTS revenuefinance.bil_corporate_invoice (             -- Monthly consolidated corporate / MNC / Mediclaim invoice with PO reference and employer guarantee
    corporate_invoice_id       BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    invoice_no                 VARCHAR(30) NOT NULL UNIQUE,
    payer_id                   INT NOT NULL,
    period_from                DATE NOT NULL,
    period_to                  DATE NOT NULL,
    po_reference               VARCHAR(50) NULL,
    guarantee_letter_ref       VARCHAR(50) NULL,
    bill_count                 INT NOT NULL DEFAULT 0,
    invoice_amount             DECIMAL(14,2) NOT NULL DEFAULT 0,
    tax_amount                 DECIMAL(14,2) NOT NULL DEFAULT 0,
    invoice_status             VARCHAR(20) NOT NULL DEFAULT 'DRAFT',           -- DRAFT, SENT, PARTLY_PAID, PAID
    due_date                   DATE NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: DOC-001, DOC-005, DOC-007 (Doctor contract entity)
CREATE TABLE IF NOT EXISTS revenuefinance.bil_doctor_contract (               -- Doctor contracts: effective dates, minimum guarantee, caps, discount bearing, share timing
    doctor_contract_id         INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    practitioner_id            BIGINT NOT NULL,                                -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    contract_no                VARCHAR(30) NOT NULL UNIQUE,
    contract_type              VARCHAR(20) NOT NULL,                           -- INHOUSE_FIXED, INHOUSE_VARIABLE, VISITING, REFERRAL
    valid_from                 DATE NOT NULL,
    valid_to                   DATE NULL,
    minimum_guarantee          DECIMAL(14,2) NULL,
    cap_amount                 DECIMAL(14,2) NULL,
    discount_borne_by          VARCHAR(10) NOT NULL DEFAULT 'HOSPITAL',        -- HOSPITAL, DOCTOR, SHARED
    share_on                   VARCHAR(20) NOT NULL DEFAULT 'BILLING',         -- BILLING, REALISATION, SETTLEMENT
    tds_section                VARCHAR(10) NULL,
    document_id                BIGINT NULL,                                    -- logical FK -> integrationcomms.core_document [Integration & Communications]
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: DOC-003
CREATE TABLE IF NOT EXISTS revenuefinance.bil_referral_agent (                -- External referring doctors / agencies for referral fees (with compliance flags)
    referral_agent_id          INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    agent_code                 VARCHAR(30) NOT NULL UNIQUE,
    agent_name                 VARCHAR(150) NOT NULL,
    agent_type                 VARCHAR(20) NOT NULL,                           -- EXTERNAL_DOCTOR, AGENCY, CAMP_ORGANISER
    pan_no                     VARCHAR(10) NULL,
    bank_details_json          JSONB NULL,
    compliance_approved        BOOLEAN NOT NULL DEFAULT FALSE,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: DOC-008, DOC-010
CREATE TABLE IF NOT EXISTS revenuefinance.bil_doctor_statement (              -- Monthly doctor statement / ledger with TDS, approval and payment voucher
    doctor_statement_id        BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    statement_no               VARCHAR(30) NOT NULL UNIQUE,
    practitioner_id            BIGINT NULL,                                    -- logical FK -> identityorg.hr_practitioner [Identity & Organization]
    referral_agent_id          INT NULL,
    period_from                DATE NOT NULL,
    period_to                  DATE NOT NULL,
    gross_amount               DECIMAL(14,2) NOT NULL DEFAULT 0,
    adjustment_amount          DECIMAL(14,2) NOT NULL DEFAULT 0,
    tds_amount                 DECIMAL(14,2) NOT NULL DEFAULT 0,
    net_amount                 DECIMAL(14,2) NOT NULL DEFAULT 0,
    statement_status           VARCHAR(20) NOT NULL DEFAULT 'DRAFT',           -- DRAFT, PUBLISHED, APPROVED, PAID
    approved_by                BIGINT NULL,
    payment_voucher_id         BIGINT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: DOC-009
CREATE TABLE IF NOT EXISTS revenuefinance.bil_doctor_statement_query (        -- Doctor queries on statement lines with resolution trail
    doctor_statement_query_id  BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    doctor_statement_id        BIGINT NOT NULL,
    doctor_payout_id           BIGINT NULL,
    query_text                 VARCHAR(1000) NOT NULL,
    raised_at                  TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolution_text            VARCHAR(1000) NULL,
    resolved_by                BIGINT NULL,
    resolved_at                TIMESTAMPTZ(0) NULL,
    query_status               VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TAX-001, HSN-001..007 (Pharmacy)
CREATE TABLE IF NOT EXISTS revenuefinance.mst_hsn_sac (                       -- HSN / SAC master with effective-dated GST rates (CGST, SGST, IGST, cess) and exemption
    hsn_sac_id                 INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    code                       VARCHAR(10) NOT NULL,
    code_type                  VARCHAR(5) NOT NULL,                            -- HSN, SAC
    description                VARCHAR(500) NOT NULL,
    gst_rate                   DECIMAL(5,2) NOT NULL,
    cgst_rate                  DECIMAL(5,2) NULL,
    sgst_rate                  DECIMAL(5,2) NULL,
    igst_rate                  DECIMAL(5,2) NULL,
    cess_rate                  DECIMAL(5,2) NULL,
    tax_category               VARCHAR(20) NOT NULL DEFAULT 'TAXABLE',         -- TAXABLE, EXEMPT, NIL_RATED, NON_GST
    effective_from             DATE NOT NULL,
    effective_to               DATE NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT                 uq_mst_hsn_sac_1 UNIQUE (code, effective_from)
);

-- [NEW v4] FDS ref: TAX-003
CREATE TABLE IF NOT EXISTS revenuefinance.fin_einvoice_log (                  -- E-invoice (IRN) and e-way bill generation log
    einvoice_log_id            BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    source_doc_type            VARCHAR(20) NOT NULL,                           -- BILL, CREDIT_NOTE, DEBIT_NOTE, STOCK_TRANSFER
    source_doc_id              BIGINT NOT NULL,
    irn                        VARCHAR(100) NULL,
    ack_no                     VARCHAR(50) NULL,
    ack_date                   TIMESTAMPTZ(0) NULL,
    signed_qr_code             TEXT NULL,
    eway_bill_no               VARCHAR(30) NULL,
    eway_valid_to              TIMESTAMPTZ(0) NULL,
    request_status             VARCHAR(20) NOT NULL,                           -- SUCCESS, FAILED, CANCELLED
    error_message              VARCHAR(1000) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TAX-005..008, PHB-010, DOC-008
CREATE TABLE IF NOT EXISTS revenuefinance.fin_tds_entry (                     -- TDS deducted on payments (doctors, vendors, contractors) and TDS receivable on receipts
    tds_entry_id               BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    direction                  VARCHAR(10) NOT NULL,                           -- PAYABLE, RECEIVABLE
    party_type                 VARCHAR(20) NOT NULL,                           -- DOCTOR, VENDOR, CONTRACTOR, PAYER, PARTNER
    party_id                   BIGINT NOT NULL,
    party_pan                  VARCHAR(10) NULL,
    tds_section                VARCHAR(10) NOT NULL,
    tds_rate                   DECIMAL(5,2) NOT NULL,
    base_amount                DECIMAL(14,2) NOT NULL,
    tds_amount                 DECIMAL(14,2) NOT NULL,
    voucher_id                 BIGINT NULL,
    tds_challan_id             BIGINT NULL,
    deducted_on                DATE NOT NULL,
    form16a_issued_at          TIMESTAMPTZ(0) NULL,
    reconciled_26as            BOOLEAN NOT NULL DEFAULT FALSE,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TAX-007
CREATE TABLE IF NOT EXISTS revenuefinance.fin_tds_challan (                   -- TDS challans for 26Q / 24Q filing
    tds_challan_id             BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    challan_no                 VARCHAR(30) NOT NULL,
    bsr_code                   VARCHAR(10) NULL,
    deposit_date               DATE NOT NULL,
    amount                     DECIMAL(14,2) NOT NULL,
    quarter                    VARCHAR(6) NOT NULL,
    form_type                  VARCHAR(5) NOT NULL,                            -- 26Q, 24Q
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: TAX-002, TAX-004, TAX-009
CREATE TABLE IF NOT EXISTS revenuefinance.fin_gst_itc_reconciliation (        -- GSTR-2B input-tax-credit reconciliation lines
    gst_itc_reconciliation_id  BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    return_period              VARCHAR(7) NOT NULL,                            -- YYYY-MM
    supplier_gstin             VARCHAR(15) NOT NULL,
    invoice_no                 VARCHAR(50) NOT NULL,
    invoice_date               DATE NULL,
    taxable_value              DECIMAL(14,2) NULL,
    igst_amount                DECIMAL(14,2) NULL,
    cgst_amount                DECIMAL(14,2) NULL,
    sgst_amount                DECIMAL(14,2) NULL,
    supplier_invoice_id        BIGINT NULL,
    match_status               VARCHAR(20) NOT NULL,                           -- MATCHED, MISMATCH, MISSING_IN_BOOKS, MISSING_IN_2B
    itc_eligible               BOOLEAN NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: PHB-009, PHB-013, PUR-006, PUR-010, GRN-008, TAX-009 (Pharmacy & Billing)
CREATE TABLE IF NOT EXISTS revenuefinance.fin_supplier_invoice (              -- Supplier purchase invoice / payable linked to GRN with three-way match and ITC eligibility
    supplier_invoice_id        BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    invoice_no                 VARCHAR(50) NOT NULL,
    vendor_id                  INT NOT NULL,                                   -- logical FK -> operationssupply.mst_vendor [Operations & Supply Chain]
    invoice_date               DATE NOT NULL,
    due_date                   DATE NULL,
    grn_ids                    VARCHAR(200) NULL,                              -- operationssupply.inv_grn ids
    purchase_order_id          BIGINT NULL,                                    -- logical FK -> operationssupply.inv_purchase_order [Operations & Supply Chain]
    store_id                   INT NULL,                                       -- logical FK -> operationssupply.mst_store [Operations & Supply Chain]
    taxable_amount             DECIMAL(14,2) NOT NULL,
    cgst_amount                DECIMAL(14,2) NULL,
    sgst_amount                DECIMAL(14,2) NULL,
    igst_amount                DECIMAL(14,2) NULL,
    cess_amount                DECIMAL(14,2) NULL,
    net_amount                 DECIMAL(14,2) NOT NULL,
    paid_amount                DECIMAL(14,2) NOT NULL DEFAULT 0,
    match_status               VARCHAR(20) NULL,                               -- MATCHED, QTY_VARIANCE, RATE_VARIANCE, TAX_VARIANCE, APPROVED_VARIANCE
    itc_eligible               BOOLEAN NOT NULL DEFAULT TRUE,
    invoice_status             VARCHAR(20) NOT NULL DEFAULT 'OPEN',            -- OPEN, APPROVED, PARTLY_PAID, PAID, CANCELLED
    document_id                BIGINT NULL,                                    -- logical FK -> integrationcomms.core_document [Integration & Communications]
    voucher_id                 BIGINT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT                 uq_fin_supplier_invoice_1 UNIQUE (vendor_id, invoice_no)
);

-- [NEW v4] FDS ref: PHB-010, VCH-003, VEN-006
CREATE TABLE IF NOT EXISTS revenuefinance.fin_payment_allocation (            -- Bill-wise settlement of payments / debit notes against supplier invoices
    payment_allocation_id      BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    voucher_id                 BIGINT NOT NULL,
    supplier_invoice_id        BIGINT NOT NULL,
    allocated_amount           DECIMAL(14,2) NOT NULL,
    tds_amount                 DECIMAL(14,2) NULL,
    allocated_at               TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: MIS-007
CREATE TABLE IF NOT EXISTS revenuefinance.fin_asset_transaction (             -- Fixed asset capitalisation, transfer and disposal posted to ledger
    asset_transaction_id       BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    asset_id                   BIGINT NOT NULL,                                -- logical FK -> operationssupply.adm_asset [Operations & Supply Chain]
    txn_type                   VARCHAR(20) NOT NULL,                           -- CAPITALISATION, TRANSFER, DISPOSAL, REVALUATION
    txn_date                   DATE NOT NULL,
    amount                     DECIMAL(14,2) NULL,
    from_cost_center_id        INT NULL,
    to_cost_center_id          INT NULL,
    voucher_id                 BIGINT NULL,
    remarks                    VARCHAR(500) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: MIS-008
CREATE TABLE IF NOT EXISTS revenuefinance.fin_cash_forecast (                 -- Daily cash position and projection
    cash_forecast_id           BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    forecast_date              DATE NOT NULL,
    bank_account_id            INT NULL,
    opening_balance            DECIMAL(16,2) NULL,
    expected_inflow            DECIMAL(16,2) NULL,
    expected_outflow           DECIMAL(16,2) NULL,
    projected_closing          DECIMAL(16,2) NULL,
    actual_closing             DECIMAL(16,2) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: MIS-006, MIS-014
CREATE TABLE IF NOT EXISTS revenuefinance.bil_leakage_exception (             -- Under-billing detection: ordered / performed / consumed / prescribed vs billed
    leakage_exception_id       BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    patient_account_id         BIGINT NULL,
    source_service             VARCHAR(20) NOT NULL,
    source_ref_type            VARCHAR(30) NOT NULL,                           -- ORDER_ITEM, CONSUMPTION, DISPENSE_ITEM, PROCEDURE
    source_ref_id              BIGINT NOT NULL,
    service_id                 INT NULL,
    expected_amount            DECIMAL(12,2) NULL,
    detected_at                TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolution                 VARCHAR(20) NULL,                               -- BILLED, WAIVED, NOT_BILLABLE, OPEN
    resolved_by                BIGINT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);


/* ---------- C. FOREIGN KEYS (same service only) ---------- */
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_patient_account_primary_payer_id') THEN
        ALTER TABLE revenuefinance.bil_patient_account ADD CONSTRAINT fk_bil_patient_account_primary_payer_id FOREIGN KEY (primary_payer_id) REFERENCES revenuefinance.mst_payer(payer_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_patient_account_tariff_plan_id') THEN
        ALTER TABLE revenuefinance.bil_patient_account ADD CONSTRAINT fk_bil_patient_account_tariff_plan_id FOREIGN KEY (tariff_plan_id) REFERENCES revenuefinance.mst_tariff_plan(tariff_plan_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_patient_account_estimate_id') THEN
        ALTER TABLE revenuefinance.bil_patient_account ADD CONSTRAINT fk_bil_patient_account_estimate_id FOREIGN KEY (estimate_id) REFERENCES revenuefinance.bil_estimate(estimate_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_deposit_request_patient_account_id') THEN
        ALTER TABLE revenuefinance.bil_deposit_request ADD CONSTRAINT fk_bil_deposit_request_patient_account_id FOREIGN KEY (patient_account_id) REFERENCES revenuefinance.bil_patient_account(patient_account_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_deposit_request_receipt_id') THEN
        ALTER TABLE revenuefinance.bil_deposit_request ADD CONSTRAINT fk_bil_deposit_request_receipt_id FOREIGN KEY (receipt_id) REFERENCES revenuefinance.bil_receipt(receipt_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_refund_request_bill_id') THEN
        ALTER TABLE revenuefinance.bil_refund_request ADD CONSTRAINT fk_bil_refund_request_bill_id FOREIGN KEY (bill_id) REFERENCES revenuefinance.bil_bill(bill_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_refund_request_receipt_id') THEN
        ALTER TABLE revenuefinance.bil_refund_request ADD CONSTRAINT fk_bil_refund_request_receipt_id FOREIGN KEY (receipt_id) REFERENCES revenuefinance.bil_receipt(receipt_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_refund_request_payment_gateway_txn_id') THEN
        ALTER TABLE revenuefinance.bil_refund_request ADD CONSTRAINT fk_bil_refund_request_payment_gateway_txn_id FOREIGN KEY (payment_gateway_txn_id) REFERENCES revenuefinance.bil_payment_gateway_txn(payment_gateway_txn_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_payment_gateway_event_payment_gateway_txn_id') THEN
        ALTER TABLE revenuefinance.bil_payment_gateway_event ADD CONSTRAINT fk_bil_payment_gateway_event_payment_gateway_txn_id FOREIGN KEY (payment_gateway_txn_id) REFERENCES revenuefinance.bil_payment_gateway_txn(payment_gateway_txn_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_cancellation_policy_service_category_id') THEN
        ALTER TABLE revenuefinance.bil_cancellation_policy ADD CONSTRAINT fk_bil_cancellation_policy_service_category_id FOREIGN KEY (service_category_id) REFERENCES revenuefinance.mst_service_category(service_category_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_recurring_charge_rule_service_id') THEN
        ALTER TABLE revenuefinance.bil_recurring_charge_rule ADD CONSTRAINT fk_bil_recurring_charge_rule_service_id FOREIGN KEY (service_id) REFERENCES revenuefinance.mst_service(service_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_mst_package_payer_package_id') THEN
        ALTER TABLE revenuefinance.mst_package_payer ADD CONSTRAINT fk_mst_package_payer_package_id FOREIGN KEY (package_id) REFERENCES revenuefinance.mst_package(package_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_mst_package_payer_payer_id') THEN
        ALTER TABLE revenuefinance.mst_package_payer ADD CONSTRAINT fk_mst_package_payer_payer_id FOREIGN KEY (payer_id) REFERENCES revenuefinance.mst_payer(payer_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_package_episode_patient_account_id') THEN
        ALTER TABLE revenuefinance.bil_package_episode ADD CONSTRAINT fk_bil_package_episode_patient_account_id FOREIGN KEY (patient_account_id) REFERENCES revenuefinance.bil_patient_account(patient_account_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_package_episode_package_id') THEN
        ALTER TABLE revenuefinance.bil_package_episode ADD CONSTRAINT fk_bil_package_episode_package_id FOREIGN KEY (package_id) REFERENCES revenuefinance.mst_package(package_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_package_episode_changed_from_package_id') THEN
        ALTER TABLE revenuefinance.bil_package_episode ADD CONSTRAINT fk_bil_package_episode_changed_from_package_id FOREIGN KEY (changed_from_package_id) REFERENCES revenuefinance.mst_package(package_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_coupon_redemption_coupon_id') THEN
        ALTER TABLE revenuefinance.bil_coupon_redemption ADD CONSTRAINT fk_bil_coupon_redemption_coupon_id FOREIGN KEY (coupon_id) REFERENCES revenuefinance.mst_coupon(coupon_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_coupon_redemption_bill_id') THEN
        ALTER TABLE revenuefinance.bil_coupon_redemption ADD CONSTRAINT fk_bil_coupon_redemption_bill_id FOREIGN KEY (bill_id) REFERENCES revenuefinance.bil_bill(bill_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_mst_kit_service_id') THEN
        ALTER TABLE revenuefinance.mst_kit ADD CONSTRAINT fk_mst_kit_service_id FOREIGN KEY (service_id) REFERENCES revenuefinance.mst_service(service_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_mst_kit_item_kit_id') THEN
        ALTER TABLE revenuefinance.mst_kit_item ADD CONSTRAINT fk_mst_kit_item_kit_id FOREIGN KEY (kit_id) REFERENCES revenuefinance.mst_kit(kit_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_payer_split_patient_account_id') THEN
        ALTER TABLE revenuefinance.bil_payer_split ADD CONSTRAINT fk_bil_payer_split_patient_account_id FOREIGN KEY (patient_account_id) REFERENCES revenuefinance.bil_patient_account(patient_account_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_payer_split_payer_id') THEN
        ALTER TABLE revenuefinance.bil_payer_split ADD CONSTRAINT fk_bil_payer_split_payer_id FOREIGN KEY (payer_id) REFERENCES revenuefinance.mst_payer(payer_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_waiver_request_bill_id') THEN
        ALTER TABLE revenuefinance.bil_waiver_request ADD CONSTRAINT fk_bil_waiver_request_bill_id FOREIGN KEY (bill_id) REFERENCES revenuefinance.bil_bill(bill_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_waiver_request_patient_account_id') THEN
        ALTER TABLE revenuefinance.bil_waiver_request ADD CONSTRAINT fk_bil_waiver_request_patient_account_id FOREIGN KEY (patient_account_id) REFERENCES revenuefinance.bil_patient_account(patient_account_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_mst_loyalty_rule_service_category_id') THEN
        ALTER TABLE revenuefinance.mst_loyalty_rule ADD CONSTRAINT fk_mst_loyalty_rule_service_category_id FOREIGN KEY (service_category_id) REFERENCES revenuefinance.mst_service_category(service_category_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_mst_insurance_plan_payer_id') THEN
        ALTER TABLE revenuefinance.mst_insurance_plan ADD CONSTRAINT fk_mst_insurance_plan_payer_id FOREIGN KEY (payer_id) REFERENCES revenuefinance.mst_payer(payer_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_mst_insurance_plan_tariff_plan_id') THEN
        ALTER TABLE revenuefinance.mst_insurance_plan ADD CONSTRAINT fk_mst_insurance_plan_tariff_plan_id FOREIGN KEY (tariff_plan_id) REFERENCES revenuefinance.mst_tariff_plan(tariff_plan_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_mst_insurance_sublimit_insurance_plan_id') THEN
        ALTER TABLE revenuefinance.mst_insurance_sublimit ADD CONSTRAINT fk_mst_insurance_sublimit_insurance_plan_id FOREIGN KEY (insurance_plan_id) REFERENCES revenuefinance.mst_insurance_plan(insurance_plan_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_mst_insurance_sublimit_service_category_id') THEN
        ALTER TABLE revenuefinance.mst_insurance_sublimit ADD CONSTRAINT fk_mst_insurance_sublimit_service_category_id FOREIGN KEY (service_category_id) REFERENCES revenuefinance.mst_service_category(service_category_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_mst_payer_network_insurer_payer_id') THEN
        ALTER TABLE revenuefinance.mst_payer_network ADD CONSTRAINT fk_mst_payer_network_insurer_payer_id FOREIGN KEY (insurer_payer_id) REFERENCES revenuefinance.mst_payer(payer_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_mst_payer_network_tpa_payer_id') THEN
        ALTER TABLE revenuefinance.mst_payer_network ADD CONSTRAINT fk_mst_payer_network_tpa_payer_id FOREIGN KEY (tpa_payer_id) REFERENCES revenuefinance.mst_payer(payer_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_mst_copay_rule_payer_id') THEN
        ALTER TABLE revenuefinance.mst_copay_rule ADD CONSTRAINT fk_mst_copay_rule_payer_id FOREIGN KEY (payer_id) REFERENCES revenuefinance.mst_payer(payer_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_mst_copay_rule_insurance_plan_id') THEN
        ALTER TABLE revenuefinance.mst_copay_rule ADD CONSTRAINT fk_mst_copay_rule_insurance_plan_id FOREIGN KEY (insurance_plan_id) REFERENCES revenuefinance.mst_insurance_plan(insurance_plan_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_mst_copay_rule_service_category_id') THEN
        ALTER TABLE revenuefinance.mst_copay_rule ADD CONSTRAINT fk_mst_copay_rule_service_category_id FOREIGN KEY (service_category_id) REFERENCES revenuefinance.mst_service_category(service_category_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_ins_document_checklist_payer_id') THEN
        ALTER TABLE revenuefinance.ins_document_checklist ADD CONSTRAINT fk_ins_document_checklist_payer_id FOREIGN KEY (payer_id) REFERENCES revenuefinance.mst_payer(payer_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_ins_claim_document_preauth_id') THEN
        ALTER TABLE revenuefinance.ins_claim_document ADD CONSTRAINT fk_ins_claim_document_preauth_id FOREIGN KEY (preauth_id) REFERENCES revenuefinance.ins_preauth(preauth_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_ins_claim_document_claim_id') THEN
        ALTER TABLE revenuefinance.ins_claim_document ADD CONSTRAINT fk_ins_claim_document_claim_id FOREIGN KEY (claim_id) REFERENCES revenuefinance.ins_claim(claim_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_ins_claim_appeal_claim_denial_id') THEN
        ALTER TABLE revenuefinance.ins_claim_appeal ADD CONSTRAINT fk_ins_claim_appeal_claim_denial_id FOREIGN KEY (claim_denial_id) REFERENCES revenuefinance.ins_claim_denial(claim_denial_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_corporate_invoice_payer_id') THEN
        ALTER TABLE revenuefinance.bil_corporate_invoice ADD CONSTRAINT fk_bil_corporate_invoice_payer_id FOREIGN KEY (payer_id) REFERENCES revenuefinance.mst_payer(payer_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_doctor_statement_referral_agent_id') THEN
        ALTER TABLE revenuefinance.bil_doctor_statement ADD CONSTRAINT fk_bil_doctor_statement_referral_agent_id FOREIGN KEY (referral_agent_id) REFERENCES revenuefinance.bil_referral_agent(referral_agent_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_doctor_statement_payment_voucher_id') THEN
        ALTER TABLE revenuefinance.bil_doctor_statement ADD CONSTRAINT fk_bil_doctor_statement_payment_voucher_id FOREIGN KEY (payment_voucher_id) REFERENCES revenuefinance.fin_voucher(voucher_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_doctor_statement_query_doctor_statement_id') THEN
        ALTER TABLE revenuefinance.bil_doctor_statement_query ADD CONSTRAINT fk_bil_doctor_statement_query_doctor_statement_id FOREIGN KEY (doctor_statement_id) REFERENCES revenuefinance.bil_doctor_statement(doctor_statement_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_doctor_statement_query_doctor_payout_id') THEN
        ALTER TABLE revenuefinance.bil_doctor_statement_query ADD CONSTRAINT fk_bil_doctor_statement_query_doctor_payout_id FOREIGN KEY (doctor_payout_id) REFERENCES revenuefinance.bil_doctor_payout(doctor_payout_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_fin_tds_entry_voucher_id') THEN
        ALTER TABLE revenuefinance.fin_tds_entry ADD CONSTRAINT fk_fin_tds_entry_voucher_id FOREIGN KEY (voucher_id) REFERENCES revenuefinance.fin_voucher(voucher_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_fin_tds_entry_tds_challan_id') THEN
        ALTER TABLE revenuefinance.fin_tds_entry ADD CONSTRAINT fk_fin_tds_entry_tds_challan_id FOREIGN KEY (tds_challan_id) REFERENCES revenuefinance.fin_tds_challan(tds_challan_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_fin_gst_itc_reconciliation_supplier_invoice_id') THEN
        ALTER TABLE revenuefinance.fin_gst_itc_reconciliation ADD CONSTRAINT fk_fin_gst_itc_reconciliation_supplier_invoice_id FOREIGN KEY (supplier_invoice_id) REFERENCES revenuefinance.fin_supplier_invoice(supplier_invoice_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_fin_supplier_invoice_voucher_id') THEN
        ALTER TABLE revenuefinance.fin_supplier_invoice ADD CONSTRAINT fk_fin_supplier_invoice_voucher_id FOREIGN KEY (voucher_id) REFERENCES revenuefinance.fin_voucher(voucher_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_fin_payment_allocation_voucher_id') THEN
        ALTER TABLE revenuefinance.fin_payment_allocation ADD CONSTRAINT fk_fin_payment_allocation_voucher_id FOREIGN KEY (voucher_id) REFERENCES revenuefinance.fin_voucher(voucher_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_fin_payment_allocation_supplier_invoice_id') THEN
        ALTER TABLE revenuefinance.fin_payment_allocation ADD CONSTRAINT fk_fin_payment_allocation_supplier_invoice_id FOREIGN KEY (supplier_invoice_id) REFERENCES revenuefinance.fin_supplier_invoice(supplier_invoice_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_fin_asset_transaction_from_cost_center_id') THEN
        ALTER TABLE revenuefinance.fin_asset_transaction ADD CONSTRAINT fk_fin_asset_transaction_from_cost_center_id FOREIGN KEY (from_cost_center_id) REFERENCES revenuefinance.fin_cost_center(cost_center_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_fin_asset_transaction_to_cost_center_id') THEN
        ALTER TABLE revenuefinance.fin_asset_transaction ADD CONSTRAINT fk_fin_asset_transaction_to_cost_center_id FOREIGN KEY (to_cost_center_id) REFERENCES revenuefinance.fin_cost_center(cost_center_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_fin_asset_transaction_voucher_id') THEN
        ALTER TABLE revenuefinance.fin_asset_transaction ADD CONSTRAINT fk_fin_asset_transaction_voucher_id FOREIGN KEY (voucher_id) REFERENCES revenuefinance.fin_voucher(voucher_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_fin_cash_forecast_bank_account_id') THEN
        ALTER TABLE revenuefinance.fin_cash_forecast ADD CONSTRAINT fk_fin_cash_forecast_bank_account_id FOREIGN KEY (bank_account_id) REFERENCES revenuefinance.fin_bank_account(bank_account_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_leakage_exception_patient_account_id') THEN
        ALTER TABLE revenuefinance.bil_leakage_exception ADD CONSTRAINT fk_bil_leakage_exception_patient_account_id FOREIGN KEY (patient_account_id) REFERENCES revenuefinance.bil_patient_account(patient_account_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_leakage_exception_service_id') THEN
        ALTER TABLE revenuefinance.bil_leakage_exception ADD CONSTRAINT fk_bil_leakage_exception_service_id FOREIGN KEY (service_id) REFERENCES revenuefinance.mst_service(service_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_bill_patient_account_id') THEN
        ALTER TABLE revenuefinance.bil_bill ADD CONSTRAINT fk_bil_bill_patient_account_id FOREIGN KEY (patient_account_id) REFERENCES revenuefinance.bil_patient_account(patient_account_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bil_bill_patient_account_id ON revenuefinance.bil_bill(patient_account_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_bill_consolidated_bill_id') THEN
        ALTER TABLE revenuefinance.bil_bill ADD CONSTRAINT fk_bil_bill_consolidated_bill_id FOREIGN KEY (consolidated_bill_id) REFERENCES revenuefinance.bil_bill(bill_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bil_bill_consolidated_bill_id ON revenuefinance.bil_bill(consolidated_bill_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_bill_revised_from_bill_id') THEN
        ALTER TABLE revenuefinance.bil_bill ADD CONSTRAINT fk_bil_bill_revised_from_bill_id FOREIGN KEY (revised_from_bill_id) REFERENCES revenuefinance.bil_bill(bill_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bil_bill_revised_from_bill_id ON revenuefinance.bil_bill(revised_from_bill_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_bill_cost_center_id') THEN
        ALTER TABLE revenuefinance.bil_bill ADD CONSTRAINT fk_bil_bill_cost_center_id FOREIGN KEY (cost_center_id) REFERENCES revenuefinance.fin_cost_center(cost_center_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bil_bill_cost_center_id ON revenuefinance.bil_bill(cost_center_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_bill_b2b_payer_id') THEN
        ALTER TABLE revenuefinance.bil_bill ADD CONSTRAINT fk_bil_bill_b2b_payer_id FOREIGN KEY (b2b_payer_id) REFERENCES revenuefinance.mst_payer(payer_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bil_bill_b2b_payer_id ON revenuefinance.bil_bill(b2b_payer_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_bill_corporate_invoice_id') THEN
        ALTER TABLE revenuefinance.bil_bill ADD CONSTRAINT fk_bil_bill_corporate_invoice_id FOREIGN KEY (corporate_invoice_id) REFERENCES revenuefinance.bil_corporate_invoice(corporate_invoice_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bil_bill_corporate_invoice_id ON revenuefinance.bil_bill(corporate_invoice_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_bill_line_cost_center_id') THEN
        ALTER TABLE revenuefinance.bil_bill_line ADD CONSTRAINT fk_bil_bill_line_cost_center_id FOREIGN KEY (cost_center_id) REFERENCES revenuefinance.fin_cost_center(cost_center_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bil_bill_line_cost_center_id ON revenuefinance.bil_bill_line(cost_center_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_bill_line_package_episode_id') THEN
        ALTER TABLE revenuefinance.bil_bill_line ADD CONSTRAINT fk_bil_bill_line_package_episode_id FOREIGN KEY (package_episode_id) REFERENCES revenuefinance.bil_package_episode(package_episode_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bil_bill_line_package_episode_id ON revenuefinance.bil_bill_line(package_episode_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_bill_line_kit_id') THEN
        ALTER TABLE revenuefinance.bil_bill_line ADD CONSTRAINT fk_bil_bill_line_kit_id FOREIGN KEY (kit_id) REFERENCES revenuefinance.mst_kit(kit_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bil_bill_line_kit_id ON revenuefinance.bil_bill_line(kit_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_credit_note_receipt_id') THEN
        ALTER TABLE revenuefinance.bil_credit_note ADD CONSTRAINT fk_bil_credit_note_receipt_id FOREIGN KEY (receipt_id) REFERENCES revenuefinance.bil_receipt(receipt_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bil_credit_note_receipt_id ON revenuefinance.bil_credit_note(receipt_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_doctor_payout_reversal_of_payout_id') THEN
        ALTER TABLE revenuefinance.bil_doctor_payout ADD CONSTRAINT fk_bil_doctor_payout_reversal_of_payout_id FOREIGN KEY (reversal_of_payout_id) REFERENCES revenuefinance.bil_doctor_payout(doctor_payout_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bil_doctor_payout_reversal_of_payout_id ON revenuefinance.bil_doctor_payout(reversal_of_payout_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_doctor_payout_doctor_statement_id') THEN
        ALTER TABLE revenuefinance.bil_doctor_payout ADD CONSTRAINT fk_bil_doctor_payout_doctor_statement_id FOREIGN KEY (doctor_statement_id) REFERENCES revenuefinance.bil_doctor_statement(doctor_statement_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bil_doctor_payout_doctor_statement_id ON revenuefinance.bil_doctor_payout(doctor_statement_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_doctor_payout_rule_doctor_contract_id') THEN
        ALTER TABLE revenuefinance.bil_doctor_payout_rule ADD CONSTRAINT fk_bil_doctor_payout_rule_doctor_contract_id FOREIGN KEY (doctor_contract_id) REFERENCES revenuefinance.bil_doctor_contract(doctor_contract_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bil_doctor_payout_rule_doctor_contract_id ON revenuefinance.bil_doctor_payout_rule(doctor_contract_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_doctor_payout_rule_package_id') THEN
        ALTER TABLE revenuefinance.bil_doctor_payout_rule ADD CONSTRAINT fk_bil_doctor_payout_rule_package_id FOREIGN KEY (package_id) REFERENCES revenuefinance.mst_package(package_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bil_doctor_payout_rule_package_id ON revenuefinance.bil_doctor_payout_rule(package_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_doctor_payout_rule_referral_agent_id') THEN
        ALTER TABLE revenuefinance.bil_doctor_payout_rule ADD CONSTRAINT fk_bil_doctor_payout_rule_referral_agent_id FOREIGN KEY (referral_agent_id) REFERENCES revenuefinance.bil_referral_agent(referral_agent_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bil_doctor_payout_rule_referral_agent_id ON revenuefinance.bil_doctor_payout_rule(referral_agent_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_loyalty_account_loyalty_tier_id') THEN
        ALTER TABLE revenuefinance.bil_loyalty_account ADD CONSTRAINT fk_bil_loyalty_account_loyalty_tier_id FOREIGN KEY (loyalty_tier_id) REFERENCES revenuefinance.mst_loyalty_tier(loyalty_tier_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bil_loyalty_account_loyalty_tier_id ON revenuefinance.bil_loyalty_account(loyalty_tier_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_loyalty_txn_loyalty_rule_id') THEN
        ALTER TABLE revenuefinance.bil_loyalty_txn ADD CONSTRAINT fk_bil_loyalty_txn_loyalty_rule_id FOREIGN KEY (loyalty_rule_id) REFERENCES revenuefinance.mst_loyalty_rule(loyalty_rule_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bil_loyalty_txn_loyalty_rule_id ON revenuefinance.bil_loyalty_txn(loyalty_rule_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_loyalty_txn_receipt_id') THEN
        ALTER TABLE revenuefinance.bil_loyalty_txn ADD CONSTRAINT fk_bil_loyalty_txn_receipt_id FOREIGN KEY (receipt_id) REFERENCES revenuefinance.bil_receipt(receipt_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bil_loyalty_txn_receipt_id ON revenuefinance.bil_loyalty_txn(receipt_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_loyalty_txn_reversal_of_txn_id') THEN
        ALTER TABLE revenuefinance.bil_loyalty_txn ADD CONSTRAINT fk_bil_loyalty_txn_reversal_of_txn_id FOREIGN KEY (reversal_of_txn_id) REFERENCES revenuefinance.bil_loyalty_txn(loyalty_txn_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bil_loyalty_txn_reversal_of_txn_id ON revenuefinance.bil_loyalty_txn(reversal_of_txn_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_receipt_cashier_shift_id') THEN
        ALTER TABLE revenuefinance.bil_receipt ADD CONSTRAINT fk_bil_receipt_cashier_shift_id FOREIGN KEY (cashier_shift_id) REFERENCES revenuefinance.bil_cashier_shift(cashier_shift_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bil_receipt_cashier_shift_id ON revenuefinance.bil_receipt(cashier_shift_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_bil_receipt_patient_account_id') THEN
        ALTER TABLE revenuefinance.bil_receipt ADD CONSTRAINT fk_bil_receipt_patient_account_id FOREIGN KEY (patient_account_id) REFERENCES revenuefinance.bil_patient_account(patient_account_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_bil_receipt_patient_account_id ON revenuefinance.bil_receipt(patient_account_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_fin_voucher_cost_center_id') THEN
        ALTER TABLE revenuefinance.fin_voucher ADD CONSTRAINT fk_fin_voucher_cost_center_id FOREIGN KEY (cost_center_id) REFERENCES revenuefinance.fin_cost_center(cost_center_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_fin_voucher_cost_center_id ON revenuefinance.fin_voucher(cost_center_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_fin_voucher_bank_account_id') THEN
        ALTER TABLE revenuefinance.fin_voucher ADD CONSTRAINT fk_fin_voucher_bank_account_id FOREIGN KEY (bank_account_id) REFERENCES revenuefinance.fin_bank_account(bank_account_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_fin_voucher_bank_account_id ON revenuefinance.fin_voucher(bank_account_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_fin_voucher_cancelled_by_voucher_id') THEN
        ALTER TABLE revenuefinance.fin_voucher ADD CONSTRAINT fk_fin_voucher_cancelled_by_voucher_id FOREIGN KEY (cancelled_by_voucher_id) REFERENCES revenuefinance.fin_voucher(voucher_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_fin_voucher_cancelled_by_voucher_id ON revenuefinance.fin_voucher(cancelled_by_voucher_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_ins_preauth_enhancement_of_preauth_id') THEN
        ALTER TABLE revenuefinance.ins_preauth ADD CONSTRAINT fk_ins_preauth_enhancement_of_preauth_id FOREIGN KEY (enhancement_of_preauth_id) REFERENCES revenuefinance.ins_preauth(preauth_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_ins_preauth_enhancement_of_preauth_id ON revenuefinance.ins_preauth(enhancement_of_preauth_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'revenuefinance' AND c.conname = 'fk_mst_package_copay_rule_id') THEN
        ALTER TABLE revenuefinance.mst_package ADD CONSTRAINT fk_mst_package_copay_rule_id FOREIGN KEY (copay_rule_id) REFERENCES revenuefinance.mst_copay_rule(copay_rule_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_mst_package_copay_rule_id ON revenuefinance.mst_package(copay_rule_id);

/* ---------- D. INDEXES ---------- */
CREATE INDEX IF NOT EXISTS ix_bil_patient_account_patient_id ON revenuefinance.bil_patient_account(patient_id);
CREATE INDEX IF NOT EXISTS ix_bil_patient_account_encounter_id ON revenuefinance.bil_patient_account(encounter_id);
CREATE INDEX IF NOT EXISTS ix_bil_patient_account_primary_payer_id ON revenuefinance.bil_patient_account(primary_payer_id);
CREATE INDEX IF NOT EXISTS ix_bil_patient_account_tariff_plan_id ON revenuefinance.bil_patient_account(tariff_plan_id);
CREATE INDEX IF NOT EXISTS ix_bil_patient_account_estimate_id ON revenuefinance.bil_patient_account(estimate_id);
CREATE INDEX IF NOT EXISTS ix_bil_deposit_request_patient_account_id ON revenuefinance.bil_deposit_request(patient_account_id);
CREATE INDEX IF NOT EXISTS ix_bil_deposit_request_receipt_id ON revenuefinance.bil_deposit_request(receipt_id);
CREATE INDEX IF NOT EXISTS ix_bil_refund_request_patient_id ON revenuefinance.bil_refund_request(patient_id);
CREATE INDEX IF NOT EXISTS ix_bil_refund_request_bill_id ON revenuefinance.bil_refund_request(bill_id);
CREATE INDEX IF NOT EXISTS ix_bil_refund_request_receipt_id ON revenuefinance.bil_refund_request(receipt_id);
CREATE INDEX IF NOT EXISTS ix_bil_refund_request_payment_gateway_txn_id ON revenuefinance.bil_refund_request(payment_gateway_txn_id);
CREATE INDEX IF NOT EXISTS ix_bil_payment_gateway_event_payment_gateway_txn_id ON revenuefinance.bil_payment_gateway_event(payment_gateway_txn_id);
CREATE INDEX IF NOT EXISTS ix_bil_cancellation_policy_service_category_id ON revenuefinance.bil_cancellation_policy(service_category_id);
CREATE INDEX IF NOT EXISTS ix_bil_recurring_charge_rule_service_id ON revenuefinance.bil_recurring_charge_rule(service_id);
CREATE INDEX IF NOT EXISTS ix_mst_package_payer_payer_id ON revenuefinance.mst_package_payer(payer_id);
CREATE INDEX IF NOT EXISTS ix_bil_package_episode_patient_account_id ON revenuefinance.bil_package_episode(patient_account_id);
CREATE INDEX IF NOT EXISTS ix_bil_package_episode_package_id ON revenuefinance.bil_package_episode(package_id);
CREATE INDEX IF NOT EXISTS ix_bil_package_episode_changed_from_package_id ON revenuefinance.bil_package_episode(changed_from_package_id);
CREATE INDEX IF NOT EXISTS ix_bil_coupon_redemption_coupon_id ON revenuefinance.bil_coupon_redemption(coupon_id);
CREATE INDEX IF NOT EXISTS ix_bil_coupon_redemption_bill_id ON revenuefinance.bil_coupon_redemption(bill_id);
CREATE INDEX IF NOT EXISTS ix_bil_coupon_redemption_online_order_id ON revenuefinance.bil_coupon_redemption(online_order_id);
CREATE INDEX IF NOT EXISTS ix_bil_coupon_redemption_patient_id ON revenuefinance.bil_coupon_redemption(patient_id);
CREATE INDEX IF NOT EXISTS ix_mst_kit_service_id ON revenuefinance.mst_kit(service_id);
CREATE INDEX IF NOT EXISTS ix_mst_kit_item_kit_id ON revenuefinance.mst_kit_item(kit_id);
CREATE INDEX IF NOT EXISTS ix_bil_payer_split_patient_account_id ON revenuefinance.bil_payer_split(patient_account_id);
CREATE INDEX IF NOT EXISTS ix_bil_payer_split_payer_id ON revenuefinance.bil_payer_split(payer_id);
CREATE INDEX IF NOT EXISTS ix_bil_waiver_request_bill_id ON revenuefinance.bil_waiver_request(bill_id);
CREATE INDEX IF NOT EXISTS ix_bil_waiver_request_patient_account_id ON revenuefinance.bil_waiver_request(patient_account_id);
CREATE INDEX IF NOT EXISTS ix_mst_loyalty_rule_service_category_id ON revenuefinance.mst_loyalty_rule(service_category_id);
CREATE INDEX IF NOT EXISTS ix_mst_insurance_plan_tariff_plan_id ON revenuefinance.mst_insurance_plan(tariff_plan_id);
CREATE INDEX IF NOT EXISTS ix_mst_insurance_sublimit_insurance_plan_id ON revenuefinance.mst_insurance_sublimit(insurance_plan_id);
CREATE INDEX IF NOT EXISTS ix_mst_insurance_sublimit_service_category_id ON revenuefinance.mst_insurance_sublimit(service_category_id);
CREATE INDEX IF NOT EXISTS ix_mst_payer_network_insurer_payer_id ON revenuefinance.mst_payer_network(insurer_payer_id);
CREATE INDEX IF NOT EXISTS ix_mst_payer_network_tpa_payer_id ON revenuefinance.mst_payer_network(tpa_payer_id);
CREATE INDEX IF NOT EXISTS ix_mst_copay_rule_payer_id ON revenuefinance.mst_copay_rule(payer_id);
CREATE INDEX IF NOT EXISTS ix_mst_copay_rule_insurance_plan_id ON revenuefinance.mst_copay_rule(insurance_plan_id);
CREATE INDEX IF NOT EXISTS ix_mst_copay_rule_service_category_id ON revenuefinance.mst_copay_rule(service_category_id);
CREATE INDEX IF NOT EXISTS ix_ins_document_checklist_payer_id ON revenuefinance.ins_document_checklist(payer_id);
CREATE INDEX IF NOT EXISTS ix_ins_claim_document_preauth_id ON revenuefinance.ins_claim_document(preauth_id);
CREATE INDEX IF NOT EXISTS ix_ins_claim_document_claim_id ON revenuefinance.ins_claim_document(claim_id);
CREATE INDEX IF NOT EXISTS ix_ins_claim_appeal_claim_denial_id ON revenuefinance.ins_claim_appeal(claim_denial_id);
CREATE INDEX IF NOT EXISTS ix_bil_corporate_invoice_payer_id ON revenuefinance.bil_corporate_invoice(payer_id);
CREATE INDEX IF NOT EXISTS ix_bil_doctor_statement_referral_agent_id ON revenuefinance.bil_doctor_statement(referral_agent_id);
CREATE INDEX IF NOT EXISTS ix_bil_doctor_statement_payment_voucher_id ON revenuefinance.bil_doctor_statement(payment_voucher_id);
CREATE INDEX IF NOT EXISTS ix_bil_doctor_statement_query_doctor_statement_id ON revenuefinance.bil_doctor_statement_query(doctor_statement_id);
CREATE INDEX IF NOT EXISTS ix_bil_doctor_statement_query_doctor_payout_id ON revenuefinance.bil_doctor_statement_query(doctor_payout_id);
CREATE INDEX IF NOT EXISTS ix_fin_tds_entry_voucher_id ON revenuefinance.fin_tds_entry(voucher_id);
CREATE INDEX IF NOT EXISTS ix_fin_tds_entry_tds_challan_id ON revenuefinance.fin_tds_entry(tds_challan_id);
CREATE INDEX IF NOT EXISTS ix_fin_gst_itc_reconciliation_supplier_invoice_id ON revenuefinance.fin_gst_itc_reconciliation(supplier_invoice_id);
CREATE INDEX IF NOT EXISTS ix_fin_supplier_invoice_voucher_id ON revenuefinance.fin_supplier_invoice(voucher_id);
CREATE INDEX IF NOT EXISTS ix_fin_payment_allocation_voucher_id ON revenuefinance.fin_payment_allocation(voucher_id);
CREATE INDEX IF NOT EXISTS ix_fin_payment_allocation_supplier_invoice_id ON revenuefinance.fin_payment_allocation(supplier_invoice_id);
CREATE INDEX IF NOT EXISTS ix_fin_asset_transaction_from_cost_center_id ON revenuefinance.fin_asset_transaction(from_cost_center_id);
CREATE INDEX IF NOT EXISTS ix_fin_asset_transaction_to_cost_center_id ON revenuefinance.fin_asset_transaction(to_cost_center_id);
CREATE INDEX IF NOT EXISTS ix_fin_asset_transaction_voucher_id ON revenuefinance.fin_asset_transaction(voucher_id);
CREATE INDEX IF NOT EXISTS ix_fin_cash_forecast_bank_account_id ON revenuefinance.fin_cash_forecast(bank_account_id);
CREATE INDEX IF NOT EXISTS ix_bil_leakage_exception_patient_account_id ON revenuefinance.bil_leakage_exception(patient_account_id);
CREATE INDEX IF NOT EXISTS ix_bil_leakage_exception_service_id ON revenuefinance.bil_leakage_exception(service_id);

/* ---------- E. TABLE COMMENTS (FDS traceability) ---------- */
COMMENT ON TABLE revenuefinance.bil_patient_account IS 'Visit-level patient account to which all modules post charges (UHID, visit, payer class, status, balance) [FDS: CORE-001, CORE-003, IPB-001 (Patient account entity)]';
COMMENT ON TABLE revenuefinance.bil_bill_number_void IS 'Gaps in bill / receipt number series with recorded reason [FDS: CORE-009]';
COMMENT ON TABLE revenuefinance.bil_cashier_shift IS 'Cashier shifts: opening float, mode-wise collections, handover, closing, variance approval [FDS: PAY-004, PAY-007]';
COMMENT ON TABLE revenuefinance.bil_deposit_request IS 'Deposit top-up requests and minimum-deposit alerts [FDS: ACC-001, IPB-001]';
COMMENT ON TABLE revenuefinance.bil_refund_request IS 'Refund requests linked to bill / receipt with approval by amount hierarchy (includes gateway refunds) [FDS: ACC-002..005, ORD-008, MFF-004, DSC-CAN-004, LAB-006, OPB-003/004]';
COMMENT ON TABLE revenuefinance.bil_payment_gateway_event IS 'Gateway callbacks / polling results (server-to-server verification) [FDS: PAY-005, CHK-005]';
COMMENT ON TABLE revenuefinance.bil_cancellation_policy IS 'Cancellation / refund policy by service category and order stage [FDS: LAB-006, OPB-003, ORD-006, DSC-CAN-004, TSL-005]';
COMMENT ON TABLE revenuefinance.bil_followup_rule IS 'Free follow-up validity window per doctor / specialty [FDS: OPB-002, OBK-008, BKG-003]';
COMMENT ON TABLE revenuefinance.bil_recurring_charge_rule IS 'Recurring IP charges (bed rent, nursing, monitoring) with day cut-off and prorating [FDS: IPB-002]';
COMMENT ON TABLE revenuefinance.bil_surgery_fee_rule IS 'OT fee rules: surgeon / anaesthetist / assistant shares and multiple-procedure rules [FDS: IPB-004, DOC-006]';
COMMENT ON TABLE revenuefinance.mst_package_payer IS 'Applicable payers for a package [FDS: TAR-003]';
COMMENT ON TABLE revenuefinance.bil_package_episode IS 'Package applied to an episode: consumption vs inclusions, upgrade / downgrade / extension [FDS: TAR-004, TAR-005, IPB-006]';
COMMENT ON TABLE revenuefinance.bil_coupon_redemption IS 'Coupon validation, redemption and reversal with audit [FDS: TAR-007, TAR-008]';
COMMENT ON TABLE revenuefinance.mst_kit IS 'KIT definitions (procedure / OT kits) with price [FDS: TAR-009]';
COMMENT ON TABLE revenuefinance.mst_kit_item IS 'KIT component items and quantities (stock deducted by component and batch) [FDS: TAR-009]';
COMMENT ON TABLE revenuefinance.bil_payer_split IS 'Split of an episode across payers (insurer, corporate, patient, scheme) by item / category / percentage [FDS: TAR-010, TAR-011, INS-005]';
COMMENT ON TABLE revenuefinance.bil_waiver_request IS 'Waiver requests (separate from discounts) with documents and multi-level approval [FDS: TAR-012]';
COMMENT ON TABLE revenuefinance.bil_approval_step IS 'Generic multi-level approval steps for discounts, waivers, refunds, write-offs, credit notes [FDS: CORE-004, TAR-012, ACC-004, DOC-003]';
COMMENT ON TABLE revenuefinance.mst_loyalty_tier IS 'Loyalty membership tiers [FDS: LOY-001]';
COMMENT ON TABLE revenuefinance.mst_loyalty_rule IS 'Points earning / redemption rules (spend, service type, campaign multipliers, birthday / referral bonus, limits) [FDS: LOY-002, LOY-004, LOY-005]';
COMMENT ON TABLE revenuefinance.mst_insurance_plan IS 'Insurer plans / policies: sum insured, room-rent limit, sub-limits, exclusions [FDS: INS-001, INS-004]';
COMMENT ON TABLE revenuefinance.mst_insurance_sublimit IS 'Plan sub-limits by service category / procedure / disease [FDS: INS-001, INS-004]';
COMMENT ON TABLE revenuefinance.mst_payer_network IS 'Insurer-TPA mappings and hospital network empanelment [FDS: INS-001, GOV-003]';
COMMENT ON TABLE revenuefinance.mst_copay_rule IS 'Co-pay / deductible rules by payer, plan, service category and room category [FDS: INS-004, INS-013, TAR-003]';
COMMENT ON TABLE revenuefinance.ins_document_checklist IS 'Mandatory document checklist per insurer / scheme and stage [FDS: INS-009, INS-008]';
COMMENT ON TABLE revenuefinance.ins_claim_document IS 'Documents attached to pre-auth / claim against the checklist [FDS: INS-006, INS-008, INS-009]';
COMMENT ON TABLE revenuefinance.ins_claim_appeal IS 'Denial appeals with owner, due date, outcome and write-off approval [FDS: INS-014, INS-015]';
COMMENT ON TABLE revenuefinance.bil_corporate_invoice IS 'Monthly consolidated corporate / MNC / Mediclaim invoice with PO reference and employer guarantee [FDS: GOV-007, ACC-010]';
COMMENT ON TABLE revenuefinance.bil_doctor_contract IS 'Doctor contracts: effective dates, minimum guarantee, caps, discount bearing, share timing [FDS: DOC-001, DOC-005, DOC-007 (Doctor contract entity)]';
COMMENT ON TABLE revenuefinance.bil_referral_agent IS 'External referring doctors / agencies for referral fees (with compliance flags) [FDS: DOC-003]';
COMMENT ON TABLE revenuefinance.bil_doctor_statement IS 'Monthly doctor statement / ledger with TDS, approval and payment voucher [FDS: DOC-008, DOC-010]';
COMMENT ON TABLE revenuefinance.bil_doctor_statement_query IS 'Doctor queries on statement lines with resolution trail [FDS: DOC-009]';
COMMENT ON TABLE revenuefinance.mst_hsn_sac IS 'HSN / SAC master with effective-dated GST rates (CGST, SGST, IGST, cess) and exemption [FDS: TAX-001, HSN-001..007 (Pharmacy)]';
COMMENT ON TABLE revenuefinance.fin_einvoice_log IS 'E-invoice (IRN) and e-way bill generation log [FDS: TAX-003]';
COMMENT ON TABLE revenuefinance.fin_tds_entry IS 'TDS deducted on payments (doctors, vendors, contractors) and TDS receivable on receipts [FDS: TAX-005..008, PHB-010, DOC-008]';
COMMENT ON TABLE revenuefinance.fin_tds_challan IS 'TDS challans for 26Q / 24Q filing [FDS: TAX-007]';
COMMENT ON TABLE revenuefinance.fin_gst_itc_reconciliation IS 'GSTR-2B input-tax-credit reconciliation lines [FDS: TAX-002, TAX-004, TAX-009]';
COMMENT ON TABLE revenuefinance.fin_supplier_invoice IS 'Supplier purchase invoice / payable linked to GRN with three-way match and ITC eligibility [FDS: PHB-009, PHB-013, PUR-006, PUR-010, GRN-008, TAX-009 (Pharmacy & Billing)]';
COMMENT ON TABLE revenuefinance.fin_payment_allocation IS 'Bill-wise settlement of payments / debit notes against supplier invoices [FDS: PHB-010, VCH-003, VEN-006]';
COMMENT ON TABLE revenuefinance.fin_asset_transaction IS 'Fixed asset capitalisation, transfer and disposal posted to ledger [FDS: MIS-007]';
COMMENT ON TABLE revenuefinance.fin_cash_forecast IS 'Daily cash position and projection [FDS: MIS-008]';
COMMENT ON TABLE revenuefinance.bil_leakage_exception IS 'Under-billing detection: ordered / performed / consumed / prescribed vs billed [FDS: MIS-006, MIS-014]';

COMMIT;
