-- ============================================================
-- 02_schema_evolution.sql
-- NOT run directly. This is the live "iterate" moment of the demo:
-- edit a definition file, re-plan, re-deploy, and show the customer
-- that DCM computes an ALTER instead of a rebuild.
-- ============================================================

-- STEP A: In definitions/02_tables.sql, add a new column to RAW.TICKETS:
--
--   DEFINE TABLE DCM_DEMO{{env_suffix}}.RAW.TICKETS (
--       TICKET_ID       NUMBER NOT NULL,
--       CUSTOMER_NAME   VARCHAR(150),
--       AGENT_ID        NUMBER,
--       PRIORITY        VARCHAR(20),
--       STATUS          VARCHAR(20),
--       OPENED_TS       TIMESTAMP_NTZ,
--       CLOSED_TS       TIMESTAMP_NTZ,
--       CHANNEL         VARCHAR(20)          -- <-- NEW COLUMN
--   )
--   CHANGE_TRACKING = TRUE
--   DATA_METRIC_SCHEDULE = 'TRIGGER_ON_CHANGES';

-- STEP B: In definitions/03_pipeline.sql, surface it through the pipeline
-- (must be appended as the LAST column in the SELECT list):
--
--   SELECT
--       t.TICKET_ID, t.CUSTOMER_NAME, t.PRIORITY, t.STATUS,
--       a.AGENT_NAME, a.TEAM, t.OPENED_TS, t.CLOSED_TS,
--       DATEDIFF('hour', t.OPENED_TS, t.CLOSED_TS) AS RESOLUTION_HOURS,
--       t.CHANNEL                                          -- <-- NEW COLUMN, appended last
--   FROM DCM_DEMO{{env_suffix}}.RAW.TICKETS t
--   JOIN DCM_DEMO{{env_suffix}}.RAW.AGENTS a ON t.AGENT_ID = a.AGENT_ID;

-- STEP C: Re-run plan and point out the changeset now shows ALTER (not CREATE):
--
--   Snowsight: Click Plan in the DCM panel, review the ALTER, then Deploy.
--   CLI:       snow dcm plan --target DCM_DEV
--              snow dcm deploy --target DCM_DEV --alias "add-channel-column"

-- STEP D: Refresh + verify the new column populated without a full rebuild:
EXECUTE DCM PROJECT DCM_DEMO_ADMIN.PROJECTS.SUPPORT_ANALYTICS_DEMO REFRESH ALL;
SELECT TICKET_ID, CUSTOMER_NAME, CHANNEL FROM DCM_DEMO_DEV.ANALYTICS.TICKET_RESOLUTION;
