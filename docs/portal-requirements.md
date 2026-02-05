# Portal Requirements

This document captures the requirements for the OOSTKit portal - the front end that serves as the entry point to all platform tools.

## Overview

The portal is a landing page and authentication hub that:
- Introduces OOSTKit and its purpose
- Routes users to the appropriate tool
- Provides shared authentication across all apps
- Maintains a consistent design language

## Goals

1. Help users find and access the right tool quickly
2. Provide a unified OOSTKit identity across apps
3. Centralize authentication for apps that require it
4. Present tools organized by audience

## Non-Goals (for initial release)

- Aggregated dashboards or cross-app data views
- Persistent workshop data storage
- Self-service account registration
- Deep integration between apps

---

## Information Architecture

### Landing Page

A split-view design organized by audience:

| Tools for Facilitators | Tools for Teams |
|------------------------|-----------------|
| Workshop Referral Tool | Workgroup Pulse |
| (future tools...)      | (future tools...) |

**Content:**
- Brief introduction to OOSTKit and its purpose
- Tool cards with name, short description, and link
- "Learn more" links to dedicated app pages
- Future: "Learn about OST" section

**Design principle:** The front page is for people who know what they want - quick selection, minimal friction.

### App Detail Pages

One page per app with:
- Longer description of the tool
- Use cases / when to use it
- Link to launch the app
- (Future: screenshots, video, documentation links)

### Future Pages

- Learn about OST / methodology background
- Pricing (when apps become paid)
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
   - Consistent logo and navigation
   - "Home" link returns to portal
   - Login state displayed in header
   - App-specific navigation below shared header

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

| Role | Description | Access |
|------|-------------|--------|
| Super Admin | Platform owner | All apps, account management, platform settings |
| Session Manager | Facilitator running workshops | Apps they have access to (e.g., WRT) |
| Participant | Invited via email/link | Session-specific access, no account needed |

**Note on terminology:** OST uses "manager" rather than "facilitator" - these are session managers.

### Initial Scope

For the first release:
- Super Admin can create Session Manager accounts
- Session Managers log in to access WRT
- Workgroup Pulse remains open (no login required)
- Participants access sessions via magic links (no account)

### Account Management

Portal admin page for:
- Creating session manager accounts
- Viewing/editing existing accounts
- Disabling/enabling accounts
- (Future: self-service registration, organization management)

### Future Considerations

- Self-service account creation (when apps are paid)
- Organization-level accounts and billing
- Role-based access to specific apps
- Persistent data access requiring authentication

---

## User Experience

### Navigation Flow

```
[Portal Landing Page]
        |
        ├── Click tool card → [App launches with shared header]
        │                            |
        │                            └── Click "Home" → [Portal Landing Page]
        │
        ├── Click "Learn more" → [App Detail Page]
        │                            |
        │                            └── Click "Launch" → [App]
        │
        └── Click "Login" → [Login Page]
                                |
                                └── Success → [Portal with authenticated state]
```

### Login-Required Apps

When a user clicks on an app that requires authentication:
1. If logged in → App launches
2. If not logged in → Redirect to portal login
3. After login → Redirect back to requested app

### Consistent Header

All apps display a shared header:
- OOSTKit logo (links to portal home)
- Navigation options (TBD)
- Login/account status
- App-specific content appears below

---

## Visual Design

### Design Language

- Consistent across portal and all apps
- Professional, approachable, not overly corporate
- Reflects OST values (collaboration, participation, human-centered)

### Shared Elements

- Logo and wordmark
- Color palette
- Typography scale
- Button and form styles
- Card components
- Header layout

### Implementation

- Shared Tailwind configuration
- Possibly a shared CSS file or Hex package
- Design tokens for colors, spacing, etc.

---

## App Visibility

### Public Apps (no login required to see or use)

- Workgroup Pulse - anyone can create/join a session

### Login-Required Apps (visible to all, require login to use)

- Workshop Referral Tool - session managers only

### Future: Role-Gated Apps

- Some apps may only be visible to certain roles
- Logged-in users may see additional apps

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

Options to evaluate:
- Phoenix built-in auth (phx.gen.auth)
- Guardian / JWT tokens
- Session cookies with subdomain scope

Key requirements:
- Secure password hashing
- Session management
- Cross-subdomain cookie support
- (Future: OAuth providers, magic links)

---

## Decisions

1. **Domain:** oostkit.com (registered)
2. **Branding:** Use placeholder logo/assets initially, create proper branding later
3. **WRT integration:** Replace WRT's auth entirely when portal auth is ready
4. **App metadata:** Config file versioned in git (simple, easy to update)
5. **Analytics:** Nice to have, implement later (not in initial phases)

---

## Phases

### Phase 1: Foundation
- Portal app with landing page
- App cards linking to existing apps
- Basic authentication (super admin + session managers)
- Account management for super admin
- Shared header styles (portal only initially)

### Phase 2: Unified Experience
- App detail pages
- Shared header integrated into Workgroup Pulse and WRT
- Subdomain cookie authentication working across apps
- WRT uses portal auth instead of its own

### Phase 3: Enhanced Features
- "Learn about OST" content section
- Self-service registration (if/when needed)
- Organization management
- Usage analytics

---

## Related Documents

- [Product Vision](product-vision.md)
- [Architecture](architecture.md)
- [WRT Requirements](../apps/wrt/REQUIREMENTS.md)
- [Workgroup Pulse Requirements](../apps/workgroup_pulse/REQUIREMENTS.md)
