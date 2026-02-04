# Design Prompts for Claude.ai + Canva

Use these prompts with Claude.ai's Canva integration to generate design concepts for the Productive Workgroups app. The prompts are based on the "butcher paper principle" - the app should feel like butcher paper on a wall: visible, permanent within each phase, sequential, shared, and simple.

## Prerequisites

- Have your company brand template loaded in Canva
- Reference the Desirable Futures Group visual language: https://www.desirablefutures.group/
- Dark theme as the base

---

## 1. Overall Visual Direction (Start Here)

> Create a mood board for a team workshop facilitation app. The core metaphor is "butcher paper on a wall" - the collaborative feeling of a team standing around a large sheet of paper, placing sticky notes or writing scores. The aesthetic should be:
> - Professional but warm and approachable
> - Collaborative and visible (nothing hidden)
> - Simple and focused (not cluttered)
> - Dark theme as the base
>
> Show color palettes, typography ideas, and visual textures that capture this feeling. Use my brand template as the foundation.

---

## 2. Main Scoring Grid Screen

> Design a web app screen showing a scoring grid for a team workshop. This is the "butcher paper" view where:
> - Rows are questions/criteria (8 total)
> - Columns are team members (4-8 people)
> - Each cell shows a score (0-10)
> - One row is highlighted as "active" (currently being scored)
> - One column shows whose turn it is
> - Scores appear immediately when placed (no hidden votes)
>
> The grid should feel like a shared whiteboard or butcher paper - visible, permanent, collaborative. Include a header showing the session name and a footer with navigation controls. Dark theme, using my brand colors.

---

## 3. Participant Scoring View

> Design a mobile-friendly screen for a participant placing their score in a team workshop. Show:
> - The current question at the top (e.g., "How well does your team handle Variety in work?")
> - A scale from 0 to 10 with clear labels at each end
> - The participant's selected score (large, prominent)
> - A "Done" button to confirm and pass to the next person
> - A subtle indicator showing who scores next
>
> The interaction should feel like walking up to butcher paper and placing a sticky note. Simple, confident, one clear action. Dark theme with my brand styling.

---

## 4. Team Discussion Phase

> Design a screen for the "team discussion" phase of a workshop. All participants have placed their scores, and now the team discusses together. Show:
> - The completed scoring row with all scores visible
> - Team average prominently displayed
> - Visual indication of variance/spread (are scores clustered or spread out?)
> - Discussion prompts or questions to guide conversation
> - A "Ready" button for participants to indicate they're done discussing
> - Progress indicator showing how many are ready
>
> The feel should be "stepping back to look at the butcher paper together." Dark theme, brand colors.

---

## 5. Session Lobby / Join Screen

> Design a simple join screen for a workshop session. A participant has received a link and lands here. Show:
> - Session name
> - A field to enter their display name
> - A "Join Session" button
> - List of participants already in the session
> - Warm, welcoming feel - like walking into a workshop room
>
> Keep it minimal - one clear action. Dark theme with brand styling.

---

## 6. Results Summary

> Design a results summary screen shown at the end of a team workshop. Display:
> - The complete scoring grid (all 8 questions, all participants)
> - Team averages per question
> - Visual highlighting of high/low scores (traffic light: green/amber/red)
> - Key insights or patterns (optional)
> - "Export" or "Share" action
>
> This is the "finished butcher paper" - the artifact the team takes away. Should feel complete and valuable. Dark theme.

---

## 7. Component Library

> Create a design system page showing UI components for a workshop app. Include:
> - Buttons (primary, secondary, disabled states)
> - Score chips/badges (showing numbers 0-10)
> - Participant avatars/name tags
> - Progress indicators
> - Cards/panels
> - Form inputs
>
> Style should match butcher paper aesthetic - perhaps subtle paper textures, marker-style highlights, or sticky-note inspired elements. Use my brand colors on a dark background.

---

## Tips for Using These Prompts

1. **Start with #1** (mood board) to establish direction before detailed screens
2. **Iterate** - ask Claude to "make it feel more handwritten" or "add more whiteboard texture"
3. **Reference your brand** - say "use my brand template" or "apply my brand colors"
4. **Export as images** for reference when implementing in code

## Implementing Designs

Once you have design concepts, bring them back to Claude Code to:
- Extract color values and create a Tailwind theme
- Translate component designs to Phoenix LiveView components
- Apply consistent styling across the app

## Reference Documents

- [REQUIREMENTS.md](../apps/workgroup_pulse/REQUIREMENTS.md) - Full app requirements including UI/UX guidelines
- [SOLUTION_DESIGN.md](../apps/workgroup_pulse/SOLUTION_DESIGN.md) - Technical architecture
- Desirable Futures Group: https://www.desirablefutures.group/
