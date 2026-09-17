-- ============================================================
-- 01_infrastructure.sql
-- Database, schemas, warehouse. {{env_suffix}} lets DEV and PROD
-- share these same files (DCM_DEMO_DEV vs DCM_DEMO).
-- ============================================================

DEFINE WAREHOUSE DCM_DEMO_WH{{env_suffix}}
WITH
    WAREHOUSE_SIZE = '{{wh_size}}'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    COMMENT = 'Warehouse for the DCM customer demo';

DEFINE DATABASE DCM_DEMO{{env_suffix}}
    DATA_RETENTION_TIME_IN_DAYS = {{retention_days}}
    COMMENT = 'Customer support ticket analytics - DCM Projects demo';

DEFINE SCHEMA DCM_DEMO{{env_suffix}}.RAW
    COMMENT = 'Landing tables for raw source data';

DEFINE SCHEMA DCM_DEMO{{env_suffix}}.ANALYTICS
    COMMENT = 'Dynamic tables that transform RAW data';

DEFINE SCHEMA DCM_DEMO{{env_suffix}}.SERVE
    COMMENT = 'Views for dashboards / BI consumption';
