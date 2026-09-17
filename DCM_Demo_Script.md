# Snowflake DCM Projects — Customer Demo Script

**Duration:** ~15–20 minutes
**Account:** SFPSCOGS-SJ_DEMO (CLI connection `SJ_DEMO`)
**Project files:** `DCM_Customer_Demo/`
**Storyline:** A support-ticket analytics pipeline (raw tables → dynamic table → BI view) deployed, evolved, and governed entirely as code.

Every step shows both the **Snowsight Workspaces** path and the **CLI** path.

---

## 0. One-time setup (before the call)

### a) Run the pre-deploy script

Open `scripts/00_pre_deploy.sql` in a **Snowsight SQL worksheet** and execute it top to bottom. It does three things:

| Step | What it creates | Role required |
|---|---|---|
| 1 | `DCM_DEVELOPER` role + grants (CREATE WAREHOUSE, CREATE DATABASE, CREATE ROLE, MANAGE GRANTS, DMF privileges) | **ACCOUNTADMIN** |
| 2 | `GITHUB_INTEGRATION.SECRETS.GITHUB_PAT` secret (stores your GitHub PAT) + `GITHUB_API_INTEGRATION` (API integration with `ALLOWED_AUTHENTICATION_SECRETS = ALL`) + grants USAGE to DCM_DEVELOPER | **ACCOUNTADMIN** |
| 3 | Two DCM project objects: `DCM_DEMO_ADMIN.PROJECTS.SUPPORT_ANALYTICS_DEMO` (DEV) and `...SUPPORT_ANALYTICS_PROD` (PROD) | **DCM_DEVELOPER** |

**Before running:** edit lines in step 2b of the script — replace the `USERNAME` and `PASSWORD` values in the `CREATE SECRET` statement with your GitHub username and a PAT generated at https://github.com/settings/tokens (required scope: `repo` for private repos, or `public_repo` for public-only).

**Why ACCOUNTADMIN for step 2?** `CREATE INTEGRATION` is an account-level privilege that only ACCOUNTADMIN has by default. You create the integration + secret once; the DCM_DEVELOPER role only needs `USAGE ON INTEGRATION` and `READ ON SECRET` (both granted in the script) to use them when creating a Workspace.

**What is `ALLOWED_AUTHENTICATION_SECRETS = ALL`?** It controls which Snowflake `SECRET` objects are permitted when someone creates a Workspace using this integration. `ALL` means any secret in the account works (fine for demos). For production, lock it down to a specific secret: `(GITHUB_INTEGRATION.SECRETS.GITHUB_PAT)`.

### b) Push files to GitHub

The Snowsight Workspace needs a GitHub repo to connect to. From your terminal:

```bash
cd /Users/sajain/coco/Notes/DCM_Customer_Demo
git init
git add .
git commit -m "DCM Projects customer demo - support ticket analytics"
```

Create a new repo on GitHub (public or private), then push:

```bash
git remote add origin https://github.com/<your-github-user>/dcm-customer-demo.git
git branch -M main
git push -u origin main
```

### c) Create a Git-linked Workspace in Snowsight

1. **Projects → Workspaces → Create (+) → From Git repository**
2. **Repository URL:** paste `https://github.com/<your-github-user>/dcm-customer-demo.git`
3. **Workspace name:** `dcm-customer-demo` (or anything you prefer)
4. **API Integration:** select `GITHUB_API_INTEGRATION` (created in step a)
5. **Authentication:** select **Personal access token**
   - **Database:** `GITHUB_INTEGRATION`
   - **Schema:** `SECRETS`
   - The secret `GITHUB_PAT` should appear — select it
   - (Or click **+ Secret** to create a new one inline if you skipped step 2b)
6. Click **Create**.

The Workspace file explorer now shows `manifest.yml`, `definitions/`, and `scripts/`. The **DCM panel** appears as a tab in the bottom bar.

> **Note on commit + push with PAT auth:** For push to work, your GitHub PAT must have the `repo` scope (read/write). If you used `public_repo` scope only, push will fail on private repos.

### d) For the CLI path (alternative to Snowsight)

Have `snow` CLI v3.16.0+ installed. Verify: `snow connection test -c SJ_DEMO`. Then `cd` into `DCM_Customer_Demo/`.

---

## 1. "Here's the problem" (2 min)

Talking points:
- Infrastructure changes today are ad-hoc `CREATE`/`ALTER` scripts run against each environment by hand — easy to drift, hard to review, no audit trail.
- DCM Projects let you describe the **desired state** in SQL, review the diff before it touches anything, and get a deployment history automatically.

Show the folder structure in the Workspace file explorer (or `tree` in terminal):
```
DCM_Customer_Demo/
├── manifest.yml                          ← environment config (DEV/PROD)
└── definitions/
    ├── 01_infrastructure.sql             ← database, schemas, warehouse
    ├── 02_tables.sql                     ← raw landing tables
    ├── 03_pipeline.sql                   ← dynamic table transformation
    ├── 04_serve.sql                      ← BI-consumption view
    ├── 05_access.sql                     ← role + grants
    └── 06_expectations.sql               ← data quality checks (DMFs)
```

---

## 2. "It's just SQL" (3 min)

Open `definitions/02_tables.sql` and `definitions/03_pipeline.sql` side by side. Point out:
- `DEFINE TABLE` / `DEFINE DYNAMIC TABLE` — **identical syntax to `CREATE`**, just a different keyword.
- `{{env_suffix}}` — Jinja templating. The **same file** deploys `DCM_DEMO_DEV` today and `DCM_DEMO` (no suffix) to production later.
- `INITIALIZE = 'ON_SCHEDULE'` — keeps `DEPLOY` fast by skipping synchronous refresh at creation.
- `DATA_METRIC_SCHEDULE = 'TRIGGER_ON_CHANGES'` — turns on the data-quality checks from `06_expectations.sql`.

Open `manifest.yml` — show the `targets:` block (DEV and PROD pointing to their respective project objects) and the `templating:` block where `env_suffix`, `wh_size`, `retention_days` differ per environment.

---

## 3. Analyze → Plan → Deploy (5 min)

### Snowsight Workspaces

1. In the bottom panel, open the **DCM** tab. The project is auto-detected from `manifest.yml`.
2. Confirm the target selector shows **DCM_DEV** (it's the `default_target`).
3. Click the ▶ button next to **Plan**. Wait for it to render, compile, and dry-run.
4. Review the changeset — every object shows as `CREATE` (brand-new environment). **This is where a reviewer signs off** — same discipline as a pull-request diff.
5. Click **Deploy** (top-right of the Plan results). Type an alias like `initial-demo-deploy`.

### CLI

```bash
cd DCM_Customer_Demo
snow dcm plan --target DCM_DEV
snow dcm deploy --target DCM_DEV --alias "initial-demo-deploy"
```

### Either path

Refresh the Snowsight Database Explorer — `DCM_DEMO_DEV` now exists with all schemas, tables, the dynamic table, the view, the role, and the grants — from one command.

---

## 4. See it run (3 min)

Open `scripts/01_post_deploy.sql` in a **SQL worksheet** and run it. This:
- Inserts 3 agents and 5 tickets into the RAW tables
- Forces the first dynamic-table refresh (`EXECUTE DCM PROJECT ... REFRESH ALL`)
- Queries `ANALYTICS.TICKET_RESOLUTION` and `SERVE.V_AGENT_PERFORMANCE`
- Runs `EXECUTE DCM PROJECT ... TEST ALL` — shows the two data-quality expectations (`NO_MISSING_TICKET_ID`, `NO_MISSING_AGENT_ID`) passing

**Talking point:** the DMF checks are **defined in code alongside the table** (`06_expectations.sql`), not bolted on afterward in a separate governance tool.

---

## 5. "Now let's change something" — the iteration story (5 min)

This is the highest-impact moment: changes go through the **same reviewed workflow**, not a one-off `ALTER TABLE`.

1. **Edit** `definitions/02_tables.sql` in the Workspace editor (or locally) — add a column to `RAW.TICKETS`:
   ```sql
   CHANNEL  VARCHAR(20)    -- add as the last column
   ```

2. **Edit** `definitions/03_pipeline.sql` — append `t.CHANNEL` as the **last column** in the SELECT list.

3. **Plan again:**

   | Snowsight | CLI |
   |---|---|
   | Click ▶ Plan in the DCM panel | `snow dcm plan --target DCM_DEV` |

4. **Show the changeset:** it now says **`ALTER`** (not `CREATE`) — DCM diffed the new definition against the live object and computed the minimal change.

5. **Deploy:**

   | Snowsight | CLI |
   |---|---|
   | Click Deploy, alias `add-channel-column` | `snow dcm deploy --target DCM_DEV --alias "add-channel-column"` |

6. **(Snowsight only) Commit + push the change back to GitHub:**
   - Click the **Changes** tab at the top of the file explorer
   - Modified files show with an **M**
   - Type a commit message: `Add CHANNEL column to tickets pipeline`
   - Click **Push**

   This commits and pushes directly to your GitHub repo from Snowsight — no terminal needed.

7. Run the verification queries from `scripts/02_schema_evolution.sql`.

---

## 6. Promote to another environment (2 min, optional)

Same files, different target:

| Snowsight | CLI |
|---|---|
| Switch the target selector from DCM_DEV to **DCM_PROD**, then Plan | `snow dcm plan --target DCM_PROD` |

Point out: the plan now targets `DCM_DEMO` (no `_DEV` suffix) with a `SMALL` warehouse and 30-day retention — driven entirely by `manifest.yml`, zero code changes.

---

## 7. Deployment history (1 min)

Show the audit trail:

```sql
SHOW DEPLOYMENTS IN DCM PROJECT DCM_DEMO_ADMIN.PROJECTS.SUPPORT_ANALYTICS_DEMO;
```

Or CLI: `snow dcm list-deployments --target DCM_DEV`

Each row shows the alias, timestamp, user, and role.

---

## 8. Wrap-up talking points

- **Review before apply** — `PLAN` is mandatory and non-destructive; nothing changes until `DEPLOY`.
- **Full audit trail** — every deployment is recorded with alias, timestamp, and user.
- **No new language** — it's the SQL you already write, with `DEFINE` instead of `CREATE`.
- **Two-way Git sync** — edit in Snowsight Workspaces and push directly to GitHub, or edit locally and pull into the Workspace.
- **Scales to platform-team patterns** — split shared infra and per-team pipelines into separate DCM projects (guide §6).
- **Works from any surface** — Snowsight Workspaces, CLI, SQL (`EXECUTE DCM PROJECT`), Cortex Code, or CI/CD.

---

## 9. Cleanup (after the call)

Run `scripts/03_cleanup.sql` in a worksheet or:
```bash
snow sql -c SJ_DEMO -f scripts/03_cleanup.sql
```

---

## Quick reference: roles & privileges summary

| Object | Created by | Needed by DCM_DEVELOPER |
|---|---|---|
| `GITHUB_API_INTEGRATION` | ACCOUNTADMIN (`CREATE INTEGRATION`) | `USAGE ON INTEGRATION` (to select it when creating a Workspace) |
| `GITHUB_INTEGRATION.SECRETS.GITHUB_PAT` | ACCOUNTADMIN (`CREATE SECRET`) | `READ ON SECRET` + `USAGE` on the parent database and schema (to select the PAT during Workspace creation) |
| `DCM_DEMO_ADMIN.PROJECTS.*` (project objects) | DCM_DEVELOPER | `OWNERSHIP` (automatic — they created it) |
| Managed objects (databases, tables, roles, etc.) | DCM_DEVELOPER via `DEPLOY` | `CREATE WAREHOUSE`, `CREATE DATABASE`, `CREATE ROLE`, `MANAGE GRANTS` on account |
| Data quality expectations | DCM_DEVELOPER via `DEPLOY` | `EXECUTE DATA METRIC FUNCTION`, `SNOWFLAKE.DATA_METRIC_USER` DB role, `DATA_QUALITY_MONITORING_ADMIN` app role |

---

## Reference

See `Snowflake_DCM_Guide.html` (parent folder) for the full concept/syntax reference covering multi-project patterns, frozen regions, task graphs, and links to the 4-part official quickstart series.
