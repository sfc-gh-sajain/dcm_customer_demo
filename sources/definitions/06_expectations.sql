-- ============================================================
-- 06_expectations.sql
-- Data quality: attach system Data Metric Functions with
-- expectations. Requires DATA_METRIC_SCHEDULE on the target
-- table/view (already set in 02_tables.sql / 04_serve.sql).
-- ============================================================

ATTACH DATA METRIC FUNCTION SNOWFLAKE.CORE.NULL_COUNT
    TO TABLE DCM_DEMO{{env_suffix}}.RAW.TICKETS
    ON (TICKET_ID)
    EXPECTATION NO_MISSING_TICKET_ID (value = 0);

ATTACH DATA METRIC FUNCTION SNOWFLAKE.CORE.NULL_COUNT
    TO TABLE DCM_DEMO{{env_suffix}}.RAW.TICKETS
    ON (AGENT_ID)
    EXPECTATION NO_MISSING_AGENT_ID (value = 0);
