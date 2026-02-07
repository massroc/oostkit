# Sheet Carousel Layout System

The sheet carousel is the universal layout system for all Pulse workshop phases. Every phase renders its content inside one or more carousel slides, providing consistent centering, transitions, and navigation.

## Standard View (Carousel)

The active slide is centred and prominent. Adjacent slides (previous/next within the phase) peek from behind — scaled down to 82%, dimmed to 45% opacity, and non-interactive. Clicking a peeked slide navigates to it.

### CSS Classes

| Class | Purpose |
|-------|---------|
| `.sheet-carousel` | Container — flex row, scroll-snap, centring padding |
| `.carousel-slide` | Individual slide — snap-aligned, transition-enabled |
| `.carousel-slide.active` | Active slide — full size, z-index 2 |
| `.carousel-slide:not(.active)` | Inactive — scaled, dimmed, clickable to navigate |

### JS Hook: `SheetCarousel`

Mounted on carousel containers with 2+ slides. Reads `data-index` to set the initial active slide and syncs on `updated()`.

**Events pushed to server:**
- `carousel_navigate` with `{ index: <number>, carousel: <element-id> }`

**Scroll-end detection:** Debounced (100ms) scroll handler finds the closest slide to container centre and pushes `carousel_navigate` if it differs from current index.

## Phase Mapping

| Phase | Carousel ID | Slides | Hook? |
|-------|------------|--------|-------|
| Lobby | (none) | 1 — lobby sheet | No (single `.active` slide) |
| Intro | `intro-carousel` | 4 — welcome, how-it-works, scales, safe-space | Yes |
| Scoring | `scoring-carousel` | 2 — main grid, notes/actions | Yes |
| Summary | (none) | 1 — summary sheet | No |
| Completed | (none) | 1 — completed sheet | No |

### Scoring Carousel Details

- **Slide 0 (main):** `ScoringComponent.render` — the full 8-question grid
- **Slide 1 (notes):** `render_notes_slide/1` in show.ex — secondary-variant sheet with notes and actions forms
- `data-index` is driven by `@active_sheet` (`:main` = 0, `:notes` = 1)
- The `focus_sheet` event updates `@active_sheet`, which changes `data-index`, and the hook scrolls

## Server-Side Dispatch

The `carousel_navigate` handler in `EventHandlers` dispatches by carousel ID:

```elixir
def handle_carousel_navigate(socket, "intro-carousel", index)   # updates intro_step
def handle_carousel_navigate(socket, "scoring-carousel", index)  # updates active_sheet
def handle_carousel_navigate(socket, _carousel, _index)          # no-op fallback
```

## Reference View (Future)

A 2-panel side-by-side layout for focused work with a reference sheet. Not yet implemented.

### Standard Reference

Previous/context sheet on LEFT (smaller, slightly darker), current work sheet on RIGHT (prominent). Used when reviewing the previous phase while working on the current one.

### Side-Sheet Reference

Main sheet shifted LEFT (smaller, slightly greyed), side sheet on RIGHT (larger, prominent). Used when editing notes/actions with the scoring grid as context. After completing the action, user returns to standard view.

## Side Sheets (Current Behaviour)

Side sheets (e.g., notes/actions in the scoring carousel) are full carousel slides. When not active, they appear as a dimmed peek on the right edge. Navigate to them by clicking or swiping.

The reference view mechanic to expand them in-place alongside the main sheet is future work.
