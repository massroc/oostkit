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
- Adjacent sheets peek from behind with a subtle coverflow effect — scaled down, slightly rotated, dimmed, and overlapping the active sheet
- Clickable to navigate
- See [ux-implementation.md](ux-implementation.md) for the technical implementation (CSS classes, JS hook, coverflow parameters, slide index map)

### Clear Visual Hierarchy
- Use size, weight, and color to indicate importance
- Most important element (the grid) is largest and centred
- Side panels provide context without competing for attention
- Disabled/inactive states clearly differentiated

### Progressive Disclosure
- Show only what's needed at each moment
- Facilitator tips hidden behind expandable "More tips" button
- Notes panel peeks as a 70px read-only preview from the right edge (visible on scoring, summary, and wrap-up screens); clicking reveals the full 480px editable panel
- Score overlay opens when participant clicks their cell in the scoring grid
- "Discuss your score" popup appears after submitting; "Discuss the scores as a team" appears when all turns complete

---

## 2. Layout Architecture

All phases use the same **sheet carousel** layout — a scroll-snap horizontal container centring the active slide with adjacent slides peeking:

```
┌─────────────────────────────────────────────────────────────────┐
│  Header (app name, gradient accent)                              │
├─────────────────────────────────────────────────────────────────┤
│  SHEET CAROUSEL (bg: warm taupe #E8E4DF)                         │
│                                                                   │
│  ┌─────┐   ┌──────────────────────────────┐   ┌─────┐           │
│  │dim  │   │                              │   │dim  │           │
│  │prev │   │  Active Sheet (paper texture) │   │next │           │
│  │slide│   │  (centred, full size)         │   │slide│           │
│  └─────┘   └──────────────────────────────┘   └─────┘           │
│                                                                   │
│                     [Floating action buttons, bottom-right]       │
└─────────────────────────────────────────────────────────────────┘
```

### Unified Slide Map

All workshop phases (except lobby) share a single unified carousel. Slides are progressively appended as the workshop advances through phases.

| Index | Content | Width | Available When |
|-------|---------|-------|---------------|
| 0 | Welcome | 720px | always (carousel shown when state != "lobby") |
| 1 | How It Works | 720px | always |
| 2 | Balance Scale | 720px | always |
| 3 | Safe Space | 720px | always |
| 4 | Scoring Grid | 720px | state in scoring/summary/completed |
| 5 | Summary | 720px | state in summary/completed |
| 6 | Wrap-up | 720px | state == completed |

Lobby renders as a standalone single slide (no hook, no carousel navigation).

**Notes/Actions Panel:** Notes and actions are presented in a fixed-position panel on the right edge of the viewport, not as a carousel slide. A 70px read-only peek is visible on slides 4-6 (scoring, summary, wrap-up). Clicking the peek reveals a 480px editable panel; clicking outside dismisses it.

### Floating Action Buttons

Viewport-fixed bar aligned to the 720px sheet width. Always visible at the bottom of the sheet area — no scrolling required to reach action buttons. Each phase renders its own set of buttons; lobby has no floating buttons (Start Workshop is inline). FABs are hidden when browsing slides outside the current phase (e.g., reviewing intro slides during scoring).

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
| Score High / Success | Gold | `#F4B945` |
| Score Low / Warning | Red | `#F44545` |
| Traffic Green | Green | `#22c55e` |
| Traffic Amber | Amber | `#f59e0b` |
| Traffic Red | Red | `#ef4444` |

See `/docs/brand-colors.md` for the complete palette.

### Typography

| Use | Font | Notes |
|-----|------|-------|
| UI Chrome | DM Sans | Headers, buttons, labels |
| Workshop Content | Caveat | Scores, criteria names, notes (handwritten feel) |

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
- Grid may need horizontal scroll or condensed view
- Score overlay is full-width on mobile (mx-4 margin)
- Side panels may stack or become drawers

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

*Document Version: 1.0*
*Created: 2026-02-07*
