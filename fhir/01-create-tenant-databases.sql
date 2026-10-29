-- Run once against the PostgreSQL server as a superuser (or a role with CREATEDB):
--   psql -h 192.168.7.164 -p 50085 -U postgres -f 01-create-tenant-databases.sql
-- HAPI creates all its tables on first startup; these just need to exist and be owned by hims.

CREATE DATABASE hims_fhir_reddys OWNER hims ENCODING 'UTF8';
CREATE DATABASE hims_fhir_apollo OWNER hims ENCODING 'UTF8';

-- Isolation: stop tenants' databases from being reachable by default PUBLIC grants
REVOKE CONNECT ON DATABASE hims_fhir_reddys FROM PUBLIC;
REVOKE CONNECT ON DATABASE hims_fhir_apollo FROM PUBLIC;
GRANT  CONNECT ON DATABASE hims_fhir_reddys TO hims;
GRANT  CONNECT ON DATABASE hims_fhir_apollo TO hims;
