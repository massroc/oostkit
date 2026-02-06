# Pulse App UX Redesign Prep

This document provides context for the upcoming UX redesign.

---

## 1. Component Structure

### Main LiveView
```
SessionLive.Show (show.ex)
├── Renders based on session.state
├── Handles all events (delegated to EventHandlers)
├── Handles all PubSub messages (delegated to MessageHandlers)
└── Uses helpers: DataLoaders, StateHelpers, OperationHelpers, TimerHandler
```

### Session States → Components
| State | Component | Purpose |
|-------|-----------|---------|
| `lobby` | LobbyComponent | Waiting room, share link, participant list |
| `intro` | IntroComponent | 4-step introduction (welcome, how it works, scales, safe space) |
| `scoring` | ScoringComponent | Main scoring flow (question card, score grid, input) |
| `summary` | SummaryComponent | Review all scores before actions |
| `actions` | ActionsComponent | Create action items (deprecated - merged into completed) |
| `completed` | CompletedComponent | Final wrap-up, export, action items |

### Nested Components
```
ScoringComponent
└── ScoreResultsComponent (LiveComponent)
    └── Shows revealed scores, notes, ready controls

ActionsComponent / CompletedComponent
└── ActionFormComponent (LiveComponent)
    └── Form for creating actions (isolates re-renders)

CompletedComponent
└── ExportModalComponent
    └── Export options modal
```

### Shared Helpers
| File | Purpose |
|------|---------|
| `score_helpers.ex` | Traffic light colors, CSS classes for scores |
| `data_loaders.ex` | Load scoring/summary/actions data into assigns |
| `state_helpers.ex` | Derive UI state from session data |
| `operation_helpers.ex` | Business logic operations |

### Core Components (core_components.ex)
- `flash/flash_group` - Toast notifications
- `simple_form` - Form wrapper
- `button` - Basic button (not widely used, custom buttons inline)
- `input` - Form inputs
- `modal` - Dark-themed modal
- `icon` - Heroicons
- `facilitator_timer` - Countdown timer (facilitator only)

---

## 2. Hardcoded Styles vs Design Tokens

### Design System Tokens Available (from tailwind.preset.js)
```
Colors:
- bg-surface-wall (#F5F5F4)     - bg-surface-sheet (#FEFDFB)
- bg-surface-sheet-alt          - bg-surface-card
- text-text-dark (#151515)      - text-text-body (#A3A3A3)
- bg-accent-purple (#7245F4)    - bg-highlight (#BC45F4)
- text-accent-gold              - text-accent-red
- bg-df-green (#42D235)         - bg-df-blue
- text-traffic-green/amber/red  - bg-interactive

Typography:
- font-brand (Inter)            - font-workshop (Caveat)
- text-score-lg/md/sm

Spacing:
- p-sheet-padding (24px)        - gap-section-gap (32px)
- gap-strip-gap (8px)

Shadows:
- shadow-sheet                  - shadow-sheet-receded
- shadow-side-sheet

Border radius:
- rounded-sheet

Z-index:
- z-wall, z-sheet-previous, z-sheet-current, z-sheet-strip, z-side-sheet, z-modal
```

### Hardcoded Styles Found (Should Use Tokens)

#### Colors - Replace with design tokens
| Hardcoded | Should Be | Location |
|-----------|-----------|----------|
| `bg-gray-100` | `bg-surface-wall` or new token | Multiple components |
| `bg-gray-200` | Design token | Score buttons (scoring_component) |
| `bg-gray-300` | Design token | Intro dots |
| `bg-gray-600` | Design token | Disabled buttons, hover states |
| `border-gray-600` | Design token | Input borders |
| `border-gray-700` | Design token | Notes section border |
| `text-gray-400` | `text-text-body` | Timer, placeholders |
| `text-gray-500` | `text-text-body` | Secondary text throughout |
| `text-gray-600` | Design token | Pending scores |
| `bg-blue-900/30` | New token for "current turn" | Score grid |
| `border-blue-500` | New token for "current turn" | Score grid |
| `text-blue-400` | New token | Current turn indicator |
| `text-purple-400` | `text-accent-purple` | Facilitator tips |
| `bg-purple-600` | `bg-accent-purple` | Facilitator badge |
| `bg-green-100` | Already uses green-100 | Score backgrounds |
| `bg-green-50` | Already defined | Strengths section |
| `bg-red-50` | Already defined | Concerns section |

#### Typography - Missing design tokens
| Issue | Location |
|-------|----------|
| No `font-workshop` usage | Scores should use handwritten font |
| No `text-score-*` usage | Score displays use inline sizes |

#### Spacing - Generally good
Most components use Tailwind defaults which align with 4px grid.

#### Shadows - Partially used
| Used | Not Used |
|------|----------|
| `shadow-sheet` in lobby, intro | Missing in scoring, summary cards |
| | `shadow-sheet-receded` not used |
| | `shadow-side-sheet` not used |

### New Tokens Needed
```js
// For current turn highlighting
'turn-current': '#...',
'turn-current-bg': '#...',

// For input/form elements
'input-bg': '#...',
'input-border': '#...',
'input-border-focus': '#...',

// For disabled states
'disabled-bg': '#...',
'disabled-text': '#...',
```

---

## 3. UI States - Scoring Flow

The scoring flow has the most complex state combinations. Your mockups should account for all of these.

### By Role

#### Participant (Regular)
| State | What's Shown |
|-------|--------------|
| **Waiting for turn** | "Waiting for [Name] to score" |
| **My turn - not scored** | Score input buttons, "Your turn to score" |
| **My turn - scored** | Score input (can change), "Discuss your score", Share/Done buttons |
| **Turn complete** | Greyed out, waiting for others |
| **All scored, not revealed** | Score grid with hidden values |
| **Scores revealed** | Results with all scores visible |
| **Ready to continue** | "I'm Ready to Continue" button |
| **Marked ready** | Checkmark, "Waiting for facilitator..." |
| **Was skipped** | "You were skipped" - auto-ready, greyed out |

#### Facilitator (Additional states)
| State | What's Shown |
|-------|--------------|
| All above PLUS... | |
| **During scoring** | Skip button for current turn |
| **After reveal** | Back button, Next Question button |
| **Next disabled** | "Waiting for all scores..." |
| **Next enabled** | "All participants ready" |
| **Timer visible** | Countdown in top-right corner |
| **Timer warning** | Red timer when low |

#### Observer
| State | What's Shown |
|-------|--------------|
| **Always** | "Observer Mode" - can see everything, cannot score |
| **During scoring** | Shows who is currently scoring |

### Score Grid States (per participant box)
| State | Appearance |
|-------|------------|
| `scored` | Colored background (green/amber/red), value visible |
| `current` | Blue pulsing border, "..." as value |
| `skipped` | Gray, "?" as value |
| `pending` | Muted, "—" as value |

### Scale Types
| Type | Range | Optimal | Colors |
|------|-------|---------|--------|
| `balance` | -5 to +5 | 0 | Green at 0, red at extremes |
| `maximal` | 0 to 10 | 10 | Green high, red low |

### Mid-Workshop Transition
Between question 4 and 5, there's a transition screen explaining the scale change from balance to maximal.

### Question Card States
| State | What's Shown |
|-------|--------------|
| **Default** | Question title, explanation, criterion name |
| **With tips collapsed** | "More tips" link |
| **With tips expanded** | Discussion prompts list, "Hide tips" |

### Notes Panel States
| State | What's Shown |
|-------|--------------|
| **Collapsed** | "Add Notes" button (with count badge if notes exist) |
| **Expanded** | List of notes, add note form |

---

## 4. Component Communication

```
User Action
    ↓
show.ex handle_event (delegates to EventHandlers)
    ↓
Business Logic (Sessions context)
    ↓
PubSub broadcast
    ↓
show.ex handle_info (delegates to MessageHandlers)
    ↓
Assigns updated → Re-render
```

All events flow through the parent LiveView. Child components are pure functional components (except ActionFormComponent and ScoreResultsComponent which are LiveComponents for render isolation).

---

## 5. Files to Modify for Redesign

### Primary (Template Changes)
- `components/scoring_component.ex` - Main scoring UI
- `score_results_component.ex` - Results display
- `components/lobby_component.ex` - Waiting room
- `components/intro_component.ex` - Introduction screens
- `components/summary_component.ex` - Score review
- `components/completed_component.ex` - Wrap-up
- `show.ex` - Container and facilitator timer

### Secondary (Token Updates)
- `/shared/tailwind.preset.js` - Add new tokens
- `score_helpers.ex` - Update CSS class mappings

### Optional (Core Components)
- `core_components.ex` - If adding new shared components

---

## 6. Analytics (PostHog)

PostHog is now integrated. To enable:

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

### Custom Event Tracking (Optional)
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

### Files Changed
- `config/runtime.exs` - PostHog configuration
- `lib/workgroup_pulse_web/analytics.ex` - Helper module
- `lib/workgroup_pulse_web/components/layouts/root.html.heex` - Script injection
- `assets/js/app.js` - PostHogTracker hook
- `lib/workgroup_pulse_web/live/session_live/show.ex` - Hook attachment

---

## 7. Questions for Design (RESOLVED)

All questions below have been resolved through the mockup session. See Section 8 for decisions.

1. ~~**Sheet metaphor scope**~~ → Main sheet + side-sheet (Notes), z-index layering
2. ~~**Mobile**~~ → TBD (desktop-first for facilitator view)
3. ~~**Score input**~~ → Grid-based, current turn highlighted
4. ~~**Participant grid**~~ → Table with participant columns, criterion rows
5. ~~**Progress**~~ → Sheet Strip at bottom showing sheet navigation
6. ~~**Notes**~~ → Side-sheet behind main, click to swap focus
7. ~~**Facilitator chrome**~~ → Header bar, floating buttons bottom-right

---

## 8. Design Decisions (Resolved)

**Reference Mockup**: `/apps/workgroup_pulse/docs/mockups/facilitator-scoring-v8.html`

### Layout Architecture

| Element | Height | Position | z-index |
|---------|--------|----------|---------|
| Header bar | 52px | Top, fixed | 10 |
| Main sheet | 580px | Centred | 2 (front) |
| Side-sheet (Notes) | 480px | Right, offset | 1 (behind) |
| Floating buttons | Auto | Bottom-right, 60px up | 20 |
| Sheet strip | 44px | Bottom, fixed | 10 |

### Sheet Dimensions

**Reference**: Post-it Easel Pad (635mm × 775mm) = **0.819 aspect ratio** (W:H)

All sheets use this ratio:
- Main sheet: 580px height × ~595px width (+ content padding)
- Side-sheet: 480px height × ~393px width
- Strip thumbnails: 34px height × ~28px width

Sheets have subtle rotation for organic feel:
- Main: `rotate(-0.2deg)`
- Notes: `rotate(1.2deg)`

### Single-Sheet Scoring Grid

**Decision**: Display ALL 8 questions on a single sheet simultaneously.

**Grid Structure**:
- Table with `border-collapse: separate`
- Sticky header row for scrolling
- Criterion column: 160px width, left-aligned
- Participant columns: auto width, min 52px, centre-aligned

**Row Labels** (Caveat font, 17px, UPPERCASE):
```
ELBOW ROOM
[parent: CONTINUAL LEARNING] SETTING GOALS
[parent: CONTINUAL LEARNING] GETTING FEEDBACK
VARIETY
MUTUAL SUPPORT & RESPECT
[parent: MEANINGFULNESS] SOCIALLY USEFUL
[parent: MEANINGFULNESS] SEE WHOLE PRODUCT
DESIRABLE FUTURE
```

Parent labels shown at 11px, 50% opacity above the criterion name.

### Active State Indicators

**Key Decision**: No text badges or triangles. Active states indicated purely through colour and borders.

| State | Treatment |
|-------|-----------|
| Active row | 3px purple left border (inset box-shadow) + purple-light background |
| Active column | 3px purple bar at top of header (70% width, centred) + subtle tint on cells |
| Active cell | Stronger purple background at row/column intersection |

### Side-Sheet Behaviour

**Decision**: Sheets swap focus (not overlay drawer).

- Notes sheet sits behind main sheet, partially visible on right
- Click Notes → main sheet recedes left, Notes expands to main position
- Click to swap back
- Both sheets remain visible, just repositioned

### Buttons

**Floating buttons** (bottom-right, 60px from bottom, 20px from right):

| Button | Style | Visibility |
|--------|-------|------------|
| Skip Turn | Secondary (white, border) | Facilitator only |
| Continue | Secondary (white, border) | Facilitator only |
| Submit | Primary (purple→magenta gradient) | Active participant only |

**Styling**:
- Font: DM Sans, 13px, weight 600
- Padding: 9px 18px
- Border-radius: 8px
- Hover: translateY(-1px) + enhanced shadow

### Sheet Strip

- Shows thumbnail previews of all sheets
- Maintains 0.819 aspect ratio
- Active sheet: purple border + gold dot (6px)
- Secondary sheets: gray background + magenta dot (4px, 60% opacity)
- Faux "lines" texture inside thumbnails

### Chrome Accents

Gradient stripes add brand colour to chrome:
- Header bottom-left: Magenta → Purple (200px wide, 3px tall)
- Strip top-right: Gold → Magenta (150px wide, 3px tall)

---

## 9. Implementation Checklist

- [ ] Add Google Fonts: DM Sans + Caveat to root layout
- [ ] Update Tailwind preset with new tokens (DONE - see `/shared/tailwind.preset.js`)
- [ ] Extract paper texture CSS to reusable component/class
- [ ] Build sheet component with aspect ratio + rotation
- [ ] Build scoring grid table with sticky headers
- [ ] Implement active row/column highlighting
- [ ] Build side-sheet component with z-index layering
- [ ] Build sheet strip with thumbnail generation
- [ ] Add gradient accent stripes to header/strip
- [ ] Create floating button container component
- [ ] Wire up sheet focus swap (main ↔ notes)
- [ ] Test scroll behaviour within main sheet
- [ ] Implement responsive fallbacks for mobile

---

## 10. Animation Notes (for LiveView)

### Recommended Approach
- CSS transforms + `phx-hook` for basic transitions
- FLIP technique for sheet position swaps
- Avoid 60fps drag — LiveView round-trips make this impractical
- "Click to swap sheets" is the target interaction model

### Transition Properties
```css
transition: transform 0.3s ease, box-shadow 0.3s ease;
```

---

## Related Documents

- **Mockup**: `/apps/workgroup_pulse/docs/mockups/facilitator-scoring-v8.html`
- **Design System**: `/docs/design-system.md`
- **Tailwind Preset**: `/shared/tailwind.preset.js`
- **Canva Prompts**: `/docs/design-prompts-canva.md` (prompt #10)
