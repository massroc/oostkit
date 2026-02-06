# Workgroup Pulse - Solution Design

## Document Info
- **Version:** 3.1
- **Last Updated:** 2026-02-06
- **Status:** Draft

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [SOLID Principles Application](#solid-principles-application)
3. [Phoenix Contexts (Bounded Contexts)](#phoenix-contexts-bounded-contexts)
4. [Domain Models](#domain-models)
5. [Database Schema](#database-schema)
6. [Real-Time Architecture](#real-time-architecture)
7. [LiveView Component Structure](#liveview-component-structure)
8. [State Management](#state-management)
9. [Security Considerations](#security-considerations)
10. [Error Handling Strategy](#error-handling-strategy)
11. [Testing Strategy](#testing-strategy)
12. [Deployment Architecture](#deployment-architecture)

---

## Architecture Overview

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
  @moduledoc """
  The Workshops context provides read-only access to workshop templates,
  questions, and content. Templates are seeded data, not user-created.
  """

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
  @moduledoc """
  The Sessions context manages workshop sessions and participants.
  Handles session creation, joining, state transitions, participant tracking,
  and turn-based scoring progression.
  """

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
  def get_participants_in_turn_order(session_id)  # By join order

  # Turn-based flow management
  def get_current_turn_participant(session_id, question_index)
  def advance_turn(session_id, question_index)  # Move to next participant
  def skip_turn(session_id, question_index)     # Skip current participant
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

**Design Rationale:**
- Same session ID/link preserved - already shared in calendar invites, Slack, etc.
- Simpler mental model: "same workshop = same link"
- All state (scores, notes, current question, timer) persisted
- No need to "export and re-import" or create new sessions

#### 3. Scoring Context

**Purpose:** Handle score submission, validation, locking, and aggregation

```elixir
defmodule WorkgroupPulse.Scoring do
  @moduledoc """
  The Scoring context handles all scoring operations.
  Validates scores, manages score locking (turn-based and row-based),
  calculates aggregations, and determines traffic light colors.

  Key concepts:
  - Scores are visible immediately when placed (no hidden/reveal)
  - A participant can edit their score until they click "Done" (turn locked)
  - All scores in a row are permanently locked when the group advances to the next criterion
  """

  # Score submission
  def submit_score(participant_id, question_index, value)
  def update_score(participant_id, question_index, new_value)  # Only while turn is active
  def lock_participant_turn(participant_id, question_index)     # When "Done" clicked
  def lock_row(session_id, question_index)                      # When group advances

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
  @moduledoc """
  The Facilitation context provides calculation utilities for timer
  and phase management. No DB persistence - the timer runs in-process
  via Process.send_after in TimerHandler.
  """

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

**Note:** There is no Timer schema or DB persistence for timers. The facilitator timer is purely in-process, managed by the `TimerHandler` module using `Process.send_after`.

#### 5. Notes Context

**Purpose:** Capture discussion notes and action items

```elixir
defmodule WorkgroupPulse.Notes do
  @moduledoc """
  The Notes context handles capturing discussion notes and action items.
  """

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

## LiveView Component Structure

### Component Hierarchy

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
│   ├── ScoringComponent      # Virtual Wall grid + score overlay + side panels (actions in notes side-sheet)
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

### Phase Components (Functional Components)

The scoring phase has been redesigned as the **Virtual Wall** — a full-screen three-panel layout:

#### ScoringComponent
**File:** `lib/workgroup_pulse_web/live/session_live/components/scoring_component.ex`

**Purpose:** Renders the entire scoring phase UI including the full 8-question grid, floating score overlay, left question info panel, and right notes side-sheet. Pure functional component — all events bubble to the parent LiveView.

**Layout:**
- **Main Sheet (centre)** — `render_full_scoring_grid/1` renders all 8 questions as a `<table>` with participant columns. Questions are grouped by scale type (Balance, Maximal) with section labels.
- **Left Panel** — Question title, explanation, and expandable facilitator tips ("More tips" toggle).
- **Right Panel (Side-sheet)** — Notes with focus-based expand/collapse. Shows preview (2 notes max) when unfocused, full list + add form when focused.
- **Score Overlay** — `render_score_overlay/1` shows a floating modal with score buttons. Auto-submits on selection. Only visible when `is_my_turn and not my_turn_locked and show_score_overlay`.

**Key Render Functions:**
- `render_full_scoring_grid/1` — Builds the complete 8-question × N-participant grid
- `render_question_row/2` — Renders a single question row with per-participant score cells
- `render_score_cell_value/3` — Pattern-matched function for cell display states (future `—`, past `?`, current `...`, scored value)
- `render_score_overlay/1` — Floating score input modal
- `render_balance_scale/1` / `render_maximal_scale/1` — Score button grids for each scale type
- `render_mid_transition/1` — Scale change explanation screen (shown before Q5)

**Actions in Scoring Phase:**
Actions are managed during the scoring phase via the notes side-sheet (below notes). The ActionFormComponent (LiveComponent) provides local form state for action creation without triggering parent re-renders. The completed/wrap-up page shows action count for export purposes but does not have inline action management.

**All other phase components** follow the same pure functional pattern:
- `SummaryComponent` — Paper-textured sheet with individual score grids, team combined values, traffic lights, and notes
- `CompletedComponent` — Wrap-up page with score overview, strengths/concerns, action count, and export
- `LobbyComponent` — Waiting room with participant list and start button
- `IntroComponent` — 4-screen introduction with navigation

### Extracted Handler Modules

The following handler modules have been extracted from SessionLive.Show to improve maintainability and separation of concerns:

#### EventHandlers
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

#### MessageHandlers
**File:** `lib/workgroup_pulse_web/live/session_live/handlers/message_handlers.ex`

**Purpose:** All `handle_info` callbacks for PubSub events. Handles real-time updates from other participants.

**Key Events Handled:**
- `:participant_joined`, `:participant_left`, `:participant_updated`, `:participant_ready`
- `:session_started`, `:session_updated`
- `:score_submitted` — Reloads score data for the affected question
- `:turn_advanced`, `:row_locked`
- `:note_updated`, `:action_updated`
- `:participants_ready_reset`

#### DataLoaders
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

#### TimerHandler
**File:** `lib/workgroup_pulse_web/live/session_live/timer_handler.ex`

**Purpose:** Manages facilitator countdown timer during workshop phases. Extracted to centralize all timer logic.

**Functions:**
- `init_timer_assigns/1` - Initialize timer-related socket assigns
- `maybe_start_timer/1` - Conditionally start timer for facilitators
- `start_phase_timer/2` - Start timer for current phase
- `cancel_timer/1` - Cancel active timer
- `handle_timer_tick/1` - Process timer tick (returns `{:noreply, socket}`)
- `maybe_restart_timer_on_transition/3` - Restart on phase change
- `stop_timer/1` - Stop and disable timer

#### OperationHelpers
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

#### ActionFormComponent
**File:** `lib/workgroup_pulse_web/live/session_live/action_form_component.ex`

**Purpose:** Manages action creation form with local state. Form input changes don't trigger parent re-renders.

**Local State:**
- `action_description` - Action description input
- `action_owner` - Action owner input
- `action_question` - Selected related question

**Communication:** Notifies parent via `send(self(), :reload_actions)` after successful action creation.

### Score Input Design

Score input uses **button grids inside a floating overlay**, not sliders. Each score value is a separate button that auto-submits on click via `phx-click="select_score"`.

**Balance Scale (-5 to +5):** 11 buttons in a row. The `0` button has special styling (green border) to indicate it's optimal. Selected button gets green background.

**Maximal Scale (0 to 10):** 11 buttons in a row. Selected button gets purple background.

Both scales show contextual labels ("Too little / Just right / Too much" for balance, "Low / High" for maximal).

### Design System Components (CoreComponents)

Shared components in `lib/workgroup_pulse_web/components/core_components.ex`:

```elixir
# App header with gradient accent stripe
<.app_header session_name="Six Criteria Assessment" />

# Sheet - core UI primitive (paper-textured surface)
<.sheet class="shadow-sheet p-6 max-w-2xl w-full">
  <h1>Content</h1>
</.sheet>

# Facilitator timer (top-right, facilitator-only)
<.facilitator_timer
  remaining_seconds={540}
  total_seconds={600}
  phase_name="Question 3"
  warning_threshold={60}
/>
```

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

### Performance Optimizations

The following optimizations have been implemented to ensure responsive UI:

#### 1. Input Debouncing
All text input fields use `phx-debounce="300"` to reduce server round-trips during typing:
- Note input field
- Action description input
- Action owner input

This reduces WebSocket messages by ~80-90% during typing.

#### 2. Optimized Data Loading
The `load_scores/3` function uses participant data from socket assigns rather than querying the database on every score submission. Participant lists are kept in sync via PubSub handlers, eliminating redundant database queries.

#### 3. LiveComponent Extraction
Frequently updated sections have been extracted into LiveComponents to isolate re-renders:
- **ActionFormComponent** - Manages local form state for action creation (typing doesn't trigger parent re-renders)

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

### Navigation Rules

**Back Button Availability:**
| Screen | Facilitator | Participants |
|--------|-------------|--------------|
| Question phase (Q1) | Hidden (can't go further back) | Hidden |
| Question phase (Q2+) | Back to previous question | Hidden |
| Summary screen | Back to last question | Hidden |
| Wrap-up screen | Back to summary | Hidden |

**Navigation Constraints:**
- Back button cannot navigate earlier than Q1 (no return to intro from scoring)
- Only facilitator can navigate - participants follow the session state
- Going back resets participants' ready state for the current question

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

### LiveView State Structure

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
     |> assign(intro_step: 1)
     |> assign(show_mid_transition: false)
     |> assign(show_facilitator_tips: false)
     |> assign(active_sheet: :main)               # Focus system: :main or :notes
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
  def render(assigns) do
    # case @session.state do
    #   "lobby"     -> LobbyComponent.render(...)
    #   "intro"     -> IntroComponent.render(...)
    #   "scoring"   -> ScoringComponent.render(...)
    #   "summary"   -> SummaryComponent.render(...)
    #   "completed" -> CompletedComponent.render(...)
    # end
    #
    # Plus: facilitator timer, sheet strip, floating action buttons
  end
end
```

**Key Design Decisions:**
- `show.ex` is a thin dispatcher — all logic lives in handler/helper modules
- DataLoaders hydrate socket assigns in bulk, avoiding piecemeal loading
- Template caching (`get_or_load_template/2`) avoids repeated DB queries
- Floating action buttons are rendered directly in `show.ex` (not in ScoringComponent) to keep the component pure

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

### Segment-Based Timer Implementation

The facilitator timer divides the total session time into 10 equal segments:

| Segment | Purpose |
|---------|---------|
| 1-8 | One segment per question (8 questions) |
| 9 | Summary + Actions (combined) |
| 10 | Unallocated flex/buffer time |

**Timer Behavior:**
- Timer is **facilitator-only** - participants don't see the timer
- Timer **auto-starts** when entering a timed phase (scoring, summary)
- Timer displays in **top-right corner** with fixed positioning
- Timer shows **warning state** (red) at 10% remaining time
- Timer **stops** when entering wrap-up (completed) state

**Implementation Details:**

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

**Client-Side Timer Hook:**
- JavaScript hook (`FacilitatorTimer`) provides smooth 1-second countdown
- Server syncs remaining time; client handles display updates
- Handles warning state class toggling for visual feedback
- Re-syncs on server updates to prevent drift

**Timer Visibility Rules:**
| State | Timer Visible (Facilitator) |
|-------|----------------------------|
| lobby | No |
| intro | No |
| scoring | Yes (phase: Question N) |
| summary | Yes (phase: Summary) |
| completed | No (wrap-up page - actions created here) |

Note: The "actions" state still exists for backwards compatibility but the
default UI flow now skips it, going directly from "summary" to "completed".

---

*Document Version: 3.1*
*v2.0 - Refactored to turn-based sequential scoring (butcher paper model)*
*v2.1 - Added extracted handler modules (TimerHandler, OperationHelpers)*
*v2.2 - Removed turn timeout (facilitator can manually skip inactive participants)*
*v2.3 - Added navigation rules and readiness behavior documentation*
*v3.0 - Updated for Virtual Wall redesign: new component hierarchy, DataLoaders, EventHandlers/MessageHandlers split, ScoringComponent with full grid, score overlay, and three-panel layout*
*v3.1 - Removed Timer schema/DB persistence (timer is purely in-process), removed ScoreResultsComponent and ActionsComponent, moved actions to scoring side-sheet, updated Workshops to read-only API, removed non-existent behaviours from SOLID examples, updated state machine to reflect lobby-intro-scoring-summary-completed flow*
*Last Updated: 2026-02-06*
