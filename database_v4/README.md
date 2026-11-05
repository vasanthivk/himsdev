# HIMS database_v4 - 9 microservices (PostgreSQL 15+)

full/   Complete schema per service (fresh install). Run 01 -> 09, then roles.sql.
        01_identityorg  02_patientengagement  03_clinicalcare  04_lims  05_rims
        06_revenuefinance  07_operationssupply  08_integrationcomms  09_pharmacy
delta/  Upgrade an existing database_v3 database in place. Run 00 -> 10, then full/roles.sql.
        00 restructure (diagnostics -> lims + rims, pharmacy out of operationssupply)
        01..09 per-service ADD COLUMN / CREATE TABLE (idempotent), 10 trigger housekeeping
seed/   v3 seeds re-pointed to the new schemas (04_lims, 06_revenuefinance).

New objects are marked "[NEW v4]" and added columns "v4 additions"; each carries its FDS requirement ids.
Details, traceability and decisions: HIMS_DB_v4_9_Microservices_Gap_Analysis.xlsx
Validated on PostgreSQL 16 (fresh build == v3 + delta: 11,965 columns, 704 FKs, 0 cross-schema FKs).
