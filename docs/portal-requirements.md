# Portal Requirements

This document captures the requirements for the OOSTKit portal - the front end that serves as the entry point to all platform tools.

## Overview

The portal serves two fundamentally different experiences:

1. **Marketing landing page (`/`)** -- a bright, values-driven introduction to OOSTKit for new visitors
2. **Dashboard (`/home`)** -- the functional tool hub for browsing and launching tools

It also provides:
- Shared authentication across all apps (facilitators only)
- Admin hub for platform management
- Coming-soon pages with email capture as soft feature gates
- A consistent design language across the platform

See also: [Portal UX Design](../apps/portal/docs/ux-design.md) for detailed design specifications.

## Goals

1. Present OOSTKit with a bold, values-driven marketing page
2. Provide a functional dashboard where users find and launch tools
3. Centralize authentication for facilitators (participants never need accounts)
4. Give super admins operational control via an admin hub
5. Capture email interest for features not yet live

## Non-Goals (current scope)

- Aggregated dashboards or cross-app data views
- Persistent workshop data storage
- Organisation or team accounts (solo facilitators only for now)
- Deep integration between apps

---

## Information Architecture

### Marketing Landing Page (`/`)

A bold, aspirational page for new visitors. Redirects logged-in users to `/home`.

**Sections:**
1. **Hero** -- Bold headline ("Tools for building democratic workplaces"), subheadline grounding in OST, primary CTA to Pulse, secondary CTA to dashboard
2. **What's in the Kit** -- Compact showcase of each tool with status and CTA
3. **OST Context** -- Brief paragraph for unfamiliar visitors, link to learn more
4. **Footer / Sign Up Prompt** -- Email capture, Sign Up / Log In buttons

**Tone:** Punchy, aspirational, DP2 language front and centre. Not corporate-safe.

### Dashboard (`/home`)

The functional tool hub. Accessible to everyone (anonymous and logged-in). Page title: "Dashboard".

**Layout:** Three-column categorized grid (12 tools). Tools grouped by `category` field into three columns: Learning, Workshop Management, Team Workshops. Each column has a heading and a vertical stack of compact tool cards beneath it. Stacks to single column on mobile.

**Card states:**
| State | When | Button | Visual |
|-------|------|--------|--------|
| Live & open | Pulse now | "Launch" | Full colour |
| Coming soon | Most tools now | "Coming soon" badge | Muted/greyed |
| Live & locked | WRT later | "Log in to access" (anon) / "Launch" (logged in) | Full colour, lock icon for anon |

Cards are compact (name, tagline, status badge, action button) -- no description text or audience badges to fit the narrower columns.

**Tool catalogue (12 tools, by category):**

| Category | Tool | Status |
|----------|------|--------|
| Learning | Introduction to Open Systems Thinking | Coming soon |
| Learning | DP1 Briefing | Coming soon |
| Learning | DP2 Briefing | Coming soon |
| Workshop Management | Search Conference | Coming soon |
| Workshop Management | Workshop Referral Tool | Coming soon |
| Workshop Management | Skill Matrix | Coming soon |
| Workshop Management | Org Design | Coming soon |
| Workshop Management | Collaboration Designer | Coming soon |
| Workshop Management | Org Cadence | Coming soon |
| Team Workshops | Team Design | Coming soon |
| Team Workshops | Team Kick-off | Coming soon |
| Team Workshops | Workgroup Pulse | Live & open |

### App Detail Pages (`/apps/:id`)

Product page per tool. Shareable URL. Includes visual walkthrough, detailed description, and context-appropriate action (launch button for live tools, or inline email capture form for coming-soon tools with name + email fields and "Notify me" button). Subscribing redirects back with `?subscribed=true` for a success message. Route: `POST /apps/:app_id/notify` creates an interest signup with context `tool:{tool_id}`.

### Coming Soon Page (`/coming-soon`)

Context-aware holding page with email capture. Serves as the soft gate for features not yet live (Sign Up, Log In, locked tools). Query parameters drive contextual messaging.

### Future Pages

- Learn about OST / methodology background
- Pricing section (platform subscription model)
- About / Contact

---

## Technical Architecture

### Hybrid Approach

Rather than embedding apps in iframes, we use a hybrid model:

1. **Portal app** (new Phoenix app) - handles:
   - Landing page
   - App detail pages
   - Authentication and account management
   - Admin tools

2. **Shared design system** - consistent across all apps:
   - Tailwind configuration
   - Color palette, typography, spacing
   - Header component markup/styles
   - Logo and branding assets

3. **Each app renders its own header** using shared styles:
   - Consistent three-zone layout: OOSTKit brand link (left), app name (centre), user/auth content (right)
   - OOSTKit link returns to Portal (configurable `:portal_url` per app)
   - Login state displayed in header (where applicable)
   - App name centered in header identifies which tool the user is in

4. **Subdomain structure:**
   - `oostkit.com` (or chosen domain) - Portal
   - `pulse.oostkit.com` - Workgroup Pulse
   - `wrt.oostkit.com` - Workshop Referral Tool

5. **Shared authentication via subdomain cookies:**
   - Login once at portal
   - Cookie valid across all subdomains
   - Apps check auth state from cookie/token

### Why not iframes?

- LiveView apps have WebSocket connections that complicate iframe auth
- Browser navigation (back button, deep linking, bookmarks) works better natively
- Iframe sizing/scrolling issues with dynamic content
- Each app remains independently deployable and debuggable

---

## Authentication & Authorization

### Design Principles

- Portal owns authentication - single login across all apps
- Flexible approach - build incrementally as needs emerge
- Minimal friction - only require login when necessary (sensitive data)
- Session-based access - users receiving email invitations don't need accounts

### User Types

Only two types of people interact with OOSTKit:

| | Facilitator | Participant |
|---|---|---|
| **Role** | Creates & manages sessions/workshops | Joins via link |
| **Account** | Yes -- logs in | Never -- no account needed |
| **Pays** | Yes (platform subscription) | No |
| **Examples** | OST practitioners, consultants | Team members, workshop attendees |

This pattern is consistent across every tool: facilitator logs in to create/manage, participants join via links with no friction.

**System roles:**
| Role | Description | Access |
|------|-------------|--------|
| Super Admin | Platform owner | All apps, admin hub, platform settings |
| Session Manager | Facilitator running workshops | Apps they have access to (e.g., WRT) |

### Current Scope
- Self-service registration for facilitators (email + name, plus optional organisation, referral source, and tool interest checkboxes; magic link confirmation; users are fully onboarded at registration)
- Super Admin can also create Session Manager accounts via admin panel
- Session Managers log in to access WRT
- Workgroup Pulse remains free and open (no login required) -- the top-of-funnel discovery tool
- Participants access sessions via links (no account, no friction)
- Sign Up and Log In buttons link to real auth pages (`/users/register` and `/users/log-in`)
- Dev auto-login: in development, Portal auto-logs in as a dev super admin (`admin@oostkit.local`) on first visit and sets the `_oostkit_token` cookie, so WRT and Pulse are accessible without manual login

### Account Management

Admin hub for super admins:
- **Admin dashboard** (`/admin`) -- stats cards (signup count, user count, tool interest)
- **User management** (`/admin/users`) -- create/edit/disable accounts, view registration data (org, referral source, tool interests)
- **Email signups** (`/admin/signups`) -- view/export coming-soon email capture list, CSV export
- **Tool management** (`/admin/tools`) -- view tool status with category column, kill switch toggle per tool

### Future Considerations

- Platform subscription billing (one price unlocks all paid tools)
- Organisation-level accounts if demand emerges (solo facilitators only for now)
- Persistent data access requiring authentication

---

## User Experience

### Navigation Flow

```
[Marketing Landing Page /]
        |
        ├── "Try Workgroup Pulse" → [pulse.oostkit.com]
        ├── "Explore all tools" → [Dashboard /home]
        │        |
        │        ├── Live tool → "Launch" → [App on subdomain]
        │        ├── Locked tool → "Log in to access" → [Login or /coming-soon]
        │        ├── Coming soon tool → "Coming soon" badge (no action)
        │        └── "Learn more" → [App Detail Page /apps/:id]
        │
        ├── "Sign Up" → [/users/register]
        └── "Log In" → [/users/log-in]

[Logged-in user hits /] → auto-redirect to [/home]
```

### Login-Required Apps

When a user clicks on an app that requires authentication:
1. If logged in → App launches
2. If not logged in → Redirect to portal login (or `/coming-soon` pre-launch)
3. After login → Redirect back to requested app

### Consistent Header

Three-zone `justify-between` layout across the entire platform (marketing page, dashboard, inside apps):

```
[Left: OOSTKit link]    [Centre: App name / Page title]    [Right: User/Auth]
```

- **Left:** "OOSTKit" brand link. In Portal, links to `/`. In Pulse/WRT, links to Portal via configurable `:portal_url` (defaults to `https://oostkit.com`).
- **Centre:** In Portal, displays the current page title (e.g., "Dashboard"). In Pulse/WRT, displays the app name ("Workgroup Pulse" / "Workshop Referral Tool") as static text.
- **Right:** Sign Up + Log In (anonymous) / User email + Settings + Log Out (authenticated) / + Admin link (super admin). In dev mode, an "Admin" button (gold text, POST to `/dev/admin-login`) appears for anonymous users to quickly log in as the dev super admin. In apps without user context (e.g., Pulse), a placeholder div maintains spacing.

---

## Visual Design

### Design Language

- Consistent across portal and all apps via the OOSTKit design system (`docs/design-system.md`)
- Professional, approachable, not overly corporate
- Reflects OST values (collaboration, participation, human-centered)

### Shared Elements (Implemented)

- Branded navigation header (`bg-ok-purple-900`) with OOSTKit wordmark
- Brand stripe (magenta-to-purple gradient) below header
- Semantic color tokens: ok-purple, ok-green, ok-red, ok-gold, ok-blue
- DM Sans brand font via Google Fonts
- Surface tokens for backgrounds: `bg-surface-wall`, `bg-surface-sheet`, `bg-surface-sheet-secondary`
- Text tokens: `text-text-dark` for headings
- Card components: `bg-surface-sheet shadow-sheet`
- Button styles: `bg-ok-purple-600` for primary actions
- Form focus/error states: `focus:border-ok-purple-400`, `border-ok-red-400`

### Implementation

- Shared Tailwind preset at `shared/tailwind.preset.js` imported by all apps
- Design tokens for colors, spacing, typography, and shadows
- All three apps (Portal, Pulse, WRT) fully aligned to the design system

---

## App Visibility & Tool Management

Tool visibility on the dashboard is determined by two layers:

- **Default status** (from database): `live` or `coming_soon`
- **Admin override** (kill switch): `enabled` (default) or `disabled`

Effective status:
- Config = live + Admin = enabled → Live (launchable)
- Config = live + Admin = disabled → Maintenance (temporarily unavailable)
- Config = coming_soon + Admin = any → Coming soon

The admin toggle is an operational kill switch -- if something goes wrong with an app, disable it from the admin panel without needing a deploy.

### Free vs Paid Strategy

- **Free without account:** Workgroup Pulse (top-of-funnel discovery tool, may eventually require facilitator login)
- **Paid (platform subscription):** WRT and future facilitator tools. One subscription unlocks everything.
- Participants always join free via links, regardless of tool

---

## Technical Implementation

### Stack

- Elixir/Phoenix (consistent with other apps)
- Phoenix LiveView for interactive elements
- Tailwind CSS for styling
- PostgreSQL for account data

### Deployment

- Fly.io (consistent with other apps)
- Own database for portal-specific data (accounts, settings)
- Subdomain configuration for cookie sharing

### Authentication Implementation

Uses Phoenix built-in auth (`phx.gen.auth`) with cross-app extensions:

- **Session cookies**: Standard Phoenix session auth for Portal UI
- **Cross-app token cookie** (`_oostkit_token`): Written on login, deleted on logout. Scoped to the shared domain via `COOKIE_DOMAIN` env var (e.g., `.oostkit.com`).
- **Internal validation API**: `POST /api/internal/auth/validate` -- accepts the token in the request body, returns user `{id, email, role}`. Protected by `ApiAuth` plug requiring `Authorization: Bearer <INTERNAL_API_KEY>` header.
- **Configurable email from-address**: `mail_from` config supports Postmark sender signatures in production (env: `MAIL_FROM`).
- **Dev auto-login**: In development, `DevAutoLogin` plug auto-logs in as `admin@oostkit.local` on first visit and sets the `_oostkit_token` cookie. A `_portal_dev_visited` cookie prevents re-login after deliberate logout. A dev-only `POST /dev/admin-login` route allows manual re-login via a gold "Admin" button in the header.

Key requirements (all met):
- Secure password hashing (bcrypt via phx.gen.auth)
- Session management
- Cross-subdomain cookie support via configurable `COOKIE_DOMAIN`
- Internal API for token validation by other apps

### Tool URL Resolution

Tool URLs are stored in the database (production subdomain URLs), but Portal overrides them per environment via `config :portal, :tool_urls`. The `Portal.Tools` context applies overrides transparently through `apply_config_url/1` on all query functions, so templates always get the correct URL from `@tool.url`.

| Environment | Pulse URL | WRT URL | Source |
|-------------|-----------|---------|--------|
| Dev | `http://localhost:4000` | `http://localhost:4001` | `config/dev.exs` |
| Test | `http://localhost:4000` | `http://localhost:4001` | `config/test.exs` |
| Prod | `https://pulse.oostkit.com` | `https://wrt.oostkit.com` | `config/runtime.exs` (overridable via `PULSE_URL`, `WRT_URL` env vars) |

The landing page uses a `pulse_url/1` helper (in `PageHTML`) that reads the URL from the live tool list, replacing previously hardcoded production URLs.

---

## Decisions

1. **Domain:** oostkit.com (registered)
2. **Branding:** Simple icon + wordmark for now, proper logo in progress
3. **WRT integration:** Replace WRT's auth entirely when portal auth is ready
4. **App metadata:** Tools table in database (replaces hardcoded app config), seeded with 12 tools via data migration (available in all environments including production). Tools have a `category` field for dashboard grouping.
5. **Analytics:** Nice to have, implement later (not in initial phases)
6. **Pricing model:** Platform subscription -- one price unlocks all paid tools
7. **Org/team accounts:** Solo facilitators only for now; org accounts if demand emerges
8. **Who logs in:** Facilitators only. Participants never need accounts.
9. **Pulse free forever?** Free for now, not necessarily forever. May require facilitator login later.
10. **Coming-soon gate:** Email capture as soft gate for features not yet live

---

## Deferred Items

- Admin dashboard trends (charts/time-series once there's enough data)

---

## Related Documents

- [Portal UX Design](../apps/portal/docs/ux-design.md)
- [Product Vision](product-vision.md)
- [Architecture](architecture.md)
- [WRT Requirements](../apps/wrt/REQUIREMENTS.md)
- [Workgroup Pulse Requirements](../apps/workgroup_pulse/REQUIREMENTS.md)
