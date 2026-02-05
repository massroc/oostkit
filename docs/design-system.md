# Desirable Futures Workshop Design System

This document defines the shared design language across all workshop applications. It serves as the source of truth for visual design decisions.

## Contents

1. [Design Principles](#design-principles)
2. [Core Metaphor: The Virtual Wall](#core-metaphor-the-virtual-wall)
3. [Color System](#color-system)
4. [Typography](#typography)
5. [Spacing & Layout](#spacing--layout)
6. [Components](#components)
7. [States & Feedback](#states--feedback)
8. [Accessibility](#accessibility)
9. [Responsive Design](#responsive-design)

---

## Design Principles

These are the guiding values behind every design decision. When in doubt, refer back to these.

### 1. Visible & Shared

Nothing is hidden. In a physical workshop, everyone can see the butcher paper on the wall. Our apps maintain this transparency - scores appear immediately, progress is visible to all, the current state is always clear.

### 2. Focused Simplicity

One thing at a time. Physical workshops work because you focus on one sheet, one question, one activity. Our apps bring the current work into focus while keeping context accessible but not distracting.

### 3. Warm & Professional

Workshop facilitation is serious work done in a human, collaborative way. The design should feel approachable and warm without being casual or playful. Think: a well-designed meeting room, not a children's classroom.

### 4. Familiar Physicality

The interface should evoke physical workshop materials - paper, markers, sticky notes. This familiarity reduces cognitive load and connects the digital experience to the in-person workshops our users know.

---

## Core Metaphor: The Virtual Wall

All workshop apps share the "Virtual Wall" metaphor - a wall where sheets of butcher paper are arranged, with work happening on one sheet at a time.

### Vocabulary

Use these terms consistently across all apps and documentation:

| Term           | Definition                                                           |
|----------------|----------------------------------------------------------------------|
| **Virtual Wall**   | The overall container - the metaphorical wall where all sheets live |
| **Sheet**          | A single working surface (like butcher paper) - the primary unit of work |
| **Current Sheet**  | The active sheet in focus, full size, where work happens |
| **Previous Sheet** | Visible alongside current, smaller with drop shadow, provides context |
| **Side-sheet**     | Drawer/toggle panel for auxiliary content (notes, questions, actions) |
| **Sheet Strip**    | Navigation filmstrip showing all sheets in miniature |

### Visual Hierarchy

```
┌─────────────────────────────────────────────────────────────────────┐
│  VIRTUAL WALL                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ Sheet Strip (thumbnails)                                     │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                     │
│   ┌─────────────┐   ┌───────────────────────────┐   ┌──────────┐   │
│   │  Previous   │   │                           │   │  Side-   │   │
│   │   Sheet     │   │      Current Sheet        │   │  sheet   │   │
│   │  (smaller,  │   │      (full focus)         │   │ (drawer) │   │
│   │  shadow)    │   │                           │   │          │   │
│   └─────────────┘   └───────────────────────────┘   └──────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Sheet Treatments

| Sheet Type     | Size    | Shadow           | Opacity | Purpose                    |
|----------------|---------|------------------|---------|----------------------------|
| Current Sheet  | 100%    | None or subtle   | 100%    | Active work area           |
| Previous Sheet | ~60-70% | Pronounced drop  | 100%    | Context from prior step    |
| Sheet Strip    | Thumbnail | Subtle          | 100%    | Navigation & orientation   |
| Side-sheet     | ~30% width | Subtle edge   | 100%    | Auxiliary content (drawer) |

---

## Color System

See [brand-colors.md](./brand-colors.md) for the complete palette. This section covers *how* to use those colors.

### Theme: Light

All workshop apps use a light theme with clean off-white backgrounds.

### Color Roles

| Role              | Color(s)                  | Usage                                    |
|-------------------|---------------------------|------------------------------------------|
| **Background**    | Off-white `#FAFAFA` or similar | Virtual Wall background            |
| **Surface**       | White/cream               | Sheet surfaces (paper texture)           |
| **Text Primary**  | Near black `#151515`      | Headings, important text                 |
| **Text Secondary**| Gray `#A3A3A3`            | Supporting text, labels                  |
| **Primary Accent**| Purple `#7245F4`          | Interactive elements, buttons, links     |
| **Secondary Accent**| Magenta `#BC45F4`       | Highlights, hover states                 |
| **Success/High**  | Gold `#F4B945`            | High scores, positive indicators         |
| **Warning/Low**   | Red `#F44545`             | Low scores, alerts, warnings             |
| **Brand**         | DF Blue `#0095FF` / Green `#42D235` | Logo, brand moments only      |

### Color Application Guidelines

1. **Accent colors are for interaction and meaning** - Don't use purple or magenta as decoration. Reserve them for clickable elements and meaningful highlights.

2. **Gold and Red convey score quality** - Use consistently across all apps. Gold = good/high. Red = needs attention/low.

3. **The sheet surface should feel like paper** - Subtle cream or off-white, possibly with light texture. Never stark white.

4. **Shadows create depth, not darkness** - Use drop shadows to show which sheet is current vs. receded. Keep shadows subtle and warm-toned.

---

## Typography

### Font Families

| Purpose              | Style                        | Example Usage                     |
|----------------------|------------------------------|-----------------------------------|
| **Branding**         | Elegant, clean sans-serif    | App name, headers, navigation     |
| **Workshop Content** | Handwritten/marker style     | Scores, participant entries, notes |
| **UI/Body**          | Clean, readable sans-serif   | Labels, instructions, body text   |

> **Note**: Specific font selections to be determined during implementation. The key is maintaining the two-font distinction: polished for branding, handwritten for workshop content.

### Type Scale

Use a consistent scale across all apps. Example (adjust based on chosen fonts):

| Level | Size   | Weight    | Usage                          |
|-------|--------|-----------|--------------------------------|
| H1    | 32px   | Bold      | Page titles, app name          |
| H2    | 24px   | Semibold  | Section headers, sheet titles  |
| H3    | 20px   | Semibold  | Subsection headers             |
| Body  | 16px   | Regular   | Default text                   |
| Small | 14px   | Regular   | Labels, captions, metadata     |
| Tiny  | 12px   | Regular   | Timestamps, fine print         |

### Workshop Content (Handwritten Font)

| Element        | Size    | Notes                              |
|----------------|---------|-----------------------------------|
| Scores         | 32-48px | Large, prominent, easily scannable |
| Participant names | 16-20px | Clear but not dominant          |
| Notes          | 16px    | Readable, casual feel              |

---

## Spacing & Layout

Consistent spacing creates visual rhythm and makes interfaces feel cohesive.

### Spacing Scale

Use multiples of 4px (or 0.25rem if using rem units):

| Token  | Value  | Usage                                      |
|--------|--------|--------------------------------------------|
| `xs`   | 4px    | Tight spacing, within components           |
| `sm`   | 8px    | Related elements, icon gaps                |
| `md`   | 16px   | Standard spacing between elements          |
| `lg`   | 24px   | Section spacing                            |
| `xl`   | 32px   | Major section breaks                       |
| `2xl`  | 48px   | Page-level spacing                         |
| `3xl`  | 64px   | Large gaps, hero sections                  |

### Layout Principles

1. **Sheets have padding** - Content doesn't touch the edges. Use `lg` (24px) minimum padding inside sheets.

2. **The Current Sheet dominates** - It should take 60-70% of available width when Previous Sheet is visible.

3. **Side-sheet is a drawer** - ~30% width, slides in from the right. Has its own internal padding.

4. **Sheet Strip is compact** - Thumbnails are small (80-120px wide), with `sm` gaps between them.

---

## Components

Common UI elements used across all apps.

### Buttons

| Type        | Appearance                           | Usage                          |
|-------------|--------------------------------------|--------------------------------|
| Primary     | Purple bg, white text                | Main actions (Submit, Join)    |
| Secondary   | White bg, purple border/text         | Secondary actions (Cancel, Back) |
| Ghost       | No bg, purple text                   | Tertiary actions, links        |
| Disabled    | Gray bg, muted text                  | Unavailable actions            |

### Score Display

Scores (0-10) are central to workshop apps. Display them consistently:

- **Large scores** (current, focused): 32-48px, handwritten font
- **Grid scores** (in matrix): 20-24px, handwritten font
- **Color coding** (applied to submitted scores, not input buttons):
  - 0-3: Red (`#F44545`)
  - 4-6: Default (black)
  - 7-10: Gold (`#F4B945`)

**Important**: Score input buttons should be neutral (no color hints) to avoid leading participants. Only the selected button highlights. Traffic light colors appear after scores are submitted and revealed.

### Participant Indicators

- **Avatar/Initial circle**: 32-40px, with participant's first initial or photo
- **Name tag**: Clean, readable, shows current participant status
- **Turn indicator**: Subtle highlight (purple border or background tint)

### Sheet Thumbnail (for Sheet Strip)

- Fixed aspect ratio matching full sheet
- Shows miniature version of content
- Current sheet has purple border
- Clickable for navigation

### Side-sheet Toggle

- Icon-based (e.g., notepad icon, or chevron)
- Fixed position at edge of viewport
- Clear open/close state
- Badge for unread notes/actions (if applicable)

---

## States & Feedback

### Interactive States

| State    | Treatment                                  |
|----------|-------------------------------------------|
| Default  | Base appearance                           |
| Hover    | Slight background tint, cursor change     |
| Active   | Pressed appearance (slight scale or shadow) |
| Focus    | Purple outline (for accessibility)        |
| Disabled | Reduced opacity (50%), no interaction     |

### Loading States

- Use skeleton screens for content loading (gray placeholder shapes)
- Subtle pulse animation (not spinning)
- Never block the entire screen if only part is loading

### Feedback

- **Success**: Brief green checkmark or toast, then fade
- **Error**: Red text/border, clear error message near the field
- **Info**: Neutral toast or inline message

---

## Accessibility

Design for everyone. These are minimum requirements.

### Color Contrast

- Text must meet WCAG AA standards (4.5:1 for normal text, 3:1 for large text)
- Don't rely on color alone to convey meaning (add icons or text)
- Test gold (`#F4B945`) on white - may need darkening for text use

### Touch Targets

- Minimum 44x44px for interactive elements on touch devices
- Adequate spacing between targets to prevent mis-taps

### Keyboard Navigation

- All interactive elements must be keyboard accessible
- Visible focus states (purple outline)
- Logical tab order

### Screen Readers

- Meaningful alt text for images
- Proper heading hierarchy (H1 > H2 > H3)
- ARIA labels for icon-only buttons

---

## Responsive Design

### Breakpoints

| Name    | Width    | Typical Device           |
|---------|----------|--------------------------|
| Mobile  | < 640px  | Phones                   |
| Tablet  | 640-1024px | Tablets, small laptops |
| Desktop | > 1024px | Laptops, desktops        |

### Adaptation Strategy

| Element         | Mobile                        | Desktop                      |
|-----------------|-------------------------------|------------------------------|
| Virtual Wall    | Single sheet view, no Previous | Full layout with Previous    |
| Sheet Strip     | Hidden or bottom drawer       | Always visible               |
| Side-sheet      | Full-screen overlay           | Slide-in drawer              |
| Scoring grid    | Scroll horizontal or stack    | Full grid visible            |

### Mobile-First Content

The core workshop experience (scoring, seeing results) must work well on mobile. Facilitators may use desktop for the full view.

---

## Tailwind Implementation

The design system is implemented as a shared Tailwind preset that all apps import.

### File Structure

```
/shared/
  tailwind.preset.js     ← Design system tokens (colors, spacing, fonts, shadows)

/apps/workgroup_pulse/assets/
  tailwind.config.js     ← imports preset + app-specific overrides

/apps/wrt/assets/
  tailwind.config.js     ← imports preset + app-specific overrides

/apps/portal/assets/
  tailwind.config.js     ← imports preset + app-specific overrides
```

### Available Classes

#### Colors

```html
<!-- Backgrounds -->
<div class="bg-surface-wall">        <!-- #FAFAFA - Virtual Wall -->
<div class="bg-surface-sheet">       <!-- #FFFFFF - Current Sheet -->
<div class="bg-surface-sheet-alt">   <!-- #FEFDFB - Paper tint -->

<!-- Text -->
<p class="text-text-dark">           <!-- #151515 - Primary text -->
<p class="text-text-body">           <!-- #A3A3A3 - Body copy -->

<!-- Accents -->
<button class="bg-accent-purple">    <!-- #7245F4 - Primary interactive -->
<span class="text-accent-gold">      <!-- #F4B945 - High scores -->
<span class="text-accent-red">       <!-- #F44545 - Low scores -->

<!-- Semantic shortcuts -->
<button class="bg-interactive">      <!-- Same as accent-purple -->
<span class="text-score-high">       <!-- Same as accent-gold -->
<span class="text-score-low">        <!-- Same as accent-red -->

<!-- Traffic lights -->
<span class="text-traffic-green">    <!-- #22c55e -->
<span class="text-traffic-amber">    <!-- #f59e0b -->
<span class="text-traffic-red">      <!-- #ef4444 -->
```

#### Typography

```html
<!-- Font families -->
<h1 class="font-brand">              <!-- Elegant branding font -->
<span class="font-workshop">         <!-- Handwritten/marker style -->
<p class="font-body">                <!-- Clean body text -->

<!-- Score sizes -->
<span class="text-score-lg">         <!-- 48px - Large focused scores -->
<span class="text-score-md">         <!-- 24px - Grid scores -->
<span class="text-score-sm">         <!-- 20px - Small scores -->
```

#### Spacing

```html
<!-- Sheet-specific spacing -->
<div class="p-sheet-padding">        <!-- 24px padding -->
<div class="gap-section-gap">        <!-- 32px gap -->
<div class="gap-strip-gap">          <!-- 8px gap (sheet strip) -->
```

#### Shadows

```html
<div class="shadow-sheet">           <!-- Subtle sheet shadow -->
<div class="shadow-sheet-receded">   <!-- Deeper shadow for previous sheet -->
<div class="shadow-side-sheet">      <!-- Left-edge shadow for drawer -->
```

#### Z-Index

```html
<div class="z-wall">                 <!-- 0 -->
<div class="z-sheet-previous">       <!-- 10 -->
<div class="z-sheet-current">        <!-- 20 -->
<div class="z-sheet-strip">          <!-- 30 -->
<div class="z-side-sheet">           <!-- 40 -->
<div class="z-modal">                <!-- 50 -->
```

### Example: Sheet Layout

```html
<!-- Virtual Wall container -->
<div class="bg-surface-wall min-h-screen p-section-gap">

  <!-- Sheet Strip -->
  <div class="flex gap-strip-gap z-sheet-strip">
    <div class="w-24 h-16 bg-surface-sheet rounded-sheet shadow-sheet"></div>
    <div class="w-24 h-16 bg-surface-sheet rounded-sheet shadow-sheet border-2 border-accent-purple"></div>
    <div class="w-24 h-16 bg-surface-sheet rounded-sheet shadow-sheet"></div>
  </div>

  <!-- Main area -->
  <div class="flex gap-section-gap mt-section-gap">

    <!-- Previous Sheet -->
    <div class="w-1/4 bg-surface-sheet rounded-sheet shadow-sheet-receded p-sheet-padding z-sheet-previous">
      <h2 class="font-brand text-text-dark">Previous</h2>
    </div>

    <!-- Current Sheet -->
    <div class="flex-1 bg-surface-sheet rounded-sheet shadow-sheet p-sheet-padding z-sheet-current">
      <h2 class="font-brand text-text-dark text-2xl">Current Sheet</h2>
      <span class="font-workshop text-score-lg text-score-high">8</span>
    </div>

  </div>
</div>
```

### Adding App-Specific Tokens

Each app can extend the preset in its own `tailwind.config.js`:

```javascript
// apps/workgroup_pulse/assets/tailwind.config.js
module.exports = {
  presets: [designSystemPreset],
  theme: {
    extend: {
      // App-specific additions
      colors: {
        'pulse-special': '#123456',
      },
    },
  },
}
```

---

## Related Documents

- [brand-colors.md](./brand-colors.md) - Complete color palette
- [design-prompts-canva.md](./design-prompts-canva.md) - Prompts for generating visual concepts
- [/shared/tailwind.preset.js](../shared/tailwind.preset.js) - Tailwind implementation
- App-specific requirements in `apps/*/REQUIREMENTS.md`

---

## Changelog

| Date       | Change                                    |
|------------|-------------------------------------------|
| 2026-02-05 | Score inputs neutral - no color hints     |
| 2026-02-05 | Light theme applied to Pulse app          |
| 2026-02-05 | Added Tailwind preset implementation      |
| 2026-02-05 | Initial design system created             |
