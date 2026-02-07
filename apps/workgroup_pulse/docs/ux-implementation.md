# Workgroup Pulse - UX Implementation

**Audience:** Developers modifying CSS, JS hooks, or component markup.
**Changes when:** CSS systems, JS hooks, carousel behaviour, sheet dimensions, or UI components change.

For the **design rationale** behind these decisions (principles, visual design, accessibility), see [ux-design.md](ux-design.md).

---

## 1. Sheet Stack System

The sheet stack is the universal layout system for all Pulse workshop phases. Every phase renders its content inside one or more stack slides, providing consistent centering, coverflow transforms, and navigation.

### CSS Classes

| Class | Purpose |
|-------|---------|
| `.sheet-stack` | Outer container — flex, centres single-slide layouts (lobby) |
| `.sheet-stack-slide` | Individual slide — `display: none` by default, flex when active |
| `.sheet-stack-slide.stack-active` | Active slide — `display: flex`, visible and interactive |
| `.sheet-stack-slide.stack-inactive` | Inactive — `display: none`, hidden |

### JS Hook: `SheetStack` (simple show/hide)

Minimal JS hook — the server (LiveView) is the sole authority on stack position via `data-index`. The hook reads it on every `updated()` call and toggles `stack-active` / `stack-inactive` classes. Only the active slide is visible (`display: flex`); all others are hidden (`display: none`). No transforms, no click-to-navigate on inactive slides.

**`_applyPositions()`:** Clears any leftover inline styles and applies `stack-active` to the current slide, `stack-inactive` to all others.

### Unified Carousel

All workshop phases (except lobby) share a single carousel element:

| ID | Element | Hook? | Click-only? |
|----|---------|-------|-------------|
| (none) | Lobby — standalone single slide, no hook | No | N/A |
| `workshop-carousel` | All other phases — unified 7-slide stack | Yes (`SheetStack`) | Yes |

### Unified Slide Index Map

Slides are progressively appended as the workshop advances. Indices are stable — slides are never removed.

| Index | Slide | Width | Rendered When |
|-------|-------|-------|--------------|
| 0 | Welcome | 720px | always |
| 1 | How It Works | 720px | always |
| 2 | Balance Scale | 720px | always |
| 3 | Safe Space | 720px | always |
| 4 | Scoring Grid | 720px | state in scoring/summary/completed |
| 5 | Summary | 720px | state in summary/completed |
| 6 | Wrap-up | 720px | state == completed |

- `data-index` is driven by `@carousel_index` (set by event handlers and state transitions)
- The `focus_sheet` event updates `@carousel_index` (`:main` → 4) or sets `notes_revealed: true` (`:notes`)
- Phase transitions set `@carousel_index` automatically (e.g., scoring → 4, summary → 5, completed → 6)
- Click-only: no scroll/swipe navigation — users click inactive slides to navigate

### IntroComponent Slide Functions

`IntroComponent` exposes 4 public function components rendered directly in the unified carousel:

- `IntroComponent.slide_welcome/1`
- `IntroComponent.slide_how_it_works/1`
- `IntroComponent.slide_balance_scale/1`
- `IntroComponent.slide_safe_space/1`

Each accepts an optional `class` attr (defaults to `"shadow-sheet p-6 w-[720px] h-full"`). All slides render at full 720px in the unified carousel.

### Server-Side Dispatch

The `carousel_navigate` handler in `EventHandlers` uses a single clause:

```elixir
def handle_carousel_navigate(socket, "workshop-carousel", index)  # updates carousel_index
def handle_carousel_navigate(socket, _carousel, _index)           # no-op fallback
```

### Notes/Actions Side Panel

The notes/actions panel is **not** a carousel slide. It is a fixed-position panel on the right edge of the viewport (z-20), outside the carousel DOM.

- **Peek tab** (40px wide) is visible when the scoring grid is active (`carousel_index == 4`)
- **Reveal:** Clicking the peek tab fires `reveal_notes`, setting `notes_revealed: true` and sliding in a 480px panel
- **Dismiss:** Clicking outside the panel (transparent backdrop at z-10) fires `hide_notes`, setting `notes_revealed: false`
- `handle_focus_sheet(:notes)` sets `notes_revealed: true` instead of changing the carousel index

### Intro Slides in Later Phases

During scoring and later phases, the intro slides are hidden (not visible as stacked peeks). Only the active slide is shown.

---

## 2. Sheet Dimensions & Overflow

### Standard Dimensions

- **Width**: 720px (all primary sheets), 480px (notes side panel and intro context slides in scoring)
- **Height**: `calc(100vh - 52px - 3rem)` — fills available viewport minus header (52px) and carousel padding (1.5rem x 2)
- **Min-height**: 879px — flipchart ratio floor based on Post-it Easel Pad (635mm x 775mm = 0.819 W:H; 720/0.819 = 879)

### CSS Overflow Rules

Content scrolls within the sheet when it exceeds the available height; no scrollbar when it fits:

```css
.sheet-stack-slide .paper-texture > div,
.sheet-stack-slide .paper-texture-secondary > div {
  height: 100%;
  overflow-y: auto;
  padding-bottom: 5rem;
}
```

This is CSS-driven — no JS intervention needed. The sheet is the scroll container, not the page. The `padding-bottom: 5rem` ensures content isn't hidden behind the fixed floating action buttons.

---

## 3. Floating Action Buttons

### Positioning

Viewport-fixed bar (`fixed bottom-10 z-50`) that is 720px wide, horizontally centred (`left-1/2 -translate-x-1/2`), with padding matching the sheet.

The container uses `pointer-events-none` with `pointer-events-auto` on the inner button wrapper, so clicks pass through to the sheet except where buttons are.

### Rendering

Floating action buttons are rendered by `FloatingButtonsComponent` — a pure functional component called from `show.ex`'s `render/1`. This ensures they're always visible without scrolling, positioned at the bottom-right of the sheet's visual area. Each phase renders its own set of buttons via phase-specific private functions; lobby has no floating buttons (Start Workshop is inline).

### Per-Phase Button Inventory

| Button | Phase | Shown When | Style |
|--------|-------|-----------|-------|
| Skip intro | Intro (slide 0 only) | First intro slide only | Text link |
| ← Back | Intro (slides 1-3) | Not on first intro slide | Secondary |
| Next → | Intro (slides 0-2) | Before last intro slide | Primary (gradient) |
| Start Scoring → | Intro (slide 3) | Last intro slide | Primary (gradient) |
| Progress dots | Intro | All intro slides | 4 dots, active = accent-purple |
| Done | Scoring | Current turn participant, after scoring | Primary (gradient) |
| Skip Turn | Scoring | Facilitator, when another participant hasn't scored | Secondary |
| Back | Scoring, Summary | Facilitator (scoring: after Q1) | Secondary |
| Next Question | Scoring | Facilitator, all participants ready | Primary |
| Continue to Summary | Scoring (last Q) | Facilitator, all participants ready | Primary |
| I'm Ready | Scoring | Non-facilitator, after all turns complete | Primary |
| Continue to Wrap-Up | Summary | Facilitator | Primary |
| Finish Workshop | Completed | Facilitator | Primary |

---

## 4. Score Overlay

### Behaviour

When it's a participant's turn, a **floating overlay** appears centred on screen:

- **Backdrop**: Semi-transparent with blur effect
- **Modal**: Paper-textured sheet with score buttons
- **Balance scale** (-5 to +5): 11 buttons in a row, 0 highlighted as optimal
- **Maximal scale** (0 to 10): 11 buttons in a row
- **Auto-submit**: Selecting a score immediately submits it and closes the overlay
- **Click-to-edit**: After submitting, clicking your cell in the grid reopens the overlay
- **Entrance animation**: `score-overlay-enter` keyframe — overlay fades/slides in for polish

### Visibility Logic

```elixir
show_score_overlay: false  # always starts closed; opened explicitly by user
```

The overlay no longer auto-opens on turn start. Users click their cell in the scoring grid to open it. Click-to-edit reopens it via `handle_edit_my_score/1`.

---

## 5. Design System Components

Shared components in `lib/workgroup_pulse_web/components/core_components.ex`:

### `<.app_header>`

App header with gradient accent stripe.

```elixir
<.app_header session_name="Six Criteria Assessment" />
```

### `<.sheet>`

Core UI primitive — paper-textured surface. The building block for all phase content.

```elixir
<.sheet class="shadow-sheet p-6 max-w-2xl w-full">
  <h1>Content</h1>
</.sheet>
```

- `style` defaults to `-0.2deg` rotation, override for other angles
- `variant={:secondary}` for notes/side-sheets (uses `paper-texture-secondary`)
- Shadow is NOT baked in — pass via `class` (e.g., `shadow-sheet`)
- `relative z-[1]` inner wrapper is inside the component (content above paper texture pseudo-elements)

### `<.facilitator_timer>`

Facilitator-only countdown timer, positioned top-right with fixed positioning.

```elixir
<.facilitator_timer
  remaining_seconds={540}
  total_seconds={600}
  phase_name="Question 3"
  warning_threshold={60}
/>
```

### `<.score_indicator>`

Traffic light score display with colour coding.

---

## 6. Responsive Design

### Breakpoints

| Size | Target | Considerations |
|------|--------|----------------|
| Mobile (< 640px) | Phones | Single column, larger touch targets |
| Tablet (640-1024px) | iPads, small laptops | Comfortable grid view |
| Desktop (> 1024px) | Primary use case | Full grid with side panels |

### Mobile Considerations

- Grid may need horizontal scroll or condensed view
- Score overlay is full-width on mobile (mx-4 margin)
- Side panels may stack or become drawers

### Stack Navigation

The unified stack uses **server-driven navigation** only. Non-active slides are hidden (`display: none`). No scroll, swipe, or click-to-navigate.

| Mode | Behaviour |
|------|-----------|
| Server-driven `data-index` | Phase transitions and FAB buttons update `@carousel_index` |
| Inactive slides | Hidden via `display: none` — no visual stacking or transforms |

---

*Document Version: 1.0*
*Created: 2026-02-07*
