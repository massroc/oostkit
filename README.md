# OOSTKit

Online Open Systems Theory toolkit. Team-facing workshop tools and facilitator toolkit for running OST engagements.

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
├── apps/
│   ├── portal/                    # OOSTKit Portal - Landing page & auth hub
│   ├── workgroup_pulse/           # Workgroup Pulse - 6 Criteria workshop
│   └── wrt/                       # Workshop Referral Tool
├── docs/                          # Platform-wide documentation
├── .github/workflows/             # CI/CD pipelines (per-app with path filtering)
├── docker-compose.yml             # Root orchestration
└── Makefile                       # Convenience commands
```

## Documentation

Platform-wide documentation lives in [`docs/`](docs/):

- [Product Vision](docs/product-vision.md) - Product lines, audiences, and strategic context
- [Architecture](docs/architecture.md) - Technical design, stack decisions, deployment
- [Roadmap](docs/ROADMAP.md) - Current status and future plans
- [Design System](docs/design-system.md) - Visual design specification
- [Portal Requirements](docs/portal-requirements.md) - Portal feature spec
- [WRT Requirements](docs/wrt-requirements.md) - Workshop Referral Tool requirements

### Adding a New App

1. Create directory: `apps/your_app_name/`
2. Add app-specific `docker-compose.yml` with prefixed service names
3. Create workflow file: `.github/workflows/your_app_name.yml`
4. Update root `docker-compose.yml` to include the new app

### CI/CD

Each app has its own workflow file with path filtering. Changes to an app only trigger CI for that app.

## License

Private
