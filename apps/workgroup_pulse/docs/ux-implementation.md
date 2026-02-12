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
| 0 | Welcome | 960px | always |
| 1 | How It Works | 960px | always |
| 2 | Balance Scale | 960px | always |
| 3 | Maximal Scale | 960px | always |
| 4 | Scoring Grid | 960px | state in scoring/summary/completed |
| 5 | Summary | 960px | state in summary/completed |
| 6 | Wrap-up | 960px | state == completed |

- `data-index` is driven by `@carousel_index` (set by event handlers and state transitions)
- The `focus_sheet` event updates `@carousel_index` (`:main` → 4) or sets `notes_revealed: true` (`:notes`)
- Phase transitions set `@carousel_index` automatically (e.g., scoring → 4, summary → 5, completed → 6)
- Click-only: no scroll/swipe navigation — users click inactive slides to navigate

### IntroComponent Slide Functions

`IntroComponent` exposes 4 public function components rendered directly in the unified carousel:

- `IntroComponent.slide_welcome/1`
- `IntroComponent.slide_how_it_works/1`
- `IntroComponent.slide_balance_scale/1`
- `IntroComponent.slide_maximal_scale/1`

Each accepts an optional `class` attr (defaults to `"shadow-sheet p-6 w-[960px] h-full"`). All slides render at full 960px landscape in the unified carousel.

### Server-Side Dispatch

The `carousel_navigate` handler in `EventHandlers` uses a single clause:

```elixir
def handle_carousel_navigate(socket, "workshop-carousel", index)  # updates carousel_index
def handle_carousel_navigate(socket, _carousel, _index)           # no-op fallback
```

### Notes/Actions Side Panel

The notes/actions panel is **not** a carousel slide. It is a fixed-position panel on the right edge of the viewport (z-20), outside the carousel DOM.

- **Peek tab** (70px wide, read-only preview showing notes/actions headings and content) is visible on slides 4-6 (scoring, summary, wrap-up)
- **Reveal:** Clicking the peek tab fires `reveal_notes`, setting `notes_revealed: true` and showing the full 480px editable panel
- **Dismiss:** Clicking outside the panel (transparent backdrop at z-10) fires `hide_notes`, setting `notes_revealed: false`
- `handle_focus_sheet(:notes)` sets `notes_revealed: true` instead of changing the carousel index

### Intro Slides in Later Phases

During scoring and later phases, the intro slides are hidden (not visible as stacked peeks). Only the active slide is shown.

---

## 2. Sheet Dimensions & Overflow

### Standard Dimensions

- **Width**: 960px (all primary sheets, landscape orientation), 480px (notes side panel)
- **Height**: `100%` — fills available space within the flex layout container (parent handles header offset)
- **Min-height**: 786px — landscape ratio floor (960/1.221 = 786)

### CSS Overflow Rules

Content scrolls within the sheet when it exceeds the available height; no scrollbar when it fits:

```css
.sheet-stack-slide .paper-texture > div,
.sheet-stack-slide .paper-texture-secondary > div {
  height: 100%;
  overflow-y: auto;
  overflow-x: hidden;
  padding-bottom: 0;
  scrollbar-width: thin;                          /* Firefox */
  scrollbar-color: rgba(26, 58, 107, 0.15) transparent;
}
```

Cross-browser thin scrollbar styling is applied via `::-webkit-scrollbar` (Chromium/Edge/Safari, 6px width) and `scrollbar-width: thin` (Firefox). `overflow-x: hidden` prevents horizontal scrollbars caused by CSS rotation on sheet containers.

This is CSS-driven — no JS intervention needed. The sheet is the scroll container, not the page. No extra bottom padding is needed because the floating action buttons are positioned close to the sheet edge and the sheet's own padding provides sufficient clearance.

---

## 3. Floating Action Buttons

### Positioning

Viewport-fixed bar (`fixed bottom-6 z-50`) that is 960px wide, horizontally centred (`left-1/2 -translate-x-1/2`), with padding matching the sheet.

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
| Progress dots | Intro | All intro slides | 4 dots, active = accent-gold |
| Done | Scoring | Current turn participant, after scoring | Primary (gradient) |
| ← Prev Question | Scoring | Facilitator, after Q1 | Secondary |
| Next Question | Scoring | Facilitator, all participants ready | Primary |
| Continue to Summary | Scoring (last Q) | Facilitator, all participants ready | Primary |
| I'm Ready | Scoring | Non-facilitator, after all turns complete | Primary |
| ← Back | Slides 4-6 (review) | All participants, carousel nav to prev slide | Secondary |
| Summary → | Slide 4 (review) | All participants, state past scoring | Primary |
| Continue to Wrap-Up | Summary | Facilitator (active summary state) | Primary |
| Wrap-Up → | Slide 5 (review) | All participants, state is completed | Primary |

**Skip Turn** is rendered inline in the scoring grid cell (not as a floating button). **Finish Workshop** is rendered inside the wrap-up sheet (not floating).

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

Components are split between `OostkitShared.Components` (`apps/oostkit_shared/`) for cross-app shared components and `core_components.ex` for app-specific components:

### Shared Components (from `OostkitShared.Components`)

| Component | Purpose |
|-----------|---------|
| `<.header_bar>` | OOSTKit brand header: dark purple (`bg-ok-purple-900`), three-zone layout (brand link, centered title `text-2xl font-semibold`, actions slot), brand stripe |
| `<.header>` | Page-level section header (`text-2xl font-bold`) with `:subtitle` and `:actions` slots |
| `<.icon>` | Heroicon renderer (`<span class={[@name, @class]} />`) |
| `<.flash>` | Flash notice with `:info` / `:error` variants, dismiss-on-click |
| `<.flash_group>` | Standard flash group with client/server reconnection flashes |
| `show/2`, `hide/2` | JS command helpers for animated show/hide transitions |

### `<.app_header>` (app-specific)

The app-specific `<.app_header>` in `core_components.ex` wraps `<.header_bar>` and adds session-specific content (session name in the actions slot). Used in session views. The OOSTKit brand link URL is read from `Application.get_env(:workgroup_pulse, :portal_url, "https://oostkit.com")`, matching the pattern used by the `:app` layout.

```elixir
<.app_header session_name="Six Criteria Assessment" />
```

### Layouts

Two Phoenix layouts control header presence:

| Layout | Used By | Header |
|--------|---------|--------|
| `:app` | Create (home page) and Join pages | Shared `<.header_bar>` in layout: OOSTKit link (left, via `:portal_url`), "Workgroup Pulse" absolutely centered, Sign Up + Log In buttons (right, linking to Portal) + brand stripe |
| `:session` | `SessionLive.Show` | Bare layout (no header) — the session LiveView renders `.app_header` inline |

Both the `:app` layout and the `<.app_header>` component use `Application.get_env(:workgroup_pulse, :portal_url, "https://oostkit.com")` for the OOSTKit brand link URL. The `:app` layout also uses it for Sign Up/Log In button URLs. This is configured in `config/dev.exs` (defaults to `http://localhost:4002`) and `config/runtime.exs` (from `PORTAL_URL` env var).

The right zone always shows Sign Up (`rounded-md bg-white/10` frosted button linking to Portal `/users/register`) and Log In (text link to Portal `/users/log-in`), matching the Portal header styling. Pulse has no user authentication context, so the right zone does not adapt based on auth state.

The `:session` layout prevents duplicate headers when the session LiveView renders its own `app_header` component (which includes the session name).

### Page Title (H1) Sizing

All page-level H1 headings use `text-2xl font-bold` to match the Portal standard. This was standardized across all pre-scoring phases:

| Component / Page | H1 Text | Classes |
|-----------------|---------|---------|
| `new.ex` (Create Workshop) | "New Workshop" | `text-2xl font-bold text-ink-blue` |
| `join.ex` (Join Workshop) | "Join Workshop" | `text-2xl font-bold text-ink-blue` |
| `LobbyComponent` | "Waiting Room" | `font-workshop text-2xl font-bold text-ink-blue` |
| `IntroComponent` (all 4 slides) | Welcome / How It Works / Balance Scale / Maximal Scale | `font-workshop text-2xl font-bold text-ink-blue` |

Scoring, summary, and wrap-up components were intentionally left at their existing sizes — their content density and layout context require different heading treatment.

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

### Accent Color Classes

Three Tailwind token classes provide accent colours across all phase components. See [ux-design.md](ux-design.md) for the design rationale.

| Token | Hex | Tailwind Classes Used |
|-------|-----|----------------------|
| `accent-magenta` | `#BC45F4` | `text-accent-magenta`, `bg-accent-magenta`, `bg-accent-magenta/5`, `border-accent-magenta/30`, `focus:border-accent-magenta`, `focus:ring-accent-magenta` |
| `accent-gold` | `#F4B945` | `text-accent-gold`, `bg-accent-gold`, `bg-accent-gold/5`, `bg-accent-gold/10`, `border-accent-gold`, `border-accent-gold/30` |
| `accent-red` | `#F44545` | `text-accent-red`, `bg-accent-red/5`, `border-accent-red/30` |

**Per-component usage:**

| Component | Magenta | Gold | Accent-red |
|-----------|---------|------|------------|
| `NotesPanelComponent` | Focus ring on notes and actions inputs | — | — |
| `CompletedComponent` | Actions section (header, input focus, arrow bullets) | Strengths section (header, checkmarks, scores, background/border) | Concerns section (header, icon, background) |
| `ScoreOverlayComponent` | Discussion tips heading and bullet points | "Your turn to score" / "Discuss your score" prompt | — |
| `LobbyComponent` | "You" badge (`bg-accent-magenta text-white`) | — | — |
| `IntroComponent` | — | Welcome blockquote border | Scale endpoint labels (-5/+5, 0) |
| `FloatingButtonsComponent` | — | Intro progress dots (active dot), ready checkmarks (individual and all-ready) | — |
| `new.ex` (Home / Create Workshop) | — | Timer active icon, duration button selected state (`bg-accent-gold border-accent-gold text-white`) | — |
| `ExportPrintComponent` | — | Strengths section (inline gold border/background/text for PDF) | Concerns section (inline red border/background/text for PDF) |

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

## 7. Export & PDF Generation

### JS Hook: `ExportHook`

Replaces the previous `FileDownload` hook. Attached to the export button container (`#export-container`). Handles two server-pushed events:

- **`download`** — CSV export. Creates a Blob from the data and triggers a download via a temporary `<a>` link.
- **`generate_pdf`** — PDF export via html2pdf.js. Clones `#export-print-content` into an isolated container on `document.body`, captures it with html2canvas, and generates an A4 landscape PDF via jsPDF. The clone approach avoids inherited transforms from the sheet/carousel stack.

### ExportPrintComponent

Hidden off-screen (`overflow:hidden; height:0; width:0`) until the JS hook reveals a clone for capture. Renders static inline-styled HTML (no Tailwind classes) sized at 960px wide with `box-sizing: border-box`. Content switches based on `export_report_type`:

- **Full Report** — participants table, individual scores grid with traffic-light cell backgrounds, team score cards, strengths/concerns, notes, and actions.
- **Team Report** — "TEAM REPORT / No individual scores, names or notes" header, team score cards, strengths/concerns, and actions. No participants, individual scores, or notes.

### Vendor Dependency

`assets/vendor/html2pdf.bundle.min.js` — UMD bundle including html2canvas + jsPDF. Imported in `app.js`.

---

*Document Version: 1.13 — Shared UI components (icon, flash, flash_group, show, hide) consolidated into `OostkitShared.Components`; CoreComponents now contains only app-specific components*
*Created: 2026-02-07*
*Updated: 2026-02-13*
