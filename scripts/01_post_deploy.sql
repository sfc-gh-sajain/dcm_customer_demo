-- ============================================================
-- 01_post_deploy.sql
-- Run after the first successful deploy. Loads sample data,
-- refreshes the dynamic table (it deployed with
-- INITIALIZE = 'ON_SCHEDULE', i.e. empty), then queries the
-- pipeline output. Assumes --configuration DEV (env_suffix=_DEV).
-- ============================================================

USE ROLE DCM_DEVELOPER;
USE DATABASE DCM_DEMO_DEV;

INSERT INTO RAW.AGENTS (AGENT_ID, AGENT_NAME, TEAM) VALUES
    (1, 'Alice Chen',   'Platform'),
    (2, 'Marco Diaz',   'Billing'),
    (3, 'Priya Rao',    'Platform');

INSERT INTO RAW.TICKETS (TICKET_ID, CUSTOMER_NAME, AGENT_ID, PRIORITY, STATUS, OPENED_TS, CLOSED_TS) VALUES
    (1001, 'Acme Corp',      1, 'HIGH',   'CLOSED', '2026-09-01 09:00:00', '2026-09-01 12:00:00'),
    (1002, 'Globex Inc',     2, 'MEDIUM', 'CLOSED', '2026-09-02 10:00:00', '2026-09-03 09:00:00'),
    (1003, 'Initech',        1, 'LOW',    'CLOSED', '2026-09-03 08:00:00', '2026-09-03 10:30:00'),
    (1004, 'Umbrella Corp',  3, 'HIGH',   'OPEN',   '2026-09-05 14:00:00', NULL),
    (1005, 'Soylent LLC',    2, 'MEDIUM', 'CLOSED', '2026-09-04 11:00:00', '2026-09-05 09:00:00');

-- Dynamic table was created empty (INITIALIZE = 'ON_SCHEDULE') - force the first refresh:
EXECUTE DCM PROJECT DCM_DEMO_ADMIN.PROJECTS.SUPPORT_ANALYTICS_DEMO REFRESH ALL;

-- Verify the pipeline end-to-end:
SELECT * FROM ANALYTICS.TICKET_RESOLUTION ORDER BY TICKET_ID;
SELECT * FROM SERVE.V_AGENT_PERFORMANCE;

-- Verify data quality expectations were attached and can be run on demand:
EXECUTE DCM PROJECT DCM_DEMO_ADMIN.PROJECTS.SUPPORT_ANALYTICS_DEMO TEST ALL;

-- Show off the read-only role granted by the project:
-- USE ROLE DCM_DEMO_READ_DEV;
-- SELECT * FROM DCM_DEMO_DEV.SERVE.V_AGENT_PERFORMANCE;
