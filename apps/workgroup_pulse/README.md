# Productive Work Groups

A self-guided team collaboration web application that guides teams through the "Six Criteria of Productive Work" workshop without requiring a trained facilitator.

Built with Elixir/Phoenix LiveView and PostgreSQL, deployed on Fly.io.

## Tech Stack

- **Backend**: Elixir 1.17 / Phoenix 1.7 with LiveView
- **Database**: PostgreSQL 16
- **Frontend**: Phoenix LiveView + Tailwind CSS
- **Deployment**: Fly.io (Sydney region)
- **CI/CD**: GitHub Actions

## Development Setup

### Prerequisites

- Docker and Docker Compose

### Quick Start

```bash
# Start development server (Phoenix + PostgreSQL)
docker compose up

# Access the app at http://localhost:4000
```

### Development Commands

```bash
# Start development environment
docker compose up

# Run tests
docker compose --profile test run --rm wp_test

# TDD mode (watches for file changes)
docker compose --profile tdd run --rm wp_test_watch

# Open IEx shell
docker compose exec wp_app iex -S mix

# Run database migrations
docker compose exec wp_app mix ecto.migrate

# Reset database
docker compose exec wp_app mix ecto.reset

# Run code quality checks (format, credo, sobelow, dialyzer)
docker compose exec wp_app mix quality
```

Alternatively, use the helper script:

```bash
chmod +x scripts/dev.sh
./scripts/dev.sh start   # Start dev server
./scripts/dev.sh tdd     # TDD mode
./scripts/dev.sh test    # Run tests
./scripts/dev.sh shell   # IEx shell
```

## Testing (TDD)

The project is configured for Test-Driven Development:

1. **Start TDD mode**: `docker compose --profile tdd run --rm wp_test_watch`
2. **Write a failing test** in `test/`
3. **Implement code** in `lib/`
4. **Tests auto-run** on file changes
5. Press Enter to re-run all tests

### Test Libraries

- **ExUnit** - Unit testing
- **ExMachina** - Test data factories
- **Mox** - Mocking
- **Wallaby** - Browser/E2E testing
- **ExCoveralls** - Code coverage

## CI/CD Pipeline

GitHub Actions runs on every push and pull request:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Test      │     │  Dialyzer   │     │   Deploy    │
│             │     │             │     │  (main only)│
│ • Format    │     │ • Type      │     │             │
│ • Credo     │────▶│   checking  │────▶│ • Fly.io    │
│ • Sobelow   │     │             │     │   deploy    │
│ • Tests     │     │             │     │             │
│ • Coverage  │     │             │     │             │
└─────────────┘     └─────────────┘     └─────────────┘
```

### Pipeline Stages

1. **Test Job**
   - Code formatting check
   - Credo static analysis
   - Sobelow security scan
   - ExUnit tests with PostgreSQL
   - Coverage report to Codecov

2. **Dialyzer Job**
   - Static type analysis
   - PLT caching for faster runs

3. **Deploy Job** (main branch only)
   - Automatic deployment to Fly.io

## Production Deployment

### Fly.io Resources

| Resource | Name | Region |
|----------|------|--------|
| App | `workgroup-pulse` | Sydney (syd) |
| Database | `workgroup-pulse-db` | Sydney (syd) |
| URL | https://workgroup-pulse.fly.dev | |

### Manual Deployment

```bash
# Deploy to Fly.io
flyctl deploy

# View logs
flyctl logs

# Open production console
flyctl ssh console

# Check app status
flyctl status
```

### Environment Variables

Set via Fly.io secrets:

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string (auto-set) |
| `SECRET_KEY_BASE` | Phoenix secret key |
| `PHX_HOST` | Production hostname |

## Project Structure

```
├── lib/
│   ├── workgroup_pulse/              # Business logic (contexts)
│   │   ├── sessions/                 # Session & participant management
│   │   ├── scoring.ex                # Score submission, validation, aggregation
│   │   ├── notes.ex                  # Notes & action items
│   │   ├── workshops/                # Workshop templates & questions
│   │   ├── facilitation.ex            # Calculation utilities
│   │   ├── export.ex                 # Export functionality
│   │   └── repo.ex
│   └── workgroup_pulse_web/          # Web layer
│       ├── components/
│       │   ├── core_components.ex    # Shared: app_header, sheet_strip, timer, etc.
│       │   └── layouts.ex
│       ├── live/session_live/
│       │   ├── show.ex               # Root LiveView (thin dispatcher)
│       │   ├── new.ex                # Create session
│       │   ├── join.ex               # Join session
│       │   ├── components/
│       │   │   ├── scoring_component.ex    # Virtual Wall grid + overlay
│       │   │   ├── summary_component.ex    # Score summary view
│       │   │   ├── completed_component.ex  # Wrap-up/export
│       │   │   ├── intro_component.ex      # Introduction screens
│       │   │   ├── lobby_component.ex      # Waiting room
│       │   │   ├── export_modal_component.ex  # Report type + format selection
│       │   │   └── export_print_component.ex # Print-optimized HTML for PDF
│       │   ├── handlers/
│       │   │   ├── event_handlers.ex       # All handle_event callbacks
│       │   │   └── message_handlers.ex     # All handle_info (PubSub)
│       │   ├── helpers/
│       │   │   ├── data_loaders.ex         # Data loading & state hydration
│       │   │   ├── state_helpers.ex        # State transition helpers
│       │   │   ├── operation_helpers.ex    # Standardised error handling
│       │   │   └── score_helpers.ex        # Score color/formatting
│       │   ├── timer_handler.ex            # Facilitator timer logic
│       │   └── action_form_component.ex    # LiveComponent for action form
│       ├── endpoint.ex
│       ├── router.ex
│       └── telemetry.ex
├── test/
│   ├── support/                      # Test helpers & factories
│   └── workgroup_pulse_web/          # Web tests
├── priv/
│   ├── repo/migrations/              # Database migrations
│   └── static/                       # Static assets
├── assets/                           # Frontend (JS, CSS)
├── config/                           # Environment configs
├── docker-compose.yml                # Development environment
├── Dockerfile                        # Production build
├── Dockerfile.dev                    # Development build
└── fly.toml                          # Fly.io configuration
```

## Current Build Status

### Completed

- [x] Session creation with shareable link (copy to clipboard)
- [x] Join session via link (name entry)
- [x] Waiting room / lobby with participant list
- [x] Facilitator role with participation mode (team member or observer)
- [x] Facilitator "Start Workshop" button
- [x] Introduction phase (4 screens with navigation)
- [x] Real-time participant sync via PubSub
- [x] Database seeding for Six Criteria template
- [x] Error handling for missing template
- [x] PostHog analytics integration

#### Scoring Phase (Complete — Virtual Wall Design)
- [x] Full 8-question grid displayed at all times (Virtual Wall)
- [x] Three-panel layout: left (question info), centre (grid), right (notes side-sheet)
- [x] Scoring input (buttons) for balance scale (-5 to +5) and maximal scale (0 to 10)
- [x] Floating score overlay — auto-submits on selection
- [x] Click-to-edit: reopen overlay to change score during your turn
- [x] Scores visible immediately in grid (butcher paper principle — no hidden state)
- [x] Turn-based sequential scoring with highlighted active row and column
- [x] Traffic light color coding (green/amber/red)
- [x] Combined team value calculation
- [x] Facilitator tips on left panel (expandable via "More tips" button)
- [x] Notes side-sheet with focus-based expand/collapse, real-time sync, and action item management
- [x] "Done" button to pass turn, floating action buttons (bottom-right)
- [x] "I'm Ready" button for non-facilitator participants to signal readiness
- [x] Facilitator "Skip Turn" button
- [x] Facilitator "Next Question" / "Continue to Summary" navigation
- [x] Facilitator "Back" navigation (after Q1)
- [x] Mid-workshop transition screen (before question 5)
- [x] Reusable `<.sheet>` component for all phase screens

#### Summary Phase (Complete)
- [x] Overview of all 8 questions with individual scores per participant
- [x] Traffic light indicators for each criterion
- [x] Combined team values (out of 10)
- [x] Pattern highlighting (strengths vs concerns)
- [x] Notes displayed from scoring phase (only if notes were taken)

#### Completed Phase (Complete)
- [x] Final summary with score overview and strengths/concerns
- [x] Actions list
- [x] Export modal UI (report type + format selection)
- [x] Export: Full Workshop Report & Team Report (anonymized) in CSV and PDF formats
- [x] Client-side PDF generation via html2pdf.js (html2canvas + jsPDF)

#### Performance Optimizations (Complete)
- [x] Input debouncing (300ms) on text fields to reduce server round-trips
- [x] Template caching in DataLoaders (avoids repeated DB queries)
- [x] Optimized score loading using cached participant data
- [x] Extracted handler modules (EventHandlers, MessageHandlers, DataLoaders)
- [x] Extracted ActionFormComponent for local form state management

### Outstanding Work

#### Timer System
- [x] Optional timer setup at session creation (No timer, 2hr, 3.5hr, Custom)
- [x] Countdown timer display per section (facilitator-only, top-right)
- [x] Warning state at 10% remaining
- [x] Timer auto-starts on phase entry, restarts on question advance
- [ ] Pacing indicator (on track/behind)
- [ ] Pause/resume controls

#### Additional Features
- [ ] Facilitator Assistance button (contextual help beyond tips)
- [ ] Feedback button
- [ ] Participant dropout handling (greyed out visual)
- [x] Observer mode (facilitator can observe without scoring)

## Documentation

- [REQUIREMENTS.md](REQUIREMENTS.md) — Functional requirements (what the product does)
- [SOLUTION_DESIGN.md](SOLUTION_DESIGN.md) — Architecture & design decisions (why + how, high-level)
- [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md) — Implementation specification (components, handlers, state)
- [docs/ux-design.md](docs/ux-design.md) — UX design specification (visual design, principles, accessibility)
- [docs/ux-implementation.md](docs/ux-implementation.md) — UX implementation detail (CSS, JS hooks, carousel, sheets)

## License

Private - All rights reserved.
