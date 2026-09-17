-- ============================================================
-- 00_pre_deploy.sql
-- Run this ONCE before the first Plan/Deploy. Creates:
--   1. DCM_DEVELOPER role with required privileges
--   2. Git API integration for Snowsight Workspaces (GitHub)
--   3. DCM project objects (DEV + PROD)
--
-- Run as ACCOUNTADMIN. This script lives OUTSIDE the DCM project
-- folder so it is never picked up by Plan/Deploy.
-- ============================================================

-- ==========================
-- 1. ROLE & PRIVILEGES
-- ==========================
USE ROLE ACCOUNTADMIN;

CREATE ROLE IF NOT EXISTS DCM_DEVELOPER;
GRANT ROLE DCM_DEVELOPER TO USER IDENTIFIER(CURRENT_USER());

-- Infrastructure privileges for DCM deployments
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE DCM_DEVELOPER;
GRANT CREATE DATABASE ON ACCOUNT TO ROLE DCM_DEVELOPER;
GRANT CREATE ROLE ON ACCOUNT TO ROLE DCM_DEVELOPER;
GRANT MANAGE GRANTS ON ACCOUNT TO ROLE DCM_DEVELOPER;

-- Data-quality (DMF) privileges for 06_expectations.sql
GRANT APPLICATION ROLE SNOWFLAKE.DATA_QUALITY_MONITORING_VIEWER TO ROLE DCM_DEVELOPER;
GRANT APPLICATION ROLE SNOWFLAKE.DATA_QUALITY_MONITORING_ADMIN  TO ROLE DCM_DEVELOPER;
GRANT DATABASE ROLE SNOWFLAKE.DATA_METRIC_USER TO ROLE DCM_DEVELOPER;
GRANT EXECUTE DATA METRIC FUNCTION ON ACCOUNT TO ROLE DCM_DEVELOPER;

-- ==========================
-- 2. GIT API INTEGRATION (using Personal Access Token)
-- ==========================
-- CREATE INTEGRATION requires CREATE INTEGRATION privilege,
-- which only ACCOUNTADMIN has by default. Create it once, then
-- grant USAGE to DCM_DEVELOPER.
--
-- How PAT auth works (two objects):
--   1. SECRET — stores your GitHub PAT securely in Snowflake
--   2. API INTEGRATION — tells Snowflake which GitHub URLs are
--      allowed and which secrets can authenticate against them
--
-- ALLOWED_AUTHENTICATION_SECRETS controls which SECRET objects
-- are permitted when creating a Workspace with this integration:
--   ALL            = any secret in the account (fine for demos)
--   (db.schema.s)  = only the listed secret(s) (best for prod)
--   NONE           = no secrets (use only if doing OAuth instead)

-- Step 2a: Create a database + schema to hold the secret
--          (you can use any existing DB/schema instead)
CREATE DATABASE IF NOT EXISTS GITHUB_INTEGRATION;
CREATE SCHEMA IF NOT EXISTS GITHUB_INTEGRATION.SECRETS;

-- Step 2b: Create a secret that stores your GitHub PAT
--          Generate a PAT at https://github.com/settings/tokens
--          Required scope: "repo" (full control of private repos)
--          For public repos only, "public_repo" is enough
CREATE OR REPLACE SECRET GITHUB_INTEGRATION.SECRETS.GITHUB_PAT
    TYPE = PASSWORD
    USERNAME = 'your-github-username'       -- <-- REPLACE with your GitHub username
    PASSWORD = 'ghp_xxxxxxxxxxxxxxxxxxxx'   -- <-- REPLACE with your GitHub PAT
    COMMENT = 'GitHub PAT for Snowsight Workspace Git integration';

-- Step 2c: Create the API integration
--          ALLOWED_AUTHENTICATION_SECRETS = ALL lets any secret in the
--          account be used with this integration. For tighter security,
--          replace ALL with (GITHUB_INTEGRATION.SECRETS.GITHUB_PAT).
CREATE OR REPLACE API INTEGRATION github_api_integration
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/')
    ALLOWED_AUTHENTICATION_SECRETS = ALL
    ENABLED = TRUE
    COMMENT = 'GitHub integration using PAT for Snowsight Workspaces';

-- Step 2d: Grant USAGE so DCM_DEVELOPER can select this integration
--          when creating a Workspace in Snowsight
GRANT USAGE ON INTEGRATION github_api_integration TO ROLE DCM_DEVELOPER;

-- Also grant read on the secret so DCM_DEVELOPER can reference it
GRANT USAGE ON DATABASE GITHUB_INTEGRATION TO ROLE DCM_DEVELOPER;
GRANT USAGE ON SCHEMA GITHUB_INTEGRATION.SECRETS TO ROLE DCM_DEVELOPER;
GRANT READ ON SECRET GITHUB_INTEGRATION.SECRETS.GITHUB_PAT TO ROLE DCM_DEVELOPER;

-- -----------------------------------------------------------------
-- Alternative: Snowflake GitHub App (OAuth — no PAT needed)
-- Uncomment below and comment out steps 2a-2d if you prefer OAuth:
--
-- CREATE OR REPLACE API INTEGRATION github_api_integration
--     API_PROVIDER = git_https_api
--     API_ALLOWED_PREFIXES = ('https://github.com/')
--     API_USER_AUTHENTICATION = (TYPE = SNOWFLAKE_GITHUB_APP)
--     ENABLED = TRUE;
-- GRANT USAGE ON INTEGRATION github_api_integration TO ROLE DCM_DEVELOPER;
-- -----------------------------------------------------------------

-- ==========================
-- 3. DCM PROJECT OBJECTS
-- ==========================
USE ROLE DCM_DEVELOPER;
CREATE DATABASE IF NOT EXISTS DCM_DEMO_ADMIN;
CREATE SCHEMA IF NOT EXISTS DCM_DEMO_ADMIN.PROJECTS;

-- DEV project (referenced by the DCM_DEV target in manifest.yml)
CREATE OR REPLACE DCM PROJECT DCM_DEMO_ADMIN.PROJECTS.SUPPORT_ANALYTICS_DEMO
    COMMENT = 'Customer-facing DCM demo (DEV): support ticket analytics pipeline';

-- PROD project (referenced by the DCM_PROD target in manifest.yml)
CREATE OR REPLACE DCM PROJECT DCM_DEMO_ADMIN.PROJECTS.SUPPORT_ANALYTICS_PROD
    COMMENT = 'Customer-facing DCM demo (PROD): support ticket analytics pipeline';

-- ==========================
-- 4. VERIFY
-- ==========================
SHOW DCM PROJECTS IN SCHEMA DCM_DEMO_ADMIN.PROJECTS;

-- Get your account identifier (needed if editing manifest.yml for a different account)
SELECT CURRENT_ORGANIZATION_NAME() || '-' || CURRENT_ACCOUNT_NAME() AS ACCOUNT_IDENTIFIER,
       CURRENT_USER() AS USER_NAME;

-- ============================================================
-- NEXT STEPS:
--
-- Snowsight:
--   1. Refresh your browser so the DCM project objects appear
--   2. Push these files to a GitHub repo, then:
--      Projects > Workspaces > Create (+) > From Git repository
--      Paste repo URL, select GITHUB_API_INTEGRATION, choose
--      "Personal access token", select GITHUB_INTEGRATION.SECRETS
--      as the database/schema, pick GITHUB_PAT, then Create
--   3. In the Workspace DCM panel, select DCM_DEV target > Plan > Deploy
--
-- CLI:
--   cd DCM_Customer_Demo
--   snow dcm plan --target DCM_DEV
--   snow dcm deploy --target DCM_DEV --alias "initial-demo-deploy"
-- ============================================================
