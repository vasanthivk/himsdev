# HIMS database_v5 - 9 microservices, one database per tenant (PostgreSQL 15+)

Changes from database_v4 (otherwise identical; v5: 701 tables, 11,557 columns, 1,559 constraints, 1,278 indexes, 542 triggers):

0. **Schema names without underscores**: identity_org -> identityorg, patient_engagement -> patientengagement,
   clinical_care -> clinicalcare, revenue_finance -> revenuefinance, operations_supply -> operationssupply,
   integration_comms -> integrationcomms (lims, rims, pharmacy unchanged). Script files renamed to match.
1. **mst_* tables carry a module prefix**: identityorg.mst_shift -> mst_hr_shift, revenuefinance.mst_service -> mst_bil_service, ...
   53 tables renamed. Tables that already named their module are unchanged (mst_lab_*, mst_rad_*, mst_ot_theatre).
2. **ref_* replicas carry the source module prefix**: ref_ + source table name (mst_ dropped):
   lims.ref_patient -> ref_pat_patient, lims.ref_service -> ref_bil_service, lims.ref_branch -> ref_core_branch, ...
   133 replica tables and 8 read-only ref_* compatibility views renamed.
3. **lims.mst_lab_test**: specimen_type -> specimen_type_id (INT NOT NULL, FK lims.mst_lab_specimen_type) and
   container_type -> container_type_id (INT NULL, FK lims.mst_lab_container). The duplicate v4 columns specimen_type_id / container_id
   were merged into these.
4. **New lims.mst_lab_section** (lab_section_id, section_code, section_name, is_active + audit columns), seeded with the 12 FDS sections
   (LAB-CAT-002). lab_section VARCHAR -> lab_section_id INT FK on lims.mst_lab_test (NOT NULL), lims.lab_analyzer and lims.lab_worklist.
5. **One database per tenant**: organization_id removed from 416 tables
   and 6 ref_* views, with its foreign keys. The 9 unique keys that included it now use the remaining columns
   (e.g. UNIQUE (organization_id, service_code) -> UNIQUE (service_code)). Kept only where it is the key of the tenant profile:
   identityorg.core_organization (one row per database: name, legal name, PAN, CIN, logo) and its ref_core_organization replicas.

All references (physical FKs, "logical FK ->" and "replica of" comments, explicit constraint / index names, seeds, grants) were updated.

These scripts do not create, drop or connect to any database. Provision each tenant's database separately, then run the scripts in it.

full/   Complete schema per service, run inside a tenant's database: 01 -> 09, then roles.sql (-v hims_password=...).
seed/   Seed data for the Dr Reddis HealthCare tenant. Run 01_identityorg -> 06_revenuefinance -> 04_lims inside that tenant's database. Each loads its own organisation row, branch, departments, doctors, services, tariff and lab masters.
delta/  01_v4_to_v5_renames.sql upgrades an existing database_v4 database in place (one transaction, data kept):
        schema, table, view, constraint, index and sequence renames, the mst_lab_test / mst_lab_section changes (codes -> IDs),
        then the organization_id removal. It stops if the database holds more than one organization (split tenants first).
        From database_v3: run the database_v4 delta first, then this script.
HIMS_DB_v5_Rename_Map.xlsx   every change: schemas, tables, views, columns, new tables, organization_id removal, unique keys,
        constraints, indexes, sequences.

Validated on PostgreSQL 16: fresh v5 build (+ seeds) == single-tenant seeded v4 + delta, compared on tables, columns
(type, null, default), constraints, indexes, sequences, triggers, view definitions and view grants (0 differences).
The seeds load cleanly and are safe to re-run.
