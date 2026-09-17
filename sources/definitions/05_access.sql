-- ============================================================
-- 05_access.sql
-- Role + grants for read-only BI/analyst access.
-- ============================================================

DEFINE ROLE DCM_DEMO_READ{{env_suffix}};

GRANT USAGE ON WAREHOUSE DCM_DEMO_WH{{env_suffix}}      TO ROLE DCM_DEMO_READ{{env_suffix}};
GRANT USAGE ON DATABASE DCM_DEMO{{env_suffix}}          TO ROLE DCM_DEMO_READ{{env_suffix}};
GRANT USAGE ON SCHEMA DCM_DEMO{{env_suffix}}.SERVE      TO ROLE DCM_DEMO_READ{{env_suffix}};
GRANT SELECT ON ALL VIEWS IN SCHEMA DCM_DEMO{{env_suffix}}.SERVE TO ROLE DCM_DEMO_READ{{env_suffix}};

-- Hand the role to whoever is running the demo so they can query SERVE.* as a "BI user"
GRANT ROLE DCM_DEMO_READ{{env_suffix}} TO USER {{demo_user}};
