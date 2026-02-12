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
| **Sheet Component** | Reusable `<.sheet>` component that renders paper-textured surfaces |

### Visual Hierarchy

```
┌─────────────────────────────────────────────────────────────────────┐
│  VIRTUAL WALL                                                       │
│   ┌─────────────┐   ┌───────────────────────────┐   ┌──────────┐   │
│   │  Previous   │   │                           │   │  Side-   │   │
│   │   Sheet     │   │      Current Sheet        │   │  sheet   │   │
│   │  (smaller,  │   │      (full focus)         │   │ (drawer) │   │
│   │  shadow)    │   │                           │   │          │   │
│   └─────────────┘   └───────────────────────────┘   └──────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Sheet Dimensions

**Reference Product**: Post-it Easel Pad (635mm W × 775mm H)

**Aspect Ratio**: `0.819` (width ÷ height) — portrait orientation

All sheets derive from this single ratio:

| Element | Height | Width | Notes |
|---------|--------|-------|-------|
| Main sheet | 580px | 720px (fixed) | Fixed width, always centred — does not resize with content |
| Side sheet (Notes) | 480px | ~393px | True 0.819 ratio |
| Strip thumbnails | 34px | ~28px | True 0.819 ratio |

### Sheet Treatments

| Sheet Type     | Size      | Shadow           | z-index | Rotation | Purpose |
|----------------|-----------|------------------|---------|----------|---------|
| Current Sheet  | 580px H, 720px W (fixed) | `shadow-sheet`   | 2       | -0.2deg  | Active work area, always centred |
| Side-sheet     | 480px H   | `shadow-sheet`   | 1       | +1.2deg  | Notes, behind main |

Sheets lift on hover with transition to `shadow-sheet-lifted`.

### OOSTKit Header

All apps share a consistent header pattern with a three-zone `justify-between` layout:

- **Background**: Dark purple (`bg-ok-purple-900`)
- **Left**: "OOSTKit" brand link (white, links to Portal via configurable `:portal_url`, defaults to `https://oostkit.com`)
- **Centre**: App name displayed as static text (e.g., "Workgroup Pulse", "Workshop Referral Tool"). In Portal, the centre shows the current page title (e.g., "Dashboard").
- **Right**: App-specific content (e.g., user email, auth links). In apps without user context (e.g., Pulse), a placeholder `<div>` maintains the three-zone spacing.
- **Below**: Magenta-to-purple gradient brand stripe (`.brand-stripe`, 3px)

The `:portal_url` is configured per-app in `config/dev.exs` (hardcoded to `http://localhost:4002`) and `config/runtime.exs` (from `PORTAL_URL` env var), defaulting to `https://oostkit.com` if unset.

This header is implemented in each app's layout files (`app.html.heex`, `admin.html.heex`) or via a shared component (e.g., Pulse's `<.app_header>`).

### Layout Hierarchy

```
┌─────────────────────────────────────────────────────────────────────┐
│  Header (52px, dark purple + brand stripe, z-index: 10)             │
├─────────────────────────────────────────────────────────────────────┤
│  VIRTUAL WALL (bg: #E8E4DF)                                         │
│                                                                     │
│   ┌─────────────────────────────────┐  ┌───────────────────┐        │
│   │                                 │  │                   │        │
│   │      Current Sheet (z: 2)       │  │  Side-sheet (z:1) │        │
│   │      (centred, in front)        │  │  (behind, right)  │        │
│   │                                 │  │                   │        │
│   └─────────────────────────────────┘  └───────────────────┘        │
│                                                                     │
│                                        [Floating buttons, z: 20]    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Color System

See [brand-colors.md](./brand-colors.md) for the complete palette. This section covers *how* to use those colors.

### Theme: Light

All workshop apps use a light theme with warm off-white backgrounds.

### Color Roles

| Role              | Color(s)                  | Usage                                    |
|-------------------|---------------------------|------------------------------------------|
| **Wall Background** | Warm taupe `#E8E4DF`    | Virtual Wall canvas                      |
| **Sheet Surface** | Cream `#FEFDFB`           | Primary sheet (paper texture)            |
| **Sheet Secondary** | Gray `#F5F3F0`          | Receded/background sheets                |
| **Ink**           | Deep blue `#1a3a6b`       | Handwritten content on sheets            |
| **UI Text**       | Dark gray `#333333`       | Chrome text (headers, buttons)           |
| **UI Text Muted** | Medium gray `#888888`     | Secondary chrome text                    |
| **UI Border**     | Light gray `#E0E0E0`      | Chrome borders                           |
| **Primary Accent**| Purple `#7245F4`          | Interactive elements, active states      |
| **Secondary Accent**| Magenta `#BC45F4`       | Highlights, gradients                    |
| **Success/High**  | Gold `#F4B945`            | High scores, positive indicators         |
| **Warning/Low**   | Red `#F44545`             | Low scores, alerts, warnings             |
| **Brand**         | DF Blue `#0095FF` / Green `#42D235` | Logo, brand moments only      |

### Accent Color Placement

Tertiary colors (purple, magenta, gold) appear **only in UI chrome**, never as sheet backgrounds:

| Location | Color | Implementation |
|----------|-------|----------------|
| Header background | Dark purple | `bg-ok-purple-900` across all apps |
| Brand stripe (below header) | Magenta → Purple | Full-width gradient stripe, 3px tall |
| Submit button | Purple → Magenta | Background gradient |
| App icon | Purple | With purple shadow glow |

### Color Application Guidelines

1. **Accent colors are for interaction and meaning** - Don't use purple or magenta as decoration. Reserve them for clickable elements and meaningful highlights.

2. **Gold and Red convey score quality** - Use consistently across all apps. Gold = good/high. Red = needs attention/low.

3. **The sheet surface should feel like paper** - Subtle cream (`#FEFDFB`), with SVG noise texture. Never stark white.

4. **Ink blue for on-sheet content** - All handwritten text (scores, criteria, notes) uses `#1a3a6b`, not black.

5. **Shadows create depth, not darkness** - Use multi-layer drop shadows. Sheets lift on hover.

---

## Typography

### Font Families

| Purpose              | Font                         | Example Usage                     |
|----------------------|------------------------------|-----------------------------------|
| **UI Chrome**        | DM Sans                      | App name, headers, buttons, labels |
| **Workshop Content** | Caveat                       | Scores, criteria, participant names, notes |

```css
font-family: 'DM Sans', system-ui, sans-serif;  /* UI */
font-family: 'Caveat', cursive;                  /* Workshop */
```

### Type Scale - On Sheet (Caveat)

| Element | Size | Weight | Style |
|---------|------|--------|-------|
| Participant names | 18px | 600 | — |
| Criterion names | 17px | 600 | UPPERCASE |
| Parent criterion labels | 11px | 500 | UPPERCASE, 50% opacity |
| Scores | 24px | 700 | — |
| Empty scores | 20px | 700 | 12% opacity |
| Sheet titles (Notes) | 20px | 700 | Underlined, centred |
| Sheet content | 16px | 400 | 70% opacity |

### Type Scale - UI Chrome (DM Sans)

| Element | Size | Weight |
|---------|------|--------|
| App name | 15px | 700 |
| Session name | 14px | 500 |
| Buttons | 13px | 600 |
| Strip label | 11px | 500 |
| Scale labels | 9px | 400 (UPPERCASE) |

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

4. **All phase screens use the `<.sheet>` component** - This formalizes the paper-textured surface as the core UI primitive.

---

## Components

Common UI elements used across all apps.

### Buttons

| Type        | Appearance                           | Usage                          |
|-------------|--------------------------------------|--------------------------------|
| Primary     | Purple→Magenta gradient, white text, shadow | Main actions (Submit) |
| Secondary   | White bg, light border, dark text    | Secondary actions (Skip, Continue) |
| Ghost       | No bg, purple text                   | Tertiary actions, links        |
| Disabled    | Gray bg, muted text                  | Unavailable actions            |

Button styling:
- Font: DM Sans, 13px, weight 600
- Padding: 9px 18px
- Border radius: 8px
- Hover: lift with `translateY(-1px)` + enhanced shadow

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

## Paper Texture

Sheets use a two-layer SVG noise texture for a tactile paper feel:

```css
/* Layer 1: Fractal noise */
background: url("data:image/svg+xml,...feTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4'...") opacity 6%;

/* Layer 2: Turbulence with multiply blend */
background: url("data:image/svg+xml,...feTurbulence type='turbulence' baseFrequency='0.7' numOctaves='3'...") opacity 4.5%, multiply;

/* Plus subtle gradient from top (transparent) to bottom (warm tint) */
```

Secondary sheets use the same approach with darker base color (`#F5F3F0`) and slightly reduced opacity.

See mockup CSS for complete implementation: `/apps/workgroup_pulse/docs/mockups/facilitator-scoring-v8.html`

---

## Shadows

Multi-layer shadows create depth without darkness:

```css
--shadow-sheet:
  0 1px 1px rgba(0,0,0,0.03),
  0 2px 4px rgba(0,0,0,0.04),
  0 4px 8px rgba(0,0,0,0.05),
  0 8px 16px rgba(0,0,0,0.05);

--shadow-sheet-lifted:  /* On hover */
  0 2px 2px rgba(0,0,0,0.03),
  0 4px 8px rgba(0,0,0,0.05),
  0 8px 16px rgba(0,0,0,0.06),
  0 16px 32px rgba(0,0,0,0.07);
```

---

## Changelog

| Date       | Change                                    |
|------------|-------------------------------------------|
| 2026-02-12 | Header consistency update: three-zone layout (OOSTKit link / centered app name / right content), configurable `:portal_url` in Pulse and WRT, Portal centre zone shows page title |
| 2026-02-12 | Consistent OOSTKit header across all apps (Portal, Pulse, WRT): dark purple bg, "OOSTKit" brand link, brand stripe below |
| 2026-02-10 | Design system applied to Portal (semantic tokens, DM Sans, brand stripe, surface/text classes, branded nav header) |
| 2026-02-10 | Design system applied to WRT (semantic tokens, DM Sans, brand stripe, surface/text classes) |
| 2026-02-06 | Added sheet dimensions, paper texture, shadows from mockup |
| 2026-02-06 | Finalized fonts: DM Sans (UI) + Caveat (workshop) |
| 2026-02-06 | Updated color palette with ink-blue, UI colors |
| 2026-02-05 | Score inputs neutral - no color hints     |
| 2026-02-05 | Light theme applied to Pulse app          |
| 2026-02-05 | Added Tailwind preset implementation      |
| 2026-02-05 | Initial design system created             |
