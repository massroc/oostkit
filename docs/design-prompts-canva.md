# Design Prompts for Claude.ai + Canva

Use these prompts with Claude.ai's Canva integration to generate design concepts for the workshop apps. Each prompt is structured to map to the Canva tool parameters that Claude.ai uses when generating designs.

## Canva Tool Parameters

When Claude.ai creates a Canva design, it calls the `generate-design` tool with these parameters:

| Parameter | Required | Description |
|-----------|----------|-------------|
| `query` | Yes | Description of what to generate |
| `design_type` | Yes | Preset type: `presentation`, `whiteboard`, `doc`, `poster`, `flyer`, `logo`, `instagram_post`, `instagram_story`, `facebook_post`, `facebook_cover`, `youtube_thumbnail`, `twitter_post`, `linkedin_post`, `business_card` |
| `user_intent` | Yes | What the user is trying to accomplish |
| `brand_kit_id` | No | Your Canva Brand Kit ID (apply to all prompts if you have one) |
| `asset_ids` | No | Existing Canva assets to reference |

## Prerequisites

- Connect your Canva account to Claude.ai via the AI Connector
- Set up your Desirable Futures Group brand kit in Canva and note the `brand_kit_id`
- Reference: https://www.desirablefutures.group/
- See [brand-colors.md](./brand-colors.md) for the full color palette

---

## Core Design Language

Include this context when prompting Claude.ai so it carries through to all designs.

### The Virtual Wall Metaphor

The app represents a virtual wall where butcher paper sheets are arranged. Users work on one sheet at a time while maintaining awareness of the broader context.

| Term           | Meaning                                                              |
|----------------|----------------------------------------------------------------------|
| Sheet          | A single working surface (like butcher paper) - the primary unit of work |
| Current Sheet  | The active sheet in focus, full size, where work happens             |
| Previous Sheet | Visible alongside current, smaller with drop shadow, provides context |
| Side-sheet     | Drawer/toggle panel for auxiliary content (notes, questions, actions) |
| Sheet Strip    | Navigation filmstrip showing all sheets in miniature                 |
| Virtual Wall   | The overall container - the metaphorical wall where all sheets live  |

### Typography

- **Branding/Headers**: Elegant, clean font matching Desirable Futures identity
- **Workshop Content**: Handwritten/marker pen font - evokes writing on butcher paper with markers

### Color Palette

**Base**: Clean off-whites, cream tones for paper texture

**Accents** (Tertiary Colors):
- `#7245F4` Purple - Primary accent, interactive elements
- `#BC45F4` Magenta - Secondary accent, highlights
- `#F4B945` Gold - Attention, active states, high scores
- `#F44545` Red - Alerts, warnings, low scores

### Visual Hierarchy

- **Current Sheet**: Full focus, prominent, white/cream surface
- **Previous Sheet**: Smaller, positioned to the side, subtle drop shadow to recede
- **Sheet Strip**: Miniature thumbnails for navigation, visible at edge of viewport
- **Side-sheet**: Slides in as a drawer when needed

---

## Prompts

### 1. Overall Visual Direction (Start Here)

- **design_type**: `presentation`
- **user_intent**: Establish the visual direction and mood for a team workshop facilitation web app

**query**:

> Create a mood board for a team workshop facilitation app called "Workgroup Pulse". The core metaphor is "Virtual Wall" - butcher paper sheets arranged on a wall, with one sheet in focus at a time. The aesthetic should be:
> - Clean, light theme with off-white/cream backgrounds
> - Paper-like textures for the sheets
> - Professional but warm and approachable
> - Two typography styles: elegant for branding, handwritten/marker-style for workshop content
> - Collaborative and visible (nothing hidden)
>
> Color accents: Purple (#7245F4), Magenta (#BC45F4), Gold (#F4B945), Red (#F44545)
>
> Show color palettes, typography ideas, and visual textures that capture this feeling.

---

### 2. Virtual Wall Overview

- **design_type**: `presentation`
- **user_intent**: Design the main layout for a web app showing multiple sheets of work arranged on a virtual wall

**query**:

> Design a web app screen showing the "Virtual Wall" - the complete view of all sheets in a workshop session. Show:
> - A filmstrip/strip of sheet thumbnails along one edge
> - One sheet prominently in focus (the Current Sheet)
> - A Previous Sheet visible but smaller, with a subtle drop shadow
> - Clean off-white background with paper textures on sheets
> - A side-sheet drawer icon/toggle visible but closed
>
> The feel should be standing in front of a wall of butcher paper, with one sheet pulled forward for attention. Light theme, brand colors as accents.

---

### 3. Main Scoring Grid (Current Sheet)

- **design_type**: `presentation`
- **user_intent**: Design the main scoring interface where team members place scores on a shared grid

**query**:

> Design the Current Sheet for a team scoring workshop. This sheet shows a scoring grid where:
> - Rows are questions/criteria (8 total)
> - Columns are team members (4-8 people)
> - Each cell shows a score (0-10)
> - One row is highlighted as "active" (currently being scored)
> - One column shows whose turn it is
> - Scores appear immediately when placed (no hidden votes)
>
> The sheet should look like butcher paper with a subtle cream/paper texture. Use marker-style handwritten font for scores and labels. The Previous Sheet should be visible to the side, smaller and with a drop shadow. Include the Sheet Strip for navigation.
>
> Light off-white background. Purple (#7245F4) for active states. Gold (#F4B945) for high scores. Red (#F44545) for low scores.

---

### 4. Side-sheet: Notes and Actions

- **design_type**: `presentation`
- **user_intent**: Design a slide-in drawer panel for capturing notes and action items alongside the main worksheet

**query**:

> Design a Side-sheet drawer that slides in from the edge of the screen. This is used for:
> - Taking notes during discussion
> - Recording action items
> - Capturing questions to address later
>
> Show it open alongside the Current Sheet. It should feel like a smaller piece of paper attached to the main sheet. Use the same paper texture and handwritten font style.
>
> Include a toggle/handle to open/close the drawer. Light theme with subtle accent colors.

---

### 5. Participant Scoring View

- **design_type**: `presentation`
- **user_intent**: Design a mobile-friendly scoring screen for a workshop participant placing their individual score

**query**:

> Design a mobile-friendly screen for a participant placing their score in a team workshop. Show:
> - The current question at the top (e.g., "How well does your team handle Variety in work?")
> - A scale from 0 to 10 with clear labels at each end
> - The participant's selected score (large, prominent)
> - A "Done" button to confirm and pass to the next person
> - A subtle indicator showing who scores next
>
> The interaction should feel like walking up to butcher paper and placing a sticky note. Simple, confident, one clear action. Light theme with paper texture. Handwritten/marker font for the score number.

---

### 6. Team Discussion Phase

- **design_type**: `presentation`
- **user_intent**: Design the post-scoring discussion screen where the team reviews results together

**query**:

> Design a screen for the "team discussion" phase of a workshop. All participants have placed their scores, and now the team discusses together. The Current Sheet shows:
> - The completed scoring row with all scores visible
> - Team average prominently displayed
> - Visual indication of variance/spread (are scores clustered or spread out?)
> - Discussion prompts or questions to guide conversation
>
> The Previous Sheet (the scoring grid) should be visible to the side for reference.
> The Side-sheet drawer should show a "notes" icon, inviting the facilitator to capture key points.
>
> The feel should be "stepping back to look at the butcher paper together." Light theme, paper textures.

---

### 7. Session Lobby / Join Screen

- **design_type**: `presentation`
- **user_intent**: Design the entry screen where participants join a workshop session

**query**:

> Design a simple join screen for a workshop session. A participant has received a link and lands here. Show:
> - Session name in elegant branding font
> - A field to enter their display name
> - A "Join Session" button
> - List of participants already in the session
> - Warm, welcoming feel - like walking into a workshop room
>
> Keep it minimal - one clear action. Light theme with clean off-white background. Accent color on the button.

---

### 8. Results Summary (Completed Wall)

- **design_type**: `presentation`
- **user_intent**: Design the end-of-workshop results view showing the completed scoring grid and key takeaways

**query**:

> Design a results summary screen shown at the end of a team workshop. This is the "completed wall" view showing:
> - All sheets in the Sheet Strip, showing the journey
> - The final summary sheet in focus with:
>   - Complete scoring grid (all questions, all participants)
>   - Team averages per question
>   - Visual highlighting of high/low scores (gold for high, red for low)
> - "Export" or "Share" action
>
> This is the finished artifact the team takes away. Should feel complete and valuable - like photographing the wall of butcher paper before leaving the room. Light theme.

---

### 9. Component Library

- **design_type**: `whiteboard`
- **user_intent**: Create a design system reference sheet showing all reusable UI components for the workshop app

**query**:

> Create a design system page showing UI components for a team workshop app. Include:
> - Buttons (primary in purple, secondary, disabled states)
> - Score chips/badges (showing numbers 0-10, gold for high, red for low)
> - Participant avatars/name tags
> - Progress indicators
> - Sheet thumbnails for the Strip
> - Side-sheet toggle/handle
> - Paper-textured cards/panels
> - Form inputs
>
> Two font styles: elegant for UI labels, handwritten/marker for scores and workshop content.
> Light off-white background with paper textures. Accent colors: Purple (#7245F4), Magenta (#BC45F4), Gold (#F4B945), Red (#F44545).

---

### 10. Facilitator Scoring Grid (Desktop 1440px)

- **design_type**: `presentation`
- **user_intent**: Design a high-fidelity desktop mockup of the facilitator's main view during a live scoring workshop session

**query**:

> Design a desktop mockup (1440px wide) showing the facilitator's view of a team workshop in progress. This is the main working screen where scoring happens.
>
> **Grid Structure:**
> - Single cream/butcher paper sheet showing ALL 8 questions visible at once
> - Rows labeled with CRITERION names (all caps, handwritten marker style):
>   1. ELBOW ROOM
>   2. CONTINUAL LEARNING - (a) Setting Goals
>   3. CONTINUAL LEARNING - (b) Getting Feedback
>   4. VARIETY
>   5. MUTUAL SUPPORT AND RESPECT
>   6. MEANINGFULNESS - (a) Socially Useful
>   7. MEANINGFULNESS - (b) See Whole Product
>   8. DESIRABLE FUTURE
> - 5 participant columns: Mary, Jo, Peter, Jane, Kate
> - Mixed scores in handwritten marker font:
>   - Rows 1-4: Balance scale (-5 to +5), show scores like "-2", "0", "+3"
>   - Rows 5-8: Maximal scale (0-10), show scores like "7", "8", "5"
> - Current position: Row 4 (Variety), Jo's turn - both row and column highlighted with subtle purple (#7245F4) accent/border
> - All scores in neutral black (no traffic light color coding yet)
>
> **Layout:**
> - Header: Top-left has app icon + "Workgroup Pulse". Center shows workshop name. Top-right has settings icon and sign-in button.
> - Main area: Scoring grid on warm cream paper texture dominates the screen
> - Right edge: Smaller "Notes" side-sheet peeking out with drop shadow, showing handwritten content partially visible. When clicked, sheets swap focus (Notes becomes main, grid recedes to left).
> - Bottom: Reserve space for future Sheet Strip thumbnails (don't show the strip itself in this mockup)
>
> **Buttons (lower-left of sheet):**
> - "Submit" button (purple fill) - only visible when it's a participant's turn to score
> - "Skip Turn" and "Continue" buttons - always visible for facilitator (shown as simple boxes, context makes their purpose clear)
>
> **Visual Style:**
> - Sheet surface: Warm cream/butcher paper texture (tactile, not stark white)
> - Scores: Handwritten marker font, 20-24px, black
> - Criterion labels: Handwritten marker style, all caps
> - Headers/UI: Clean elegant sans-serif (Inter or similar)
> - Purple (#7245F4) for interactive highlights and current turn indicator
> - Light off-white (#FAFAFA) for wall background behind the sheet
>
> **NOT in this mockup:**
> - Sheet Strip thumbnails (space reserved only)
> - Traffic light color coding on scores (future enhancement after reveal)
> - Previous Sheet (this is a single-sheet approach)
> - "Show Score" or Back buttons

---

## Tips for Using These Prompts

1. **Start with #1** (mood board) to establish direction before detailed screens
2. **Include `brand_kit_id`** on every prompt if you have a Desirable Futures brand kit set up in Canva
3. **Iterate** - ask Claude to "make the paper texture more subtle" or "increase the drop shadow on the previous sheet"
4. **Export as images** for reference when implementing in code
5. **Prompt #10** is the primary mockup for the current redesign - start there if you're working on the scoring grid

## Implementing Designs

Once you have design concepts, bring them back to Claude Code to:
- Extract color values and create a Tailwind theme
- Translate component designs to Phoenix LiveView components
- Apply consistent styling across the app
- Implement the Sheet navigation system

## Reference Documents

- [brand-colors.md](./brand-colors.md) - Full color palette reference
- [design-system.md](./design-system.md) - Design system tokens and Tailwind implementation
- [REQUIREMENTS.md](../apps/workgroup_pulse/REQUIREMENTS.md) - Functional requirements
- [SOLUTION_DESIGN.md](../apps/workgroup_pulse/SOLUTION_DESIGN.md) - Technical architecture
- [UX Design](../apps/workgroup_pulse/docs/ux-design.md) - UX design specification
- [UX Implementation](../apps/workgroup_pulse/docs/ux-implementation.md) - UX implementation detail
- Desirable Futures Group: https://www.desirablefutures.group/
