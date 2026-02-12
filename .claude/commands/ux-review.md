Review a LiveView page's layout and suggest UX improvements.

Usage: `/ux-review <file_path>` — pass the path to a LiveView module (e.g., `apps/portal/lib/portal_web/live/user_live/settings.ex`)

If no argument is given, ask the user which file to review.

## Step 1: Read the page and its context

Read the target file: `$ARGUMENTS`

If the file references components, layouts, or helpers that are relevant to the layout,
read those too (but skip compiled assets like `priv/static/assets/*`).

## Step 2: Identify the page type

Classify the page into one of these common types:

| Type | Typical use |
|------|-------------|
| **Settings/Profile** | Multiple independent form sections (account settings, preferences) |
| **Dashboard** | Stats cards, quick links, overview grids |
| **List/Table** | Data table with header actions, search, pagination |
| **Detail/Show** | Single record view with fields/description list |
| **Form** | Single-purpose form (create/edit a resource) |
| **Empty state** | Zero-data placeholder page |
| **Auth** | Login, register, forgot password, etc. |
| **Mixed** | Combination (e.g., dashboard with a table below) |

## Step 3: Audit against known good patterns

For each page type, check against the reference pattern below. Flag anything that
deviates without good reason.

### Reference patterns (OOSTKit design system)

**Card (the universal container):**
```html
<div class="bg-surface-sheet shadow-sheet ring-1 ring-zinc-950/5 rounded-xl">
  <div class="p-6">
    <!-- content -->
  </div>
</div>
```
Variant — card with footer (for forms):
```html
<div class="bg-surface-sheet shadow-sheet ring-1 ring-zinc-950/5 rounded-xl">
  <div class="p-6 space-y-4">
    <!-- fields -->
  </div>
  <div class="flex justify-end border-t border-zinc-200 px-6 py-4">
    <!-- action buttons -->
  </div>
</div>
```
Variant — danger card: use `ring-ok-red-200` instead of `ring-zinc-950/5`.

**Settings / Profile page:**
```html
<div class="space-y-2">
  <.header>Page Title<:subtitle>Subtitle</:subtitle></.header>

  <div class="divide-y divide-zinc-200">
    <!-- repeat for each section -->
    <div class="grid grid-cols-1 gap-x-8 gap-y-6 py-10 md:grid-cols-3">
      <div>
        <h2 class="text-base font-semibold text-text-dark">Section Name</h2>
        <p class="mt-1 text-sm text-zinc-500">Description text.</p>
      </div>
      <div class="bg-surface-sheet shadow-sheet ring-1 ring-zinc-950/5 rounded-xl md:col-span-2">
        <!-- form card with footer -->
      </div>
    </div>
  </div>
</div>
```

**Dashboard page:**
```html
<div class="space-y-8">
  <.header>Dashboard<:subtitle>Overview</:subtitle><:actions><!-- buttons --></:actions></.header>

  <!-- Stats row -->
  <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
    <!-- stat cards -->
    <div class="bg-surface-sheet shadow-sheet ring-1 ring-zinc-950/5 rounded-xl p-6">
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

  <div class="bg-surface-sheet shadow-sheet ring-1 ring-zinc-950/5 rounded-xl overflow-hidden">
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
<div class="mx-auto max-w-2xl">
  <.header>Create Thing<:subtitle>Fill in the details</:subtitle></.header>

  <div class="mt-8 bg-surface-sheet shadow-sheet ring-1 ring-zinc-950/5 rounded-xl">
    <.form ...>
      <div class="p-6 space-y-4">
        <!-- fields -->
      </div>
      <div class="flex justify-end border-t border-zinc-200 px-6 py-4">
        <.button>Save</.button>
      </div>
    </.form>
  </div>
</div>
```

**Auth pages (login, register, forgot password):**
```html
<div class="mx-auto max-w-sm">
  <.header class="text-center">Log In<:subtitle>Welcome back</:subtitle></.header>

  <div class="mt-8 bg-surface-sheet shadow-sheet ring-1 ring-zinc-950/5 rounded-xl">
    <.form ...>
      <div class="p-6 space-y-4">
        <!-- fields -->
      </div>
      <div class="flex justify-end border-t border-zinc-200 px-6 py-4">
        <.button class="w-full">Log In</.button>
      </div>
    </.form>
  </div>

  <p class="mt-6 text-center text-sm text-zinc-500">
    <!-- secondary links (register, forgot password) -->
  </p>
</div>
```

### Common issues to check for

1. **No card containment** — forms/tables/content floating without a card wrapper
2. **Redundant container** — page adds `max-w-4xl` when the app layout already provides it
3. **Missing section descriptions** — headings without explanatory subtitle text
4. **Unbalanced grid** — 2-column grid where one column has much less content
5. **Inconsistent spacing** — mixing arbitrary margin/padding instead of using `space-y-*` or `gap-*`
6. **Tables outside cards** — tables should be inside a card with `overflow-hidden`
7. **Buttons not in card footer** — form submit buttons should be in a `border-t` footer strip
8. **Missing empty state** — list pages with no handling for zero items
9. **Wrong container width** — form pages that are too wide (should be `max-w-2xl` or `max-w-sm`)
10. **Centered headers on non-auth pages** — `text-center` on headers is typically only for auth pages

### Design system tokens to prefer

- Surfaces: `bg-surface-sheet`, `bg-surface-sheet-secondary`, `bg-surface-wall`
- Shadows: `shadow-sheet`, `shadow-sheet-lifted`
- Card border: `ring-1 ring-zinc-950/5`
- Danger border: `ring-1 ring-ok-red-200`
- Text: `text-text-dark` (headings), `text-zinc-500` or `text-zinc-600` (secondary)
- Section heading: `text-base font-semibold text-text-dark`
- Rounding: `rounded-xl` for cards, `rounded-lg` for smaller elements

## Step 4: Present findings

Output a structured review:

1. **Page type**: What kind of page this is
2. **Current layout**: Brief description of what's there now
3. **Issues found**: Numbered list of specific problems (reference the checklist above)
4. **Suggested layout**: Show the concrete HEEx markup for the improved version
5. **What changed**: Bullet list of structural changes (no logic changes)

Be specific — show actual class names and markup, not vague suggestions. The user
should be able to look at the diff and decide whether to apply it.

If the page already follows the patterns well, say so and note any minor tweaks.
Do NOT invent problems that don't exist.
