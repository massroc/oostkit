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

## New Rollout: Phase A -- Foundation + Public Face (Complete)

Gets the new public experience live. Replaces the current landing page.

**Task A1: Tools table + seed data** (Done)
- DB migration `20260211000001_create_tools` creating `tools` table: id (text), name, tagline, description, url, audience, default_status, admin_enabled (boolean), sort_order (integer)
- `Portal.Tools` context and `Portal.Tools.Tool` schema
- Seed all 11 tools: Workgroup Pulse (live), WRT, Search Conference, Team Kick-off, Team Design, Org Design, Skill Matrix, DP1 Briefing, DP2 Briefing, Collaboration Designer, Org Cadence (all coming_soon)
- Replaces hardcoded app config

**Task A2: Interest signups table** (Done)
- DB migration `20260211000002_create_interest_signups` for `interest_signups` table: id (uuid), name, email (unique), context (text), inserted_at
- `Portal.Marketing` context and `Portal.Marketing.InterestSignup` schema
- Stores email captures from coming-soon page

**Task A3: Route restructure** (Done)
- `/` is now marketing landing page (redirects logged-in users to `/home`)
- `/home` is the dashboard
- `/coming-soon` route added
- `signed_in_path` in `UserAuth` updated to `/home`

**Task A4: Coming-soon page** (Done)
- `PortalWeb.ComingSoonLive` LiveView
- Context-aware messaging via query params (`?context=signup`, `?context=login`, `?context=tool&name=WRT`)
- Email capture form (name + email) with success state
- Sign Up / Log In buttons in header point here

**Task A5: Header redesign** (Done)
- Three-zone layout in `root.html.heex`: [Brand + Context] [Centre Nav] [User/Auth]
- Left: OOSTKit wordmark, breadcrumb app name when inside an app
- Right: Sign Up + Log In buttons → `/coming-soon` (anonymous) / User menu (authenticated)

**Task A6: Dashboard (`/home`)** (Done)
- Tool cards reading from `tools` DB table via `tool_card` component in `CoreComponents`
- Three card states (live & open, coming soon, maintenance)
- 11 cards displayed from DB

**Task A7: Marketing landing page (`/`)** (Done)
- Hero section with bold headline, CTAs
- "What's in the Kit" tool showcase
- OST context paragraph
- Footer with email capture and auth buttons
- Bold, aspirational marketing tone

## New Rollout: Phase B -- Admin Hub (Complete)

Operational control panel for platform management.

**Task B1: Admin dashboard (`/admin`)** (Done)
- `PortalWeb.Admin.DashboardLive` LiveView at `/admin`
- Stats cards: email signup count, registered users, active users (last 30 days), tool status breakdown
- Quick links to Manage Users, View Signups, Tool Status sub-pages
- New context functions: `Accounts.count_users/0`, `Accounts.count_active_users/1`, `Accounts.last_login_map/0`

**Task B2: Email signups admin (`/admin/signups`)** (Done)
- `PortalWeb.Admin.SignupsLive` LiveView at `/admin/signups`
- Table: name, email, context, date
- Live search filtering, delete individual entries
- CSV export via `PortalWeb.Admin.SignupsController` at `/admin/signups/export`
- New context functions: `Marketing.get_interest_signup!/1`, `Marketing.delete_interest_signup/1`, `Marketing.search_interest_signups/1`

**Task B3: Tool management admin (`/admin/tools`)** (Done)
- `PortalWeb.Admin.ToolsLive` LiveView at `/admin/tools`
- Table/cards per tool: name, default status, admin override toggle (kill switch), effective status, URL
- Kill switch: toggle `admin_enabled` instantly without a deploy
- New context function: `Tools.toggle_admin_enabled/1`

**Task B4: Enhanced user management** (Done)
- Added Registered date and Last Login columns to `/admin/users`
- Last login data sourced from `Accounts.last_login_map/0`
- Organisation column deferred to Phase C (requires user profile fields migration)

## New Rollout: Phase C -- Auth & Onboarding (Complete)

Self-service registration and facilitator onboarding live.

**Task C1: User profile fields** (Done)
- DB migration `20260212000001_add_onboarding_fields_to_users`: adds `organisation` (text), `referral_source` (text), `onboarding_completed` (boolean) to users table
- New `user_tool_interests` join table (user_id + tool_id composite PK)
- New `Portal.Accounts.UserToolInterest` schema

**Task C2: Registration flow update** (Done)
- `PortalWeb.UserLive.Registration` updated with name field + facilitator-focused messaging ("Start running workshops with OOSTKit")
- New `registration_changeset/2` on User schema (validates name + email, no password at registration)
- New context functions: `Accounts.change_user_registration/2`
- Magic link confirmation flow sends email with login token

**Task C3: Login page messaging** (Done)
- `PortalWeb.UserLive.Login` updated with "Welcome back" heading
- Magic link as primary login method, password section below as secondary
- Clean visual hierarchy with magic link prominent

**Task C4: Settings page update** (Done)
- `PortalWeb.UserLive.Settings` updated with profile editing section (name, organisation, referral source)
- New `profile_changeset/2` on User schema for profile field validation
- New context functions: `Accounts.change_user_profile/2`, `Accounts.update_user_profile/2`
- Dynamic password label: "Add a password" when no password set, "Change password" when password exists

**Task C5: First-visit onboarding** (Done)
- Dashboard (`/home`) shows onboarding card at top for users with `onboarding_completed == false`
- Card contains: organisation field, referral source field, tool interest checkboxes (from tools DB)
- New `PortalWeb.OnboardingController` handles form POST
- New `onboarding_changeset/2` on User schema for onboarding field validation
- New context functions: `Accounts.complete_onboarding/3`, `Accounts.skip_onboarding/1`, `Accounts.list_user_tool_interests/1`
- "Save" submits data, "Skip for now" marks onboarding complete without data

**Task C6: Flip the switch** (Done)
- Header buttons in `root.html.heex` changed from `/coming-soon?context=signup` and `/coming-soon?context=login` to `/users/register` and `/users/log-in`
- Organisation column added to admin users table (`PortalWeb.Admin.UsersLive`)

## New Rollout: Phase D -- Polish & Detail (D1-D3 Complete, D4-D5 Deferred)

Enhancements once core platform is running.

**Task D1: App detail page enhancements** (Done)
- Richer layout on `/apps/:id` with better spacing, structured header area, visual walkthrough section, detailed description, and action area
- Enhanced card-style layout consistent with the rest of the design system

**Task D2: Inline email capture on detail pages** (Done)
- For coming-soon tools on their `/apps/:id` pages
- Inline form with name + email fields and "Notify me" button
- New route: `POST /apps/:app_id/notify` in `PageController`
- Creates `interest_signup` record with context `tool:{tool_id}`
- Success state: redirects back with `?subscribed=true` query param, showing "Thanks! We'll let you know when it's ready."

**Task D3: SEO & social sharing** (Done)
- Added `<meta name="description">` tag to root layout with per-page override via `@meta_description` assign
- Added Open Graph tags: `og:title` (from `@page_title`), `og:description` (from `@meta_description`), `og:type` ("website"), `og:site_name` ("OOSTKit")
- App detail pages pass tool description as `meta_description` for page-specific SEO
- Title suffix changed from " - OOSTKit" to " — OOSTKit" (em dash)

**Task D4: Header integration in Pulse/WRT** (Deferred)
- Breadcrumb app name in shared header across apps
- Deferred: lower priority, requires changes in Pulse and WRT apps

**Task D5: Admin dashboard trends** (Deferred)
- Charts and time-series once there's enough data
- Deferred: not enough data volume yet to justify implementation

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
POST /apps/:app_id/notify Submit inline email capture from app detail page (Phase D)
GET  /coming-soon         Holding page with email capture
POST /coming-soon         Submit email capture form

# Auth
GET  /users/register      Registration (name + email, magic link confirmation)
GET  /users/log-in        Login (magic link primary, password secondary)
GET  /users/log-in/:token Magic link handler
GET  /users/settings      Account settings (profile, email, password)
POST /onboarding/complete First-visit onboarding form submission
POST /onboarding/skip     Skip onboarding

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

### Phase A: Foundation + Public Face (Complete)
- All tasks (A1-A7) delivered

### Phase B: Admin Hub (Complete)
- Admin dashboard: Small-Medium
- Email signups admin: Small
- Tool management admin: Small-Medium
- Enhanced user management: Small

### Phase C: Auth & Onboarding (Complete)
- All tasks (C1-C6) delivered

### Phase D: Polish & Detail (D1-D3 Complete, D4-D5 Deferred)
- App detail enhancements: Medium — Done
- Inline email capture: Small — Done
- SEO & social sharing: Small — Done
- Header integration in apps: Small-Medium — Deferred
- Admin trends: Medium — Deferred

---

## Next Steps

Phases A, B, C, and D (D1-D3) are complete. Remaining deferred items:

1. D4: Header integration in Pulse/WRT (breadcrumb app name in shared header) — lower priority
2. D5: Admin dashboard trends (charts and time-series once there's enough data) — needs data volume

Future priorities beyond Phase D:
- Content expansion (Learn about OST section, richer app pages)
- Billing integration (platform subscription)
- Analytics (page view and tool launch tracking)
