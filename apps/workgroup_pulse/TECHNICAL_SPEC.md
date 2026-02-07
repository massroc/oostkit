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
│   ├── EventHandlers         # All handle_event callbacks
│   └── MessageHandlers       # All handle_info callbacks (PubSub)
│
├── Helpers/
│   ├── DataLoaders           # Data loading & state hydration
│   ├── StateHelpers          # State transition helpers
│   ├── OperationHelpers      # Standardised error handling
│   └── ScoreHelpers          # Score color/formatting utilities
│
├── TimerHandler              # Facilitator timer logic
│
├── Components/ (pure functional components)
│   ├── LobbyComponent        # Waiting room, participant list, start button
│   ├── IntroComponent        # 4 intro screens with navigation
│   ├── ScoringComponent      # Scoring grid + score overlay (notes slide managed in show.ex carousel)
│   ├── SummaryComponent      # Score summary with individual scores & notes
│   ├── CompletedComponent    # Wrap-up: results, action count, export
│   └── ExportModalComponent  # Export format/content selection
│
├── LiveComponents/
│   └── ActionFormComponent   # Local form state for action creation
│
├── Shared (in CoreComponents)
│   ├── .app_header           # App header with gradient accent
│   ├── .sheet               # Core UI primitive (paper-textured sheet)
│   ├── .facilitator_timer    # Timer display (facilitator-only)
│   └── .score_indicator      # Traffic light score display
│
└── Other LiveViews
    ├── SessionLive.New        # Create new session
    └── SessionLive.Join       # Join existing session
```

### Component Design Principles

1. **Stateless where possible** - Components receive assigns, parent manages state
2. **Slots for flexibility** - Use slots for customizable content areas
3. **Consistent styling API** - Common props like `class`, `variant`, `size`
4. **Render isolation** - Extract LiveComponents to limit re-render scope for frequently updated sections

---

## 2. Phase Components

All phases use the **Sheet Carousel** layout. See [docs/ux-implementation.md](docs/ux-implementation.md) for the full carousel specification (CSS classes, JS hook, slide index map).

**Layout orchestration** lives in `show.ex` via `render_phase_carousel/1`:
- **Lobby** — standalone single-slide wrapper with one `.active` slide, no JS hook
- **All other phases** — unified `workshop-carousel` with `SheetCarousel` hook, `data-index` from `@carousel_index`, click-only mode (`data-click-only` + `sheet-carousel-locked`). Slides 0-3 (intro) are always rendered; slides 4-7 (scoring, notes, summary, wrap-up) are conditionally rendered based on session state.

The `SheetCarousel` JS hook sends `carousel_navigate` events with `carousel: "workshop-carousel"`, updating `@carousel_index` on the server. Phase transitions (via PubSub) automatically set the carousel index to the appropriate slide.

### ScoringComponent

**File:** `lib/workgroup_pulse_web/live/session_live/components/scoring_component.ex`

**Purpose:** Renders the scoring grid sheet and floating score overlay. The notes/actions sheet is a separate carousel slide managed in `show.ex`. Pure functional component — all events bubble to the parent LiveView.

**Layout:**
- **Main Sheet** — `render_full_scoring_grid/1` renders all 8 questions as a `<table>` with participant columns. Questions are grouped by scale type (Balance, Maximal) with section labels.
- **Score Overlay** — `render_score_overlay/1` shows a floating modal with score buttons. Auto-submits on selection. Only visible when `is_my_turn and not my_turn_locked and show_score_overlay`.
- **Notes/Actions Slide** — Managed in `show.ex` as carousel slide 5 (index 5), rendered by `render_notes_slide/1`. Full-height secondary sheet with notes and actions forms.
- **Intro Context Slides** — Slides 0-3 reuse `IntroComponent` public functions (`slide_welcome/1`, etc.) at 480px width for read-only context.

**Key Render Functions:**
- `render_full_scoring_grid/1` — Builds the complete 8-question x N-participant grid
- `render_question_row/2` — Renders a single question row with per-participant score cells
- `render_score_cell_value/3` — Pattern-matched function for cell display states (future `—`, past `?`, current `...`, scored value)
- `render_score_overlay/1` — Floating score input modal
- `render_balance_scale/1` / `render_maximal_scale/1` — Score button grids for each scale type
- `render_mid_transition/1` — Scale change explanation screen (shown before Q5)

**Actions in Scoring Phase:**
Actions are managed during the scoring phase via the notes/actions carousel slide (below notes). The completed/wrap-up page shows action count for export purposes but does not have inline action management.

### Other Phase Components

All follow the same pure functional pattern:
- **SummaryComponent** — Paper-textured sheet with individual score grids, team combined values, traffic lights, and notes
- **CompletedComponent** — Wrap-up page with score overview, strengths/concerns, action count, and export
- **LobbyComponent** — Waiting room with participant list and start button
- **IntroComponent** — 4-screen introduction with navigation

### ActionFormComponent (LiveComponent)

**File:** `lib/workgroup_pulse_web/live/session_live/action_form_component.ex`

**Purpose:** Manages action creation form with local state. Form input changes don't trigger parent re-renders.

**Local State:**
- `action_description` - Action description input
- `action_owner` - Action owner input
- `action_question` - Selected related question

**Communication:** Notifies parent via `send(self(), :reload_actions)` after successful action creation.

---

## 3. Extracted Handler Modules

The following handler modules have been extracted from SessionLive.Show to improve maintainability and separation of concerns.

### EventHandlers

**File:** `lib/workgroup_pulse_web/live/session_live/handlers/event_handlers.ex`

**Purpose:** All `handle_event` callbacks extracted from the root LiveView. Each function receives the socket and returns `{:noreply, socket}`.

**Key Functions:**
- `handle_select_score/2` — Parses score value and auto-submits immediately (no separate submit step)
- `handle_edit_my_score/1` — Reopens the score overlay for click-to-edit
- `handle_complete_turn/1` — Locks turn and advances to next participant
- `handle_skip_turn/1` — Facilitator skips current participant
- `handle_mark_ready/1` — Marks participant as ready to continue
- `handle_focus_sheet/2` — Brings specified sheet panel to front (`:main` or `:notes`)
- `handle_next_question/1` — Advances to next question (facilitator only)
- `handle_go_back/1` — Navigate back (facilitator only, context-aware)
- Note, action, intro, transition, and export handlers

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
- `load_scoring_data/3` — Loads all scoring state: template, current question, scores, turn state, score overlay visibility, all-questions grid data, notes
- `load_scores/3` — Loads scores for a specific question, builds participant score grid, calculates readiness
- `load_all_questions_scores/3` — Loads scores for all 8 questions (for the full grid display)
- `load_notes/3` — Loads notes for a specific question
- `load_summary_data/2` — Loads summary state: scores summary, individual scores, notes by question, strengths/concerns
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
     |> assign(carousel_index: initial_carousel_index(session.state))  # Unified carousel index
     |> assign(show_mid_transition: false)
     |> assign(show_facilitator_tips: false)
     |> assign(note_input: "")
     |> assign(show_export_modal: false)
     |> assign(export_content: "all")

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
     # notes_by_question, strengths, concerns, neutral

     # Actions state (via DataLoaders.load_actions_data/2)
     # all_actions, action_count
    }
  end

  # Events delegate to EventHandlers
  def handle_event("select_score", params, socket),
    do: EventHandlers.handle_select_score(socket, params)

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
- DataLoaders hydrate socket assigns in bulk, avoiding piecemeal loading
- Template caching (`get_or_load_template/2`) avoids repeated DB queries
- Floating action buttons are rendered directly in `show.ex` (not in ScoringComponent) to keep the component pure

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
- Timer **auto-starts** when entering a timed phase (scoring, summary)
- Timer displays in **top-right corner** with fixed positioning
- Timer shows **warning state** (red) at 10% remaining time
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
  do: "summary"
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

### Timer Visibility Rules

| State | Timer Visible (Facilitator) |
|-------|----------------------------|
| lobby | No |
| intro | No |
| scoring | Yes (phase: Question N) |
| summary | Yes (phase: Summary) |
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
- Action owner input

This reduces WebSocket messages by ~80-90% during typing.

### Optimized Data Loading

The `load_scores/3` function uses participant data from socket assigns rather than querying the database on every score submission. Participant lists are kept in sync via PubSub handlers, eliminating redundant database queries.

### LiveComponent Extraction

Frequently updated sections have been extracted into LiveComponents to isolate re-renders:
- **ActionFormComponent** — Manages local form state for action creation (typing doesn't trigger parent re-renders)

### Template Caching

`get_or_load_template/2` reuses the template from socket assigns if already loaded, avoiding repeated DB queries during phase transitions and score submissions.

---

*Document Version: 1.0*
*Created: 2026-02-07*
