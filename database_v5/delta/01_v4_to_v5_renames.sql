-- HIMS database_v5 upgrade: run on an existing database_v4 database (PostgreSQL 15+).
-- 0) schemas renamed without underscores (identity_org -> identityorg, ...)
-- 1) mst_* tables get a module prefix  2) ref_* replicas get the source module prefix
-- 3) lims.mst_lab_test: specimen_type -> specimen_type_id, container_type -> container_type_id (INT FKs)
-- 4) new lims.mst_lab_section  5) organization_id removed (one database per tenant)
-- Renames keep all data, grants, defaults and foreign keys. Runs in one transaction.
\set ON_ERROR_STOP on
BEGIN;

-- ============ 0. schema names without underscores ============
ALTER SCHEMA identity_org RENAME TO identityorg;
ALTER SCHEMA patient_engagement RENAME TO patientengagement;
ALTER SCHEMA clinical_care RENAME TO clinicalcare;
ALTER SCHEMA revenue_finance RENAME TO revenuefinance;
ALTER SCHEMA operations_supply RENAME TO operationssupply;
ALTER SCHEMA integration_comms RENAME TO integrationcomms;

-- ============ 1+2. table renames (186) ============
ALTER TABLE IF EXISTS identityorg.mst_department RENAME TO mst_core_department;
ALTER TABLE IF EXISTS identityorg.mst_branch_department RENAME TO mst_core_branch_department;
ALTER TABLE IF EXISTS identityorg.mst_specialty RENAME TO mst_hr_specialty;
ALTER TABLE IF EXISTS identityorg.mst_designation RENAME TO mst_hr_designation;
ALTER TABLE IF EXISTS identityorg.mst_shift RENAME TO mst_hr_shift;
ALTER TABLE IF EXISTS patientengagement.mst_building RENAME TO mst_adt_building;
ALTER TABLE IF EXISTS patientengagement.mst_floor RENAME TO mst_adt_floor;
ALTER TABLE IF EXISTS patientengagement.mst_ward RENAME TO mst_adt_ward;
ALTER TABLE IF EXISTS patientengagement.mst_room RENAME TO mst_adt_room;
ALTER TABLE IF EXISTS patientengagement.mst_bed RENAME TO mst_adt_bed;
ALTER TABLE IF EXISTS clinicalcare.mst_procedure RENAME TO mst_ot_procedure;
ALTER TABLE IF EXISTS clinicalcare.mst_clinical_template RENAME TO mst_emr_clinical_template;
ALTER TABLE IF EXISTS clinicalcare.mst_order_set RENAME TO mst_ord_order_set;
ALTER TABLE IF EXISTS clinicalcare.mst_order_set_item RENAME TO mst_ord_order_set_item;
ALTER TABLE IF EXISTS clinicalcare.mst_immunization_schedule RENAME TO mst_emr_immunization_schedule;
ALTER TABLE IF EXISTS clinicalcare.mst_template_assignment RENAME TO mst_emr_template_assignment;
ALTER TABLE IF EXISTS clinicalcare.mst_external_therapy RENAME TO mst_emr_external_therapy;
ALTER TABLE IF EXISTS clinicalcare.mst_yoga_protocol RENAME TO mst_emr_yoga_protocol;
ALTER TABLE IF EXISTS revenuefinance.mst_service_category RENAME TO mst_bil_service_category;
ALTER TABLE IF EXISTS revenuefinance.mst_service RENAME TO mst_bil_service;
ALTER TABLE IF EXISTS revenuefinance.mst_payer RENAME TO mst_bil_payer;
ALTER TABLE IF EXISTS revenuefinance.mst_tariff_plan RENAME TO mst_bil_tariff_plan;
ALTER TABLE IF EXISTS revenuefinance.mst_tariff_rate RENAME TO mst_bil_tariff_rate;
ALTER TABLE IF EXISTS revenuefinance.mst_package RENAME TO mst_bil_package;
ALTER TABLE IF EXISTS revenuefinance.mst_package_item RENAME TO mst_bil_package_item;
ALTER TABLE IF EXISTS revenuefinance.mst_discount_scheme RENAME TO mst_bil_discount_scheme;
ALTER TABLE IF EXISTS revenuefinance.mst_coupon RENAME TO mst_bil_coupon;
ALTER TABLE IF EXISTS revenuefinance.mst_package_payer RENAME TO mst_bil_package_payer;
ALTER TABLE IF EXISTS revenuefinance.mst_kit RENAME TO mst_bil_kit;
ALTER TABLE IF EXISTS revenuefinance.mst_kit_item RENAME TO mst_bil_kit_item;
ALTER TABLE IF EXISTS revenuefinance.mst_loyalty_tier RENAME TO mst_bil_loyalty_tier;
ALTER TABLE IF EXISTS revenuefinance.mst_loyalty_rule RENAME TO mst_bil_loyalty_rule;
ALTER TABLE IF EXISTS revenuefinance.mst_insurance_plan RENAME TO mst_ins_insurance_plan;
ALTER TABLE IF EXISTS revenuefinance.mst_insurance_sublimit RENAME TO mst_ins_insurance_sublimit;
ALTER TABLE IF EXISTS revenuefinance.mst_payer_network RENAME TO mst_ins_payer_network;
ALTER TABLE IF EXISTS revenuefinance.mst_copay_rule RENAME TO mst_ins_copay_rule;
ALTER TABLE IF EXISTS revenuefinance.mst_hsn_sac RENAME TO mst_fin_hsn_sac;
ALTER TABLE IF EXISTS operationssupply.mst_vendor RENAME TO mst_inv_vendor;
ALTER TABLE IF EXISTS operationssupply.mst_item_category RENAME TO mst_inv_item_category;
ALTER TABLE IF EXISTS operationssupply.mst_item RENAME TO mst_inv_item;
ALTER TABLE IF EXISTS operationssupply.mst_store RENAME TO mst_inv_store;
ALTER TABLE IF EXISTS operationssupply.mst_vendor_document RENAME TO mst_inv_vendor_document;
ALTER TABLE IF EXISTS integrationcomms.mst_report_letterhead RENAME TO mst_rpt_report_letterhead;
ALTER TABLE IF EXISTS pharmacy.mst_generic RENAME TO mst_pha_generic;
ALTER TABLE IF EXISTS pharmacy.mst_drug RENAME TO mst_pha_drug;
ALTER TABLE IF EXISTS pharmacy.mst_drug_generic RENAME TO mst_pha_drug_generic;
ALTER TABLE IF EXISTS pharmacy.mst_drug_substitute RENAME TO mst_pha_drug_substitute;
ALTER TABLE IF EXISTS pharmacy.mst_drug_interaction RENAME TO mst_pha_drug_interaction;
ALTER TABLE IF EXISTS pharmacy.mst_drug_contraindication RENAME TO mst_pha_drug_contraindication;
ALTER TABLE IF EXISTS pharmacy.mst_allergen RENAME TO mst_pha_allergen;
ALTER TABLE IF EXISTS pharmacy.mst_drug_dose_range RENAME TO mst_pha_drug_dose_range;
ALTER TABLE IF EXISTS pharmacy.mst_drug_change_request RENAME TO mst_pha_drug_change_request;
ALTER TABLE IF EXISTS pharmacy.mst_lasa_pair RENAME TO mst_pha_lasa_pair;
ALTER TABLE IF EXISTS identityorg.ref_patient RENAME TO ref_pat_patient;
ALTER TABLE IF EXISTS identityorg.ref_payer RENAME TO ref_bil_payer;
ALTER TABLE IF EXISTS patientengagement.ref_organization RENAME TO ref_core_organization;
ALTER TABLE IF EXISTS patientengagement.ref_branch RENAME TO ref_core_branch;
ALTER TABLE IF EXISTS patientengagement.ref_department RENAME TO ref_core_department;
ALTER TABLE IF EXISTS patientengagement.ref_payer RENAME TO ref_bil_payer;
ALTER TABLE IF EXISTS patientengagement.ref_specialty RENAME TO ref_hr_specialty;
ALTER TABLE IF EXISTS patientengagement.ref_practitioner RENAME TO ref_hr_practitioner;
ALTER TABLE IF EXISTS patientengagement.ref_tariff_plan RENAME TO ref_bil_tariff_plan;
ALTER TABLE IF EXISTS patientengagement.ref_employee RENAME TO ref_hr_employee;
ALTER TABLE IF EXISTS patientengagement.ref_service RENAME TO ref_bil_service;
ALTER TABLE IF EXISTS patientengagement.ref_patient_balance RENAME TO ref_bil_patient_balance;
ALTER TABLE IF EXISTS patientengagement.ref_order_item RENAME TO ref_ord_order_item;
ALTER TABLE IF EXISTS patientengagement.ref_dicom_study RENAME TO ref_pacs_dicom_study;
ALTER TABLE IF EXISTS patientengagement.ref_estimate RENAME TO ref_bil_estimate;
ALTER TABLE IF EXISTS patientengagement.ref_discount_scheme RENAME TO ref_bil_discount_scheme;
ALTER TABLE IF EXISTS patientengagement.ref_complaint RENAME TO ref_adm_complaint;
ALTER TABLE IF EXISTS patientengagement.ref_coupon RENAME TO ref_bil_coupon;
ALTER TABLE IF EXISTS patientengagement.ref_payment_gateway_txn RENAME TO ref_bil_payment_gateway_txn;
ALTER TABLE IF EXISTS patientengagement.ref_clinical_order RENAME TO ref_ord_clinical_order;
ALTER TABLE IF EXISTS patientengagement.ref_service_request RENAME TO ref_fld_service_request;
ALTER TABLE IF EXISTS patientengagement.ref_bill RENAME TO ref_bil_bill;
ALTER TABLE IF EXISTS patientengagement.ref_item RENAME TO ref_inv_item;
ALTER TABLE IF EXISTS patientengagement.ref_capacity_agent RENAME TO ref_fld_agent;
ALTER TABLE IF EXISTS clinicalcare.ref_organization RENAME TO ref_core_organization;
ALTER TABLE IF EXISTS clinicalcare.ref_branch RENAME TO ref_core_branch;
ALTER TABLE IF EXISTS clinicalcare.ref_floor RENAME TO ref_adt_floor;
ALTER TABLE IF EXISTS clinicalcare.ref_service RENAME TO ref_bil_service;
ALTER TABLE IF EXISTS clinicalcare.ref_specialty RENAME TO ref_hr_specialty;
ALTER TABLE IF EXISTS clinicalcare.ref_clinical_code RENAME TO ref_core_clinical_code;
ALTER TABLE IF EXISTS clinicalcare.ref_drug RENAME TO ref_pha_drug;
ALTER TABLE IF EXISTS clinicalcare.ref_patient RENAME TO ref_pat_patient;
ALTER TABLE IF EXISTS clinicalcare.ref_encounter RENAME TO ref_pat_encounter;
ALTER TABLE IF EXISTS clinicalcare.ref_practitioner RENAME TO ref_hr_practitioner;
ALTER TABLE IF EXISTS clinicalcare.ref_employee RENAME TO ref_hr_employee;
ALTER TABLE IF EXISTS clinicalcare.ref_allergen RENAME TO ref_pha_allergen;
ALTER TABLE IF EXISTS clinicalcare.ref_item RENAME TO ref_inv_item;
ALTER TABLE IF EXISTS clinicalcare.ref_payer RENAME TO ref_bil_payer;
ALTER TABLE IF EXISTS clinicalcare.ref_department RENAME TO ref_core_department;
ALTER TABLE IF EXISTS clinicalcare.ref_generic RENAME TO ref_pha_generic;
ALTER TABLE IF EXISTS clinicalcare.ref_admission RENAME TO ref_adt_admission;
ALTER TABLE IF EXISTS clinicalcare.ref_ward RENAME TO ref_adt_ward;
ALTER TABLE IF EXISTS clinicalcare.ref_shift RENAME TO ref_hr_shift;
ALTER TABLE IF EXISTS clinicalcare.ref_bed RENAME TO ref_adt_bed;
ALTER TABLE IF EXISTS clinicalcare.ref_micro_culture RENAME TO ref_lab_micro_culture;
ALTER TABLE IF EXISTS clinicalcare.ref_unit_issue RENAME TO ref_bb_unit_issue;
ALTER TABLE IF EXISTS clinicalcare.ref_medication_dispensed RENAME TO ref_pha_medication_dispensed;
ALTER TABLE IF EXISTS clinicalcare.ref_code_system_release RENAME TO ref_core_code_system_release;
ALTER TABLE IF EXISTS lims.ref_organization RENAME TO ref_core_organization;
ALTER TABLE IF EXISTS lims.ref_branch RENAME TO ref_core_branch;
ALTER TABLE IF EXISTS lims.ref_service RENAME TO ref_bil_service;
ALTER TABLE IF EXISTS lims.ref_clinical_code RENAME TO ref_core_clinical_code;
ALTER TABLE IF EXISTS lims.ref_patient RENAME TO ref_pat_patient;
ALTER TABLE IF EXISTS lims.ref_clinical_order RENAME TO ref_ord_clinical_order;
ALTER TABLE IF EXISTS lims.ref_employee RENAME TO ref_hr_employee;
ALTER TABLE IF EXISTS lims.ref_order_item RENAME TO ref_ord_order_item;
ALTER TABLE IF EXISTS lims.ref_generic RENAME TO ref_pha_generic;
ALTER TABLE IF EXISTS lims.ref_report_letterhead RENAME TO ref_rpt_report_letterhead;
ALTER TABLE IF EXISTS lims.ref_practitioner RENAME TO ref_hr_practitioner;
ALTER TABLE IF EXISTS lims.ref_item RENAME TO ref_inv_item;
ALTER TABLE IF EXISTS lims.ref_vendor RENAME TO ref_inv_vendor;
ALTER TABLE IF EXISTS lims.ref_encounter RENAME TO ref_pat_encounter;
ALTER TABLE IF EXISTS lims.ref_transport_trip RENAME TO ref_fld_trip;
ALTER TABLE IF EXISTS rims.ref_organization RENAME TO ref_core_organization;
ALTER TABLE IF EXISTS rims.ref_branch RENAME TO ref_core_branch;
ALTER TABLE IF EXISTS rims.ref_service RENAME TO ref_bil_service;
ALTER TABLE IF EXISTS rims.ref_patient RENAME TO ref_pat_patient;
ALTER TABLE IF EXISTS rims.ref_employee RENAME TO ref_hr_employee;
ALTER TABLE IF EXISTS rims.ref_order_item RENAME TO ref_ord_order_item;
ALTER TABLE IF EXISTS rims.ref_report_letterhead RENAME TO ref_rpt_report_letterhead;
ALTER TABLE IF EXISTS rims.ref_practitioner RENAME TO ref_hr_practitioner;
ALTER TABLE IF EXISTS rims.ref_item RENAME TO ref_inv_item;
ALTER TABLE IF EXISTS rims.ref_room RENAME TO ref_adt_room;
ALTER TABLE IF EXISTS rims.ref_slot RENAME TO ref_sch_slot;
ALTER TABLE IF EXISTS rims.ref_appointment RENAME TO ref_sch_appointment;
ALTER TABLE IF EXISTS revenuefinance.ref_organization RENAME TO ref_core_organization;
ALTER TABLE IF EXISTS revenuefinance.ref_branch RENAME TO ref_core_branch;
ALTER TABLE IF EXISTS revenuefinance.ref_department RENAME TO ref_core_department;
ALTER TABLE IF EXISTS revenuefinance.ref_clinical_code RENAME TO ref_core_clinical_code;
ALTER TABLE IF EXISTS revenuefinance.ref_item_category RENAME TO ref_inv_item_category;
ALTER TABLE IF EXISTS revenuefinance.ref_patient RENAME TO ref_pat_patient;
ALTER TABLE IF EXISTS revenuefinance.ref_procedure RENAME TO ref_ot_procedure;
ALTER TABLE IF EXISTS revenuefinance.ref_encounter RENAME TO ref_pat_encounter;
ALTER TABLE IF EXISTS revenuefinance.ref_employee RENAME TO ref_hr_employee;
ALTER TABLE IF EXISTS revenuefinance.ref_item RENAME TO ref_inv_item;
ALTER TABLE IF EXISTS revenuefinance.ref_item_batch RENAME TO ref_inv_item_batch;
ALTER TABLE IF EXISTS revenuefinance.ref_order_item RENAME TO ref_ord_order_item;
ALTER TABLE IF EXISTS revenuefinance.ref_dispense_item RENAME TO ref_pha_dispense_item;
ALTER TABLE IF EXISTS revenuefinance.ref_bed_allocation RENAME TO ref_adt_bed_allocation;
ALTER TABLE IF EXISTS revenuefinance.ref_practitioner RENAME TO ref_hr_practitioner;
ALTER TABLE IF EXISTS revenuefinance.ref_patient_payer RENAME TO ref_pat_patient_payer;
ALTER TABLE IF EXISTS revenuefinance.ref_asset RENAME TO ref_adm_asset;
ALTER TABLE IF EXISTS revenuefinance.ref_shift RENAME TO ref_hr_shift;
ALTER TABLE IF EXISTS revenuefinance.ref_ward RENAME TO ref_adt_ward;
ALTER TABLE IF EXISTS revenuefinance.ref_designation RENAME TO ref_hr_designation;
ALTER TABLE IF EXISTS revenuefinance.ref_room RENAME TO ref_adt_room;
ALTER TABLE IF EXISTS revenuefinance.ref_vehicle RENAME TO ref_fld_vehicle;
ALTER TABLE IF EXISTS operationssupply.ref_organization RENAME TO ref_core_organization;
ALTER TABLE IF EXISTS operationssupply.ref_branch RENAME TO ref_core_branch;
ALTER TABLE IF EXISTS operationssupply.ref_department RENAME TO ref_core_department;
ALTER TABLE IF EXISTS operationssupply.ref_employee RENAME TO ref_hr_employee;
ALTER TABLE IF EXISTS operationssupply.ref_booking RENAME TO ref_ot_booking;
ALTER TABLE IF EXISTS operationssupply.ref_patient RENAME TO ref_pat_patient;
ALTER TABLE IF EXISTS operationssupply.ref_encounter RENAME TO ref_pat_encounter;
ALTER TABLE IF EXISTS operationssupply.ref_service RENAME TO ref_bil_service;
ALTER TABLE IF EXISTS operationssupply.ref_admission RENAME TO ref_adt_admission;
ALTER TABLE IF EXISTS operationssupply.ref_diet_plan RENAME TO ref_diet_diet_plan;
ALTER TABLE IF EXISTS operationssupply.ref_bed RENAME TO ref_adt_bed;
ALTER TABLE IF EXISTS operationssupply.ref_room RENAME TO ref_adt_room;
ALTER TABLE IF EXISTS operationssupply.ref_ward RENAME TO ref_adt_ward;
ALTER TABLE IF EXISTS operationssupply.ref_clinical_order RENAME TO ref_ord_clinical_order;
ALTER TABLE IF EXISTS operationssupply.ref_appointment RENAME TO ref_sch_appointment;
ALTER TABLE IF EXISTS operationssupply.ref_hsn_sac RENAME TO ref_fin_hsn_sac;
ALTER TABLE IF EXISTS operationssupply.ref_online_order RENAME TO ref_ecom_online_order;
ALTER TABLE IF EXISTS integrationcomms.ref_patient RENAME TO ref_pat_patient;
ALTER TABLE IF EXISTS integrationcomms.ref_encounter RENAME TO ref_pat_encounter;
ALTER TABLE IF EXISTS integrationcomms.ref_organization RENAME TO ref_core_organization;
ALTER TABLE IF EXISTS integrationcomms.ref_branch RENAME TO ref_core_branch;
ALTER TABLE IF EXISTS integrationcomms.ref_payer RENAME TO ref_bil_payer;
ALTER TABLE IF EXISTS pharmacy.ref_organization RENAME TO ref_core_organization;
ALTER TABLE IF EXISTS pharmacy.ref_branch RENAME TO ref_core_branch;
ALTER TABLE IF EXISTS pharmacy.ref_clinical_code RENAME TO ref_core_clinical_code;
ALTER TABLE IF EXISTS pharmacy.ref_employee RENAME TO ref_hr_employee;
ALTER TABLE IF EXISTS pharmacy.ref_patient RENAME TO ref_pat_patient;
ALTER TABLE IF EXISTS pharmacy.ref_encounter RENAME TO ref_pat_encounter;
ALTER TABLE IF EXISTS pharmacy.ref_prescription RENAME TO ref_ord_prescription;
ALTER TABLE IF EXISTS pharmacy.ref_prescription_item RENAME TO ref_ord_prescription_item;
ALTER TABLE IF EXISTS pharmacy.ref_practitioner RENAME TO ref_hr_practitioner;
ALTER TABLE IF EXISTS pharmacy.ref_item RENAME TO ref_inv_item;
ALTER TABLE IF EXISTS pharmacy.ref_item_batch RENAME TO ref_inv_item_batch;
ALTER TABLE IF EXISTS pharmacy.ref_store RENAME TO ref_inv_store;
ALTER TABLE IF EXISTS pharmacy.ref_stock RENAME TO ref_inv_stock;
ALTER TABLE IF EXISTS pharmacy.ref_hsn_sac RENAME TO ref_fin_hsn_sac;

-- ============ ref_* compatibility views (8) ============
ALTER VIEW IF EXISTS patientengagement.ref_appointment RENAME TO ref_sch_appointment;
ALTER VIEW IF EXISTS patientengagement.ref_encounter RENAME TO ref_pat_encounter;
ALTER VIEW IF EXISTS patientengagement.ref_patient RENAME TO ref_pat_patient;
ALTER VIEW IF EXISTS patientengagement.ref_slot RENAME TO ref_sch_slot;
ALTER VIEW IF EXISTS revenuefinance.ref_receipt RENAME TO ref_bil_receipt;
ALTER VIEW IF EXISTS operationssupply.ref_vendor RENAME TO ref_inv_vendor;
ALTER VIEW IF EXISTS operationssupply.ref_grn RENAME TO ref_inv_grn;
ALTER VIEW IF EXISTS operationssupply.ref_item RENAME TO ref_inv_item;

-- ============ constraint names that embed the old table name ============
ALTER TABLE identityorg.mst_core_department RENAME CONSTRAINT mst_department_pkey TO mst_core_department_pkey;
ALTER TABLE identityorg.mst_core_department RENAME CONSTRAINT mst_department_organization_id_fkey TO mst_core_department_organization_id_fkey;
ALTER TABLE identityorg.mst_core_department RENAME CONSTRAINT mst_department_parent_department_id_fkey TO mst_core_department_parent_department_id_fkey;
ALTER TABLE identityorg.mst_core_branch_department RENAME CONSTRAINT mst_branch_department_pkey TO mst_core_branch_department_pkey;
ALTER TABLE identityorg.mst_core_branch_department RENAME CONSTRAINT mst_branch_department_branch_id_fkey TO mst_core_branch_department_branch_id_fkey;
ALTER TABLE identityorg.mst_core_branch_department RENAME CONSTRAINT mst_branch_department_department_id_fkey TO mst_core_branch_department_department_id_fkey;
ALTER TABLE identityorg.mst_hr_specialty RENAME CONSTRAINT mst_specialty_pkey TO mst_hr_specialty_pkey;
ALTER TABLE identityorg.mst_hr_specialty RENAME CONSTRAINT mst_specialty_specialty_code_key TO mst_hr_specialty_specialty_code_key;
ALTER TABLE identityorg.mst_hr_specialty RENAME CONSTRAINT mst_specialty_department_id_fkey TO mst_hr_specialty_department_id_fkey;
ALTER TABLE identityorg.mst_hr_designation RENAME CONSTRAINT mst_designation_pkey TO mst_hr_designation_pkey;
ALTER TABLE identityorg.mst_hr_designation RENAME CONSTRAINT mst_designation_designation_code_key TO mst_hr_designation_designation_code_key;
ALTER TABLE identityorg.mst_hr_shift RENAME CONSTRAINT mst_shift_pkey TO mst_hr_shift_pkey;
ALTER TABLE identityorg.mst_hr_shift RENAME CONSTRAINT mst_shift_organization_id_fkey TO mst_hr_shift_organization_id_fkey;
ALTER TABLE identityorg.ref_pat_patient RENAME CONSTRAINT ref_patient_pkey TO ref_pat_patient_pkey;
ALTER TABLE identityorg.ref_bil_payer RENAME CONSTRAINT ref_payer_pkey TO ref_bil_payer_pkey;
ALTER TABLE identityorg.mst_hr_specialty RENAME CONSTRAINT fk_mst_specialty_sub_specialty_of_id TO fk_mst_hr_specialty_sub_specialty_of_id;
ALTER TABLE patientengagement.mst_adt_building RENAME CONSTRAINT mst_building_pkey TO mst_adt_building_pkey;
ALTER TABLE patientengagement.mst_adt_floor RENAME CONSTRAINT mst_floor_pkey TO mst_adt_floor_pkey;
ALTER TABLE patientengagement.mst_adt_floor RENAME CONSTRAINT mst_floor_building_id_fkey TO mst_adt_floor_building_id_fkey;
ALTER TABLE patientengagement.mst_adt_ward RENAME CONSTRAINT mst_ward_pkey TO mst_adt_ward_pkey;
ALTER TABLE patientengagement.mst_adt_ward RENAME CONSTRAINT mst_ward_floor_id_fkey TO mst_adt_ward_floor_id_fkey;
ALTER TABLE patientengagement.mst_adt_room RENAME CONSTRAINT mst_room_pkey TO mst_adt_room_pkey;
ALTER TABLE patientengagement.mst_adt_room RENAME CONSTRAINT mst_room_ward_id_fkey TO mst_adt_room_ward_id_fkey;
ALTER TABLE patientengagement.mst_adt_bed RENAME CONSTRAINT mst_bed_pkey TO mst_adt_bed_pkey;
ALTER TABLE patientengagement.mst_adt_bed RENAME CONSTRAINT mst_bed_room_id_fkey TO mst_adt_bed_room_id_fkey;
ALTER TABLE patientengagement.ref_core_organization RENAME CONSTRAINT ref_organization_pkey TO ref_core_organization_pkey;
ALTER TABLE patientengagement.ref_core_branch RENAME CONSTRAINT ref_branch_pkey TO ref_core_branch_pkey;
ALTER TABLE patientengagement.ref_core_department RENAME CONSTRAINT ref_department_pkey TO ref_core_department_pkey;
ALTER TABLE patientengagement.ref_bil_payer RENAME CONSTRAINT ref_payer_pkey TO ref_bil_payer_pkey;
ALTER TABLE patientengagement.ref_hr_specialty RENAME CONSTRAINT ref_specialty_pkey TO ref_hr_specialty_pkey;
ALTER TABLE patientengagement.ref_hr_practitioner RENAME CONSTRAINT ref_practitioner_pkey TO ref_hr_practitioner_pkey;
ALTER TABLE patientengagement.ref_bil_tariff_plan RENAME CONSTRAINT ref_tariff_plan_pkey TO ref_bil_tariff_plan_pkey;
ALTER TABLE patientengagement.ref_hr_employee RENAME CONSTRAINT ref_employee_pkey TO ref_hr_employee_pkey;
ALTER TABLE patientengagement.ref_bil_service RENAME CONSTRAINT ref_service_pkey TO ref_bil_service_pkey;
ALTER TABLE patientengagement.ref_bil_patient_balance RENAME CONSTRAINT ref_patient_balance_pkey TO ref_bil_patient_balance_pkey;
ALTER TABLE patientengagement.ref_ord_order_item RENAME CONSTRAINT ref_order_item_pkey TO ref_ord_order_item_pkey;
ALTER TABLE patientengagement.ref_pacs_dicom_study RENAME CONSTRAINT ref_dicom_study_pkey TO ref_pacs_dicom_study_pkey;
ALTER TABLE patientengagement.ref_bil_estimate RENAME CONSTRAINT ref_estimate_pkey TO ref_bil_estimate_pkey;
ALTER TABLE patientengagement.ref_bil_discount_scheme RENAME CONSTRAINT ref_discount_scheme_pkey TO ref_bil_discount_scheme_pkey;
ALTER TABLE patientengagement.ref_adm_complaint RENAME CONSTRAINT ref_complaint_pkey TO ref_adm_complaint_pkey;
ALTER TABLE patientengagement.ref_bil_coupon RENAME CONSTRAINT ref_coupon_pkey TO ref_bil_coupon_pkey;
ALTER TABLE patientengagement.ref_bil_payment_gateway_txn RENAME CONSTRAINT ref_payment_gateway_txn_pkey TO ref_bil_payment_gateway_txn_pkey;
ALTER TABLE patientengagement.ref_ord_clinical_order RENAME CONSTRAINT ref_clinical_order_pkey TO ref_ord_clinical_order_pkey;
ALTER TABLE patientengagement.ref_fld_service_request RENAME CONSTRAINT ref_service_request_pkey TO ref_fld_service_request_pkey;
ALTER TABLE patientengagement.ref_bil_bill RENAME CONSTRAINT ref_bill_pkey TO ref_bil_bill_pkey;
ALTER TABLE patientengagement.ref_inv_item RENAME CONSTRAINT ref_item_pkey TO ref_inv_item_pkey;
ALTER TABLE patientengagement.ref_fld_agent RENAME CONSTRAINT ref_capacity_agent_pkey TO ref_fld_agent_pkey;
ALTER TABLE clinicalcare.mst_ot_procedure RENAME CONSTRAINT mst_procedure_pkey TO mst_ot_procedure_pkey;
ALTER TABLE clinicalcare.mst_ot_procedure RENAME CONSTRAINT mst_procedure_service_id_key TO mst_ot_procedure_service_id_key;
ALTER TABLE clinicalcare.mst_emr_clinical_template RENAME CONSTRAINT mst_clinical_template_pkey TO mst_emr_clinical_template_pkey;
ALTER TABLE clinicalcare.mst_ord_order_set RENAME CONSTRAINT mst_order_set_pkey TO mst_ord_order_set_pkey;
ALTER TABLE clinicalcare.mst_ord_order_set_item RENAME CONSTRAINT mst_order_set_item_pkey TO mst_ord_order_set_item_pkey;
ALTER TABLE clinicalcare.mst_ord_order_set_item RENAME CONSTRAINT mst_order_set_item_order_set_id_fkey TO mst_ord_order_set_item_order_set_id_fkey;
ALTER TABLE clinicalcare.ref_core_organization RENAME CONSTRAINT ref_organization_pkey TO ref_core_organization_pkey;
ALTER TABLE clinicalcare.ref_core_branch RENAME CONSTRAINT ref_branch_pkey TO ref_core_branch_pkey;
ALTER TABLE clinicalcare.ref_adt_floor RENAME CONSTRAINT ref_floor_pkey TO ref_adt_floor_pkey;
ALTER TABLE clinicalcare.ref_bil_service RENAME CONSTRAINT ref_service_pkey TO ref_bil_service_pkey;
ALTER TABLE clinicalcare.ref_hr_specialty RENAME CONSTRAINT ref_specialty_pkey TO ref_hr_specialty_pkey;
ALTER TABLE clinicalcare.ref_core_clinical_code RENAME CONSTRAINT ref_clinical_code_pkey TO ref_core_clinical_code_pkey;
ALTER TABLE clinicalcare.ref_pha_drug RENAME CONSTRAINT ref_drug_pkey TO ref_pha_drug_pkey;
ALTER TABLE clinicalcare.ref_pat_patient RENAME CONSTRAINT ref_patient_pkey TO ref_pat_patient_pkey;
ALTER TABLE clinicalcare.ref_pat_encounter RENAME CONSTRAINT ref_encounter_pkey TO ref_pat_encounter_pkey;
ALTER TABLE clinicalcare.ref_hr_practitioner RENAME CONSTRAINT ref_practitioner_pkey TO ref_hr_practitioner_pkey;
ALTER TABLE clinicalcare.ref_hr_employee RENAME CONSTRAINT ref_employee_pkey TO ref_hr_employee_pkey;
ALTER TABLE clinicalcare.ref_pha_allergen RENAME CONSTRAINT ref_allergen_pkey TO ref_pha_allergen_pkey;
ALTER TABLE clinicalcare.ref_inv_item RENAME CONSTRAINT ref_item_pkey TO ref_inv_item_pkey;
ALTER TABLE clinicalcare.ref_bil_payer RENAME CONSTRAINT ref_payer_pkey TO ref_bil_payer_pkey;
ALTER TABLE clinicalcare.ref_core_department RENAME CONSTRAINT ref_department_pkey TO ref_core_department_pkey;
ALTER TABLE clinicalcare.ref_pha_generic RENAME CONSTRAINT ref_generic_pkey TO ref_pha_generic_pkey;
ALTER TABLE clinicalcare.ref_adt_admission RENAME CONSTRAINT ref_admission_pkey TO ref_adt_admission_pkey;
ALTER TABLE clinicalcare.ref_adt_ward RENAME CONSTRAINT ref_ward_pkey TO ref_adt_ward_pkey;
ALTER TABLE clinicalcare.ref_hr_shift RENAME CONSTRAINT ref_shift_pkey TO ref_hr_shift_pkey;
ALTER TABLE clinicalcare.ref_adt_bed RENAME CONSTRAINT ref_bed_pkey TO ref_adt_bed_pkey;
ALTER TABLE clinicalcare.ref_lab_micro_culture RENAME CONSTRAINT ref_micro_culture_pkey TO ref_lab_micro_culture_pkey;
ALTER TABLE clinicalcare.ref_bb_unit_issue RENAME CONSTRAINT ref_unit_issue_pkey TO ref_bb_unit_issue_pkey;
ALTER TABLE clinicalcare.ref_pha_medication_dispensed RENAME CONSTRAINT ref_medication_dispensed_pkey TO ref_pha_medication_dispensed_pkey;
ALTER TABLE clinicalcare.mst_emr_immunization_schedule RENAME CONSTRAINT mst_immunization_schedule_pkey TO mst_emr_immunization_schedule_pkey;
ALTER TABLE clinicalcare.mst_emr_template_assignment RENAME CONSTRAINT mst_template_assignment_pkey TO mst_emr_template_assignment_pkey;
ALTER TABLE clinicalcare.mst_emr_external_therapy RENAME CONSTRAINT mst_external_therapy_pkey TO mst_emr_external_therapy_pkey;
ALTER TABLE clinicalcare.mst_emr_external_therapy RENAME CONSTRAINT mst_external_therapy_therapy_code_key TO mst_emr_external_therapy_therapy_code_key;
ALTER TABLE clinicalcare.mst_emr_yoga_protocol RENAME CONSTRAINT mst_yoga_protocol_pkey TO mst_emr_yoga_protocol_pkey;
ALTER TABLE clinicalcare.mst_emr_yoga_protocol RENAME CONSTRAINT mst_yoga_protocol_protocol_code_key TO mst_emr_yoga_protocol_protocol_code_key;
ALTER TABLE clinicalcare.ref_core_code_system_release RENAME CONSTRAINT ref_code_system_release_pkey TO ref_core_code_system_release_pkey;
ALTER TABLE clinicalcare.mst_emr_template_assignment RENAME CONSTRAINT fk_mst_template_assignment_clinical_template_id TO fk_mst_emr_template_assignment_clinical_template_id;
ALTER TABLE lims.ref_core_organization RENAME CONSTRAINT ref_organization_pkey TO ref_core_organization_pkey;
ALTER TABLE lims.ref_core_branch RENAME CONSTRAINT ref_branch_pkey TO ref_core_branch_pkey;
ALTER TABLE lims.ref_bil_service RENAME CONSTRAINT ref_service_pkey TO ref_bil_service_pkey;
ALTER TABLE lims.ref_core_clinical_code RENAME CONSTRAINT ref_clinical_code_pkey TO ref_core_clinical_code_pkey;
ALTER TABLE lims.ref_pat_patient RENAME CONSTRAINT ref_patient_pkey TO ref_pat_patient_pkey;
ALTER TABLE lims.ref_ord_clinical_order RENAME CONSTRAINT ref_clinical_order_pkey TO ref_ord_clinical_order_pkey;
ALTER TABLE lims.ref_hr_employee RENAME CONSTRAINT ref_employee_pkey TO ref_hr_employee_pkey;
ALTER TABLE lims.ref_ord_order_item RENAME CONSTRAINT ref_order_item_pkey TO ref_ord_order_item_pkey;
ALTER TABLE lims.ref_pha_generic RENAME CONSTRAINT ref_generic_pkey TO ref_pha_generic_pkey;
ALTER TABLE lims.ref_rpt_report_letterhead RENAME CONSTRAINT ref_report_letterhead_pkey TO ref_rpt_report_letterhead_pkey;
ALTER TABLE lims.ref_hr_practitioner RENAME CONSTRAINT ref_practitioner_pkey TO ref_hr_practitioner_pkey;
ALTER TABLE lims.ref_inv_item RENAME CONSTRAINT ref_item_pkey TO ref_inv_item_pkey;
ALTER TABLE lims.ref_inv_vendor RENAME CONSTRAINT ref_vendor_pkey TO ref_inv_vendor_pkey;
ALTER TABLE lims.ref_pat_encounter RENAME CONSTRAINT ref_encounter_pkey TO ref_pat_encounter_pkey;
ALTER TABLE lims.ref_fld_trip RENAME CONSTRAINT ref_transport_trip_pkey TO ref_fld_trip_pkey;
ALTER TABLE rims.ref_core_organization RENAME CONSTRAINT ref_organization_pkey TO ref_core_organization_pkey;
ALTER TABLE rims.ref_core_branch RENAME CONSTRAINT ref_branch_pkey TO ref_core_branch_pkey;
ALTER TABLE rims.ref_bil_service RENAME CONSTRAINT ref_service_pkey TO ref_bil_service_pkey;
ALTER TABLE rims.ref_pat_patient RENAME CONSTRAINT ref_patient_pkey TO ref_pat_patient_pkey;
ALTER TABLE rims.ref_hr_employee RENAME CONSTRAINT ref_employee_pkey TO ref_hr_employee_pkey;
ALTER TABLE rims.ref_ord_order_item RENAME CONSTRAINT ref_order_item_pkey TO ref_ord_order_item_pkey;
ALTER TABLE rims.ref_rpt_report_letterhead RENAME CONSTRAINT ref_report_letterhead_pkey TO ref_rpt_report_letterhead_pkey;
ALTER TABLE rims.ref_hr_practitioner RENAME CONSTRAINT ref_practitioner_pkey TO ref_hr_practitioner_pkey;
ALTER TABLE rims.ref_inv_item RENAME CONSTRAINT ref_item_pkey TO ref_inv_item_pkey;
ALTER TABLE rims.ref_adt_room RENAME CONSTRAINT ref_room_pkey TO ref_adt_room_pkey;
ALTER TABLE rims.ref_sch_slot RENAME CONSTRAINT ref_slot_pkey TO ref_sch_slot_pkey;
ALTER TABLE rims.ref_sch_appointment RENAME CONSTRAINT ref_appointment_pkey TO ref_sch_appointment_pkey;
ALTER TABLE revenuefinance.mst_bil_service_category RENAME CONSTRAINT mst_service_category_pkey TO mst_bil_service_category_pkey;
ALTER TABLE revenuefinance.mst_bil_service_category RENAME CONSTRAINT mst_service_category_category_code_key TO mst_bil_service_category_category_code_key;
ALTER TABLE revenuefinance.mst_bil_service_category RENAME CONSTRAINT mst_service_category_parent_category_id_fkey TO mst_bil_service_category_parent_category_id_fkey;
ALTER TABLE revenuefinance.mst_bil_service RENAME CONSTRAINT mst_service_pkey TO mst_bil_service_pkey;
ALTER TABLE revenuefinance.mst_bil_service RENAME CONSTRAINT mst_service_service_category_id_fkey TO mst_bil_service_service_category_id_fkey;
ALTER TABLE revenuefinance.mst_bil_payer RENAME CONSTRAINT mst_payer_pkey TO mst_bil_payer_pkey;
ALTER TABLE revenuefinance.mst_bil_payer RENAME CONSTRAINT mst_payer_parent_payer_id_fkey TO mst_bil_payer_parent_payer_id_fkey;
ALTER TABLE revenuefinance.mst_bil_tariff_plan RENAME CONSTRAINT mst_tariff_plan_pkey TO mst_bil_tariff_plan_pkey;
ALTER TABLE revenuefinance.mst_bil_tariff_plan RENAME CONSTRAINT mst_tariff_plan_payer_id_fkey TO mst_bil_tariff_plan_payer_id_fkey;
ALTER TABLE revenuefinance.mst_bil_tariff_rate RENAME CONSTRAINT mst_tariff_rate_pkey TO mst_bil_tariff_rate_pkey;
ALTER TABLE revenuefinance.mst_bil_tariff_rate RENAME CONSTRAINT mst_tariff_rate_tariff_plan_id_fkey TO mst_bil_tariff_rate_tariff_plan_id_fkey;
ALTER TABLE revenuefinance.mst_bil_tariff_rate RENAME CONSTRAINT mst_tariff_rate_service_id_fkey TO mst_bil_tariff_rate_service_id_fkey;
ALTER TABLE revenuefinance.mst_bil_package RENAME CONSTRAINT mst_package_pkey TO mst_bil_package_pkey;
ALTER TABLE revenuefinance.mst_bil_package RENAME CONSTRAINT mst_package_service_id_key TO mst_bil_package_service_id_key;
ALTER TABLE revenuefinance.mst_bil_package RENAME CONSTRAINT mst_package_service_id_fkey TO mst_bil_package_service_id_fkey;
ALTER TABLE revenuefinance.mst_bil_package_item RENAME CONSTRAINT mst_package_item_pkey TO mst_bil_package_item_pkey;
ALTER TABLE revenuefinance.mst_bil_package_item RENAME CONSTRAINT mst_package_item_package_id_fkey TO mst_bil_package_item_package_id_fkey;
ALTER TABLE revenuefinance.mst_bil_package_item RENAME CONSTRAINT mst_package_item_service_id_fkey TO mst_bil_package_item_service_id_fkey;
ALTER TABLE revenuefinance.mst_bil_discount_scheme RENAME CONSTRAINT mst_discount_scheme_pkey TO mst_bil_discount_scheme_pkey;
ALTER TABLE revenuefinance.mst_bil_discount_scheme RENAME CONSTRAINT mst_discount_scheme_service_category_id_fkey TO mst_bil_discount_scheme_service_category_id_fkey;
ALTER TABLE revenuefinance.mst_bil_coupon RENAME CONSTRAINT mst_coupon_pkey TO mst_bil_coupon_pkey;
ALTER TABLE revenuefinance.mst_bil_coupon RENAME CONSTRAINT mst_coupon_coupon_code_key TO mst_bil_coupon_coupon_code_key;
ALTER TABLE revenuefinance.mst_bil_coupon RENAME CONSTRAINT mst_coupon_discount_scheme_id_fkey TO mst_bil_coupon_discount_scheme_id_fkey;
ALTER TABLE revenuefinance.ref_core_organization RENAME CONSTRAINT ref_organization_pkey TO ref_core_organization_pkey;
ALTER TABLE revenuefinance.ref_core_branch RENAME CONSTRAINT ref_branch_pkey TO ref_core_branch_pkey;
ALTER TABLE revenuefinance.ref_core_department RENAME CONSTRAINT ref_department_pkey TO ref_core_department_pkey;
ALTER TABLE revenuefinance.ref_core_clinical_code RENAME CONSTRAINT ref_clinical_code_pkey TO ref_core_clinical_code_pkey;
ALTER TABLE revenuefinance.ref_inv_item_category RENAME CONSTRAINT ref_item_category_pkey TO ref_inv_item_category_pkey;
ALTER TABLE revenuefinance.ref_pat_patient RENAME CONSTRAINT ref_patient_pkey TO ref_pat_patient_pkey;
ALTER TABLE revenuefinance.ref_ot_procedure RENAME CONSTRAINT ref_procedure_pkey TO ref_ot_procedure_pkey;
ALTER TABLE revenuefinance.ref_pat_encounter RENAME CONSTRAINT ref_encounter_pkey TO ref_pat_encounter_pkey;
ALTER TABLE revenuefinance.ref_hr_employee RENAME CONSTRAINT ref_employee_pkey TO ref_hr_employee_pkey;
ALTER TABLE revenuefinance.ref_inv_item RENAME CONSTRAINT ref_item_pkey TO ref_inv_item_pkey;
ALTER TABLE revenuefinance.ref_inv_item_batch RENAME CONSTRAINT ref_item_batch_pkey TO ref_inv_item_batch_pkey;
ALTER TABLE revenuefinance.ref_ord_order_item RENAME CONSTRAINT ref_order_item_pkey TO ref_ord_order_item_pkey;
ALTER TABLE revenuefinance.ref_pha_dispense_item RENAME CONSTRAINT ref_dispense_item_pkey TO ref_pha_dispense_item_pkey;
ALTER TABLE revenuefinance.ref_adt_bed_allocation RENAME CONSTRAINT ref_bed_allocation_pkey TO ref_adt_bed_allocation_pkey;
ALTER TABLE revenuefinance.ref_hr_practitioner RENAME CONSTRAINT ref_practitioner_pkey TO ref_hr_practitioner_pkey;
ALTER TABLE revenuefinance.ref_pat_patient_payer RENAME CONSTRAINT ref_patient_payer_pkey TO ref_pat_patient_payer_pkey;
ALTER TABLE revenuefinance.ref_adm_asset RENAME CONSTRAINT ref_asset_pkey TO ref_adm_asset_pkey;
ALTER TABLE revenuefinance.ref_hr_shift RENAME CONSTRAINT ref_shift_pkey TO ref_hr_shift_pkey;
ALTER TABLE revenuefinance.ref_adt_ward RENAME CONSTRAINT ref_ward_pkey TO ref_adt_ward_pkey;
ALTER TABLE revenuefinance.ref_hr_designation RENAME CONSTRAINT ref_designation_pkey TO ref_hr_designation_pkey;
ALTER TABLE revenuefinance.ref_adt_room RENAME CONSTRAINT ref_room_pkey TO ref_adt_room_pkey;
ALTER TABLE revenuefinance.ref_fld_vehicle RENAME CONSTRAINT ref_vehicle_pkey TO ref_fld_vehicle_pkey;
ALTER TABLE revenuefinance.mst_bil_package_payer RENAME CONSTRAINT mst_package_payer_pkey TO mst_bil_package_payer_pkey;
ALTER TABLE revenuefinance.mst_bil_package_payer RENAME CONSTRAINT uq_mst_package_payer_1 TO uq_mst_bil_package_payer_1;
ALTER TABLE revenuefinance.mst_bil_kit RENAME CONSTRAINT mst_kit_pkey TO mst_bil_kit_pkey;
ALTER TABLE revenuefinance.mst_bil_kit RENAME CONSTRAINT mst_kit_kit_code_key TO mst_bil_kit_kit_code_key;
ALTER TABLE revenuefinance.mst_bil_kit_item RENAME CONSTRAINT mst_kit_item_pkey TO mst_bil_kit_item_pkey;
ALTER TABLE revenuefinance.mst_bil_loyalty_tier RENAME CONSTRAINT mst_loyalty_tier_pkey TO mst_bil_loyalty_tier_pkey;
ALTER TABLE revenuefinance.mst_bil_loyalty_tier RENAME CONSTRAINT mst_loyalty_tier_tier_code_key TO mst_bil_loyalty_tier_tier_code_key;
ALTER TABLE revenuefinance.mst_bil_loyalty_rule RENAME CONSTRAINT mst_loyalty_rule_pkey TO mst_bil_loyalty_rule_pkey;
ALTER TABLE revenuefinance.mst_bil_loyalty_rule RENAME CONSTRAINT mst_loyalty_rule_rule_code_key TO mst_bil_loyalty_rule_rule_code_key;
ALTER TABLE revenuefinance.mst_ins_insurance_plan RENAME CONSTRAINT mst_insurance_plan_pkey TO mst_ins_insurance_plan_pkey;
ALTER TABLE revenuefinance.mst_ins_insurance_plan RENAME CONSTRAINT uq_mst_insurance_plan_1 TO uq_mst_ins_insurance_plan_1;
ALTER TABLE revenuefinance.mst_ins_insurance_sublimit RENAME CONSTRAINT mst_insurance_sublimit_pkey TO mst_ins_insurance_sublimit_pkey;
ALTER TABLE revenuefinance.mst_ins_payer_network RENAME CONSTRAINT mst_payer_network_pkey TO mst_ins_payer_network_pkey;
ALTER TABLE revenuefinance.mst_ins_copay_rule RENAME CONSTRAINT mst_copay_rule_pkey TO mst_ins_copay_rule_pkey;
ALTER TABLE revenuefinance.mst_fin_hsn_sac RENAME CONSTRAINT mst_hsn_sac_pkey TO mst_fin_hsn_sac_pkey;
ALTER TABLE revenuefinance.mst_fin_hsn_sac RENAME CONSTRAINT uq_mst_hsn_sac_1 TO uq_mst_fin_hsn_sac_1;
ALTER TABLE revenuefinance.mst_bil_package_payer RENAME CONSTRAINT fk_mst_package_payer_package_id TO fk_mst_bil_package_payer_package_id;
ALTER TABLE revenuefinance.mst_bil_package_payer RENAME CONSTRAINT fk_mst_package_payer_payer_id TO fk_mst_bil_package_payer_payer_id;
ALTER TABLE revenuefinance.mst_bil_kit RENAME CONSTRAINT fk_mst_kit_service_id TO fk_mst_bil_kit_service_id;
ALTER TABLE revenuefinance.mst_bil_kit_item RENAME CONSTRAINT fk_mst_kit_item_kit_id TO fk_mst_bil_kit_item_kit_id;
ALTER TABLE revenuefinance.mst_bil_loyalty_rule RENAME CONSTRAINT fk_mst_loyalty_rule_service_category_id TO fk_mst_bil_loyalty_rule_service_category_id;
ALTER TABLE revenuefinance.mst_ins_insurance_plan RENAME CONSTRAINT fk_mst_insurance_plan_payer_id TO fk_mst_ins_insurance_plan_payer_id;
ALTER TABLE revenuefinance.mst_ins_insurance_plan RENAME CONSTRAINT fk_mst_insurance_plan_tariff_plan_id TO fk_mst_ins_insurance_plan_tariff_plan_id;
ALTER TABLE revenuefinance.mst_ins_insurance_sublimit RENAME CONSTRAINT fk_mst_insurance_sublimit_insurance_plan_id TO fk_mst_ins_insurance_sublimit_insurance_plan_id;
ALTER TABLE revenuefinance.mst_ins_insurance_sublimit RENAME CONSTRAINT fk_mst_insurance_sublimit_service_category_id TO fk_mst_ins_insurance_sublimit_service_category_id;
ALTER TABLE revenuefinance.mst_ins_payer_network RENAME CONSTRAINT fk_mst_payer_network_insurer_payer_id TO fk_mst_ins_payer_network_insurer_payer_id;
ALTER TABLE revenuefinance.mst_ins_payer_network RENAME CONSTRAINT fk_mst_payer_network_tpa_payer_id TO fk_mst_ins_payer_network_tpa_payer_id;
ALTER TABLE revenuefinance.mst_ins_copay_rule RENAME CONSTRAINT fk_mst_copay_rule_payer_id TO fk_mst_ins_copay_rule_payer_id;
ALTER TABLE revenuefinance.mst_ins_copay_rule RENAME CONSTRAINT fk_mst_copay_rule_insurance_plan_id TO fk_mst_ins_copay_rule_insurance_plan_id;
ALTER TABLE revenuefinance.mst_ins_copay_rule RENAME CONSTRAINT fk_mst_copay_rule_service_category_id TO fk_mst_ins_copay_rule_service_category_id;
ALTER TABLE revenuefinance.mst_bil_package RENAME CONSTRAINT fk_mst_package_copay_rule_id TO fk_mst_bil_package_copay_rule_id;
ALTER TABLE operationssupply.mst_inv_vendor RENAME CONSTRAINT mst_vendor_pkey TO mst_inv_vendor_pkey;
ALTER TABLE operationssupply.mst_inv_item_category RENAME CONSTRAINT mst_item_category_pkey TO mst_inv_item_category_pkey;
ALTER TABLE operationssupply.mst_inv_item_category RENAME CONSTRAINT mst_item_category_category_code_key TO mst_inv_item_category_category_code_key;
ALTER TABLE operationssupply.mst_inv_item_category RENAME CONSTRAINT mst_item_category_parent_category_id_fkey TO mst_inv_item_category_parent_category_id_fkey;
ALTER TABLE operationssupply.mst_inv_item RENAME CONSTRAINT mst_item_pkey TO mst_inv_item_pkey;
ALTER TABLE operationssupply.mst_inv_item RENAME CONSTRAINT mst_item_item_category_id_fkey TO mst_inv_item_item_category_id_fkey;
ALTER TABLE operationssupply.mst_inv_store RENAME CONSTRAINT mst_store_pkey TO mst_inv_store_pkey;
ALTER TABLE operationssupply.mst_inv_store RENAME CONSTRAINT mst_store_parent_store_id_fkey TO mst_inv_store_parent_store_id_fkey;
ALTER TABLE operationssupply.ref_core_organization RENAME CONSTRAINT ref_organization_pkey TO ref_core_organization_pkey;
ALTER TABLE operationssupply.ref_core_branch RENAME CONSTRAINT ref_branch_pkey TO ref_core_branch_pkey;
ALTER TABLE operationssupply.ref_core_department RENAME CONSTRAINT ref_department_pkey TO ref_core_department_pkey;
ALTER TABLE operationssupply.ref_hr_employee RENAME CONSTRAINT ref_employee_pkey TO ref_hr_employee_pkey;
ALTER TABLE operationssupply.ref_ot_booking RENAME CONSTRAINT ref_booking_pkey TO ref_ot_booking_pkey;
ALTER TABLE operationssupply.ref_pat_patient RENAME CONSTRAINT ref_patient_pkey TO ref_pat_patient_pkey;
ALTER TABLE operationssupply.ref_pat_encounter RENAME CONSTRAINT ref_encounter_pkey TO ref_pat_encounter_pkey;
ALTER TABLE operationssupply.ref_bil_service RENAME CONSTRAINT ref_service_pkey TO ref_bil_service_pkey;
ALTER TABLE operationssupply.ref_adt_admission RENAME CONSTRAINT ref_admission_pkey TO ref_adt_admission_pkey;
ALTER TABLE operationssupply.ref_diet_diet_plan RENAME CONSTRAINT ref_diet_plan_pkey TO ref_diet_diet_plan_pkey;
ALTER TABLE operationssupply.ref_adt_bed RENAME CONSTRAINT ref_bed_pkey TO ref_adt_bed_pkey;
ALTER TABLE operationssupply.ref_adt_room RENAME CONSTRAINT ref_room_pkey TO ref_adt_room_pkey;
ALTER TABLE operationssupply.ref_adt_ward RENAME CONSTRAINT ref_ward_pkey TO ref_adt_ward_pkey;
ALTER TABLE operationssupply.ref_ord_clinical_order RENAME CONSTRAINT ref_clinical_order_pkey TO ref_ord_clinical_order_pkey;
ALTER TABLE operationssupply.ref_sch_appointment RENAME CONSTRAINT ref_appointment_pkey TO ref_sch_appointment_pkey;
ALTER TABLE operationssupply.mst_inv_vendor_document RENAME CONSTRAINT mst_vendor_document_pkey TO mst_inv_vendor_document_pkey;
ALTER TABLE operationssupply.ref_fin_hsn_sac RENAME CONSTRAINT ref_hsn_sac_pkey TO ref_fin_hsn_sac_pkey;
ALTER TABLE operationssupply.ref_ecom_online_order RENAME CONSTRAINT ref_online_order_pkey TO ref_ecom_online_order_pkey;
ALTER TABLE operationssupply.mst_inv_vendor_document RENAME CONSTRAINT fk_mst_vendor_document_vendor_id TO fk_mst_inv_vendor_document_vendor_id;
ALTER TABLE integrationcomms.ref_pat_patient RENAME CONSTRAINT ref_patient_pkey TO ref_pat_patient_pkey;
ALTER TABLE integrationcomms.ref_pat_encounter RENAME CONSTRAINT ref_encounter_pkey TO ref_pat_encounter_pkey;
ALTER TABLE integrationcomms.mst_rpt_report_letterhead RENAME CONSTRAINT mst_report_letterhead_pkey TO mst_rpt_report_letterhead_pkey;
ALTER TABLE integrationcomms.ref_core_organization RENAME CONSTRAINT ref_organization_pkey TO ref_core_organization_pkey;
ALTER TABLE integrationcomms.ref_core_branch RENAME CONSTRAINT ref_branch_pkey TO ref_core_branch_pkey;
ALTER TABLE integrationcomms.ref_bil_payer RENAME CONSTRAINT ref_payer_pkey TO ref_bil_payer_pkey;
ALTER TABLE pharmacy.mst_pha_generic RENAME CONSTRAINT mst_generic_pkey TO mst_pha_generic_pkey;
ALTER TABLE pharmacy.mst_pha_generic RENAME CONSTRAINT mst_generic_generic_name_key TO mst_pha_generic_generic_name_key;
ALTER TABLE pharmacy.mst_pha_drug RENAME CONSTRAINT mst_drug_pkey TO mst_pha_drug_pkey;
ALTER TABLE pharmacy.mst_pha_drug RENAME CONSTRAINT mst_drug_item_id_key TO mst_pha_drug_item_id_key;
ALTER TABLE pharmacy.mst_pha_drug_generic RENAME CONSTRAINT mst_drug_generic_pkey TO mst_pha_drug_generic_pkey;
ALTER TABLE pharmacy.mst_pha_drug_generic RENAME CONSTRAINT mst_drug_generic_drug_id_fkey TO mst_pha_drug_generic_drug_id_fkey;
ALTER TABLE pharmacy.mst_pha_drug_generic RENAME CONSTRAINT mst_drug_generic_generic_id_fkey TO mst_pha_drug_generic_generic_id_fkey;
ALTER TABLE pharmacy.mst_pha_drug_substitute RENAME CONSTRAINT mst_drug_substitute_pkey TO mst_pha_drug_substitute_pkey;
ALTER TABLE pharmacy.mst_pha_drug_substitute RENAME CONSTRAINT mst_drug_substitute_drug_id_fkey TO mst_pha_drug_substitute_drug_id_fkey;
ALTER TABLE pharmacy.mst_pha_drug_substitute RENAME CONSTRAINT mst_drug_substitute_substitute_drug_id_fkey TO mst_pha_drug_substitute_substitute_drug_id_fkey;
ALTER TABLE pharmacy.mst_pha_drug_interaction RENAME CONSTRAINT mst_drug_interaction_pkey TO mst_pha_drug_interaction_pkey;
ALTER TABLE pharmacy.mst_pha_drug_interaction RENAME CONSTRAINT mst_drug_interaction_generic_id_a_fkey TO mst_pha_drug_interaction_generic_id_a_fkey;
ALTER TABLE pharmacy.mst_pha_drug_interaction RENAME CONSTRAINT mst_drug_interaction_generic_id_b_fkey TO mst_pha_drug_interaction_generic_id_b_fkey;
ALTER TABLE pharmacy.mst_pha_drug_contraindication RENAME CONSTRAINT mst_drug_contraindication_pkey TO mst_pha_drug_contraindication_pkey;
ALTER TABLE pharmacy.mst_pha_drug_contraindication RENAME CONSTRAINT mst_drug_contraindication_generic_id_fkey TO mst_pha_drug_contraindication_generic_id_fkey;
ALTER TABLE pharmacy.mst_pha_allergen RENAME CONSTRAINT mst_allergen_pkey TO mst_pha_allergen_pkey;
ALTER TABLE pharmacy.mst_pha_allergen RENAME CONSTRAINT mst_allergen_generic_id_fkey TO mst_pha_allergen_generic_id_fkey;
ALTER TABLE pharmacy.ref_core_organization RENAME CONSTRAINT ref_organization_pkey TO ref_core_organization_pkey;
ALTER TABLE pharmacy.ref_core_branch RENAME CONSTRAINT ref_branch_pkey TO ref_core_branch_pkey;
ALTER TABLE pharmacy.ref_core_clinical_code RENAME CONSTRAINT ref_clinical_code_pkey TO ref_core_clinical_code_pkey;
ALTER TABLE pharmacy.ref_hr_employee RENAME CONSTRAINT ref_employee_pkey TO ref_hr_employee_pkey;
ALTER TABLE pharmacy.ref_pat_patient RENAME CONSTRAINT ref_patient_pkey TO ref_pat_patient_pkey;
ALTER TABLE pharmacy.ref_pat_encounter RENAME CONSTRAINT ref_encounter_pkey TO ref_pat_encounter_pkey;
ALTER TABLE pharmacy.ref_ord_prescription RENAME CONSTRAINT ref_prescription_pkey TO ref_ord_prescription_pkey;
ALTER TABLE pharmacy.ref_ord_prescription_item RENAME CONSTRAINT ref_prescription_item_pkey TO ref_ord_prescription_item_pkey;
ALTER TABLE pharmacy.ref_hr_practitioner RENAME CONSTRAINT ref_practitioner_pkey TO ref_hr_practitioner_pkey;
ALTER TABLE pharmacy.mst_pha_drug_dose_range RENAME CONSTRAINT mst_drug_dose_range_pkey TO mst_pha_drug_dose_range_pkey;
ALTER TABLE pharmacy.mst_pha_drug_change_request RENAME CONSTRAINT mst_drug_change_request_pkey TO mst_pha_drug_change_request_pkey;
ALTER TABLE pharmacy.mst_pha_lasa_pair RENAME CONSTRAINT mst_lasa_pair_pkey TO mst_pha_lasa_pair_pkey;
ALTER TABLE pharmacy.ref_inv_item RENAME CONSTRAINT ref_item_pkey TO ref_inv_item_pkey;
ALTER TABLE pharmacy.ref_inv_item_batch RENAME CONSTRAINT ref_item_batch_pkey TO ref_inv_item_batch_pkey;
ALTER TABLE pharmacy.ref_inv_store RENAME CONSTRAINT ref_store_pkey TO ref_inv_store_pkey;
ALTER TABLE pharmacy.ref_inv_stock RENAME CONSTRAINT ref_stock_pkey TO ref_inv_stock_pkey;
ALTER TABLE pharmacy.ref_fin_hsn_sac RENAME CONSTRAINT ref_hsn_sac_pkey TO ref_fin_hsn_sac_pkey;
ALTER TABLE pharmacy.mst_pha_drug_dose_range RENAME CONSTRAINT fk_mst_drug_dose_range_generic_id TO fk_mst_pha_drug_dose_range_generic_id;
ALTER TABLE pharmacy.mst_pha_drug_change_request RENAME CONSTRAINT fk_mst_drug_change_request_drug_id TO fk_mst_pha_drug_change_request_drug_id;
ALTER TABLE pharmacy.mst_pha_lasa_pair RENAME CONSTRAINT fk_mst_lasa_pair_drug_id_a TO fk_mst_pha_lasa_pair_drug_id_a;
ALTER TABLE pharmacy.mst_pha_lasa_pair RENAME CONSTRAINT fk_mst_lasa_pair_drug_id_b TO fk_mst_pha_lasa_pair_drug_id_b;
ALTER TABLE pharmacy.mst_pha_drug RENAME CONSTRAINT fk_mst_drug_merged_into_drug_id TO fk_mst_pha_drug_merged_into_drug_id;

-- ============ index names (indexes behind PK / UNIQUE were renamed with their constraint) ============
ALTER INDEX IF EXISTS identityorg.mst_department_pkey RENAME TO mst_core_department_pkey;
ALTER INDEX IF EXISTS identityorg.mst_branch_department_pkey RENAME TO mst_core_branch_department_pkey;
ALTER INDEX IF EXISTS identityorg.mst_specialty_pkey RENAME TO mst_hr_specialty_pkey;
ALTER INDEX IF EXISTS identityorg.mst_specialty_specialty_code_key RENAME TO mst_hr_specialty_specialty_code_key;
ALTER INDEX IF EXISTS identityorg.mst_designation_pkey RENAME TO mst_hr_designation_pkey;
ALTER INDEX IF EXISTS identityorg.mst_designation_designation_code_key RENAME TO mst_hr_designation_designation_code_key;
ALTER INDEX IF EXISTS identityorg.mst_shift_pkey RENAME TO mst_hr_shift_pkey;
ALTER INDEX IF EXISTS identityorg.ref_patient_pkey RENAME TO ref_pat_patient_pkey;
ALTER INDEX IF EXISTS identityorg.ref_payer_pkey RENAME TO ref_bil_payer_pkey;
ALTER INDEX IF EXISTS identityorg.ix_mst_specialty_sub_specialty_of_id RENAME TO ix_mst_hr_specialty_sub_specialty_of_id;
ALTER INDEX IF EXISTS patientengagement.mst_building_pkey RENAME TO mst_adt_building_pkey;
ALTER INDEX IF EXISTS patientengagement.mst_floor_pkey RENAME TO mst_adt_floor_pkey;
ALTER INDEX IF EXISTS patientengagement.mst_ward_pkey RENAME TO mst_adt_ward_pkey;
ALTER INDEX IF EXISTS patientengagement.mst_room_pkey RENAME TO mst_adt_room_pkey;
ALTER INDEX IF EXISTS patientengagement.mst_bed_pkey RENAME TO mst_adt_bed_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_organization_pkey RENAME TO ref_core_organization_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_branch_pkey RENAME TO ref_core_branch_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_department_pkey RENAME TO ref_core_department_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_payer_pkey RENAME TO ref_bil_payer_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_specialty_pkey RENAME TO ref_hr_specialty_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_practitioner_pkey RENAME TO ref_hr_practitioner_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_tariff_plan_pkey RENAME TO ref_bil_tariff_plan_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_employee_pkey RENAME TO ref_hr_employee_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_service_pkey RENAME TO ref_bil_service_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_patient_balance_pkey RENAME TO ref_bil_patient_balance_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_bill_pkey RENAME TO ref_bil_bill_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_item_pkey RENAME TO ref_inv_item_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_order_item_pkey RENAME TO ref_ord_order_item_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_dicom_study_pkey RENAME TO ref_pacs_dicom_study_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_estimate_pkey RENAME TO ref_bil_estimate_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_discount_scheme_pkey RENAME TO ref_bil_discount_scheme_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_complaint_pkey RENAME TO ref_adm_complaint_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_coupon_pkey RENAME TO ref_bil_coupon_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_payment_gateway_txn_pkey RENAME TO ref_bil_payment_gateway_txn_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_clinical_order_pkey RENAME TO ref_ord_clinical_order_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_service_request_pkey RENAME TO ref_fld_service_request_pkey;
ALTER INDEX IF EXISTS patientengagement.ref_capacity_agent_pkey RENAME TO ref_fld_agent_pkey;
ALTER INDEX IF EXISTS clinicalcare.mst_procedure_pkey RENAME TO mst_ot_procedure_pkey;
ALTER INDEX IF EXISTS clinicalcare.mst_procedure_service_id_key RENAME TO mst_ot_procedure_service_id_key;
ALTER INDEX IF EXISTS clinicalcare.mst_clinical_template_pkey RENAME TO mst_emr_clinical_template_pkey;
ALTER INDEX IF EXISTS clinicalcare.mst_order_set_pkey RENAME TO mst_ord_order_set_pkey;
ALTER INDEX IF EXISTS clinicalcare.mst_order_set_item_pkey RENAME TO mst_ord_order_set_item_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_specialty_pkey RENAME TO ref_hr_specialty_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_organization_pkey RENAME TO ref_core_organization_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_branch_pkey RENAME TO ref_core_branch_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_floor_pkey RENAME TO ref_adt_floor_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_service_pkey RENAME TO ref_bil_service_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_clinical_code_pkey RENAME TO ref_core_clinical_code_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_drug_pkey RENAME TO ref_pha_drug_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_patient_pkey RENAME TO ref_pat_patient_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_encounter_pkey RENAME TO ref_pat_encounter_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_practitioner_pkey RENAME TO ref_hr_practitioner_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_employee_pkey RENAME TO ref_hr_employee_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_allergen_pkey RENAME TO ref_pha_allergen_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_item_pkey RENAME TO ref_inv_item_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_payer_pkey RENAME TO ref_bil_payer_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_department_pkey RENAME TO ref_core_department_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_generic_pkey RENAME TO ref_pha_generic_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_admission_pkey RENAME TO ref_adt_admission_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_ward_pkey RENAME TO ref_adt_ward_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_shift_pkey RENAME TO ref_hr_shift_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_bed_pkey RENAME TO ref_adt_bed_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_micro_culture_pkey RENAME TO ref_lab_micro_culture_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_unit_issue_pkey RENAME TO ref_bb_unit_issue_pkey;
ALTER INDEX IF EXISTS clinicalcare.ref_medication_dispensed_pkey RENAME TO ref_pha_medication_dispensed_pkey;
ALTER INDEX IF EXISTS clinicalcare.mst_immunization_schedule_pkey RENAME TO mst_emr_immunization_schedule_pkey;
ALTER INDEX IF EXISTS clinicalcare.mst_template_assignment_pkey RENAME TO mst_emr_template_assignment_pkey;
ALTER INDEX IF EXISTS clinicalcare.mst_external_therapy_pkey RENAME TO mst_emr_external_therapy_pkey;
ALTER INDEX IF EXISTS clinicalcare.mst_external_therapy_therapy_code_key RENAME TO mst_emr_external_therapy_therapy_code_key;
ALTER INDEX IF EXISTS clinicalcare.mst_yoga_protocol_pkey RENAME TO mst_emr_yoga_protocol_pkey;
ALTER INDEX IF EXISTS clinicalcare.mst_yoga_protocol_protocol_code_key RENAME TO mst_emr_yoga_protocol_protocol_code_key;
ALTER INDEX IF EXISTS clinicalcare.ref_code_system_release_pkey RENAME TO ref_core_code_system_release_pkey;
ALTER INDEX IF EXISTS clinicalcare.ix_mst_template_assignment_clinical_template_id RENAME TO ix_mst_emr_template_assignment_clinical_template_id;
ALTER INDEX IF EXISTS lims.ref_organization_pkey RENAME TO ref_core_organization_pkey;
ALTER INDEX IF EXISTS lims.ref_branch_pkey RENAME TO ref_core_branch_pkey;
ALTER INDEX IF EXISTS lims.ref_service_pkey RENAME TO ref_bil_service_pkey;
ALTER INDEX IF EXISTS lims.ref_clinical_code_pkey RENAME TO ref_core_clinical_code_pkey;
ALTER INDEX IF EXISTS lims.ref_patient_pkey RENAME TO ref_pat_patient_pkey;
ALTER INDEX IF EXISTS lims.ref_clinical_order_pkey RENAME TO ref_ord_clinical_order_pkey;
ALTER INDEX IF EXISTS lims.ref_employee_pkey RENAME TO ref_hr_employee_pkey;
ALTER INDEX IF EXISTS lims.ref_order_item_pkey RENAME TO ref_ord_order_item_pkey;
ALTER INDEX IF EXISTS lims.ref_generic_pkey RENAME TO ref_pha_generic_pkey;
ALTER INDEX IF EXISTS lims.ref_report_letterhead_pkey RENAME TO ref_rpt_report_letterhead_pkey;
ALTER INDEX IF EXISTS lims.ref_practitioner_pkey RENAME TO ref_hr_practitioner_pkey;
ALTER INDEX IF EXISTS lims.ref_item_pkey RENAME TO ref_inv_item_pkey;
ALTER INDEX IF EXISTS lims.ref_vendor_pkey RENAME TO ref_inv_vendor_pkey;
ALTER INDEX IF EXISTS lims.ref_encounter_pkey RENAME TO ref_pat_encounter_pkey;
ALTER INDEX IF EXISTS lims.ref_transport_trip_pkey RENAME TO ref_fld_trip_pkey;
ALTER INDEX IF EXISTS rims.ref_organization_pkey RENAME TO ref_core_organization_pkey;
ALTER INDEX IF EXISTS rims.ref_branch_pkey RENAME TO ref_core_branch_pkey;
ALTER INDEX IF EXISTS rims.ref_service_pkey RENAME TO ref_bil_service_pkey;
ALTER INDEX IF EXISTS rims.ref_patient_pkey RENAME TO ref_pat_patient_pkey;
ALTER INDEX IF EXISTS rims.ref_employee_pkey RENAME TO ref_hr_employee_pkey;
ALTER INDEX IF EXISTS rims.ref_order_item_pkey RENAME TO ref_ord_order_item_pkey;
ALTER INDEX IF EXISTS rims.ref_report_letterhead_pkey RENAME TO ref_rpt_report_letterhead_pkey;
ALTER INDEX IF EXISTS rims.ref_practitioner_pkey RENAME TO ref_hr_practitioner_pkey;
ALTER INDEX IF EXISTS rims.ref_item_pkey RENAME TO ref_inv_item_pkey;
ALTER INDEX IF EXISTS rims.ref_room_pkey RENAME TO ref_adt_room_pkey;
ALTER INDEX IF EXISTS rims.ref_slot_pkey RENAME TO ref_sch_slot_pkey;
ALTER INDEX IF EXISTS rims.ref_appointment_pkey RENAME TO ref_sch_appointment_pkey;
ALTER INDEX IF EXISTS revenuefinance.mst_service_category_pkey RENAME TO mst_bil_service_category_pkey;
ALTER INDEX IF EXISTS revenuefinance.mst_service_category_category_code_key RENAME TO mst_bil_service_category_category_code_key;
ALTER INDEX IF EXISTS revenuefinance.mst_service_pkey RENAME TO mst_bil_service_pkey;
ALTER INDEX IF EXISTS revenuefinance.mst_payer_pkey RENAME TO mst_bil_payer_pkey;
ALTER INDEX IF EXISTS revenuefinance.mst_tariff_plan_pkey RENAME TO mst_bil_tariff_plan_pkey;
ALTER INDEX IF EXISTS revenuefinance.mst_tariff_rate_pkey RENAME TO mst_bil_tariff_rate_pkey;
ALTER INDEX IF EXISTS revenuefinance.mst_package_pkey RENAME TO mst_bil_package_pkey;
ALTER INDEX IF EXISTS revenuefinance.mst_package_service_id_key RENAME TO mst_bil_package_service_id_key;
ALTER INDEX IF EXISTS revenuefinance.mst_package_item_pkey RENAME TO mst_bil_package_item_pkey;
ALTER INDEX IF EXISTS revenuefinance.mst_coupon_coupon_code_key RENAME TO mst_bil_coupon_coupon_code_key;
ALTER INDEX IF EXISTS revenuefinance.mst_discount_scheme_pkey RENAME TO mst_bil_discount_scheme_pkey;
ALTER INDEX IF EXISTS revenuefinance.mst_coupon_pkey RENAME TO mst_bil_coupon_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_organization_pkey RENAME TO ref_core_organization_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_branch_pkey RENAME TO ref_core_branch_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_department_pkey RENAME TO ref_core_department_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_clinical_code_pkey RENAME TO ref_core_clinical_code_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_item_category_pkey RENAME TO ref_inv_item_category_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_patient_pkey RENAME TO ref_pat_patient_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_procedure_pkey RENAME TO ref_ot_procedure_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_encounter_pkey RENAME TO ref_pat_encounter_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_employee_pkey RENAME TO ref_hr_employee_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_item_pkey RENAME TO ref_inv_item_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_item_batch_pkey RENAME TO ref_inv_item_batch_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_order_item_pkey RENAME TO ref_ord_order_item_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_dispense_item_pkey RENAME TO ref_pha_dispense_item_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_bed_allocation_pkey RENAME TO ref_adt_bed_allocation_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_practitioner_pkey RENAME TO ref_hr_practitioner_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_patient_payer_pkey RENAME TO ref_pat_patient_payer_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_asset_pkey RENAME TO ref_adm_asset_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_shift_pkey RENAME TO ref_hr_shift_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_ward_pkey RENAME TO ref_adt_ward_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_designation_pkey RENAME TO ref_hr_designation_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_room_pkey RENAME TO ref_adt_room_pkey;
ALTER INDEX IF EXISTS revenuefinance.ref_vehicle_pkey RENAME TO ref_fld_vehicle_pkey;
ALTER INDEX IF EXISTS revenuefinance.mst_package_payer_pkey RENAME TO mst_bil_package_payer_pkey;
ALTER INDEX IF EXISTS revenuefinance.uq_mst_package_payer_1 RENAME TO uq_mst_bil_package_payer_1;
ALTER INDEX IF EXISTS revenuefinance.mst_kit_pkey RENAME TO mst_bil_kit_pkey;
ALTER INDEX IF EXISTS revenuefinance.mst_kit_kit_code_key RENAME TO mst_bil_kit_kit_code_key;
ALTER INDEX IF EXISTS revenuefinance.mst_kit_item_pkey RENAME TO mst_bil_kit_item_pkey;
ALTER INDEX IF EXISTS revenuefinance.mst_loyalty_tier_pkey RENAME TO mst_bil_loyalty_tier_pkey;
ALTER INDEX IF EXISTS revenuefinance.mst_loyalty_tier_tier_code_key RENAME TO mst_bil_loyalty_tier_tier_code_key;
ALTER INDEX IF EXISTS revenuefinance.mst_loyalty_rule_pkey RENAME TO mst_bil_loyalty_rule_pkey;
ALTER INDEX IF EXISTS revenuefinance.mst_loyalty_rule_rule_code_key RENAME TO mst_bil_loyalty_rule_rule_code_key;
ALTER INDEX IF EXISTS revenuefinance.mst_insurance_plan_pkey RENAME TO mst_ins_insurance_plan_pkey;
ALTER INDEX IF EXISTS revenuefinance.uq_mst_insurance_plan_1 RENAME TO uq_mst_ins_insurance_plan_1;
ALTER INDEX IF EXISTS revenuefinance.mst_insurance_sublimit_pkey RENAME TO mst_ins_insurance_sublimit_pkey;
ALTER INDEX IF EXISTS revenuefinance.mst_payer_network_pkey RENAME TO mst_ins_payer_network_pkey;
ALTER INDEX IF EXISTS revenuefinance.mst_copay_rule_pkey RENAME TO mst_ins_copay_rule_pkey;
ALTER INDEX IF EXISTS revenuefinance.mst_hsn_sac_pkey RENAME TO mst_fin_hsn_sac_pkey;
ALTER INDEX IF EXISTS revenuefinance.uq_mst_hsn_sac_1 RENAME TO uq_mst_fin_hsn_sac_1;
ALTER INDEX IF EXISTS revenuefinance.ix_mst_package_copay_rule_id RENAME TO ix_mst_bil_package_copay_rule_id;
ALTER INDEX IF EXISTS revenuefinance.ix_mst_package_payer_payer_id RENAME TO ix_mst_bil_package_payer_payer_id;
ALTER INDEX IF EXISTS revenuefinance.ix_mst_kit_service_id RENAME TO ix_mst_bil_kit_service_id;
ALTER INDEX IF EXISTS revenuefinance.ix_mst_kit_item_kit_id RENAME TO ix_mst_bil_kit_item_kit_id;
ALTER INDEX IF EXISTS revenuefinance.ix_mst_loyalty_rule_service_category_id RENAME TO ix_mst_bil_loyalty_rule_service_category_id;
ALTER INDEX IF EXISTS revenuefinance.ix_mst_insurance_plan_tariff_plan_id RENAME TO ix_mst_ins_insurance_plan_tariff_plan_id;
ALTER INDEX IF EXISTS revenuefinance.ix_mst_insurance_sublimit_insurance_plan_id RENAME TO ix_mst_ins_insurance_sublimit_insurance_plan_id;
ALTER INDEX IF EXISTS revenuefinance.ix_mst_insurance_sublimit_service_category_id RENAME TO ix_mst_ins_insurance_sublimit_service_category_id;
ALTER INDEX IF EXISTS revenuefinance.ix_mst_payer_network_insurer_payer_id RENAME TO ix_mst_ins_payer_network_insurer_payer_id;
ALTER INDEX IF EXISTS revenuefinance.ix_mst_payer_network_tpa_payer_id RENAME TO ix_mst_ins_payer_network_tpa_payer_id;
ALTER INDEX IF EXISTS revenuefinance.ix_mst_copay_rule_payer_id RENAME TO ix_mst_ins_copay_rule_payer_id;
ALTER INDEX IF EXISTS revenuefinance.ix_mst_copay_rule_insurance_plan_id RENAME TO ix_mst_ins_copay_rule_insurance_plan_id;
ALTER INDEX IF EXISTS revenuefinance.ix_mst_copay_rule_service_category_id RENAME TO ix_mst_ins_copay_rule_service_category_id;
ALTER INDEX IF EXISTS operationssupply.mst_vendor_pkey RENAME TO mst_inv_vendor_pkey;
ALTER INDEX IF EXISTS operationssupply.mst_item_category_pkey RENAME TO mst_inv_item_category_pkey;
ALTER INDEX IF EXISTS operationssupply.mst_item_category_category_code_key RENAME TO mst_inv_item_category_category_code_key;
ALTER INDEX IF EXISTS operationssupply.mst_item_pkey RENAME TO mst_inv_item_pkey;
ALTER INDEX IF EXISTS operationssupply.mst_store_pkey RENAME TO mst_inv_store_pkey;
ALTER INDEX IF EXISTS operationssupply.ref_organization_pkey RENAME TO ref_core_organization_pkey;
ALTER INDEX IF EXISTS operationssupply.ref_branch_pkey RENAME TO ref_core_branch_pkey;
ALTER INDEX IF EXISTS operationssupply.ref_department_pkey RENAME TO ref_core_department_pkey;
ALTER INDEX IF EXISTS operationssupply.ref_employee_pkey RENAME TO ref_hr_employee_pkey;
ALTER INDEX IF EXISTS operationssupply.ref_booking_pkey RENAME TO ref_ot_booking_pkey;
ALTER INDEX IF EXISTS operationssupply.ref_patient_pkey RENAME TO ref_pat_patient_pkey;
ALTER INDEX IF EXISTS operationssupply.ref_encounter_pkey RENAME TO ref_pat_encounter_pkey;
ALTER INDEX IF EXISTS operationssupply.ref_service_pkey RENAME TO ref_bil_service_pkey;
ALTER INDEX IF EXISTS operationssupply.ref_admission_pkey RENAME TO ref_adt_admission_pkey;
ALTER INDEX IF EXISTS operationssupply.ref_diet_plan_pkey RENAME TO ref_diet_diet_plan_pkey;
ALTER INDEX IF EXISTS operationssupply.ref_bed_pkey RENAME TO ref_adt_bed_pkey;
ALTER INDEX IF EXISTS operationssupply.ref_room_pkey RENAME TO ref_adt_room_pkey;
ALTER INDEX IF EXISTS operationssupply.ref_ward_pkey RENAME TO ref_adt_ward_pkey;
ALTER INDEX IF EXISTS operationssupply.ref_clinical_order_pkey RENAME TO ref_ord_clinical_order_pkey;
ALTER INDEX IF EXISTS operationssupply.ref_appointment_pkey RENAME TO ref_sch_appointment_pkey;
ALTER INDEX IF EXISTS operationssupply.mst_vendor_document_pkey RENAME TO mst_inv_vendor_document_pkey;
ALTER INDEX IF EXISTS operationssupply.ref_hsn_sac_pkey RENAME TO ref_fin_hsn_sac_pkey;
ALTER INDEX IF EXISTS operationssupply.ref_online_order_pkey RENAME TO ref_ecom_online_order_pkey;
ALTER INDEX IF EXISTS operationssupply.ix_mst_vendor_document_vendor_id RENAME TO ix_mst_inv_vendor_document_vendor_id;
ALTER INDEX IF EXISTS integrationcomms.ref_patient_pkey RENAME TO ref_pat_patient_pkey;
ALTER INDEX IF EXISTS integrationcomms.ref_encounter_pkey RENAME TO ref_pat_encounter_pkey;
ALTER INDEX IF EXISTS integrationcomms.mst_report_letterhead_pkey RENAME TO mst_rpt_report_letterhead_pkey;
ALTER INDEX IF EXISTS integrationcomms.ref_organization_pkey RENAME TO ref_core_organization_pkey;
ALTER INDEX IF EXISTS integrationcomms.ref_branch_pkey RENAME TO ref_core_branch_pkey;
ALTER INDEX IF EXISTS integrationcomms.ref_payer_pkey RENAME TO ref_bil_payer_pkey;
ALTER INDEX IF EXISTS pharmacy.mst_generic_pkey RENAME TO mst_pha_generic_pkey;
ALTER INDEX IF EXISTS pharmacy.mst_generic_generic_name_key RENAME TO mst_pha_generic_generic_name_key;
ALTER INDEX IF EXISTS pharmacy.mst_drug_pkey RENAME TO mst_pha_drug_pkey;
ALTER INDEX IF EXISTS pharmacy.mst_drug_item_id_key RENAME TO mst_pha_drug_item_id_key;
ALTER INDEX IF EXISTS pharmacy.mst_drug_generic_pkey RENAME TO mst_pha_drug_generic_pkey;
ALTER INDEX IF EXISTS pharmacy.mst_drug_substitute_pkey RENAME TO mst_pha_drug_substitute_pkey;
ALTER INDEX IF EXISTS pharmacy.mst_drug_interaction_pkey RENAME TO mst_pha_drug_interaction_pkey;
ALTER INDEX IF EXISTS pharmacy.mst_drug_contraindication_pkey RENAME TO mst_pha_drug_contraindication_pkey;
ALTER INDEX IF EXISTS pharmacy.mst_allergen_pkey RENAME TO mst_pha_allergen_pkey;
ALTER INDEX IF EXISTS pharmacy.ref_organization_pkey RENAME TO ref_core_organization_pkey;
ALTER INDEX IF EXISTS pharmacy.ref_branch_pkey RENAME TO ref_core_branch_pkey;
ALTER INDEX IF EXISTS pharmacy.ref_clinical_code_pkey RENAME TO ref_core_clinical_code_pkey;
ALTER INDEX IF EXISTS pharmacy.ref_employee_pkey RENAME TO ref_hr_employee_pkey;
ALTER INDEX IF EXISTS pharmacy.ref_patient_pkey RENAME TO ref_pat_patient_pkey;
ALTER INDEX IF EXISTS pharmacy.ref_encounter_pkey RENAME TO ref_pat_encounter_pkey;
ALTER INDEX IF EXISTS pharmacy.ref_prescription_pkey RENAME TO ref_ord_prescription_pkey;
ALTER INDEX IF EXISTS pharmacy.ref_prescription_item_pkey RENAME TO ref_ord_prescription_item_pkey;
ALTER INDEX IF EXISTS pharmacy.ref_practitioner_pkey RENAME TO ref_hr_practitioner_pkey;
ALTER INDEX IF EXISTS pharmacy.mst_drug_dose_range_pkey RENAME TO mst_pha_drug_dose_range_pkey;
ALTER INDEX IF EXISTS pharmacy.mst_drug_change_request_pkey RENAME TO mst_pha_drug_change_request_pkey;
ALTER INDEX IF EXISTS pharmacy.mst_lasa_pair_pkey RENAME TO mst_pha_lasa_pair_pkey;
ALTER INDEX IF EXISTS pharmacy.ref_item_pkey RENAME TO ref_inv_item_pkey;
ALTER INDEX IF EXISTS pharmacy.ref_item_batch_pkey RENAME TO ref_inv_item_batch_pkey;
ALTER INDEX IF EXISTS pharmacy.ref_store_pkey RENAME TO ref_inv_store_pkey;
ALTER INDEX IF EXISTS pharmacy.ref_stock_pkey RENAME TO ref_inv_stock_pkey;
ALTER INDEX IF EXISTS pharmacy.ref_hsn_sac_pkey RENAME TO ref_fin_hsn_sac_pkey;
ALTER INDEX IF EXISTS pharmacy.ix_mst_drug_merged_into_drug_id RENAME TO ix_mst_pha_drug_merged_into_drug_id;
ALTER INDEX IF EXISTS pharmacy.ix_mst_drug_dose_range_generic_id RENAME TO ix_mst_pha_drug_dose_range_generic_id;
ALTER INDEX IF EXISTS pharmacy.ix_mst_drug_change_request_drug_id RENAME TO ix_mst_pha_drug_change_request_drug_id;
ALTER INDEX IF EXISTS pharmacy.ix_mst_lasa_pair_drug_id_a RENAME TO ix_mst_pha_lasa_pair_drug_id_a;
ALTER INDEX IF EXISTS pharmacy.ix_mst_lasa_pair_drug_id_b RENAME TO ix_mst_pha_lasa_pair_drug_id_b;

-- ============ identity sequences ============
ALTER SEQUENCE IF EXISTS identityorg.mst_department_department_id_seq RENAME TO mst_core_department_department_id_seq;
ALTER SEQUENCE IF EXISTS identityorg.mst_branch_department_branch_department_id_seq RENAME TO mst_core_branch_department_branch_department_id_seq;
ALTER SEQUENCE IF EXISTS identityorg.mst_specialty_specialty_id_seq RENAME TO mst_hr_specialty_specialty_id_seq;
ALTER SEQUENCE IF EXISTS identityorg.mst_designation_designation_id_seq RENAME TO mst_hr_designation_designation_id_seq;
ALTER SEQUENCE IF EXISTS identityorg.mst_shift_shift_id_seq RENAME TO mst_hr_shift_shift_id_seq;
ALTER SEQUENCE IF EXISTS patientengagement.mst_building_building_id_seq RENAME TO mst_adt_building_building_id_seq;
ALTER SEQUENCE IF EXISTS patientengagement.mst_floor_floor_id_seq RENAME TO mst_adt_floor_floor_id_seq;
ALTER SEQUENCE IF EXISTS patientengagement.mst_ward_ward_id_seq RENAME TO mst_adt_ward_ward_id_seq;
ALTER SEQUENCE IF EXISTS patientengagement.mst_room_room_id_seq RENAME TO mst_adt_room_room_id_seq;
ALTER SEQUENCE IF EXISTS patientengagement.mst_bed_bed_id_seq RENAME TO mst_adt_bed_bed_id_seq;
ALTER SEQUENCE IF EXISTS clinicalcare.mst_procedure_procedure_id_seq RENAME TO mst_ot_procedure_procedure_id_seq;
ALTER SEQUENCE IF EXISTS clinicalcare.mst_clinical_template_clinical_template_id_seq RENAME TO mst_emr_clinical_template_clinical_template_id_seq;
ALTER SEQUENCE IF EXISTS clinicalcare.mst_order_set_order_set_id_seq RENAME TO mst_ord_order_set_order_set_id_seq;
ALTER SEQUENCE IF EXISTS clinicalcare.mst_order_set_item_order_set_item_id_seq RENAME TO mst_ord_order_set_item_order_set_item_id_seq;
ALTER SEQUENCE IF EXISTS clinicalcare.mst_immunization_schedule_immunization_schedule_id_seq RENAME TO mst_emr_immunization_schedule_immunization_schedule_id_seq;
ALTER SEQUENCE IF EXISTS clinicalcare.mst_template_assignment_template_assignment_id_seq RENAME TO mst_emr_template_assignment_template_assignment_id_seq;
ALTER SEQUENCE IF EXISTS clinicalcare.mst_external_therapy_external_therapy_id_seq RENAME TO mst_emr_external_therapy_external_therapy_id_seq;
ALTER SEQUENCE IF EXISTS clinicalcare.mst_yoga_protocol_yoga_protocol_id_seq RENAME TO mst_emr_yoga_protocol_yoga_protocol_id_seq;
ALTER SEQUENCE IF EXISTS revenuefinance.mst_service_category_service_category_id_seq RENAME TO mst_bil_service_category_service_category_id_seq;
ALTER SEQUENCE IF EXISTS revenuefinance.mst_service_service_id_seq RENAME TO mst_bil_service_service_id_seq;
ALTER SEQUENCE IF EXISTS revenuefinance.mst_payer_payer_id_seq RENAME TO mst_bil_payer_payer_id_seq;
ALTER SEQUENCE IF EXISTS revenuefinance.mst_tariff_plan_tariff_plan_id_seq RENAME TO mst_bil_tariff_plan_tariff_plan_id_seq;
ALTER SEQUENCE IF EXISTS revenuefinance.mst_tariff_rate_tariff_rate_id_seq RENAME TO mst_bil_tariff_rate_tariff_rate_id_seq;
ALTER SEQUENCE IF EXISTS revenuefinance.mst_package_package_id_seq RENAME TO mst_bil_package_package_id_seq;
ALTER SEQUENCE IF EXISTS revenuefinance.mst_package_item_package_item_id_seq RENAME TO mst_bil_package_item_package_item_id_seq;
ALTER SEQUENCE IF EXISTS revenuefinance.mst_discount_scheme_discount_scheme_id_seq RENAME TO mst_bil_discount_scheme_discount_scheme_id_seq;
ALTER SEQUENCE IF EXISTS revenuefinance.mst_coupon_coupon_id_seq RENAME TO mst_bil_coupon_coupon_id_seq;
ALTER SEQUENCE IF EXISTS revenuefinance.mst_package_payer_package_payer_id_seq RENAME TO mst_bil_package_payer_package_payer_id_seq;
ALTER SEQUENCE IF EXISTS revenuefinance.mst_kit_kit_id_seq RENAME TO mst_bil_kit_kit_id_seq;
ALTER SEQUENCE IF EXISTS revenuefinance.mst_kit_item_kit_item_id_seq RENAME TO mst_bil_kit_item_kit_item_id_seq;
ALTER SEQUENCE IF EXISTS revenuefinance.mst_loyalty_tier_loyalty_tier_id_seq RENAME TO mst_bil_loyalty_tier_loyalty_tier_id_seq;
ALTER SEQUENCE IF EXISTS revenuefinance.mst_loyalty_rule_loyalty_rule_id_seq RENAME TO mst_bil_loyalty_rule_loyalty_rule_id_seq;
ALTER SEQUENCE IF EXISTS revenuefinance.mst_insurance_plan_insurance_plan_id_seq RENAME TO mst_ins_insurance_plan_insurance_plan_id_seq;
ALTER SEQUENCE IF EXISTS revenuefinance.mst_insurance_sublimit_insurance_sublimit_id_seq RENAME TO mst_ins_insurance_sublimit_insurance_sublimit_id_seq;
ALTER SEQUENCE IF EXISTS revenuefinance.mst_payer_network_payer_network_id_seq RENAME TO mst_ins_payer_network_payer_network_id_seq;
ALTER SEQUENCE IF EXISTS revenuefinance.mst_copay_rule_copay_rule_id_seq RENAME TO mst_ins_copay_rule_copay_rule_id_seq;
ALTER SEQUENCE IF EXISTS revenuefinance.mst_hsn_sac_hsn_sac_id_seq RENAME TO mst_fin_hsn_sac_hsn_sac_id_seq;
ALTER SEQUENCE IF EXISTS operationssupply.mst_vendor_vendor_id_seq RENAME TO mst_inv_vendor_vendor_id_seq;
ALTER SEQUENCE IF EXISTS operationssupply.mst_item_category_item_category_id_seq RENAME TO mst_inv_item_category_item_category_id_seq;
ALTER SEQUENCE IF EXISTS operationssupply.mst_item_item_id_seq RENAME TO mst_inv_item_item_id_seq;
ALTER SEQUENCE IF EXISTS operationssupply.mst_store_store_id_seq RENAME TO mst_inv_store_store_id_seq;
ALTER SEQUENCE IF EXISTS operationssupply.mst_vendor_document_vendor_document_id_seq RENAME TO mst_inv_vendor_document_vendor_document_id_seq;
ALTER SEQUENCE IF EXISTS integrationcomms.mst_report_letterhead_report_letterhead_id_seq RENAME TO mst_rpt_report_letterhead_report_letterhead_id_seq;
ALTER SEQUENCE IF EXISTS pharmacy.mst_generic_generic_id_seq RENAME TO mst_pha_generic_generic_id_seq;
ALTER SEQUENCE IF EXISTS pharmacy.mst_drug_drug_id_seq RENAME TO mst_pha_drug_drug_id_seq;
ALTER SEQUENCE IF EXISTS pharmacy.mst_drug_generic_drug_generic_id_seq RENAME TO mst_pha_drug_generic_drug_generic_id_seq;
ALTER SEQUENCE IF EXISTS pharmacy.mst_drug_substitute_drug_substitute_id_seq RENAME TO mst_pha_drug_substitute_drug_substitute_id_seq;
ALTER SEQUENCE IF EXISTS pharmacy.mst_drug_interaction_drug_interaction_id_seq RENAME TO mst_pha_drug_interaction_drug_interaction_id_seq;
ALTER SEQUENCE IF EXISTS pharmacy.mst_drug_contraindication_drug_contraindication_id_seq RENAME TO mst_pha_drug_contraindication_drug_contraindication_id_seq;
ALTER SEQUENCE IF EXISTS pharmacy.mst_allergen_allergen_id_seq RENAME TO mst_pha_allergen_allergen_id_seq;
ALTER SEQUENCE IF EXISTS pharmacy.mst_drug_dose_range_drug_dose_range_id_seq RENAME TO mst_pha_drug_dose_range_drug_dose_range_id_seq;
ALTER SEQUENCE IF EXISTS pharmacy.mst_drug_change_request_drug_change_request_id_seq RENAME TO mst_pha_drug_change_request_drug_change_request_id_seq;
ALTER SEQUENCE IF EXISTS pharmacy.mst_lasa_pair_lasa_pair_id_seq RENAME TO mst_pha_lasa_pair_lasa_pair_id_seq;

-- ============ 3. lims.mst_lab_test specimen / container -> lookup FKs ============
-- make sure every code in use exists in the lookups
INSERT INTO lims.mst_lab_specimen_type (organization_id, specimen_code, specimen_name)
SELECT COALESCE((SELECT min(organization_id) FROM lims.ref_core_organization), 1), t.specimen_type, initcap(t.specimen_type)
  FROM (SELECT DISTINCT specimen_type FROM lims.mst_lab_test WHERE specimen_type IS NOT NULL) t
 WHERE NOT EXISTS (SELECT 1 FROM lims.mst_lab_specimen_type s WHERE s.specimen_code = t.specimen_type);
INSERT INTO lims.mst_lab_container (organization_id, container_code, container_name)
SELECT COALESCE((SELECT min(organization_id) FROM lims.ref_core_organization), 1), t.container_type, initcap(t.container_type)
  FROM (SELECT DISTINCT container_type FROM lims.mst_lab_test WHERE container_type IS NOT NULL) t
 WHERE NOT EXISTS (SELECT 1 FROM lims.mst_lab_container c WHERE c.container_code = t.container_type);

-- specimen: fill the existing v4 specimen_type_id from the code, then drop the code column
UPDATE lims.mst_lab_test t SET specimen_type_id = s.lab_specimen_type_id
  FROM lims.mst_lab_specimen_type s WHERE t.specimen_type_id IS NULL AND s.specimen_code = t.specimen_type;
ALTER TABLE lims.mst_lab_test DROP COLUMN specimen_type;
ALTER TABLE lims.mst_lab_test ALTER COLUMN specimen_type_id SET NOT NULL;

-- container: the v4 container_id becomes container_type_id; fill it from the code, then drop the code column
ALTER TABLE lims.mst_lab_test RENAME COLUMN container_id TO container_type_id;
UPDATE lims.mst_lab_test t SET container_type_id = c.lab_container_id
  FROM lims.mst_lab_container c WHERE t.container_type_id IS NULL AND c.container_code = t.container_type;
ALTER TABLE lims.mst_lab_test DROP COLUMN container_type;
ALTER TABLE lims.mst_lab_test RENAME CONSTRAINT fk_mst_lab_test_container_id TO fk_mst_lab_test_container_type_id;
ALTER INDEX IF EXISTS lims.ix_mst_lab_test_container_id RENAME TO ix_mst_lab_test_container_type_id;
COMMENT ON COLUMN lims.mst_lab_test.specimen_type_id IS 'FK -> lims.mst_lab_specimen_type.lab_specimen_type_id [v5: was specimen_type VARCHAR]';
COMMENT ON COLUMN lims.mst_lab_test.container_type_id IS 'FK -> lims.mst_lab_container.lab_container_id [v5: was container_type VARCHAR]';

-- ============ 4. lims.mst_lab_section (new) and lab_section -> lab_section_id ============
CREATE TABLE lims.mst_lab_section (                                            -- [NEW v5] Lab sections (Haematology, Biochemistry, Microbiology ...)
    lab_section_id             INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    organization_id            INT NOT NULL,                                   -- logical FK -> identityorg.core_organization [Identity & Organization]
    section_code               VARCHAR(30) NOT NULL UNIQUE,                    -- HEMATOLOGY, BIOCHEMISTRY, ENDOCRINOLOGY, IMMUNOLOGY, TOXICOLOGY, SEROLOGY, MICROBIOLOGY, PATHOLOGY, HISTOPATHOLOGY, GENETICS, BONE_MARROW, BLOOD_BANK
    section_name               VARCHAR(100) NOT NULL,
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                 BIGINT NULL,
    updated_at                 TIMESTAMPTZ(3) NULL,
    updated_by                 BIGINT NULL,
    row_ver                    INTEGER NOT NULL DEFAULT 1
);

CREATE TRIGGER trg_row_ver BEFORE UPDATE ON lims.mst_lab_section FOR EACH ROW EXECUTE FUNCTION lims.util_touch_audit();
COMMENT ON TABLE lims.mst_lab_section IS 'Lab sections a test, analyzer or worklist belongs to [NEW v5] [FDS: LAB-CAT-002, LAB-WKL-001, LAB-INT-001, LAB-SEC-001..008]';
-- [v5] lab sections used by lims.mst_lab_test / lab_analyzer / lab_worklist.lab_section_id
INSERT INTO lims.mst_lab_section (organization_id, section_code, section_name) VALUES
  (COALESCE((SELECT min(organization_id) FROM lims.ref_core_organization), 1), 'HEMATOLOGY', 'Haematology'),
  (COALESCE((SELECT min(organization_id) FROM lims.ref_core_organization), 1), 'BIOCHEMISTRY', 'Biochemistry'),
  (COALESCE((SELECT min(organization_id) FROM lims.ref_core_organization), 1), 'ENDOCRINOLOGY', 'Endocrinology'),
  (COALESCE((SELECT min(organization_id) FROM lims.ref_core_organization), 1), 'IMMUNOLOGY', 'Immunology'),
  (COALESCE((SELECT min(organization_id) FROM lims.ref_core_organization), 1), 'TOXICOLOGY', 'Toxicology'),
  (COALESCE((SELECT min(organization_id) FROM lims.ref_core_organization), 1), 'SEROLOGY', 'Serology / Virology'),
  (COALESCE((SELECT min(organization_id) FROM lims.ref_core_organization), 1), 'MICROBIOLOGY', 'Microbiology'),
  (COALESCE((SELECT min(organization_id) FROM lims.ref_core_organization), 1), 'PATHOLOGY', 'Pathology'),
  (COALESCE((SELECT min(organization_id) FROM lims.ref_core_organization), 1), 'HISTOPATHOLOGY', 'Histopathology'),
  (COALESCE((SELECT min(organization_id) FROM lims.ref_core_organization), 1), 'GENETICS', 'Genetics'),
  (COALESCE((SELECT min(organization_id) FROM lims.ref_core_organization), 1), 'BONE_MARROW', 'Bone Marrow'),
  (COALESCE((SELECT min(organization_id) FROM lims.ref_core_organization), 1), 'BLOOD_BANK', 'Blood Bank')
ON CONFLICT (section_code) DO NOTHING;

-- any other code already in use becomes a section too
INSERT INTO lims.mst_lab_section (organization_id, section_code, section_name)
SELECT COALESCE((SELECT min(organization_id) FROM lims.ref_core_organization), 1), x.code, initcap(replace(x.code, '_', ' '))
  FROM (SELECT lab_section AS code FROM lims.mst_lab_test UNION SELECT lab_section FROM lims.lab_analyzer UNION SELECT lab_section FROM lims.lab_worklist) x
 WHERE x.code IS NOT NULL AND NOT EXISTS (SELECT 1 FROM lims.mst_lab_section s WHERE s.section_code = x.code);

ALTER TABLE lims.mst_lab_test ADD COLUMN lab_section_id INT NULL;
ALTER TABLE lims.lab_analyzer ADD COLUMN lab_section_id INT NULL;
ALTER TABLE lims.lab_worklist ADD COLUMN lab_section_id INT NULL;
UPDATE lims.mst_lab_test t SET lab_section_id = s.lab_section_id FROM lims.mst_lab_section s WHERE s.section_code = t.lab_section;
UPDATE lims.lab_analyzer t SET lab_section_id = s.lab_section_id FROM lims.mst_lab_section s WHERE s.section_code = t.lab_section;
UPDATE lims.lab_worklist t SET lab_section_id = s.lab_section_id FROM lims.mst_lab_section s WHERE s.section_code = t.lab_section;
ALTER TABLE lims.mst_lab_test DROP COLUMN lab_section;
ALTER TABLE lims.lab_analyzer DROP COLUMN lab_section;
ALTER TABLE lims.lab_worklist DROP COLUMN lab_section;
ALTER TABLE lims.mst_lab_test ALTER COLUMN lab_section_id SET NOT NULL;
ALTER TABLE lims.mst_lab_test ADD CONSTRAINT fk_mst_lab_test_lab_section_id FOREIGN KEY (lab_section_id) REFERENCES lims.mst_lab_section(lab_section_id);
CREATE INDEX IF NOT EXISTS ix_mst_lab_test_lab_section_id ON lims.mst_lab_test(lab_section_id);
ALTER TABLE lims.lab_analyzer ADD CONSTRAINT fk_lab_analyzer_lab_section_id FOREIGN KEY (lab_section_id) REFERENCES lims.mst_lab_section(lab_section_id);
CREATE INDEX IF NOT EXISTS ix_lab_analyzer_lab_section_id ON lims.lab_analyzer(lab_section_id);
ALTER TABLE lims.lab_worklist ADD CONSTRAINT fk_lab_worklist_lab_section_id FOREIGN KEY (lab_section_id) REFERENCES lims.mst_lab_section(lab_section_id);
CREATE INDEX IF NOT EXISTS ix_lab_worklist_lab_section_id ON lims.lab_worklist(lab_section_id);
COMMENT ON COLUMN lims.mst_lab_test.lab_section_id IS 'FK -> lims.mst_lab_section.lab_section_id [v5: was lab_section VARCHAR]';
COMMENT ON COLUMN lims.lab_analyzer.lab_section_id IS 'FK -> lims.mst_lab_section.lab_section_id [v5: was lab_section VARCHAR]';
COMMENT ON COLUMN lims.lab_worklist.lab_section_id IS 'FK -> lims.mst_lab_section.lab_section_id [v5: was lab_section VARCHAR]';


-- ============ 5. one database per tenant: organization_id removed ============
-- identityorg.core_organization (the tenant profile, one row) and the ref_core_organization replicas keep it.
DO $$ BEGIN
  IF (SELECT count(*) FROM identityorg.core_organization) > 1 THEN
    RAISE EXCEPTION 'This database holds % organizations; v5 expects one tenant per database (split the data first).', (SELECT count(*) FROM identityorg.core_organization);
  END IF;
END $$;

-- read-only ref_* views that expose organization_id: dropped here, recreated below
DROP VIEW operationssupply.ref_inv_grn;
DROP VIEW operationssupply.ref_inv_item;
DROP VIEW operationssupply.ref_inv_vendor;
DROP VIEW patientengagement.ref_pat_encounter;
DROP VIEW patientengagement.ref_sch_appointment;
DROP VIEW revenuefinance.ref_bil_receipt;

-- unique / foreign keys that include organization_id
ALTER TABLE identityorg.core_branch DROP CONSTRAINT core_branch_organization_id_fkey;
ALTER TABLE identityorg.core_clinical_code_synonym DROP CONSTRAINT core_clinical_code_synonym_organization_id_fkey;
ALTER TABLE identityorg.core_code_set_rule DROP CONSTRAINT core_code_set_rule_organization_id_fkey;
ALTER TABLE identityorg.core_code_system_release DROP CONSTRAINT core_code_system_release_organization_id_fkey;
ALTER TABLE identityorg.core_lookup_value DROP CONSTRAINT core_lookup_value_organization_id_fkey;
ALTER TABLE identityorg.hr_employee DROP CONSTRAINT hr_employee_organization_id_fkey;
ALTER TABLE identityorg.hr_practitioner DROP CONSTRAINT hr_practitioner_organization_id_fkey;
ALTER TABLE identityorg.mst_core_department DROP CONSTRAINT mst_core_department_organization_id_fkey;
ALTER TABLE identityorg.mst_hr_shift DROP CONSTRAINT mst_hr_shift_organization_id_fkey;
ALTER TABLE identityorg.sec_approval_matrix DROP CONSTRAINT sec_approval_matrix_organization_id_fkey;
ALTER TABLE identityorg.sec_break_glass_access DROP CONSTRAINT sec_break_glass_access_organization_id_fkey;
ALTER TABLE identityorg.sec_role DROP CONSTRAINT sec_role_organization_id_fkey;
ALTER TABLE identityorg.sec_user_account DROP CONSTRAINT sec_user_account_organization_id_fkey;
ALTER TABLE identityorg.sec_user_device DROP CONSTRAINT sec_user_device_organization_id_fkey;
ALTER TABLE identityorg.sec_user_store_access DROP CONSTRAINT sec_user_store_access_organization_id_fkey;
ALTER TABLE identityorg.core_lookup_value DROP CONSTRAINT uq_lookup_value;
ALTER TABLE identityorg.mst_core_department DROP CONSTRAINT uq_department;
ALTER TABLE identityorg.sec_role DROP CONSTRAINT uq_role;
ALTER TABLE integrationcomms.comm_template DROP CONSTRAINT uq_comm_template_1;
ALTER TABLE operationssupply.mst_inv_item DROP CONSTRAINT uq_item;
ALTER TABLE operationssupply.mst_inv_vendor DROP CONSTRAINT uq_vendor;
ALTER TABLE revenuefinance.fin_ledger_account DROP CONSTRAINT uq_ledger_account;
ALTER TABLE revenuefinance.mst_bil_payer DROP CONSTRAINT uq_payer;
ALTER TABLE revenuefinance.mst_bil_service DROP CONSTRAINT uq_service;

-- the column itself (416 tables)
ALTER TABLE clinicalcare.cds_medication_suggestion DROP COLUMN organization_id;
ALTER TABLE clinicalcare.cds_prescriber_preference DROP COLUMN organization_id;
ALTER TABLE clinicalcare.cds_rule DROP COLUMN organization_id;
ALTER TABLE clinicalcare.cod_coder_credential DROP COLUMN organization_id;
ALTER TABLE clinicalcare.cod_coder_query DROP COLUMN organization_id;
ALTER TABLE clinicalcare.cod_coding_audit DROP COLUMN organization_id;
ALTER TABLE clinicalcare.cod_coding_task DROP COLUMN organization_id;
ALTER TABLE clinicalcare.cod_coding_task_code DROP COLUMN organization_id;
ALTER TABLE clinicalcare.cod_drg_grouping DROP COLUMN organization_id;
ALTER TABLE clinicalcare.cod_trial_event DROP COLUMN organization_id;
ALTER TABLE clinicalcare.cod_trial_participant DROP COLUMN organization_id;
ALTER TABLE clinicalcare.core_number_sequence DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_care_plan_goal DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_clinical_document DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_dictation DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_document_signature DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_external_document DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_external_result DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_followup_request DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_medication_list DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_medication_reconciliation DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_observation DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_obstetric_history DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_pain_assessment DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_patient_clinical_flag DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_problem DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_problem_history DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_problem_link DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_quick_text DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_record_deficiency DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_release_of_information DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_result_acknowledgement DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_review_of_systems DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_social_history DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_timeline_event DROP COLUMN organization_id;
ALTER TABLE clinicalcare.emr_vital_set DROP COLUMN organization_id;
ALTER TABLE clinicalcare.er_code_event DROP COLUMN organization_id;
ALTER TABLE clinicalcare.er_mlc_case DROP COLUMN organization_id;
ALTER TABLE clinicalcare.er_triage DROP COLUMN organization_id;
ALTER TABLE clinicalcare.evt_outbox DROP COLUMN organization_id;
ALTER TABLE clinicalcare.icu_infection_event DROP COLUMN organization_id;
ALTER TABLE clinicalcare.mst_emr_clinical_template DROP COLUMN organization_id;
ALTER TABLE clinicalcare.mst_emr_external_therapy DROP COLUMN organization_id;
ALTER TABLE clinicalcare.mst_emr_immunization_schedule DROP COLUMN organization_id;
ALTER TABLE clinicalcare.mst_emr_template_assignment DROP COLUMN organization_id;
ALTER TABLE clinicalcare.mst_emr_yoga_protocol DROP COLUMN organization_id;
ALTER TABLE clinicalcare.mst_ord_order_set DROP COLUMN organization_id;
ALTER TABLE clinicalcare.mst_ot_theatre DROP COLUMN organization_id;
ALTER TABLE clinicalcare.nur_ward_task DROP COLUMN organization_id;
ALTER TABLE clinicalcare.ord_clinical_order DROP COLUMN organization_id;
ALTER TABLE clinicalcare.ord_order_status_history DROP COLUMN organization_id;
ALTER TABLE clinicalcare.ord_prescription DROP COLUMN organization_id;
ALTER TABLE clinicalcare.ot_booking DROP COLUMN organization_id;
ALTER TABLE clinicalcare.ref_adt_ward DROP COLUMN organization_id;
ALTER TABLE clinicalcare.ref_bil_payer DROP COLUMN organization_id;
ALTER TABLE clinicalcare.ref_bil_service DROP COLUMN organization_id;
ALTER TABLE clinicalcare.ref_core_branch DROP COLUMN organization_id;
ALTER TABLE clinicalcare.ref_core_code_system_release DROP COLUMN organization_id;
ALTER TABLE clinicalcare.ref_core_department DROP COLUMN organization_id;
ALTER TABLE clinicalcare.ref_hr_shift DROP COLUMN organization_id;
ALTER TABLE clinicalcare.ref_inv_item DROP COLUMN organization_id;
ALTER TABLE clinicalcare.ref_pat_encounter DROP COLUMN organization_id;
ALTER TABLE identityorg.core_branch DROP COLUMN organization_id;
ALTER TABLE identityorg.core_clinical_code_synonym DROP COLUMN organization_id;
ALTER TABLE identityorg.core_code_set_rule DROP COLUMN organization_id;
ALTER TABLE identityorg.core_code_system_release DROP COLUMN organization_id;
ALTER TABLE identityorg.core_lookup_value DROP COLUMN organization_id;
ALTER TABLE identityorg.evt_outbox DROP COLUMN organization_id;
ALTER TABLE identityorg.hr_employee DROP COLUMN organization_id;
ALTER TABLE identityorg.hr_practitioner DROP COLUMN organization_id;
ALTER TABLE identityorg.mst_core_department DROP COLUMN organization_id;
ALTER TABLE identityorg.mst_hr_shift DROP COLUMN organization_id;
ALTER TABLE identityorg.ref_bil_payer DROP COLUMN organization_id;
ALTER TABLE identityorg.sec_approval_matrix DROP COLUMN organization_id;
ALTER TABLE identityorg.sec_break_glass_access DROP COLUMN organization_id;
ALTER TABLE identityorg.sec_role DROP COLUMN organization_id;
ALTER TABLE identityorg.sec_user_account DROP COLUMN organization_id;
ALTER TABLE identityorg.sec_user_device DROP COLUMN organization_id;
ALTER TABLE identityorg.sec_user_store_access DROP COLUMN organization_id;
ALTER TABLE integrationcomms.comm_reminder_rule DROP COLUMN organization_id;
ALTER TABLE integrationcomms.comm_secure_link DROP COLUMN organization_id;
ALTER TABLE integrationcomms.comm_secure_link_access DROP COLUMN organization_id;
ALTER TABLE integrationcomms.comm_template DROP COLUMN organization_id;
ALTER TABLE integrationcomms.core_document DROP COLUMN organization_id;
ALTER TABLE integrationcomms.core_notification DROP COLUMN organization_id;
ALTER TABLE integrationcomms.evt_outbox DROP COLUMN organization_id;
ALTER TABLE integrationcomms.intg_abdm_consent_artefact DROP COLUMN organization_id;
ALTER TABLE integrationcomms.intg_abdm_health_info_txn DROP COLUMN organization_id;
ALTER TABLE integrationcomms.intg_abdm_request_queue DROP COLUMN organization_id;
ALTER TABLE integrationcomms.intg_bulk_import_job DROP COLUMN organization_id;
ALTER TABLE integrationcomms.intg_bulk_import_row DROP COLUMN organization_id;
ALTER TABLE integrationcomms.intg_hl7_dicom_endpoint DROP COLUMN organization_id;
ALTER TABLE integrationcomms.mst_rpt_report_letterhead DROP COLUMN organization_id;
ALTER TABLE integrationcomms.ref_bil_payer DROP COLUMN organization_id;
ALTER TABLE integrationcomms.ref_core_branch DROP COLUMN organization_id;
ALTER TABLE integrationcomms.ref_pat_encounter DROP COLUMN organization_id;
ALTER TABLE integrationcomms.rpt_report_definition DROP COLUMN organization_id;
ALTER TABLE lims.bb_blood_request DROP COLUMN organization_id;
ALTER TABLE lims.bb_blood_unit DROP COLUMN organization_id;
ALTER TABLE lims.bb_component_preparation DROP COLUMN organization_id;
ALTER TABLE lims.bb_donor DROP COLUMN organization_id;
ALTER TABLE lims.bb_patient_grouping DROP COLUMN organization_id;
ALTER TABLE lims.bb_stock_level DROP COLUMN organization_id;
ALTER TABLE lims.core_number_sequence DROP COLUMN organization_id;
ALTER TABLE lims.evt_outbox DROP COLUMN organization_id;
ALTER TABLE lims.lab_analyzer DROP COLUMN organization_id;
ALTER TABLE lims.lab_analyzer_message_log DROP COLUMN organization_id;
ALTER TABLE lims.lab_autoverify_rule DROP COLUMN organization_id;
ALTER TABLE lims.lab_eqas_result DROP COLUMN organization_id;
ALTER TABLE lims.lab_histo_block DROP COLUMN organization_id;
ALTER TABLE lims.lab_histo_case DROP COLUMN organization_id;
ALTER TABLE lims.lab_histo_slide DROP COLUMN organization_id;
ALTER TABLE lims.lab_label_print_log DROP COLUMN organization_id;
ALTER TABLE lims.lab_master_change_log DROP COLUMN organization_id;
ALTER TABLE lims.lab_outsource_manifest DROP COLUMN organization_id;
ALTER TABLE lims.lab_qc_lot DROP COLUMN organization_id;
ALTER TABLE lims.lab_recollection_request DROP COLUMN organization_id;
ALTER TABLE lims.lab_report DROP COLUMN organization_id;
ALTER TABLE lims.lab_result_attachment DROP COLUMN organization_id;
ALTER TABLE lims.lab_result_exception DROP COLUMN organization_id;
ALTER TABLE lims.lab_sample DROP COLUMN organization_id;
ALTER TABLE lims.lab_transport_batch DROP COLUMN organization_id;
ALTER TABLE lims.lab_worklist DROP COLUMN organization_id;
ALTER TABLE lims.mst_lab_antibiotic_panel DROP COLUMN organization_id;
ALTER TABLE lims.mst_lab_comment_template DROP COLUMN organization_id;
ALTER TABLE lims.mst_lab_container DROP COLUMN organization_id;
ALTER TABLE lims.mst_lab_section DROP COLUMN organization_id;
ALTER TABLE lims.mst_lab_specimen_type DROP COLUMN organization_id;
ALTER TABLE lims.mst_lab_test_routing DROP COLUMN organization_id;
ALTER TABLE lims.ref_bil_service DROP COLUMN organization_id;
ALTER TABLE lims.ref_core_branch DROP COLUMN organization_id;
ALTER TABLE lims.ref_inv_item DROP COLUMN organization_id;
ALTER TABLE lims.ref_inv_vendor DROP COLUMN organization_id;
ALTER TABLE lims.ref_ord_clinical_order DROP COLUMN organization_id;
ALTER TABLE lims.ref_pat_encounter DROP COLUMN organization_id;
ALTER TABLE lims.ref_rpt_report_letterhead DROP COLUMN organization_id;
ALTER TABLE operationssupply.adm_asset DROP COLUMN organization_id;
ALTER TABLE operationssupply.adm_complaint DROP COLUMN organization_id;
ALTER TABLE operationssupply.adm_gate_pass DROP COLUMN organization_id;
ALTER TABLE operationssupply.adm_housekeeping_task DROP COLUMN organization_id;
ALTER TABLE operationssupply.adm_incident DROP COLUMN organization_id;
ALTER TABLE operationssupply.adm_linen_txn DROP COLUMN organization_id;
ALTER TABLE operationssupply.adm_policy_document DROP COLUMN organization_id;
ALTER TABLE operationssupply.adm_quality_indicator DROP COLUMN organization_id;
ALTER TABLE operationssupply.core_number_sequence DROP COLUMN organization_id;
ALTER TABLE operationssupply.cssd_instrument_set DROP COLUMN organization_id;
ALTER TABLE operationssupply.cssd_set_instance DROP COLUMN organization_id;
ALTER TABLE operationssupply.cssd_sterilization_cycle DROP COLUMN organization_id;
ALTER TABLE operationssupply.diet_meal_menu DROP COLUMN organization_id;
ALTER TABLE operationssupply.evt_outbox DROP COLUMN organization_id;
ALTER TABLE operationssupply.fld_agent DROP COLUMN organization_id;
ALTER TABLE operationssupply.fld_agent_duty_log DROP COLUMN organization_id;
ALTER TABLE operationssupply.fld_cash_collection DROP COLUMN organization_id;
ALTER TABLE operationssupply.fld_handover_code DROP COLUMN organization_id;
ALTER TABLE operationssupply.fld_service_request DROP COLUMN organization_id;
ALTER TABLE operationssupply.fld_sos_alert DROP COLUMN organization_id;
ALTER TABLE operationssupply.fld_task DROP COLUMN organization_id;
ALTER TABLE operationssupply.fld_task_exception DROP COLUMN organization_id;
ALTER TABLE operationssupply.fld_task_milestone DROP COLUMN organization_id;
ALTER TABLE operationssupply.fld_task_order DROP COLUMN organization_id;
ALTER TABLE operationssupply.fld_vehicle DROP COLUMN organization_id;
ALTER TABLE operationssupply.inv_consumption DROP COLUMN organization_id;
ALTER TABLE operationssupply.inv_department_budget DROP COLUMN organization_id;
ALTER TABLE operationssupply.inv_grn DROP COLUMN organization_id;
ALTER TABLE operationssupply.inv_grn_po DROP COLUMN organization_id;
ALTER TABLE operationssupply.inv_indent DROP COLUMN organization_id;
ALTER TABLE operationssupply.inv_physical_count DROP COLUMN organization_id;
ALTER TABLE operationssupply.inv_physical_count_item DROP COLUMN organization_id;
ALTER TABLE operationssupply.inv_purchase_order DROP COLUMN organization_id;
ALTER TABLE operationssupply.inv_purchase_request DROP COLUMN organization_id;
ALTER TABLE operationssupply.inv_purchase_return DROP COLUMN organization_id;
ALTER TABLE operationssupply.inv_rate_contract DROP COLUMN organization_id;
ALTER TABLE operationssupply.inv_rate_contract_item DROP COLUMN organization_id;
ALTER TABLE operationssupply.inv_stock_snapshot DROP COLUMN organization_id;
ALTER TABLE operationssupply.inv_stock_sync_log DROP COLUMN organization_id;
ALTER TABLE operationssupply.inv_stock_transfer DROP COLUMN organization_id;
ALTER TABLE operationssupply.inv_store_location DROP COLUMN organization_id;
ALTER TABLE operationssupply.inv_vendor_item DROP COLUMN organization_id;
ALTER TABLE operationssupply.inv_vendor_rating DROP COLUMN organization_id;
ALTER TABLE operationssupply.mst_inv_item DROP COLUMN organization_id;
ALTER TABLE operationssupply.mst_inv_store DROP COLUMN organization_id;
ALTER TABLE operationssupply.mst_inv_vendor DROP COLUMN organization_id;
ALTER TABLE operationssupply.mst_inv_vendor_document DROP COLUMN organization_id;
ALTER TABLE operationssupply.ref_adt_ward DROP COLUMN organization_id;
ALTER TABLE operationssupply.ref_bil_service DROP COLUMN organization_id;
ALTER TABLE operationssupply.ref_core_branch DROP COLUMN organization_id;
ALTER TABLE operationssupply.ref_core_department DROP COLUMN organization_id;
ALTER TABLE operationssupply.ref_ecom_online_order DROP COLUMN organization_id;
ALTER TABLE operationssupply.ref_fin_hsn_sac DROP COLUMN organization_id;
ALTER TABLE operationssupply.ref_ord_clinical_order DROP COLUMN organization_id;
ALTER TABLE operationssupply.ref_ot_booking DROP COLUMN organization_id;
ALTER TABLE operationssupply.ref_ot_theatre DROP COLUMN organization_id;
ALTER TABLE operationssupply.ref_pat_encounter DROP COLUMN organization_id;
ALTER TABLE operationssupply.ref_sch_appointment DROP COLUMN organization_id;
ALTER TABLE patientengagement.adt_admission DROP COLUMN organization_id;
ALTER TABLE patientengagement.adt_visitor_log DROP COLUMN organization_id;
ALTER TABLE patientengagement.camp_camp DROP COLUMN organization_id;
ALTER TABLE patientengagement.core_number_sequence DROP COLUMN organization_id;
ALTER TABLE patientengagement.crm_call_log DROP COLUMN organization_id;
ALTER TABLE patientengagement.crm_campaign DROP COLUMN organization_id;
ALTER TABLE patientengagement.crm_enquiry DROP COLUMN organization_id;
ALTER TABLE patientengagement.crm_feedback DROP COLUMN organization_id;
ALTER TABLE patientengagement.ecom_cart DROP COLUMN organization_id;
ALTER TABLE patientengagement.ecom_cart_item DROP COLUMN organization_id;
ALTER TABLE patientengagement.ecom_customer_account DROP COLUMN organization_id;
ALTER TABLE patientengagement.ecom_customer_address DROP COLUMN organization_id;
ALTER TABLE patientengagement.ecom_customer_consent DROP COLUMN organization_id;
ALTER TABLE patientengagement.ecom_online_order DROP COLUMN organization_id;
ALTER TABLE patientengagement.ecom_order_document DROP COLUMN organization_id;
ALTER TABLE patientengagement.ecom_order_episode DROP COLUMN organization_id;
ALTER TABLE patientengagement.ecom_order_status_history DROP COLUMN organization_id;
ALTER TABLE patientengagement.ecom_patient_profile DROP COLUMN organization_id;
ALTER TABLE patientengagement.ecom_prescription_attachment DROP COLUMN organization_id;
ALTER TABLE patientengagement.ecom_rating_review DROP COLUMN organization_id;
ALTER TABLE patientengagement.evt_outbox DROP COLUMN organization_id;
ALTER TABLE patientengagement.mkt_catalogue_item DROP COLUMN organization_id;
ALTER TABLE patientengagement.mkt_channel_listing_map DROP COLUMN organization_id;
ALTER TABLE patientengagement.mkt_channel_partner DROP COLUMN organization_id;
ALTER TABLE patientengagement.mkt_commission_plan DROP COLUMN organization_id;
ALTER TABLE patientengagement.mkt_listing DROP COLUMN organization_id;
ALTER TABLE patientengagement.mkt_partner_settlement DROP COLUMN organization_id;
ALTER TABLE patientengagement.mkt_partner_settlement_line DROP COLUMN organization_id;
ALTER TABLE patientengagement.mkt_provider DROP COLUMN organization_id;
ALTER TABLE patientengagement.mkt_provider_document DROP COLUMN organization_id;
ALTER TABLE patientengagement.mkt_provider_location DROP COLUMN organization_id;
ALTER TABLE patientengagement.mkt_questionnaire DROP COLUMN organization_id;
ALTER TABLE patientengagement.mkt_questionnaire_question DROP COLUMN organization_id;
ALTER TABLE patientengagement.mkt_service_zone DROP COLUMN organization_id;
ALTER TABLE patientengagement.mst_adt_building DROP COLUMN organization_id;
ALTER TABLE patientengagement.mst_adt_ward DROP COLUMN organization_id;
ALTER TABLE patientengagement.pat_communication_preference DROP COLUMN organization_id;
ALTER TABLE patientengagement.pat_consent DROP COLUMN organization_id;
ALTER TABLE patientengagement.pat_corporate_tag DROP COLUMN organization_id;
ALTER TABLE patientengagement.pat_demographic_change_log DROP COLUMN organization_id;
ALTER TABLE patientengagement.pat_encounter DROP COLUMN organization_id;
ALTER TABLE patientengagement.pat_family_group DROP COLUMN organization_id;
ALTER TABLE patientengagement.pat_patient DROP COLUMN organization_id;
ALTER TABLE patientengagement.pat_patient_address DROP COLUMN organization_id;
ALTER TABLE patientengagement.pat_patient_merge DROP COLUMN organization_id;
ALTER TABLE patientengagement.pat_questionnaire_response DROP COLUMN organization_id;
ALTER TABLE patientengagement.pat_referral DROP COLUMN organization_id;
ALTER TABLE patientengagement.pat_referral_status_history DROP COLUMN organization_id;
ALTER TABLE patientengagement.pat_report_dispatch DROP COLUMN organization_id;
ALTER TABLE patientengagement.pat_report_dispatch_batch DROP COLUMN organization_id;
ALTER TABLE patientengagement.pat_scheme_beneficiary DROP COLUMN organization_id;
ALTER TABLE patientengagement.ref_adm_complaint DROP COLUMN organization_id;
ALTER TABLE patientengagement.ref_bil_bill DROP COLUMN organization_id;
ALTER TABLE patientengagement.ref_bil_discount_scheme DROP COLUMN organization_id;
ALTER TABLE patientengagement.ref_bil_estimate DROP COLUMN organization_id;
ALTER TABLE patientengagement.ref_bil_payer DROP COLUMN organization_id;
ALTER TABLE patientengagement.ref_bil_payment_gateway_txn DROP COLUMN organization_id;
ALTER TABLE patientengagement.ref_bil_service DROP COLUMN organization_id;
ALTER TABLE patientengagement.ref_bil_tariff_plan DROP COLUMN organization_id;
ALTER TABLE patientengagement.ref_core_branch DROP COLUMN organization_id;
ALTER TABLE patientengagement.ref_core_department DROP COLUMN organization_id;
ALTER TABLE patientengagement.ref_fld_agent DROP COLUMN organization_id;
ALTER TABLE patientengagement.ref_fld_service_request DROP COLUMN organization_id;
ALTER TABLE patientengagement.ref_inv_item DROP COLUMN organization_id;
ALTER TABLE patientengagement.ref_ord_clinical_order DROP COLUMN organization_id;
ALTER TABLE patientengagement.sch_appointment DROP COLUMN organization_id;
ALTER TABLE patientengagement.sch_capacity_window DROP COLUMN organization_id;
ALTER TABLE patientengagement.sch_channel_quota DROP COLUMN organization_id;
ALTER TABLE patientengagement.sch_consult_room DROP COLUMN organization_id;
ALTER TABLE patientengagement.sch_display_board DROP COLUMN organization_id;
ALTER TABLE patientengagement.sch_ondemand_request DROP COLUMN organization_id;
ALTER TABLE patientengagement.sch_practitioner_availability DROP COLUMN organization_id;
ALTER TABLE patientengagement.sch_practitioner_schedule DROP COLUMN organization_id;
ALTER TABLE patientengagement.sch_queue_token DROP COLUMN organization_id;
ALTER TABLE patientengagement.sch_queue_token_event DROP COLUMN organization_id;
ALTER TABLE patientengagement.sch_resource_schedule DROP COLUMN organization_id;
ALTER TABLE patientengagement.sch_schedule_change_request DROP COLUMN organization_id;
ALTER TABLE patientengagement.sch_schedule_visit_type DROP COLUMN organization_id;
ALTER TABLE patientengagement.sch_waitlist DROP COLUMN organization_id;
ALTER TABLE patientengagement.tele_expert_request DROP COLUMN organization_id;
ALTER TABLE patientengagement.tele_session DROP COLUMN organization_id;
ALTER TABLE pharmacy.core_number_sequence DROP COLUMN organization_id;
ALTER TABLE pharmacy.evt_outbox DROP COLUMN organization_id;
ALTER TABLE pharmacy.mst_pha_drug_change_request DROP COLUMN organization_id;
ALTER TABLE pharmacy.mst_pha_drug_dose_range DROP COLUMN organization_id;
ALTER TABLE pharmacy.mst_pha_lasa_pair DROP COLUMN organization_id;
ALTER TABLE pharmacy.pha_controlled_count DROP COLUMN organization_id;
ALTER TABLE pharmacy.pha_counseling_template DROP COLUMN organization_id;
ALTER TABLE pharmacy.pha_dispense DROP COLUMN organization_id;
ALTER TABLE pharmacy.pha_dispense_alert DROP COLUMN organization_id;
ALTER TABLE pharmacy.pha_dispense_return DROP COLUMN organization_id;
ALTER TABLE pharmacy.pha_drug_recall DROP COLUMN organization_id;
ALTER TABLE pharmacy.pha_eprescription_access_log DROP COLUMN organization_id;
ALTER TABLE pharmacy.pha_eprescription_link DROP COLUMN organization_id;
ALTER TABLE pharmacy.pha_narcotic_register DROP COLUMN organization_id;
ALTER TABLE pharmacy.pha_prescription_clarification DROP COLUMN organization_id;
ALTER TABLE pharmacy.pha_prescription_refill DROP COLUMN organization_id;
ALTER TABLE pharmacy.ref_core_branch DROP COLUMN organization_id;
ALTER TABLE pharmacy.ref_fin_hsn_sac DROP COLUMN organization_id;
ALTER TABLE pharmacy.ref_inv_item DROP COLUMN organization_id;
ALTER TABLE pharmacy.ref_inv_store DROP COLUMN organization_id;
ALTER TABLE pharmacy.ref_ord_prescription DROP COLUMN organization_id;
ALTER TABLE pharmacy.ref_pat_encounter DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_approval_step DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_bill DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_bill_number_void DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_cancellation_policy DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_cashier_shift DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_corporate_invoice DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_coupon_redemption DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_credit_note DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_deposit_request DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_doctor_contract DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_doctor_statement DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_doctor_statement_query DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_estimate DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_followup_rule DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_leakage_exception DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_package_episode DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_patient_account DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_payer_split DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_payment_gateway_event DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_payment_gateway_txn DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_receipt DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_recurring_charge_rule DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_referral_agent DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_refund_request DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_surgery_fee_rule DROP COLUMN organization_id;
ALTER TABLE revenuefinance.bil_waiver_request DROP COLUMN organization_id;
ALTER TABLE revenuefinance.core_number_sequence DROP COLUMN organization_id;
ALTER TABLE revenuefinance.edu_program DROP COLUMN organization_id;
ALTER TABLE revenuefinance.edu_student DROP COLUMN organization_id;
ALTER TABLE revenuefinance.evt_outbox DROP COLUMN organization_id;
ALTER TABLE revenuefinance.fin_asset_transaction DROP COLUMN organization_id;
ALTER TABLE revenuefinance.fin_bank_account DROP COLUMN organization_id;
ALTER TABLE revenuefinance.fin_cash_forecast DROP COLUMN organization_id;
ALTER TABLE revenuefinance.fin_cost_center DROP COLUMN organization_id;
ALTER TABLE revenuefinance.fin_einvoice_log DROP COLUMN organization_id;
ALTER TABLE revenuefinance.fin_fiscal_period DROP COLUMN organization_id;
ALTER TABLE revenuefinance.fin_gst_itc_reconciliation DROP COLUMN organization_id;
ALTER TABLE revenuefinance.fin_ledger_account DROP COLUMN organization_id;
ALTER TABLE revenuefinance.fin_payment_allocation DROP COLUMN organization_id;
ALTER TABLE revenuefinance.fin_posting_rule DROP COLUMN organization_id;
ALTER TABLE revenuefinance.fin_supplier_invoice DROP COLUMN organization_id;
ALTER TABLE revenuefinance.fin_tds_challan DROP COLUMN organization_id;
ALTER TABLE revenuefinance.fin_tds_entry DROP COLUMN organization_id;
ALTER TABLE revenuefinance.fin_voucher DROP COLUMN organization_id;
ALTER TABLE revenuefinance.hr_duty_roster DROP COLUMN organization_id;
ALTER TABLE revenuefinance.hr_job_requisition DROP COLUMN organization_id;
ALTER TABLE revenuefinance.hr_leave_type DROP COLUMN organization_id;
ALTER TABLE revenuefinance.hr_pay_component DROP COLUMN organization_id;
ALTER TABLE revenuefinance.hr_payroll_run DROP COLUMN organization_id;
ALTER TABLE revenuefinance.hr_training DROP COLUMN organization_id;
ALTER TABLE revenuefinance.ins_claim DROP COLUMN organization_id;
ALTER TABLE revenuefinance.ins_claim_appeal DROP COLUMN organization_id;
ALTER TABLE revenuefinance.ins_claim_document DROP COLUMN organization_id;
ALTER TABLE revenuefinance.ins_document_checklist DROP COLUMN organization_id;
ALTER TABLE revenuefinance.ins_preauth DROP COLUMN organization_id;
ALTER TABLE revenuefinance.it_helpdesk_ticket DROP COLUMN organization_id;
ALTER TABLE revenuefinance.mst_bil_discount_scheme DROP COLUMN organization_id;
ALTER TABLE revenuefinance.mst_bil_kit DROP COLUMN organization_id;
ALTER TABLE revenuefinance.mst_bil_kit_item DROP COLUMN organization_id;
ALTER TABLE revenuefinance.mst_bil_loyalty_rule DROP COLUMN organization_id;
ALTER TABLE revenuefinance.mst_bil_loyalty_tier DROP COLUMN organization_id;
ALTER TABLE revenuefinance.mst_bil_package_payer DROP COLUMN organization_id;
ALTER TABLE revenuefinance.mst_bil_payer DROP COLUMN organization_id;
ALTER TABLE revenuefinance.mst_bil_service DROP COLUMN organization_id;
ALTER TABLE revenuefinance.mst_bil_tariff_plan DROP COLUMN organization_id;
ALTER TABLE revenuefinance.mst_fin_hsn_sac DROP COLUMN organization_id;
ALTER TABLE revenuefinance.mst_ins_copay_rule DROP COLUMN organization_id;
ALTER TABLE revenuefinance.mst_ins_insurance_plan DROP COLUMN organization_id;
ALTER TABLE revenuefinance.mst_ins_insurance_sublimit DROP COLUMN organization_id;
ALTER TABLE revenuefinance.mst_ins_payer_network DROP COLUMN organization_id;
ALTER TABLE revenuefinance.ref_adm_asset DROP COLUMN organization_id;
ALTER TABLE revenuefinance.ref_adt_ward DROP COLUMN organization_id;
ALTER TABLE revenuefinance.ref_core_branch DROP COLUMN organization_id;
ALTER TABLE revenuefinance.ref_core_department DROP COLUMN organization_id;
ALTER TABLE revenuefinance.ref_fld_vehicle DROP COLUMN organization_id;
ALTER TABLE revenuefinance.ref_hr_shift DROP COLUMN organization_id;
ALTER TABLE revenuefinance.ref_inv_item DROP COLUMN organization_id;
ALTER TABLE revenuefinance.ref_pat_encounter DROP COLUMN organization_id;
ALTER TABLE rims.core_number_sequence DROP COLUMN organization_id;
ALTER TABLE rims.evt_outbox DROP COLUMN organization_id;
ALTER TABLE rims.mst_rad_procedure_modality DROP COLUMN organization_id;
ALTER TABLE rims.pacs_access_audit DROP COLUMN organization_id;
ALTER TABLE rims.pacs_ai_impression_draft DROP COLUMN organization_id;
ALTER TABLE rims.pacs_ai_job DROP COLUMN organization_id;
ALTER TABLE rims.pacs_ai_model DROP COLUMN organization_id;
ALTER TABLE rims.pacs_ai_routing_rule DROP COLUMN organization_id;
ALTER TABLE rims.pacs_correction_log DROP COLUMN organization_id;
ALTER TABLE rims.pacs_deid_profile DROP COLUMN organization_id;
ALTER TABLE rims.pacs_dicom_instance DROP COLUMN organization_id;
ALTER TABLE rims.pacs_distribution_rule DROP COLUMN organization_id;
ALTER TABLE rims.pacs_hanging_protocol DROP COLUMN organization_id;
ALTER TABLE rims.pacs_ingestion_log DROP COLUMN organization_id;
ALTER TABLE rims.pacs_print_job DROP COLUMN organization_id;
ALTER TABLE rims.pacs_quarantine_item DROP COLUMN organization_id;
ALTER TABLE rims.pacs_radiologist_shift DROP COLUMN organization_id;
ALTER TABLE rims.pacs_routing_job DROP COLUMN organization_id;
ALTER TABLE rims.pacs_routing_rule DROP COLUMN organization_id;
ALTER TABLE rims.pacs_share_link_access DROP COLUMN organization_id;
ALTER TABLE rims.pacs_storage_policy DROP COLUMN organization_id;
ALTER TABLE rims.pacs_study_comment DROP COLUMN organization_id;
ALTER TABLE rims.pacs_user_viewer_pref DROP COLUMN organization_id;
ALTER TABLE rims.pacs_worklist_event DROP COLUMN organization_id;
ALTER TABLE rims.rad_contrast_reaction DROP COLUMN organization_id;
ALTER TABLE rims.rad_critical_finding_alert DROP COLUMN organization_id;
ALTER TABLE rims.rad_dictation_job DROP COLUMN organization_id;
ALTER TABLE rims.rad_exposure_reject DROP COLUMN organization_id;
ALTER TABLE rims.rad_macro DROP COLUMN organization_id;
ALTER TABLE rims.rad_media_issue DROP COLUMN organization_id;
ALTER TABLE rims.rad_modality DROP COLUMN organization_id;
ALTER TABLE rims.rad_modality_downtime DROP COLUMN organization_id;
ALTER TABLE rims.rad_pcpndt_form_f DROP COLUMN organization_id;
ALTER TABLE rims.rad_peer_review DROP COLUMN organization_id;
ALTER TABLE rims.rad_study DROP COLUMN organization_id;
ALTER TABLE rims.rad_study_checklist DROP COLUMN organization_id;
ALTER TABLE rims.ref_bil_service DROP COLUMN organization_id;
ALTER TABLE rims.ref_core_branch DROP COLUMN organization_id;
ALTER TABLE rims.ref_inv_item DROP COLUMN organization_id;
ALTER TABLE rims.ref_rpt_report_letterhead DROP COLUMN organization_id;
ALTER TABLE rims.ref_sch_appointment DROP COLUMN organization_id;

-- unique keys re-created without organization_id
ALTER TABLE identityorg.core_lookup_value ADD CONSTRAINT uq_lookup_value UNIQUE NULLS NOT DISTINCT (lookup_type_id, value_code);
ALTER TABLE identityorg.mst_core_department ADD CONSTRAINT uq_department UNIQUE (dept_code);
ALTER TABLE identityorg.sec_role ADD CONSTRAINT uq_role UNIQUE (role_code);
ALTER TABLE revenuefinance.mst_bil_service ADD CONSTRAINT uq_service UNIQUE (service_code);
ALTER TABLE revenuefinance.mst_bil_payer ADD CONSTRAINT uq_payer UNIQUE (payer_code);
ALTER TABLE revenuefinance.fin_ledger_account ADD CONSTRAINT uq_ledger_account UNIQUE (account_code);
ALTER TABLE operationssupply.mst_inv_vendor ADD CONSTRAINT uq_vendor UNIQUE (vendor_code);
ALTER TABLE operationssupply.mst_inv_item ADD CONSTRAINT uq_item UNIQUE (item_code);
ALTER TABLE integrationcomms.comm_template ADD CONSTRAINT uq_comm_template_1 UNIQUE (template_code, channel, language_code, version_no);

-- views re-created without organization_id
CREATE VIEW operationssupply.ref_inv_grn AS
SELECT grn_id,
    branch_id,
    grn_no,
    store_id,
    vendor_id,
    purchase_order_id,
    supplier_invoice_no,
    supplier_invoice_date,
    grn_status,
    invoice_document_id,
    updated_at,
    updated_by,
    row_ver::bigint AS source_version,
    COALESCE(updated_at, created_at) AS replicated_at
   FROM operationssupply.inv_grn;
CREATE TRIGGER trg_read_only INSTEAD OF INSERT OR DELETE OR UPDATE ON operationssupply.ref_inv_grn FOR EACH ROW EXECUTE FUNCTION operationssupply.util_reject_write();
GRANT INSERT, SELECT, UPDATE, DELETE ON operationssupply.ref_inv_grn TO hims;
CREATE VIEW operationssupply.ref_inv_item AS
SELECT item_id,
    item_category_id,
    item_code,
    item_name,
    item_type,
    hsn_code,
    gst_rate,
    is_batch_tracked,
    is_expiry_tracked,
    is_serial_tracked,
    is_billable,
    is_cold_chain,
    barcode,
    updated_at,
    updated_by,
    row_ver::bigint AS source_version,
    COALESCE(updated_at, created_at) AS replicated_at
   FROM operationssupply.mst_inv_item;
CREATE TRIGGER trg_read_only INSTEAD OF INSERT OR DELETE OR UPDATE ON operationssupply.ref_inv_item FOR EACH ROW EXECUTE FUNCTION operationssupply.util_reject_write();
GRANT INSERT, SELECT, UPDATE, DELETE ON operationssupply.ref_inv_item TO hims;
CREATE VIEW operationssupply.ref_inv_vendor AS
SELECT vendor_id,
    vendor_code,
    vendor_name,
    vendor_type,
    pan_no,
    drug_licence_no,
    msme_no,
    state_code,
    bank_account_no,
    ifsc_code,
    updated_at,
    updated_by,
    row_ver::bigint AS source_version,
    COALESCE(updated_at, created_at) AS replicated_at
   FROM operationssupply.mst_inv_vendor;
CREATE TRIGGER trg_read_only INSTEAD OF INSERT OR DELETE OR UPDATE ON operationssupply.ref_inv_vendor FOR EACH ROW EXECUTE FUNCTION operationssupply.util_reject_write();
GRANT INSERT, SELECT, UPDATE, DELETE ON operationssupply.ref_inv_vendor TO hims;
CREATE VIEW patientengagement.ref_pat_encounter AS
SELECT encounter_id,
    branch_id,
    encounter_no,
    patient_id,
    encounter_type,
    department_id,
    specialty_id,
    attending_practitioner_id,
    tariff_plan_id,
    primary_patient_payer_id,
    financial_class,
    is_mlc,
    start_at,
    end_at,
    encounter_status,
    row_ver::bigint AS source_version,
    COALESCE(updated_at, created_at) AS replicated_at
   FROM patientengagement.pat_encounter;
CREATE TRIGGER trg_read_only INSTEAD OF INSERT OR DELETE OR UPDATE ON patientengagement.ref_pat_encounter FOR EACH ROW EXECUTE FUNCTION patientengagement.util_reject_write();
GRANT INSERT, SELECT, UPDATE, DELETE ON patientengagement.ref_pat_encounter TO hims;
CREATE VIEW patientengagement.ref_sch_appointment AS
SELECT appointment_id,
    branch_id,
    appointment_no,
    patient_id,
    provisional_name,
    appointment_type,
    practitioner_id,
    specialty_id,
    service_id,
    slot_id,
    booked_by_user_id,
    appointment_status,
    is_late_arrival,
    rescheduled_from_id,
    encounter_id,
    updated_at,
    updated_by,
    row_ver::bigint AS source_version,
    COALESCE(updated_at, created_at) AS replicated_at
   FROM patientengagement.sch_appointment;
CREATE TRIGGER trg_read_only INSTEAD OF INSERT OR DELETE OR UPDATE ON patientengagement.ref_sch_appointment FOR EACH ROW EXECUTE FUNCTION patientengagement.util_reject_write();
GRANT INSERT, SELECT, UPDATE, DELETE ON patientengagement.ref_sch_appointment TO hims;
CREATE VIEW revenuefinance.ref_bil_receipt AS
SELECT receipt_id,
    branch_id,
    receipt_no,
    receipt_type,
    patient_id,
    encounter_id,
    payer_id,
    counter_code,
    cashier_id,
    receipt_status,
    updated_at,
    updated_by,
    row_ver::bigint AS source_version,
    COALESCE(updated_at, created_at) AS replicated_at
   FROM revenuefinance.bil_receipt;
CREATE TRIGGER trg_read_only INSTEAD OF INSERT OR DELETE OR UPDATE ON revenuefinance.ref_bil_receipt FOR EACH ROW EXECUTE FUNCTION revenuefinance.util_reject_write();
GRANT INSERT, SELECT, UPDATE, DELETE ON revenuefinance.ref_bil_receipt TO hims;

COMMIT;
