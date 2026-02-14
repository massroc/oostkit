# Workgroup Pulse - UX Design Specification

**Audience:** Designers, product owners, anyone asking "why does it look this way?"
**Changes when:** Visual design, layout principles, or accessibility requirements change.

---

## 1. Design Principles

### Content First, Chrome Last
- The scoring grid is the star of the show — it dominates the screen as a paper-textured sheet
- UI elements (buttons, navigation, controls) float above the grid as overlays
- The accumulating scores *are* the interface

### Sheet Carousel Metaphor
- The screen evokes sheets of butcher paper arranged on a table
- Paper texture, subtle shadows, and slight rotation give a physical feel
- **Current implementation:** Only the active sheet is visible; inactive slides are hidden. Navigation is server-driven (phase transitions and buttons).
- **Planned (future):** Adjacent sheets may peek from behind (scaled, slightly rotated, dimmed) and be clickable to navigate — not abandoned, lower priority for now.
- See [ux-implementation.md](ux-implementation.md) for the technical implementation (CSS classes, JS hook, slide index map).

### Clear Visual Hierarchy
- Use size, weight, and color to indicate importance
- Most important element (the grid) is largest and centred
- Side panels provide context without competing for attention
- Disabled/inactive states clearly differentiated

### Progressive Disclosure
- Show only what's needed at each moment
- Facilitator tips hidden behind expandable "More tips" button
- Notes panel peeks as a 70px read-only preview from the right edge (visible on scoring, summary, and wrap-up screens); clicking reveals the full 480px editable panel. The peek tab should include a visible label or icon (e.g., "Notes") and an `aria-label` so its purpose is clear to sighted and screen-reader users.
- Score overlay opens when participant clicks their cell in the scoring grid. Since the overlay no longer auto-opens, the "your turn" state must be highly visible — gold "Your turn to score" prompt, plus a subtle pulse or border on the participant's column/cell. First-time users should see a one-off hint ("Click your cell to add your score") if onboarding is implemented.
- "Discuss your score" popup appears after submitting; "Discuss the scores as a team" appears when all turns complete

---

## 2. Layout Architecture

All phases use the same **sheet carousel** layout. Only the active slide is visible (inactive slides are `display: none`). Future enhancement: adjacent sheet peeks for click-to-navigate.

```
┌─────────────────────────────────────────────────────────────────┐
│  Header (OOSTKit → Portal | "Workgroup Pulse" abs. centred | Sign Up + Log In) │
├─────────────────────────────────────────────────────────────────┤
│  SHEET CAROUSEL (bg: warm taupe #E8E4DF)                         │
│                                                                   │
│              ┌──────────────────────────────┐                   │
│              │                              │                   │
│              │  Active Sheet (paper texture)  │                   │
│              │  (centred, 960px, full focus)  │                   │
│              │                              │                   │
│              └──────────────────────────────┘                   │
│                                                                   │
│                     [Floating action buttons, bottom-right]       │
└─────────────────────────────────────────────────────────────────┘
```

### Unified Slide Map

All workshop phases (except lobby) share a single unified carousel. Slides are progressively appended as the workshop advances through phases.

| Index | Content | Width | Available When |
|-------|---------|-------|---------------|
| 0 | Welcome | 960px | always (carousel shown when state != "lobby") |
| 1 | How It Works | 960px | always |
| 2 | Balance Scale | 960px | always |
| 3 | Maximal Scale | 960px | always |
| 4 | Scoring Grid | 960px | state in scoring/summary/completed |
| 5 | Summary | 960px | state in summary/completed |
| 6 | Wrap-up | 960px | state == completed |

Lobby renders as a standalone single slide (no hook, no carousel navigation).

**Notes/Actions Panel:** Notes and actions are presented in a fixed-position panel on the right edge of the viewport, not as a carousel slide. A 70px read-only peek is visible on slides 4-6 (scoring, summary, wrap-up). Clicking the peek reveals a 480px editable panel; clicking outside dismisses it.

### Floating Action Buttons

Viewport-fixed bar aligned to the 960px sheet width. Always visible at the bottom of the sheet area — no scrolling required to reach action buttons. Each phase renders its own set of buttons; lobby has no floating buttons (Start Workshop is inline). FABs are hidden when browsing slides outside the current phase (e.g., reviewing intro slides during scoring).

| Button | Phase | Shown When | Style |
|--------|-------|-----------|-------|
| Skip intro | Intro (carousel_index == 0) | First intro slide only | Text link |
| Next | Intro (carousel_index 0-2) | Intro slides before last | Primary (gradient) |
| Next (→ scoring) | Intro (carousel_index == 3) | Last intro slide | Primary (gradient) |
| Done | Scoring | Current turn participant, after scoring | Primary (gradient) |
| ← Prev Question | Scoring | Facilitator, after Q1 | Secondary |
| Next Question | Scoring | Facilitator, all participants ready | Primary |
| Continue to Summary | Scoring (last Q) | Facilitator, all participants ready | Primary |
| I'm Ready | Scoring | Non-facilitator, after all turns complete | Primary |
| ← Back | Summary, Wrap-up | All participants (carousel nav to prev slide) | Secondary |
| Summary → | Scoring (review) | All participants, when state past scoring | Primary |
| Continue to Wrap-Up | Summary | Facilitator (active summary state) | Primary |
| Wrap-Up → | Summary (review) | All participants, when state is completed | Primary |

**Skip Turn** is rendered inline in the scoring grid cell (not as a floating button). **Finish Workshop** is rendered inside the wrap-up sheet (not floating).

---

## 3. Visual Design

### Design System

The app follows the shared **Desirable Futures Workshop Design System** documented in `/docs/design-system.md`. Key decisions are summarised here; refer to the design system for implementation details and Tailwind classes.

**Reference:** https://www.desirablefutures.group/

### Theme: Light

All workshop apps use a **light theme** with warm off-white backgrounds, replacing the earlier dark theme concept.

### Color Palette

| Role | Color | Value |
|------|-------|-------|
| Wall Background | Warm taupe | `#E8E4DF` |
| Sheet Surface | Cream (paper texture) | `#FEFDFB` |
| Sheet Secondary | Light gray | `#F5F3F0` |
| Ink (on-sheet content) | Deep blue | `#1a3a6b` |
| UI Text | Dark gray | `#333333` |
| Primary Accent | Purple | `#7245F4` |
| Secondary Accent | Magenta | `#BC45F4` |
| Warm Accent | Gold | `#F4B945` |
| Alert Accent | Accent-red | `#F44545` |
| Traffic Green | Green | `#22c55e` |
| Traffic Amber | Amber | `#f59e0b` |
| Traffic Red | Red | `#ef4444` |

#### Accent Color Usage

The three accent colors (magenta, gold, accent-red) serve distinct semantic roles across the UI:

| Accent | Semantic Role | Used In |
|--------|--------------|---------|
| **Magenta** (`accent-magenta`) | Interactive focus / user identity | Input focus rings (notes, actions), action items section header and bullets, discussion tips in score overlay, "You" badge in lobby |
| **Gold** (`accent-gold`) | Warmth / readiness / positive status / strengths | Welcome blockquote border, ready checkmarks (individual and all-ready), timer active state icon, new workshop "+" icon, "your turn to score" prompt, intro carousel progress dots, duration button selected state, strengths section (header, icons, background), PDF export strengths |
| **Accent-red** (`accent-red`) | Concerns / warnings / emphasis | Concerns section (header, icons, background), scale endpoint labels (balance -5/+5, maximal 0), error messages |

**Note:** Accent-red (`#F44545`) is semantically distinct from traffic-red (`#ef4444`). Traffic-red is reserved for score traffic-light indicators; accent-red is used for concerns, warnings, and emphasis in non-scoring contexts.

See `/docs/brand-colors.md` for the complete palette.

### Typography

| Use | Font | Notes |
|-----|------|-------|
| UI Chrome | DM Sans | Headers, buttons, labels |
| Workshop Content | Caveat | Scores, criteria names, notes (handwritten feel) |

**Page title (H1) sizing:** All page-level H1 headings use `text-2xl font-bold` to match the Portal standard. This applies to the create page, join page, lobby, and intro slides. Scoring, summary, and wrap-up phases may use different heading sizes appropriate to their content density.

### Style Direction

- **Light, warm, physical** — evokes paper and markers on a wall
- **Paper texture** — SVG noise overlays on sheet surfaces for tactile feel
- **Multi-layer shadows** — sheets lift on hover, creating depth
- **Subtle rotation** — sheets have slight CSS rotation for a natural, pinned-to-wall feel
- **High contrast** — ink-blue text on cream paper for readability
- **Generous whitespace** — breathing room within sheets

### Traffic Light Colors

Traffic lights use semantic Tailwind classes (`text-traffic-green`, `text-traffic-amber`, `text-traffic-red`) for consistent application across scores, summaries, and indicators.

---

## 4. Interaction Patterns

### Feedback & States
- Scores auto-submit with immediate visual feedback in the grid
- Loading states for async operations (avoid spinners where possible)
- Success/error states communicated via flash messages
- Hover and focus states for all interactive elements

### Transitions
- Score overlay entrance animation (`score-overlay-enter` keyframe)
- Panel focus transitions (300ms duration)
- Sheet lift on hover with shadow transition
- Never animate in a way that delays user action

### Touch & Click Targets
- Minimum 44x44px touch targets (WCAG recommendation)
- Score buttons are full-width flex items for easy tapping
- Entire note cards and sheet panels are clickable

### Error Prevention & Recovery

**Prevent Errors:**
- Disable "Next Question" until all participants are ready
- Auto-save scores immediately on selection
- Confirm destructive actions (delete notes, skip turn)

**Recover from Errors:**
- Clear error messages via flash
- Easy path back (facilitator Back button)
- Never lose user work due to errors

### Responsive Design

| Size | Target | Considerations |
|------|--------|----------------|
| Mobile (< 640px) | Phones | Single column, larger touch targets |
| Tablet (640-1024px) | iPads, small laptops | Comfortable grid view |
| Desktop (> 1024px) | Primary use case | Full grid with side panels |

**Mobile Considerations:**
- **< 640px (phones):** Scoring grid uses horizontal scroll with a visible scroll cue (e.g., fading edge or scroll indicator). FABs must not cover critical grid content — position below or use a thin bottom bar. Side panels become full-screen overlays.
- Score overlay is full-width on mobile (`mx-4` margin)
- Intro slides and summary content stack vertically in single column

---

## 5. Accessibility

- **Target: WCAG AA compliance**
- Semantic HTML structure
- Full keyboard navigation
- Screen reader compatible
- Sufficient color contrast
- Focus indicators
- Alt text for any images/icons

---

## 6. Design System Reference

The platform-wide design system is documented at [`/docs/design-system.md`](/docs/design-system.md). It covers:
- Tailwind preset tokens (colors, typography, spacing, shadows, z-index)
- Brand colors and palette
- Component patterns shared across all workshop apps

For the **implementation** of these design decisions (CSS classes, JS hooks, sheet dimensions, responsive breakpoints), see [ux-implementation.md](ux-implementation.md).

---

*Document Version: 1.8 — Standardized page title (H1) sizing to `text-2xl font-bold` across all pre-scoring phases, matching Portal standard*
*Created: 2026-02-07*
*Updated: 2026-02-12*
