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
ALTER TABLE lab.analyzer ADD COLUMN IF NOT EXISTS host_address            VARCHAR(100) NULL;  -- host the Integration Engine listens on / polls for this instrument
ALTER TABLE lab.analyzer ADD COLUMN IF NOT EXISTS port                    INT          NULL;
ALTER TABLE lab.analyzer ADD COLUMN IF NOT EXISTS integration_channel_id  VARCHAR(100) NULL;  -- channel id returned by the Open Integration Engine
ALTER TABLE lab.analyzer ADD COLUMN IF NOT EXISTS routing_key             VARCHAR(150) NULL;  -- RabbitMQ routing key the engine publishes this instrument's results under
ALTER TABLE lab.analyzer ADD COLUMN IF NOT EXISTS channel_status          VARCHAR(20)  NULL;  -- PROVISIONED, PENDING, FAILED
