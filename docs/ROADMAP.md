# OOSTKit Platform Roadmap

Last updated: 2026-02-06

## Platform Overview

OOSTKit is a monorepo with three Elixir/Phoenix applications, all deployed to Fly.io (Sydney region).

| App | Purpose | Status | Port |
|-----|---------|--------|------|
| **Portal** | Landing page & auth hub | Phase 1 complete | 4002 |
| **Workgroup Pulse** | 6 Criteria workshop (self-guided) | MVP complete, UX redesign in progress | 4000 |
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

**Current work**: UX redesign preparation
- PostHog analytics integration added
- Component audit documented
- Design system defined (see `docs/design-system.md`)

**Deferred to Phase 2**:
- Export (CSV/PDF)
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

**Test coverage**: 1,185 lines, 7 test suites (infrastructure solid, gaps in context tests)

**Outstanding items**:
- One TODO: Data retention warning emails
- Test coverage gaps in business logic contexts

---

## Current Sprint: Pulse Visual Redesign

### Objective

Apply the design system (documented in `docs/design-system.md`) to the Workgroup Pulse app. This visual foundation will then be shared across all apps.

### Approach

1. **Reference design** - Use the design system spec and any visual mockups as the source of truth
2. **Apply Tailwind preset** - Implement the shared `tailwind.preset.js` with design tokens
3. **Component-by-component** - Work through each phase/component, updating styles
4. **Preserve functionality** - Handle any breaking changes to flow management carefully
5. **Test parity** - Ensure all 241 tests continue to pass

### Key Design Elements

From `docs/design-system.md`:
- **Virtual Wall metaphor** - Sheets of butcher paper on a wall
- **Light theme** - Warm taupe wall (`#E8E4DF`), cream paper (`#FEFDFB`)
- **Typography** - DM Sans (UI chrome), Caveat (workshop content)
- **Paper texture** - SVG noise for tactile feel
- **Color system** - Traffic lights for scores, purple accent for interactions

### Success Criteria

- Pulse app matches the design system visually
- All existing tests pass
- Tailwind preset ready for Portal and WRT adoption

---

## Next Phase: WRT Testing & Refinement

After the Pulse visual redesign is complete:

1. **Review WRT functionality** - Walk through all user flows
2. **Expand test coverage** - Add context unit tests for Campaigns, Rounds, People
3. **Apply design system** - Bring WRT visual design in line with Pulse
4. **Address outstanding TODO** - Implement data retention warning emails

---

## Future Roadmap

### Portal Phase 2: Unified Experience

- Shared header component across all apps
- Subdomain routing (oostkit.com, pulse.oostkit.com, wrt.oostkit.com)
- Cross-subdomain cookie authentication
- WRT migrates to Portal auth (replaces its own auth)

### Pulse Phase 2: Enhanced Features

- Export (CSV, PDF)
- Integration with Portal authentication
- Persistent teams (requires accounts)
- Historical session comparison

### WRT Enhancements

- Full Portal auth integration
- Visual design alignment
- Expanded test coverage

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
