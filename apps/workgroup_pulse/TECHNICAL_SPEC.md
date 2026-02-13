# Workgroup Pulse - Technical Specification

**Audience:** Developers working on backend LiveView components, handlers, state management, and integrations.
**Changes when:** Component hierarchy, handler functions, socket assigns, timer logic, or analytics change.

For **architecture and design decisions** (contexts, schemas, state machine, PubSub), see [SOLUTION_DESIGN.md](SOLUTION_DESIGN.md).
For **frontend/UX implementation** (CSS, JS hooks, carousel, sheet dimensions), see [docs/ux-implementation.md](docs/ux-implementation.md).

---

## Table of Contents

1. [LiveView Component Hierarchy](#1-liveview-component-hierarchy)
2. [Phase Components](#2-phase-components)
3. [Extracted Handler Modules](#3-extracted-handler-modules)
4. [LiveView Socket State](#4-liveview-socket-state)
5. [Score Input & Display Logic](#5-score-input--display-logic)
6. [Timer Implementation](#6-timer-implementation)
7. [Analytics Integration (PostHog)](#7-analytics-integration-posthog)
8. [Performance Optimizations](#8-performance-optimizations)

---

## 1. LiveView Component Hierarchy

```
SessionLive.Show (root LiveView)
├── Handlers/
│   ├── NavigationHandlers    # Workshop flow: start, intro, carousel, phase transitions, go back
│   ├── ScoringHandlers       # Score submission, turn completion, skipping, readiness
│   ├── ContentHandlers       # Notes, actions, export, UI toggles
│   └── MessageHandlers       # All handle_info callbacks (PubSub)
│
├── Helpers/
│   ├── DataLoaders           # Data loading & state hydration
│   ├── GridHelpers           # Shared scoring grid helpers (used by Scoring/Summary/Export components)
│   ├── StateHelpers          # State transition helpers
│   ├── OperationHelpers      # Standardised error handling
│   └── ScoreHelpers          # Score color/formatting utilities
│
├── TimerHandler              # Facilitator timer logic
│
├── Components/ (pure functional components)
│   ├── LobbyComponent              # Waiting room, participant list, start button
│   ├── IntroComponent              # 4 intro screens with navigation
│   ├── ScoringComponent            # Scoring grid table (8-question grid)
│   ├── FloatingButtonsComponent    # Phase-specific floating action buttons
│   ├── NotesPanelComponent         # Notes/actions side panel (peek tab + expanded)
│   ├── ScoreOverlayComponent       # Score input overlay + criterion info popup
│   ├── SummaryComponent            # Score summary with individual scores & notes
│   ├── CompletedComponent          # Wrap-up: results, action count, export
│   ├── ExportModalComponent        # Export report type (full/team) + format (CSV/PDF) selection
│   └── ExportPrintComponent        # Hidden print-optimized HTML for PDF capture via html2pdf.js
│
├── Shared (from OostkitShared.Components — `apps/oostkit_shared/`)
│   ├── .header_bar           # OOSTKit brand header (dark purple, 3-zone: brand link + title(text-2xl) + actions slot)
│   ├── .header               # Page-level section header (text-2xl font-bold, subtitle + actions slots)
│   ├── .icon                 # Heroicon renderer
│   ├── .flash / .flash_group # Flash notices with client/server reconnection
│   ├── show/2, hide/2        # JS command helpers for animated transitions
│
├── App-Specific (in CoreComponents)
│   ├── .sheet               # Core UI primitive (paper-textured sheet)
│   ├── .facilitator_timer    # Timer display (facilitator-only)
│   ├── .score_indicator      # Traffic light score display
│   └── translate_error/1, translate_errors/1  # Error translation (per-app, referenced by Petal config)
│
├── Layouts
│   ├── app.html.heex         # Standard layout using shared <.header_bar> (OOSTKit link via :portal_url, absolutely centered "Workgroup Pulse" title, Sign Up + Log In buttons linking to Portal) + brand stripe
│   └── session.html.heex     # Bare layout for session pages (no header — session LiveView renders shared .header_bar inline)
│
└── Other LiveViews
    ├── SessionLive.New        # Home page / create new session (mounted at `/`)
    └── SessionLive.Join       # Join existing session
```

### Component Design Principles

1. **Stateless where possible** - Components receive assigns, parent manages state
2. **Slots for flexibility** - Use slots for customizable content areas
3. **Consistent styling API** - Common props like `class`, `variant`, `size`
4. **Render isolation** - Extract LiveComponents to limit re-render scope for frequently updated sections

---

## 2. Phase Components

All phases use the **Sheet Stack** layout. See [docs/ux-implementation.md](docs/ux-implementation.md) for the full stack specification (CSS classes, JS hook, slide index map).

**Layout orchestration** lives in `show.ex` via `render_phase_carousel/1`:
- **Lobby** — standalone single-slide wrapper, no JS hook
- **All other phases** — unified `workshop-carousel` with `SheetStack` hook, `data-index` from `@carousel_index`, click-only navigation. Slides 0-3 (intro) are always rendered; slides 4-6 (scoring, summary, wrap-up) are conditionally rendered based on session state.

The `SheetStack` JS hook sends `carousel_navigate` events with `{ index, carousel }`, updating `@carousel_index` on the server. Phase transitions (via PubSub) automatically set the carousel index to the appropriate slide. When transitioning from lobby → scoring, carousel starts at 0 (intro slides); participants navigate to the scoring sheet (index 4) independently. Summary → 5, completed → 6.

### ScoringComponent

**File:** `lib/workgroup_pulse_web/live/session_live/components/scoring_component.ex`

**Purpose:** Renders the scoring grid table. Pure functional component — all events bubble to the parent LiveView. Score overlays, floating buttons, and the notes panel are separate components. Uses `GridHelpers.scoring_grid/1` for the shared grid table structure, providing a `:cell` slot for scoring-specific cell rendering.

**Attrs (10):** `session`, `participant`, `participants`, `current_question`, `has_submitted`, `is_my_turn`, `current_turn_participant_id`, `my_turn_locked`, `all_questions`, `all_questions_scores`

**Key Render Functions:**
- Uses `GridHelpers.scoring_grid/1` with a `:cell` slot for per-cell rendering
- Cell rendering handles display states: future `—`, past `?` (skipped), current `...` (active turn), scored value with traffic-light color

### ScoreOverlayComponent

**File:** `lib/workgroup_pulse_web/live/session_live/components/score_overlay_component.ex`

**Purpose:** Renders the score input overlay and criterion info popup. These are rendered outside the carousel container in the DOM because CSS `transform` on carousel slides breaks `position: fixed`.

**Attrs (11):** `session`, `is_my_turn`, `my_turn_locked`, `show_score_overlay`, `show_discuss_prompt`, `show_team_discuss_prompt`, `show_criterion_popup`, `current_question`, `selected_value`, `has_submitted`, `all_questions`

**Key Render Functions:**
- `render_score_overlay/1` — Floating score input modal with backdrop
- `render_balance_scale/1` / `render_maximal_scale/1` — Score button grids for each scale type
- `render_discuss_prompt/1` — "Discuss your score" popup after individual score submission
- `render_team_discuss_prompt/1` — "Discuss the scores as a team" popup when all turns complete (only during active scoring)
- `render_criterion_popup/1` — Criterion info popup with discussion tips

### FloatingButtonsComponent

**File:** `lib/workgroup_pulse_web/live/session_live/components/floating_buttons_component.ex`

**Purpose:** Renders phase-specific floating action buttons fixed to the viewport. Scoring-specific attrs use defaults so the component works across all phases.

**Attrs (14):** `session`, `participant`, `carousel_index`, `show_mid_transition`, `scores_revealed`, `all_ready`, `ready_count`, `eligible_participant_count`, `is_my_turn`, `my_turn_locked`, `has_submitted`, `current_turn_has_score`, `total_questions`, `participant_was_skipped`

### NotesPanelComponent

**File:** `lib/workgroup_pulse_web/live/session_live/components/notes_panel_component.ex`

**Purpose:** Renders the notes/actions side panel fixed to the right edge of the viewport. Includes a 70px read-only peek (showing notes/actions headings and content preview) and a 480px expanded editable panel.

**Attrs (7):** `notes_revealed`, `carousel_index`, `question_notes`, `note_input`, `all_actions`, `action_count`, `action_input`

**Notes/Actions Panel** — Fixed-position panel on the right edge of the viewport (z-20). A 70px read-only peek is visible on slides 4-6 (scoring, summary, wrap-up). Clicking the peek sets `notes_revealed: true`, revealing a 480px editable panel. Clicking outside (transparent backdrop at z-10) fires `hide_notes` to dismiss. Not a carousel slide.

**Actions in Scoring Phase:**
Actions are managed during the scoring phase via the notes/actions side panel (below notes). The completed/wrap-up page displays all captured action items in a dedicated section (beneath strengths/concerns) and includes the action count for export purposes.

### Other Phase Components

All follow the same pure functional pattern:
- **SummaryComponent** — Read-only scoring grid table via `GridHelpers.scoring_grid/1` with traffic-light coloured cells (same grid layout as scoring phase, grouped by scale type)
- **CompletedComponent** — Wrap-up page with "Cumulative Team Score" overview, strengths/concerns, inline action items input, export, and "Finish Workshop" button (facilitator only)
- **LobbyComponent** — Waiting room with participant list and start button
- **IntroComponent** — 4-screen introduction with navigation

---

## 3. Extracted Handler Modules

The following handler modules have been extracted from SessionLive.Show to improve maintainability and separation of concerns.

### NavigationHandlers

**File:** `lib/workgroup_pulse_web/live/session_live/handlers/navigation_handlers.ex`

**Purpose:** Workshop flow and navigation events. Each function receives the socket and returns `{:noreply, socket}`.

**Key Functions:**
- `handle_start_workshop/1` — Starts the session (facilitator only)
- `handle_intro_next/1` / `handle_intro_prev/1` — Navigate intro slides locally
- `handle_skip_intro/1` — Navigates to scoring sheet (local); starts timer for facilitator on first arrival
- `handle_carousel_navigate/3` — Updates carousel index for sheet stack navigation
- `handle_next_question/1` — Advances to next question (facilitator only)
- `handle_go_back/1` — Navigate back (facilitator only, context-aware by session state)
- `handle_continue_to_wrapup/1` — Advances from summary to completed state
- `handle_finish_workshop/1` — Redirects facilitator to homepage

### ScoringHandlers

**File:** `lib/workgroup_pulse_web/live/session_live/handlers/scoring_handlers.ex`

**Purpose:** Scoring and turn-based events. Handles score submission, turn lifecycle, and readiness.

**Key Functions:**
- `handle_select_score/2` — Parses score value and auto-submits immediately (no separate submit step)
- `handle_edit_my_score/1` — Reopens the score overlay for click-to-edit
- `handle_close_score_overlay/1` — Dismisses the score overlay
- `handle_complete_turn/1` — Locks turn and advances to next participant
- `handle_skip_turn/1` — Facilitator skips current participant
- `handle_mark_ready/1` — Marks participant as ready to continue

### ContentHandlers

**File:** `lib/workgroup_pulse_web/live/session_live/handlers/content_handlers.ex`

**Purpose:** Content events covering notes, actions, export, and UI toggles.

**Key Functions:**
- `handle_focus_sheet/2` — Brings specified sheet panel to front (`:main` → carousel index 4; `:notes` → sets `notes_revealed: true`)
- `handle_reveal_notes/1` / `handle_hide_notes/1` — Toggle the fixed-position notes panel
- `handle_dismiss_prompt/2` — Dismisses any prompt type (discuss, team_discuss)
- `handle_add_note/2` / `handle_delete_note/2` — Note CRUD (content read from form params)
- `handle_add_action/2` / `handle_delete_action/2` — Action CRUD (description read from form params)
- `handle_export/2` — Generates CSV or triggers PDF export via JS hook
- `handle_show_criterion_info/2` / `handle_close_criterion_info/1` — Criterion popup toggle

### MessageHandlers

**File:** `lib/workgroup_pulse_web/live/session_live/handlers/message_handlers.ex`

**Purpose:** All `handle_info` callbacks for PubSub events. Handles real-time updates from other participants.

**Key Events Handled:**
- `:participant_joined`, `:participant_left`, `:participant_updated`, `:participant_ready`
- `:session_started`, `:session_updated`
- `:score_submitted` — Reloads score data for the affected question
- `:turn_advanced`, `:row_locked`
- `:note_updated`, `:action_updated`
- `:participants_ready_reset`

### DataLoaders

**File:** `lib/workgroup_pulse_web/live/session_live/helpers/data_loaders.ex`

**Purpose:** Centralised data loading functions that hydrate the socket with data for each phase. Uses smart caching to avoid redundant DB queries.

**Key Functions:**
- `load_scoring_data/3` — Loads all scoring state for scoring/summary/completed states. Uses a single clause with guard for active states, falling back to `reset_scoring_assigns/1` for others. Delegates common assigns to `assign_common_scoring/5`.
- `load_scores/3` — Loads scores for a specific question, builds participant score grid, calculates readiness
- `load_all_questions_scores/3` — Loads scores for all 8 questions (for the full grid display)
- `load_notes/2` — Loads all notes for a session (session-level, not per-question)
- `load_summary_data/2` — Loads summary state: scores summary, individual scores, all notes, strengths/concerns
- `load_actions_data/2` — Loads actions for wrap-up phase
- `get_or_load_template/2` — Template caching (reuses from socket assigns)
- `reset_scoring_assigns/1` — Resets all scoring-related assigns to defaults

**Score Overlay Logic:**
```elixir
# Overlay shows only when it's your turn AND you haven't submitted yet
show_score_overlay: turn_state.is_my_turn and my_score == nil
```

**Readiness Calculation:**
- Skipped participants (no score when all turns done) auto-counted as ready
- Row-locked questions (revisiting completed): all participants auto-ready
- Otherwise: explicit "I'm Ready" click required from non-facilitator, non-observer participants

### GridHelpers

**File:** `lib/workgroup_pulse_web/live/session_live/helpers/grid_helpers.ex`

**Purpose:** Shared helpers and a `scoring_grid/1` function component for scoring grid rendering, used by `ScoringComponent`, `SummaryComponent`, and `ExportPrintComponent`. Eliminates duplicated grid table structure and logic across these three components.

**Function Component:**
- `scoring_grid/1` — Renders the full scoring grid table (scale section labels, criterion headers with paired-group rows, participant column headers, and score cells). Each consumer provides cell rendering via a required `:cell` slot that receives `%{question: question, participant: participant, score_data: data}`. Attrs: `:all_questions`, `:participants`, `:scores` (map of `%{question_index => [score_maps]}`), and optional `:active_participant_id`, `:active_question_index`, `:criterion_click_event`.

**Helper Functions:**
- `prepare_grid_assigns/1` — Prepares common grid assigns: filters active participants, splits questions by scale type (balance/maximal), calculates empty column slots and total columns. Fixed at 10 participant column slots for consistent grid width.
- `sub_label/1` — Returns "a" or "b" suffix for paired criteria questions, nil otherwise
- `first_of_pair?/1` — Returns true if a question starts a paired criterion group (e.g., "2a", "5a")
- `format_score_value/2` — Formats score for display; balance values > 0 get a "+" prefix
- `format_criterion_title/1` — Wraps long criterion titles (e.g., "Mutual Support and Respect" gets a line break)

### TimerHandler

**File:** `lib/workgroup_pulse_web/live/session_live/timer_handler.ex`

**Purpose:** Manages facilitator countdown timer during workshop phases.

**Functions:**
- `init_timer_assigns/1` - Initialize timer-related socket assigns
- `maybe_start_timer/1` - Conditionally start timer for facilitators
- `start_phase_timer/2` - Start timer for current phase
- `cancel_timer/1` - Cancel active timer
- `handle_timer_tick/1` - Process timer tick (returns `{:noreply, socket}`)
- `maybe_restart_timer_on_transition/3` - Restart on phase change
- `stop_timer/1` - Stop and disable timer

### OperationHelpers

**File:** `lib/workgroup_pulse_web/live/session_live/helpers/operation_helpers.ex`

**Purpose:** Standardized error handling for context operations, reducing duplication across event handlers.

**Functions:**
- `handle_operation/4` - Handle `{:ok, result}` / `{:error, reason}` with logging

**Usage:**
```elixir
# Before (repeated pattern)
case Sessions.start_session(session) do
  {:ok, updated_session} ->
    {:noreply, assign(socket, session: updated_session)}
  {:error, reason} ->
    Logger.error("Failed to start workshop: #{inspect(reason)}")
    {:noreply, put_flash(socket, :error, "Failed to start workshop")}
end

# After
handle_operation(
  socket,
  Sessions.start_session(session),
  "Failed to start workshop",
  &assign(&1, session: &2)
)
```

---

## 4. LiveView Socket State

The root LiveView (`SessionLive.Show`) delegates to handler modules and DataLoaders for state management:

```elixir
defmodule WorkgroupPulseWeb.SessionLive.Show do
  use WorkgroupPulseWeb, :live_view

  # Mount: load session, participant, subscribe, hydrate all phase data
  def mount(%{"code" => code}, session, socket) do
    # ... session/participant lookup, redirect if not found ...

    {:ok,
     socket
     # Core state
     |> assign(session: workshop_session)
     |> assign(participant: participant)
     |> assign(participants: participants)        # Ordered by join order

     # UI state
     |> assign(carousel_index: initial_carousel_index(session.state))  # Unified carousel index (7 slides max)
     |> assign(notes_revealed: false)          # Notes side panel visibility
     |> assign(show_mid_transition: false)
     |> assign(show_facilitator_tips: false)
     |> assign(note_input: "")
     |> assign(show_export_modal: false)
     |> assign(export_report_type: "full")

     # Timer state (via TimerHandler.init_timer_assigns/1)
     # timer_enabled, timer_remaining, segment_duration,
     # timer_phase_name, timer_warning_threshold, timer_ref

     # Scoring state (via DataLoaders.load_scoring_data/3)
     # template, total_questions, current_question,
     # selected_value, my_score, has_submitted,
     # is_my_turn, current_turn_participant_id, current_turn_has_score,
     # my_turn_locked, participant_was_skipped,
     # all_scores, scores_revealed, score_count, active_participant_count,
     # question_notes, show_score_overlay,
     # all_questions, all_questions_scores,    # Full grid data
     # ready_count, eligible_participant_count, all_ready

     # Summary state (via DataLoaders.load_summary_data/2)
     # summary_template, scores_summary, all_notes, individual_scores,
     # all_notes, strengths, concerns, neutral

     # Actions state (via DataLoaders.load_actions_data/2)
     # all_actions, action_count
    }
  end

  # Events delegate to focused handler modules
  def handle_event("select_score", params, socket),
    do: ScoringHandlers.handle_select_score(socket, params)
  def handle_event("go_back", _params, socket),
    do: NavigationHandlers.handle_go_back(socket)
  def handle_event("add_note", %{"note" => content}, socket),
    do: ContentHandlers.handle_add_note(socket, content)

  # PubSub messages delegate to MessageHandlers
  def handle_info({:score_submitted, pid, qi}, socket),
    do: {:noreply, MessageHandlers.handle_score_submitted(socket, pid, qi)}

  # Timer ticks handled by TimerHandler
  def handle_info(:timer_tick, socket),
    do: TimerHandler.handle_timer_tick(socket)

  # Render dispatches to phase components based on session.state
  # Plus: facilitator timer, floating action buttons
end
```

**Key Design Decisions:**
- `show.ex` is a thin dispatcher — all logic lives in handler/helper modules
- Event handlers are split by domain: `NavigationHandlers` (flow/navigation), `ScoringHandlers` (scores/turns/readiness), `ContentHandlers` (notes/actions/export/UI toggles). Events in `show.ex` delegate to the appropriate module via one-liner clauses grouped by section.
- DataLoaders hydrate socket assigns in bulk, avoiding piecemeal loading
- Template caching (`get_or_load_template/2`) avoids repeated DB queries
- Shared grid rendering logic is centralised in `GridHelpers`, which provides both helper functions and a `scoring_grid/1` function component with a `:cell` slot. This eliminates duplicate grid table markup across `ScoringComponent`, `SummaryComponent`, and `ExportPrintComponent` — each provides only its cell rendering logic
- Floating action buttons, notes panel, and score overlays are separate extracted components called from `show.ex`'s `render/1`

---

## 5. Score Input & Display Logic

### Score Input Design

Score input uses **button grids inside a floating overlay**, not sliders. Each score value is a separate button that auto-submits on click via `phx-click="select_score"`.

**Balance Scale (-5 to +5):** 11 buttons in a row. The `0` button has special styling (green border) to indicate it's optimal. Selected button gets green background.

**Maximal Scale (0 to 10):** 11 buttons in a row. Selected button gets purple background.

Both scales show contextual labels ("Too little / Just right / Too much" for balance, "Low / High" for maximal).

### Score Cell Display States

The scoring grid uses pattern-matched render functions for cell content:

| Cell State | Display | When |
|------------|---------|------|
| Future question | `—` | Question hasn't been reached yet |
| Past, scored | Actual value (`+3`, `7`) | Question completed, participant scored |
| Past, skipped | `?` | Question completed, participant was skipped |
| Current, scored | Actual value | Current question, participant already scored |
| Current, active turn | `...` | Current question, this participant is scoring now |
| Current, pending | `—` | Current question, participant's turn hasn't come yet |

---

## 6. Timer Implementation

### Segment-Based Approach

The facilitator timer divides the total session time into 10 equal segments:

| Segment | Purpose |
|---------|---------|
| 1-8 | One segment per question (8 questions) |
| 9 | Summary + Actions (combined) |
| 10 | Unallocated flex/buffer time |

### Timer Behaviour

- Timer is **facilitator-only** — participants don't see the timer
- Timer starts when the **facilitator first reaches the scoring sheet** (skips/completes intro slides)
- Timer displays in **top-right corner** with fixed positioning
- Timer shows **warning state** (red) at 10% remaining time
- Timer **restarts** on each question transition and summary phase
- Timer **stops** when entering wrap-up (completed) state

### Implementation Details

Timer logic is centralized in the `TimerHandler` module (`lib/workgroup_pulse_web/live/session_live/timer_handler.ex`).

```elixir
# Segment duration calculation (Facilitation context)
def calculate_segment_duration(%Session{planned_duration_minutes: minutes}) do
  div(minutes * 60, 10)  # 10 equal segments in seconds
end

# Timer phase mapping
def current_timer_phase(%Session{state: "scoring", current_question_index: idx}),
  do: "question_#{idx}"
def current_timer_phase(%Session{state: "summary"}),
  do: "summary_actions"
def current_timer_phase(_), do: nil  # Timer stops on completed (wrap-up) state

# Warning threshold (10% of segment duration)
def warning_threshold(%Session{} = session) do
  case calculate_segment_duration(session) do
    nil -> nil
    duration -> div(duration, 10)
  end
end
```

### Client-Side Timer Hook

- JavaScript hook (`FacilitatorTimer`) provides smooth 1-second countdown
- Server syncs remaining time; client handles display updates
- Handles warning state class toggling for visual feedback
- Re-syncs on server updates to prevent drift

### Timer Start Behaviour

The timer does **not** start when the session enters scoring state. Instead, it starts when the **facilitator first reaches the scoring sheet** (skips or completes intro slides). This means:
- Facilitator browses intro slides → no timer running
- Facilitator clicks "Skip intro" or "Start Scoring" → timer starts for Question 1
- Other participants' intro navigation has no effect on the timer

### Timer Visibility Rules

| State | Timer Visible (Facilitator) |
|-------|----------------------------|
| lobby | No |
| scoring (intro slides, carousel 0-3) | No (timer not yet started) |
| scoring (scoring sheet, carousel 4) | Yes (phase: Question N) |
| summary | Yes (phase: Summary + Actions) |
| completed | No (wrap-up page — actions created here) |

Note: The "actions" state still exists for backwards compatibility but the default UI flow now skips it, going directly from "summary" to "completed".

---

## 7. Analytics Integration (PostHog)

### Setup

Set environment variable:
```bash
POSTHOG_API_KEY=phc_your_project_api_key
# Optional: POSTHOG_HOST=https://us.i.posthog.com (default)
```

### What's Tracked Automatically

- Page views and page leaves
- Autocapture (clicks, form submissions, etc.)
- Session recordings (if enabled in PostHog dashboard)

### Custom Event Tracking

From any LiveView, you can track custom events:

```elixir
# Track a custom event
{:noreply, push_event(socket, "posthog:capture", %{
  event: "score_submitted",
  properties: %{
    question_index: socket.assigns.session.current_question_index,
    scale_type: socket.assigns.current_question.scale_type
  }
})}

# Identify a user (e.g., facilitator vs participant)
{:noreply, push_event(socket, "posthog:identify", %{
  distinct_id: socket.assigns.participant.id,
  properties: %{
    is_facilitator: socket.assigns.participant.is_facilitator,
    session_code: socket.assigns.session.code
  }
})}
```

### Files Involved

- `config/runtime.exs` — PostHog configuration
- `lib/workgroup_pulse_web/analytics.ex` — Helper module
- `lib/workgroup_pulse_web/components/layouts/root.html.heex` — Script injection
- `assets/js/app.js` — PostHogTracker hook
- `lib/workgroup_pulse_web/live/session_live/show.ex` — Hook attachment

---

## 8. Performance Optimizations

### Input Debouncing

All text input fields use `phx-debounce="300"` to reduce server round-trips during typing:
- Note input field
- Action description input

Note and action form submissions read content directly from form params (not from debounced socket assigns), ensuring that pressing Enter always saves the current input value regardless of debounce timing.

### Optimized Data Loading

The `load_scores/3` function uses participant data from socket assigns rather than querying the database on every score submission. Participant lists are kept in sync via PubSub handlers, eliminating redundant database queries.

### Template Caching

`get_or_load_template/2` reuses the template from socket assigns if already loaded, avoiding repeated DB queries during phase transitions and score submissions.

---

*Document Version: 1.11 — Removed app_header from CoreComponents (session view now uses shared header_bar directly); trimmed unused Petal imports to Button/Field/Form/Input/Link*
*Last Updated: 2026-02-13*
