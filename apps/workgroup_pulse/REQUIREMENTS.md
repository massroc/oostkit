# Productive Work Groups

## Requirements Document

## Overview

A **self-guided** team collaboration web application for conducting Open Systems Theory's "Six Criteria of Productive Work" workshop. The app acts as the facilitator - guiding teams through the process without requiring an experienced external facilitator.

Team members enter their individual scores for each criterion and then discuss the results together to surface obstacles to performance and engagement.

### Key Value Proposition
- **Removes the need for a trained facilitator** - the app guides the workshop flow
- **Self-serve for teams** - any team can run this workshop independently
- Provides context, explanations, and discussion prompts at each step

**Related documents:**
- [SOLUTION_DESIGN.md](SOLUTION_DESIGN.md) — Architecture, tech stack, design for reuse
- [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md) — LiveView components, handlers, state management
- [docs/ux-design.md](docs/ux-design.md) — UX design principles, visual design, accessibility
- [docs/ux-implementation.md](docs/ux-implementation.md) — CSS systems, JS hooks, sheet dimensions

## Domain Background

Based on research by Drs Fred & Merrelyn Emery, the six intrinsic motivators that determine employee engagement are grouped into two categories:

### Criteria 1-3: Personal Optimization (require balance)
1. **Elbow Room** - Autonomy in making decisions about work methods and timing
2. **Continual Learning** - Two sub-components:
   - 2a. *Setting Goals* - Ability to set your own goals
   - 2b. *Getting Feedback* - Receiving timely, useful feedback
3. **Variety** - Balanced workload avoiding excessive routine or overwhelming demands

### Criteria 4-6: Workplace Climate (maximal - more is better)
4. **Mutual Support and Respect** - Cooperative culture where colleagues help each other
5. **Meaningfulness** - Two sub-components:
   - 5a. *Socially Useful* - Work that contributes value to society
   - 5b. *See Whole Product* - Understanding the complete product/service you contribute to
6. **Desirable Future** - Skill development and career progression opportunities

### Summary: 6 Criteria, 8 Scored Questions
| Criterion # | Question | Parent Criterion | Scale |
|-------------|----------|------------------|-------|
| 1 | Elbow Room | Elbow Room | -5 to +5 |
| 2a | Setting Goals | Continual Learning | -5 to +5 |
| 2b | Getting Feedback | Continual Learning | -5 to +5 |
| 3 | Variety | Variety | -5 to +5 |
| 4 | Mutual Support and Respect | Mutual Support | 0 to 10 |
| 5a | Socially Useful | Meaningfulness | 0 to 10 |
| 5b | See Whole Product | Meaningfulness | 0 to 10 |
| 6 | Desirable Future | Desirable Future | 0 to 10 |

## Scoring System

### Questions 1-4: Balance Scale (from Criteria 1-3)
- **Range**: -5 to +5
- **Optimal**: 0 (balanced)
- **Interpretation**: Negative values indicate too little, positive values indicate too much

| Criterion # | Question | -5 | 0 | +5 |
|-------------|----------|-----|-----|-----|
| 1 | Elbow Room | Too constrained | Just right | Too much autonomy |
| 2a | Setting Goals | No ability to set goals | Balanced | Overwhelmed by goal-setting |
| 2b | Getting Feedback | No feedback | Right amount | Excessive feedback |
| 3 | Variety | Too routine | Good mix | Too chaotic |

### Questions 5-8: Maximal Scale (from Criteria 4-6)
- **Range**: 0 to 10
- **Optimal**: 10 (more is better)

| Criterion # | Question | 0 | 10 |
|-------------|----------|-----|-----|
| 4 | Mutual Support and Respect | No support | Excellent support |
| 5a | Socially Useful | Work feels pointless | Highly valuable to society |
| 5b | See Whole Product | No visibility of outcome | Clear view of full product |
| 6 | Desirable Future | Dead-end | Great growth path |

## Workshop Flow

### Design Philosophy: The Butcher Paper Principle

The tool behaves like butcher paper on a wall: **visible, permanent within each phase, sequential, shared, and simple**.

- One person at a time goes up to place their score, visibly
- The group discusses while seeing what's been placed
- The conversation happens *during* scoring, not after a reveal
- The tool creates conditions for discussion; it doesn't make people discuss

### 1. Session Setup
- Facilitator starts a new session and sends links to participants
- Shareable link generated for team members to join
- Waiting room shows who has joined (join order determines scoring order)

### 2. Introduction & Scoring Phase

After the facilitator starts the session, all participants see intro slides (skippable). Each participant navigates to the scoring sheet independently — there is no facilitator-gated transition.

**Introduction Slides (self-paced):**
- **Guided overview** of the Six Criteria framework
- Explanation of how the workshop works
- What to expect from the process
- Each participant clicks through or skips to scoring at their own pace

**Scoring (repeated for each criterion):**

**Unified Workshop Carousel:**

All phases (except lobby) share a single **unified carousel** — a click-only horizontal layout powered by Embla Carousel. The active sheet is centred and prominent; adjacent sheets peek from behind at the same fixed size but dimmed (30% opacity), clickable for reference. Sheets never change size. See [docs/ux-implementation.md](docs/ux-implementation.md) for the full technical specification.

The scoring screen displays all 8 questions as a grid with participants as columns and questions as rows. This mirrors butcher paper on a wall — the full picture is always visible, with the current question highlighted.

**Unified Slide Map (up to 7 slides, progressively appended):**
- **Slides 0-3: Intro slides** — Welcome, how-it-works, balance scale, maximal scale (always rendered, full 960px)
- **Slide 4: Scoring Grid** — The full 8-question scoring grid (rendered in scoring/summary/completed)
- **Slide 5: Summary** — Overview of all scores and notes (rendered in summary/completed)
- **Slide 6: Wrap-up** — Action planning and export (rendered in completed)

**Notes/Actions Side Panel:**
Notes and actions are presented in a fixed-position panel that peeks from the right edge of the viewport (not a carousel slide). A 40px peek tab is visible when the scoring grid is active (carousel index 4). Clicking the tab reveals a 480px panel; clicking outside dismisses it. This keeps notes accessible without consuming a carousel slot.

Users can click any visible slide to view it for reference. This is local navigation only — no backend state change. FABs (floating action buttons) drive phase transitions and are shown only when the carousel index matches the current phase.

**Turn-Based Sequential Scoring:**

For each of the 8 questions (one row at a time):

1. **Present the criterion** — the left panel shows explanation, scoring guidance, and discussion tips
2. **Individual turns** — participants score one at a time, in join order:
   - A **floating score overlay** appears for the current turn participant
   - They select a score — it **auto-submits immediately** (no separate Share/Submit button)
   - The overlay closes and their score appears in the grid
   - **Click-to-edit**: While it's still their turn, they can click their score cell to reopen the overlay and change their score
   - After discussing, they click **"Done"** to pass the turn
   - Facilitator can **skip** an inactive participant via a floating button in the bottom-right
3. **Ready to advance** — after all turns are complete:
   - All scores are visible in the grid
   - Any participant can add notes via the side-sheet
   - Each non-facilitator participant clicks **"I'm Ready"** when done discussing
   - Skipped participants are automatically marked as ready
   - Facilitator advances to next question once all participants are ready
4. **Row locks permanently** — once the group advances, scores for that row cannot be changed

**Key UX Principles:**
- No hidden scores — everything is visible immediately in the grid
- No "reveal" moment — discussion happens during scoring, not after
- Sequential turns, but the full grid provides context across all questions
- Auto-submit reduces friction — select a score and it's placed instantly
- Click-to-edit allows score changes without extra UI (during your turn only)
- Floating action buttons in bottom-right keep the grid uncluttered

### 4. Summary & Review
- Overview of all 8 questions with individual scores and notes
- Participants list for reference
- Review discussion points before creating actions

### 5. Wrap-up & Action Planning
- Highlight areas of strength (green) and areas needing attention (red)
- Score grid showing all question averages at a glance
- **Action items** - prompt team to identify concrete actions/next steps:
  - Add discrete action items
  - No limit on number of actions, but quality over quantity
- Suggestions on what to focus on available via **Facilitator Assistance** (not shown by default)
- Discussion notes summary
- Participants list
- Export with two report types:
  - **Full Workshop Report** — all data including individual scores, participant names, notes, and actions
  - **Team Report** — anonymized team-level view with "TEAM REPORT / No individual scores, names or notes" header: team scores, strengths/concerns, and actions (no individual scores, names, or notes)
- Export formats: CSV and PDF (client-side rendering via html2pdf.js)
- "Finish Workshop" to return to home

## Time Management

### Overview
Workshops can range from under an hour (experienced teams) to a full day (first-timers with rich discussions). A built-in timer helps facilitators stay on track without being rigid.

**Recommended duration:** 100-120 minutes (most teams)

### Session Time Setup
- Timer is **optional** - facilitator chooses whether to use one at session creation
- If enabled, select from presets or custom duration:
  - **No timer** (default) - no time tracking
  - **2 hours** - Normal session
  - **3.5 hours** - Full session (recommended for first-time teams)
  - **Custom** - Set any duration in 5-minute increments (30 min to 8 hours)

### Time Allocation: 10-Segment Approach

The system divides total time into **10 equal segments**:

| Segment | Purpose |
|---------|---------|
| 1-8 | One segment per question (8 questions) |
| 9 | Summary + Actions (combined phase) |
| 10 | Unallocated flex/buffer time |

**Example: 100-minute workshop**
- Each segment = 10 minutes
- Questions 1-8: 10 minutes each (80 min total)
- Summary + Actions: 10 minutes
- Flex buffer: 10 minutes

This simplified approach ensures equal time per question and provides built-in flexibility.

### Timer Features (MVP)

**Facilitator-only countdown:**
- Timer visible **only to the facilitator** (not participants)
- Fixed position in top-right corner
- Shows time remaining for current section
- Displays current phase name (e.g., "Question 3", "Summary + Actions")

**Warning state:**
- Timer turns **red at 10% remaining** (e.g., 1 minute left on a 10-minute segment)
- Visual cue helps facilitator pace discussions

**Auto-start behavior:**
- Timer starts when the **facilitator first reaches the scoring sheet** (not during intro slides)
- Timer restarts when moving to the next question
- Summary and Actions **share one timer** - no restart on that transition

### Philosophy
- **Guidance, not enforcement** - timers inform, they don't control
- **Facilitator's tool** - keeps the facilitator aware of pacing without distracting participants
- Teams are free to spend more time where conversations are rich
- The flex buffer provides breathing room

### Future Enhancements (Not in MVP)
- Pause timer (e.g., for breaks)
- Adjust remaining time mid-session
- Overall workshop time remaining display
- Pacing indicators for ahead/behind schedule

---

## Psychological Safety & Privacy

### The Prime Directive (Norm Kerth)

The workshop operates under Norm Kerth's Prime Directive:

> **"Regardless of what we discover, we understand and truly believe that everyone did the best job they could, given what they knew at the time, their skills and abilities, the resources available, and the situation at hand."**

Scores reflect the *system and environment*, not individual failings. Low scores are not accusations - they are opportunities to understand and improve how work is structured.

### Privacy Principles

**Individual scores are visible only to the team:**
- Scores are never shared outside the session participants
- No management dashboards or aggregated org-level reporting of individual data
- What happens in the session stays in the session

**Trust is foundational:**
- Honest responses require safety
- The tool will never be used to evaluate or judge individuals
- Variance in scores is expected and healthy - it reveals different experiences

### Data Visibility Summary

| Data | Who Can See |
|------|-------------|
| Individual scores | Team members in that session only |
| Notes & actions | Team members in that session only |
| Session exists | Only those with the link |

*Note: Multi-team and organizational use cases (aggregated/anonymized insights across teams) are out of scope for MVP and will be discussed separately.*

---

## User Roles & Participation

### Facilitator Role
- The session creator is designated as the **facilitator**
- Facilitator controls workshop progression (starting, advancing questions)
- Facilitator can choose to participate in two modes:
  - **Team member** (default) - participates in scoring like other team members
  - **Observer** - watches the session without entering scores; useful when facilitating for another team

### Participation
- Participants score one at a time in join order (column order on the grid)
- Scores are visible immediately when placed - no hidden state
- **Turn progression**: Current participant places score, then clicks "Done" to pass turn
- **Advancing to next criterion**: All participants mark "Ready" to move forward
- **Facilitator role during scoring**: Facilitator starts the session but does not control pace during scoring. Anyone can move the session forward if it stalls (but this is a fallback, not normal flow)
- **Typical team size**: 6-12 participants (optimize UI for this range)

### Handling Dropouts
- If a participant leaves mid-workshop:
  - Their previous scores are retained
  - They are shown as **greyed out** in the participant list
  - Remaining participants can continue without them
  - System only waits for active participants to submit/confirm

## Session Management

### Team Room Concept
Each team has a "team room" - a persistent space containing:
- **Incomplete sessions** - workshops in progress that can be resumed
- **Completed sessions** - finished workshops available for review
- Team room accessed via a shareable link (no account required for MVP)

### Session Lifecycle
1. **Create session** - generates team room if first session, or adds to existing team room
2. **Active session** - participants join and work through questions
3. **Paused/Incomplete** - team can leave and return later via team room link
4. **Completed** - all 8 questions scored, actions captured, available for review

### Session Time Limits
- Sessions have a configurable time limit (TBD - e.g., 7 days?)
- Incomplete sessions remain accessible until expiry
- Completed sessions retained longer (or indefinitely for logged-in users)

### Joining a Session
- Each session has its own unique link
- **New sessions**: Anyone with the link can join before scoring begins
- **In-progress sessions**: Only original participants can rejoin
  - Primary: Automatic recognition via browser localStorage
  - Fallback: Re-enter name, matched against original participant list
- Team room is a conceptual grouping, not a separate navigable page in MVP

## Authentication (Phased)

### Phase 1 (MVP)
- **No authentication required**
- Anyone with a session link can join
- Enter display name to participate

### Phase 2 (Future)
- Optional account creation
- Required to:
  - Save sessions for later review
  - Compare current scores to previous workshops
  - Manage persistent teams

## Data Persistence

### Results Storage
- Workshop results saved to database
- Historical comparison available (for logged-in users)
- Export options: CSV and PDF, with Full (all data) or Team (anonymized) report types

### Privacy Considerations
- Anonymous sessions: data retained for session duration + configurable period
- Logged-in users: full history retained

## Discussion Approach

- **No in-app chat** - teams discuss via their own channels (in-person, MS Teams, Zoom, etc.)
- The app facilitates scoring and visualization, not the conversation itself
- **Notes feature**: Ability to capture key discussion points at the session level
  - Any participant can add notes
  - Notes saved with the session results

## Guided Facilitation Features

Since the app replaces a human facilitator, it should provide:

### For Each Criterion
1. **Clear explanation** of what the criterion means
2. **Scoring guidance** - what the numbers represent
3. **Discussion prompts** - suggested questions to explore after scores are revealed
4. **Interpretation help** - what patterns in scores might indicate

### Facilitation Philosophy
- **Create space, don't spoon-feed** - prompts should open conversation, not direct it
- The goal is to surface **unexpected variance** - where team members have different experiences
- Teams need to talk to uncover what's really going on
- Over-prescriptive prompts can be disempowering and limit organic discovery

### Generic Discussion Prompts
Prompts should be observational and open-ended:

**When scores show variance:**
- "There's a spread in scores here. What might be behind the different experiences?"
- "Some of you scored quite differently - what's that about?"

**When scores are clustered:**
- "The team seems aligned on this one. Does that match your sense?"

**For balance criteria (1-4) when scores trend away from 0:**
- "Most scores lean in one direction. What's contributing to that?"

**General exploration:**
- "What stands out to you looking at these scores?"
- "Anything here that surprises you?"

**Note:** Prompts are suggestions only - teams may skip them entirely if conversation flows naturally.

## Results Visualization

### During Workshop (Scoring Grid)
- **Full 8-question grid** displayed at all times — criteria as rows, participants as columns
- **Two scale sections** — Balance Scale (-5 to +5) and Maximal Scale (0 to 10) with section labels
- **Active row highlighted** — the current criterion being scored is visually distinct
- **Active column highlighted** — the current turn participant's column header is marked
- **Scores appear immediately** when placed — visible to all participants in the grid
- **Cell states** — `...` (current turn, waiting), `?` (skipped), `—` (pending/future), or actual score value
- **Balance scores formatted** — positive values show `+` prefix (e.g., `+3`)
- **Completed rows** — visible as a permanent record, locked once group advances

### Traffic Light Color Coding

Colors indicate how concerning a score is at a glance.

**Balance Scale Questions (1-4)** - where 0 is optimal:

| Score | Color | Meaning |
|-------|-------|---------|
| 0, +/-1 | Green | Healthy - close to optimal |
| +/-2, +/-3 | Amber | Moderate concern |
| +/-4, +/-5 | Red | Significant concern |

**Maximal Scale Questions (5-8)** - where 10 is optimal:

| Score | Color | Meaning |
|-------|-------|---------|
| 7-10 | Green | Healthy |
| 4-6 | Amber | Moderate concern |
| 0-3 | Red | Significant concern |

### Applying Traffic Lights

- **Individual scores**: Each participant's score shown with traffic light color
- **Combined Team Value**: Team score for each question shown with traffic light color
- **Summary view**: All 8 questions at a glance with color indicators

### Combined Team Value

The **Combined Team Value** is a score out of 10 that represents team performance on each criterion while accounting for variance. Unlike a simple average, it grades each person's score individually before combining.

**How it works:**
1. Each individual score is graded based on traffic light color:
   - Green = 2 points (good)
   - Amber = 1 point (medium)
   - Red = 0 points (low)
2. Grades are summed and divided by number of participants
3. Result is scaled to 0-10

**Interpretation:**
| Score | Meaning |
|-------|---------|
| 10 | Everyone scored well (all green) |
| 5 | Mixed results (average of amber scores) |
| 0 | Everyone scored poorly (all red) |

**Why this matters:** A simple average can hide variance. For example, if half the team scores +5 and half scores -5 on a balance question, the average is 0 (appearing optimal). The Combined Team Value would show 0/10 (all red), correctly identifying that everyone is outside the healthy range.

### End of Workshop Summary
- Overview of all 8 questions with Combined Team Values
- Quickly see which areas are healthy (green) vs need attention (red)
- Pattern recognition across the team

## MVP Scope (Phase 1)

### Included in MVP (all complete)
- [x] Session creation with shareable link
- [x] Time allocation setup at session creation
- [x] Join session via link (name entry only, no account)
- [x] Waiting room showing participants (join order determines scoring order)
- [x] Introduction/overview screen (4 screens, skippable)
- [x] Turn-based sequential scoring interface for all 8 questions
- [x] Section timers with countdown and warnings (facilitator-only)
- [x] Immediate score visibility — no hidden state (butcher paper principle)
- [x] Auto-submit scoring with floating overlay
- [x] Click-to-edit score during turn
- [x] Turn progression with "Done" button
- [x] Row locking when group advances
- [x] Skipped participants auto-marked as ready
- [x] Discussion prompts per criterion (expandable tips)
- [x] Notes capture (session-level, side-sheet panel)
- [x] "Ready" confirmation from all to advance rows
- [x] Summary view with individual scores and traffic lights
- [x] Action planning
- [x] Real-time sync via Phoenix LiveView + PubSub
- [x] Sheet carousel layout with full 8-question grid
- [x] PostHog analytics integration
- [x] Observer mode for facilitator
- [ ] Feedback button

### Deferred to Later Phases
- [ ] User accounts and authentication
- [ ] Persistent teams
- [ ] Historical comparison
- [x] Export (CSV, PDF) — Full Workshop Report and Team Report types
- [ ] Previous score comparison
- [ ] Advanced visualizations
- [ ] Usage analytics (aggregated, anonymized)

## Content: Introduction Screen

The introduction is presented before scoring begins. **Skippable** for experienced teams.

### Skip Option
- "Skip intro" button visible on all intro slides
- Skipping takes the individual participant directly to the scoring sheet
- Each participant navigates independently — no facilitator-gated transition

### Screen 1: Welcome

> **Welcome to the Six Criteria Workshop**
>
> This workshop helps your team have a meaningful conversation about what makes work engaging and productive.
>
> Based on forty years of research by Fred and Merrelyn Emery, the Six Criteria are the psychological factors that determine whether work is motivating or draining.
>
> As Fred Emery put it: *"If you don't get these criteria right, there will not be the human interest to see the job through."*

### Screen 2: What You'll Do

> **How This Workshop Works**
>
> You'll work through 8 questions covering 6 criteria together as a team.
>
> For each question:
> 1. One person at a time places their score (like writing on butcher paper)
> 2. Scores are visible immediately - the conversation happens as you go
> 3. When it's your turn, place your score and click "Done" to pass to the next person
> 4. When everyone has scored, mark "Ready" to move to the next question
>
> The goal isn't to "fix" scores - it's to **surface and understand** different experiences within your team.

### Screen 3: The Balance Scale (Questions 1-4)

> **Understanding the First Four Questions**
>
> These use a **balance scale** from -5 to +5:
> - These need the right amount - not too much, not too little
> - **0 is optimal** (balanced)
> - Negative means too little, positive means too much
>
> Don't overthink - go with your gut feeling about your current experience.

### Screen 4: Understanding the Maximal Scale

> **Understanding the Maximal Scale**
>
> The last four questions use a **maximal scale** from 0 to 10:
> - For these criteria, **more is always better**
> - **10 is optimal** — the ideal to strive for
> - Lower scores highlight areas where the team needs more

---

## Content: Mid-Workshop Transition (Before Question 5)

Shown after completing Question 4, before starting Question 5:

> **New Scoring Scale Ahead**
>
> Great progress! You've completed the first four questions.
>
> The next four questions use a different scale: **0 to 10**
> - For these, **more is always better**
> - 10 is optimal
>
> These measure aspects of work where you can never have too much.

---

## On-Demand Facilitator Assistance

A **"Facilitator Assistance"** button available throughout the workshop. When clicked, shows contextual guidance without forcing it on everyone.

### Help Content Examples

**During scoring:**
> Think about your day-to-day experience, not exceptional situations. What's your typical reality?

**During discussion (when scores vary):**
> Wide score differences often reveal that team members have different roles, contexts, or experiences. Try asking: "What's a specific example that led to your score?"

**During discussion (when stuck):**
> If conversation stalls, try: "What would need to change for scores to improve?" But don't force it - sometimes a quick acknowledgment is enough.

**During discussion (general):**
> The facilitator's job is to create space, not fill it. Silence is okay. Let people think.

**During action planning:**
> Consider focusing on areas that showed red or amber scores. But don't ignore patterns - if several related questions scored poorly, there may be a root cause worth addressing.

> Good actions are specific and achievable. "Improve communication" is vague. "Hold a weekly 15-minute team sync" is actionable.

> You don't need to fix everything today. Pick 1-3 actions the team can realistically commit to.

**Note:** Facilitator Assistance appears only when requested - respects the "don't spoon-feed" principle while supporting teams that want more guidance.

---

## Content: Question Explanations

The following explanations will be shown to participants when scoring each question:

### Question 1: Elbow Room
**What it means:** The ability to make decisions about how you do your work in a way that suits your needs. This includes autonomy over methods, timing, and approach.

**Balance consideration:** Autonomy preferences vary - some people thrive with more freedom, others prefer more structure. The optimal score (0) means you have the right amount for you.

### Question 2a: Setting Goals (Continual Learning)
**What it means:** The ability to set your own challenges and targets rather than having them imposed externally. This enables you to maintain an optimal level of challenge.

**Example:** When management sets a Friday deadline but work could finish Wednesday, do you have authority to set your own timeframes?

### Question 2b: Getting Feedback (Continual Learning)
**What it means:** Receiving accurate, timely feedback that enables learning and improvement. Delayed feedback (weeks or months later) provides little value for current work.

**Why it matters:** Without timely feedback, you can't experiment and discover better methods - success becomes chance rather than learning.

### Question 3: Variety
**What it means:** Having a good mix of different tasks and activities. Preferences differ - some people prefer diverse tasks, others favor routine.

**Balance consideration:** The optimal score (0) means you're not stuck with excessive routine tasks, nor overwhelmed by too many demanding activities at once.

### Question 4: Mutual Support and Respect
**What it means:** Working in a cooperative rather than competitive environment where team members help each other during difficult periods.

**What good looks like:** Help flows naturally among peers. Colleagues assist during challenging times without being asked.

### Question 5a: Socially Useful (Meaningfulness)
**What it means:** Your work is worthwhile and contributes value that is recognized by both you and the broader community.

**Reflection:** Can you identify the tangible value your work contributes?

### Question 5b: See Whole Product (Meaningfulness)
**What it means:** Understanding how your specific work contributes to the complete product or service your organization delivers.

**Example:** Like an assembly line worker who knows what happens before and after their station, and understands quality standards - can you connect your individual effort to organizational output?

### Question 6: Desirable Future
**What it means:** Your position offers opportunities to learn new skills and progress in your career. As you master new competencies, your aspirations can grow.

**What good looks like:** Clear paths for development, recognition of growing capabilities, opportunities for increased responsibility.

---

## Error States & Edge Cases

### Connection Issues

**Participant loses connection:**
- Auto-rejoin seamlessly when connection restored
- Pick up exactly where they left off
- No disruption to other participants

**Server/network errors:**
- Show friendly error message
- Attempt automatic reconnection
- Preserve local state where possible

### Participant Edge Cases

**Late joiner (session already in progress):**
- Allowed to join as **observer only**
- Can see scores and discussion but cannot participate
- May be useful for managers or stakeholders observing

**Current participant is slow/away:**
- **Subtle indicator** shows whose turn it is
- Facilitator can skip to the next person if the current person is unavailable
- Skipped participants are automatically counted as ready for the team discussion phase
- Team manages pacing socially

**Solo participant (everyone else dropped):**
- **Prompt with options**: pause session and wait for others, or continue alone
- Continuing alone has limited value but is allowed

**Participant wants to change score:**
- **Allowed during their turn** - can modify score before clicking "Done"
- Once "Done" is clicked, their score is locked for that turn
- Once the group advances to the next criterion, all scores in that row are permanently locked

### Session Edge Cases

**Invalid or expired session link:**
- Silently **redirect to app homepage**
- No error message shown

**Session timeout during workshop:**
- Warn participants before timeout
- Option to extend if still active
- Incomplete sessions remain accessible via original link until expiry

**Minimum participants:**
- Minimum 2 participants to start a session
- Workshop can continue with 1 if others drop (with prompt)

**Maximum participants:**
- **Soft limit** at 15 participants - show warning: "Large groups may make discussion difficult"
- **Hard limit** at 20 participants - cannot exceed
- Allow to proceed past soft limit if team chooses (up to hard limit)

**Session creator leaves:**
- **Ownership transfers** to another active participant automatically
- Session continues without disruption
- No special privileges tied to creator role (all participants equal)

### Input Validation

**Missing score:**
- Cannot submit without selecting a score
- Clear visual indication that score is required

**Notes/actions:**
- Notes are optional
- Actions are optional but encouraged
- No character limits (reasonable max for DB storage)

---

## Feedback

### Feedback Button
- **Always accessible** throughout the workshop (e.g., in footer or menu)
- Opens simple form to capture:
  - What's working well
  - Improvement ideas
  - Bug reports
- Optional: include session context (which section, time spent) to help understand feedback
- Optional: email address for follow-up

### Philosophy
- Make it easy to share thoughts in the moment
- Feedback helps improve the tool for everyone
- Low friction - don't interrupt the workshop flow

---

## Outstanding Items (To Be Defined)

The following features require further design decisions:

### Session Results Access
- **Question:** After completing a workshop, can users return to view results later?
- **Considerations:**
  - How long should results persist?
  - Should there be a unique results URL?
  - Should participants be able to access results independently, or only via facilitator?

### Session Management
- **Question:** How should facilitators manage their sessions?
- **Considerations:**
  - View list of past sessions
  - Delete old sessions
  - Session expiration/cleanup policy
  - Session status indicators (active, completed, expired)

---

## Future Enhancements (Phase 2+)

- User authentication (magic link or email/password)
- Save sessions to account
- Compare current workshop to previous results
- Persistent team management
- Usage analytics dashboard (for product improvement)
- Richer analytics and trend visualization
- Mobile-optimized experience

---

*Document Version: 4.5 — Fixed "Intrinsic Motivator" → "Intrinsic Motivation" subtitle; header now uses shared `OostkitShared.Components.header_bar/1` component*
*Last Updated: 2026-02-12*
