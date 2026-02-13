# OOSTKit Design System

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
| **Inactive Sheet** | Hidden (`display: none`); navigable via server-driven carousel |
| **Side-sheet**     | Fixed-position drawer panel for auxiliary content (notes, actions) |
| **Sheet Component** | Reusable `<.sheet>` component that renders paper-textured surfaces |

### Visual Hierarchy

Only the active sheet is visible at any time. Inactive slides are hidden (`display: none`) via the `SheetStack` JS hook — there is no visible "previous sheet" peek. The side-sheet (notes panel) is a fixed-position drawer, not a carousel slide.

```
┌─────────────────────────────────────────────────────────────────────┐
│  VIRTUAL WALL                                                       │
│                                                                     │
│        ┌───────────────────────────────────┐   ┌──────────┐        │
│        │                                   │   │  Side-   │        │
│        │      Active Sheet (960px)         │   │  sheet   │        │
│        │      (centred, full focus)        │   │ (drawer) │        │
│        │                                   │   │  480px   │        │
│        └───────────────────────────────────┘   └──────────┘        │
│                                                                     │
│                          [Floating action buttons]                  │
└─────────────────────────────────────────────────────────────────────┘
```

### Sheet Dimensions

**Reference Product**: Post-it Easel Pad (635mm W × 775mm H)

**Orientation**: Landscape (960px wide)

All sheets use a consistent width:

| Element | Width | Height | Notes |
|---------|-------|--------|-------|
| Main sheet | 960px (fixed) | 100% of container (min 786px) | Fixed width, always centred — fills available height |
| Side sheet (Notes) | 480px | 100% | Fixed-position right panel |

### Sheet Treatments

| Sheet Type     | Size      | Shadow           | z-index | Rotation | Purpose |
|----------------|-----------|------------------|---------|----------|---------|
| Current Sheet  | 960px W, 100% H (min 786px) | `shadow-sheet`   | `z-sheet-current` (5) | -0.2deg  | Active work area, always centred |
| Side-sheet     | 480px W   | `shadow-sheet`   | `z-sheet-side` (2) | +1.2deg  | Notes, beside main |

Sheets lift on hover with transition to `shadow-sheet-lifted`.

### OOSTKit Header

All apps share a consistent header via the `<.header_bar>` component from `OostkitShared.Components` (`apps/oostkit_shared/`). This is an in-umbrella dependency consumed by all three apps, ensuring a single source of truth for the header markup.

**Component API:**
- **`:brand_url`** (string) — URL for the OOSTKit brand link. Defaults to `"/"`.
- **`:title`** (string) — Optional page/app title displayed in the centre (absolutely centered).
- **`:actions`** (slot) — Content for the right side of the header (auth links, user info, etc.).

**Rendered output:**
- **Background**: Dark purple (`bg-ok-purple-900`)
- **Left**: "OOSTKit" brand link (white, links to Portal via `:brand_url`)
- **Centre**: Absolutely centered title text (`pointer-events-none absolute inset-x-0 text-center font-brand text-2xl font-semibold text-ok-purple-200`). In Portal, shows the current page title (e.g., "Dashboard"). In Pulse/WRT, shows the app name.
- **Right**: `:actions` slot for app-specific content (e.g., Sign Up + Log In buttons, user email, Settings link)
- **Below**: Magenta-to-purple gradient brand stripe (`.brand-stripe`, 3px), rendered by the component

The `:brand_url` is set per-app: Portal passes `"/"`, Pulse/WRT pass the configurable `:portal_url` (configured in `config/dev.exs` as `http://localhost:4002` and `config/runtime.exs` from `PORTAL_URL` env var, defaulting to `https://oostkit.com`).

Each app's Tailwind config includes the shared library path in its content list so that Tailwind scans the shared component templates for class names.

### Layout Hierarchy

All apps use a **sticky footer layout pattern** on the root layout. The `<body>` element
uses `flex min-h-screen flex-col` and the main content area uses `flex-1` (or
`flex flex-1 flex-col` in Portal) to fill available vertical space. This pushes any
footer to the bottom of the viewport on short-content pages and ensures consistent
full-height layouts without per-page `min-h-screen` wrappers.

```
┌─────────────────────────────────────────────────────────────────────┐
│  Header (52px, dark purple + brand stripe, z-index: 10)             │
├─────────────────────────────────────────────────────────────────────┤
│  MAIN CONTENT AREA (flex-1, fills remaining viewport height)         │
│                                                                     │
│  Pulse: VIRTUAL WALL (bg: #E8E4DF)                                  │
│   ┌─────────────────────────────────┐  ┌───────────────────┐        │
│   │                                 │  │                   │        │
│   │      Current Sheet (z: 5)       │  │  Side-sheet (z:2) │        │
│   │      (centred, in front)        │  │  (behind, right)  │        │
│   │                                 │  │                   │        │
│   └─────────────────────────────────┘  └───────────────────┘        │
│                                                                     │
│                                        [Floating buttons, z: 20]    │
├─────────────────────────────────────────────────────────────────────┤
│  Footer (Portal only: footer_bar with About, Privacy, Contact)       │
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

2. **The Current Sheet dominates** - It is always centred at 960px, with full focus. Inactive slides are hidden, not shown as smaller peeks.

3. **Side-sheet is a drawer** - 480px wide, fixed-position on the right edge. Has its own internal padding.

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
- **Color coding** (traffic light system, applied to submitted scores, not input buttons):
  - **Balance scale** (-5 to +5): Green near 0 (optimal), Amber moderate, Red at extremes
  - **Maximal scale** (0 to 10): Green high, Amber mid, Red low
  - Traffic light colors: green (`#22c55e`), amber (`#f59e0b`), red (`#ef4444`)

**Important**: Score input buttons should be neutral (no color hints) to avoid leading participants. Only the selected button highlights. Traffic light colors appear after scores are submitted and revealed.

### Participant List

- **Name display**: Clean, readable text showing participant name and status
- **Turn indicator**: Subtle highlight (purple border or `...` animation) for the active scorer
- **Facilitator badge**: Identifies the session facilitator
- **Ready indicator**: Checkmark when participant has marked ready

### Notes/Actions Side Panel

- **Peek tab**: 70px wide, fixed-position on right edge of viewport, read-only content preview
- **Expanded panel**: 480px wide, editable, uses `<.sheet variant={:secondary}>`
- **Reveal**: Click peek tab to expand; click outside (backdrop) to dismiss
- **Visible on**: Scoring, summary, and wrap-up slides only

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
| Virtual Wall    | Full-width single sheet       | Centred 960px sheet          |
| Side-sheet      | Full-screen overlay           | Fixed-position 480px drawer  |
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

/apps/oostkit_shared/
  lib/oostkit_shared/
    components.ex        ← Shared Phoenix components (header_bar/1, header/1)

/apps/workgroup_pulse/assets/
  tailwind.config.js     ← imports preset + app-specific overrides

/apps/wrt/assets/
  tailwind.config.js     ← imports preset + app-specific overrides

/apps/portal/assets/
  tailwind.config.js     ← imports preset + app-specific overrides
```

Each app's `tailwind.config.js` includes the `oostkit_shared` library path in its content list so Tailwind scans the shared component templates for class names. In the umbrella structure this is typically `../../apps/oostkit_shared/**/*.ex` (relative to each app's `assets/` directory).

### Available Classes

#### Colors

```html
<!-- Backgrounds -->
<div class="bg-surface-wall">             <!-- #E8E4DF - Virtual Wall (warm taupe) -->
<div class="bg-surface-sheet">            <!-- #FEFDFB - Primary sheet (cream/paper) -->
<div class="bg-surface-sheet-secondary">  <!-- #F5F3F0 - Receded sheets, table headers -->

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
<div class="z-sheet-previous">       <!-- 1 -->
<div class="z-sheet-side">           <!-- 2 -->
<div class="z-sheet-current">        <!-- 5 -->
<div class="z-floating">             <!-- 20 -->
<div class="z-modal">                <!-- 50 -->
```

### Example: Sheet Layout

```html
<!-- Virtual Wall container -->
<div class="bg-surface-wall min-h-screen">

  <!-- Sheet stack (server-driven show/hide via SheetStack JS hook) -->
  <div id="workshop-carousel" phx-hook="SheetStack" data-index={@carousel_index}>

    <!-- Each slide (only the active one is visible) -->
    <div class="sheet-stack-slide">
      <.sheet class="shadow-sheet p-6 w-[960px] h-full">
        <h2 class="font-brand text-text-dark text-2xl">Sheet Title</h2>
        <span class="font-workshop text-score-lg text-score-high">8</span>
      </.sheet>
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
| 2026-02-13 | Doc consistency pass: fixed Available Classes hex values and class names to match `tailwind.preset.js`; corrected z-index scale throughout (was showing old values); updated Sheet Dimensions to 960px landscape; replaced stale "Previous Sheet" references with current show/hide carousel model; updated Components section (Participant List, Notes Panel) to match Pulse implementation; fixed Tailwind config path for umbrella structure. |
| 2026-02-12 | Consolidated `header/1` component into shared library (`OostkitShared.Components`). Header bar centre title bumped from `text-sm font-medium` to `text-2xl font-semibold` for better visual hierarchy. |
| 2026-02-12 | Sticky footer layout pattern applied to Portal and WRT root layouts (`flex min-h-screen flex-col` on body, `flex-1` on main). Portal auth pages use flex centering; settings and admin pages use consistent `px-6 sm:px-8` padding. |
| 2026-02-12 | Header extracted to shared Elixir component library (`apps/oostkit_shared/`). All apps now use `<.header_bar>` from `OostkitShared.Components` instead of inline header markup. Portal adds footer bar. |
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
