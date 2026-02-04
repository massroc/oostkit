# Productive Tools Monorepo

Online tools supporting Open Systems Theory (OST) methodology. Includes team-facing workshop tools and facilitator toolkit for running OST engagements.

## Apps

| App | Description | Port | Status |
|-----|-------------|------|--------|
| [productive_workgroups](apps/productive_workgroups/) | Facilitation tools for workshops and team sessions | 4000 | Production |

## Development

### Prerequisites

- Docker and Docker Compose

### Quick Start

```bash
# Start all apps
docker compose up

# Or start a specific app
cd apps/productive_workgroups
docker compose up
```

### Project Structure

```
/
├── apps/                          # Individual applications
│   └── productive_workgroups/     # Workshop facilitation tool
├── docs/                          # Platform-wide documentation
├── .github/workflows/             # CI/CD pipelines (per-app)
├── docker-compose.yml             # Root orchestration
└── Makefile                       # Convenience commands
```

## Documentation

Platform-wide documentation lives in [`docs/`](docs/):

- [Product Vision](docs/product-vision.md) - Product lines, audiences, and strategic context
- [Architecture](docs/architecture.md) - Technical design, stack decisions, deployment
- [Referral Tool Requirements](docs/referral-tool-requirements.md) - PDW participant selection tool

### Adding a New App

1. Create directory: `apps/your_app_name/`
2. Add app-specific `docker-compose.yml` with prefixed service names
3. Create workflow file: `.github/workflows/your_app_name.yml`
4. Update root `docker-compose.yml` to include the new app

### CI/CD

Each app has its own workflow file with path filtering. Changes to an app only trigger CI for that app.

## License

Private
