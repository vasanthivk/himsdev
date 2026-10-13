-- =============================================================================================
-- EXTENSION to 03_laboratory.sql  (the original script is NOT modified; run this after it)
--
-- Extra columns on lab.analyzer so that "add a device" can be wired to the Open Integration
-- Engine. The original table only has a 500-char free-text `connection_details` column.
--
-- Also note: lab.analyzer.interface_protocol is documented as ASTM, HL7V2, LIS2-A2, FILE. There
-- is no CHECK constraint, and this project also stores HL7V3 and FHIR there (devices can speak
-- HL7 v2, HL7 v3 or FHIR). No schema change is needed for that.
-- =============================================================================================
ALTER TABLE lab.analyzer ADD COLUMN IF NOT EXISTS sending_application_id  VARCHAR(50)  NULL;  -- HL7 MSH-3 / FHIR Device identifier the instrument identifies itself with
ALTER TABLE lab.analyzer ADD COLUMN IF NOT EXISTS integration_channel_id  VARCHAR(100) NULL;  -- channel id returned by the Open Integration Engine
ALTER TABLE lab.analyzer ADD COLUMN IF NOT EXISTS routing_key             VARCHAR(150) NULL;  -- RabbitMQ routing key the engine publishes this instrument's results under
ALTER TABLE lab.analyzer ADD COLUMN IF NOT EXISTS channel_status          VARCHAR(20)  NULL;  -- PROVISIONED, PENDING, FAILED

-- Open Integration Engine connection for this device, entered on the "Add a device" form. NULL = the Integration Hub's own
-- setting (services/integration/.env) is used.
ALTER TABLE lab.analyzer ADD COLUMN IF NOT EXISTS engine_url              VARCHAR(200) NULL;  -- engine REST API base, e.g. https://engine-host:8443
ALTER TABLE lab.analyzer ADD COLUMN IF NOT EXISTS engine_user             VARCHAR(100) NULL;
ALTER TABLE lab.analyzer ADD COLUMN IF NOT EXISTS engine_password         VARCHAR(200) NULL;  -- kept for re-provisioning; never returned by the Laboratory API
ALTER TABLE lab.analyzer ADD COLUMN IF NOT EXISTS engine_verify_tls       BOOLEAN      NULL;
ALTER TABLE lab.analyzer ADD COLUMN IF NOT EXISTS engine_first_listen_port INT         NULL;  -- port the device's channel listens on inside the engine (used as entered)
ALTER TABLE lab.analyzer ADD COLUMN IF NOT EXISTS engine_channel_url      VARCHAR(200) NULL;  -- the deployed channel's own HTTP endpoint (messages are sent here)
