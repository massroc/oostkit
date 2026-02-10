# Platform Architecture

## Overview

**OOSTKit** (Online Open Systems Theory Kit) - a monorepo containing multiple applications supporting OST methodology. Each app is self-contained with its own tech stack, database, and deployment, while sharing common infrastructure where beneficial.

## Monorepo Structure

```
/
├── apps/                          # Individual applications
│   ├── portal/                    # OOSTKit Portal (landing page & auth hub)
│   ├── workgroup_pulse/           # Workgroup Pulse (6 Criteria workshop)
│   └── wrt/                       # Workshop Referral Tool
├── shared/                        # Shared assets across apps
│   └── tailwind.preset.js         # Design system tokens (colors, fonts, shadows)
├── docs/                          # Platform-wide documentation
├── .github/workflows/             # CI/CD pipelines (per-app)
├── docker-compose.yml             # Root orchestration
├── Makefile                       # Convenience commands
└── CLAUDE.md                      # AI assistant context
```

### Apps

| Product Name | Directory | Description |
|--------------|-----------|-------------|
| Portal | `apps/portal/` | Landing page & auth hub |
| Workgroup Pulse | `apps/workgroup_pulse/` | 6 Criteria for Productive Work |
| Workshop Referral Tool (WRT) | `apps/wrt/` | PDW participant selection |

### App Conventions

Each app in `apps/` should have:
- Self-contained codebase with its own dependencies
- `docker-compose.yml` with prefixed service names (e.g., `wp_app`, `wp_db`)
- Own CI workflow in `.github/workflows/<app_name>.yml` with path filtering
- Own deployment configuration (e.g., `fly.toml`)
- Own documentation (README, requirements, design docs)

### Naming Conventions

- Docker services: `<prefix>_<service>` (e.g., `wp_app`, `wp_db`, `wrt_app`, `wrt_db`)
- Ports: Each app gets unique port ranges to avoid conflicts
- Databases: Separate database per app

## Tech Stack

### Current: Elixir/Phoenix

Used for `workgroup_pulse` and likely future apps requiring:
- Real-time collaboration (LiveView, PubSub)
- WebSocket-based features
- Concurrent session handling

### Stack Selection Criteria

Choose tech stack based on app requirements:
- **Real-time collaborative**: Elixir/Phoenix with LiveView
- **Async workflow/CRUD**: Could be lighter weight, but stack consistency has value
- **Different stacks**: Supported by monorepo structure if genuinely needed

## Databases

### Strategy: Isolated Databases

Each app has its own database:
- Prevents coupling between apps
- Allows independent schema evolution
- Simplifies deployment and scaling

Shared services (e.g., future auth) would have their own database.

### Current Databases

| App | Dev Database | Test Database | Port |
|-----|--------------|---------------|------|
| portal | `portal_dev` | `portal_test` | 5436/5437 |
| workgroup_pulse | `workgroup_pulse_dev` | `workgroup_pulse_test` | 5432/5433 |
| wrt | `wrt_dev` | `wrt_test` | 5434/5435 |

## Shared Design System

All apps share a unified visual identity defined in `shared/tailwind.preset.js`:

- **Semantic color tokens**: `ok-purple`, `ok-green`, `ok-red`, `ok-gold`, `ok-blue` (branded), plus surface and text tokens (`bg-surface-wall`, `bg-surface-sheet`, `text-text-dark`)
- **Typography**: DM Sans (UI chrome) loaded via Google Fonts, with `font-brand` utility
- **Shadows**: `shadow-sheet` for card-like surfaces
- **Brand stripe**: Magenta-to-purple gradient bar below headers

Each app imports the preset in its `assets/tailwind.config.js` and can extend with app-specific tokens. All three apps (Pulse, WRT, and Portal) now have the design system fully applied. See `docs/design-system.md` for the full specification.

## Shared Infrastructure (Planned)

### Authentication

Implemented via Portal app (`apps/portal/`). Portal owns platform-wide authentication using a cross-app token model:

- **Portal login** sets a subdomain-scoped `_oostkit_token` cookie (domain configurable via `COOKIE_DOMAIN` env var, e.g., `.oostkit.com`)
- **Internal validation API** at `POST /api/internal/auth/validate` allows other apps to verify tokens. Protected by `INTERNAL_API_KEY` (shared secret via `ApiAuth` plug).
- **Consumer apps** (e.g., WRT) read the `_oostkit_token` cookie and call the Portal API to resolve the user. Results are cached in ETS with a 5-minute TTL.
- **Shared `SECRET_KEY_BASE`** across Portal and all consuming apps ensures cookie signing compatibility.
- **Mail delivery** uses a configurable `mail_from` address (supports Postmark sender signatures in production).

### Portal/Landing Page

Implemented in `apps/portal/` (Phase 1 complete, Phase 2 in progress):
- User authentication (password + magic link)
- Landing page with app cards (split by audience)
- Role system (Super Admin, Session Manager)
- Admin user management (`/admin/users` LiveView)
- Cross-app auth: subdomain cookie + internal validation API (Phase 2)

## Deployment

### Platform: Fly.io

Each app deploys independently:
- Own `fly.toml` configuration
- Own database instance
- Sydney region (primary)

### CI/CD

GitHub Actions with path filtering:
- Changes to `apps/workgroup_pulse/**` trigger only that app's CI
- Each app has own workflow file
- Deploys to Fly.io on merge to main

### Environment Configuration

- Development: Docker Compose (local)
- Production: Fly.io with secrets management
- Database URLs, secrets injected via environment

## Inter-App Communication

### Cross-App Authentication (Active)

Portal authenticates users and issues a signed `_oostkit_token` cookie scoped to the shared domain (`.oostkit.com`). Consumer apps validate tokens via Portal's internal API:

```
WRT (or other app)                        Portal
─────────────────                         ──────
1. Read _oostkit_token cookie
2. POST /api/internal/auth/validate  ──►  3. Verify token, return user JSON
   (Authorization: Bearer <API_KEY>)  ◄──  4. {id, email, role}
5. Cache result in ETS (5-min TTL)
6. Set :portal_user assign on conn
```

**Secrets required:**
- Portal: `INTERNAL_API_KEY`, `COOKIE_DOMAIN` (e.g., `.oostkit.com`)
- WRT: `PORTAL_API_KEY` (same value as Portal's `INTERNAL_API_KEY`), `PORTAL_API_URL`
- Both: must share the same `SECRET_KEY_BASE`

### Future Options

- **Event-based**: Message queue if apps need loose coupling
- **Direct API**: REST/GraphQL between services for non-auth use cases

Preference: Keep apps independent as long as possible. Add communication only when genuinely needed.

## Development Workflow

### Local Development

```bash
# Start specific app
cd apps/workgroup_pulse
docker compose up

# Or from root (starts all)
docker compose up
```

### Testing

```bash
cd apps/<app_name>
docker compose --profile test run --rm <prefix>_test
```

### Adding a New App

1. Create `apps/<app_name>/` with app code
2. Add `docker-compose.yml` with prefixed services
3. Create `.github/workflows/<app_name>.yml` with path filtering
4. Update root `docker-compose.yml` to include new app
5. Add to root README apps table
