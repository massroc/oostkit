# Claude Code Instructions

This file contains instructions for AI assistants working on this monorepo.

## Monorepo Structure

This is a monorepo containing multiple applications:

```
/
├── apps/
│   └── productive_workgroups/   # Workshop facilitation tool (Elixir/Phoenix)
├── .github/workflows/           # CI/CD pipelines (per-app with path filtering)
├── docker-compose.yml           # Root orchestration (includes all apps)
└── Makefile                     # Convenience commands
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
cd apps/productive_workgroups
```

### Common Commands (Productive Workgroups)

```bash
# From apps/productive_workgroups directory:

# Start the app
docker compose up

# Compile the project
docker compose exec pw_app mix compile

# Compile with warnings as errors
docker compose exec pw_app mix compile --warnings-as-errors

# Run tests
docker compose --profile test run --rm pw_test

# Run tests in TDD mode (watches for file changes)
docker compose --profile tdd run --rm pw_test_watch

# Run a specific test file
docker compose --profile test run --rm pw_test mix test test/path/to/test.exs

# Open IEx shell
docker compose exec pw_app iex -S mix

# Run database migrations
docker compose exec pw_app mix ecto.migrate

# Reset database (drop, create, migrate, seed)
docker compose exec pw_app mix ecto.reset

# Run code quality checks
docker compose exec pw_app mix quality

# Format code
docker compose exec pw_app mix format

# View logs
docker compose logs -f pw_app
```

### Service Names (Productive Workgroups)

- `pw_app` - The Phoenix application container
- `pw_db` - PostgreSQL database (development)
- `pw_db_test` - PostgreSQL database (test)
- `pw_test` - Test runner container (profile: test)
- `pw_test_watch` - TDD watcher container (profile: tdd)

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

Each app has its own workflow file with path filtering:
- `.github/workflows/productive_workgroups.yml` - Runs only when `apps/productive_workgroups/**` changes

Changes to one app do not trigger CI for other apps.

## Adding a New App

1. Create `apps/your_app_name/` directory
2. Add app-specific `docker-compose.yml` with prefixed service names (e.g., `ya_app`, `ya_db`)
3. Create CI workflow: `.github/workflows/your_app_name.yml` with path filtering
4. Update root `docker-compose.yml` to include the new app
5. Add app-specific section to this CLAUDE.md with commands

## Documentation

Each app maintains its own documentation:
- `apps/<app>/README.md` - App overview and setup
- `apps/<app>/REQUIREMENTS.md` - Functional requirements (if applicable)
- `apps/<app>/SOLUTION_DESIGN.md` - Technical architecture (if applicable)

### Documentation Guidelines

- Document new API functions with `@doc` annotations
- Update app README if setup or usage instructions change
- Keep documentation concise but comprehensive

## Code Style

- Elixir projects use `mix format` for code formatting
- Run formatting through Docker (see commands above)
- Compilation warnings should be treated as errors in CI
