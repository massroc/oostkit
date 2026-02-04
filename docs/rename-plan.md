# Rename Plan: productive_workgroups → workgroup_pulse

## Status: COMPLETE

All items below have been completed and tested. 234 tests passing.

## Changes Completed

### 1. Directory Structure
- [x] `apps/productive_workgroups/` → `apps/workgroup_pulse/`

### 2. Elixir Modules
- [x] `ProductiveWorkgroups` → `WorkgroupPulse`
- [x] `ProductiveWorkgroupsWeb` → `WorkgroupPulseWeb`
- [x] `ProductiveWorkgroups.Repo` → `WorkgroupPulse.Repo`
- [x] All module references in lib/, test/, config/

### 3. Mix Configuration
- [x] `mix.exs`: app name `:productive_workgroups` → `:workgroup_pulse`
- [x] Update all dependency references

### 4. Directory Names
- [x] `lib/productive_workgroups/` → `lib/workgroup_pulse/`
- [x] `lib/productive_workgroups_web/` → `lib/workgroup_pulse_web/`
- [x] `test/productive_workgroups/` → `test/workgroup_pulse/`
- [x] `test/productive_workgroups_web/` → `test/workgroup_pulse_web/`

### 5. Database
- [x] Database name: `productive_workgroups_dev` → `workgroup_pulse_dev`
- [x] Test database: `productive_workgroups_test` → `workgroup_pulse_test`
- [x] Update `config/dev.exs`, `config/test.exs`, `config/runtime.exs`

### 6. Docker
- [x] Service prefix: `pw_` → `wp_`
- [x] Volume names in docker-compose.yml
- [x] Update CLAUDE.md with new service names

### 7. CI/CD
- [x] `.github/workflows/productive_workgroups.yml` → `.github/workflows/workgroup_pulse.yml`
- [x] Update path filters in workflow
- [x] Update cache keys
- [x] Update format.yml workflow

### 8. Fly.io
- [x] Update `fly.toml` app name: `workgroup-pulse`
- [x] Create new Fly app `workgroup-pulse`
- [x] Attach new database `workgroup-pulse-db`
- [x] Set secrets (SECRET_KEY_BASE, DATABASE_URL, ECTO_IPV6)
- [x] Deploy and verify
- [x] Destroy old app `productive-workgroups`
- [x] Destroy old database `productive-workgroups-db`

### 9. Documentation
- [x] `apps/workgroup_pulse/README.md` - update references
- [x] Root `README.md` - update paths
- [x] `CLAUDE.md` - update commands and paths
- [x] `Makefile` - update targets
- [x] `docs/architecture.md` - update references

### 10. Root Config
- [x] `docker-compose.yml` - update include path

## Verification

- All 234 tests passing
- Docker containers start with new names (wp_app, wp_db, etc.)
- All module references updated
- All documentation updated
- Fly.io app deployed at https://workgroup-pulse.fly.dev/
- Fly.io database `workgroup-pulse-db` attached and working

---

## Repository Rename: productiveworkgroups → oostkit

The GitHub repository should be renamed to match the platform name (OOSTKit).

### When to Do This

After the app rename is complete and merged to main. This is a separate operation.

### Steps

#### 1. Rename on GitHub

- [ ] Go to repository **Settings → General → Repository name**
- [ ] Change `productiveworkgroups` → `oostkit`
- [ ] GitHub automatically sets up redirects from old URL

#### 2. Update Local Clone

```bash
# Rename local directory
cd /home/rossm/Projects
mv productiveworkgroups oostkit

# Update remote URL
cd oostkit
git remote set-url origin git@github.com:<username>/oostkit.git

# Verify
git remote -v
```

#### 3. Update Fly.io Configuration (DONE)

Fly.io has already been updated:
- App: `workgroup-pulse`
- Database: `workgroup-pulse-db`
- URL: https://workgroup-pulse.fly.dev/

Optional future: custom domain `pulse.oostkit.com`

#### 4. Update Documentation References

- [x] `apps/workgroup_pulse/SOLUTION_DESIGN.md` - update `productiveworkgroups.fly.dev` reference

### Notes

- GitHub Actions workflows don't reference the repo name directly, so CI/CD continues working
- Old GitHub URLs redirect automatically (bookmarks, links still work)
- Fly.io app name is independent of repo name
