# Portal

The OOSTKit Portal — landing page, authentication hub, and admin dashboard for the OOSTKit platform.

Built with Elixir/Phoenix LiveView and PostgreSQL, deployed on Fly.io.

## Tech Stack

- **Backend**: Elixir 1.17 / Phoenix 1.7 with LiveView
- **Shared Components**: `oostkit_shared` in-umbrella dependency (shared header bar, health checks)
- **Database**: PostgreSQL 16
- **Frontend**: Phoenix LiveView + Tailwind CSS
- **Deployment**: Fly.io (Sydney region)
- **CI/CD**: GitHub Actions

## Development Setup

### Prerequisites

- Docker and Docker Compose

### Quick Start

```bash
# Start development server (Phoenix + PostgreSQL)
docker compose up

# Access the app at http://localhost:4002
```

### Development Commands

```bash
# Start development environment
docker compose up

# Run tests
docker compose --profile test run --rm portal_test

# TDD mode (watches for file changes)
docker compose --profile tdd run --rm portal_test_watch

# Compile with warnings as errors
docker compose exec portal_app mix compile --warnings-as-errors

# Open IEx shell
docker compose exec portal_app iex -S mix

# Run database migrations
docker compose exec portal_app mix ecto.migrate

# Reset database
docker compose exec portal_app mix ecto.reset

# Run code quality checks
docker compose exec portal_app mix quality

# Format code
docker compose exec portal_app mix format
```

## Production Deployment

### Fly.io Resources

| Resource | Name | Region |
|----------|------|--------|
| App | `oostkit-portal` | Sydney (syd) |
| Database | `oostkit-portal-db` | Sydney (syd) |
| URL | https://oostkit.com | |

## Documentation

- [REQUIREMENTS.md](REQUIREMENTS.md) — Functional requirements
- [docs/ux-design.md](docs/ux-design.md) — UX design specification

## License

Private - All rights reserved.
