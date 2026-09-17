-- ============================================================
-- 04_serve.sql
-- SERVE layer: a consumption-ready view for a BI dashboard.
-- ============================================================

DEFINE VIEW DCM_DEMO{{env_suffix}}.SERVE.V_AGENT_PERFORMANCE
DATA_METRIC_SCHEDULE = 'USING CRON 0 6 * * * UTC'
AS
SELECT
    TEAM,
    AGENT_NAME,
    COUNT(*)                    AS TICKETS_HANDLED,
    AVG(RESOLUTION_HOURS)        AS AVG_RESOLUTION_HOURS
FROM DCM_DEMO{{env_suffix}}.ANALYTICS.TICKET_RESOLUTION
WHERE STATUS = 'CLOSED'
GROUP BY TEAM, AGENT_NAME
ORDER BY AVG_RESOLUTION_HOURS;
