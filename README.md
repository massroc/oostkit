# OOSTKit

Online Open Systems Theory toolkit. An Elixir umbrella project containing team-facing workshop tools and facilitator toolkit for running OST engagements.

## Apps

| App | Product Name | Description | Port | Status |
|-----|--------------|-------------|------|--------|
| [portal](apps/portal/) | OOSTKit Portal | Landing page & auth hub | 4002 | Production |
| [workgroup_pulse](apps/workgroup_pulse/) | Workgroup Pulse | 6 Criteria for Productive Work workshop | 4000 | Production |
| [wrt](apps/wrt/) | Workshop Referral Tool | PDW participant selection | 4001 | Production |

## Development

### Prerequisites

- Docker and Docker Compose

### Quick Start

```bash
# Start all apps
docker compose up

# Or start a specific app
cd apps/workgroup_pulse
docker compose up
```

### Project Structure

```
/
├── mix.exs                        # Umbrella root (apps_path: "apps", named releases)
├── config/                        # Consolidated config (all apps)
│   ├── config.exs                 # Compile-time config (shared + per-app)
│   ├── dev.exs / test.exs / prod.exs
│   └── runtime.exs                # Runtime config (guarded per-release)
├── mix.lock                       # Unified lock file
├── apps/
│   ├── oostkit_shared/            # Shared Elixir component library (in_umbrella dep)
│   ├── portal/                    # OOSTKit Portal - Landing page & auth hub
│   ├── workgroup_pulse/           # Workgroup Pulse - 6 Criteria workshop
│   └── wrt/                       # Workshop Referral Tool
├── deps/                          # Shared dependencies (gitignored)
├── _build/                        # Shared build artifacts (gitignored)
├── docs/                          # Platform-wide documentation
├── .github/workflows/             # CI/CD pipelines (per-app with path filtering)
├── docker-compose.yml             # Root orchestration
└── Makefile                       # Convenience commands
```

All apps share `deps/`, `_build/`, and `config/` through the umbrella structure. Each app's `mix.exs` declares it as an umbrella child (no per-app `config/` or `mix.lock`).

## Documentation

Platform-wide documentation lives in [`docs/`](docs/):

- [Product Vision](docs/product-vision.md) - Product lines, audiences, and strategic context
- [Architecture](docs/architecture.md) - Technical design, stack decisions, deployment
- [Roadmap](docs/ROADMAP.md) - Current status and future plans
- [Design System](docs/design-system.md) - Visual design specification
- [Portal Requirements](apps/portal/REQUIREMENTS.md) - Portal feature spec
- [WRT Requirements](apps/wrt/REQUIREMENTS.md) - Workshop Referral Tool requirements
- [Pulse Requirements](apps/workgroup_pulse/REQUIREMENTS.md) - Workgroup Pulse requirements

### Adding a New App

1. Create umbrella child: `apps/your_app_name/` with `in_umbrella: true` deps in its `mix.exs`
2. Add app-specific config sections to root `config/` files
3. Add a named release in root `mix.exs`
4. Add app-specific `docker-compose.yml` with prefixed service names
5. Create workflow file: `.github/workflows/your_app_name.yml`
6. Update root `docker-compose.yml` to include the new app

### CI/CD

Each app has its own workflow file with path filtering. Changes to an app only trigger CI for that app.

## License

Private
