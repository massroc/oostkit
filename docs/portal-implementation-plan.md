# Portal Implementation Plan

This document outlines the implementation approach for the OOSTKit portal, broken into phases with concrete tasks.

## Overview

The portal is a Phoenix application that serves as:
- Marketing landing page (`/`) and tool dashboard (`/home`)
- Authentication hub for the platform (facilitators only)
- Admin hub for platform management (tool status, email signups, users)
- Coming-soon gate with email capture for features not yet live

**Location:** `apps/portal/`

See also: [Portal UX Design](../apps/portal/docs/ux-design.md) for detailed design specifications.

---

## Phase 1: Foundation (Complete)

### 1.1 Project Setup

**Task 1.1.1: Create Phoenix app**
- Generate new Phoenix app: `mix phx.new portal --no-mailer --no-dashboard`
- Configure for monorepo structure
- Set up basic folder structure

**Task 1.1.2: Docker configuration**
- Create `Dockerfile` and `Dockerfile.dev`
  - Production `Dockerfile` uses **monorepo root as build context** (paths like `COPY apps/portal/mix.exs`)
  - Includes `COPY shared /shared` to access design system Tailwind preset during asset compilation
- Create `docker-compose.yml` with services:
  - `portal_app` (port 4002)
  - `portal_db` (port 5436)
  - `portal_db_test` (port 5437)
  - `portal_test` (profile: test)
  - `portal_test_watch` (profile: tdd)
- Follow patterns from existing apps

**Task 1.1.3: CI/CD workflow**
- Create `.github/workflows/portal.yml` calling `_elixir-ci.yml`
- Add path filtering for `apps/portal/**`
- Configure deployment to Fly.io (enabled)
- Add `.dockerignore` to exclude other apps from build context

**Task 1.1.4: Development tooling**
- Configure `mix format`
- Add `mix quality` alias (credo, dialyzer if used)
- Update root `docker-compose.yml` to include portal
- Update `CLAUDE.md` with portal commands

### 1.2 Landing Page

**Task 1.2.1: App configuration** (superseded by Phase A -- tools table in DB)
- ~~Create `config/apps.yml` for tool metadata~~ → replaced by `tools` database table
- See Phase A, step A1 for the new tools table with 11 seeded tools

**Task 1.2.2: Landing page layout** (superseded by Phase A)
- ~~Split-view layout~~ → replaced by two-experience model:
  - Marketing landing page at `/` (see Phase A, step A7)
  - Dashboard at `/home` with vertical tool card stack (see Phase A, step A6)
- No audience grouping on dashboard -- flat list of 11 tools

**Task 1.2.3: ~~Placeholder branding~~ OOSTKit design system applied**
- ~~Simple text logo "OOSTKit"~~ Branded navigation header with `bg-ok-purple-900`
- ~~Basic color palette (can use Tailwind defaults initially)~~ Full semantic token palette via shared Tailwind preset (ok-purple, ok-green, ok-red, ok-gold, ok-blue)
- ~~Consistent typography~~ DM Sans brand font loaded via Google Fonts, `font-brand` utility class
- Brand stripe (magenta-to-purple gradient) below header
- Surface tokens (`bg-surface-wall`, `bg-surface-sheet`, `bg-surface-sheet-secondary`) for backgrounds
- Text tokens (`text-text-dark`) for headings

**Task 1.2.4: App detail pages**
- Route: `/apps/:app_id`
- Display full description from config
- "Launch" button linking to app URL
- Back link to landing page

### 1.3 Authentication

**Task 1.3.1: Generate auth scaffolding**
- Run `mix phx.gen.auth Accounts User users`
- Customize for our user model needs

**Task 1.3.2: User roles**
- Add `role` field to users: `super_admin`, `session_manager`
- Add migration for role field
- Create role-based authorization helpers

**Task 1.3.3: Login/logout UI**
- Login page at `/login`
- Logout functionality
- Session management
- "Login" link in header (when not authenticated)
- User menu in header (when authenticated)

**Task 1.3.4: Super admin bootstrap**
- Seed file or mix task to create initial super admin
- `mix portal.create_super_admin email@example.com`

### 1.4 Account Management

**Task 1.4.1: Admin routes**
- `/admin` - Admin dashboard (super admin only)
- `/admin/users` - User list
- `/admin/users/new` - Create user
- `/admin/users/:id` - View/edit user

**Task 1.4.2: User CRUD**
- List all users (with role filter)
- Create new session manager account
- Edit user details
- Disable/enable user accounts
- Password reset capability

**Task 1.4.3: Authorization**
- Plug to restrict admin routes to super_admin role
- Clear error messages for unauthorized access

### 1.5 Shared Header Component

**Task 1.5.1: Header component**
- OOSTKit logo (links to landing page)
- Login/user menu
- Clean, minimal design
- Responsive (mobile-friendly)

**Task 1.5.2: Shared styles documentation**
- Document the header HTML structure
- Document CSS classes used
- Create guide for other apps to implement matching header

---

## Phase 2: Unified Experience (Complete)

### 2.1 Subdomain & Cookie Setup

**Task 2.1.1: Domain configuration**
- Configure domain (once registered)
- Set up subdomains: portal, pulse, wrt
- SSL certificates for all subdomains

**Task 2.1.2: Cross-subdomain cookies** (done)
- Session cookie domain is runtime-configurable via `COOKIE_DOMAIN` env var (e.g., `.oostkit.com`)
- Portal writes `_oostkit_token` cookie on login, deletes on logout
- All apps sharing the same `SECRET_KEY_BASE` can read the cookie

### 2.2 WRT Auth Migration

**Task 2.2.1: Auth token/session sharing** (done)
- Portal sets `_oostkit_token` cookie (subdomain-scoped, signed)
- Internal API endpoint `POST /api/internal/auth/validate` for cross-app validation
- Protected by `ApiAuth` plug requiring `Authorization: Bearer <INTERNAL_API_KEY>`
- Returns user `{id, email, role}` on success

**Task 2.2.2: WRT integration** (done - transitional)
- Added `PortalAuthClient` (Finch HTTP client with ETS cache, 5-min TTL)
- Added `PortalAuth` plug (reads `_oostkit_token`, validates via client, sets `:portal_user` assign)
- Added `RequirePortalOrWrtSuperAdmin` plug (transitional: accepts either Portal super_admin or WRT's existing session auth)
- Split admin routes: auth routes (login/logout) separated from protected routes (dashboard/orgs)
- Removed controller-level `RequireSuperAdmin` plug from dashboard and org controllers (now handled by router pipeline)
- Config additions: `portal_api_url`, `portal_api_key`, `portal_login_url`

**Task 2.2.3: Migration path**
- Transitional approach: `RequirePortalOrWrtSuperAdmin` accepts both auth methods during migration
- WRT's existing super admin login still works alongside Portal auth
- Future: remove WRT's built-in admin auth once all admins use Portal

### 2.3 Shared Header Integration

**Task 2.3.1: Extract shared styles** (done)
- Shared Tailwind preset at `shared/tailwind.preset.js`
- All apps import the preset and share design tokens

**Task 2.3.2: Update Workgroup Pulse** (done)
- Shared header applied via design system
- "Home" link to portal

**Task 2.3.3: Update WRT** (done)
- Shared header applied via design system
- "Home" link to portal
- Display login state from portal session (via `:portal_user` assign)

---

## New Rollout: Phase A -- Foundation + Public Face

Gets the new public experience live. Replaces the current landing page. This is the priority.

**Task A1: Tools table + seed data**
- DB migration creating `tools` table: id (text), name, tagline, description, url, audience, default_status, admin_enabled (boolean), sort_order (integer)
- Seed all 11 tools: Workgroup Pulse (live), WRT, Search Conference, Team Kick-off, Team Design, Org Design, Skill Matrix, DP1 Briefing, DP2 Briefing, Collaboration Designer, Org Cadence (all coming_soon)
- Replaces hardcoded app config

**Task A2: Interest signups table**
- DB migration for `interest_signups` table: id (uuid), name, email (unique), context (text), inserted_at
- Stores email captures from coming-soon page

**Task A3: Route restructure**
- Current landing page moves to `/home` (dashboard)
- New marketing page at `/`
- `/coming-soon` route added
- Logged-in users visiting `/` auto-redirect to `/home`

**Task A4: Coming-soon page**
- Context-aware messaging via query params (`?context=signup`, `?context=login`, `?context=tool&name=WRT`)
- Email capture form (name + email)
- Success state replaces form
- Sign Up / Log In buttons in header now point here

**Task A5: Header redesign**
- Three-zone layout: [Brand + Context] [Centre Nav] [User/Auth]
- Left: OOSTKit wordmark, breadcrumb app name when inside an app
- Centre: "Home" link to `/home`
- Right: Sign Up + Log In (anonymous) / User menu (authenticated) / Admin link (super admin)

**Task A6: Dashboard (`/home`)**
- Tool cards reading from `tools` DB table
- Three card states (live & open, coming soon, live & locked)
- Vertical stack, 11 cards
- Warm, collegial tone

**Task A7: Marketing landing page (`/`)**
- Hero section with bold headline, CTAs
- "What's in the Kit" tool showcase
- OST context paragraph
- Footer with email capture and auth buttons
- Bold, aspirational marketing tone

## New Rollout: Phase B -- Admin Hub

Operational control panel for platform management.

**Task B1: Admin dashboard (`/admin`)**
- Stats cards: email signup count, registered users, active users (last 30 days), tool interest breakdown
- Quick links to sub-pages

**Task B2: Email signups admin (`/admin/signups`)**
- Table: name, email, context, date
- CSV export, delete individual entries, search/filter

**Task B3: Tool management admin (`/admin/tools`)**
- Table/cards per tool: name, default status, admin override toggle (kill switch), effective status, URL
- Kill switch: disable any tool instantly without a deploy

**Task B4: Enhanced user management**
- Add columns: organisation (from onboarding), last login
- View onboarding data (referral source, tool interests)

## New Rollout: Phase C -- Auth & Onboarding

When ready for first facilitator users.

**Task C1: User profile fields**
- DB migration: add organisation, referral_source, onboarding_completed to users
- New `user_tool_interests` join table

**Task C2: Registration flow update**
- Email + name form (no password at registration)
- Magic link confirmation flow
- Facilitator-focused messaging: "Start running workshops with OOSTKit"

**Task C3: Login page messaging**
- "Welcome back" heading
- Magic link as primary login method
- Password as secondary (below, visually secondary)

**Task C4: Settings page update**
- Add name, organisation, referral source editing
- Password framed as "Add a password" if not set

**Task C5: First-visit onboarding**
- Dashboard card (not modal): org, referral source, tool interest checkboxes
- Dismissable, data saved to user profile
- Appears on first visit to `/home` after registration

**Task C6: Flip the switch**
- Sign Up / Log In buttons change from `/coming-soon` to real auth pages

## New Rollout: Phase D -- Polish & Detail

Enhancements once core platform is running.

**Task D1: App detail page enhancements**
- Screenshots, visual walkthroughs per tool

**Task D2: Inline email capture on detail pages**
- For coming-soon tools on their `/apps/:id` pages

**Task D3: SEO & social sharing**
- Open Graph tags, meta descriptions, clean titles

**Task D4: Header integration in Pulse/WRT**
- Breadcrumb app name in shared header across apps

**Task D5: Admin dashboard trends**
- Charts and time-series once there's enough data

## Future: Enhanced Features

### Content Expansion
- "Learn about OST" section (`/learn`)
- Richer app pages with FAQ sections

### Billing
- Platform subscription integration (one price unlocks all paid tools)
- Payment provider integration
- Subscription management

### Analytics
- Page view and tool launch tracking
- Admin analytics dashboard

---

## Technical Decisions

### Stack
- **Framework:** Phoenix 1.7 with LiveView
- **Database:** PostgreSQL 16
- **Styling:** Tailwind CSS
- **Auth:** phx.gen.auth (built-in)
- **Deployment:** Fly.io

### Database Schema

```
users (existing + Phase C additions)
- id (uuid)
- email (unique)
- hashed_password
- role (enum: super_admin, session_manager)
- name
- enabled (boolean, default true)
- organisation (text, nullable) — Phase C: from onboarding
- referral_source (text, nullable) — Phase C: how they heard about OOSTKit
- onboarding_completed (boolean, default false) — Phase C: controls onboarding card
- inserted_at
- updated_at

users_tokens (from phx.gen.auth)
- id
- user_id
- token
- context
- sent_to
- inserted_at

tools (Phase A — replaces hardcoded app config)
- id (text) — e.g. "workgroup_pulse"
- name (text) — display name
- tagline (text)
- description (text)
- url (text) — external app URL
- audience (text) — "facilitator" or "team"
- default_status (text) — "live" or "coming_soon"
- admin_enabled (boolean, default true) — admin kill switch
- sort_order (integer)
- inserted_at
- updated_at

interest_signups (Phase A — email capture from coming-soon page)
- id (uuid)
- name (text)
- email (text, unique)
- context (text) — what they clicked (signup, login, tool:wrt, etc.)
- inserted_at

user_tool_interests (Phase C — onboarding tool interest)
- user_id (uuid)
- tool_id (text)
- inserted_at
```

### API Routes

```
# Public pages
GET  /                    Marketing landing page (redirects to /home if logged in)
GET  /home                Dashboard (tool hub)
GET  /apps/:id            App detail / product page
GET  /coming-soon         Holding page with email capture
POST /coming-soon         Submit email capture form

# Auth
GET  /users/register      Registration (Phase C; pre-launch redirects to /coming-soon)
GET  /users/log-in        Login (pre-launch: super admin direct URL only)
GET  /users/log-in/:token Magic link handler
GET  /users/settings      Account settings (authenticated)

# Admin (super admin only)
GET  /admin               Admin dashboard with stats
GET  /admin/users         User management
GET  /admin/signups       Email signups list (Phase B)
GET  /admin/tools         Tool management with kill switch (Phase B)

# Internal API
POST /api/internal/auth/validate   Validate cross-app token (requires INTERNAL_API_KEY)
```

### Environment Variables

```
DATABASE_URL              PostgreSQL connection
SECRET_KEY_BASE           Phoenix secret (must match across all apps for cookie sharing)
PHX_HOST                  Host for URL generation
PORTAL_SUPER_ADMIN_EMAIL  Initial super admin (for seeding)
COOKIE_DOMAIN             Subdomain cookie scope (e.g., .oostkit.com)
INTERNAL_API_KEY          Shared secret for internal API auth (used by WRT as PORTAL_API_KEY)
POSTMARK_API_KEY          Postmark API key for email delivery
MAIL_FROM                 Configurable email from-address (e.g., noreply@oostkit.com)
```

**Production Configuration:**
- `config/prod.exs` configures Swoosh to use `Swoosh.ApiClient.Finch` (instead of hackney) for email delivery via Postmark

---

## Deployment

### Fly.io Configuration

```toml
# fly.toml
app = "oostkit-portal"
primary_region = "syd"

[build]
  dockerfile = "Dockerfile"
  # Build context is monorepo root, not apps/portal/

[env]
  PHX_HOST = "oostkit.com"
  PORT = "8080"

[http_service]
  internal_port = 8080
  force_https = true

[[services.ports]]
  port = 443
  handlers = ["tls", "http"]
```

**Important:** The `Dockerfile` expects the **monorepo root** as the build context (not `apps/portal/`). This allows access to the `shared/` directory for the Tailwind design system preset during asset compilation.

### DNS

Domain: **oostkit.com** (registered)

```
oostkit.com        → portal.fly.dev
pulse.oostkit.com  → pulse.oostkit.com (custom domain)
wrt.oostkit.com    → wrt.oostkit.com (custom domain)
```

---

## Dependencies on Other Work

| Dependency | Required For | Notes |
|------------|--------------|-------|
| ~~Domain registration~~ | Phase 2 (subdomains) | ✓ oostkit.com registered |
| WRT completion | Phase 2 (auth migration) | WRT should be stable first |
| Branding decisions | Phase 1 (but placeholder OK) | Can iterate later |

---

## Estimated Effort

### Phase A: Foundation + Public Face (Priority)
- Tools table + seed data: Small
- Interest signups table: Small
- Route restructure: Small-Medium
- Coming-soon page: Small
- Header redesign: Medium
- Dashboard: Medium
- Marketing landing page: Medium-Large

### Phase B: Admin Hub
- Admin dashboard: Small-Medium
- Email signups admin: Small
- Tool management admin: Small-Medium
- Enhanced user management: Small

### Phase C: Auth & Onboarding
- User profile fields: Small
- Registration flow update: Medium
- Login page + settings: Small-Medium
- Onboarding flow: Medium
- Flip the switch: Small

### Phase D: Polish & Detail
- App detail enhancements: Medium
- SEO & social sharing: Small
- Header integration in apps: Small-Medium
- Admin trends: Medium

---

## Next Steps

Phase A is the priority. Begin with:

1. A1: Create `tools` table migration and seed all 11 tools
2. A2: Create `interest_signups` table migration
3. A3: Restructure routes (`/` → marketing, `/home` → dashboard, `/coming-soon`)
4. A4: Build coming-soon page with email capture
5. A5: Redesign header (three-zone layout)
6. A6: Build dashboard reading from tools DB
7. A7: Build marketing landing page
