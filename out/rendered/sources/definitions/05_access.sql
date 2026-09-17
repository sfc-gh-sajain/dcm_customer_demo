-- ============================================================
-- 05_access.sql
-- Role + grants for read-only BI/analyst access.
-- ============================================================

DEFINE ROLE DCM_DEMO_READ_DEV;

GRANT USAGE ON WAREHOUSE DCM_DEMO_WH_DEV      TO ROLE DCM_DEMO_READ_DEV;
GRANT USAGE ON DATABASE DCM_DEMO_DEV          TO ROLE DCM_DEMO_READ_DEV;
GRANT USAGE ON SCHEMA DCM_DEMO_DEV.SERVE      TO ROLE DCM_DEMO_READ_DEV;
GRANT SELECT ON ALL VIEWS IN SCHEMA DCM_DEMO_DEV.SERVE TO ROLE DCM_DEMO_READ_DEV;

-- Hand the role to whoever is running the demo so they can query SERVE.* as a "BI user"
GRANT ROLE DCM_DEMO_READ_DEV TO USER SJAIN;