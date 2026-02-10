# Portal Implementation Plan

This document outlines the implementation approach for the OOSTKit portal, broken into phases with concrete tasks.

## Overview

The portal is a Phoenix application that serves as:
- Landing page and tool directory
- Authentication hub for the platform
- Account management for admins

**Location:** `apps/portal/`

---

## Phase 1: Foundation

### 1.1 Project Setup

**Task 1.1.1: Create Phoenix app**
- Generate new Phoenix app: `mix phx.new portal --no-mailer --no-dashboard`
- Configure for monorepo structure
- Set up basic folder structure

**Task 1.1.2: Docker configuration**
- Create `Dockerfile` and `Dockerfile.dev`
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
- Configure deployment to Fly.io (when ready)

**Task 1.1.4: Development tooling**
- Configure `mix format`
- Add `mix quality` alias (credo, dialyzer if used)
- Update root `docker-compose.yml` to include portal
- Update `CLAUDE.md` with portal commands

### 1.2 Landing Page

**Task 1.2.1: App configuration**
- Create `config/apps.yml` (or `priv/apps.json`) for tool metadata:
  ```yaml
  apps:
    - id: workgroup_pulse
      name: "Workgroup Pulse"
      tagline: "6 Criteria for Productive Work"
      description: "A self-guided workshop helping teams assess..."
      audience: team
      url: "https://pulse.oostkit.com"  # or env-based
      requires_auth: false
      status: live

    - id: wrt
      name: "Workshop Referral Tool"
      tagline: "Participative selection for PDW participants"
      description: "Manage the referral process to let..."
      audience: facilitator
      url: "https://wrt.oostkit.com"
      requires_auth: true
      status: live
  ```

**Task 1.2.2: Landing page layout**
- Create `PageController` and `PageLive` (or static controller)
- Hero section: OOSTKit name, brief tagline
- Split view layout:
  - Left: "Tools for Facilitators"
  - Right: "Tools for Teams"
- Tool cards displaying: name, tagline, launch button
- Footer with basic info

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

## Phase 2: Unified Experience (In Progress)

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

## Phase 3: Enhanced Features

### 3.1 Content Expansion

**Task 3.1.1: "Learn about OST" section**
- New route: `/learn`
- Content pages about OST methodology
- Links to external resources

**Task 3.1.2: Richer app pages**
- Screenshots or illustrations
- Use cases and examples
- FAQ section per app

### 3.2 Self-Service (Future)

**Task 3.2.1: Registration flow**
- Self-service account creation
- Email verification
- Approval workflow (if needed)

**Task 3.2.2: Billing integration**
- Payment provider integration
- Subscription management
- Usage tracking

### 3.3 Analytics

**Task 3.3.1: Basic analytics**
- Page view tracking
- Tool launch tracking
- Simple dashboard for super admin

---

## Technical Decisions

### Stack
- **Framework:** Phoenix 1.7 with LiveView
- **Database:** PostgreSQL 16
- **Styling:** Tailwind CSS
- **Auth:** phx.gen.auth (built-in)
- **Deployment:** Fly.io

### Database Schema (Phase 1)

```
users
- id (uuid)
- email (unique)
- hashed_password
- role (enum: super_admin, session_manager)
- name
- enabled (boolean, default true)
- inserted_at
- updated_at

users_tokens (from phx.gen.auth)
- id
- user_id
- token
- context
- sent_to
- inserted_at
```

### API Routes

```
GET  /                    Landing page
GET  /apps/:id            App detail page

GET  /login               Login form
POST /login               Process login
GET  /logout              Logout

GET  /admin               Admin dashboard
GET  /admin/users         User list
GET  /admin/users/new     New user form
POST /admin/users         Create user
GET  /admin/users/:id     View user
PUT  /admin/users/:id     Update user

# Internal API (Phase 2)
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

---

## Deployment

### Fly.io Configuration

```toml
# fly.toml
app = "oostkit-portal"
primary_region = "syd"

[build]
  dockerfile = "Dockerfile"

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

### Phase 1: Foundation
- Project setup: Small
- Landing page: Small
- Authentication: Medium
- Account management: Medium

### Phase 2: Unified Experience
- Subdomain/cookie setup: Medium
- WRT auth migration: Medium-Large
- Shared header integration: Small-Medium

### Phase 3: Enhanced Features
- Content expansion: Small
- Self-service: Large
- Analytics: Medium

---

## Next Steps

When ready to begin:

1. Create `apps/portal/` directory
2. Generate Phoenix app
3. Set up Docker configuration
4. Get landing page running locally
5. Add authentication
6. Build admin user management

The portal can be developed independently and then integrated with the other apps in Phase 2.
