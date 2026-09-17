-- ============================================================
-- 02_tables.sql
-- Raw landing tables: support agents + support tickets.
-- CHANGE_TRACKING is required for downstream dynamic tables and
-- for DATA_METRIC_SCHEDULE = 'TRIGGER_ON_CHANGES'.
-- ============================================================

DEFINE TABLE DCM_DEMO{{env_suffix}}.RAW.AGENTS (
    AGENT_ID    NUMBER NOT NULL,
    AGENT_NAME  VARCHAR(100),
    TEAM        VARCHAR(50)
)
CHANGE_TRACKING = TRUE;

DEFINE TABLE DCM_DEMO{{env_suffix}}.RAW.TICKETS (
    TICKET_ID       NUMBER NOT NULL,
    CUSTOMER_NAME   VARCHAR(150),
    AGENT_ID        NUMBER,
    PRIORITY        VARCHAR(20),
    STATUS          VARCHAR(20),
    OPENED_TS       TIMESTAMP_NTZ,
    CLOSED_TS       TIMESTAMP_NTZ
)
CHANGE_TRACKING = TRUE
DATA_METRIC_SCHEDULE = 'TRIGGER_ON_CHANGES';
