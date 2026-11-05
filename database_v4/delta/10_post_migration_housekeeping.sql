/* =====================================================================================
   DR REDDIS HEALTHCARE - HIMS  database_v3 (7 services)  ->  database_v4 (9 services)
   Step 10 - post-migration housekeeping (row_ver triggers for every table incl. moved / new ones)
   Run against an EXISTING himsdev database that was built from database_v3, in file-name order:
     00_restructure_7_to_9_services.sql  -> 01..09_<service>_delta.sql  -> 10_post_migration_housekeeping.sql -> ../full/roles.sql
   Every statement is idempotent where PostgreSQL allows it (IF NOT EXISTS / guarded DO blocks).
   ===================================================================================== */


CREATE OR REPLACE FUNCTION identityorg.util_reject_write() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION '% is a read-only view of a table owned by this service; write to the owner table instead', TG_TABLE_NAME;
END $$;

CREATE OR REPLACE FUNCTION identityorg.util_bump_row_ver() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver := COALESCE(OLD.row_ver, 0) + 1;
    RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION identityorg.util_touch_audit() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver    := COALESCE(OLD.row_ver, 0) + 1;
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END $$;


CREATE OR REPLACE FUNCTION patientengagement.util_reject_write() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION '% is a read-only view of a table owned by this service; write to the owner table instead', TG_TABLE_NAME;
END $$;

CREATE OR REPLACE FUNCTION patientengagement.util_bump_row_ver() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver := COALESCE(OLD.row_ver, 0) + 1;
    RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION patientengagement.util_touch_audit() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver    := COALESCE(OLD.row_ver, 0) + 1;
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END $$;


CREATE OR REPLACE FUNCTION clinicalcare.util_reject_write() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION '% is a read-only view of a table owned by this service; write to the owner table instead', TG_TABLE_NAME;
END $$;

CREATE OR REPLACE FUNCTION clinicalcare.util_bump_row_ver() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver := COALESCE(OLD.row_ver, 0) + 1;
    RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION clinicalcare.util_touch_audit() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver    := COALESCE(OLD.row_ver, 0) + 1;
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END $$;


CREATE OR REPLACE FUNCTION lims.util_reject_write() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION '% is a read-only view of a table owned by this service; write to the owner table instead', TG_TABLE_NAME;
END $$;

CREATE OR REPLACE FUNCTION lims.util_bump_row_ver() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver := COALESCE(OLD.row_ver, 0) + 1;
    RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION lims.util_touch_audit() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver    := COALESCE(OLD.row_ver, 0) + 1;
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END $$;


CREATE OR REPLACE FUNCTION rims.util_reject_write() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION '% is a read-only view of a table owned by this service; write to the owner table instead', TG_TABLE_NAME;
END $$;

CREATE OR REPLACE FUNCTION rims.util_bump_row_ver() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver := COALESCE(OLD.row_ver, 0) + 1;
    RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION rims.util_touch_audit() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver    := COALESCE(OLD.row_ver, 0) + 1;
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END $$;


CREATE OR REPLACE FUNCTION revenuefinance.util_reject_write() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION '% is a read-only view of a table owned by this service; write to the owner table instead', TG_TABLE_NAME;
END $$;

CREATE OR REPLACE FUNCTION revenuefinance.util_bump_row_ver() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver := COALESCE(OLD.row_ver, 0) + 1;
    RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION revenuefinance.util_touch_audit() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver    := COALESCE(OLD.row_ver, 0) + 1;
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END $$;


CREATE OR REPLACE FUNCTION operationssupply.util_reject_write() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION '% is a read-only view of a table owned by this service; write to the owner table instead', TG_TABLE_NAME;
END $$;

CREATE OR REPLACE FUNCTION operationssupply.util_bump_row_ver() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver := COALESCE(OLD.row_ver, 0) + 1;
    RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION operationssupply.util_touch_audit() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver    := COALESCE(OLD.row_ver, 0) + 1;
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END $$;


CREATE OR REPLACE FUNCTION integrationcomms.util_reject_write() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION '% is a read-only view of a table owned by this service; write to the owner table instead', TG_TABLE_NAME;
END $$;

CREATE OR REPLACE FUNCTION integrationcomms.util_bump_row_ver() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver := COALESCE(OLD.row_ver, 0) + 1;
    RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION integrationcomms.util_touch_audit() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver    := COALESCE(OLD.row_ver, 0) + 1;
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END $$;


CREATE OR REPLACE FUNCTION pharmacy.util_reject_write() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION '% is a read-only view of a table owned by this service; write to the owner table instead', TG_TABLE_NAME;
END $$;

CREATE OR REPLACE FUNCTION pharmacy.util_bump_row_ver() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver := COALESCE(OLD.row_ver, 0) + 1;
    RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION pharmacy.util_touch_audit() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.row_ver    := COALESCE(OLD.row_ver, 0) + 1;
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END $$;


DO $$
DECLARE r record;
BEGIN
    FOR r IN
        SELECT c.table_schema, c.table_name,
               EXISTS (SELECT 1 FROM information_schema.columns u
                        WHERE u.table_schema = c.table_schema AND u.table_name = c.table_name
                          AND u.column_name = 'updated_at') AS has_updated_at
          FROM information_schema.columns c
          JOIN information_schema.tables t ON t.table_schema = c.table_schema AND t.table_name = c.table_name
         WHERE c.column_name = 'row_ver' AND t.table_type = 'BASE TABLE'
           AND c.table_schema IN ('identityorg', 'patientengagement', 'clinicalcare', 'lims', 'rims', 'revenuefinance', 'operationssupply', 'integrationcomms', 'pharmacy')
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_row_ver ON %I.%I', r.table_schema, r.table_name);
        EXECUTE format('CREATE TRIGGER trg_row_ver BEFORE UPDATE ON %I.%I FOR EACH ROW EXECUTE FUNCTION %I.%s',
                       r.table_schema, r.table_name, r.table_schema,
                       CASE WHEN r.has_updated_at THEN 'util_touch_audit()' ELSE 'util_bump_row_ver()' END);
    END LOOP;
END $$;

-- read-only replica views keep their INSTEAD OF triggers; re-point them to the function of their own schema
DO $$
DECLARE r record;
BEGIN
    FOR r IN
        SELECT n.nspname AS sch, c.relname AS vw
          FROM pg_trigger tg JOIN pg_class c ON c.oid = tg.tgrelid JOIN pg_namespace n ON n.oid = c.relnamespace
         WHERE tg.tgname = 'trg_read_only' AND n.nspname IN ('identityorg', 'patientengagement', 'clinicalcare', 'lims', 'rims', 'revenuefinance', 'operationssupply', 'integrationcomms', 'pharmacy')
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_read_only ON %I.%I', r.sch, r.vw);
        EXECUTE format('CREATE TRIGGER trg_read_only INSTEAD OF INSERT OR UPDATE OR DELETE ON %I.%I FOR EACH ROW EXECUTE FUNCTION %I.util_reject_write()', r.sch, r.vw, r.sch);
    END LOOP;
END $$;
