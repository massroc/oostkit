Review CI/CD pipelines, Docker configuration, deployment setup, or scaffold a new app.

Usage:
- `/devops` — general health check across all infrastructure
- `/devops ci` — review CI workflows for issues
- `/devops deploy <app>` — review deployment config for a specific app
- `/devops new-app <name>` — checklist and scaffolding guide for adding a new app

If no argument is given, default to general health check mode.

## Step 1: Determine mode

Parse `$ARGUMENTS`:

- **Blank or "health"** → **General health check**
- **"ci"** → **CI review**
- **"deploy"** followed by an app name → **Deploy review**
- **"new-app"** followed by a name → **New app checklist**

---

## Mode: General health check

### 1a. Load infrastructure files

Read these files:
- `.github/workflows/_elixir-ci.yml` — reusable CI workflow
- `.github/workflows/ci-gate.yml` — always-run gate
- Each app workflow: `.github/workflows/portal.yml`, `.github/workflows/workgroup_pulse.yml`, `.github/workflows/wrt.yml`

Use Glob to find all `docker-compose.yml` and `fly.toml` files across the repo.

### 1b. Check for known issues

Run through this checklist (items are based on real issues encountered in this repo):

| Check | What to verify | Why |
|-------|---------------|-----|
| PLT cache key | Includes `apps/oostkit_shared/lib/**` in hash | Stale PLT causes false Dialyzer failures |
| PLT cache restore-keys | Does NOT use `restore-keys` | Prefix match restores stale PLT that won't rebuild |
| Deps cache | Can use `restore-keys` safely | Deps cache is additive, not invalidated by changes |
| Path filters | All app workflows trigger on `apps/oostkit_shared/**` and `shared/**` | Changes to shared code must trigger all app CI |
| CI Gate | `ci-gate.yml` exists and runs on every PR | Branch protection requires a check that always runs |
| `_elixir-ci.yml` trigger | Changes to `_elixir-ci.yml` trigger all app workflows | Reusable workflow changes affect all apps |
| mix.lock in cache key | `mix.lock` is in the deps cache hash | New deps must invalidate the cache |
| Concurrency groups | Each app workflow has `cancel-in-progress: true` | Superseded CI runs waste resources |
| Docker service naming | Services use `<prefix>_<service>` convention | Avoids conflicts when running multiple apps |
| Port conflicts | No two apps share the same port | Dev environments run concurrently |

### 1c. Output

**Infrastructure status:**

| Component | Status | Notes |
|-----------|--------|-------|
| CI workflows | OK / Issue | detail |
| Docker configs | OK / Issue | detail |
| Fly.io configs | OK / Issue | detail |
| Path filtering | OK / Issue | detail |
| Cache strategy | OK / Issue | detail |

Then list any issues found, numbered with severity:
- **must fix** — will cause CI failures, deploy issues, or data loss
- **should fix** — suboptimal but not breaking
- **info** — observation, no action needed

---

## Mode: CI review

### 2a. Load all CI files

Read:
- `.github/workflows/_elixir-ci.yml`
- `.github/workflows/ci-gate.yml`
- All app-specific workflows (use Glob: `.github/workflows/*.yml`)

### 2b. Review checklist

**Reusable workflow (`_elixir-ci.yml`):**
- [ ] Test job: runs `mix coveralls.json` (not plain `mix test`)
- [ ] Test job: compiles with `--warnings-as-errors`
- [ ] Test job: runs `mix credo --strict`
- [ ] Test job: runs `mix sobelow --config`
- [ ] Test job: checks formatting (`mix format --check-formatted`) on PRs
- [ ] Dialyzer job: PLT cache key includes `apps/oostkit_shared/lib/**`
- [ ] Dialyzer job: PLT cache does NOT use `restore-keys`
- [ ] Deploy job: only runs on `push` to `main` (not on PRs)
- [ ] Deploy job: has retry logic (up to 3 attempts)
- [ ] Deploy job: has post-deploy smoke test
- [ ] Deploy job: creates GitHub issue on failure
- [ ] Elixir/OTP versions are consistent across jobs and apps

**App workflows:**
- [ ] Path filters include the app's own path
- [ ] Path filters include `apps/oostkit_shared/**`
- [ ] Path filters include `shared/**`
- [ ] Path filters include `.github/workflows/_elixir-ci.yml`
- [ ] Path filters include the app's own workflow file
- [ ] Concurrency group set with `cancel-in-progress: true`
- [ ] Passes correct `app_name`, `app_path`, `database_name`
- [ ] `deploy_enabled` and `app_url` set correctly

**CI Gate:**
- [ ] Triggers on all PRs to main (no path filter)
- [ ] Job is minimal (just reports success)

### 2c. Output

Issues found (numbered, with severity) and a summary of what's correct.

---

## Mode: Deploy review

### 3a. Load deploy config for the specified app

Read:
- `apps/<app>/fly.toml`
- `apps/<app>/Dockerfile`
- `apps/<app>/docker-compose.yml`
- The app's CI workflow in `.github/workflows/`

### 3b. Review checklist

- [ ] `fly.toml` has health check configured (`path = "/health"`)
- [ ] `fly.toml` region is `syd` (Sydney)
- [ ] `fly.toml` has appropriate machine sizing
- [ ] Dockerfile uses multi-stage build (build → release)
- [ ] Dockerfile copies `shared/tailwind.preset.js` for asset compilation
- [ ] Dockerfile copies `apps/oostkit_shared/` for the path dependency
- [ ] Dockerfile runs `mix assets.deploy` in the build stage (this is correct for PRODUCTION builds — it's only wrong for dev builds)
- [ ] `.dockerignore` excludes `_build`, `deps`, `node_modules`, `.git`
- [ ] CI deploy step uses the correct `--config` and `--dockerfile` paths
- [ ] Required env vars documented or set as Fly secrets
- [ ] Smoke test URL matches the app's production URL

### 3c. Output

Deploy config summary table and any issues found.

---

## Mode: New app checklist

### 4a. Generate the complete checklist

For a new app named `<name>`:

**Directory structure:**
```
apps/<name>/
├── lib/
│   ├── <name>/
│   │   ├── application.ex
│   │   └── repo.ex
│   └── <name>_web/
│       ├── router.ex
│       ├── endpoint.ex
│       ├── components/
│       │   ├── core_components.ex
│       │   └── layouts.ex
│       └── controllers/
│           └── health_controller.ex
├── test/
│   ├── support/
│   │   ├── conn_case.ex
│   │   └── data_case.ex
│   └── test_helper.exs
├── config/
│   ├── config.exs
│   ├── dev.exs
│   ├── test.exs
│   ├── prod.exs
│   └── runtime.exs
├── assets/
│   └── tailwind.config.js          # imports shared/tailwind.preset.js
├── priv/
│   └── repo/migrations/
├── docker-compose.yml               # <prefix>_app, <prefix>_db, etc.
├── Dockerfile
├── Dockerfile.dev
├── fly.toml
├── mix.exs                          # depends on {:oostkit_shared, path: "../oostkit_shared"}
└── README.md
```

**CI workflow:** `.github/workflows/<name>.yml` — provide the complete YAML (follows the pattern in CLAUDE.md).

**Checklist:**
- [ ] Docker service names use `<prefix>_` convention (pick a short prefix)
- [ ] Ports don't conflict with existing apps (Portal: 4002/5436-7, Pulse: 4000/5432-3, WRT: 4001/5434-5)
- [ ] `mix.exs` includes `oostkit_shared` as path dependency
- [ ] `tailwind.config.js` imports `../../shared/tailwind.preset.js`
- [ ] `tailwind.config.js` content paths include `../oostkit_shared/lib/**/*`
- [ ] `CoreComponents` imports `OostkitShared.Components`
- [ ] Health endpoints: `GET /health` and `GET /health/ready`
- [ ] `fly.toml` configured for `syd` region
- [ ] Dockerfile copies `shared/` and `apps/oostkit_shared/` into build context
- [ ] CI workflow has correct path filters (includes `apps/oostkit_shared/**`, `shared/**`, `_elixir-ci.yml`)
- [ ] Root `docker-compose.yml` updated to include new app
- [ ] CLAUDE.md updated with new app's commands and service names
- [ ] `docs/ROADMAP.md` updated
- [ ] `docs/architecture.md` updated

### 4b. Output

The complete checklist with file contents where helpful (especially the CI workflow YAML and `docker-compose.yml`).

---

## Critical gotchas (encoded from past issues)

These are things that have broken this repo before. Always flag them if relevant:

1. **PLT cache must not use `restore-keys`** — a prefix-matched stale PLT causes Dialyzer to report missing functions that clearly exist
2. **Path filters must include `apps/oostkit_shared/**`** — otherwise shared lib changes don't trigger app CI
3. **CI Gate must exist and always run** — without it, path-filtered PRs that don't trigger any app CI can never merge (branch protection blocks them)
4. **`mix assets.deploy` empties un-digested files** — never use it for dev builds. Use `mix tailwind <profile>` and `mix esbuild <profile>` instead
5. **Stale `_build` after merging shared lib changes** — running dev containers need `mix deps.clean oostkit_shared` after pulling changes
6. **NEVER use `gh pr checks --watch`** — it shows stale runs from old force-pushes. The `/ship` command polls the commit SHA directly instead
