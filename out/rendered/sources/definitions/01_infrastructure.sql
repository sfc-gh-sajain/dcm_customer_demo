-- ============================================================
-- 01_infrastructure.sql
-- Database, schemas, warehouse. _DEV lets DEV and PROD
-- share these same files (DCM_DEMO_DEV vs DCM_DEMO).
-- ============================================================

DEFINE WAREHOUSE DCM_DEMO_WH_DEV
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    COMMENT = 'Warehouse for the DCM customer demo';

DEFINE DATABASE DCM_DEMO_DEV
    DATA_RETENTION_TIME_IN_DAYS = 1
    COMMENT = 'Customer support ticket analytics - DCM Projects demo';

DEFINE SCHEMA DCM_DEMO_DEV.RAW
    COMMENT = 'Landing tables for raw source data';

DEFINE SCHEMA DCM_DEMO_DEV.ANALYTICS
    COMMENT = 'Dynamic tables that transform RAW data';

DEFINE SCHEMA DCM_DEMO_DEV.SERVE
    COMMENT = 'Views for dashboards / BI consumption';