-- ============================================================
-- 03_pipeline.sql
-- ANALYTICS layer: a dynamic table joining TICKETS + AGENTS and
-- computing resolution time. INITIALIZE = 'ON_SCHEDULE' keeps the
-- DCM deploy fast (no synchronous refresh at CREATE time) --
-- run `EXECUTE DCM PROJECT ... REFRESH ALL` once after deploying.
-- ============================================================

DEFINE DYNAMIC TABLE DCM_DEMO_DEV.ANALYTICS.TICKET_RESOLUTION
WAREHOUSE = DCM_DEMO_WH_DEV
TARGET_LAG = '1 hour'
INITIALIZE = 'ON_SCHEDULE'
DATA_METRIC_SCHEDULE = 'TRIGGER_ON_CHANGES'
AS
SELECT
    t.TICKET_ID,
    t.CUSTOMER_NAME,
    t.PRIORITY,
    t.STATUS,
    a.AGENT_NAME,
    a.TEAM,
    t.OPENED_TS,
    t.CLOSED_TS,
    DATEDIFF('hour', t.OPENED_TS, t.CLOSED_TS) AS RESOLUTION_HOURS,
    t.CHANNEL
FROM DCM_DEMO_DEV.RAW.TICKETS t
JOIN DCM_DEMO_DEV.RAW.AGENTS a
    ON t.AGENT_ID = a.AGENT_ID;