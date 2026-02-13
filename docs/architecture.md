# Platform Architecture

## Overview

**OOSTKit** (Online Open Systems Theory Kit) - an Elixir umbrella project containing multiple applications supporting OST methodology. Each app has its own database and deployment, while sharing dependencies, build artifacts, and configuration through the umbrella structure.

## Monorepo Structure

```
/
├── mix.exs                        # Umbrella root (apps_path: "apps", named releases)
├── config/                        # Consolidated config (all apps)
│   ├── config.exs                 # Compile-time config (shared + per-app)
│   ├── dev.exs / test.exs / prod.exs
│   └── runtime.exs                # Runtime config (guarded per-release)
├── mix.lock                       # Unified lock file (all dependencies)
├── apps/                          # Umbrella child applications
│   ├── oostkit_shared/            # Shared Elixir component library (in_umbrella dep)
│   ├── portal/                    # OOSTKit Portal (landing page & auth hub)
│   ├── workgroup_pulse/           # Workgroup Pulse (6 Criteria workshop)
│   └── wrt/                       # Workshop Referral Tool
├── deps/                          # Shared dependencies (gitignored)
├── _build/                        # Shared build artifacts (gitignored)
├── shared/                        # Shared frontend assets across apps
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
| OOSTKit Shared | `apps/oostkit_shared/` | Shared Elixir component library |
| Portal | `apps/portal/` | Landing page & auth hub |
| Workgroup Pulse | `apps/workgroup_pulse/` | 6 Criteria for Productive Work |
| Workshop Referral Tool (WRT) | `apps/wrt/` | PDW participant selection |

### Umbrella Structure

The project uses an Elixir umbrella (`apps_path: "apps"` in root `mix.exs`):
- **Shared `deps/` and `_build/`** at the root -- all apps share compiled dependencies
- **Consolidated `config/`** at the root -- one config directory for all apps, with per-app sections guarded by app atom (e.g., `config :portal, ...`)
- **Unified `mix.lock`** at the root -- single lock file for all dependencies
- **Named releases** -- each app has its own release definition in root `mix.exs` (e.g., `portal`, `workgroup_pulse`, `wrt`)
- **In-umbrella dependencies** -- apps reference `oostkit_shared` with `in_umbrella: true` instead of relative path deps
- Changes to `oostkit_shared` automatically recompile in all apps -- no more stale `_build` issues

### App Conventions

Each app in `apps/` should have:
- `mix.exs` declaring it as an umbrella child (no `config/` or `mix.lock` -- those live at root)
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

Portal's database is expanding beyond user accounts to include:
- `tools` -- tool catalogue (12 tools with category grouping, read by dashboard, managed via admin kill switch)
- `interest_signups` -- email captures from coming-soon pages
- `user_tool_interests` -- registration tool interest data (user_id + tool_id join table)

## Shared Design System

All apps share a unified visual identity via two mechanisms:

**Frontend tokens** — `shared/tailwind.preset.js`:
- **Semantic color tokens**: `ok-purple`, `ok-green`, `ok-red`, `ok-gold`, `ok-blue` (branded), plus surface and text tokens (`bg-surface-wall`, `bg-surface-sheet`, `text-text-dark`)
- **Typography**: DM Sans (UI chrome) loaded via Google Fonts, with `font-brand` utility
- **Shadows**: `shadow-sheet` for card-like surfaces
- **Brand stripe**: Magenta-to-purple gradient bar below the header

**Shared Elixir library** — `apps/oostkit_shared/`:
- A shared Elixir library consumed by all apps as an in-umbrella dependency (`{:oostkit_shared, in_umbrella: true}`)
- **Phoenix components** (`OostkitShared.Components`) consumed by all apps:
  - `header_bar/1` — the consistent OOSTKit header: three-zone layout with `relative` nav — "OOSTKit" brand link on the left (configurable `:brand_url`), absolutely centered title (`pointer-events-none absolute inset-x-0 text-center font-brand text-2xl font-semibold`), and an `:actions` slot on the right for app-specific auth/user content
  - `header/1` — a page-level section header (`text-2xl font-bold`) with `:subtitle` and `:actions` slots, used for page titles across Portal and WRT
  - `icon/1` — Heroicon renderer (`<span class={[@name, @class]} />`)
  - `flash/1` — flash notice component with `:info` and `:error` variants
  - `flash_group/1` — standard flash group with client/server reconnection flashes
  - `show/2` and `hide/2` — JS command helpers for animated show/hide transitions
- **Portal auth** — cross-app authentication modules used by WRT (and future apps):
  - `OostkitShared.PortalAuthClient` — Finch HTTP client for validating Portal session tokens via `POST /api/internal/auth/validate`, with ETS cache (5-minute TTL)
  - `OostkitShared.Plugs.PortalAuth` — reads `_oostkit_token` cookie, validates via `PortalAuthClient`, sets `:portal_user` assign. Dev bypass assigns fake admin when Portal is unreachable.
  - `OostkitShared.Plugs.RequirePortalUser` — enforces authenticated Portal user, redirects to Portal login with `return_to` URL for unauthenticated requests
  - Configured via `config :oostkit_shared, :portal_auth` with `api_url`, `api_key`, `login_url`, and `finch` keys
- **Health checks** — `OostkitShared.HealthChecks` provides shared liveness/readiness logic. Each app's `HealthController` is a thin wrapper that delegates to the shared module with app-specific checks (repo, Oban, etc.)
- Each app's `CoreComponents` module contains only app-specific components (e.g., Pulse's `sheet`, `facilitator_timer`; WRT's `stat_card`, `callout`; Portal's `tool_card`, `footer_bar`). Common UI primitives that were duplicated across apps have been consolidated into the shared lib.
- `translate_error/1` remains per-app because each app's Petal Components config references its own `CoreComponents` module for error translation
- Import chain in each app's `*Web` module: selective Petal Components imports (excluding `PetalComponents.Icon` since shared `icon/1` replaces it) -> app `CoreComponents` -> `OostkitShared.Components`
- Dependencies: `phoenix_live_view`, `finch`, `jason`
- CI path filter: changes to `apps/oostkit_shared/**` trigger all three app workflows

Each app imports the Tailwind preset in its `assets/tailwind.config.js` (with content paths including the shared lib for Tailwind class scanning) and can extend with app-specific tokens. All three apps (Pulse, WRT, and Portal) now have the design system fully applied. See `docs/design-system.md` for the full specification.

## Shared Infrastructure

### Authentication

Implemented via Portal app (`apps/portal/`). Portal owns platform-wide authentication using a cross-app token model:

- **Portal login** sets a subdomain-scoped `_oostkit_token` cookie (domain configurable via `COOKIE_DOMAIN` env var, e.g., `.oostkit.com`)
- **Internal validation API** at `POST /api/internal/auth/validate` allows other apps to verify tokens. Protected by `INTERNAL_API_KEY` (shared secret via `ApiAuth` plug).
- **Consumer apps** (e.g., WRT) use the shared `OostkitShared.Plugs.PortalAuth` and `OostkitShared.Plugs.RequirePortalUser` plugs from `oostkit_shared` to read the `_oostkit_token` cookie and validate it via `OostkitShared.PortalAuthClient`. Results are cached in ETS with a 5-minute TTL. WRT delegates all authentication to Portal — it has no login pages or password-based auth of its own.
- **Shared `SECRET_KEY_BASE`** across Portal and all consuming apps ensures cookie signing compatibility.
- **Mail delivery** uses a configurable `mail_from` address (supports Postmark sender signatures in production).
- **Dev auto-login**: In development, Portal's `DevAutoLogin` plug auto-logs in as a dev super admin (`admin@oostkit.local`) on first visit and sets the `_oostkit_token` cookie, making all cross-app routes (WRT, Pulse) accessible without manual login. WRT's `PortalAuth` plug has a complementary dev bypass: when no cross-app cookie is present in dev mode, it assigns a fake dev admin user so WRT routes work even without Portal running.

### Portal

Implemented in `apps/portal/`. See [Portal UX Design](../apps/portal/docs/ux-design.md) for the comprehensive UX vision.

**Current state:**
- User authentication (password + magic link + password reset)
- Self-service registration (name + email + optional org, referral source, tool interests; magic link confirmation; users fully onboarded at registration)
- Role system (Super Admin, Session Manager)
- Cross-app auth: subdomain cookie + internal validation API
- Mail delivery: Swoosh configured to use Finch API client (not hackney) in production
- Marketing landing page (`/`) with hero, tool highlights, OST context, footer CTA
- Dashboard (`/home`) with DB-backed tool cards in a 3-column categorized grid (12 tools across Learning, Workshop Management, Team Workshops categories; three states: live, coming soon, maintenance)
- Registration form collects org, referral source, and tool interest checkboxes (no separate onboarding step)
- `tools` table in DB replacing hardcoded app config, seeded with 12 tools via data migration (ensures tools are available in all environments including production)
- `interest_signups` table for email capture from coming-soon pages and app detail pages
- `user_tool_interests` table for tool interest data collected at registration
- Coming-soon page (`/coming-soon`) with context-aware messaging and email capture form
- Three-zone header via shared `<.header_bar>` component from `OostkitShared.Components`: OOSTKit brand link (left), absolutely centered page title, Sign Up (`bg-white/10` frosted) / Log In buttons (right) pointing to real auth pages (`/users/register`, `/users/log-in`)
- Footer bar in root layout with links to About, Privacy, and Contact pages
- Sticky footer layout: root layout uses `flex min-h-screen flex-col` on body with `flex flex-1 flex-col` on main, ensuring footer stays at viewport bottom on short pages. Auth pages use flex centering; settings and admin pages use consistent `px-6 sm:px-8` horizontal padding.
- Static pages: About (`/about`), Privacy Policy (`/privacy`), Contact (`/contact`)
- Marketing landing page (`/`) with no redirect for logged-in users — header shows "Dashboard" link to `/home`
- Login page with "Welcome back" heading, magic link primary, password secondary, "Forgot your password?" link
- Password reset flow: forgot password page (`/users/forgot-password`) sends email with time-limited reset token, reset password page (`/users/reset-password/:token`) allows setting a new password
- Settings page restructured with section headers (Profile, Email, Password, Danger zone) separated by `border-t` dividers, using `space-y-10` for generous vertical rhythm. Profile editing (name, org), email change, password (add/change), and account deletion. Loads without requiring sudo mode; sudo checks in handlers for sensitive actions with graceful redirect to login if not in sudo mode. Referral source removed from settings (collected at registration only).
- Account deletion: users can delete their own account from settings, which deletes the user record and logs them out
- Admin routes (`/admin/*`) protected by a `require_super_admin` router pipeline (covers both LiveView and controller routes), plus LiveView `on_mount` hooks
- Admin dashboard (`/admin`) with stats cards and quick links
- Email signups admin (`/admin/signups`) with table listing, live search, delete, CSV export
- Tool management admin (`/admin/tools`) with status display and admin_enabled kill switch toggle
- Enhanced user management (`/admin/users`) with Registered date, Last Login, and Organisation columns
- App detail pages (`/apps/:id`) with richer layout, inline email capture for coming-soon tools (`POST /apps/:app_id/notify`)
- SEO/Open Graph meta tags (og:title, og:description, og:type, og:site_name, meta description) in root layout with per-page overrides
- Dev auto-login flow: auto-logs in as dev super admin on first visit, sets cross-app cookie, dev-only "Admin" button in header for manual re-login (`POST /dev/admin-login`)
- System status page (`/admin/status`) with a `Portal.StatusPoller` GenServer that polls app health endpoints (`/health`) and GitHub Actions CI status every 5 minutes. Results are broadcast via PubSub to a LiveView (`PortalWeb.Admin.StatusLive`) that updates connected admin sessions in real time. Shows health status (response time, up/down) and recent CI workflow runs for Portal, Pulse, and WRT. Uses the Req HTTP client. The poller is conditionally started in the supervision tree (disabled in test via `:start_status_poller` config).
- Rate limiting via PlugAttack (ETS-backed): login 5/min, magic link 3/min, password reset 3/min, registration 5/min, internal API 60/min, general 120/min per IP. Returns 429 with JSON error. Configurable enable/disable.
- Audit logging: append-only `audit_logs` table tracking admin actions (tool toggles, user CRUD, signup exports) with actor, action, entity, changes map, and IP address. `Portal.Audit` context provides `log/5`, `list_recent/1`, `list_for_entity/3`.

**Deferred:** Admin dashboard trends/charts.

**Data model:**
- `users` table -- email, name, role, organisation, referral_source, onboarding_completed (set true at registration), enabled
- `users_tokens` table -- session/magic link/reset password tokens (from phx.gen.auth, extended with `reset_password` context)
- `tools` table -- 12 tools with name, tagline, status, URL, audience, category, sort_order (per category), admin kill switch
- `interest_signups` table -- email captures from coming-soon and app detail pages
- `user_tool_interests` table -- registration tool interest (user_id + tool_id join table)
- `audit_logs` table -- append-only admin action log (actor_id, actor_email, action, entity_type, entity_id, changes map, ip_address)

**Environment variables:**
- `DATABASE_URL` -- PostgreSQL connection
- `SECRET_KEY_BASE` -- Phoenix secret (must match across all apps for cookie sharing)
- `PHX_HOST` -- Host for URL generation
- `PORTAL_SUPER_ADMIN_EMAIL` -- Initial super admin (for seeding)
- `COOKIE_DOMAIN` -- Subdomain cookie scope (e.g., `.oostkit.com`)
- `INTERNAL_API_KEY` -- Shared secret for internal API auth (used by WRT as `PORTAL_API_KEY`)
- `POSTMARK_API_KEY` -- Postmark API key for email delivery
- `MAIL_FROM` -- Configurable email from-address (e.g., `noreply@oostkit.com`)
- `PULSE_URL` -- Override Pulse URL in production (default: `https://pulse.oostkit.com`)
- `WRT_URL` -- Override WRT URL in production (default: `https://wrt.oostkit.com`)
- `GITHUB_TOKEN` -- (optional) GitHub personal access token for CI status polling; enables higher API rate limits and access to private repos
- `GITHUB_REPO` -- GitHub repository in `owner/repo` format for CI status polling (default: `rossm/oostkit`)

## Deployment

### Platform: Fly.io

Each app deploys independently:
- Own `fly.toml` configuration
- Own database instance
- Sydney region (primary)

### CI/CD

GitHub Actions with path filtering. CI runs from the umbrella root, compiling and testing the target app within the shared `deps/` and `_build/`:
- Changes to `apps/workgroup_pulse/**` trigger only that app's CI
- Changes to `config/**` trigger CI for all apps (shared config)
- Each app has own workflow file
- Deploys to Fly.io on merge to main (with retry: up to 3 attempts with exponential backoff)
- Creates/updates a GitHub issue labelled `deploy-failure` on genuine deploy failure (after all retries exhausted), with error log details and a link to the workflow run
- Post-deploy smoke test curls the app's `/health` endpoint with retries to verify successful deployment
- All apps use the monorepo root as Docker build context to access the umbrella's shared `config/`, `deps/`, and `_build/`
  - Production Dockerfiles compile from the umbrella root and build named releases (e.g., `mix release portal`)
  - Deploy command: `fly deploy --config apps/<app>/fly.toml --dockerfile apps/<app>/Dockerfile`

### Health Checks

All apps expose standardised health check endpoints (no authentication required). Health check logic is shared via `OostkitShared.HealthChecks` (`apps/oostkit_shared/`) — each app's `HealthController` is a thin wrapper that delegates to the shared module with app-specific checks (e.g., `check_database(Repo)`, `check_process(Oban)`).

| Endpoint | Purpose | Response |
|----------|---------|----------|
| `GET /health` | Liveness check | `200 {"status": "ok", "timestamp": "..."}` |
| `GET /health/ready` | Readiness check (DB connectivity) | `200 {"status": "ready", ...}` or `503` |

Used by:
- **Fly.io** HTTP service health checks (`fly.toml` → `path = "/health"`) to determine machine health
- **CI pipeline** post-deploy smoke test to verify each deployment succeeded

### Environment Configuration

- **Configuration**: Consolidated in root `config/` directory (all apps share one config tree). Runtime config (`config/runtime.exs`) uses release-name guards to apply per-app settings in production.
- **Development**: Docker Compose (local). Each app's `docker-compose.yml` mounts the root project as build context so all apps share `deps/`, `_build/`, and `config/`.
- **Production**: Fly.io with secrets management. Named releases (e.g., `MIX_ENV=prod mix release portal`) ensure only the target app starts.
- Database URLs, secrets injected via environment

### Tool URL and Status Resolution

Portal's tool catalogue stores production URLs and statuses in the database. Two config keys allow per-environment overrides so that links and statuses resolve correctly in dev, test, and production:

- **`config :portal, :tool_urls`** — Maps tool IDs to environment-specific URLs:
  - **Dev/test:** `localhost` ports (Pulse → `http://localhost:4000`, WRT → `http://localhost:4001`)
  - **Production:** Defaults to production subdomain URLs, overridable via `PULSE_URL` and `WRT_URL` env vars

- **`config :portal, :tool_status_overrides`** — Maps tool IDs to status strings (e.g., `"live"`). Allows a tool to appear as "live" in development even if its database status is "coming_soon". Used in `dev.exs` to mark WRT as live locally (since WRT is live for local development but not yet in production).

The `Portal.Tools` context applies both overrides transparently via `apply_config_overrides/1`, which is piped through all query functions (`list_tools`, `get_tool`, `get_tool!`). The `list_tools_grouped/0` function additionally sorts live tools to the top within each category. Any `@tool.url` or `@tool.default_status` reference in templates automatically resolves to the correct environment-specific value.

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

**Cross-app login redirect:** When an unauthenticated user hits a tool app (e.g., WRT), the app redirects to Portal's login page with a `return_to` query param containing the user's current URL:

```
Tool app (WRT)                            Portal
──────────                                ──────
1. User hits /org/acme/manage
2. RequirePortalUser: no portal_user
3. Redirect to Portal login ──────────►  4. store_external_return_to plug reads return_to param
   ?return_to=http://wrt:4001/org/acme     5. Validates URL origin against :tool_urls config
                                           6. Stores in session as :user_return_to
                                           7. User logs in
                                           8. redirect(external: stored_url) ──► back to tool
```

Portal validates `return_to` URLs by comparing scheme + host + port against its configured `:tool_urls` map. Only URLs matching a known tool origin are accepted, preventing open redirects. Invalid URLs are silently ignored and Portal falls back to its default post-login path (`/home`).

**Secrets required:**
- Portal: `INTERNAL_API_KEY`, `COOKIE_DOMAIN` (e.g., `.oostkit.com`)
- Consumer apps (WRT): `PORTAL_API_KEY` (same value as Portal's `INTERNAL_API_KEY`), `PORTAL_API_URL`, `PORTAL_LOGIN_URL` — configured under `config :oostkit_shared, :portal_auth` in runtime.exs
- Both: must share the same `SECRET_KEY_BASE`

**Dev mode bypass:** In development, Portal auto-sets the `_oostkit_token` cookie via `DevAutoLogin`. If a consumer app (e.g., WRT) is running without Portal (or the cookie is absent), the shared `OostkitShared.Plugs.PortalAuth` plug assigns a fake dev super admin so all routes work without requiring Portal to be running.

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

1. Create `apps/<app_name>/` as an umbrella child (`mix new apps/<app_name>` or manually with `in_umbrella: true` deps)
2. Add app-specific config sections to root `config/` files (config.exs, dev.exs, test.exs, prod.exs, runtime.exs)
3. Add a named release in root `mix.exs` under `releases/0`
4. Add `docker-compose.yml` with prefixed services
5. Create `.github/workflows/<app_name>.yml` with path filtering
6. Update root `docker-compose.yml` to include new app
7. Add to root README apps table
