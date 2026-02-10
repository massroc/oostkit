# OOSTKit Platform Roadmap

Last updated: 2026-02-10

## Platform Overview

OOSTKit is a monorepo with three Elixir/Phoenix applications, all deployed to Fly.io (Sydney region).

| App | Purpose | Status | Port |
|-----|---------|--------|------|
| **Portal** | Landing page & auth hub | Phase 1 complete | 4002 |
| **Workgroup Pulse** | 6 Criteria workshop (self-guided) | MVP + UX redesign + export complete | 4000 |
| **WRT** | Workshop Referral Tool (facilitator) | All 6 phases complete | 4001 |

---

## Current App Status

### Portal

**Phase 1: Foundation** - Complete

- User authentication (password + magic link)
- Super admin user management (CRUD)
- Landing page with app cards (split by audience)
- Session-based auth with sudo mode
- Role system (Super Admin, Session Manager)
- OOSTKit design system applied (branded semantic tokens, DM Sans, brand stripe, navigation header)

**Test coverage**: 787 lines across 9 test files

**Next milestone**: Phase 2 - Unified Experience
- Integrate shared header into Pulse and WRT
- Subdomain cookie auth across apps
- Migrate WRT to use Portal authentication

### Workgroup Pulse

**MVP** - Complete

Core features working:
- Full workshop flow (all 8 questions, both scoring scales)
- Turn-based sequential scoring with real-time sync
- Session creation with shareable links
- Facilitator timer with presets
- Observer mode, skip participant, facilitator tips
- Discussion notes per question
- Action planning with owner assignment
- Summary view with traffic light indicators

**Test coverage**: 241 test cases - excellent TDD coverage

**UX redesign** — Complete
- PostHog analytics integration added
- Design system defined and applied (see `docs/design-system.md`)
- Virtual Wall scoring screen: full 8-question grid, floating score overlay, three-panel layout
- Light theme with paper texture, handwritten fonts, warm colour palette
- Sheet carousel with coverflow effect, side panel for notes
- Auto-submit scoring (no separate Submit button), click-to-edit
- Petal Components installed with OOSTKit brand colours
- Export: Full and Team reports with CSV & PDF

**Deferred to Phase 2**:
- Authentication integration with Portal
- Persistent teams
- Historical comparison

### WRT (Workshop Referral Tool)

**All 6 Phases** - Complete

- Multi-tenancy (schema-per-org via Triplex)
- Super admin org approval/suspension
- Campaign lifecycle (Draft → Active → Completed)
- Round management with deadline control
- Seed group CSV upload + manual entry
- Magic link auth for nominators
- Nomination collection with single-ask constraint
- Email system (Postmark/SendGrid) with webhook tracking
- CSV/PDF export and reporting
- Rate limiting, health checks, structured logging

**Test coverage**: 1,185+ lines across 13+ test suites (comprehensive coverage including context unit tests and controller integration tests)

**Recently completed**:
- OOSTKit design system applied (shared Tailwind preset, branded semantic tokens, DM Sans font, brand stripe)
- Data retention warning emails (PR #106)
- Context tests for 6 business logic modules (PR #103)
- Controller integration tests across all routes (PR #104)

---

## Completed Sprints

### Pulse Visual Redesign — Done

Applied the design system (`docs/design-system.md`) to Workgroup Pulse (PRs #78–#102):
- Virtual Wall metaphor with sheet carousel and coverflow effect
- Light theme: warm taupe wall, cream paper, paper textures
- Typography: DM Sans (UI chrome), Caveat (workshop content)
- Traffic light colour system, purple accent for interactions
- Petal Components installed with OOSTKit brand colours
- All 241+ tests passing

### WRT Testing & Refinement — Done

Completed all planned items (PRs #103–#106):
- Context unit tests for 6 business logic modules
- Controller integration tests across all routes
- Data retention warning emails implemented

### Portal Visual Design Alignment — Done

Applied the OOSTKit design system to Portal, completing design consistency across all three apps:
- Generic Tailwind colors (zinc, emerald, rose, amber, purple, blue) replaced with branded semantic tokens (ok-purple, ok-green, ok-red, ok-gold, ok-blue)
- Cards migrated to `bg-surface-sheet shadow-sheet`
- Headings use `text-text-dark`, body uses `bg-surface-wall font-brand`
- DM Sans brand font loaded via Google Fonts in root layout
- New branded navigation header with `bg-ok-purple-900` and nav links
- Brand stripe (magenta-to-purple gradient) added below header
- Primary buttons use `bg-ok-purple-600`, links use `text-ok-purple-600`
- Footer uses `bg-surface-sheet-secondary`, empty states and table hover rows use `bg-surface-sheet-secondary`
- Status badges use branded ok-purple, ok-blue, ok-green, ok-red tokens
- All templates updated: landing page, app detail, admin users, error pages, core components

### WRT Visual Design Alignment — Done

Applied the OOSTKit design system to WRT, bringing it in line with Pulse:
- Generic Tailwind colors replaced with branded semantic tokens (ok-purple, ok-green, ok-red, ok-gold, ok-blue)
- Cards migrated to `bg-surface-sheet shadow-sheet`
- Headings use `text-text-dark`, body uses `bg-surface-wall font-brand`
- DM Sans brand font loaded via Google Fonts
- Brand stripe (magenta-to-purple gradient) added below headers in all layouts
- App branding corrected: "WRT" page title suffix, "Workshop Referral Tool" header name
- All templates updated across nominator, org admin, super admin, registration, and public pages

### Pulse Export — Done

Full and Team reports with CSV & PDF export (PR #105). Originally deferred to Phase 2, shipped early.

---

## Next Up

### Pulse: Remaining Feature Gaps

- [ ] Timer: pacing indicator (on track/behind)
- [ ] Timer: pause/resume controls
- [ ] Facilitator Assistance button (contextual help beyond tips)
- [ ] Feedback button
- [ ] Participant dropout handling (greyed out visual)

### Visual Design Alignment — Done (all apps)

- [x] Apply OOSTKit design system to Pulse (original design system target)
- [x] Apply OOSTKit design system to WRT (PR #108)
- [x] Apply OOSTKit design system to Portal (PR #109)

---

## Future Roadmap

### Portal Phase 2: Unified Experience

- Shared header component across all apps
- Subdomain routing (oostkit.com, pulse.oostkit.com, wrt.oostkit.com)
- Cross-subdomain cookie authentication
- WRT migrates to Portal auth (replaces its own auth)

### Pulse Phase 2: Enhanced Features

- ~~Export (CSV, PDF)~~ — Shipped (PR #105)
- Integration with Portal authentication
- Persistent teams (requires accounts)
- Historical session comparison

### WRT Enhancements

- Full Portal auth integration
- ~~Visual design alignment with design system~~ — Shipped
- ~~Expanded test coverage~~ — Shipped (PRs #103, #104)

### Platform-Wide

- Usage analytics dashboards
- Self-service registration (currently admin-only)
- Organization/team management

---

## Technical Debt & Notes

### Shared Infrastructure

- **CI/CD**: Path-filtered GitHub Actions workflows
- **Deployment**: Fly.io, Sydney region, auto-scaling machines
- **Design system**: `docs/design-system.md` + `shared/tailwind.preset.js`

### Testing Standards

All apps follow TDD:
1. Run existing tests first
2. Write new tests before/alongside implementation
3. Update tests when behavior changes
4. All tests must pass before work is complete

### Git Workflow

- Never push directly to main (branch protection enabled)
- Use `/ship` to create PRs
- One PR per app when possible
- `strict: false` allows concurrent work on different apps

---

## Related Documents

- [Product Vision](./product-vision.md) - Strategic overview
- [Architecture](./architecture.md) - Technical architecture
- [Design System](./design-system.md) - Visual design specification
- [Portal Requirements](./portal-requirements.md) - Portal feature spec
- [Portal Implementation Plan](./portal-implementation-plan.md) - Portal technical plan
- App-specific docs in `apps/*/REQUIREMENTS.md` and `apps/*/SOLUTION_DESIGN.md`
