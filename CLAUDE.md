# Claude Code Instructions

This file contains instructions for AI assistants working on this monorepo.

## Monorepo Structure

This is a monorepo containing multiple applications:

```
/
├── apps/
│   ├── portal/            # OOSTKit Portal - Landing page and auth hub (Elixir/Phoenix)
│   ├── workgroup_pulse/   # Workgroup Pulse - 6 Criteria workshop (Elixir/Phoenix)
│   └── wrt/               # Workshop Referral Tool (Elixir/Phoenix)
├── .github/workflows/     # CI/CD pipelines (per-app with path filtering)
├── docker-compose.yml     # Root orchestration (includes all apps)
└── Makefile               # Convenience commands
```

Each app is self-contained with its own:
- `docker-compose.yml` - App-specific services
- `Dockerfile` / `Dockerfile.dev` - Container definitions
- `fly.toml` - Deployment configuration
- README, tests, etc.

## Development Environment

**IMPORTANT: Elixir/Phoenix runs in Docker, not locally.**

Do NOT attempt to run `mix`, `elixir`, or `iex` commands directly. All Elixir commands must be run through Docker.

### Working with Apps

Always work from the app directory:

```bash
cd apps/workgroup_pulse
```

### Common Commands (Workgroup Pulse)

```bash
# From apps/workgroup_pulse directory:

# Start the app
docker compose up

# Compile the project
docker compose exec wp_app mix compile

# Compile with warnings as errors
docker compose exec wp_app mix compile --warnings-as-errors

# Run tests
docker compose --profile test run --rm wp_test

# Run tests in TDD mode (watches for file changes)
docker compose --profile tdd run --rm wp_test_watch

# Run a specific test file
docker compose --profile test run --rm wp_test mix test test/path/to/test.exs

# Open IEx shell
docker compose exec wp_app iex -S mix

# Run database migrations
docker compose exec wp_app mix ecto.migrate

# Reset database (drop, create, migrate, seed)
docker compose exec wp_app mix ecto.reset

# Run code quality checks
docker compose exec wp_app mix quality

# Format code
docker compose exec wp_app mix format

# View logs
docker compose logs -f wp_app

# Build static assets (CSS/JS) for committing
# IMPORTANT: Do NOT use `mix assets.deploy` — it digests files and empties
# the un-digested copies. The repo tracks un-digested dev builds.
docker compose exec wp_app mix tailwind workgroup_pulse   # Build CSS
docker compose exec wp_app mix esbuild workgroup_pulse    # Build JS
# Then copy from container to host:
docker compose cp wp_app:/app/priv/static/assets/app.css priv/static/assets/app.css
docker compose cp wp_app:/app/priv/static/assets/app.js priv/static/assets/app.js
```

### Service Names (Workgroup Pulse)

- `wp_app` - The Phoenix application container
- `wp_db` - PostgreSQL database (development)
- `wp_db_test` - PostgreSQL database (test)
- `wp_test` - Test runner container (profile: test)
- `wp_test_watch` - TDD watcher container (profile: tdd)

### Common Commands (WRT - Workshop Referral Tool)

```bash
# From apps/wrt directory:

# Start the app
docker compose up

# Compile the project
docker compose exec wrt_app mix compile

# Compile with warnings as errors
docker compose exec wrt_app mix compile --warnings-as-errors

# Run tests
docker compose --profile test run --rm wrt_test

# Run tests in TDD mode (watches for file changes)
docker compose --profile tdd run --rm wrt_test_watch

# Run a specific test file
docker compose --profile test run --rm wrt_test mix test test/path/to/test.exs

# Open IEx shell
docker compose exec wrt_app iex -S mix

# Run database migrations
docker compose exec wrt_app mix ecto.migrate

# Migrate all tenant schemas
docker compose exec wrt_app mix wrt.migrate_tenants

# Reset database (drop, create, migrate, seed)
docker compose exec wrt_app mix ecto.reset

# Run code quality checks
docker compose exec wrt_app mix quality

# Format code
docker compose exec wrt_app mix format

# View logs
docker compose logs -f wrt_app
```

### Service Names (WRT)

- `wrt_app` - The Phoenix application container (port 4001)
- `wrt_db` - PostgreSQL database (development, port 5434)
- `wrt_db_test` - PostgreSQL database (test, port 5435)
- `wrt_test` - Test runner container (profile: test)
- `wrt_test_watch` - TDD watcher container (profile: tdd)

### Common Commands (Portal)

```bash
# From apps/portal directory:

# Start the app
docker compose up

# Compile the project
docker compose exec portal_app mix compile

# Compile with warnings as errors
docker compose exec portal_app mix compile --warnings-as-errors

# Run tests
docker compose --profile test run --rm portal_test

# Run tests in TDD mode (watches for file changes)
docker compose --profile tdd run --rm portal_test_watch

# Run a specific test file
docker compose --profile test run --rm portal_test mix test test/path/to/test.exs

# Open IEx shell
docker compose exec portal_app iex -S mix

# Run database migrations
docker compose exec portal_app mix ecto.migrate

# Reset database (drop, create, migrate, seed)
docker compose exec portal_app mix ecto.reset

# Run code quality checks
docker compose exec portal_app mix quality

# Format code
docker compose exec portal_app mix format

# View logs
docker compose logs -f portal_app
```

### Service Names (Portal)

- `portal_app` - The Phoenix application container (port 4002)
- `portal_db` - PostgreSQL database (development, port 5436)
- `portal_db_test` - PostgreSQL database (test, port 5437)
- `portal_test` - Test runner container (profile: test)
- `portal_test_watch` - TDD watcher container (profile: tdd)

## Testing (TDD Required)

**This project strictly follows Test-Driven Development (TDD).** When implementing new features or making changes:

1. **Run existing tests first** to verify current state
2. **Write new tests** for any new functionality before or alongside implementation
3. **Update existing tests** if behavior changes
4. **Run tests again** to verify nothing broke and new tests pass
5. **All tests must pass** before considering work complete

### TDD Guidelines

- Every new function in contexts should have corresponding unit tests
- Every new LiveView event handler should have integration tests
- When modifying existing behavior, update the relevant tests to match
- Test edge cases and error conditions, not just happy paths
- Use the existing test files as patterns for new tests

## CI/CD

CI uses a **reusable workflow pattern** for consistency across apps:

- `.github/workflows/_elixir-ci.yml` - Shared CI logic (test, dialyzer, deploy)
- `.github/workflows/portal.yml` - Thin caller for Portal
- `.github/workflows/workgroup_pulse.yml` - Thin caller for Workgroup Pulse
- `.github/workflows/wrt.yml` - Thin caller for WRT

Each app workflow has path filtering so changes to one app don't trigger CI for others. Updates to `_elixir-ci.yml` trigger CI for all apps.

## Adding a New App

1. Create `apps/your_app_name/` directory
2. Add app-specific `docker-compose.yml` with prefixed service names (e.g., `ya_app`, `ya_db`)
3. Create CI workflow: `.github/workflows/your_app_name.yml` that calls `_elixir-ci.yml`:
   ```yaml
   jobs:
     ci:
       uses: ./.github/workflows/_elixir-ci.yml
       with:
         app_name: your_app
         app_path: apps/your_app_name
         database_name: your_app_test
       secrets: inherit
   ```
4. Update root `docker-compose.yml` to include the new app
5. Add app-specific section to this CLAUDE.md with commands

## Documentation

Each app maintains its own documentation:
- `apps/<app>/README.md` - App overview and setup
- `apps/<app>/REQUIREMENTS.md` - Functional requirements (if applicable)
- `apps/<app>/SOLUTION_DESIGN.md` - Technical architecture (if applicable)
- `apps/<app>/TECHNICAL_SPEC.md` - Implementation specification (if applicable)
- `apps/<app>/docs/ux-design.md` - UX design specification (if applicable)
- `apps/<app>/docs/ux-implementation.md` - UX implementation detail (if applicable)

Platform-wide documentation lives in `docs/`:
- [Product Vision](docs/product-vision.md)
- [Architecture](docs/architecture.md)
- [Portal Requirements](docs/portal-requirements.md)
- [Portal Implementation Plan](docs/portal-implementation-plan.md)
- [WRT Requirements](docs/wrt-requirements.md)

### Documentation-First Shipping (CRITICAL)

**Before creating a commit or PR via `/ship`, update documentation first.** This is the first step in the shipping process, before staging code changes.

1. **REQUIREMENTS.md** — Update if product behaviour changed
2. **SOLUTION_DESIGN.md** — Update if architecture or design decisions changed
3. **TECHNICAL_SPEC.md** — Update if implementation details changed (components, state, handlers)
4. **docs/ux-design.md** — Update if design principles, visual design, or accessibility changed
5. **docs/ux-implementation.md** — Update if CSS systems, JS hooks, or UI components changed
6. **README.md** — Update if setup instructions, commands, or usage patterns changed

Only update docs for the affected app(s). Skip a doc file if the changes are truly irrelevant to it (e.g., a pure CSS tweak doesn't need a SOLUTION_DESIGN.md update). Use judgment, but err on the side of updating.

### Documentation Guidelines

- Document new API functions with `@doc` annotations
- Update app README if setup or usage instructions change
- Keep documentation concise but comprehensive

## Code Style

- Elixir projects use `mix format` for code formatting
- Run formatting through Docker (see commands above)
- Compilation warnings should be treated as errors in CI

## Git Workflow (CRITICAL)

**NEVER push directly to main.** The main branch has protection enabled requiring pull requests.

### Committing Changes

When the user asks to "commit" or "save" changes:
1. **Update documentation first** - see [Documentation-First Shipping](#documentation-first-shipping-critical) above
2. **Always use `/ship`** - never use manual `git add`, `git commit`, `git push origin main`
3. The `/ship` skill handles creating branches and PRs properly

### Monorepo PR Guidelines

When creating PRs in this monorepo, consider what files are changed:

| Changed Files | PR Scope | Notes |
|--------------|----------|-------|
| Only `apps/portal/**` | Portal only | CI runs portal workflow |
| Only `apps/workgroup_pulse/**` | Pulse only | CI runs pulse workflow |
| Only `apps/wrt/**` | WRT only | CI runs WRT workflow |
| `CLAUDE.md`, `.gitignore`, root configs | Shared/infrastructure | Affects all apps |
| `.github/workflows/_elixir-ci.yml` | CI infrastructure | Triggers ALL app workflows |
| Multiple apps | Split into separate PRs | One PR per app when possible |

### Branch Naming

Use descriptive branch names with app prefix when app-specific:
- `feature/portal-auth` - Portal-specific feature
- `feature/wrt-tenants` - WRT-specific feature
- `fix/shared-gitignore` - Shared infrastructure fix
- `docs/update-readme` - Documentation changes

### Concurrent Work on Different Apps

**Safe to work concurrently** on different apps (e.g., one session on portal, another on wrt).
PRs can merge independently without rebasing, as long as there are no file conflicts.

Branch protection uses `strict: false` to enable this - PRs don't need to be up-to-date
with main before merging.

### Handling Merge Conflicts

If GitHub shows "This branch has conflicts", resolve before merging:

```bash
git fetch origin main
git merge origin/main
# Resolve conflicts in editor
git add <resolved-files>
git commit
git push
```

**Minimize conflicts** by keeping changes to shared files (CLAUDE.md, .gitignore, root configs)
small and merging quickly.
