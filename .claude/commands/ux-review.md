Review a page's layout, components, and accessibility against the OOSTKit design system.

Usage: `/ux-review <file_path>` — pass the path to a LiveView module, controller template, or component (e.g., `apps/portal/lib/portal_web/live/user_live/settings.ex`)

If no argument is given, ask the user which file to review.

## Step 0: Take a screenshot

Before reading any code, **take a screenshot** of the actual rendered page using Playwright:

```bash
npx playwright screenshot --browser chromium --full-page --wait-for-timeout 3000 'http://localhost:<port><path>' /tmp/ux-review.png
```

Ports: Portal = 4002, Pulse = 4000, WRT = 4001.

Look at the screenshot first and note your honest visual impression: Does the page look
good? Is there too much whitespace? Are elements proportionate? Do the fields look
the right size? Only THEN proceed to read the code.

If the page requires authentication, check if dev auto-login is enabled. If you can't
screenshot, proceed with code-only review but note the limitation.

## Step 1: Read the page and its context

Read the target file: `$ARGUMENTS`

Determine which app it belongs to:
- `apps/portal/` → Portal (admin pages, auth, landing, dashboard)
- `apps/workgroup_pulse/` → Pulse (workshop, scoring, carousel, sheets)
- `apps/wrt/` → WRT (campaigns, nominations, multi-tenant admin)
- `apps/oostkit_shared/` → Shared component (used by all apps)

If the file references components, layouts, or helpers that are relevant to the review,
read those too. In particular:
- The app's `core_components.ex` if custom components are used
- The app's layout files (`layouts.ex`, `root.html.heex`, `app.html.heex`)
- `apps/oostkit_shared/lib/oostkit_shared/components.ex` if shared components are used

Skip compiled assets (`priv/static/assets/*`).

## Step 2: Identify the page type

Classify the page into one of these types:

### Portal / WRT page types

| Type | Typical use |
|------|-------------|
| **Settings/Profile** | Multiple independent form sections (account settings, preferences) |
| **Dashboard** | Stats cards, quick links, overview grids |
| **List/Table** | Data table with header actions, search, pagination |
| **Detail/Show** | Single record view with fields/description list |
| **Form** | Single-purpose form (create/edit a resource) |
| **Empty state** | Zero-data placeholder page |
| **Auth** | Login, register, forgot password, etc. |
| **Landing/Marketing** | Public-facing landing page with hero, sections, CTAs |
| **Mixed** | Combination (e.g., dashboard with a table below) |

### Pulse page types

| Type | Typical use |
|------|-------------|
| **Lobby** | Session creation or join — standalone, no carousel |
| **Intro slide** | Welcome, How It Works, scale explanations — in carousel |
| **Scoring** | The main scoring grid sheet — turn-based, real-time |
| **Summary** | Traffic-light results, team overview |
| **Wrap-up** | Action planning, notes, export |
| **Side panel** | Notes/actions panel (not a carousel slide — fixed position) |
| **Component** | Reusable component (`<.sheet>`, `<.facilitator_timer>`, etc.) |

## Step 3: Audit against known good patterns

For each page type, check against the reference patterns below. Flag anything that
deviates without good reason.

---

### Shared patterns (all apps)

**OOSTKit header bar** (from `OostkitShared.Components`):
```heex
<.header_bar brand_url={...} title="App Name">
  <:actions>
    <!-- auth links, user info -->
  </:actions>
</.header_bar>
```
- Background: `bg-ok-purple-900`
- Brand stripe rendered automatically below
- Title is absolutely centred, hidden on mobile (`hidden sm:block`)
- `:brand_url` — Portal uses `"/"`, Pulse/WRT use configurable `:portal_url`

**Page-level header** (from `OostkitShared.Components`):
```heex
<.header>
  Page Title
  <:subtitle>Description text</:subtitle>
  <:actions><.button>Action</.button></:actions>
</.header>
```
- `text-2xl font-bold text-text-dark`
- Subtitle: `text-sm text-zinc-600`

**Sticky footer layout** (root layout):
- `<body>` uses `flex min-h-screen flex-col` + `font-brand`
- Main content area uses `flex-1` (or `flex flex-1 flex-col`)
- Footer (Portal only) stays at viewport bottom on short pages

---

### Petal Components — critical defaults to watch

**`<.field>` adds `mb-6` (24px) to every field wrapper.** Inside a grid with `gap-*`,
this stacks: you get the grid gap PLUS the 24px bottom margin. The fix:
- Use `no_margin` on every `<.field>` inside a grid or tight layout
- Let `gap-x-*` and `gap-y-*` control spacing instead

**`<.button>` uses `color` and `variant` attrs, not CSS classes.**
- `color="danger"` — not `class="btn btn-error"`
- `variant="outline"` — not `class="btn-soft"`
- Phantom CSS classes like `btn`, `btn-error`, `btn-soft` do nothing — they don't
  exist in the compiled stylesheet

---

### Portal / WRT reference patterns

**Card (the universal container):**
```html
<div class="rounded-xl bg-surface-sheet p-4 shadow-sheet ring-1 ring-zinc-950/5">
  <!-- content -->
</div>
```
- Standard padding: `p-4` (compact pages, settings) or `p-4 sm:p-6` (spacious pages)
- Gap between stacked cards: `mb-3`
- Danger variant: `ring-ok-red-200` instead of `ring-zinc-950/5`

**Field grid (Flowbite pattern — use for all form layouts):**
```html
<div class="grid grid-cols-6 gap-x-3 gap-y-2">
  <div class="col-span-6 sm:col-span-3">
    <.field ... no_margin />
  </div>
  <div class="col-span-6 sm:col-span-3">
    <.field ... no_margin />
  </div>
  <div class="col-span-6 mt-1">
    <.button size="sm">Save</.button>
  </div>
</div>
```
- Always use `no_margin` on `<.field>` inside grids
- `col-span-6 sm:col-span-3` for half-width field pairs
- `col-span-6` for full-width fields
- Button row gets `mt-1` for slight separation

**Settings / Profile page (card-per-section pattern):**
```html
<div class="mx-auto max-w-xl">
  <h1 class="mb-3 text-lg font-bold text-text-dark">Account Settings</h1>

  <!-- One card per form/concern -->
  <div class="mb-3 rounded-xl bg-surface-sheet p-4 shadow-sheet ring-1 ring-zinc-950/5">
    <h2 class="mb-2 text-sm font-semibold text-text-dark">Section Name</h2>
    <.form ...>
      <div class="grid grid-cols-6 gap-x-3 gap-y-2">
        <!-- fields with no_margin -->
        <!-- button -->
      </div>
    </.form>
  </div>

  <!-- Next section card -->
  <div class="mb-3 rounded-xl bg-surface-sheet p-4 shadow-sheet ring-1 ring-zinc-950/5">
    ...
  </div>
</div>
```
Key rules:
- `max-w-xl` for settings (not `max-w-2xl` or `max-w-4xl`)
- Separate card per form/concern — NOT one giant card with `<hr>` dividers
- Section heading inside card: `text-sm font-semibold`, `mb-2`
- If multiple sibling forms must share a card, put them as siblings (NOT nested)
  with a thin `border-t border-zinc-100` divider between them

**Dashboard page:**
```html
<div class="space-y-8">
  <.header>Dashboard<:subtitle>Overview</:subtitle><:actions><!-- buttons --></:actions></.header>

  <!-- Stats row -->
  <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
    <!-- stat cards -->
    <div class="rounded-xl bg-surface-sheet p-6 shadow-sheet ring-1 ring-zinc-950/5">
      <p class="text-sm text-zinc-500">Label</p>
      <p class="mt-2 text-3xl font-bold text-text-dark">42</p>
    </div>
  </div>

  <!-- Content sections in cards -->
</div>
```

**List / Table page:**
```html
<div class="space-y-6">
  <.header>
    Items
    <:subtitle>Manage your items</:subtitle>
    <:actions><.button>Create</.button></:actions>
  </.header>

  <!-- Optional search/filter bar -->

  <div class="overflow-hidden rounded-xl bg-surface-sheet shadow-sheet ring-1 ring-zinc-950/5">
    <table class="min-w-full divide-y divide-zinc-200">
      <thead class="bg-surface-sheet-secondary">
        <!-- headers -->
      </thead>
      <tbody class="divide-y divide-zinc-100">
        <!-- rows -->
      </tbody>
    </table>
  </div>
</div>
```

**Single form page (create/edit):**
```html
<div class="mx-auto max-w-xl">
  <.header>Create Thing<:subtitle>Fill in the details</:subtitle></.header>

  <div class="mt-4 rounded-xl bg-surface-sheet p-4 shadow-sheet ring-1 ring-zinc-950/5">
    <.form ...>
      <div class="grid grid-cols-6 gap-x-3 gap-y-2">
        <!-- fields with no_margin -->
      </div>
      <div class="mt-3 flex border-t border-zinc-200 pt-3">
        <.button size="sm">Save</.button>
      </div>
    </.form>
  </div>
</div>
```

**Auth pages (login, register, forgot password):**
```html
<div class="mx-auto max-w-sm">
  <.header class="text-center">Log In<:subtitle>Welcome back</:subtitle></.header>

  <div class="mt-4 rounded-xl bg-surface-sheet p-4 shadow-sheet ring-1 ring-zinc-950/5">
    <.form ...>
      <div class="space-y-3">
        <.field ... no_margin />
        <.field ... no_margin />
      </div>
      <div class="mt-3 flex border-t border-zinc-200 pt-3">
        <.button class="w-full">Log In</.button>
      </div>
    </.form>
  </div>

  <p class="mt-4 text-center text-sm text-zinc-500">
    <!-- secondary links (register, forgot password) -->
  </p>
</div>
```

---

### Pulse reference patterns

**Sheet component** (`<.sheet>` from `WorkgroupPulseWeb.CoreComponents`):
```heex
<.sheet>
  <!-- content sits above paper texture pseudo-elements -->
</.sheet>
```
- Inner wrapper has `relative z-[1]` to sit above paper texture
- Default rotation: `-0.2deg` (override via `style` attr)
- `variant={:secondary}` uses `paper-texture-secondary` (notes/side-sheets)
- Shadow is NOT baked in — apply dynamically via `class` attr when needed (e.g., scoring sheet)
- All phase components import it: `import WorkgroupPulseWeb.CoreComponents, only: [sheet: 1]`

**Sheet stack / carousel:**
```html
<!-- Virtual Wall container -->
<div class="bg-surface-wall min-h-screen">
  <!-- Sheet stack with JS hook -->
  <div id="workshop-carousel" phx-hook="SheetStack" data-index={@carousel_index}>
    <!-- Each slide -->
    <div class="sheet-stack-slide">
      <.sheet class="shadow-sheet p-6 w-[960px] h-full">
        <!-- slide content -->
      </.sheet>
    </div>
  </div>
</div>
```
- `SheetStack` hook toggles `stack-active` / `stack-inactive` classes
- Server controls position via `data-index` — hook reads on `updated()`
- Active slide: `display: flex`. All others: `display: none`
- Standard slide width: `960px`
- Lobby is a standalone single slide (no hook, no carousel)

**Scoring grid (on-sheet content):**
- Participant names: `font-workshop text-participant` (Caveat 18px, weight 600)
- Criterion labels: `font-workshop text-criterion uppercase` (17px, weight 600)
- Parent criterion labels: `font-workshop text-criterion-parent uppercase opacity-50` (11px)
- Scores: `font-workshop text-score-md` (24px) or `text-score-lg` (48px for focused)
- Empty scores: `font-workshop text-score-sm opacity-[0.12]` (20px)
- Ink colour for all on-sheet text: `text-ink-blue` (`#1a3a6b`)

**Score colour coding** (applied after submission, not during input):
- 0-3: `text-traffic-red` or `text-accent-red`
- 4-6: default (no special colour)
- 7-10: `text-traffic-green` or `text-accent-gold`

**Notes/Actions side panel:**
- Fixed position, right edge of viewport, z-20
- Peek tab: 70px wide, read-only preview (slides 4-6)
- Revealed: 480px wide, editable
- Uses `<.sheet variant={:secondary}>` for paper texture

**Floating action buttons:**
- Viewport-fixed, aligned to the 960px sheet width
- Always visible at bottom of sheet area — no scrolling needed
- Hidden when browsing slides outside current phase
- Primary button: purple-to-magenta gradient, white text
- Secondary button: white bg, light border, dark text

---

## Step 4: Check against issue checklists

Work through the relevant checklist. Only flag genuine issues.

### Visual density & proportion (CHECK FIRST)

These are the most impactful issues. Check them before token correctness.

1. **Petal `mb-6` stacking** — `<.field>` without `no_margin` inside a grid. Each field adds 24px bottom margin ON TOP of the grid gap. Fix: add `no_margin` to every `<.field>` inside a grid or tight layout.
2. **Container too wide for content** — count the fields per card. 2-4 fields → `max-w-xl`. 5-8 fields → `max-w-2xl`. 8+ fields → `max-w-4xl`. A settings page with 2 fields in a `max-w-4xl` container will always look empty.
3. **Excessive section spacing** — `py-10`, `space-y-8`, `gap-6` between sections with only 1-2 fields each. Use `mb-3` between cards, `gap-y-2` inside grids for compact pages.
4. **Generous card padding** — `p-6 sm:p-8` on cards with 2-3 small fields creates visible whitespace. Use `p-4` for compact pages, `p-4 sm:p-6` only for spacious content.
5. **Empty grid columns** — a field at `col-span-3` with nothing beside it leaves a visible gap. Either pair fields, make the field full-width, or put a related action button in the empty column.
6. **Button row wasting a full grid row** — if a button can sit inline with a field (e.g. "Change Email" next to email input), use `items-end` on the grid and put the button in the adjacent column.

### Layout & structure issues

7. **No card containment** — forms/tables/content floating without a card wrapper
8. **Redundant container** — page adds `max-w-4xl` when the app layout already provides it
9. **Inconsistent spacing** — mixing arbitrary margin/padding instead of `gap-*`
10. **Tables outside cards** — tables should be inside a card with `overflow-hidden`
11. **Missing empty state** — list pages with no handling for zero items
12. **Centered headers on non-auth pages** — `text-center` on headers is only for auth pages

### Form & component issues

13. **Nested `<.form>` tags** — `<.form>` inside another `<.form>` is invalid HTML. Browsers strip the inner `<form>` tag, so its `phx-submit`/`phx-change` won't fire and `#id` selectors won't find it. Fix: restructure as sibling forms within a shared card container, or use a single form with combined handling.
14. **Inconsistent button variants** — non-destructive buttons should all use the same style. Don't mix solid primary with outline primary for actions at the same level. Exception: secondary/cancel actions can be outline alongside a solid primary.
15. **Phantom Petal CSS classes** — using `class="btn btn-error btn-soft"` on `<.button>`. Petal buttons use `color` and `variant` attrs, not CSS class strings. These classes don't exist in the stylesheet and do nothing.
16. **Missing `no_margin` in grids** — any `<.field>` inside a `grid` without `no_margin` will have excessive vertical spacing.

### Design system token issues

17. **Raw colour values** — using `#7245F4` or `bg-purple-600` instead of semantic tokens (`bg-accent-purple`, `bg-ok-purple-600`)
18. **Wrong surface token** — using `bg-white` instead of `bg-surface-sheet`, or `bg-gray-50` instead of `bg-surface-sheet-secondary`
19. **Wrong text token** — using `text-gray-900` instead of `text-text-dark`, or `text-gray-400` instead of `text-zinc-500`
20. **Wrong shadow** — using generic `shadow-lg` instead of `shadow-sheet` or `shadow-sheet-lifted`
21. **Wrong rounding** — using `rounded-md` on cards (should be `rounded-xl`), or `rounded-xl` on sheet content (sheets use `rounded-sheet` = 2px)
22. **Missing font family** — UI text without `font-brand`, or workshop content without `font-workshop`
23. **Wrong score sizing** — scores not using `text-score-lg`/`text-score-md`/`text-score-sm`
24. **Wrong z-index** — ad-hoc `z-10` instead of semantic `z-sheet-current`, `z-floating`, `z-modal`

### Shared component issues

25. **Inline header instead of `<.header>`** — custom `<h1>` markup where `<.header>` from shared lib should be used
26. **Inline header bar** — app-specific header markup instead of `<.header_bar>` from `OostkitShared.Components`
27. **Inline icons** — SVG icons instead of `<.icon name="hero-...">` from shared lib
28. **Missing flash group** — page without `<.flash_group flash={@flash} />`
29. **Duplicate shared component** — app defines a component that already exists in `OostkitShared.Components`

### Pulse-specific issues

30. **Sheet without `<.sheet>`** — paper-textured surface built with manual classes instead of the component
31. **Wrong font on sheet content** — UI font (`font-brand` / DM Sans) used for on-sheet text (should be `font-workshop` / Caveat)
32. **Score input with colour hints** — score buttons should be neutral during input; colour only after submission
33. **Carousel logic in JS** — `SheetStack` hook should only show/hide; server must be sole authority on `data-index`
34. **Side panel as carousel slide** — notes/actions panel should be fixed-position, not a carousel slide
35. **Missing sheet rotation** — sheets should have slight rotation (default `-0.2deg`)

### Accessibility issues

36. **Colour contrast** — text on background fails WCAG AA (4.5:1 normal text, 3:1 large text). Watch especially: gold (`#F4B945`) on white, `text-zinc-500` on light backgrounds
37. **Small touch targets** — interactive elements below 44x44px on touch devices
38. **Missing ARIA labels** — icon-only buttons without `aria-label`
39. **No visible focus state** — interactive elements without a visible focus ring (should be purple outline)
40. **Heading hierarchy** — skipped heading levels (e.g., `<h1>` to `<h3>` with no `<h2>`)
41. **Colour-only meaning** — relying solely on colour to convey information (e.g., score quality) without text or icon backup

### Responsive design issues

42. **Fixed width without responsive fallback** — `w-[960px]` without a mobile alternative
43. **Missing mobile adaptation** — Pulse sheet carousel should show single-sheet view on mobile (no Previous Sheet)
44. **Side panel on mobile** — should be full-screen overlay, not inline drawer
45. **Grid collapse** — multi-column grid without `grid-cols-1` base for mobile

---

## Design system token reference

Use these tokens. Flag any raw values that should use a token instead.

### Surfaces
- `bg-surface-wall` — `#E8E4DF` (warm taupe, virtual wall background)
- `bg-surface-sheet` — `#FEFDFB` (cream paper, primary sheets and cards)
- `bg-surface-sheet-secondary` — `#F5F3F0` (receded sheets, table headers, empty states)

### Text
- `text-text-dark` — `#151515` (headings, primary text)
- `text-zinc-500` / `text-zinc-600` — secondary/muted text
- `text-ink-blue` — `#1a3a6b` (on-sheet handwritten content, Pulse only)

### Brand colour scales (Petal Components mapped)
- `ok-purple` → `primary` (buttons, links, interactive elements)
- `ok-magenta` → `secondary` (highlights, gradients)
- `ok-gold` → `warning` (high scores, attention)
- `ok-red` → `danger` (low scores, alerts, danger zones)
- `ok-blue` → `info`
- `ok-green` → `success`

### Shadows
- `shadow-sheet` — subtle multi-layer (cards, current sheets)
- `shadow-sheet-lifted` — enhanced on hover
- `shadow-sheet-receded` — deeper (previous sheets)
- `shadow-side-sheet` — left-edge (drawer panels)

### Rounding
- `rounded-xl` — cards (Portal/WRT)
- `rounded-sheet` — 2px (paper-like, Pulse sheets)
- `rounded-button` — 8px (buttons)

### Typography
- `font-brand` — DM Sans (all UI chrome: headers, buttons, labels)
- `font-workshop` — Caveat (on-sheet content: scores, criteria, participant names)
- `text-score-lg` — 48px (large focused scores)
- `text-score-md` — 24px (grid scores)
- `text-score-sm` — 20px (small/empty scores)
- `text-participant` — 18px (participant names)
- `text-criterion` — 17px (criterion labels)

### Z-index scale
- `z-wall` — 0
- `z-sheet-previous` — 1
- `z-sheet-side` — 2
- `z-sheet-current` — 5
- `z-floating` — 20 (FABs)
- `z-modal` — 50

### Spacing
- `p-sheet-padding` — 24px (inside sheets)
- `p-sheet-padding-sm` — 20px (compact sheets)
- `gap-section-gap` — 32px (between major sections)

### Interactive states
- Hover: slight background tint, cursor change; sheets lift with `shadow-sheet-lifted`
- Focus: purple outline for keyboard navigation
- Active: slight scale or shadow reduction
- Disabled: 50% opacity, no pointer events

---

## Step 5: Present findings

Output a structured review:

1. **App & page type**: Which app, what kind of page
2. **Screenshot impression**: What you actually see — is the density right? Does it
   look like a professional app or does it have obvious visual problems? Be honest,
   not diplomatic. If it looks bad, say so.
3. **Issues found**: Numbered list referencing the checklists above, ordered by visual
   impact (density/proportion issues FIRST, then structural, then tokens). For each:
   - Issue number and title
   - File and line
   - What's wrong
   - Concrete fix (show the actual class names or markup)
4. **Accessibility notes**: Any a11y issues from the checklist, with specific fixes
5. **Suggested layout**: Show the concrete HEEx markup for the improved version (only
   if structural changes are needed — skip for minor token swaps). Use the Flowbite
   field grid pattern with `no_margin` fields as the baseline.
6. **What changed**: Bullet list of changes (structural and token-level, no logic changes)

Be specific — show actual class names and markup, not vague suggestions. The user
should be able to look at the diff and decide whether to apply it.

**Do NOT say the page "follows patterns well" if it has whitespace or proportion
problems.** Token correctness is secondary to visual quality. A page with all the
right design tokens but terrible spacing is NOT a good page.
