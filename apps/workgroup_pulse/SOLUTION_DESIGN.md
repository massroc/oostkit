# Workgroup Pulse - Solution Design

## Document Info
- **Version:** 4.0
- **Last Updated:** 2026-02-07
- **Status:** Draft

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [SOLID Principles Application](#solid-principles-application)
3. [Phoenix Contexts (Bounded Contexts)](#phoenix-contexts-bounded-contexts)
4. [Domain Models](#domain-models)
5. [Database Schema](#database-schema)
6. [Real-Time Architecture](#real-time-architecture)
7. [State Management](#state-management)
8. [Security Considerations](#security-considerations)
9. [Error Handling Strategy](#error-handling-strategy)
10. [Testing Strategy](#testing-strategy)
11. [Deployment Architecture](#deployment-architecture)

**Related documents:**
- [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md) — LiveView component hierarchy, handler modules, socket state, timer logic, analytics
- [docs/ux-design.md](docs/ux-design.md) — UX design principles, visual design, accessibility
- [docs/ux-implementation.md](docs/ux-implementation.md) — CSS systems, JS hooks, carousel, sheet dimensions

---

## Architecture Overview

### Tech Stack

| Component | Technology |
|-----------|------------|
| Backend | Elixir / Phoenix |
| Real-time | Phoenix LiveView + PubSub |
| Database | PostgreSQL |
| Styling | Tailwind CSS |
| Analytics | PostHog |
| Hosting | Fly.io |

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Browser (Client)                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 Phoenix LiveView                         │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐               │   │
│  │  │  Lobby   │ │ Scoring  │ │ Summary  │               │   │
│  │  │   View   │ │   View   │ │   View   │               │   │
│  │  └──────────┘ └──────────┘ └──────────┘               │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │ WebSocket
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Phoenix Application                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    LiveView Layer                        │   │
│  └─────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 Phoenix PubSub (Real-time)               │   │
│  └─────────────────────────────────────────────────────────┘   │
│  ┌───────────────┐ ┌───────────────┐ ┌───────────────────┐    │
│  │   Workshops   │ │   Sessions    │ │    Facilitation   │    │
│  │    Context    │ │    Context    │ │      Context      │    │
│  └───────────────┘ └───────────────┘ └───────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Ecto / PostgreSQL                     │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Design Philosophy

1. **Separation of Concerns** - Clear boundaries between workshop content, session management, and facilitation logic
2. **Configuration-Driven** - Workshop definitions stored as data, enabling future workshop types
3. **Real-Time First** - Built on Phoenix PubSub for seamless multi-user synchronization
4. **Progressive Enhancement** - Core functionality works; enhanced features layer on top
5. **Butcher Paper Principle** - The tool behaves like butcher paper on a wall: visible, permanent within each phase, sequential, shared, and simple. Scores are visible immediately when placed, one person scores at a time, and rows lock permanently once the group moves on.

### Design for Reuse

This tool may serve as a foundation for other facilitated team events (e.g., team kick-offs, retrospectives, planning sessions). The architecture supports this by:

**Separating concerns:**
- **Core facilitation engine** - real-time sync, session management, participant tracking
- **Workshop-specific content** - the Six Criteria questions, explanations, scoring scales
- **Reusable UI components** - timers, voting/scoring widgets, discussion prompts, action capture

**Potentially reusable components:**

| Component | Reuse Potential |
|-----------|-----------------|
| Session creation & joining | Any team event |
| Real-time participant sync | Any collaborative activity |
| Waiting room / lobby | Any group event |
| Timed sections with countdown | Any structured workshop |
| Turn-based sequential input | Round-robin exercises, facilitated discussions |
| Discussion prompts (contextual) | Any facilitated discussion |
| Notes capture per section | Any workshop |
| Action planning with owners | Any team session |
| Facilitator Assistance (on-demand help) | Any guided experience |
| Traffic light visualization | Any scored/rated content |
| Feedback button | Any product |

**Architectural approach:**
- Clean separation between generic facilitation features and Six Criteria-specific content
- Configuration-driven where possible (e.g., questions, scales, timing could be data)
- Component-based UI that can be composed for different workshop types
- Consider a "workshop template" concept for future flexibility

*Note: This doesn't mean over-engineering the MVP - but make conscious decisions that don't paint us into a corner.*

---

## SOLID Principles Application

### Single Responsibility Principle (SRP)

Each module has one reason to change:

| Module | Responsibility |
|--------|---------------|
| `Workshops` | Workshop template definitions and question content |
| `Sessions` | Session lifecycle, participant management |
| `Scoring` | Score submission, validation, aggregation |
| `Facilitation` | Timer calculations, phase transitions, prompts |
| `Notes` | Notes and action item capture |
| `Presence` | Real-time participant presence tracking |

### Open/Closed Principle (OCP)

**Workshop Templates are extensible without modification:**

New workshop types can be added as database records (Template + Questions) without changing core logic. The Workshops context provides read-only access to template data, and the scoring/facilitation logic adapts based on question scale types.

**Scoring strategies are pluggable:**

```elixir
defmodule WorkgroupPulse.Scoring.Strategy do
  @callback validate(score :: integer(), question :: Question.t()) :: :ok | {:error, String.t()}
  @callback color_code(score :: integer(), question :: Question.t()) :: :green | :amber | :red
  @callback optimal_score(question :: Question.t()) :: integer()
end

# Balance scale (-5 to +5, optimal at 0)
defmodule WorkgroupPulse.Scoring.BalanceScale do
  @behaviour WorkgroupPulse.Scoring.Strategy
end

# Maximal scale (0 to 10, optimal at 10)
defmodule WorkgroupPulse.Scoring.MaximalScale do
  @behaviour WorkgroupPulse.Scoring.Strategy
end
```

### Liskov Substitution Principle (LSP)

All workshop templates are interchangeable:

```elixir
# Any workshop template can be used wherever Template is expected
def start_session(template) when is_struct(template, Template) do
  questions = template.questions()
  # Works with SixCriteria or any future workshop type
end
```

### Interface Segregation Principle (ISP)

Focused context APIs rather than monolithic interfaces:

Each Phoenix context exposes a focused public API for its bounded domain. For example, `Scoring` handles only score submission and aggregation, `Notes` handles only notes and actions, and `Facilitation` provides only timer calculation utilities. Contexts don't leak responsibilities across boundaries.

### Dependency Inversion Principle (DIP)

High-level modules don't depend on low-level details:

```elixir
# LiveView depends on abstract Session behaviour, not concrete implementation
defmodule WorkgroupPulseWeb.WorkshopLive do
  # Injected dependency - can be mocked in tests
  def mount(_params, _session, socket) do
    session_server = socket.assigns[:session_server] || WorkgroupPulse.Sessions.Server
    # Use session_server abstraction
  end
end

# PubSub abstracted for testing
defmodule WorkgroupPulse.Broadcaster do
  @callback broadcast(topic :: String.t(), event :: atom(), payload :: map()) :: :ok
end
```

---

## Phoenix Contexts (Bounded Contexts)

### Context Map

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  ┌─────────────┐      ┌─────────────┐      ┌────────────┐  │
│  │  Workshops  │◄────►│  Sessions   │◄────►│  Scoring   │  │
│  │             │      │             │      │            │  │
│  │ - Templates │      │ - Session   │      │ - Scores   │  │
│  │ - Questions │      │ - Particip. │      │ - Aggreg.  │  │
│  │ - Scales    │      │ - State     │      │ - Colors   │  │
│  └─────────────┘      └─────────────┘      └────────────┘  │
│         │                    │                    │         │
│         │                    ▼                    │         │
│         │           ┌─────────────┐               │         │
│         └──────────►│ Facilitation│◄──────────────┘         │
│                     │             │                         │
│                     │ - Calcs     │                         │
│                     │ - Phases    │                         │
│                     │ - Prompts   │                         │
│                     └─────────────┘                         │
│                            │                                │
│                            ▼                                │
│                     ┌─────────────┐                         │
│                     │    Notes    │                         │
│                     │             │                         │
│                     │ - Notes     │                         │
│                     │ - Actions   │                         │
│                     └─────────────┘                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Context Definitions

#### 1. Workshops Context

**Purpose:** Read-only access to workshop templates and content (the "what" of workshops)

```elixir
defmodule WorkgroupPulse.Workshops do
  # Public API (read-only)
  def list_templates()
  def get_template!(id)
  def get_template_by_slug(slug)
  def get_template_with_questions(id)
  def list_questions(template_id)
  def get_question(template_id, question_number)
  def count_questions(template_id)
end
```

**Entities:**
- `Template` - Workshop definition (Six Criteria, future types)
- `Question` - Individual question with explanation, scale, prompts

#### 2. Sessions Context

**Purpose:** Manage session lifecycle, participants, and turn-based flow (the "who" and "when")

```elixir
defmodule WorkgroupPulse.Sessions do
  # Session management
  def create_session(template_id, opts \\ [])
  def get_session!(id)
  def get_session_by_code(code)
  def end_session(session_id)

  # Participant management
  def join_session(session_id, participant_name)
  def leave_session(session_id, participant_id)
  def mark_participant_ready(session_id, participant_id)
  def mark_participant_inactive(session_id, participant_id)
  def reactivate_participant(session_id, participant_id)
  def get_active_participants(session_id)
  def get_participants_in_turn_order(session_id)

  # Turn-based flow management
  def get_current_turn_participant(session_id, question_index)
  def advance_turn(session_id, question_index)
  def skip_turn(session_id, question_index)
  def get_skipped_participants(session_id, question_index)

  # State queries
  def all_participants_ready?(session_id)
  def all_active_participants_scored?(session_id, question_index)
  def get_session_state(session_id)
end
```

**Entities:**
- `Session` - Workshop instance with state, timing, settings
- `Participant` - Person in a session with status, browser token
- `SessionSettings` - Time allocation, participant limits

**Session Persistence & Resumption:**

Sessions are fully persisted to the database, allowing teams to pause and resume workshops across browser sessions or days. The same session link remains valid throughout.

| Session State | Expiry | Behavior |
|---------------|--------|----------|
| Incomplete (in progress) | 14 days from last activity | Team can resume via original link |
| Completed | 90 days from completion | Available for review, then cleaned up |
| Expired | - | Link redirects to homepage (no error) |

**Resumption Flow:**
```
1. Team starts workshop → Session created with code ABC123
2. Complete questions 1-4 → State persisted to DB
3. Everyone closes browser (break/meeting/end of day)
4. Team returns later → Same link: /workshop/ABC123
5. Participants rejoin:
   - Browser token matches → Auto-recognized
   - Token missing → Re-enter name, matched to original participant
6. Resume at question 5 → All previous scores/notes intact
```

#### 3. Scoring Context

**Purpose:** Handle score submission, validation, locking, and aggregation

```elixir
defmodule WorkgroupPulse.Scoring do
  # Score submission
  def submit_score(participant_id, question_index, value)
  def update_score(participant_id, question_index, new_value)
  def lock_participant_turn(participant_id, question_index)
  def lock_row(session_id, question_index)

  # Score state queries
  def turn_locked?(participant_id, question_index)
  def row_locked?(session_id, question_index)
  def can_edit_score?(participant_id, question_index)

  # Score retrieval
  def get_scores(session_id, question_index)
  def get_participant_score(participant_id, question_index)
  def get_all_session_scores(session_id)

  # Aggregation
  def calculate_average(session_id, question_index)
  def calculate_spread(session_id, question_index)
  def get_score_summary(session_id)

  # Traffic light
  def color_for_score(score_value, question)
  def color_for_average(average, question)
end
```

**Entities:**
- `Score` - Individual participant score for a question (includes turn_locked and row_locked flags)
- `ScoreSummary` - Aggregated statistics for a question

#### 4. Facilitation Context

**Purpose:** Provide timer calculation utilities and phase metadata (the timer itself is in-process via `Process.send_after` in TimerHandler, not stored in the database)

```elixir
defmodule WorkgroupPulse.Facilitation do
  # Calculation utilities
  def phase_name(session)
  def calculate_segment_duration(session)
  def current_timer_phase(session)
  def timer_enabled?(session)
  def warning_threshold(session)
  def suggested_duration(session)
  def total_suggested_duration(session)
end
```

**Note:** There is no Timer schema or DB persistence for timers. The facilitator timer is purely in-process, managed by the `TimerHandler` module using `Process.send_after`. See [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md) for timer implementation details.

#### 5. Notes Context

**Purpose:** Capture discussion notes and action items

```elixir
defmodule WorkgroupPulse.Notes do
  # Notes
  def add_note(session_id, question_id, content, author_id)
  def update_note(note_id, content)
  def delete_note(note_id)
  def get_notes(session_id, question_id)
  def get_all_notes(session_id)

  # Actions
  def add_action(session_id, content, opts \\ [])
  def update_action(action_id, attrs)
  def delete_action(action_id)
  def assign_owner(action_id, owner_name)
  def link_to_question(action_id, question_id)
  def get_actions(session_id)
end
```

**Entities:**
- `Note` - Discussion note linked to a question
- `Action` - Action item with optional owner and question link

---

## Domain Models

### Entity Relationship Diagram

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│   Template   │       │   Session    │       │ Participant  │
├──────────────┤       ├──────────────┤       ├──────────────┤
│ id           │       │ id           │       │ id           │
│ name         │◄──────│ template_id  │       │ session_id   │──┐
│ description  │       │ code         │◄──────│ name         │  │
│ version      │       │ state        │       │ browser_token│  │
└──────────────┘       │ settings     │       │ status       │  │
       │               │ started_at   │       │ joined_at    │  │
       │               │ completed_at │       └──────────────┘  │
       ▼               └──────────────┘              │          │
┌──────────────┐              │                      │          │
│   Question   │              │                      ▼          │
├──────────────┤              │               ┌──────────────┐  │
│ id           │              │               │    Score     │  │
│ template_id  │──────────────┼───────────────├──────────────┤  │
│ number       │              │               │ id           │  │
│ title        │              │               │ session_id   │──┘
│ explanation  │              │               │ question_id  │──┐
│ scale_type   │◄─────────────┼───────────────│ participant_id│  │
│ scale_min    │              │               │ value        │  │
│ scale_max    │              │               │ submitted_at │  │
│ optimal      │              │               │ locked       │  │
└──────────────┘              │               └──────────────┘  │
                              │                                  │
                              │               ┌──────────────┐  │
                              │               │     Note     │  │
                              │               ├──────────────┤  │
                              │               │ id           │  │
                              │               │ session_id   │  │
                              │               │ question_id  │──┘
                              │               │ content      │
                              │               │ author_id    │
                              │               │ created_at   │
                              │               └──────────────┘
                                             ┌──────────────┐
                                             │    Action    │
                                             ├──────────────┤
                                             │ id           │
                                             │ session_id   │
                                             │ content      │
                                             │ owner        │
                                             │ question_id  │
                                             │ created_at   │
                                             └──────────────┘
```

### Core Schemas

```elixir
defmodule WorkgroupPulse.Sessions.Session do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "sessions" do
    field :code, :string  # 6-character join code
    field :state, Ecto.Enum, values: [:lobby, :intro, :scoring, :summary, :actions, :completed]
    field :current_question, :integer, default: 0
    field :current_turn_index, :integer, default: 0   # Index into turn_order for current scorer

    # Settings (embedded)
    embeds_one :settings, Settings do
      field :total_duration_minutes, :integer, default: nil  # nil = no timer; optional presets: 120, 210, or custom
      field :max_participants, :integer, default: 20
      field :skip_intro, :boolean, default: false
    end

    # Timestamps
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :last_activity_at, :utc_datetime  # Updated on any participant action
    field :expires_at, :utc_datetime        # Calculated: last_activity + 14 days (or completed + 90 days)

    belongs_to :template, WorkgroupPulse.Workshops.Template, type: :binary_id
    has_many :participants, WorkgroupPulse.Sessions.Participant
    has_many :scores, WorkgroupPulse.Scoring.Score
    has_many :notes, WorkgroupPulse.Notes.Note
    has_many :actions, WorkgroupPulse.Notes.Action

    timestamps()
  end
end

defmodule WorkgroupPulse.Sessions.Participant do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "participants" do
    field :name, :string
    field :browser_token, :string  # For reconnection
    field :status, Ecto.Enum, values: [:active, :inactive, :dropped]
    field :is_facilitator, :boolean, default: false
    field :is_observer, :boolean, default: false  # Observer cannot enter scores
    field :ready, :boolean, default: false
    field :joined_at, :utc_datetime
    field :last_seen_at, :utc_datetime

    belongs_to :session, WorkgroupPulse.Sessions.Session, type: :binary_id
    has_many :scores, WorkgroupPulse.Scoring.Score

    timestamps()
  end
end

defmodule WorkgroupPulse.Scoring.Score do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "scores" do
    field :value, :integer
    field :turn_locked, :boolean, default: false   # Locked when participant clicks "Done"
    field :row_locked, :boolean, default: false    # Locked when group advances to next row
    field :submitted_at, :utc_datetime

    belongs_to :session, WorkgroupPulse.Sessions.Session, type: :binary_id
    belongs_to :participant, WorkgroupPulse.Sessions.Participant, type: :binary_id
    belongs_to :question, WorkgroupPulse.Workshops.Question, type: :binary_id

    timestamps()
  end
end
```

### Value Objects

```elixir
defmodule WorkgroupPulse.Scoring.ScoreResult do
  @moduledoc "Immutable value object representing a scored question result"

  defstruct [
    :question_number,
    :scores,           # List of {participant_name, value, color}
    :average,
    :average_color,
    :spread,           # Standard deviation
    :all_submitted
  ]
end

defmodule WorkgroupPulse.Facilitation.TimeStatus do
  @moduledoc "Immutable value object representing current time status"

  defstruct [
    :section_remaining_ms,
    :section_total_ms,
    :overall_remaining_ms,
    :overall_total_ms,
    :is_paused,
    :is_exceeded,
    :pacing  # :ahead, :on_track, :behind
  ]
end
```

---

## Database Schema

### Migrations

```elixir
# Migration: Create Templates and Questions (Workshop Content)
defmodule WorkgroupPulse.Repo.Migrations.CreateWorkshopContent do
  use Ecto.Migration

  def change do
    create table(:templates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :version, :string, default: "1.0"
      add :active, :boolean, default: true

      timestamps()
    end

    create table(:questions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :template_id, references(:templates, type: :binary_id, on_delete: :delete_all), null: false
      add :number, :integer, null: false
      add :title, :string, null: false
      add :short_title, :string
      add :explanation, :text, null: false
      add :scale_type, :string, null: false  # "balance" or "maximal"
      add :scale_min, :integer, null: false
      add :scale_max, :integer, null: false
      add :optimal_value, :integer, null: false
      add :discussion_prompts, {:array, :string}, default: []
      add :facilitator_help, :text

      timestamps()
    end

    create unique_index(:questions, [:template_id, :number])
  end
end

# Migration: Create Sessions and Participants
defmodule WorkgroupPulse.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :template_id, references(:templates, type: :binary_id), null: false
      add :code, :string, size: 6, null: false
      add :state, :string, default: "lobby"
      add :current_question, :integer, default: 0
      add :current_turn_index, :integer, default: 0
      add :settings, :map, default: %{}
      add :started_at, :utc_datetime
      add :completed_at, :utc_datetime
      add :last_activity_at, :utc_datetime
      add :expires_at, :utc_datetime

      timestamps()
    end

    create unique_index(:sessions, [:code])
    create index(:sessions, [:state])
    create index(:sessions, [:expires_at])
    create index(:sessions, [:last_activity_at])

    create table(:participants, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :session_id, references(:sessions, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :browser_token, :string, null: false
      add :status, :string, default: "active"
      add :ready, :boolean, default: false
      add :joined_at, :utc_datetime
      add :last_seen_at, :utc_datetime

      timestamps()
    end

    create index(:participants, [:session_id])
    create unique_index(:participants, [:session_id, :browser_token])
  end
end

# Migration: Create Scores
defmodule WorkgroupPulse.Repo.Migrations.CreateScores do
  use Ecto.Migration

  def change do
    create table(:scores, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :session_id, references(:sessions, type: :binary_id, on_delete: :delete_all), null: false
      add :participant_id, references(:participants, type: :binary_id, on_delete: :delete_all), null: false
      add :question_id, references(:questions, type: :binary_id), null: false
      add :value, :integer, null: false
      add :locked, :boolean, default: false
      add :submitted_at, :utc_datetime

      timestamps()
    end

    create unique_index(:scores, [:session_id, :participant_id, :question_id])
    create index(:scores, [:session_id, :question_id])
  end
end

# Migration: Create Notes and Actions
defmodule WorkgroupPulse.Repo.Migrations.CreateNotesAndActions do
  use Ecto.Migration

  def change do
    create table(:notes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :session_id, references(:sessions, type: :binary_id, on_delete: :delete_all), null: false
      add :question_id, references(:questions, type: :binary_id), null: true  # Can be general note
      add :author_id, references(:participants, type: :binary_id, on_delete: :nilify_all)
      add :content, :text, null: false

      timestamps()
    end

    create index(:notes, [:session_id])
    create index(:notes, [:session_id, :question_id])

    create table(:actions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :session_id, references(:sessions, type: :binary_id, on_delete: :delete_all), null: false
      add :question_id, references(:questions, type: :binary_id), null: true  # Optional link
      add :content, :text, null: false
      add :owner, :string  # Just a name, not a participant reference
      add :position, :integer  # For ordering

      timestamps()
    end

    create index(:actions, [:session_id])
  end
end

# Migration: Create Feedback
defmodule WorkgroupPulse.Repo.Migrations.CreateFeedback do
  use Ecto.Migration

  def change do
    create table(:feedback, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :session_id, references(:sessions, type: :binary_id, on_delete: :nilify_all)
      add :section, :string  # Where in workshop feedback was given
      add :category, :string  # "working_well", "improvement", "bug"
      add :content, :text, null: false
      add :email, :string  # Optional contact

      timestamps()
    end
  end
end
```

### Indexes Strategy

| Table | Index | Purpose |
|-------|-------|---------|
| sessions | code (unique) | Fast join by code |
| sessions | state | Filter active sessions |
| sessions | expires_at | Cleanup expired sessions |
| sessions | last_activity_at | Identify stale sessions |
| participants | session_id | List session participants |
| participants | session_id, browser_token (unique) | Reconnection lookup |
| scores | session_id, question_id | Get all scores for reveal |
| scores | session_id, participant_id, question_id (unique) | One score per participant per question |

---

## Real-Time Architecture

### PubSub Topics

```elixir
defmodule WorkgroupPulse.PubSub.Topics do
  @moduledoc "Centralized topic definitions for PubSub"

  # Session-level events (all participants)
  def session(session_id), do: "session:#{session_id}"

  # Presence tracking
  def presence(session_id), do: "presence:#{session_id}"

  # Timer updates (frequent, separate channel)
  def timer(session_id), do: "timer:#{session_id}"
end
```

### Event Types

```elixir
defmodule WorkgroupPulse.PubSub.Events do
  @moduledoc "Event definitions for real-time updates"

  # Session events
  @type session_event ::
    :participant_joined
    | :participant_left
    | :participant_ready
    | :participant_unready
    | :phase_changed
    | :question_changed
    | :row_locked           # All scores in row permanently locked
    | :session_ended

  # Turn-based scoring events
  @type scoring_event ::
    :score_placed          # Participant placed/updated score (visible immediately)
    | :turn_completed      # Participant clicked "Done", turn advances
    | :turn_skipped        # Current participant was skipped

  # Notes events
  @type notes_event ::
    :note_added
    | :note_updated
    | :note_deleted
    | :action_added
    | :action_updated
    | :action_deleted

  # Timer events
  @type timer_event ::
    :timer_started
    | :timer_paused
    | :timer_resumed
    | :timer_tick
    | :timer_exceeded
end
```

### Presence Tracking

```elixir
defmodule WorkgroupPulseWeb.Presence do
  use Phoenix.Presence,
    otp_app: :workgroup_pulse,
    pubsub_server: WorkgroupPulse.PubSub

  @doc "Track a participant joining a session"
  def track_participant(socket, session_id, participant) do
    track(socket, "presence:#{session_id}", participant.id, %{
      name: participant.name,
      status: participant.status,
      ready: participant.ready,
      joined_at: participant.joined_at
    })
  end

  @doc "Get all present participants for a session"
  def list_participants(session_id) do
    list("presence:#{session_id}")
    |> Enum.map(fn {_id, %{metas: [meta | _]}} -> meta end)
  end
end
```

### Broadcast Helper

```elixir
defmodule WorkgroupPulse.Broadcaster do
  @moduledoc "Centralized broadcasting for real-time events"

  alias Phoenix.PubSub
  alias WorkgroupPulse.PubSub.Topics

  def broadcast_session_event(session_id, event, payload \\ %{}) do
    PubSub.broadcast(
      WorkgroupPulse.PubSub,
      Topics.session(session_id),
      {event, payload}
    )
  end

  def broadcast_timer_tick(session_id, time_status) do
    PubSub.broadcast(
      WorkgroupPulse.PubSub,
      Topics.timer(session_id),
      {:timer_tick, time_status}
    )
  end
end
```

---

## State Management

### Session State Machine

```
                    ┌─────────┐
                    │  lobby  │
                    └────┬────┘
                         │ facilitator starts
                         ▼
                    ┌─────────┐
            ┌──────►│  intro  │ (skippable)
            │       └────┬────┘
            │            │ complete intro / skip
            │            ▼
            │       ┌─────────┐
            │       │ scoring │◄───────────────┐
            │       └────┬────┘                │
            │            │                     │
            │            ▼                     │
            │    ┌─────────────────────────┐   │
            │    │     question N (row)    │   │
            │    │                         │   │
            │    │  ┌───────────────────┐  │   │
            │    │  │ turn: participant │  │   │
            │    │  │      1, 2, 3...   │──┼───┼── "Done" advances turn
            │    │  └─────────┬─────────┘  │   │
            │    │            │            │   │
            │    │            ▼            │   │
            │    │  ┌───────────────────┐  │   │
            │    │  │  all mark ready   │  │   │
            │    │  └─────────┬─────────┘  │   │
            │    │            │ row locks  │   │
            │    └────────────┼────────────┘   │
            │                 │                │
            │                 │ N < 8 ─────────┘
            │                 │ N = 8
            │                 ▼
            │            ┌─────────┐
            │            │ summary │  (review scores & notes)
            │            └────┬────┘
            │                 │ continue to wrap-up
            │                 ▼
            │            ┌───────────┐
            └────────────│ completed │  (wrap-up: actions & finish)
                         └───────────┘
```

### Turn-Based Scoring Flow (Within Each Question/Row)

```
┌─────────────────────────────────────────────────────────────────┐
│                    Question N Active                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Turn Order: [P1] → [P2] → [P3] → [P4] → ... (by join order)    │
│               ▲                                                  │
│               └── current_turn_index                             │
│                                                                  │
│  For each participant's turn:                                    │
│    1. Highlight "Your turn to score"                            │
│    2. Participant places score (visible immediately)             │
│    3. Participant can edit score while turn is active            │
│    4. Participant clicks "Done" → turn_locked = true             │
│    5. current_turn_index advances to next active participant     │
│                                                                  │
│  Catch-up phase (after last active participant):                 │
│    - Any skipped participants can add their score                │
│    - They go in turn order if multiple were skipped              │
│                                                                  │
│  Row completion:                                                 │
│    - All participants mark "Ready"                               │
│    - Row locks permanently (row_locked = true for all scores)    │
│    - Advance to question N+1                                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

Note: The "actions" state still exists in the schema for backwards compatibility
but the default UI flow now goes directly from "summary" to "completed".
The "completed" state serves as the wrap-up page where actions are created.
The wrap-up page displays all captured action items inline (beneath strengths/concerns).

### Navigation Rules

**Unified carousel navigation:**

All workshop phases (except lobby) share a single unified carousel (`workshop-carousel`) powered by [Embla Carousel](https://www.embla-carousel.com/) v8.6.0 (vendored ESM). Embla handles slide positioning, centering (`align: 'center'`), and smooth scroll animation. Drag/swipe is disabled (`watchDrag: false`) — navigation is click-only. Slides are progressively appended as the workshop advances. FABs drive backend state changes (synced via PubSub); clicking carousel slides is local-only navigation for reference.

**Back Button Availability (FABs, facilitator only):**
| Screen | Carousel Index | Facilitator | Participants |
|--------|---------------|-------------|--------------|
| Scoring (Q1) | 4 | Hidden (can't go further back) | Hidden |
| Scoring (Q2+) | 4 | Back to previous question | Hidden |
| Summary | 6 | Back to last question | Hidden |
| Wrap-up | 7 | Back to summary | Hidden |

**Navigation Constraints:**
- Back button cannot navigate earlier than Q1 (no return to intro from scoring)
- Only facilitator can navigate backwards — participants follow the session state via PubSub
- Going back resets participants' ready state for the current question
- FABs are hidden when browsing slides outside the current phase (e.g., reviewing intro slides during scoring)

### Readiness Rules

**Team Discussion Phase (after all turns complete):**
- Scored participants must explicitly click "I'm Ready to Continue"
- Skipped participants are automatically marked as ready
- Facilitator can advance once all participants are ready

**Revisiting Completed Questions:**
When navigating back to a row-locked (completed) question:
- All participants are automatically marked as ready
- This allows immediate forward navigation without re-clicking Ready
- The team has already discussed and agreed to move forward previously

---

## Security Considerations

### Authentication & Authorization

| Concern | MVP Approach | Future Enhancement |
|---------|--------------|-------------------|
| Session access | Anyone with link can join (before start) | Invite-only option |
| Participant identity | Browser token + name match | Account-based auth |
| Rejoin verification | Browser localStorage token | Login required |
| Score visibility | Team only, never external | Unchanged |

### Input Validation

```elixir
defmodule WorkgroupPulse.Scoring do
  def submit_score(participant_id, question_id, value) do
    with {:ok, participant} <- get_active_participant(participant_id),
         {:ok, question} <- Workshops.get_question(question_id),
         :ok <- validate_score_value(value, question),
         :ok <- validate_not_already_locked(participant_id, question_id) do
      # Proceed with score submission
    end
  end

  defp validate_score_value(value, %{scale_type: :balance}) when value in -5..5, do: :ok
  defp validate_score_value(value, %{scale_type: :maximal}) when value in 0..10, do: :ok
  defp validate_score_value(_, _), do: {:error, :invalid_score}
end
```

### Rate Limiting

```elixir
# In endpoint.ex or a plug
plug WorkgroupPulseWeb.Plugs.RateLimiter,
  routes: [
    {"/api/sessions", :create, limit: 10, window: :minute},
    {"/api/feedback", :create, limit: 5, window: :minute}
  ]
```

### Data Sanitization

- All user input (names, notes, actions) sanitized before storage and display
- Phoenix's built-in XSS protection via `~H` sigil
- Content Security Policy headers configured

---

## Error Handling Strategy

### Error Types

```elixir
defmodule WorkgroupPulse.Error do
  defexception [:type, :message, :details]

  @type error_type ::
    :not_found
    | :invalid_state
    | :unauthorized
    | :validation_failed
    | :session_expired
    | :session_full
    | :already_exists

  def not_found(resource), do: %__MODULE__{type: :not_found, message: "#{resource} not found"}
  def invalid_state(msg), do: %__MODULE__{type: :invalid_state, message: msg}
  def session_expired(), do: %__MODULE__{type: :session_expired, message: "Session has expired"}
end
```

### Context Error Handling

```elixir
defmodule WorkgroupPulse.Sessions do
  def join_session(session_id, name) do
    with {:ok, session} <- get_active_session(session_id),
         :ok <- validate_can_join(session),
         :ok <- validate_participant_limit(session),
         {:ok, participant} <- create_participant(session, name) do
      broadcast_participant_joined(session_id, participant)
      {:ok, participant}
    else
      {:error, :session_not_found} -> {:error, Error.not_found("Session")}
      {:error, :session_started} -> {:error, Error.invalid_state("Session already started")}
      {:error, :session_full} -> {:error, Error.session_full()}
      error -> error
    end
  end
end
```

### LiveView Error Display

```elixir
defmodule WorkgroupPulseWeb.WorkshopLive do
  def handle_info({:error, %Error{} = error}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, error.message)
     |> maybe_redirect(error)}
  end

  defp maybe_redirect(socket, %Error{type: :session_expired}) do
    push_navigate(socket, to: ~p"/")
  end
  defp maybe_redirect(socket, _), do: socket
end
```

### Connection Recovery

```elixir
defmodule WorkgroupPulseWeb.WorkshopLive do
  # Automatic reconnection handling
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    # Re-sync state after reconnection
    {:noreply, reload_session_state(socket)}
  end

  defp reload_session_state(socket) do
    session = Sessions.get_session!(socket.assigns.session.id)

    socket
    |> assign(:session, session)
    |> assign(:participants, Sessions.get_active_participants(session.id))
    |> assign(:scores, Scoring.get_all_session_scores(session.id))
  end
end
```

---

## Testing Strategy

### Test Pyramid

```
                    ┌─────────┐
                    │   E2E   │  Few, critical paths
                    │  Tests  │  (Wallaby/Playwright)
                    └────┬────┘
                         │
              ┌──────────┴──────────┐
              │   Integration Tests │  LiveView, PubSub
              │                     │  (Phoenix.LiveViewTest)
              └──────────┬──────────┘
                         │
         ┌───────────────┴───────────────┐
         │         Unit Tests            │  Contexts, Schemas
         │                               │  (ExUnit)
         └───────────────────────────────┘
```

### Context Testing

```elixir
defmodule WorkgroupPulse.ScoringTest do
  use WorkgroupPulse.DataCase

  alias WorkgroupPulse.Scoring

  describe "submit_score/3" do
    setup do
      session = insert(:session)
      participant = insert(:participant, session: session)
      question = insert(:question, scale_type: :balance)

      %{session: session, participant: participant, question: question}
    end

    test "creates score with valid balance value", ctx do
      assert {:ok, score} = Scoring.submit_score(ctx.participant.id, ctx.question.id, 0)
      assert score.value == 0
    end

    test "rejects out of range balance value", ctx do
      assert {:error, :invalid_score} = Scoring.submit_score(ctx.participant.id, ctx.question.id, 6)
    end

    test "broadcasts score_submitted event", ctx do
      Phoenix.PubSub.subscribe(WorkgroupPulse.PubSub, "session:#{ctx.session.id}")

      {:ok, _} = Scoring.submit_score(ctx.participant.id, ctx.question.id, 3)

      assert_receive {:score_submitted, %{participant_id: pid}}
      assert pid == ctx.participant.id
    end
  end
end
```

### LiveView Testing

```elixir
defmodule WorkgroupPulseWeb.WorkshopLiveTest do
  use WorkgroupPulseWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "scoring phase" do
    setup do
      session = insert(:session, state: :scoring, current_question: 1)
      participant = insert(:participant, session: session)

      %{session: session, participant: participant}
    end

    test "displays current question", %{conn: conn, session: session, participant: participant} do
      {:ok, view, _html} =
        conn
        |> init_test_session(participant)
        |> live(~p"/workshop/#{session.code}")

      assert has_element?(view, "[data-question-number='1']")
      assert has_element?(view, ".score-input")
    end

    test "submitting score updates UI", %{conn: conn, session: session, participant: participant} do
      {:ok, view, _html} =
        conn
        |> init_test_session(participant)
        |> live(~p"/workshop/#{session.code}")

      view
      |> element(".score-input")
      |> render_change(%{value: "3"})

      view
      |> element("button", "Submit Score")
      |> render_click()

      assert has_element?(view, ".score-submitted-indicator")
    end
  end
end
```

### Factory Pattern

```elixir
defmodule WorkgroupPulse.Factory do
  use ExMachina.Ecto, repo: WorkgroupPulse.Repo

  def session_factory do
    %WorkgroupPulse.Sessions.Session{
      code: sequence(:code, &"TEST#{&1}"),
      state: :lobby,
      template: build(:template),
      settings: %{total_duration_minutes: 210, max_participants: 20}
    }
  end

  def participant_factory do
    %WorkgroupPulse.Sessions.Participant{
      name: sequence(:name, &"Participant #{&1}"),
      browser_token: Ecto.UUID.generate(),
      status: :active,
      session: build(:session)
    }
  end

  def score_factory do
    %WorkgroupPulse.Scoring.Score{
      value: Enum.random(-5..5),
      locked: false,
      session: build(:session),
      participant: build(:participant),
      question: build(:question)
    }
  end
end
```

---

## Deployment Architecture

### Fly.io Configuration

```toml
# fly.toml
app = "workgroup-pulse"
primary_region = "syd"  # Sydney for AU-based teams

[build]
  [build.args]
    MIX_ENV = "prod"

[env]
  PHX_HOST = "workgroup-pulse.fly.dev"
  PORT = "8080"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 1

  [http_service.concurrency]
    type = "connections"
    hard_limit = 1000
    soft_limit = 800

[[services]]
  protocol = "tcp"
  internal_port = 8080

  [[services.ports]]
    port = 80
    handlers = ["http"]

  [[services.ports]]
    port = 443
    handlers = ["tls", "http"]

[[vm]]
  cpu_kind = "shared"
  cpus = 1
  memory_mb = 512

[deploy]
  release_command = "/app/bin/migrate"
```

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | PostgreSQL connection string |
| `SECRET_KEY_BASE` | Phoenix secret key |
| `PHX_HOST` | Public hostname |
| `POOL_SIZE` | DB connection pool size |

### Release Configuration

```elixir
# config/runtime.exs
import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "DATABASE_URL not set"

  config :workgroup_pulse, WorkgroupPulse.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    ssl: true

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "SECRET_KEY_BASE not set"

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :workgroup_pulse, WorkgroupPulseWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [port: port],
    secret_key_base: secret_key_base,
    server: true
end
```

### Database Backups

- Fly.io Postgres includes daily automatic backups
- Point-in-time recovery available
- Manual backup before major deployments

---

## Appendix: Six Criteria Workshop Data

### Template Seed Data

```elixir
defmodule WorkgroupPulse.Seeds.SixCriteria do
  alias WorkgroupPulse.Repo
  alias WorkgroupPulse.Workshops.{Template, Question}

  def seed! do
    template = Repo.insert!(%Template{
      id: "six-criteria-v1",
      name: "Six Criteria of Productive Work",
      description: "Based on research by Drs Fred & Merrelyn Emery",
      version: "1.0"
    })

    questions = [
      %{
        number: 1,
        title: "Elbow Room",
        short_title: "Elbow Room",
        scale_type: :balance,
        scale_min: -5,
        scale_max: 5,
        optimal_value: 0,
        explanation: "The ability to make decisions about how you do your work...",
        discussion_prompts: [
          "There's a spread in scores here. What might be behind the different experiences?",
          "What would need to change for scores to improve?"
        ]
      },
      # ... remaining 7 questions
    ]

    for q <- questions do
      Repo.insert!(%Question{template_id: template.id} |> Map.merge(q))
    end
  end
end
```

### Time Allocation Defaults

```elixir
defmodule WorkgroupPulse.Facilitation.TimeAllocations do
  @default_percentages %{
    introduction: 0.05,
    questions_1_4: 0.35,
    mid_transition: 0.02,
    questions_5_8: 0.35,
    summary: 0.08,
    actions: 0.12,
    buffer: 0.03
  }

  def calculate(total_minutes) do
    for {section, pct} <- @default_percentages, into: %{} do
      {section, round(total_minutes * pct)}
    end
  end

  def per_question_minutes(total_minutes) do
    question_time = total_minutes * 0.35  # Each question block
    round(question_time / 4)  # 4 questions per block
  end
end
```

---

*Document Version: 4.0 — Restructured: implementation detail moved to TECHNICAL_SPEC.md, UX moved to docs/ux-design.md and docs/ux-implementation.md*
*Previous versions: v3.x covered LiveView component structure, socket state, and timer implementation inline*
*Last Updated: 2026-02-07*
