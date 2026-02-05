# Design Prompts for Claude.ai + Canva

Use these prompts with Claude.ai's Canva integration to generate design concepts for the workshop apps. The prompts are based on the "Virtual Wall" metaphor - sheets of butcher paper arranged on a wall, with one sheet in focus at a time.

## Prerequisites

- Have your company brand template loaded in Canva
- Reference the Desirable Futures Group visual language: https://www.desirablefutures.group/
- See [brand-colors.md](./brand-colors.md) for the full color palette
- Light theme with clean off-whites as the base

---

## Core Design Language

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

## 1. Overall Visual Direction (Start Here)

> Create a mood board for a team workshop facilitation app. The core metaphor is "Virtual Wall" - butcher paper sheets arranged on a wall, with one sheet in focus at a time. The aesthetic should be:
> - Clean, light theme with off-white/cream backgrounds
> - Paper-like textures for the sheets
> - Professional but warm and approachable
> - Two typography styles: elegant for branding, handwritten/marker-style for workshop content
> - Collaborative and visible (nothing hidden)
>
> Color accents: Purple (#7245F4), Magenta (#BC45F4), Gold (#F4B945), Red (#F44545)
>
> Show color palettes, typography ideas, and visual textures that capture this feeling. Use my brand template as the foundation.

---

## 2. Virtual Wall Overview

> Design a web app screen showing the "Virtual Wall" - the complete view of all sheets in a workshop session. Show:
> - A filmstrip/strip of sheet thumbnails along one edge
> - One sheet prominently in focus (the Current Sheet)
> - A Previous Sheet visible but smaller, with a subtle drop shadow
> - Clean off-white background with paper textures on sheets
> - A side-sheet drawer icon/toggle visible but closed
>
> The feel should be standing in front of a wall of butcher paper, with one sheet pulled forward for attention. Light theme, brand colors as accents.

---

## 3. Main Scoring Grid (Current Sheet)

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

## 4. Side-sheet: Notes and Actions

> Design a Side-sheet drawer that slides in from the edge of the screen. This is used for:
> - Taking notes during discussion
> - Recording action items
> - Capturing questions to address later
>
> Show it open alongside the Current Sheet. It should feel like a smaller piece of paper attached to the main sheet. Use the same paper texture and handwritten font style.
>
> Include a toggle/handle to open/close the drawer. Light theme with subtle accent colors.

---

## 5. Participant Scoring View

> Design a mobile-friendly screen for a participant placing their score in a team workshop. Show:
> - The current question at the top (e.g., "How well does your team handle Variety in work?")
> - A scale from 0 to 10 with clear labels at each end
> - The participant's selected score (large, prominent)
> - A "Done" button to confirm and pass to the next person
> - A subtle indicator showing who scores next
>
> The interaction should feel like walking up to butcher paper and placing a sticky note. Simple, confident, one clear action. Light theme with paper texture. Handwritten/marker font for the score number.

---

## 6. Team Discussion Phase

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

## 7. Session Lobby / Join Screen

> Design a simple join screen for a workshop session. A participant has received a link and lands here. Show:
> - Session name in elegant branding font
> - A field to enter their display name
> - A "Join Session" button
> - List of participants already in the session
> - Warm, welcoming feel - like walking into a workshop room
>
> Keep it minimal - one clear action. Light theme with clean off-white background. Accent color on the button.

---

## 8. Results Summary (Completed Wall)

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

## 9. Component Library

> Create a design system page showing UI components for the workshop app. Include:
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
> Light off-white background with paper textures. Accent colors: Purple, Magenta, Gold, Red.

---

## Tips for Using These Prompts

1. **Start with #1** (mood board) to establish direction before detailed screens
2. **Iterate** - ask Claude to "make the paper texture more subtle" or "increase the drop shadow on the previous sheet"
3. **Reference your brand** - say "use my brand template" or "apply my brand colors"
4. **Export as images** for reference when implementing in code

## Implementing Designs

Once you have design concepts, bring them back to Claude Code to:
- Extract color values and create a Tailwind theme
- Translate component designs to Phoenix LiveView components
- Apply consistent styling across the app
- Implement the Sheet navigation system

## Reference Documents

- [brand-colors.md](./brand-colors.md) - Full color palette reference
- [REQUIREMENTS.md](../apps/workgroup_pulse/REQUIREMENTS.md) - Full app requirements including UI/UX guidelines
- [SOLUTION_DESIGN.md](../apps/workgroup_pulse/SOLUTION_DESIGN.md) - Technical architecture
- Desirable Futures Group: https://www.desirablefutures.group/
