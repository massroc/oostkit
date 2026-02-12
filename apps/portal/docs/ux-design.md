# Portal UX Design

This document captures the UX vision for the OOSTKit portal, based on design discussions in February 2026.

## Core Concept: Two Experiences

The portal serves two fundamentally different purposes, each with its own page:

### 1. Marketing Landing Page (`/`)

**Audience:** People who don't know OOSTKit yet, or are returning to share the link.

This is the shopfront — a bright, attractive introduction to the platform. Bold and
energetic tone, but rendered in the warm Pulse aesthetic (paper textures, OOSTKit
palette) rather than a cold tech-startup look.

**Behaviour for logged-in users:** No redirect. Logged-in users see the same marketing
page as anonymous visitors. The header bar shows "Dashboard" as a clickable link to
`/home`, providing easy navigation without forcing a redirect.

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
- The root layout includes a persistent `footer_bar` component with links to About (`/about`), Privacy (`/privacy`), and Contact (`/contact`) pages. This replaces inline footer sections that were previously duplicated across landing and home page templates.

**Future additions:**
- Testimonials / case studies
- Pricing section
- "Who it's for" section (facilitators vs teams)
- Video walkthroughs of tools

### 2. Dashboard (`/home`)

**Audience:** Everyone — both anonymous visitors and logged-in users.

This is the functional hub where tools live. Tone is warm and collegial — no selling,
just "here are your tools, let's go." Page title is "Dashboard". The on-page heading
is "Your tools" at `text-2xl` with an inline subtitle " — Let's go." for a compact,
friendly introduction. Reduced vertical padding (`pt-3 pb-12`) keeps the layout tight.

#### Layout

Three-column categorized grid. Tools are grouped into three categories displayed as
columns on desktop (stacked on mobile):

| Column | Category Key | Label |
|--------|-------------|-------|
| 1 | `learning` | Learning |
| 2 | `workshop_management` | Workshop Management |
| 3 | `team_workshops` | Team Workshops |

Each column has a category heading and a vertical stack of compact tool cards beneath it.
The layout uses `md:grid-cols-3` with `gap-8` between columns. Within each category,
cards are arranged using `grid gap-4` to ensure equal spacing. This replaced the
earlier flat full-width card list — the categorized grid better organises the growing
tool catalogue (12 tools) and gives each category its own visual lane.

**Sorting:** Within each category, live tools are sorted to the top. This ensures
active tools are immediately visible without scrolling past coming-soon placeholders.
The sorting is applied in the `list_tools_grouped/0` function.

#### Tool Cards

Cards use `flex flex-col` layout with a `flex-1` tagline to ensure equal height across
all cards within a column. Each card contains:
- **Name** — tool name (smaller text than previous full-width cards)
- **Tagline** — one-line summary (uses `flex-1` to push action buttons to the bottom)
- **Status badge** — "Live" / "Coming soon"
- **Action button** — depends on card state (see below)

Cards no longer display description text or audience badges — these were removed to
keep the cards compact in the narrower three-column layout. The tool name and tagline
provide enough context, and the category column provides implicit audience grouping.

#### Card States

Cards have three possible states:

| State | When | Button | Visual Treatment |
|-------|------|--------|-----------------|
| **Live & open** | Pulse now | "Launch" → direct link | Full colour, active |
| **Coming soon** | WRT, Search Conference now | No action button, "Coming soon" badge (gold: `bg-ok-gold-100 text-ok-gold-800`) | Muted/greyed, still readable |
| **Live & locked** | WRT later (when auth is live) | "Log in to access" (anon) / "Launch" (logged in) | Full colour, lock icon for anon |

#### Tool Catalogue (12 tools, by category)

**Learning:**
| Tool | Tagline | Status |
|------|---------|--------|
| **Introduction to Open Systems Thinking** | Learn the foundations of democratic organisation design | Coming soon |
| **DP1 Briefing** | TBD | Coming soon |
| **DP2 Briefing** | TBD | Coming soon |

**Workshop Management:**
| Tool | Tagline | Status |
|------|---------|--------|
| **Search Conference** | Collaborative strategic planning | Coming soon |
| **Workshop Referral Tool** | Participative selection for design workshops | Coming soon |
| **Skill Matrix** | TBD | Coming soon |
| **Org Design** | TBD | Coming soon |
| **Collaboration Designer** | TBD | Coming soon |
| **Org Cadence** | TBD | Coming soon |

**Team Workshops:**
| Tool | Tagline | Status |
|------|---------|--------|
| **Team Design** | TBD | Coming soon |
| **Team Kick-off** | TBD | Coming soon |
| **Workgroup Pulse** | 6 Criteria for Productive Work | Live & open |

Note: 12 tools total. The three-column categorized grid keeps the growing catalogue
organised. Each tool has a `category` field in the database that determines which
column it appears in.

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
  → Sees marketing page (same as anonymous visitors)
  → Header shows clickable "Dashboard" link → clicks through to /home
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
- **Registration collects profile data**: Organisation (optional), referral source (optional), and tool interest checkboxes are part of the registration form. Users are fully onboarded from the moment they register.
- **Settings**: Facilitators can edit profile (name, org), manage contact preferences (product updates opt-in), and manage email/password at `/users/settings`
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

Three-zone layout with an absolutely centered title, consistent across Portal, Pulse, and WRT:

```
┌──────────────────────────────────────────────────────────────────┐
│  [Left: Brand]    [Centre: Title (absolute)]    [Right: Auth]    │
└──────────────────────────────────────────────────────────────────┘
│  Brand stripe (magenta-to-purple gradient)                       │
└──────────────────────────────────────────────────────────────────┘
```

The centre title uses `pointer-events-none absolute inset-x-0 text-center` to achieve
true visual centering regardless of left/right zone widths. The `font-brand` (DM Sans) class
is applied to the title text.

### Left Zone — Brand

- **OOSTKit** wordmark/logo (always links to `/` — the front page)
- When inside an app (Pulse/WRT): links to Portal via configurable `:portal_url`
- No breadcrumb separator — the centre zone identifies the current app/page

### Centre Zone — Page Title (Absolutely Centered)

Absolutely positioned (`pointer-events-none absolute inset-x-0`) to achieve true centering
independent of left/right zone content. Displays `font-brand text-2xl font-semibold text-ok-purple-200`.
Hidden on small screens (`sm:block`).

When `title_url` is set, the title renders as a clickable `<a>` link with `pointer-events-auto`
to override the `pointer-events-none` on the container (avoids a full-width clickable overlay).
When no `title_url` is set, it renders as a static `<span>`.

- **Portal:** For logged-in users, displays "Dashboard" as a clickable link to `/home`.
  Hidden on the landing page via the `hide_header_title` assign, so logged-in users on `/`
  see OOSTKit branding without a redundant title. On other pages (settings, admin), the
  page title displays as static text (no `title_url`).
- **Pulse/WRT:** Displays the app name ("Workgroup Pulse", "Workshop Referral Tool") as static text

### Right Zone — User & Auth

Adapts based on authentication state. All three apps use consistent button styling:
- "Sign Up" uses `rounded-md bg-white/10 px-3 py-1.5 text-sm font-semibold text-white hover:bg-white/20`
- "Log In" uses `text-sm font-semibold text-ok-purple-200 hover:text-white`

| State | Right Zone Content |
|-------|-------------------|
| **Anonymous** | "Sign Up" (frosted button → `/users/register`) + "Log In" (text link → `/users/log-in`) |
| **Anonymous (dev mode)** | "Admin" button (gold text, `POST /dev/admin-login`) + Sign Up + Log In. The Admin button logs in as the dev super admin for quick access. |
| **Logged in** | User email + Settings link + "Log Out" |
| **Super admin** | Same as logged in + "Admin" link |

**Per-app right zone behaviour:**
- **Portal:** Full auth state (anonymous/logged-in/super-admin as above)
- **Pulse:** Always shows Sign Up + Log In (no user context — Pulse has no authentication)
- **WRT:** Shows Sign Up + Log In when no `portal_user`, or user email + Settings link when authenticated via Portal cookie

### Brand Stripe

Magenta-to-purple gradient bar sits below the header on all pages. A distinctive
visual identity element. Kept for now — may evolve as the overall design matures.

### Implementation Notes

- All apps use the shared `<.header_bar>` component from `OostkitShared.Components` (`apps/oostkit_shared/`), imported as a path dependency
- The component provides `:brand_url`, `:title`, `:title_url`, and `:actions` (slot) attrs, plus renders the brand stripe
- The centre title is absolutely positioned within the `relative` nav container using `pointer-events-none absolute inset-x-0 text-center`, ensuring true visual centering regardless of left/right content width. When `title_url` is set, the title renders as a clickable `<a>` with `pointer-events-auto`; otherwise it renders as a static `<span>`.
- Portal: `:brand_url="/"`, `:title` is conditionally set to `"Dashboard"` for logged-in users (hidden on landing page via `hide_header_title`), `:title_url="/home"` when title is shown, actions slot renders auth links
- Pulse: `:brand_url={@portal_url}`, `:title="Workgroup Pulse"`, actions slot always shows Sign Up + Log In linking to Portal
- WRT: `:brand_url={@portal_url}`, `:title="Workshop Referral Tool"`, actions slot shows Sign Up + Log In (anonymous) or email + Settings (authenticated)
- All apps: Sign Up button uses `rounded-md bg-white/10` frosted style, Log In uses text link style
- Design system tokens: `bg-ok-purple-900` header, `font-brand` (DM Sans), brand stripe gradient
- Portal additionally renders a `footer_bar` component in the root layout with links to About, Privacy, and Contact pages
- **Root layout uses a sticky footer pattern**: `<body class="flex min-h-screen flex-col">` with `<main class="flex flex-1 flex-col">` wrapping `@inner_content`. This ensures the footer bar is pushed to the bottom of the viewport on short-content pages. Individual pages no longer need their own `min-h-screen` wrappers.

---

## Auth Pages

Auth pages are for facilitators (and super admin) only. Participants never see them.
Tone is collegial — clean, simple, no selling. The facilitator is already interested
enough to sign up; make it easy and welcoming.

**Layout:** All auth pages (login, registration, forgot password, reset password,
confirmation) use a flex centering container (`flex flex-1 items-center justify-center`)
that vertically and horizontally centres the form content within the available viewport
space. Combined with the root layout's sticky footer pattern, this keeps auth forms
visually centred between the header and footer regardless of viewport height.

**Card containment:** Form content on all auth pages is wrapped in a card container
(`bg-surface-sheet shadow-sheet ring-1 ring-zinc-950/5 rounded-xl p-6`) matching the
card treatment used on the settings and admin pages. The header text (page title and
subtitle) sits above the card, while form fields, buttons, and dividers sit inside it.
This gives each auth form a clear visual boundary and consistent surface treatment
across the platform.

### Registration (`/users/register`)

**Status:** Live. Linked from header Sign Up button.

#### Registration Form

- **Email** (required)
- **Name** (required) — first and last name, single field
- **Organisation** (optional, text field) — where the facilitator works
- **How did you hear about OOSTKit?** (optional, text field) — referral source
- **Which tools are you interested in?** (optional, checkboxes) — tool interest, shown as checkboxes for all available tools
- **Submit button**: "Get started" or "Create account"
- No password at registration — magic link flow instead

#### Registration Flow

```
Facilitator clicks "Sign Up"
  → Registration page: enters name + email, plus optional org, referral source, and tool interests
  → Submits → confirmation email sent (magic link)
  → Clicks link in email
  → Logged in, lands on dashboard (fully onboarded, no further prompts)
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
- "Log in with password" button (soft primary style)
- Shown below magic link section, separated by "or use a password" divider
- Starts at reduced opacity, full opacity on focus (visual hierarchy cue)

#### "Forgot your password?" Link

Below the password section (hidden when re-authenticating). Links to `/users/forgot-password`.

#### Messaging

- Heading: "Welcome back" (or "Re-authenticate" if already logged in and performing a sensitive action)
- Subtitle adapts: re-auth context explains why, normal context links to registration
- Link to registration for new users

### Email Confirmation (`/users/log-in/:token`)

Handles magic link tokens from both registration and login. Already built.
Auto-logs in the user and redirects to dashboard.

### Settings (`/users/settings`)

Requires authentication. Where facilitators manage their account. The page loads
without requiring sudo mode — sudo checks are performed in event handlers for
sensitive actions (email change, password change, account deletion). If not in
sudo mode, the user is redirected to the login page with a message to re-authenticate.

**Layout:** Uses the "stacked sections with cards" pattern (Tailwind UI style). An
"Account Settings" title with subtitle sits at the top via the shared `<.header>` component.
Below it, sections are separated by `divide-y divide-zinc-200` dividers. Each section
uses a responsive 1/3 + 2/3 grid (`grid grid-cols-1 md:grid-cols-3 gap-x-8 gap-y-6 py-10`):

- **Left column (1/3)** — section heading (`text-base font-semibold text-text-dark`) and
  a subtitle paragraph (`text-sm text-zinc-500`) describing the section's purpose.
- **Right column (2/3)** — a card (`bg-surface-sheet shadow-sheet ring-1 ring-zinc-950/5
  rounded-xl md:col-span-2`) containing the form fields in a `p-6` content area, with a
  card footer (`border-t border-zinc-200 px-6 py-4`) housing a right-aligned save button
  (`flex justify-end`).

**Sections (stacked vertically, separated by dividers):**

- **Profile** — heading "Profile", subtitle "Your name and organisation." Name and
  organisation fields. Referral source is collected at registration only and is not
  shown on the settings page.
- **Contact Preferences** — heading "Contact Preferences", subtitle "How we communicate
  with you." A single `product_updates` checkbox labelled "Product updates" controls
  whether the user receives product update emails. Saved via a dedicated "Save Preferences"
  button.
- **Email** — heading "Email", subtitle "Change the email address associated with your
  account." Email field. Sends confirmation to new address (requires sudo mode).
- **Password** — heading "Password", subtitle "Update your password to keep your account
  secure." Password fields. Optional, for facilitators who prefer password login over
  magic links. If no password is set yet, the button label reads "Add a password" rather
  than "Change password" (requires sudo mode).
- **Danger zone** — heading "Danger zone" in `text-ok-red-600`, subtitle warns that
  deletion is irreversible. Card uses `ring-ok-red-200` instead of the default ring for
  visual warning. Red "Delete Account" button with confirmation prompt. Permanently
  deletes the user account and logs them out (requires sudo mode).

### Forgot Password (`/users/forgot-password`)

**Status:** Live. Linked from login page "Forgot your password?" link.

#### Page Layout

- Heading: "Forgot your password?"
- Subtitle: "We'll send a password reset link to your email address."
- Email field
- "Send reset link" button
- "Back to log in" link below

#### Flow

```
User clicks "Forgot your password?" on login page
  → Enters email address
  → Submits → always shows success message (prevents user enumeration)
  → "If your email is in our system, you will receive password reset instructions shortly."
  → Redirected back to login page
  → Clicks link in email → arrives at reset password page
```

### Reset Password (`/users/reset-password/:token`)

**Status:** Live. Accessed via the link in the password reset email.

#### Page Layout

- Heading: "Reset your password"
- Subtitle: "Enter a new password below."
- New password field (with live validation)
- Confirm new password field
- "Reset password" button
- "Back to log in" link below

#### Flow

```
User clicks reset link in email
  → Token is validated (if invalid/expired, redirect to login with error flash)
  → Enters new password + confirmation
  → Submits → password updated, all existing sessions invalidated
  → Flash: "Password reset successfully. Please log in."
  → Redirected to login page
```

### Data Model Implications

The user table needs additional fields beyond the current schema:

```
users (additions)
- name (text) — already exists
- organisation (text, nullable) — collected at registration
- referral_source (text, nullable) — how they heard about OOSTKit, collected at registration
- onboarding_completed (boolean, default true) — set to true at registration
- product_updates (boolean, default false) — opt-in to product update emails, managed via settings
```

Tool interest captured separately (many-to-many or simple join table):

```
user_tool_interests
- user_id (uuid)
- tool_id (text) — e.g. "workgroup_pulse", "wrt", "search_conference"
- inserted_at (timestamp)
```

Note: Organisation, referral source, and tool interests are all collected during registration.
The `onboarding_completed` flag is set to `true` at registration time. There is no separate
onboarding step — users are fully onboarded from the moment they create their account.

---

## Admin Pages

Super admin only. A full admin hub for platform management. Accessed via "Admin"
link in the header (visible only to super admins).

**Layout:** All admin pages use consistent `px-6 sm:px-8` horizontal padding with
`max-w-4xl mx-auto` centering, matching the settings page pattern. Section-level card
containers use `rounded-xl` for design system consistency with settings and auth pages.

### Admin Dashboard (`/admin`)

At-a-glance health check for the platform. Simple counts for now, charts/trends later
when there's enough data.

#### Quick Links

Displayed first, at the top of the dashboard for immediate navigation:

- "Manage users" → `/admin/users`
- "View signups" → `/admin/signups`
- "Tool status" → `/admin/tools`
- "System Status" → `/admin/status`

#### Stats Cards

- **Email signups** — total coming-soon email captures
- **Registered users** — total facilitator accounts
- **Active users** — users who've logged in recently (last 30 days)
- **Tool interest** — breakdown of which tools people selected during registration

### User Management (`/admin/users`)

Already built. Includes registration data (org, referral source, tool interests).

#### User List

Table with columns:
- Email
- Name
- Role (Super Admin / Session Manager) — colour-coded badges
- Organisation (from registration, may be blank)
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

- View all profile info including registration data (org, referral source, tool interests)
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
- Category (Learning, Workshop Management, Team Workshops)
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
- category (text) — "learning", "workshop_management", or "team_workshops"
- admin_enabled (boolean, default true) — admin override toggle
- sort_order (integer) — display order within category (unique per category)
```

This replaces the current hardcoded app config and gives the admin full control.
The `sort_order` is scoped per category (unique constraint on `[category, sort_order]`),
so each category has its own independent ordering.

### System Status (`/admin/status`)

Live operational dashboard showing app health and CI pipeline status for all deployed
apps (Portal, Pulse, WRT). Page title: "System Status". Subtitle: "App health and
CI pipeline status".

#### App Health Section

Card grid (3 columns on desktop, stacked on mobile) with one card per app. Each card shows:
- **Status dot** — green (`bg-ok-green-500`) for healthy, red (`bg-ok-red-500`) for unhealthy
- **App name** — Portal, Pulse, WRT
- **Response time** (when healthy) — e.g., "Response: 142ms"
- **Error detail** (when unhealthy) — error message or HTTP status code
- **Last checked** — timestamp of most recent health poll

Health is determined by polling each app's `/health` endpoint. A 200 response = healthy.

#### CI Status Section

Card grid (same layout) with one card per app's GitHub Actions workflow. Each card shows:
- **Status dot** — green (success), red (failure), yellow (in progress), grey (unknown)
- **App name**
- **Latest run result** — "Passed", "Failed", "Running", or the conclusion string
- **Commit SHA** — short hash of the commit that triggered the run
- **Run timestamp**
- **"View run" link** — opens the GitHub Actions workflow run in a new tab

CI status is fetched from the GitHub Actions API (most recent 5 runs on the `main` branch
per workflow). An optional `GITHUB_TOKEN` env var provides higher rate limits and access
to private repos.

#### Auto-Refresh and Manual Refresh

The page auto-refreshes every 5 minutes via a background `Portal.StatusPoller` GenServer
that broadcasts updates through PubSub. A "Refresh now" button allows manual refresh on
demand. The last polled timestamp is displayed at the bottom of the page.

#### Design

- Uses the standard admin layout (`max-w-4xl mx-auto px-6 sm:px-8`)
- Section cards use `bg-surface-sheet shadow-sheet rounded-xl border border-zinc-200`
- Section headings at `text-lg font-semibold text-text-dark`
- Waiting state: "Waiting for first health check..." / "Waiting for first CI status check..."
  displayed in muted text when no data has been polled yet

---

## Page Inventory

| Route | Page | Auth Required | Description |
|-------|------|---------------|-------------|
| `/` | Marketing landing | No | Brochure/sales page. Same for all visitors (no redirect for logged-in users). Header shows clickable "Dashboard" link for logged-in users. |
| `/home` | Dashboard | No | Tool hub. Shows all tools, lock state varies by auth. |
| `/about` | About | No | Information about OOSTKit and the team. |
| `/privacy` | Privacy Policy | No | How OOSTKit collects, uses, and protects personal data. |
| `/contact` | Contact | No | How to get in touch with the OOSTKit team. |
| `/apps/:id` | App detail / product page | No | Visual walkthrough, full description, launch or inline email capture. Shareable URL. |
| `POST /apps/:app_id/notify` | Email capture from detail page | No | Creates interest_signup with context `tool:{tool_id}`. Redirects back with `?subscribed=true`. |
| `/users/log-in` | Login | No | "Welcome back" heading. Magic link (primary) + password (secondary). "Forgot your password?" link. |
| `/users/register` | Registration | No | Name + email + optional org, referral source, tool interests. Magic link confirmation. Facilitator-focused messaging. Users are fully onboarded at registration. |
| `/users/forgot-password` | Forgot password | No | Email field, sends password reset link. Always shows success message (prevents user enumeration). |
| `/users/reset-password/:token` | Reset password | No | New password + confirmation. Token validated on mount, redirects to login on success. |
| `/users/settings` | Account settings | Yes | Stacked sections with cards (Tailwind UI pattern): Profile (name, org), Contact Preferences (product updates opt-in), Email change, Password (add/change), Danger zone (account deletion). Each section has a 1/3 description + 2/3 form card layout. Sudo checks in handlers, not on page load. |
| `DELETE /users/delete-account` | Delete account | Yes | Deletes user account and logs out. Triggered from settings page. |
| `/admin` | Admin dashboard | Super Admin | Stats overview: signup counts, user counts, tool status. |
| `/admin/users` | User management | Super Admin | Create/edit/disable user accounts. View registration data (org, referral source, tool interests). |
| `/admin/signups` | Email signups | Super Admin | View/export coming-soon email capture list. |
| `/admin/tools` | Tool management | Super Admin | View tool status, toggle tools on/off (kill switch). |
| `/admin/status` | System status | Super Admin | Live app health checks and CI pipeline status for Portal, Pulse, WRT. Auto-refreshes every 5 minutes. |
| `/coming-soon` | Holding page | No | Context-aware holding page with email capture. |
| `POST /dev/admin-login` | Dev admin login | No | Dev-only. Logs in as dev super admin and redirects to `/admin`. |

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

---

## Decisions Log

Resolved during design discussions (February 2026):

| Question | Decision | Notes |
|----------|----------|-------|
| Landing page redirect | Removed | Logged-in users no longer auto-redirect to `/home`. The header "Dashboard" link provides navigation instead. Lets logged-in users share the marketing URL without being redirected away. |
| Page title consistency | `<.header>` component | Page titles (admin pages, settings page title) use the `<.header>` component from `OostkitShared.Components` at `text-2xl font-bold`. Settings section headings within the page use plain `<h2>` elements at `text-base font-semibold` as part of the stacked-sections card layout. |
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

- Admin dashboard trends (charts/time-series once there's enough data)

---

## Open Questions

- What visual assets are needed for the marketing page? (Illustrations, screenshots, animations showing tools in use)
- What content goes on the "Learn about OST" section when it's built?
- When Pulse eventually requires login to create sessions, what happens to existing sessions created anonymously?
