/* =====================================================================================
   DR REDDIS HEALTHCARE - HIMS  database_v3 (7 services)  ->  database_v4 (9 services)
   Step 07 - Operations & Supply Chain: column additions to existing tables + new FDS tables
   Run against an EXISTING himsdev database that was built from database_v3, in file-name order:
     00_restructure_7_to_9_services.sql  -> 01..09_<service>_delta.sql  -> 10_post_migration_housekeeping.sql -> ../full/roles.sql
   Every statement is idempotent where PostgreSQL allows it (IF NOT EXISTS / guarded DO blocks).
   ===================================================================================== */

BEGIN;

/* ---------- A. MODIFICATIONS TO EXISTING TABLES (ADD COLUMN) ---------- */

-- operationssupply.adm_complaint  (3 new columns)  FDS: ORD-009 (help request against order), RET-010
ALTER TABLE operationssupply.adm_complaint ADD COLUMN IF NOT EXISTS online_order_id BIGINT NULL;
ALTER TABLE operationssupply.adm_complaint ADD COLUMN IF NOT EXISTS attachment_document_id BIGINT NULL;
ALTER TABLE operationssupply.adm_complaint ADD COLUMN IF NOT EXISTS complaint_channel VARCHAR(20) NULL;
COMMENT ON COLUMN operationssupply.adm_complaint.online_order_id IS '[v4: ORD-009 (help request against order), RET-010]';
COMMENT ON COLUMN operationssupply.adm_complaint.attachment_document_id IS '[v4: ORD-009 (help request against order), RET-010]';
COMMENT ON COLUMN operationssupply.adm_complaint.complaint_channel IS '[v4: ORD-009 (help request against order), RET-010]';

-- operationssupply.fld_cold_chain_reading  (2 new columns)  FDS: PCS-008, LAB-TRK-008
ALTER TABLE operationssupply.fld_cold_chain_reading ADD COLUMN IF NOT EXISTS transport_batch_ref VARCHAR(30) NULL;
ALTER TABLE operationssupply.fld_cold_chain_reading ADD COLUMN IF NOT EXISTS agent_id BIGINT NULL;
COMMENT ON COLUMN operationssupply.fld_cold_chain_reading.transport_batch_ref IS 'lims.lab_transport_batch.batch_no (bag id) [v4: PCS-008, LAB-TRK-008]';
COMMENT ON COLUMN operationssupply.fld_cold_chain_reading.agent_id IS '[v4: PCS-008, LAB-TRK-008]';

-- operationssupply.fld_gps_ping  (2 new columns)  FDS: OPS-007
ALTER TABLE operationssupply.fld_gps_ping ADD COLUMN IF NOT EXISTS agent_id BIGINT NULL;
ALTER TABLE operationssupply.fld_gps_ping ADD COLUMN IF NOT EXISTS task_id BIGINT NULL;
COMMENT ON COLUMN operationssupply.fld_gps_ping.agent_id IS '[v4: OPS-007]';
COMMENT ON COLUMN operationssupply.fld_gps_ping.task_id IS '[v4: OPS-007]';

-- operationssupply.fld_service_request  (2 new columns)  FDS: Links demand requests to online orders / tasks
ALTER TABLE operationssupply.fld_service_request ADD COLUMN IF NOT EXISTS online_order_id BIGINT NULL;
ALTER TABLE operationssupply.fld_service_request ADD COLUMN IF NOT EXISTS task_id BIGINT NULL;
COMMENT ON COLUMN operationssupply.fld_service_request.online_order_id IS '[v4: Links demand requests to online orders / tasks]';
COMMENT ON COLUMN operationssupply.fld_service_request.task_id IS '[v4: Links demand requests to online orders / tasks]';

-- operationssupply.fld_trip  (3 new columns)  FDS: OPS-004 (route building)
ALTER TABLE operationssupply.fld_trip ADD COLUMN IF NOT EXISTS agent_id BIGINT NULL;
ALTER TABLE operationssupply.fld_trip ADD COLUMN IF NOT EXISTS route_json JSONB NULL;
ALTER TABLE operationssupply.fld_trip ADD COLUMN IF NOT EXISTS planned_distance_km DECIMAL(8,2) NULL;
COMMENT ON COLUMN operationssupply.fld_trip.agent_id IS '[v4: OPS-004 (route building)]';
COMMENT ON COLUMN operationssupply.fld_trip.route_json IS '[v4: OPS-004 (route building)]';
COMMENT ON COLUMN operationssupply.fld_trip.planned_distance_km IS '[v4: OPS-004 (route building)]';

-- operationssupply.inv_consumption  (5 new columns)  FDS: CON-001, CON-003, CON-007, IPI-008
ALTER TABLE operationssupply.inv_consumption ADD COLUMN IF NOT EXISTS cost_center_id INT NULL;
ALTER TABLE operationssupply.inv_consumption ADD COLUMN IF NOT EXISTS practitioner_id BIGINT NULL;
ALTER TABLE operationssupply.inv_consumption ADD COLUMN IF NOT EXISTS procedure_ref VARCHAR(50) NULL;
ALTER TABLE operationssupply.inv_consumption ADD COLUMN IF NOT EXISTS reversed_by_consumption_id BIGINT NULL;
ALTER TABLE operationssupply.inv_consumption ADD COLUMN IF NOT EXISTS voucher_id BIGINT NULL;
COMMENT ON COLUMN operationssupply.inv_consumption.cost_center_id IS '[v4: CON-001, CON-003, CON-007, IPI-008]';
COMMENT ON COLUMN operationssupply.inv_consumption.practitioner_id IS '[v4: CON-001, CON-003, CON-007, IPI-008]';
COMMENT ON COLUMN operationssupply.inv_consumption.procedure_ref IS '[v4: CON-001, CON-003, CON-007, IPI-008]';
COMMENT ON COLUMN operationssupply.inv_consumption.reversed_by_consumption_id IS '[v4: CON-001, CON-003, CON-007, IPI-008]';
COMMENT ON COLUMN operationssupply.inv_consumption.voucher_id IS '[v4: CON-001, CON-003, CON-007, IPI-008]';

-- operationssupply.inv_grn  (14 new columns)  FDS: GRN-001..010 (GRN / purchase entity)
ALTER TABLE operationssupply.inv_grn ADD COLUMN IF NOT EXISTS is_direct_grn BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE operationssupply.inv_grn ADD COLUMN IF NOT EXISTS challan_no VARCHAR(50) NULL;
ALTER TABLE operationssupply.inv_grn ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) NULL DEFAULT 'PENDING';
ALTER TABLE operationssupply.inv_grn ADD COLUMN IF NOT EXISTS approved_by BIGINT NULL;
ALTER TABLE operationssupply.inv_grn ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ(0) NULL;
ALTER TABLE operationssupply.inv_grn ADD COLUMN IF NOT EXISTS qc_status VARCHAR(20) NULL;
ALTER TABLE operationssupply.inv_grn ADD COLUMN IF NOT EXISTS arrival_temperature_c DECIMAL(5,2) NULL;
ALTER TABLE operationssupply.inv_grn ADD COLUMN IF NOT EXISTS packaging_ok BOOLEAN NULL;
ALTER TABLE operationssupply.inv_grn ADD COLUMN IF NOT EXISTS labelling_ok BOOLEAN NULL;
ALTER TABLE operationssupply.inv_grn ADD COLUMN IF NOT EXISTS documents_ok BOOLEAN NULL;
ALTER TABLE operationssupply.inv_grn ADD COLUMN IF NOT EXISTS invoice_match_status VARCHAR(20) NULL;
ALTER TABLE operationssupply.inv_grn ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ(0) NULL;
ALTER TABLE operationssupply.inv_grn ADD COLUMN IF NOT EXISTS cancel_reason VARCHAR(300) NULL;
ALTER TABLE operationssupply.inv_grn ADD COLUMN IF NOT EXISTS supplier_invoice_id BIGINT NULL;
COMMENT ON COLUMN operationssupply.inv_grn.is_direct_grn IS '[v4: GRN-001..010 (GRN / purchase entity)]';
COMMENT ON COLUMN operationssupply.inv_grn.challan_no IS '[v4: GRN-001..010 (GRN / purchase entity)]';
COMMENT ON COLUMN operationssupply.inv_grn.approval_status IS 'PENDING, APPROVED, REJECTED, CANCELLED [v4: GRN-001..010 (GRN / purchase entity)]';
COMMENT ON COLUMN operationssupply.inv_grn.approved_by IS '[v4: GRN-001..010 (GRN / purchase entity)]';
COMMENT ON COLUMN operationssupply.inv_grn.approved_at IS '[v4: GRN-001..010 (GRN / purchase entity)]';
COMMENT ON COLUMN operationssupply.inv_grn.qc_status IS 'PASSED, FAILED, PARTIAL [v4: GRN-001..010 (GRN / purchase entity)]';
COMMENT ON COLUMN operationssupply.inv_grn.arrival_temperature_c IS '[v4: GRN-001..010 (GRN / purchase entity)]';
COMMENT ON COLUMN operationssupply.inv_grn.packaging_ok IS '[v4: GRN-001..010 (GRN / purchase entity)]';
COMMENT ON COLUMN operationssupply.inv_grn.labelling_ok IS '[v4: GRN-001..010 (GRN / purchase entity)]';
COMMENT ON COLUMN operationssupply.inv_grn.documents_ok IS '[v4: GRN-001..010 (GRN / purchase entity)]';
COMMENT ON COLUMN operationssupply.inv_grn.invoice_match_status IS 'NOT_INVOICED, MATCHED, VARIANCE [v4: GRN-001..010 (GRN / purchase entity)]';
COMMENT ON COLUMN operationssupply.inv_grn.cancelled_at IS '[v4: GRN-001..010 (GRN / purchase entity)]';
COMMENT ON COLUMN operationssupply.inv_grn.cancel_reason IS '[v4: GRN-001..010 (GRN / purchase entity)]';
COMMENT ON COLUMN operationssupply.inv_grn.supplier_invoice_id IS 'revenuefinance.fin_supplier_invoice [v4: GRN-001..010 (GRN / purchase entity)]';

-- operationssupply.inv_grn_item  (8 new columns)  FDS: GRN-002..006
ALTER TABLE operationssupply.inv_grn_item ADD COLUMN IF NOT EXISTS accepted_qty DECIMAL(12,2) NULL;
ALTER TABLE operationssupply.inv_grn_item ADD COLUMN IF NOT EXISTS short_expiry_approved_by BIGINT NULL;
ALTER TABLE operationssupply.inv_grn_item ADD COLUMN IF NOT EXISTS qc_decision VARCHAR(20) NULL;
ALTER TABLE operationssupply.inv_grn_item ADD COLUMN IF NOT EXISTS qty_variance DECIMAL(12,2) NULL;
ALTER TABLE operationssupply.inv_grn_item ADD COLUMN IF NOT EXISTS rate_variance DECIMAL(12,4) NULL;
ALTER TABLE operationssupply.inv_grn_item ADD COLUMN IF NOT EXISTS scheme_discount DECIMAL(12,2) NULL;
ALTER TABLE operationssupply.inv_grn_item ADD COLUMN IF NOT EXISTS cess_amount DECIMAL(12,2) NULL;
ALTER TABLE operationssupply.inv_grn_item ADD COLUMN IF NOT EXISTS store_location_id INT NULL;
COMMENT ON COLUMN operationssupply.inv_grn_item.accepted_qty IS '[v4: GRN-002..006]';
COMMENT ON COLUMN operationssupply.inv_grn_item.short_expiry_approved_by IS '[v4: GRN-002..006]';
COMMENT ON COLUMN operationssupply.inv_grn_item.qc_decision IS 'ACCEPT, REJECT, QUARANTINE [v4: GRN-002..006]';
COMMENT ON COLUMN operationssupply.inv_grn_item.qty_variance IS '[v4: GRN-002..006]';
COMMENT ON COLUMN operationssupply.inv_grn_item.rate_variance IS '[v4: GRN-002..006]';
COMMENT ON COLUMN operationssupply.inv_grn_item.scheme_discount IS '[v4: GRN-002..006]';
COMMENT ON COLUMN operationssupply.inv_grn_item.cess_amount IS '[v4: GRN-002..006]';
COMMENT ON COLUMN operationssupply.inv_grn_item.store_location_id IS '[v4: GRN-002..006]';

-- operationssupply.inv_indent  (11 new columns)  FDS: IND-001..007, IPI-008 (Indent entity)
ALTER TABLE operationssupply.inv_indent ADD COLUMN IF NOT EXISTS department_id INT NULL;
ALTER TABLE operationssupply.inv_indent ADD COLUMN IF NOT EXISTS priority VARCHAR(10) NULL;
ALTER TABLE operationssupply.inv_indent ADD COLUMN IF NOT EXISTS is_standing BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE operationssupply.inv_indent ADD COLUMN IF NOT EXISTS standing_frequency VARCHAR(20) NULL;
ALTER TABLE operationssupply.inv_indent ADD COLUMN IF NOT EXISTS next_standing_due DATE NULL;
ALTER TABLE operationssupply.inv_indent ADD COLUMN IF NOT EXISTS rejection_reason VARCHAR(300) NULL;
ALTER TABLE operationssupply.inv_indent ADD COLUMN IF NOT EXISTS purchase_request_id BIGINT NULL;
ALTER TABLE operationssupply.inv_indent ADD COLUMN IF NOT EXISTS issued_at TIMESTAMPTZ(0) NULL;
ALTER TABLE operationssupply.inv_indent ADD COLUMN IF NOT EXISTS received_at TIMESTAMPTZ(0) NULL;
ALTER TABLE operationssupply.inv_indent ADD COLUMN IF NOT EXISTS closed_at TIMESTAMPTZ(0) NULL;
ALTER TABLE operationssupply.inv_indent ADD COLUMN IF NOT EXISTS admission_id BIGINT NULL;
COMMENT ON COLUMN operationssupply.inv_indent.department_id IS '[v4: IND-001..007, IPI-008 (Indent entity)]';
COMMENT ON COLUMN operationssupply.inv_indent.priority IS 'ROUTINE, URGENT, EMERGENCY [v4: IND-001..007, IPI-008 (Indent entity)]';
COMMENT ON COLUMN operationssupply.inv_indent.is_standing IS '[v4: IND-001..007, IPI-008 (Indent entity)]';
COMMENT ON COLUMN operationssupply.inv_indent.standing_frequency IS '[v4: IND-001..007, IPI-008 (Indent entity)]';
COMMENT ON COLUMN operationssupply.inv_indent.next_standing_due IS '[v4: IND-001..007, IPI-008 (Indent entity)]';
COMMENT ON COLUMN operationssupply.inv_indent.rejection_reason IS '[v4: IND-001..007, IPI-008 (Indent entity)]';
COMMENT ON COLUMN operationssupply.inv_indent.purchase_request_id IS '[v4: IND-001..007, IPI-008 (Indent entity)]';
COMMENT ON COLUMN operationssupply.inv_indent.issued_at IS '[v4: IND-001..007, IPI-008 (Indent entity)]';
COMMENT ON COLUMN operationssupply.inv_indent.received_at IS '[v4: IND-001..007, IPI-008 (Indent entity)]';
COMMENT ON COLUMN operationssupply.inv_indent.closed_at IS '[v4: IND-001..007, IPI-008 (Indent entity)]';
COMMENT ON COLUMN operationssupply.inv_indent.admission_id IS 'ward indent for patient [v4: IND-001..007, IPI-008 (Indent entity)]';

-- operationssupply.inv_indent_item  (5 new columns)  FDS: IND-002..004
ALTER TABLE operationssupply.inv_indent_item ADD COLUMN IF NOT EXISTS rejected_qty DECIMAL(12,2) NULL;
ALTER TABLE operationssupply.inv_indent_item ADD COLUMN IF NOT EXISTS shortage_qty DECIMAL(12,2) NULL;
ALTER TABLE operationssupply.inv_indent_item ADD COLUMN IF NOT EXISTS damaged_qty DECIMAL(12,2) NULL;
ALTER TABLE operationssupply.inv_indent_item ADD COLUMN IF NOT EXISTS batch_mismatch BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE operationssupply.inv_indent_item ADD COLUMN IF NOT EXISTS remarks VARCHAR(300) NULL;
COMMENT ON COLUMN operationssupply.inv_indent_item.rejected_qty IS '[v4: IND-002..004]';
COMMENT ON COLUMN operationssupply.inv_indent_item.shortage_qty IS '[v4: IND-002..004]';
COMMENT ON COLUMN operationssupply.inv_indent_item.damaged_qty IS '[v4: IND-002..004]';
COMMENT ON COLUMN operationssupply.inv_indent_item.batch_mismatch IS '[v4: IND-002..004]';
COMMENT ON COLUMN operationssupply.inv_indent_item.remarks IS '[v4: IND-002..004]';

-- operationssupply.inv_item_batch  (6 new columns)  FDS: STR-002, EXP-006, BAT-002/004, DRG-008 (Batch stock entity)
ALTER TABLE operationssupply.inv_item_batch ADD COLUMN IF NOT EXISTS batch_status VARCHAR(20) NULL DEFAULT 'AVAILABLE';
ALTER TABLE operationssupply.inv_item_batch ADD COLUMN IF NOT EXISTS gs1_serial VARCHAR(50) NULL;
ALTER TABLE operationssupply.inv_item_batch ADD COLUMN IF NOT EXISTS internal_barcode VARCHAR(50) NULL;
ALTER TABLE operationssupply.inv_item_batch ADD COLUMN IF NOT EXISTS grn_item_id BIGINT NULL;
ALTER TABLE operationssupply.inv_item_batch ADD COLUMN IF NOT EXISTS manufacturer VARCHAR(150) NULL;
ALTER TABLE operationssupply.inv_item_batch ADD COLUMN IF NOT EXISTS recall_id BIGINT NULL;
COMMENT ON COLUMN operationssupply.inv_item_batch.batch_status IS 'AVAILABLE, QUARANTINED, EXPIRED, RECALLED, BLOCKED [v4: STR-002, EXP-006, BAT-002/004, DRG-008 (Batch stock entity)]';
COMMENT ON COLUMN operationssupply.inv_item_batch.gs1_serial IS '[v4: STR-002, EXP-006, BAT-002/004, DRG-008 (Batch stock entity)]';
COMMENT ON COLUMN operationssupply.inv_item_batch.internal_barcode IS '[v4: STR-002, EXP-006, BAT-002/004, DRG-008 (Batch stock entity)]';
COMMENT ON COLUMN operationssupply.inv_item_batch.grn_item_id IS '[v4: STR-002, EXP-006, BAT-002/004, DRG-008 (Batch stock entity)]';
COMMENT ON COLUMN operationssupply.inv_item_batch.manufacturer IS '[v4: STR-002, EXP-006, BAT-002/004, DRG-008 (Batch stock entity)]';
COMMENT ON COLUMN operationssupply.inv_item_batch.recall_id IS '[v4: STR-002, EXP-006, BAT-002/004, DRG-008 (Batch stock entity)]';

-- operationssupply.inv_purchase_order  (7 new columns)  FDS: PUR-001..005, ROL-003/004, IND-006 (Purchase order entity)
ALTER TABLE operationssupply.inv_purchase_order ADD COLUMN IF NOT EXISTS indent_id BIGINT NULL;
ALTER TABLE operationssupply.inv_purchase_order ADD COLUMN IF NOT EXISTS due_date DATE NULL;
ALTER TABLE operationssupply.inv_purchase_order ADD COLUMN IF NOT EXISTS sent_to_vendor_at TIMESTAMPTZ(0) NULL;
ALTER TABLE operationssupply.inv_purchase_order ADD COLUMN IF NOT EXISTS vendor_ack_at TIMESTAMPTZ(0) NULL;
ALTER TABLE operationssupply.inv_purchase_order ADD COLUMN IF NOT EXISTS dispatch_notice_at TIMESTAMPTZ(0) NULL;
ALTER TABLE operationssupply.inv_purchase_order ADD COLUMN IF NOT EXISTS cancel_reason VARCHAR(300) NULL;
ALTER TABLE operationssupply.inv_purchase_order ADD COLUMN IF NOT EXISTS rate_contract_id BIGINT NULL;
COMMENT ON COLUMN operationssupply.inv_purchase_order.indent_id IS '[v4: PUR-001..005, ROL-003/004, IND-006 (Purchase order entity)]';
COMMENT ON COLUMN operationssupply.inv_purchase_order.due_date IS '[v4: PUR-001..005, ROL-003/004, IND-006 (Purchase order entity)]';
COMMENT ON COLUMN operationssupply.inv_purchase_order.sent_to_vendor_at IS '[v4: PUR-001..005, ROL-003/004, IND-006 (Purchase order entity)]';
COMMENT ON COLUMN operationssupply.inv_purchase_order.vendor_ack_at IS '[v4: PUR-001..005, ROL-003/004, IND-006 (Purchase order entity)]';
COMMENT ON COLUMN operationssupply.inv_purchase_order.dispatch_notice_at IS '[v4: PUR-001..005, ROL-003/004, IND-006 (Purchase order entity)]';
COMMENT ON COLUMN operationssupply.inv_purchase_order.cancel_reason IS '[v4: PUR-001..005, ROL-003/004, IND-006 (Purchase order entity)]';
COMMENT ON COLUMN operationssupply.inv_purchase_order.rate_contract_id IS '[v4: PUR-001..005, ROL-003/004, IND-006 (Purchase order entity)]';

-- operationssupply.inv_purchase_order_item  (3 new columns)  FDS: PUR-004, PUR-011
ALTER TABLE operationssupply.inv_purchase_order_item ADD COLUMN IF NOT EXISTS pending_qty DECIMAL(12,2) NULL;
ALTER TABLE operationssupply.inv_purchase_order_item ADD COLUMN IF NOT EXISTS last_purchase_rate DECIMAL(12,4) NULL;
ALTER TABLE operationssupply.inv_purchase_order_item ADD COLUMN IF NOT EXISTS rate_variance_pct DECIMAL(6,2) NULL;
COMMENT ON COLUMN operationssupply.inv_purchase_order_item.pending_qty IS '[v4: PUR-004, PUR-011]';
COMMENT ON COLUMN operationssupply.inv_purchase_order_item.last_purchase_rate IS '[v4: PUR-004, PUR-011]';
COMMENT ON COLUMN operationssupply.inv_purchase_order_item.rate_variance_pct IS '[v4: PUR-004, PUR-011]';

-- operationssupply.inv_purchase_return  (5 new columns)  FDS: RET-009, PUR-008/009, GRN-009
ALTER TABLE operationssupply.inv_purchase_return ADD COLUMN IF NOT EXISTS reason_code VARCHAR(30) NULL;
ALTER TABLE operationssupply.inv_purchase_return ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) NULL DEFAULT 'APPROVED';
ALTER TABLE operationssupply.inv_purchase_return ADD COLUMN IF NOT EXISTS debit_note_document_id BIGINT NULL;
ALTER TABLE operationssupply.inv_purchase_return ADD COLUMN IF NOT EXISTS vendor_credit_note_no VARCHAR(50) NULL;
ALTER TABLE operationssupply.inv_purchase_return ADD COLUMN IF NOT EXISTS vendor_credit_received_at TIMESTAMPTZ(0) NULL;
COMMENT ON COLUMN operationssupply.inv_purchase_return.reason_code IS 'EXPIRED, DAMAGED, REJECTED, RECALLED, NEAR_EXPIRY [v4: RET-009, PUR-008/009, GRN-009]';
COMMENT ON COLUMN operationssupply.inv_purchase_return.approval_status IS '[v4: RET-009, PUR-008/009, GRN-009]';
COMMENT ON COLUMN operationssupply.inv_purchase_return.debit_note_document_id IS '[v4: RET-009, PUR-008/009, GRN-009]';
COMMENT ON COLUMN operationssupply.inv_purchase_return.vendor_credit_note_no IS '[v4: RET-009, PUR-008/009, GRN-009]';
COMMENT ON COLUMN operationssupply.inv_purchase_return.vendor_credit_received_at IS '[v4: RET-009, PUR-008/009, GRN-009]';

-- operationssupply.inv_stock  (4 new columns)  FDS: STR-002..004
ALTER TABLE operationssupply.inv_stock ADD COLUMN IF NOT EXISTS qty_in_transit DECIMAL(12,2) NULL DEFAULT 0;
ALTER TABLE operationssupply.inv_stock ADD COLUMN IF NOT EXISTS qty_quarantined DECIMAL(12,2) NULL DEFAULT 0;
ALTER TABLE operationssupply.inv_stock ADD COLUMN IF NOT EXISTS store_location_id INT NULL;
ALTER TABLE operationssupply.inv_stock ADD COLUMN IF NOT EXISTS last_synced_at TIMESTAMPTZ(0) NULL;
COMMENT ON COLUMN operationssupply.inv_stock.qty_in_transit IS '[v4: STR-002..004]';
COMMENT ON COLUMN operationssupply.inv_stock.qty_quarantined IS '[v4: STR-002..004]';
COMMENT ON COLUMN operationssupply.inv_stock.store_location_id IS '[v4: STR-002..004]';
COMMENT ON COLUMN operationssupply.inv_stock.last_synced_at IS '[v4: STR-002..004]';

-- operationssupply.inv_stock_adjustment  (7 new columns)  FDS: STK-009, EXP-011 (damage / write-off with approval)
ALTER TABLE operationssupply.inv_stock_adjustment ADD COLUMN IF NOT EXISTS adjustment_no VARCHAR(30) NULL;
ALTER TABLE operationssupply.inv_stock_adjustment ADD COLUMN IF NOT EXISTS reason_code VARCHAR(30) NULL;
ALTER TABLE operationssupply.inv_stock_adjustment ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) NULL DEFAULT 'APPROVED';
ALTER TABLE operationssupply.inv_stock_adjustment ADD COLUMN IF NOT EXISTS requested_by BIGINT NULL;
ALTER TABLE operationssupply.inv_stock_adjustment ADD COLUMN IF NOT EXISTS value_amount DECIMAL(14,2) NULL;
ALTER TABLE operationssupply.inv_stock_adjustment ADD COLUMN IF NOT EXISTS document_id BIGINT NULL;
ALTER TABLE operationssupply.inv_stock_adjustment ADD COLUMN IF NOT EXISTS voucher_id BIGINT NULL;
COMMENT ON COLUMN operationssupply.inv_stock_adjustment.adjustment_no IS '[v4: STK-009, EXP-011 (damage / write-off with approval)]';
COMMENT ON COLUMN operationssupply.inv_stock_adjustment.reason_code IS '[v4: STK-009, EXP-011 (damage / write-off with approval)]';
COMMENT ON COLUMN operationssupply.inv_stock_adjustment.approval_status IS '[v4: STK-009, EXP-011 (damage / write-off with approval)]';
COMMENT ON COLUMN operationssupply.inv_stock_adjustment.requested_by IS '[v4: STK-009, EXP-011 (damage / write-off with approval)]';
COMMENT ON COLUMN operationssupply.inv_stock_adjustment.value_amount IS '[v4: STK-009, EXP-011 (damage / write-off with approval)]';
COMMENT ON COLUMN operationssupply.inv_stock_adjustment.document_id IS '[v4: STK-009, EXP-011 (damage / write-off with approval)]';
COMMENT ON COLUMN operationssupply.inv_stock_adjustment.voucher_id IS 'revenuefinance.fin_voucher (journal) [v4: STK-009, EXP-011 (damage / write-off with approval)]';

-- operationssupply.inv_stock_ledger  (11 new columns)  FDS: STK-008, CON-001, BAT-004 (Stock movement entity)
ALTER TABLE operationssupply.inv_stock_ledger ADD COLUMN IF NOT EXISTS qty_before DECIMAL(12,2) NULL;
ALTER TABLE operationssupply.inv_stock_ledger ADD COLUMN IF NOT EXISTS from_store_id INT NULL;
ALTER TABLE operationssupply.inv_stock_ledger ADD COLUMN IF NOT EXISTS to_store_id INT NULL;
ALTER TABLE operationssupply.inv_stock_ledger ADD COLUMN IF NOT EXISTS reason_code VARCHAR(30) NULL;
ALTER TABLE operationssupply.inv_stock_ledger ADD COLUMN IF NOT EXISTS department_id INT NULL;
ALTER TABLE operationssupply.inv_stock_ledger ADD COLUMN IF NOT EXISTS cost_center_id INT NULL;
ALTER TABLE operationssupply.inv_stock_ledger ADD COLUMN IF NOT EXISTS patient_id BIGINT NULL;
ALTER TABLE operationssupply.inv_stock_ledger ADD COLUMN IF NOT EXISTS encounter_id BIGINT NULL;
ALTER TABLE operationssupply.inv_stock_ledger ADD COLUMN IF NOT EXISTS practitioner_id BIGINT NULL;
ALTER TABLE operationssupply.inv_stock_ledger ADD COLUMN IF NOT EXISTS source_service VARCHAR(20) NULL;
ALTER TABLE operationssupply.inv_stock_ledger ADD COLUMN IF NOT EXISTS terminal_id VARCHAR(100) NULL;
COMMENT ON COLUMN operationssupply.inv_stock_ledger.qty_before IS '[v4: STK-008, CON-001, BAT-004 (Stock movement entity)]';
COMMENT ON COLUMN operationssupply.inv_stock_ledger.from_store_id IS '[v4: STK-008, CON-001, BAT-004 (Stock movement entity)]';
COMMENT ON COLUMN operationssupply.inv_stock_ledger.to_store_id IS '[v4: STK-008, CON-001, BAT-004 (Stock movement entity)]';
COMMENT ON COLUMN operationssupply.inv_stock_ledger.reason_code IS '[v4: STK-008, CON-001, BAT-004 (Stock movement entity)]';
COMMENT ON COLUMN operationssupply.inv_stock_ledger.department_id IS '[v4: STK-008, CON-001, BAT-004 (Stock movement entity)]';
COMMENT ON COLUMN operationssupply.inv_stock_ledger.cost_center_id IS '[v4: STK-008, CON-001, BAT-004 (Stock movement entity)]';
COMMENT ON COLUMN operationssupply.inv_stock_ledger.patient_id IS '[v4: STK-008, CON-001, BAT-004 (Stock movement entity)]';
COMMENT ON COLUMN operationssupply.inv_stock_ledger.encounter_id IS '[v4: STK-008, CON-001, BAT-004 (Stock movement entity)]';
COMMENT ON COLUMN operationssupply.inv_stock_ledger.practitioner_id IS '[v4: STK-008, CON-001, BAT-004 (Stock movement entity)]';
COMMENT ON COLUMN operationssupply.inv_stock_ledger.source_service IS 'PHARMACY, LIMS, RIMS, CLINICAL_CARE, OPERATIONS [v4: STK-008, CON-001, BAT-004 (Stock movement entity)]';
COMMENT ON COLUMN operationssupply.inv_stock_ledger.terminal_id IS '[v4: STK-008, CON-001, BAT-004 (Stock movement entity)]';

-- operationssupply.inv_store_item_policy  (8 new columns)  FDS: STR-007, ROL-002..004, STK-005, CON-006
ALTER TABLE operationssupply.inv_store_item_policy ADD COLUMN IF NOT EXISTS is_stockable BOOLEAN NULL DEFAULT TRUE;
ALTER TABLE operationssupply.inv_store_item_policy ADD COLUMN IF NOT EXISTS is_issuable BOOLEAN NULL DEFAULT TRUE;
ALTER TABLE operationssupply.inv_store_item_policy ADD COLUMN IF NOT EXISTS is_saleable BOOLEAN NULL DEFAULT TRUE;
ALTER TABLE operationssupply.inv_store_item_policy ADD COLUMN IF NOT EXISTS auto_reorder_suspended BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE operationssupply.inv_store_item_policy ADD COLUMN IF NOT EXISTS max_days_cover SMALLINT NULL;
ALTER TABLE operationssupply.inv_store_item_policy ADD COLUMN IF NOT EXISTS store_location_id INT NULL;
ALTER TABLE operationssupply.inv_store_item_policy ADD COLUMN IF NOT EXISTS suggested_reorder_level DECIMAL(12,2) NULL;
ALTER TABLE operationssupply.inv_store_item_policy ADD COLUMN IF NOT EXISTS suggested_at TIMESTAMPTZ(0) NULL;
COMMENT ON COLUMN operationssupply.inv_store_item_policy.is_stockable IS '[v4: STR-007, ROL-002..004, STK-005, CON-006]';
COMMENT ON COLUMN operationssupply.inv_store_item_policy.is_issuable IS '[v4: STR-007, ROL-002..004, STK-005, CON-006]';
COMMENT ON COLUMN operationssupply.inv_store_item_policy.is_saleable IS '[v4: STR-007, ROL-002..004, STK-005, CON-006]';
COMMENT ON COLUMN operationssupply.inv_store_item_policy.auto_reorder_suspended IS '[v4: STR-007, ROL-002..004, STK-005, CON-006]';
COMMENT ON COLUMN operationssupply.inv_store_item_policy.max_days_cover IS '[v4: STR-007, ROL-002..004, STK-005, CON-006]';
COMMENT ON COLUMN operationssupply.inv_store_item_policy.store_location_id IS '[v4: STR-007, ROL-002..004, STK-005, CON-006]';
COMMENT ON COLUMN operationssupply.inv_store_item_policy.suggested_reorder_level IS '[v4: STR-007, ROL-002..004, STK-005, CON-006]';
COMMENT ON COLUMN operationssupply.inv_store_item_policy.suggested_at IS '[v4: STR-007, ROL-002..004, STK-005, CON-006]';

-- operationssupply.mst_item  (7 new columns)  FDS: DRG-001, HSN-002, BAT-001/003
ALTER TABLE operationssupply.mst_item ADD COLUMN IF NOT EXISTS gs1_gtin VARCHAR(20) NULL;
ALTER TABLE operationssupply.mst_item ADD COLUMN IF NOT EXISTS hsn_sac_id INT NULL;
ALTER TABLE operationssupply.mst_item ADD COLUMN IF NOT EXISTS pack_size VARCHAR(50) NULL;
ALTER TABLE operationssupply.mst_item ADD COLUMN IF NOT EXISTS abc_class CHAR(1) NULL;
ALTER TABLE operationssupply.mst_item ADD COLUMN IF NOT EXISTS ved_class CHAR(1) NULL;
ALTER TABLE operationssupply.mst_item ADD COLUMN IF NOT EXISTS is_returnable BOOLEAN NULL DEFAULT TRUE;
ALTER TABLE operationssupply.mst_item ADD COLUMN IF NOT EXISTS min_shelf_life_days SMALLINT NULL;
COMMENT ON COLUMN operationssupply.mst_item.gs1_gtin IS '[v4: DRG-001, HSN-002, BAT-001/003]';
COMMENT ON COLUMN operationssupply.mst_item.hsn_sac_id IS 'revenuefinance.mst_hsn_sac [v4: DRG-001, HSN-002, BAT-001/003]';
COMMENT ON COLUMN operationssupply.mst_item.pack_size IS '[v4: DRG-001, HSN-002, BAT-001/003]';
COMMENT ON COLUMN operationssupply.mst_item.abc_class IS '[v4: DRG-001, HSN-002, BAT-001/003]';
COMMENT ON COLUMN operationssupply.mst_item.ved_class IS '[v4: DRG-001, HSN-002, BAT-001/003]';
COMMENT ON COLUMN operationssupply.mst_item.is_returnable IS '[v4: DRG-001, HSN-002, BAT-001/003]';
COMMENT ON COLUMN operationssupply.mst_item.min_shelf_life_days IS 'GRN-003 short-expiry block [v4: DRG-001, HSN-002, BAT-001/003]';

-- operationssupply.mst_store  (12 new columns)  FDS: STR-001, STR-006..008, STK-011, SCH-008 (Store entity)
ALTER TABLE operationssupply.mst_store ADD COLUMN IF NOT EXISTS store_category VARCHAR(20) NULL;
ALTER TABLE operationssupply.mst_store ADD COLUMN IF NOT EXISTS drug_licence_valid_to DATE NULL;
ALTER TABLE operationssupply.mst_store ADD COLUMN IF NOT EXISTS in_charge_employee_id BIGINT NULL;
ALTER TABLE operationssupply.mst_store ADD COLUMN IF NOT EXISTS store_status VARCHAR(20) NULL DEFAULT 'ACTIVE';
ALTER TABLE operationssupply.mst_store ADD COLUMN IF NOT EXISTS allow_negative_stock BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE operationssupply.mst_store ADD COLUMN IF NOT EXISTS is_controlled_drug_store BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE operationssupply.mst_store ADD COLUMN IF NOT EXISTS has_cold_chain BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE operationssupply.mst_store ADD COLUMN IF NOT EXISTS sync_mode VARCHAR(20) NULL DEFAULT 'REALTIME';
ALTER TABLE operationssupply.mst_store ADD COLUMN IF NOT EXISTS sync_interval_minutes SMALLINT NULL;
ALTER TABLE operationssupply.mst_store ADD COLUMN IF NOT EXISTS is_frozen_for_count BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE operationssupply.mst_store ADD COLUMN IF NOT EXISTS gstin VARCHAR(15) NULL;
ALTER TABLE operationssupply.mst_store ADD COLUMN IF NOT EXISTS state_code VARCHAR(5) NULL;
COMMENT ON COLUMN operationssupply.mst_store.store_category IS 'CENTRAL, SUB_BRANCH, DEPARTMENTAL, WARD_FLOOR, PHARMACY_OUTLET [v4: STR-001, STR-006..008, STK-011, SCH-008 (Store entity)]';
COMMENT ON COLUMN operationssupply.mst_store.drug_licence_valid_to IS '[v4: STR-001, STR-006..008, STK-011, SCH-008 (Store entity)]';
COMMENT ON COLUMN operationssupply.mst_store.in_charge_employee_id IS '[v4: STR-001, STR-006..008, STK-011, SCH-008 (Store entity)]';
COMMENT ON COLUMN operationssupply.mst_store.store_status IS '[v4: STR-001, STR-006..008, STK-011, SCH-008 (Store entity)]';
COMMENT ON COLUMN operationssupply.mst_store.allow_negative_stock IS '[v4: STR-001, STR-006..008, STK-011, SCH-008 (Store entity)]';
COMMENT ON COLUMN operationssupply.mst_store.is_controlled_drug_store IS '[v4: STR-001, STR-006..008, STK-011, SCH-008 (Store entity)]';
COMMENT ON COLUMN operationssupply.mst_store.has_cold_chain IS '[v4: STR-001, STR-006..008, STK-011, SCH-008 (Store entity)]';
COMMENT ON COLUMN operationssupply.mst_store.sync_mode IS 'REALTIME, INTERVAL [v4: STR-001, STR-006..008, STK-011, SCH-008 (Store entity)]';
COMMENT ON COLUMN operationssupply.mst_store.sync_interval_minutes IS '[v4: STR-001, STR-006..008, STK-011, SCH-008 (Store entity)]';
COMMENT ON COLUMN operationssupply.mst_store.is_frozen_for_count IS '[v4: STR-001, STR-006..008, STK-011, SCH-008 (Store entity)]';
COMMENT ON COLUMN operationssupply.mst_store.gstin IS '[v4: STR-001, STR-006..008, STK-011, SCH-008 (Store entity)]';
COMMENT ON COLUMN operationssupply.mst_store.state_code IS '[v4: STR-001, STR-006..008, STK-011, SCH-008 (Store entity)]';

-- operationssupply.mst_vendor  (9 new columns)  FDS: VEN-001..007 (Vendor entity)
ALTER TABLE operationssupply.mst_vendor ADD COLUMN IF NOT EXISTS drug_licence_valid_to DATE NULL;
ALTER TABLE operationssupply.mst_vendor ADD COLUMN IF NOT EXISTS vendor_status VARCHAR(20) NULL DEFAULT 'ACTIVE';
ALTER TABLE operationssupply.mst_vendor ADD COLUMN IF NOT EXISTS status_reason VARCHAR(300) NULL;
ALTER TABLE operationssupply.mst_vendor ADD COLUMN IF NOT EXISTS status_approved_by BIGINT NULL;
ALTER TABLE operationssupply.mst_vendor ADD COLUMN IF NOT EXISTS bank_name VARCHAR(100) NULL;
ALTER TABLE operationssupply.mst_vendor ADD COLUMN IF NOT EXISTS addresses_json JSONB NULL;
ALTER TABLE operationssupply.mst_vendor ADD COLUMN IF NOT EXISTS contacts_json JSONB NULL;
ALTER TABLE operationssupply.mst_vendor ADD COLUMN IF NOT EXISTS portal_enabled BOOLEAN NULL DEFAULT FALSE;
ALTER TABLE operationssupply.mst_vendor ADD COLUMN IF NOT EXISTS is_outsource_lab BOOLEAN NULL DEFAULT FALSE;
COMMENT ON COLUMN operationssupply.mst_vendor.drug_licence_valid_to IS '[v4: VEN-001..007 (Vendor entity)]';
COMMENT ON COLUMN operationssupply.mst_vendor.vendor_status IS 'ACTIVE, ON_HOLD, BLACKLISTED [v4: VEN-001..007 (Vendor entity)]';
COMMENT ON COLUMN operationssupply.mst_vendor.status_reason IS '[v4: VEN-001..007 (Vendor entity)]';
COMMENT ON COLUMN operationssupply.mst_vendor.status_approved_by IS '[v4: VEN-001..007 (Vendor entity)]';
COMMENT ON COLUMN operationssupply.mst_vendor.bank_name IS '[v4: VEN-001..007 (Vendor entity)]';
COMMENT ON COLUMN operationssupply.mst_vendor.addresses_json IS '[v4: VEN-001..007 (Vendor entity)]';
COMMENT ON COLUMN operationssupply.mst_vendor.contacts_json IS '[v4: VEN-001..007 (Vendor entity)]';
COMMENT ON COLUMN operationssupply.mst_vendor.portal_enabled IS '[v4: VEN-001..007 (Vendor entity)]';
COMMENT ON COLUMN operationssupply.mst_vendor.is_outsource_lab IS '[v4: VEN-001..007 (Vendor entity)]';

/* ---------- B. NEW TABLES ---------- */

-- ===== Pharmacy FRD - Sections 3.4 to 3.11 (stores, stock, purchase, GRN, expiry, batch) - inventory engine =====
-- [NEW v4] FDS ref: STR-006, SUB-005
CREATE TABLE IF NOT EXISTS operationssupply.inv_store_location (              -- Storage locations within a store (rack, shelf, bin; cold-chain and controlled areas)
    store_location_id          INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    store_id                   INT NOT NULL,
    location_code              VARCHAR(30) NOT NULL,
    rack                       VARCHAR(20) NULL,
    shelf                      VARCHAR(20) NULL,
    bin                        VARCHAR(20) NULL,
    area_type                  VARCHAR(20) NOT NULL DEFAULT 'GENERAL',         -- GENERAL, COLD_CHAIN, CONTROLLED, QUARANTINE, LASA_SEGREGATED
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT                 uq_inv_store_location_1 UNIQUE (store_id, location_code)
);

-- [NEW v4] FDS ref: STR-003, STR-008
CREATE TABLE IF NOT EXISTS operationssupply.inv_stock_sync_log (              -- Central / sub-store inventory sync status with failures and reconciliation
    stock_sync_log_id          BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    store_id                   INT NOT NULL,
    sync_type                  VARCHAR(20) NOT NULL,                           -- REALTIME, SCHEDULED, RECONCILIATION
    started_at                 TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    finished_at                TIMESTAMPTZ(0) NULL,
    records_synced             INT NULL,
    mismatch_count             INT NULL,
    sync_status                VARCHAR(20) NOT NULL,                           -- SUCCESS, FAILED, DELAYED, PARTIAL
    error_message              VARCHAR(1000) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: STK-003, STK-007, EXP-002
CREATE TABLE IF NOT EXISTS operationssupply.inv_stock_snapshot (              -- Opening / closing stock snapshots by store, item and batch per period
    stock_snapshot_id          BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    store_id                   INT NOT NULL,
    snapshot_type              VARCHAR(10) NOT NULL,                           -- OPENING, CLOSING
    period_date                DATE NOT NULL,
    item_id                    INT NOT NULL,
    item_batch_id              BIGINT NOT NULL,
    quantity                   DECIMAL(12,2) NOT NULL,
    unit_cost                  DECIMAL(12,4) NULL,
    mrp                        DECIMAL(12,2) NULL,
    approved_by                BIGINT NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: STK-010, STK-011, SCH-007
CREATE TABLE IF NOT EXISTS operationssupply.inv_physical_count (              -- Physical stock verification (cycle / full count) with freeze and variance approval
    physical_count_id          BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    count_no                   VARCHAR(30) NOT NULL UNIQUE,
    store_id                   INT NOT NULL,
    count_type                 VARCHAR(10) NOT NULL,                           -- CYCLE, FULL
    freeze_movements           BOOLEAN NOT NULL DEFAULT FALSE,
    started_at                 TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at               TIMESTAMPTZ(0) NULL,
    variance_value             DECIMAL(14,2) NULL,
    approved_by                BIGINT NULL,
    count_status               VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS',     -- IN_PROGRESS, SUBMITTED, APPROVED, ADJUSTED
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: STK-010
CREATE TABLE IF NOT EXISTS operationssupply.inv_physical_count_item (         -- Counted quantities vs system with variance
    physical_count_item_id     BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    physical_count_id          BIGINT NOT NULL,
    item_batch_id              BIGINT NOT NULL,
    system_qty                 DECIMAL(12,2) NOT NULL,
    counted_qty                DECIMAL(12,2) NULL,
    variance_qty               DECIMAL(12,2) NULL,
    variance_reason            VARCHAR(300) NULL,
    stock_adjustment_id        BIGINT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: PUR-011, VEN-003
CREATE TABLE IF NOT EXISTS operationssupply.inv_rate_contract (               -- Vendor rate contracts with validity
    rate_contract_id           BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    contract_no                VARCHAR(30) NOT NULL UNIQUE,
    vendor_id                  INT NOT NULL,
    valid_from                 DATE NOT NULL,
    valid_to                   DATE NOT NULL,
    document_id                BIGINT NULL,                                    -- logical FK -> integrationcomms.core_document [Integration & Communications]
    contract_status            VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: PUR-011
CREATE TABLE IF NOT EXISTS operationssupply.inv_rate_contract_item (          -- Rate contract item rates
    rate_contract_item_id      BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    rate_contract_id           BIGINT NOT NULL,
    item_id                    INT NOT NULL,
    contract_rate              DECIMAL(12,4) NOT NULL,
    discount_pct               DECIMAL(5,2) NULL,
    max_qty                    DECIMAL(12,2) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: VEN-003, PUR-011
CREATE TABLE IF NOT EXISTS operationssupply.inv_vendor_item (                 -- Vendor-item mapping with preferred vendor and last purchase rate
    vendor_item_id             BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    vendor_id                  INT NOT NULL,
    item_id                    INT NOT NULL,
    vendor_item_code           VARCHAR(50) NULL,
    is_preferred               BOOLEAN NOT NULL DEFAULT FALSE,
    last_purchase_rate         DECIMAL(12,4) NULL,
    last_purchase_date         DATE NULL,
    lead_time_days             SMALLINT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT                 uq_inv_vendor_item_1 UNIQUE (vendor_id, item_id)
);

-- [NEW v4] FDS ref: GRN-001
CREATE TABLE IF NOT EXISTS operationssupply.inv_grn_po (                      -- GRN against multiple POs
    grn_po_id                  BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    grn_id                     BIGINT NOT NULL,
    purchase_order_id          BIGINT NOT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT                 uq_inv_grn_po_1 UNIQUE (grn_id, purchase_order_id)
);

-- [NEW v4] FDS ref: VEN-002
CREATE TABLE IF NOT EXISTS operationssupply.mst_vendor_document (             -- Vendor licences / agreements / certificates with expiry alerts (block PO on expiry)
    vendor_document_id         BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    vendor_id                  INT NOT NULL,
    document_type              VARCHAR(30) NOT NULL,                           -- DRUG_LICENCE, GST, AGREEMENT, ISO, FSSAI
    document_no                VARCHAR(100) NULL,
    valid_from                 DATE NULL,
    valid_to                   DATE NULL,
    document_id                BIGINT NULL,                                    -- logical FK -> integrationcomms.core_document [Integration & Communications]
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: VEN-004
CREATE TABLE IF NOT EXISTS operationssupply.inv_vendor_rating (               -- Periodic vendor rating (timeliness, fill rate, price compliance, rejections, expiry returns)
    vendor_rating_id           BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    vendor_id                  INT NOT NULL,
    period_from                DATE NOT NULL,
    period_to                  DATE NOT NULL,
    on_time_pct                DECIMAL(5,2) NULL,
    fill_rate_pct              DECIMAL(5,2) NULL,
    price_compliance_pct       DECIMAL(5,2) NULL,
    rejection_pct              DECIMAL(5,2) NULL,
    expiry_return_pct          DECIMAL(5,2) NULL,
    short_expiry_pct           DECIMAL(5,2) NULL,
    overall_score              DECIMAL(5,2) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: CON-004
CREATE TABLE IF NOT EXISTS operationssupply.inv_department_budget (           -- Department consumption budgets with alerts
    department_budget_id       BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    department_id              INT NOT NULL,                                   -- logical FK -> identityorg.mst_department [Identity & Organization]
    store_id                   INT NULL,
    item_category_id           INT NULL,
    period_from                DATE NOT NULL,
    period_to                  DATE NOT NULL,
    budget_amount              DECIMAL(14,2) NOT NULL,
    consumed_amount            DECIMAL(14,2) NOT NULL DEFAULT 0,
    alert_threshold_pct        DECIMAL(5,2) NOT NULL DEFAULT 90,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);


-- ===== FDS Website & E-commerce Portal - Field agent apps, i-WP dispatch (Field task entity) =====
-- [NEW v4] FDS ref: FAA-001..011, OPS-002, PHA-006, RRA-004, MFF-009
CREATE TABLE IF NOT EXISTS operationssupply.fld_agent (                       -- Field agents (phlebo, rider, pharm agent, OPD rider, home-visit doctor) incl. partner agents
    agent_id                   BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    agent_code                 VARCHAR(30) NOT NULL UNIQUE,
    employee_id                BIGINT NULL,                                    -- logical FK -> identityorg.hr_employee [Identity & Organization]
    provider_id                BIGINT NULL,                                    -- partner agent | logical FK -> patientengagement.mkt_provider [Patient Access & Engagement]
    full_name                  VARCHAR(150) NOT NULL,
    mobile                     VARCHAR(15) NOT NULL,
    photo_uri                  VARCHAR(500) NULL,
    skills                     VARCHAR(100) NOT NULL,                          -- PHLEBO, RIDER, PHARM, OPD_RIDER, DOCTOR
    authorised_provider_ids    VARCHAR(500) NULL,                              -- e-Phlebo / e-Rayd partner authorisation
    service_zone_ids           VARCHAR(500) NULL,                              -- patientengagement.mkt_service_zone
    vehicle_id                 INT NULL,
    has_cold_box               BOOLEAN NOT NULL DEFAULT FALSE,
    user_device_id             INT NULL,                                       -- logical FK -> identityorg.sec_user_device [Identity & Organization]
    duty_status                VARCHAR(20) NOT NULL DEFAULT 'OFF_DUTY',        -- ON_DUTY, OFF_DUTY, ON_TASK, ON_BREAK
    last_latitude              DECIMAL(9,6) NULL,
    last_longitude             DECIMAL(9,6) NULL,
    last_location_at           TIMESTAMPTZ(0) NULL,
    cash_in_hand               DECIMAL(12,2) NOT NULL DEFAULT 0,
    agent_status               VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: FAA-001, OPS-007
CREATE TABLE IF NOT EXISTS operationssupply.fld_agent_duty_log (              -- Agent on-duty / off-duty log
    agent_duty_log_id          BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    agent_id                   BIGINT NOT NULL,
    duty_status                VARCHAR(20) NOT NULL,
    status_at                  TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    latitude                   DECIMAL(9,6) NULL,
    longitude                  DECIMAL(9,6) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: OPS-001..006, FAA-002..007, PHA-001, RRA-001/002, MFF-007, OPU-001 (Field task entity)
CREATE TABLE IF NOT EXISTS operationssupply.fld_task (                        -- Field task: collection, pick-up, return, delivery, OPD pick-up / drop, home visit
    task_id                    BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NOT NULL,                                   -- logical FK -> identityorg.core_branch [Identity & Organization]
    task_no                    VARCHAR(30) NOT NULL UNIQUE,
    task_type                  VARCHAR(20) NOT NULL,                           -- SAMPLE_COLLECTION, PATIENT_PICKUP, PATIENT_RETURN, MED_DELIVERY, OPD_PICKUP, OPD_DROP, HOME_VISIT, RECOLLECTION
    service_line               VARCHAR(20) NOT NULL,
    agent_id                   BIGINT NULL,
    vehicle_id                 INT NULL,
    trip_id                    BIGINT NULL,
    route_sequence             SMALLINT NULL,
    slot_start                 TIMESTAMPTZ(0) NULL,
    slot_end                   TIMESTAMPTZ(0) NULL,
    pickup_address             VARCHAR(500) NULL,
    pickup_lat                 DECIMAL(9,6) NULL,
    pickup_lng                 DECIMAL(9,6) NULL,
    drop_address               VARCHAR(500) NULL,
    drop_lat                   DECIMAL(9,6) NULL,
    drop_lng                   DECIMAL(9,6) NULL,
    access_instructions        VARCHAR(500) NULL,
    patient_first_name         VARCHAR(100) NULL,
    contact_mobile_masked      VARCHAR(20) NULL,
    mobility_needs             VARCHAR(100) NULL,
    attender_count             SMALLINT NULL,
    requires_cold_box          BOOLEAN NOT NULL DEFAULT FALSE,
    is_standby                 BOOLEAN NOT NULL DEFAULT FALSE,                 -- return task on standby until scan complete
    assignment_method          VARCHAR(20) NULL,                               -- AUTO, MANUAL
    assigned_at                TIMESTAMPTZ(0) NULL,
    accepted_at                TIMESTAMPTZ(0) NULL,
    decline_reason             VARCHAR(300) NULL,
    reassign_reason            VARCHAR(300) NULL,
    sla_due_at                 TIMESTAMPTZ(0) NULL,
    cod_amount_due             DECIMAL(12,2) NULL,
    task_status                VARCHAR(20) NOT NULL DEFAULT 'UNASSIGNED',      -- UNASSIGNED, ASSIGNED, ACCEPTED, STARTED, REACHED, IN_PROGRESS, HANDED_OVER, COMPLETED, EXCEPTION, CANCELLED
    completed_at               TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: PBK-006, PHA-001
CREATE TABLE IF NOT EXISTS operationssupply.fld_task_order (                  -- Orders served by a task (one phlebo visit for several family members / orders)
    task_order_id              BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    task_id                    BIGINT NOT NULL,
    online_order_id            BIGINT NOT NULL,                                -- logical FK -> patientengagement.ecom_online_order [Patient Access & Engagement]
    patient_profile_id         BIGINT NULL,                                    -- logical FK -> patientengagement.ecom_patient_profile [Patient Access & Engagement]
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT                 uq_fld_task_order_1 UNIQUE (task_id, online_order_id)
);

-- [NEW v4] FDS ref: FAA-005, FAA-008, ORD-002
CREATE TABLE IF NOT EXISTS operationssupply.fld_task_milestone (              -- Task milestones with timestamp and device location (offline-capable)
    task_milestone_id          BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    task_id                    BIGINT NOT NULL,
    milestone                  VARCHAR(30) NOT NULL,                           -- STARTED, REACHED, PATIENT_VERIFIED, SAMPLE_COLLECTED, PICKED_UP, CENTRE_DROP, HANDED_OVER, DELIVERED, DROPPED
    milestone_at               TIMESTAMPTZ(0) NOT NULL,
    latitude                   DECIMAL(9,6) NULL,
    longitude                  DECIMAL(9,6) NULL,
    captured_offline           BOOLEAN NOT NULL DEFAULT FALSE,
    synced_at                  TIMESTAMPTZ(0) NULL,
    proof_document_id          BIGINT NULL,                                    -- logical FK -> integrationcomms.core_document [Integration & Communications]
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: FAA-006, PCS-001, PLB-005, RPU-001/002, RDP-002/004, MFF-008, MDL-002 (Handover code entity)
CREATE TABLE IF NOT EXISTS operationssupply.fld_handover_code (               -- Hand-off verification codes (customer, centre, pharmacy, lab receipt, drop) - hashed
    handover_code_id           BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    task_id                    BIGINT NOT NULL,
    handoff_type               VARCHAR(20) NOT NULL,                           -- CUSTOMER_PICKUP, CENTRE_DROP, CENTRE_RETURN, PHARMACY_PICKUP, LAB_RECEIPT, PATIENT_DROP, DELIVERY
    code_hash                  VARCHAR(128) NOT NULL,
    generated_at               TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at                 TIMESTAMPTZ(0) NULL,
    verified_at                TIMESTAMPTZ(0) NULL,
    failed_attempts            SMALLINT NOT NULL DEFAULT 0,
    override_by                BIGINT NULL,
    override_reason            VARCHAR(300) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: FAA-007, OPS-006, PHA-005, MDL-004/005
CREATE TABLE IF NOT EXISTS operationssupply.fld_task_exception (              -- Exceptions reported by agents / ops (customer not available, wrong address, refused, partial, rejected)
    task_exception_id          BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    task_id                    BIGINT NOT NULL,
    exception_code             VARCHAR(30) NOT NULL,
    note                       VARCHAR(1000) NULL,
    photo_document_id          BIGINT NULL,                                    -- logical FK -> integrationcomms.core_document [Integration & Communications]
    call_attempts              SMALLINT NULL,
    reported_by                BIGINT NULL,
    reported_at                TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolution                 VARCHAR(30) NULL,                               -- RESCHEDULED, REASSIGNED, CANCELLED, RETURNED, RESOLVED
    resolved_by                BIGINT NULL,
    resolved_at                TIMESTAMPTZ(0) NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: FAA-009, CHK-006
CREATE TABLE IF NOT EXISTS operationssupply.fld_cash_collection (             -- Cash / UPI collected at doorstep and agent cash-in-hand deposits
    cash_collection_id         BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    agent_id                   BIGINT NOT NULL,
    task_id                    BIGINT NULL,
    online_order_id            BIGINT NULL,                                    -- logical FK -> patientengagement.ecom_online_order [Patient Access & Engagement]
    collection_type            VARCHAR(20) NOT NULL,                           -- COLLECTION, DEPOSIT
    payment_mode               VARCHAR(10) NOT NULL,                           -- CASH, UPI
    amount                     DECIMAL(12,2) NOT NULL,
    reference_no               VARCHAR(50) NULL,
    collected_at               TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    receipt_id                 BIGINT NULL,                                    -- logical FK -> revenuefinance.bil_receipt [Revenue & Finance]
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] FDS ref: FAA-010
CREATE TABLE IF NOT EXISTS operationssupply.fld_sos_alert (                   -- Agent SOS alerts with location and current task
    sos_alert_id               BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    branch_id                  INT NULL,                                       -- logical FK -> identityorg.core_branch [Identity & Organization]
    agent_id                   BIGINT NOT NULL,
    task_id                    BIGINT NULL,
    latitude                   DECIMAL(9,6) NULL,
    longitude                  DECIMAL(9,6) NULL,
    raised_at                  TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    acknowledged_by            BIGINT NULL,
    acknowledged_at            TIMESTAMPTZ(0) NULL,
    resolution_notes           VARCHAR(1000) NULL,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

-- [NEW v4] replica of revenuefinance.mst_hsn_sac, owned by Revenue & Finance; used by: operationssupply.mst_item, operationssupply.inv_grn_item
CREATE TABLE IF NOT EXISTS operationssupply.ref_hsn_sac (
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

-- [NEW v4] replica of patientengagement.ecom_online_order, owned by Patient Access & Engagement; used by: operationssupply.fld_task_order
CREATE TABLE IF NOT EXISTS operationssupply.ref_online_order (
    online_order_id            BIGINT PRIMARY KEY,
    organization_id            INT NULL,
    branch_id                  INT NULL,
    order_no                   VARCHAR(25) NULL,
    user_id                    BIGINT NULL,
    patient_id                 BIGINT NULL,
    order_type                 VARCHAR(20) NULL,
    fulfilment_mode            VARCHAR(20) NULL,
    delivery_address           VARCHAR(500) NULL,
    slot_id                    BIGINT NULL,
    coupon_id                  BIGINT NULL,
    gross_amount               DECIMAL(14,2) NULL,
    discount_amount            DECIMAL(14,2) NULL,
    net_amount                 DECIMAL(14,2) NULL,
    payment_gateway_txn_id     BIGINT NULL,
    clinical_order_id          BIGINT NULL,
    service_request_id         BIGINT NULL,
    bill_id                    BIGINT NULL,
    order_status               VARCHAR(20) NULL,
    is_active                  BOOLEAN NULL,
    customer_account_id        BIGINT NULL,
    patient_profile_id         BIGINT NULL,
    provider_id                BIGINT NULL,
    service_line               VARCHAR(20) NULL,                               -- LAB, RAD, PHARMACY, OPD, TELE
    source_channel             VARCHAR(20) NULL,                               -- WEBSITE, ANDROID, IOS, AGGREGATOR, CALL_CENTRE
    channel_partner_id         INT NULL,
    channel_order_ref          VARCHAR(100) NULL,
    address_id                 BIGINT NULL,
    pin_latitude               DECIMAL(9,6) NULL,
    pin_longitude              DECIMAL(9,6) NULL,
    pin_locked_at              TIMESTAMPTZ(0) NULL,
    capacity_window_id         BIGINT NULL,
    item_amount                DECIMAL(12,2) NULL,
    charges_amount             DECIMAL(12,2) NULL,                             -- home collection / rider / delivery charges
    tax_amount                 DECIMAL(12,2) NULL,
    payment_mode               VARCHAR(20) NULL,                               -- PREPAID, PAY_AT_VISIT, COD
    payment_status             VARCHAR(20) NULL,                               -- PENDING, PAID, PARTIALLY_REFUNDED, REFUNDED, FAILED
    cod_collected_amount       DECIMAL(12,2) NULL,
    partner_price_amount       DECIMAL(12,2) NULL,
    platform_fee_amount        DECIMAL(12,2) NULL,
    corporate_ref              VARCHAR(100) NULL,
    insurance_ref              VARCHAR(100) NULL,
    order_episode_id           BIGINT NULL,
    parent_order_id            BIGINT NULL,
    appointment_id             BIGINT NULL,
    encounter_id               BIGINT NULL,
    lims_order_ref             BIGINT NULL,                                    -- clinicalcare.ord_clinical_order id (lab)
    rims_study_ref             BIGINT NULL,                                    -- rims.rad_study id
    pharmacy_dispense_ref      BIGINT NULL,                                    -- pharmacy.pha_dispense id
    visit_mode                 VARCHAR(20) NULL,                               -- SELF_VISIT, PICKUP_DROP, HOME_VISIT, TELE
    mobility_needs             VARCHAR(100) NULL,
    attender_count             SMALLINT NULL,
    substitution_preference    VARCHAR(20) NULL,                               -- ALLOW, DO_NOT_ALLOW
    expected_report_at         TIMESTAMPTZ(0) NULL,
    reschedule_count           SMALLINT NULL,
    cancel_reason              VARCHAR(300) NULL,
    cancelled_at               TIMESTAMPTZ(0) NULL,
    completed_at               TIMESTAMPTZ(0) NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    source_version             BIGINT NULL,                                    -- version / sequence from publisher (ignore stale events)
    replicated_at              TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);


/* ---------- C. FOREIGN KEYS (same service only) ---------- */
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_store_location_store_id') THEN
        ALTER TABLE operationssupply.inv_store_location ADD CONSTRAINT fk_inv_store_location_store_id FOREIGN KEY (store_id) REFERENCES operationssupply.mst_store(store_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_stock_sync_log_store_id') THEN
        ALTER TABLE operationssupply.inv_stock_sync_log ADD CONSTRAINT fk_inv_stock_sync_log_store_id FOREIGN KEY (store_id) REFERENCES operationssupply.mst_store(store_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_stock_snapshot_store_id') THEN
        ALTER TABLE operationssupply.inv_stock_snapshot ADD CONSTRAINT fk_inv_stock_snapshot_store_id FOREIGN KEY (store_id) REFERENCES operationssupply.mst_store(store_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_stock_snapshot_item_id') THEN
        ALTER TABLE operationssupply.inv_stock_snapshot ADD CONSTRAINT fk_inv_stock_snapshot_item_id FOREIGN KEY (item_id) REFERENCES operationssupply.mst_item(item_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_stock_snapshot_item_batch_id') THEN
        ALTER TABLE operationssupply.inv_stock_snapshot ADD CONSTRAINT fk_inv_stock_snapshot_item_batch_id FOREIGN KEY (item_batch_id) REFERENCES operationssupply.inv_item_batch(item_batch_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_physical_count_store_id') THEN
        ALTER TABLE operationssupply.inv_physical_count ADD CONSTRAINT fk_inv_physical_count_store_id FOREIGN KEY (store_id) REFERENCES operationssupply.mst_store(store_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_physical_count_item_physical_count_id') THEN
        ALTER TABLE operationssupply.inv_physical_count_item ADD CONSTRAINT fk_inv_physical_count_item_physical_count_id FOREIGN KEY (physical_count_id) REFERENCES operationssupply.inv_physical_count(physical_count_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_physical_count_item_item_batch_id') THEN
        ALTER TABLE operationssupply.inv_physical_count_item ADD CONSTRAINT fk_inv_physical_count_item_item_batch_id FOREIGN KEY (item_batch_id) REFERENCES operationssupply.inv_item_batch(item_batch_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_physical_count_item_stock_adjustment_id') THEN
        ALTER TABLE operationssupply.inv_physical_count_item ADD CONSTRAINT fk_inv_physical_count_item_stock_adjustment_id FOREIGN KEY (stock_adjustment_id) REFERENCES operationssupply.inv_stock_adjustment(stock_adjustment_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_rate_contract_vendor_id') THEN
        ALTER TABLE operationssupply.inv_rate_contract ADD CONSTRAINT fk_inv_rate_contract_vendor_id FOREIGN KEY (vendor_id) REFERENCES operationssupply.mst_vendor(vendor_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_rate_contract_item_rate_contract_id') THEN
        ALTER TABLE operationssupply.inv_rate_contract_item ADD CONSTRAINT fk_inv_rate_contract_item_rate_contract_id FOREIGN KEY (rate_contract_id) REFERENCES operationssupply.inv_rate_contract(rate_contract_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_rate_contract_item_item_id') THEN
        ALTER TABLE operationssupply.inv_rate_contract_item ADD CONSTRAINT fk_inv_rate_contract_item_item_id FOREIGN KEY (item_id) REFERENCES operationssupply.mst_item(item_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_vendor_item_vendor_id') THEN
        ALTER TABLE operationssupply.inv_vendor_item ADD CONSTRAINT fk_inv_vendor_item_vendor_id FOREIGN KEY (vendor_id) REFERENCES operationssupply.mst_vendor(vendor_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_vendor_item_item_id') THEN
        ALTER TABLE operationssupply.inv_vendor_item ADD CONSTRAINT fk_inv_vendor_item_item_id FOREIGN KEY (item_id) REFERENCES operationssupply.mst_item(item_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_grn_po_grn_id') THEN
        ALTER TABLE operationssupply.inv_grn_po ADD CONSTRAINT fk_inv_grn_po_grn_id FOREIGN KEY (grn_id) REFERENCES operationssupply.inv_grn(grn_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_grn_po_purchase_order_id') THEN
        ALTER TABLE operationssupply.inv_grn_po ADD CONSTRAINT fk_inv_grn_po_purchase_order_id FOREIGN KEY (purchase_order_id) REFERENCES operationssupply.inv_purchase_order(purchase_order_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_mst_vendor_document_vendor_id') THEN
        ALTER TABLE operationssupply.mst_vendor_document ADD CONSTRAINT fk_mst_vendor_document_vendor_id FOREIGN KEY (vendor_id) REFERENCES operationssupply.mst_vendor(vendor_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_vendor_rating_vendor_id') THEN
        ALTER TABLE operationssupply.inv_vendor_rating ADD CONSTRAINT fk_inv_vendor_rating_vendor_id FOREIGN KEY (vendor_id) REFERENCES operationssupply.mst_vendor(vendor_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_department_budget_store_id') THEN
        ALTER TABLE operationssupply.inv_department_budget ADD CONSTRAINT fk_inv_department_budget_store_id FOREIGN KEY (store_id) REFERENCES operationssupply.mst_store(store_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_department_budget_item_category_id') THEN
        ALTER TABLE operationssupply.inv_department_budget ADD CONSTRAINT fk_inv_department_budget_item_category_id FOREIGN KEY (item_category_id) REFERENCES operationssupply.mst_item_category(item_category_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_fld_agent_vehicle_id') THEN
        ALTER TABLE operationssupply.fld_agent ADD CONSTRAINT fk_fld_agent_vehicle_id FOREIGN KEY (vehicle_id) REFERENCES operationssupply.fld_vehicle(vehicle_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_fld_agent_duty_log_agent_id') THEN
        ALTER TABLE operationssupply.fld_agent_duty_log ADD CONSTRAINT fk_fld_agent_duty_log_agent_id FOREIGN KEY (agent_id) REFERENCES operationssupply.fld_agent(agent_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_fld_task_agent_id') THEN
        ALTER TABLE operationssupply.fld_task ADD CONSTRAINT fk_fld_task_agent_id FOREIGN KEY (agent_id) REFERENCES operationssupply.fld_agent(agent_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_fld_task_vehicle_id') THEN
        ALTER TABLE operationssupply.fld_task ADD CONSTRAINT fk_fld_task_vehicle_id FOREIGN KEY (vehicle_id) REFERENCES operationssupply.fld_vehicle(vehicle_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_fld_task_trip_id') THEN
        ALTER TABLE operationssupply.fld_task ADD CONSTRAINT fk_fld_task_trip_id FOREIGN KEY (trip_id) REFERENCES operationssupply.fld_trip(trip_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_fld_task_order_task_id') THEN
        ALTER TABLE operationssupply.fld_task_order ADD CONSTRAINT fk_fld_task_order_task_id FOREIGN KEY (task_id) REFERENCES operationssupply.fld_task(task_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_fld_task_milestone_task_id') THEN
        ALTER TABLE operationssupply.fld_task_milestone ADD CONSTRAINT fk_fld_task_milestone_task_id FOREIGN KEY (task_id) REFERENCES operationssupply.fld_task(task_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_fld_handover_code_task_id') THEN
        ALTER TABLE operationssupply.fld_handover_code ADD CONSTRAINT fk_fld_handover_code_task_id FOREIGN KEY (task_id) REFERENCES operationssupply.fld_task(task_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_fld_task_exception_task_id') THEN
        ALTER TABLE operationssupply.fld_task_exception ADD CONSTRAINT fk_fld_task_exception_task_id FOREIGN KEY (task_id) REFERENCES operationssupply.fld_task(task_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_fld_cash_collection_agent_id') THEN
        ALTER TABLE operationssupply.fld_cash_collection ADD CONSTRAINT fk_fld_cash_collection_agent_id FOREIGN KEY (agent_id) REFERENCES operationssupply.fld_agent(agent_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_fld_cash_collection_task_id') THEN
        ALTER TABLE operationssupply.fld_cash_collection ADD CONSTRAINT fk_fld_cash_collection_task_id FOREIGN KEY (task_id) REFERENCES operationssupply.fld_task(task_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_fld_sos_alert_agent_id') THEN
        ALTER TABLE operationssupply.fld_sos_alert ADD CONSTRAINT fk_fld_sos_alert_agent_id FOREIGN KEY (agent_id) REFERENCES operationssupply.fld_agent(agent_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_fld_sos_alert_task_id') THEN
        ALTER TABLE operationssupply.fld_sos_alert ADD CONSTRAINT fk_fld_sos_alert_task_id FOREIGN KEY (task_id) REFERENCES operationssupply.fld_task(task_id);
    END IF;
END $$;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_fld_cold_chain_reading_agent_id') THEN
        ALTER TABLE operationssupply.fld_cold_chain_reading ADD CONSTRAINT fk_fld_cold_chain_reading_agent_id FOREIGN KEY (agent_id) REFERENCES operationssupply.fld_agent(agent_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_fld_cold_chain_reading_agent_id ON operationssupply.fld_cold_chain_reading(agent_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_fld_gps_ping_agent_id') THEN
        ALTER TABLE operationssupply.fld_gps_ping ADD CONSTRAINT fk_fld_gps_ping_agent_id FOREIGN KEY (agent_id) REFERENCES operationssupply.fld_agent(agent_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_fld_gps_ping_agent_id ON operationssupply.fld_gps_ping(agent_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_fld_gps_ping_task_id') THEN
        ALTER TABLE operationssupply.fld_gps_ping ADD CONSTRAINT fk_fld_gps_ping_task_id FOREIGN KEY (task_id) REFERENCES operationssupply.fld_task(task_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_fld_gps_ping_task_id ON operationssupply.fld_gps_ping(task_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_fld_service_request_task_id') THEN
        ALTER TABLE operationssupply.fld_service_request ADD CONSTRAINT fk_fld_service_request_task_id FOREIGN KEY (task_id) REFERENCES operationssupply.fld_task(task_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_fld_service_request_task_id ON operationssupply.fld_service_request(task_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_fld_trip_agent_id') THEN
        ALTER TABLE operationssupply.fld_trip ADD CONSTRAINT fk_fld_trip_agent_id FOREIGN KEY (agent_id) REFERENCES operationssupply.fld_agent(agent_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_fld_trip_agent_id ON operationssupply.fld_trip(agent_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_consumption_reversed_by_consumption_id') THEN
        ALTER TABLE operationssupply.inv_consumption ADD CONSTRAINT fk_inv_consumption_reversed_by_consumption_id FOREIGN KEY (reversed_by_consumption_id) REFERENCES operationssupply.inv_consumption(consumption_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_inv_consumption_reversed_by_consumption_id ON operationssupply.inv_consumption(reversed_by_consumption_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_grn_item_store_location_id') THEN
        ALTER TABLE operationssupply.inv_grn_item ADD CONSTRAINT fk_inv_grn_item_store_location_id FOREIGN KEY (store_location_id) REFERENCES operationssupply.inv_store_location(store_location_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_inv_grn_item_store_location_id ON operationssupply.inv_grn_item(store_location_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_indent_purchase_request_id') THEN
        ALTER TABLE operationssupply.inv_indent ADD CONSTRAINT fk_inv_indent_purchase_request_id FOREIGN KEY (purchase_request_id) REFERENCES operationssupply.inv_purchase_request(purchase_request_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_inv_indent_purchase_request_id ON operationssupply.inv_indent(purchase_request_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_item_batch_grn_item_id') THEN
        ALTER TABLE operationssupply.inv_item_batch ADD CONSTRAINT fk_inv_item_batch_grn_item_id FOREIGN KEY (grn_item_id) REFERENCES operationssupply.inv_grn_item(grn_item_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_inv_item_batch_grn_item_id ON operationssupply.inv_item_batch(grn_item_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_purchase_order_indent_id') THEN
        ALTER TABLE operationssupply.inv_purchase_order ADD CONSTRAINT fk_inv_purchase_order_indent_id FOREIGN KEY (indent_id) REFERENCES operationssupply.inv_indent(indent_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_inv_purchase_order_indent_id ON operationssupply.inv_purchase_order(indent_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_purchase_order_rate_contract_id') THEN
        ALTER TABLE operationssupply.inv_purchase_order ADD CONSTRAINT fk_inv_purchase_order_rate_contract_id FOREIGN KEY (rate_contract_id) REFERENCES operationssupply.inv_rate_contract(rate_contract_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_inv_purchase_order_rate_contract_id ON operationssupply.inv_purchase_order(rate_contract_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_stock_store_location_id') THEN
        ALTER TABLE operationssupply.inv_stock ADD CONSTRAINT fk_inv_stock_store_location_id FOREIGN KEY (store_location_id) REFERENCES operationssupply.inv_store_location(store_location_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_inv_stock_store_location_id ON operationssupply.inv_stock(store_location_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_stock_ledger_from_store_id') THEN
        ALTER TABLE operationssupply.inv_stock_ledger ADD CONSTRAINT fk_inv_stock_ledger_from_store_id FOREIGN KEY (from_store_id) REFERENCES operationssupply.mst_store(store_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_inv_stock_ledger_from_store_id ON operationssupply.inv_stock_ledger(from_store_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_stock_ledger_to_store_id') THEN
        ALTER TABLE operationssupply.inv_stock_ledger ADD CONSTRAINT fk_inv_stock_ledger_to_store_id FOREIGN KEY (to_store_id) REFERENCES operationssupply.mst_store(store_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_inv_stock_ledger_to_store_id ON operationssupply.inv_stock_ledger(to_store_id);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'operationssupply' AND c.conname = 'fk_inv_store_item_policy_store_location_id') THEN
        ALTER TABLE operationssupply.inv_store_item_policy ADD CONSTRAINT fk_inv_store_item_policy_store_location_id FOREIGN KEY (store_location_id) REFERENCES operationssupply.inv_store_location(store_location_id);
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS ix_inv_store_item_policy_store_location_id ON operationssupply.inv_store_item_policy(store_location_id);

/* ---------- D. INDEXES ---------- */
CREATE INDEX IF NOT EXISTS ix_inv_stock_sync_log_store_id ON operationssupply.inv_stock_sync_log(store_id);
CREATE INDEX IF NOT EXISTS ix_inv_stock_snapshot_store_id ON operationssupply.inv_stock_snapshot(store_id);
CREATE INDEX IF NOT EXISTS ix_inv_stock_snapshot_item_id ON operationssupply.inv_stock_snapshot(item_id);
CREATE INDEX IF NOT EXISTS ix_inv_stock_snapshot_item_batch_id ON operationssupply.inv_stock_snapshot(item_batch_id);
CREATE INDEX IF NOT EXISTS ix_inv_physical_count_store_id ON operationssupply.inv_physical_count(store_id);
CREATE INDEX IF NOT EXISTS ix_inv_physical_count_item_physical_count_id ON operationssupply.inv_physical_count_item(physical_count_id);
CREATE INDEX IF NOT EXISTS ix_inv_physical_count_item_item_batch_id ON operationssupply.inv_physical_count_item(item_batch_id);
CREATE INDEX IF NOT EXISTS ix_inv_physical_count_item_stock_adjustment_id ON operationssupply.inv_physical_count_item(stock_adjustment_id);
CREATE INDEX IF NOT EXISTS ix_inv_rate_contract_vendor_id ON operationssupply.inv_rate_contract(vendor_id);
CREATE INDEX IF NOT EXISTS ix_inv_rate_contract_item_rate_contract_id ON operationssupply.inv_rate_contract_item(rate_contract_id);
CREATE INDEX IF NOT EXISTS ix_inv_rate_contract_item_item_id ON operationssupply.inv_rate_contract_item(item_id);
CREATE INDEX IF NOT EXISTS ix_inv_vendor_item_item_id ON operationssupply.inv_vendor_item(item_id);
CREATE INDEX IF NOT EXISTS ix_inv_grn_po_purchase_order_id ON operationssupply.inv_grn_po(purchase_order_id);
CREATE INDEX IF NOT EXISTS ix_mst_vendor_document_vendor_id ON operationssupply.mst_vendor_document(vendor_id);
CREATE INDEX IF NOT EXISTS ix_inv_vendor_rating_vendor_id ON operationssupply.inv_vendor_rating(vendor_id);
CREATE INDEX IF NOT EXISTS ix_inv_department_budget_store_id ON operationssupply.inv_department_budget(store_id);
CREATE INDEX IF NOT EXISTS ix_inv_department_budget_item_category_id ON operationssupply.inv_department_budget(item_category_id);
CREATE INDEX IF NOT EXISTS ix_fld_agent_vehicle_id ON operationssupply.fld_agent(vehicle_id);
CREATE INDEX IF NOT EXISTS ix_fld_agent_duty_log_agent_id ON operationssupply.fld_agent_duty_log(agent_id);
CREATE INDEX IF NOT EXISTS ix_fld_task_agent_id ON operationssupply.fld_task(agent_id);
CREATE INDEX IF NOT EXISTS ix_fld_task_vehicle_id ON operationssupply.fld_task(vehicle_id);
CREATE INDEX IF NOT EXISTS ix_fld_task_trip_id ON operationssupply.fld_task(trip_id);
CREATE INDEX IF NOT EXISTS ix_fld_task_order_online_order_id ON operationssupply.fld_task_order(online_order_id);
CREATE INDEX IF NOT EXISTS ix_fld_task_milestone_task_id ON operationssupply.fld_task_milestone(task_id);
CREATE INDEX IF NOT EXISTS ix_fld_handover_code_task_id ON operationssupply.fld_handover_code(task_id);
CREATE INDEX IF NOT EXISTS ix_fld_task_exception_task_id ON operationssupply.fld_task_exception(task_id);
CREATE INDEX IF NOT EXISTS ix_fld_cash_collection_agent_id ON operationssupply.fld_cash_collection(agent_id);
CREATE INDEX IF NOT EXISTS ix_fld_cash_collection_task_id ON operationssupply.fld_cash_collection(task_id);
CREATE INDEX IF NOT EXISTS ix_fld_cash_collection_online_order_id ON operationssupply.fld_cash_collection(online_order_id);
CREATE INDEX IF NOT EXISTS ix_fld_sos_alert_agent_id ON operationssupply.fld_sos_alert(agent_id);
CREATE INDEX IF NOT EXISTS ix_fld_sos_alert_task_id ON operationssupply.fld_sos_alert(task_id);

/* ---------- E. TABLE COMMENTS (FDS traceability) ---------- */
COMMENT ON TABLE operationssupply.inv_store_location IS 'Storage locations within a store (rack, shelf, bin; cold-chain and controlled areas) [FDS: STR-006, SUB-005]';
COMMENT ON TABLE operationssupply.inv_stock_sync_log IS 'Central / sub-store inventory sync status with failures and reconciliation [FDS: STR-003, STR-008]';
COMMENT ON TABLE operationssupply.inv_stock_snapshot IS 'Opening / closing stock snapshots by store, item and batch per period [FDS: STK-003, STK-007, EXP-002]';
COMMENT ON TABLE operationssupply.inv_physical_count IS 'Physical stock verification (cycle / full count) with freeze and variance approval [FDS: STK-010, STK-011, SCH-007]';
COMMENT ON TABLE operationssupply.inv_physical_count_item IS 'Counted quantities vs system with variance [FDS: STK-010]';
COMMENT ON TABLE operationssupply.inv_rate_contract IS 'Vendor rate contracts with validity [FDS: PUR-011, VEN-003]';
COMMENT ON TABLE operationssupply.inv_rate_contract_item IS 'Rate contract item rates [FDS: PUR-011]';
COMMENT ON TABLE operationssupply.inv_vendor_item IS 'Vendor-item mapping with preferred vendor and last purchase rate [FDS: VEN-003, PUR-011]';
COMMENT ON TABLE operationssupply.inv_grn_po IS 'GRN against multiple POs [FDS: GRN-001]';
COMMENT ON TABLE operationssupply.mst_vendor_document IS 'Vendor licences / agreements / certificates with expiry alerts (block PO on expiry) [FDS: VEN-002]';
COMMENT ON TABLE operationssupply.inv_vendor_rating IS 'Periodic vendor rating (timeliness, fill rate, price compliance, rejections, expiry returns) [FDS: VEN-004]';
COMMENT ON TABLE operationssupply.inv_department_budget IS 'Department consumption budgets with alerts [FDS: CON-004]';
COMMENT ON TABLE operationssupply.fld_agent IS 'Field agents (phlebo, rider, pharm agent, OPD rider, home-visit doctor) incl. partner agents [FDS: FAA-001..011, OPS-002, PHA-006, RRA-004, MFF-009]';
COMMENT ON TABLE operationssupply.fld_agent_duty_log IS 'Agent on-duty / off-duty log [FDS: FAA-001, OPS-007]';
COMMENT ON TABLE operationssupply.fld_task IS 'Field task: collection, pick-up, return, delivery, OPD pick-up / drop, home visit [FDS: OPS-001..006, FAA-002..007, PHA-001, RRA-001/002, MFF-007, OPU-001 (Field task entity)]';
COMMENT ON TABLE operationssupply.fld_task_order IS 'Orders served by a task (one phlebo visit for several family members / orders) [FDS: PBK-006, PHA-001]';
COMMENT ON TABLE operationssupply.fld_task_milestone IS 'Task milestones with timestamp and device location (offline-capable) [FDS: FAA-005, FAA-008, ORD-002]';
COMMENT ON TABLE operationssupply.fld_handover_code IS 'Hand-off verification codes (customer, centre, pharmacy, lab receipt, drop) - hashed [FDS: FAA-006, PCS-001, PLB-005, RPU-001/002, RDP-002/004, MFF-008, MDL-002 (Handover code entity)]';
COMMENT ON TABLE operationssupply.fld_task_exception IS 'Exceptions reported by agents / ops (customer not available, wrong address, refused, partial, rejected) [FDS: FAA-007, OPS-006, PHA-005, MDL-004/005]';
COMMENT ON TABLE operationssupply.fld_cash_collection IS 'Cash / UPI collected at doorstep and agent cash-in-hand deposits [FDS: FAA-009, CHK-006]';
COMMENT ON TABLE operationssupply.fld_sos_alert IS 'Agent SOS alerts with location and current task [FDS: FAA-010]';

COMMIT;
