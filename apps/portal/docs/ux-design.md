# Portal UX Design

This document captures the UX vision for the OOSTKit portal, based on design discussions in February 2026.

## Core Concept: Two Experiences

The portal serves two fundamentally different purposes, each with its own page:

### 1. Marketing Landing Page (`/`)

**Audience:** People who don't know OOSTKit yet, or are returning to share the link.

This is the shopfront — a bright, attractive introduction to the platform. Bold and
energetic tone, but rendered in the warm Pulse aesthetic (paper textures, OOSTKit
palette) rather than a cold tech-startup look.

**Behaviour for logged-in users:** Auto-redirect to `/home` (dashboard).

**Design principle (Merrelyn Emery):** "Tell them what it does." Headlines and copy
should be concrete — but wrapped in aspiration. Tell them what it does *and why it matters*.

#### Tone: Two Voices

The portal has two distinct tones matching its two contexts:

**Marketing page** — Punchy, aspirational, bold. Unapologetically about democratic
workplaces, self-management, and participative design. This is DP2 language — don't
water it down or make it corporate-safe. "Democracy" and "self-managing" are features,
not risks. People who resonate are the users; people who don't, aren't.

Not explaining OST methodology (that's what `opensystemstheory.org` is for) — selling
the vision that organisations can be designed so people manage their own work, and
here are the practical tools to make it happen.

**Dashboard and in-app** — Warm, friendly, collegial. No selling. Users are already here,
already doing the work. Supportive and practical. "Here are your tools, let's go."

Think: conference keynote (marketing page) vs the workshop room afterwards (the app).
The keynote fires people up. The workshop is collaborative.

#### Section 1: Hero

The first thing you see. Big, confident, immediate.

- **Headline**: Bold, values-driven, tells you what it does.
  Direction: *"Tools for building democratic workplaces"* or *"Democracy at work"*.
  Not hedged or corporate-safe. DP2 values front and centre.
- **Subheadline**: Grounds it in OST and practicality.
  Direction: *"Practical online tools built on Open Systems Theory — design
  organisations where people manage their own work"*
- **Primary CTA**: "Try Workgroup Pulse" → links directly to `pulse.oostkit.com`.
  Gets people using the product immediately, no intermediate steps.
- **Secondary CTA**: "Explore all tools" → `/home` (dashboard).
  For people who want to browse first.
- **Visual**: Logo icon + wordmark (simple icon + text for now, proper logo in progress).
  Possibly an illustrated or animated preview of Pulse in action.

#### Section 2: What's in the Kit

Brief showcase of each tool. For each, a compact block:

**Workgroup Pulse**
- What it does: *"Find out how your team is really doing. The 6 Criteria reveal
  whether people have what they need to do productive, self-managing work."*
- Status: Live
- CTA: "Try it now" → `pulse.oostkit.com`
- Visual: Screenshot or illustration of Pulse in action

**Workshop Referral Tool**
- What it does: *"Let the network decide who should be in the room. Participative
  selection for design workshops."*
- Status: Coming soon
- CTA: "Coming soon" (no link, muted styling)
- Visual: Screenshot or illustration of WRT

#### Section 3: OST Context

A short paragraph — enough that someone unfamiliar isn't lost, not a full explanation.

Direction: *"Open Systems Theory provides a practical framework for designing
productive organisations. OOSTKit brings key OST methods online — making them
accessible whether you're a seasoned practitioner or exploring the approach for
the first time."*

Links to "Learn more about OST" (future dedicated page, or external resource for now).

#### Section 4: Footer / Sign Up Prompt

- Email capture: *"More tools coming soon. Leave your email to be notified."*
- Sign Up and Log In buttons (linking to `/users/register` and `/users/log-in`)
- Basic footer info (branding, links)

**Future additions:**
- Testimonials / case studies
- Pricing section
- "Who it's for" section (facilitators vs teams)
- Video walkthroughs of tools

### 2. Dashboard (`/home`)

**Audience:** Everyone — both anonymous visitors and logged-in users.

This is the functional hub where tools live. Tone is warm and collegial — no selling,
just "here are your tools, let's go."

#### Layout

Vertical stack of rich, full-width tool cards. Each tool gets its own row with generous
space for content. Reads like a curated catalogue, top to bottom. Three cards initially —
not sparse, shows a real platform with a roadmap.

No grouping by audience (facilitator vs team) — the split is awkward with few tools
and the boundaries are fluid. Just a flat list.

#### Tool Cards

Each card contains:
- **Name** — tool name
- **Tagline** — one-line summary
- **Description** — 2-3 sentences explaining what it does and when you'd use it
- **Visual** — icon, illustration, or screenshot thumbnail
- **Status badge** — "Live" / "Coming soon"
- **Audience tag** — "For facilitators", "For teams", etc.
- **Action button** — depends on card state (see below)

#### Card States

Cards have three possible states:

| State | When | Button | Visual Treatment |
|-------|------|--------|-----------------|
| **Live & open** | Pulse now | "Launch" → direct link | Full colour, active |
| **Coming soon** | WRT, Search Conference now | No action button, "Coming soon" badge (gold: `bg-ok-gold-100 text-ok-gold-800`) | Muted/greyed, still readable |
| **Live & locked** | WRT later (when auth is live) | "Log in to access" (anon) / "Launch" (logged in) | Full colour, lock icon for anon |

#### Initial Cards

| Tool | Tagline | Status |
|------|---------|--------|
| **Workgroup Pulse** | 6 Criteria for Productive Work | Live & open |
| **Workshop Referral Tool** | Participative selection for design workshops | Coming soon |
| **Search Conference** | Collaborative strategic planning | Coming soon |
| **Team Kick-off** | TBD | Coming soon |
| **Team Design** | TBD | Coming soon |
| **Org Design** | TBD | Coming soon |
| **Skill Matrix** | TBD | Coming soon |
| **DP1 Briefing** | TBD | Coming soon |
| **DP2 Briefing** | TBD | Coming soon |
| **Collaboration Designer** | TBD | Coming soon |
| **Org Cadence** | TBD | Coming soon |

Note: 11 tools total. Layout and organisation (grouping, ordering, card size) will be
revisited as the list matures. With this many coming-soon cards the vertical full-width
stack may shift to a grid layout — to be decided when we tackle implementation.

Note: Pulse and WRT are both components of the Participative Design Workshop (PDW)
process, but the dashboard presents them as standalone tools. The relationship between
tools and OST processes (PDW, Search Conference) may become explicit in the UI later
as the product matures.

#### Future Additions

- "Your recent sessions" / activity feed per tool
- Tool-specific quick actions
- Subscription status and upgrade prompts
- More tools as they're built

**Design:** Cleaner, more functional than the marketing page. OOSTKit design system
(warm palette, paper textures) but restrained — prioritises usability over visual impact.

---

## User Flows

### First-Time Visitor (Curious)

```
Lands on oostkit.com (/)
  → Sees marketing page, reads about OOSTKit
  → Clicks "Explore the Tools"
  → Arrives at /home (dashboard)
  → Sees Workgroup Pulse (open) and WRT (locked)
  → Launches Pulse directly — no friction
```

### Facilitator Wanting WRT Access

```
Lands on oostkit.com (/)
  → Clicks "Explore the Tools" or "Log In"
  → At /home, sees WRT is locked → "Log in to access"
  → Clicks through to login
  → Logs in (or signs up when registration is live)
  → Returns to /home with WRT unlocked
  → Launches WRT
```

### Returning Logged-In User

```
Hits oostkit.com (/)
  → Auto-redirected to /home (dashboard)
  → Launches their tool directly
```

### Team Member Invited to Pulse

```
Receives direct link to pulse.oostkit.com
  → Never sees Portal at all
  → Joins Pulse session directly
```

---

## User Types

Only two types of people interact with OOSTKit:

| | Facilitator | Participant |
|---|---|---|
| **Role** | Creates & manages sessions/workshops | Joins via link |
| **Account** | Yes — logs in | Never — no account needed |
| **Pays** | Yes (subscription) | No |
| **Examples** | OST practitioners, consultants | Team members, workshop attendees |

This pattern is consistent across **every tool** on the platform:
- Facilitator logs in → creates/manages things (sessions, referral rounds, etc.)
- Participants join via links → no account, no friction

### Solo Facilitators Only (For Now)

Individual accounts, individual subscriptions. No organisation or team accounts.
If consulting firms with multiple facilitators need shared access, that's a future
feature driven by actual demand.

### Sign Up Messaging

Registration speaks directly to facilitators: "Sign up to start running workshops"
or "Get started as a facilitator" — not generic "create an account" language.

---

## Authentication & Access Model

### Current State

- **Sign Up button**: Links to `/users/register` — self-service registration with name + email, magic link confirmation
- **Log In button**: Links to `/users/log-in` — "Welcome back" page with magic link (primary) and password (secondary)
- **First-visit onboarding**: Dashboard shows onboarding card for new users (org, referral source, tool interests)
- **Settings**: Facilitators can edit profile (name, org, referral source) and manage password at `/users/settings`
- **Admin panel**: Super admin manages the platform at `/admin` (dashboard with links to users, signups, tools). Users table includes Organisation column.

### Next: Subscription

- Platform subscription unlocks paid tools
- Pulse remains free to use without login (for now)

### Monetization (Future)

- Platform subscription: one price unlocks all paid tools
- Simple upgrade path — single "Subscribe" action
- Can add tiers later if needed, but start flat

---

## Free vs Paid Strategy

### Free Without Account

- **Workgroup Pulse** — the top-of-funnel tool (for now)
- Facilitators can create sessions, participants join via links
- No login, no registration, zero friction
- This is how people discover OOSTKit
- **Not necessarily free forever** — Pulse may eventually require facilitator login to create sessions, while participant joining stays free

### Paid (Platform Subscription)

- **Workshop Referral Tool (WRT)** — first paid tool
- Future facilitator tools
- One subscription unlocks everything
- Pricing details TBD

### Rationale

Pulse as the free entry point gets facilitators in the door. They experience OOSTKit,
see the value, and when they need more tools they have a reason to subscribe.
The eventual model is that all tools require facilitator login — Pulse just gets a
grace period as the discovery tool.

---

## Navigation & Header

One consistent header across the entire platform — marketing page, dashboard, and
inside each app. Same component, same style, adapts content based on context.

### Header Layout

Three-zone layout following standard SaaS patterns:

```
┌──────────────────────────────────────────────────────────────────┐
│  [Left: Brand + Context]    [Centre: Nav]    [Right: User/Auth] │
└──────────────────────────────────────────────────────────────────┘
│  Brand stripe (magenta-to-purple gradient)                       │
└──────────────────────────────────────────────────────────────────┘
```

### Left Zone — Brand + App Context

- **OOSTKit** wordmark/logo (always links to `/`, which redirects to `/home` if logged in)
- When inside an app: **breadcrumb separator + app name** appears
  - e.g. `OOSTKit › Workgroup Pulse`
  - App name is a label (or links to the app's own root)
- When on portal pages (marketing, dashboard, coming-soon): just the OOSTKit wordmark

### Centre Zone — Navigation

Minimal:
- **"Home"** link to `/home` (dashboard) — shown when inside an app, so users can
  get back to the tool hub
- On portal pages: may not be needed (logo already links home)
- Can grow later if more top-level nav is added

### Right Zone — User & Auth

Adapts based on authentication state:

| State | Right Zone Content |
|-------|-------------------|
| **Anonymous** | "Sign Up" (primary button → `/users/register`) + "Log In" (secondary/text → `/users/log-in`) |
| **Logged in** | User name/email + Settings link + "Log Out" |
| **Super admin** | Same as logged in + "Admin" link |

### Brand Stripe

Magenta-to-purple gradient bar sits below the header on all pages. A distinctive
visual identity element. Kept for now — may evolve as the overall design matures.

### Implementation Notes

- The header is a shared component used across Portal, Pulse, and WRT
- Each app already renders its own header using the shared Tailwind preset
- The app name in the breadcrumb is the only thing that changes per-app
- Design system tokens: `bg-ok-purple-900` header, `font-brand` (DM Sans), brand stripe gradient

---

## Auth Pages

Auth pages are for facilitators (and super admin) only. Participants never see them.
Tone is collegial — clean, simple, no selling. The facilitator is already interested
enough to sign up; make it easy and welcoming.

### Registration (`/users/register`)

**Status:** Live. Linked from header Sign Up button.

#### Registration Form

- **Email** (required)
- **Name** (required) — first and last name, single field
- **Submit button**: "Get started" or "Create account"
- No password at registration — magic link flow instead

#### Registration Flow

```
Facilitator clicks "Sign Up"
  → Registration page: enters name + email
  → Submits → confirmation email sent (magic link)
  → Clicks link in email
  → Logged in, lands on dashboard
  → First-visit onboarding prompt appears (see below)
```

#### Messaging

Speak directly to facilitators:
- Heading: "Start running workshops with OOSTKit"
- Subtext: "Create your facilitator account to access the full toolkit."
- Link to login for existing users

### Login (`/users/log-in`)

**Status:** Live. Linked from header Log In button. Two login methods, magic link as primary.

#### Magic Link (Primary)

- Email field
- "Send me a login link" button
- Success message: "Check your email — we've sent you a login link."

#### Password (Secondary)

- Email + password fields
- "Log in" button
- "Forgot password?" link
- Shown below magic link section, visually secondary

#### Messaging

- Heading: "Welcome back"
- Link to registration for new users

### Email Confirmation (`/users/log-in/:token`)

Handles magic link tokens from both registration and login. Already built.
Auto-logs in the user and redirects to dashboard.

### Settings (`/users/settings`)

Requires authentication. Where facilitators manage their account:

- **Change email** — sends confirmation to new address
- **Set/change password** — optional, for facilitators who prefer password login
  over magic links. If no password is set yet, framed as "Add a password" rather
  than "Change password"
- **Edit name** — update display name
- **Profile info** — organisation, how they heard about OOSTKit (same fields as
  onboarding, editable here)

### First-Visit Onboarding

After a facilitator's first login, the dashboard shows a friendly onboarding card
(not a blocking modal or multi-step wizard). It appears at the top of the dashboard
and can be completed or dismissed.

#### Onboarding Card Content

- Heading: "Tell us a bit about yourself"
- **Organisation** (text field, optional)
- **How did you hear about OOSTKit?** (text field or dropdown, optional)
- **Which tools are you interested in?** (checkboxes of available tools, optional)
- "Save" button + "Skip for now" dismiss link
- **Visual:** Gold border (`border-ok-gold-300`) to draw attention as an onboarding prompt

#### Behaviour

- Appears on first visit to `/home` after registration
- Dismissed permanently once completed or skipped
- Data saved to user profile (visible/editable in Settings)
- Super admin can see onboarding data in the admin user list

### Data Model Implications

The user table needs additional fields beyond the current schema:

```
users (additions)
- name (text) — already exists
- organisation (text, nullable) — from onboarding
- referral_source (text, nullable) — how they heard about OOSTKit
- onboarding_completed (boolean, default false) — controls onboarding card visibility
```

Tool interest captured separately (many-to-many or simple join table):

```
user_tool_interests
- user_id (uuid)
- tool_id (text) — e.g. "workgroup_pulse", "wrt", "search_conference"
- inserted_at (timestamp)
```

---

## Admin Pages

Super admin only. A full admin hub for platform management. Accessed via "Admin"
link in the header (visible only to super admins).

### Admin Dashboard (`/admin`)

At-a-glance health check for the platform. Simple counts for now, charts/trends later
when there's enough data.

#### Stats Cards

- **Email signups** — total coming-soon email captures
- **Registered users** — total facilitator accounts
- **Active users** — users who've logged in recently (last 30 days)
- **Tool interest** — breakdown of which tools people selected during onboarding

#### Quick Links

- "Manage users" → `/admin/users`
- "View signups" → `/admin/signups`
- "Tool status" → `/admin/tools`

### User Management (`/admin/users`)

Already built. Evolve to include onboarding data.

#### User List

Table with columns:
- Email
- Name
- Role (Super Admin / Session Manager) — colour-coded badges
- Organisation (from onboarding, may be blank)
- Status (Enabled / Disabled) — colour-coded badges
- Registered date
- Last login
- Actions (Edit, Enable/Disable)

#### Create User

- Email (required)
- Name (required)
- Role selector (Session Manager default, Super Admin option)
- Sends magic link for first login

#### Edit User

- View all profile info including onboarding data (org, referral source, tool interests)
- Edit name, role
- Enable/disable account
- Cannot edit email (security — user changes their own email via settings)

### Email Signups (`/admin/signups`)

View and manage the coming-soon email capture list.

#### Signup List

Table with columns:
- Name
- Email
- Context (what they clicked: signup, login, tool:wrt, etc.)
- Date

#### Actions

- **Export** — download as CSV for use in email campaigns
- **Delete** — remove individual entries (e.g. spam)
- Simple search/filter by context

### Tool Management (`/admin/tools`)

View and control tool status across the platform.

#### Tool List

Table or card layout showing each tool:
- Tool name
- Default status (from config/code: live, coming soon)
- **Admin override toggle** — can disable any tool instantly
- Current effective status (the combination of config + override)
- URL (link to the tool)

#### How It Works

Tool visibility on the dashboard is determined by two layers:

```
Code/config defines:    live | coming_soon
Admin override:         enabled (default) | disabled

Effective status:
- Config = live + Admin = enabled     → Live (launchable)
- Config = live + Admin = disabled    → Maintenance (shown as temporarily unavailable)
- Config = coming_soon + Admin = any  → Coming soon
```

The admin toggle is an operational kill switch — if something goes wrong with an app,
disable it from the admin panel without needing a deploy. Accessible from a phone
in an emergency.

#### Data Model

```
tools (new table, or could be config-seeded)
- id (text) — e.g. "workgroup_pulse"
- name (text) — display name
- tagline (text)
- description (text)
- url (text) — external app URL
- audience (text) — "facilitator" or "team"
- default_status (text) — "live" or "coming_soon" (from config)
- admin_enabled (boolean, default true) — admin override toggle
- sort_order (integer) — display order on dashboard
```

This replaces the current hardcoded app config and gives the admin full control.

---

## Page Inventory

| Route | Page | Auth Required | Description |
|-------|------|---------------|-------------|
| `/` | Marketing landing | No | Brochure/sales page. Redirects to `/home` if logged in. |
| `/home` | Dashboard | No | Tool hub. Shows all tools, lock state varies by auth. |
| `/apps/:id` | App detail / product page | No | Visual walkthrough, full description, launch or inline email capture. Shareable URL. |
| `POST /apps/:app_id/notify` | Email capture from detail page | No | Creates interest_signup with context `tool:{tool_id}`. Redirects back with `?subscribed=true`. |
| `/users/log-in` | Login | No | "Welcome back" heading. Magic link (primary) + password (secondary). |
| `/users/register` | Registration | No | Name + email form, magic link confirmation. Facilitator-focused messaging. |
| `/users/settings` | Account settings | Yes | Profile (name, org, referral source), email change, password (add/change). |
| `/admin` | Admin dashboard | Super Admin | Stats overview: signup counts, user counts, tool status. |
| `/admin/users` | User management | Super Admin | Create/edit/disable user accounts. View onboarding data. |
| `/admin/signups` | Email signups | Super Admin | View/export coming-soon email capture list. |
| `/admin/tools` | Tool management | Super Admin | View tool status, toggle tools on/off (kill switch). |
| `/coming-soon` | Holding page | No | Context-aware holding page with email capture. |

---

## Coming Soon Page (`/coming-soon`)

A context-aware holding page that serves as the soft gate for features not yet live.
Also captures emails for the launch mailing list.

### Context Awareness

The page adapts its message based on where the user came from. A query parameter
(e.g. `?context=signup`, `?context=login`, `?context=tool&name=WRT`) drives the heading:

| Source | Heading | Subtext |
|--------|---------|---------|
| Sign Up button | "Sign up is coming soon" | "We're getting ready for our first users." |
| Log In button | "Login is coming soon" | "We're getting ready for our first users." |
| Locked tool card | "[Tool name] is coming soon" | "We're still building this one." |
| Direct visit / unknown | "More tools are on the way" | Generic fallback. |

### Email Capture Form

Below the context message, a simple form:

- **Name** field (text input)
- **Email** field (email input)
- **Submit button**: "Notify me" or "Keep me posted"
- **Success state**: Replaces form with "Thanks! We'll be in touch."

### Storage

Captured emails stored in the Portal database. Simple table:

```
interest_signups
- id (uuid)
- name (text)
- email (text, unique)
- context (text) — what they clicked to get here (signup, login, tool:wrt, etc.)
- inserted_at (timestamp)
```

No external email service dependency. Emails can be exported or queried directly
when ready to send launch notifications. An admin view could be added later to
see the list.

### Design

- Collegial tone (they're already on the site, not being sold to)
- Clean, simple layout — message, form, done
- OOSTKit branding and design system
- "Back to tools" link to `/home`

---

## App Detail Pages (`/apps/:id`)

A proper product page for each tool. Linked from "Learn more" on dashboard cards and
shareable as a direct URL (e.g. `oostkit.com/apps/workgroup_pulse`).

These pages serve two audiences:
- Someone browsing who wants to understand a tool before trying it
- Someone who received a direct link to a specific tool's page

### Page Structure

#### 1. Header Area

- Back navigation: "Back to all tools" → `/home`
- Tool name (large heading)
- Tagline
- Audience tag ("For facilitators" / "For teams")
- Status badge ("Live" / "Coming soon")

#### 2. Visual Walkthrough

Screenshots or illustrations showing the tool in action:
- Step-by-step overview of what using it looks like
- Key screens / states that demonstrate the workflow
- Could be static images initially, animated or interactive later

#### 3. Detailed Description

Longer prose expanding on the dashboard card summary:
- What the tool does in detail
- Who it's for and when you'd use it
- What the workflow looks like (create session → invite participants → review results)
- What outcomes to expect

Tone: collegial (dashboard tone, not marketing tone). The person is already
interested — help them understand, don't sell.

#### 4. Action Area

Depends on tool status:

| Status | Action Area |
|--------|-------------|
| **Live & open** | "Launch [tool name]" button → direct link to app |
| **Live & locked** | "Log in to access" (anon) / "Launch" (logged in) |
| **Coming soon** | Inline email capture form: "Interested? Leave your email and we'll let you know when it's ready." Name + email fields with "Notify me" button. Submits to `POST /apps/:app_id/notify`, creates interest_signup with context `tool:{tool_id}`. Success state shown via `?subscribed=true` redirect: "Thanks! We'll let you know when it's ready." |

### Content Per Tool

**Workgroup Pulse** (`/apps/workgroup_pulse`)
- Screenshots of: session creation, scoring interface, results summary
- Description: running the 6 Criteria assessment, what each criterion measures,
  how results drive team discussion
- Status: Live → "Try Workgroup Pulse" button

**Workshop Referral Tool** (`/apps/wrt`)
- Screenshots of: referral round setup, participant nomination, results
- Description: participative selection process for PDW, how network referral works,
  managing multiple rounds
- Status: Coming soon → email capture

**Search Conference** (`/apps/search_conference`)
- Placeholder illustration or conceptual visual
- Description: what a Search Conference is, how the tool will support it
- Status: Coming soon → email capture

### SEO & Sharing

These pages are the primary shareable URL for each tool. Implemented:
- Descriptive `<title>` tags: "Workgroup Pulse — OOSTKit" (em dash separator)
- Open Graph meta tags in root layout: `og:title`, `og:description`, `og:type` ("website"), `og:site_name` ("OOSTKit")
- `<meta name="description">` tag with per-page overrides via `@meta_description` assign
- App detail pages pass tool description as `meta_description` for page-specific SEO
- Clean, readable URLs

---

## Design Direction

The portal extends the aesthetic established in Workgroup Pulse:
- Paper textures, warm surfaces
- The `sheet` component language
- OOSTKit colour palette (ok-purple, ok-green, ok-red, ok-gold, ok-blue)
- DM Sans typography
- Not a cold/corporate SaaS feel — approachable, human, collaborative

The marketing page pushes this further with more visual richness (illustrations, animations, bolder typography). The dashboard is more restrained and functional.

### Gold Accent Usage

Gold (`ok-gold`) is used prominently across the portal for warmth and visual consistency with the Pulse app:

| Element | Classes | Context |
|---------|---------|---------|
| "Coming soon" badges | `bg-ok-gold-100 text-ok-gold-800` | Landing page, dashboard tool cards, app detail pages, admin tools page |
| Onboarding card border | `border-ok-gold-300` | Dashboard first-visit onboarding prompt |

---

## Decisions Log

Resolved during design discussions (February 2026):

| Question | Decision | Notes |
|----------|----------|-------|
| "Coming soon" page | Email capture | Collects emails for launch notification. Simple form. |
| App detail pages | Keep | Useful as shareable links and for SEO. Already built. |
| Mobile vs desktop | Desktop-first | Responsive but not mobile-obsessed. Marketing page should look decent on mobile for sharing. |
| Logo | Simple icon + wordmark for now | Proper logo design in progress. Build so it can be swapped in easily. |
| Pricing model | Platform subscription | One price unlocks all paid tools. Simplest to start. Can add tiers later. |
| Org/team accounts | Solo facilitators only for now | Individual accounts and subscriptions. Org accounts are a future feature if demand emerges. |
| Who logs in? | Facilitators only | Participants never need accounts. Login = facilitator creating/managing things. No login for login's sake. |
| Pulse free forever? | Free for now, not necessarily forever | Pulse may eventually require facilitator login to create sessions. Participants always join free via links. |
| Consistent tool pattern | Yes — all tools follow same model | Facilitator logs in to create/manage, participants join via links. Universal across the platform. |

---

## Deferred Items

- Header breadcrumb integration in Pulse/WRT (app name in shared header across apps)
- Admin dashboard trends (charts/time-series once there's enough data)

---

## Open Questions

- What visual assets are needed for the marketing page? (Illustrations, screenshots, animations showing tools in use)
- What content goes on the "Learn about OST" section when it's built?
- When Pulse eventually requires login to create sessions, what happens to existing sessions created anonymously?
