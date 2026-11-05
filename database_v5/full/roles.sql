-- The login the services use for the tenant database (ConnectionStrings:Default / DATABASE_URL): read/write on the 9 service schemas.
-- Run as the database owner after the schemas exist:  psql -d <tenant_database> -v hims_password='...' -f roles.sql
-- (deploy.sh does this when HIMS_DB_PASSWORD is set.)
SELECT format('CREATE ROLE hims LOGIN PASSWORD %L', :'hims_password') WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hims') \gexec
SELECT format('ALTER ROLE hims PASSWORD %L', :'hims_password') \gexec
SELECT format('GRANT CONNECT ON DATABASE %I TO hims', current_database()) \gexec

DO $$
DECLARE s text;
BEGIN
    FOREACH s IN ARRAY ARRAY['identityorg', 'patientengagement', 'clinicalcare', 'lims', 'rims', 'revenuefinance', 'operationssupply', 'integrationcomms', 'pharmacy'] LOOP
        EXECUTE format('GRANT USAGE ON SCHEMA %I TO hims', s);
        EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA %I TO hims', s);
        EXECUTE format('GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA %I TO hims', s);
        EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA %I TO hims', s);
        EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO hims', s);
        EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO hims', s);
    END LOOP;
END $$;
