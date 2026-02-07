# Workgroup Pulse - UX Implementation

**Audience:** Developers modifying CSS, JS hooks, or component markup.
**Changes when:** CSS systems, JS hooks, carousel behaviour, sheet dimensions, or UI components change.

For the **design rationale** behind these decisions (principles, visual design, accessibility), see [ux-design.md](ux-design.md).

---

## 1. Sheet Carousel System

The sheet carousel is the universal layout system for all Pulse workshop phases. Every phase renders its content inside one or more carousel slides, providing consistent centering, transitions, and navigation.

### CSS Classes

| Class | Purpose |
|-------|---------|
| `.sheet-carousel` | Container — flex row, scroll-snap, centring padding |
| `.sheet-carousel-locked` | Click-only variant — `overflow-x: hidden`, no scroll/swipe |
| `.carousel-slide` | Individual slide — snap-aligned, transition-enabled |
| `.carousel-slide.active` | Active slide — full size, z-index 2 |
| `.carousel-slide:not(.active)` | Inactive — scaled to 68%, 30% opacity, -7rem margins, clickable |

### JS Hook: `SheetCarousel`

Mounted on carousel containers with 2+ slides. Reads `data-index` to set the initial active slide and syncs on `updated()`.

**Click-only mode:** When `data-click-only` attribute is present, the scroll listener is skipped and `scrollTo` is used instead of `scrollIntoView` (required for `overflow-x: hidden` containers). Navigation only via clicking inactive slides.

**Events pushed to server:**
- `carousel_navigate` with `{ index: <number>, carousel: <element-id> }`

**Scroll-end detection (non-click-only only):** Debounced (100ms) scroll handler finds the closest slide to container centre and pushes `carousel_navigate` if it differs from current index.

### Phase Mapping

| Phase | Carousel ID | Slides | Hook? | Click-only? |
|-------|------------|--------|-------|-------------|
| Lobby | (none) | 1 — lobby sheet | No (single `.active` slide) | N/A |
| Intro | `intro-carousel` | 4 — welcome, how-it-works, scales, safe-space | Yes | No |
| Scoring | `scoring-carousel` | 6 — 4 intro context + main grid + notes/actions | Yes | Yes |
| Summary | (none) | 1 — summary sheet | No | N/A |
| Completed | (none) | 1 — completed sheet | No | N/A |

### Scoring Carousel Slide Index Map

The scoring carousel contains 6 slides: the 4 intro sheets (read-only context, smaller at 480px) followed by the scoring grid and notes sheet.

| Index | Slide | Width |
|-------|-------|-------|
| 0 | Welcome (intro) | 480px |
| 1 | How it works (intro) | 480px |
| 2 | Balance scale (intro) | 480px |
| 3 | Safe space (intro) | 480px |
| 4 | Scoring grid (default active) | 720px |
| 5 | Notes/actions | 480px |

- `data-index` is driven by `@active_slide_index` (default `4` = scoring grid)
- The `focus_sheet` event updates `@active_slide_index` (`:main` → 4, `:notes` → 5)
- Click-only: no scroll/swipe navigation — users click inactive slides to navigate
- Intro slides reuse `IntroComponent` public functions (`slide_welcome/1`, etc.) with smaller dimensions

### IntroComponent Slide Functions

`IntroComponent` exposes 4 public function components for reuse in the scoring carousel:

- `IntroComponent.slide_welcome/1`
- `IntroComponent.slide_how_it_works/1`
- `IntroComponent.slide_balance_scale/1`
- `IntroComponent.slide_safe_space/1`

Each accepts an optional `class` attr (defaults to `"shadow-sheet p-6 w-[720px] h-full"` for intro phase). The scoring carousel passes smaller dimensions (`"shadow-sheet p-4 w-[480px] h-full text-sm"`).

### Server-Side Dispatch

The `carousel_navigate` handler in `EventHandlers` dispatches by carousel ID:

```elixir
def handle_carousel_navigate(socket, "intro-carousel", index)   # updates intro_step
def handle_carousel_navigate(socket, "scoring-carousel", index)  # updates active_slide_index
def handle_carousel_navigate(socket, _carousel, _index)          # no-op fallback
```

### Side Sheets

Side sheets (e.g., notes/actions in the scoring carousel) are full carousel slides. When not active, they appear as a dimmed peek on the right edge. Navigate to them by clicking (scoring carousel is click-only, no swipe).

The intro context slides appear as deep stacked peeks to the left of the active scoring grid, providing visual continuity between phases.

---

## 2. Sheet Dimensions & Overflow

### Standard Dimensions

- **Width**: 720px (all primary sheets), 480px (notes side-sheet and intro context slides in scoring)
- **Height**: `calc(100vh - 52px - 3rem)` — fills available viewport minus header (52px) and carousel padding (1.5rem x 2)
- **Min-height**: 879px — flipchart ratio floor based on Post-it Easel Pad (635mm x 775mm = 0.819 W:H; 720/0.819 = 879)

### CSS Overflow Rules

Content scrolls within the sheet when it exceeds the available height; no scrollbar when it fits:

```css
.carousel-slide .paper-texture > div {
  height: 100%;
  overflow-y: auto;
}
```

This is CSS-driven — no JS intervention needed. The sheet is the scroll container, not the page.

---

## 3. Floating Action Buttons

### Positioning

Viewport-fixed bar (`fixed bottom-10 z-50`) that is 720px wide, horizontally centred (`left-1/2 -translate-x-1/2`), with padding matching the sheet.

The container uses `pointer-events-none` with `pointer-events-auto` on the inner button wrapper, so clicks pass through to the sheet except where buttons are.

### Rendering

Floating action buttons are rendered by `render_floating_buttons/1` in `show.ex` — not inside phase components. This ensures they're always visible without scrolling, positioned at the bottom-right of the sheet's visual area. Each phase renders its own set of buttons; lobby has no floating buttons (Start Workshop is inline).

### Per-Phase Button Inventory

| Button | Phase | Shown When | Style |
|--------|-------|-----------|-------|
| Skip intro | Intro (slide 1 only) | Always on first intro slide | Text link |
| Next | Intro | All slides | Primary (gradient) |
| Done | Scoring | Current turn participant, after scoring | Primary (gradient) |
| Skip Turn | Scoring | Facilitator, when another participant hasn't scored | Secondary |
| Back | Scoring, Summary, Completed | Facilitator (scoring: after Q1) | Secondary |
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
show_score_overlay: is_my_turn and not my_turn_locked and my_score == nil
```

After auto-submit, the overlay closes. Click-to-edit reopens it via `handle_edit_my_score/1`.

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

### Carousel Navigation by Mode

| Mode | Intro | Scoring |
|------|-------|---------|
| Scroll/swipe | Yes | No (click-only) |
| Click inactive slide | Yes | Yes |
| Server-driven `data-index` | Yes | Yes |

Non-active slides are scaled to 68%, dimmed to 30% opacity, with -7rem overlap margins and `pointer-events: none` on children.

---

*Document Version: 1.0*
*Created: 2026-02-07*
