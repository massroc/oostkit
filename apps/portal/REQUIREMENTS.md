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

See also: [Portal UX Design](docs/ux-design.md) for detailed design specifications.

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

A bold, aspirational page for new visitors. No redirect for logged-in users — they see the same marketing page, with the header bar providing a "Dashboard" link to `/home`.

**Sections:**
1. **Hero** -- Bold headline ("Tools for building democratic workplaces"), subheadline grounding in OST, primary CTA to Pulse, secondary CTA to dashboard
2. **What's in the Kit** -- Compact showcase of each tool with status and CTA
3. **OST Context** -- Brief paragraph for unfamiliar visitors, link to learn more
4. **Footer / Sign Up Prompt** -- Email capture, Sign Up / Log In buttons

**Tone:** Punchy, aspirational, DP2 language front and centre. Not corporate-safe.

### Dashboard (`/home`)

The functional tool hub. Accessible to everyone (anonymous and logged-in). Page title: "Dashboard".

**Layout:** Three-column categorized grid (12 tools). Tools grouped by `category` field into three columns: Learning, Workshop Management, Team Workshops. Each column has a heading and a vertical stack of compact tool cards beneath it. Stacks to single column on mobile. Within each category, live tools are sorted to the top so active tools are immediately visible.

**Card layout:** Cards use `flex flex-col` with `flex-1` on the tagline to ensure equal height across all cards within a category column. Action buttons are pushed to the bottom of each card.

**Card states:**
| State | When | Button | Visual |
|-------|------|--------|--------|
| Live & open | Pulse now | "Launch" | Full colour |
| Coming soon | Most tools now | "Coming soon" badge | Muted/greyed |
| Live & locked | WRT later | "Log in to access" (anon) / "Launch" (logged in) | Full colour, lock icon for anon |

Cards are compact (name, tagline, status badge, action button) -- no description text or audience badges to fit the narrower columns.

**Visual emphasis:** "Coming soon" badges should be visually secondary (muted background + darker gold text via `accent-gold-text` for contrast) so the live tool (Pulse) remains the clear primary action. As the catalogue grows, consider `line-clamp-2` for taglines and a `md:grid-cols-2` breakpoint so columns don't feel cramped at mid-width.

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

### Static Pages

- **About** (`/about`) — information about OOSTKit and the team
- **Privacy Policy** (`/privacy`) — how OOSTKit collects, uses, and protects personal data
- **Contact** (`/contact`) — how to get in touch with the OOSTKit team

### Future Pages

- Learn about OST / methodology background
- Pricing section (platform subscription model)

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
   - Tailwind configuration (`shared/tailwind.preset.js`)
   - Color palette, typography, spacing
   - Shared Elixir component library (`apps/oostkit_shared/`) providing `header_bar/1`
   - Logo and branding assets

3. **Each app renders its header via the shared `header_bar/1` component** from `OostkitShared.Components`:
   - Consistent three-zone layout: OOSTKit brand link (left), app name (centre), actions slot (right)
   - OOSTKit link returns to Portal (configurable `:brand_url` per app)
   - Login state displayed in header (where applicable)
   - App name centered in header identifies which tool the user is in
   - Portal additionally renders a `footer_bar` component with links to About, Privacy, and Contact pages

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
- Password reset: "Forgot your password?" link on login page, email-based reset flow with time-limited tokens
- Account deletion: users can delete their own account from the settings page (requires sudo mode)
- Dev auto-login: in development, Portal auto-logs in as a dev super admin (`admin@oostkit.local`) on first visit and sets the `_oostkit_token` cookie, so WRT and Pulse are accessible without manual login

### Account Management

**Self-service (facilitators):**
- **Settings** (`/users/settings`) -- stacked sections with cards layout (Tailwind UI style). An "Account Settings" title with subtitle at the top. Sections separated by `divide-y` dividers, each using a responsive 1/3 + 2/3 grid (`md:grid-cols-3`): left column has the section heading and subtitle, right column has a card (`bg-surface-sheet shadow-sheet rounded-xl`) with form fields and a footer with save button. Five sections stacked vertically: Profile (name, org), Contact Preferences (product_updates checkbox), Email (change address), Password (add/change), and Danger zone (delete account, heading in `text-ok-red-600`). Referral source is collected at registration only and not editable in settings. The settings page loads without requiring sudo mode; sudo checks are performed in handlers for sensitive actions (email change, password change, account deletion) with a graceful redirect to login if not in sudo mode.
- **Password reset** -- "Forgot your password?" link on login page sends a reset email with a time-limited token. User sets a new password via `/users/reset-password/:token`.
- **Account deletion** -- "Danger zone" section on settings page with confirmation prompt. Deletes the user account and logs them out.

**Admin hub (super admins):**

All admin routes (`/admin/*`) are protected by a `require_super_admin` router pipeline that enforces super admin authorization at the router level for both LiveView and controller routes (e.g., CSV export). LiveView routes additionally use an `on_mount` hook for the same check.

- **Admin dashboard** (`/admin`) -- stats cards (signup count, user count, tool interest), quick links to all admin pages
- **User management** (`/admin/users`) -- create/edit/disable accounts, view registration data (org, referral source, tool interests)
- **Email signups** (`/admin/signups`) -- view/export coming-soon email capture list, CSV export
- **Tool management** (`/admin/tools`) -- view tool status with category column, kill switch toggle per tool
- **System status** (`/admin/status`) -- live health check and CI pipeline status for all deployed apps (Portal, Pulse, WRT). Polls every 5 minutes via a background GenServer and broadcasts updates to connected admin sessions in real time via PubSub. Displays app health (response time, up/down) and recent GitHub Actions workflow runs (pass/fail/running). Manual refresh button available.

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
                 └── "Forgot your password?" → [/users/forgot-password]
                          └── Email with reset link → [/users/reset-password/:token]

[Logged-in user hits /] → sees marketing page (header shows Dashboard link to /home)
```

### Login-Required Apps

When a user clicks on an app that requires authentication:
1. If logged in → App launches
2. If not logged in → App redirects to Portal login with a `return_to` query param containing the user's current URL (e.g., `/users/log-in?return_to=http://localhost:4001/org/acme/manage`)
3. Portal validates the `return_to` URL against configured `tool_urls` origins (scheme + host + port must match a known tool) to prevent open redirects
4. If valid, Portal stores the URL in the session as `:user_return_to`
5. After login → Portal redirects to the stored external URL instead of defaulting to `/home`
6. If the `return_to` URL is missing or invalid, Portal falls back to `/home`

### Consistent Header

All apps use the shared `<.header_bar>` component from `OostkitShared.Components` (`apps/oostkit_shared/`). Three-zone layout with absolutely centered title, consistent across the entire platform (Portal, Pulse, WRT):

```
[Left: OOSTKit link]    [Centre: Title (absolute)]    [Right: Auth (actions slot)]
```

The centre title uses `pointer-events-none absolute inset-x-0 text-center font-brand` for true visual centering regardless of left/right zone widths.

- **Left:** "OOSTKit" brand link (`:brand_url` attr). In Portal, links to `/`. In Pulse/WRT, links to Portal via configurable `:portal_url` (defaults to `https://oostkit.com`).
- **Centre:** `:title` attr. In Portal, displays the current page title (e.g., "Dashboard"). In Pulse/WRT, displays the app name ("Workgroup Pulse" / "Workshop Referral Tool") as static text.
- **Right:** `:actions` slot for app-specific content. All apps use consistent button styling — Sign Up (`rounded-md bg-white/10` frosted button) + Log In (text link). Auth state varies by app:
  - **Portal:** Sign Up + Log In (anonymous) / User email + Settings + Log Out (authenticated) / + Admin link (super admin). Dev mode adds an "Admin" button (gold text, POST to `/dev/admin-login`).
  - **Pulse:** Always shows Sign Up + Log In (no user context — Pulse has no authentication).
  - **WRT:** Shows Sign Up + Log In when no `portal_user`, or user email + Settings link when authenticated via Portal cookie.

### Footer Bar

Portal renders a `footer_bar` component in the root layout with links to About (`/about`), Privacy (`/privacy`), and Contact (`/contact`) pages. The footer replaces the inline footer sections that were previously part of the landing and home page templates.

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
- Req HTTP client (used by StatusPoller for health checks and GitHub API calls)

### Deployment

- Fly.io (consistent with other apps)
- Own database for portal-specific data (accounts, settings)
- Subdomain configuration for cookie sharing

### Authentication Implementation

Uses Phoenix built-in auth (`phx.gen.auth`) with cross-app extensions:

- **Session cookies**: Standard Phoenix session auth for Portal UI
- **Cross-app token cookie** (`_oostkit_token`): Written on login, deleted on logout. Scoped to the shared domain via `COOKIE_DOMAIN` env var (e.g., `.oostkit.com`).
- **Internal validation API**: `POST /api/internal/auth/validate` -- accepts the token in the request body, returns user `{id, email, role}`. Protected by `ApiAuth` plug requiring `Authorization: Bearer <INTERNAL_API_KEY>` header.
- **Cross-app return redirect**: The `store_external_return_to` plug (in the browser pipeline) reads a `return_to` query param from incoming requests, validates the URL against `:tool_urls` origins (scheme + host + port must match a known tool), and stores it in the session as `:user_return_to`. After login, `log_in_user/3` redirects to the stored URL — using `redirect(external: url)` for absolute tool URLs, or `redirect(to: path)` for internal paths. Invalid or missing `return_to` values fall back to `/home`. This prevents open redirects while enabling seamless cross-app login flows.
- **Password reset tokens**: Hashed tokens stored in `users_tokens` table with a `reset_password` context and configurable expiry. Sent via email when a user requests a password reset from `/users/forgot-password`.
- **Configurable email from-address**: `mail_from` config supports Postmark sender signatures in production (env: `MAIL_FROM`).
- **Dev auto-login**: In development, `DevAutoLogin` plug auto-logs in as `admin@oostkit.local` on first visit and sets the `_oostkit_token` cookie. A `_portal_dev_visited` cookie prevents re-login after deliberate logout. A dev-only `POST /dev/admin-login` route allows manual re-login via a gold "Admin" button in the header.

Key requirements (all met):
- Secure password hashing (bcrypt via phx.gen.auth)
- Session management
- Cross-subdomain cookie support via configurable `COOKIE_DOMAIN`
- Internal API for token validation by other apps

### Tool URL and Status Resolution

Tool URLs and statuses are stored in the database (production values), but Portal overrides them per environment via two config keys. The `Portal.Tools` context applies overrides transparently through `apply_config_overrides/1` on all query functions, so templates always get the correct values from `@tool.url` and `@tool.default_status`.

**URL overrides (`config :portal, :tool_urls`):**

| Environment | Pulse URL | WRT URL | Source |
|-------------|-----------|---------|--------|
| Dev | `http://localhost:4000` | `http://localhost:4001` | `config/dev.exs` |
| Test | `http://localhost:4000` | `http://localhost:4001` | `config/test.exs` |
| Prod | `https://pulse.oostkit.com` | `https://wrt.oostkit.com` | `config/runtime.exs` (overridable via `PULSE_URL`, `WRT_URL` env vars) |

**Status overrides (`config :portal, :tool_status_overrides`):**

Maps tool IDs to status strings. Used in `dev.exs` to mark WRT as `"live"` locally, since WRT is functional in development but still "coming soon" in production. This lets developers see and test the live tool card experience for WRT without changing the production database status.

**Dashboard sorting:** The `list_tools_grouped/0` function sorts live tools to the top within each category, ensuring active tools appear first.

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

- [Portal UX Design](docs/ux-design.md)
- [Product Vision](../../docs/product-vision.md)
- [Architecture](../../docs/architecture.md)
- [WRT Requirements](../wrt/REQUIREMENTS.md)
- [Workgroup Pulse Requirements](../workgroup_pulse/REQUIREMENTS.md)
