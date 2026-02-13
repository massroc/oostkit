Audit pages, components, and templates for web accessibility against WCAG 2.2 Level AA.

Usage:
- `/accessibility <file path>` — audit a specific LiveView, component, or template
- `/accessibility audit <app>` — accessibility survey across an entire app
- `/accessibility forms <app>` — focused audit of all forms in an app

If no argument is given, ask the user which file or app to review.

## Step 1: Determine mode and gather code

Parse `$ARGUMENTS`:

- **File path** → **Page audit** mode: read the specified file
- **"audit" followed by app name** → **App audit** mode: scan templates across the app
- **"forms" followed by app name** → **Forms audit** mode: focused review of all forms

Identify the affected app:
- `apps/portal/` → Portal
- `apps/workgroup_pulse/` → Pulse
- `apps/wrt/` → WRT
- `apps/oostkit_shared/` → Shared components

## Step 2: Load context

Read these files for the affected app:
- The target file(s) from step 1
- The app's `core_components.ex` — how `<.input>`, `<.button>`, `<.modal>`, `<.flash>`, `<.error>` are built
- The app's root layout (`root.html.heex`) — `<html lang>`, skip links, landmarks
- The app's app layout (`app.html.heex`) — navigation, landmarks, heading structure
- `apps/oostkit_shared/lib/oostkit_shared/components.ex` if shared components are used

For **app audit** mode, Glob for:
- All templates: `apps/<app>/lib/<app>_web/**/*.heex`
- All LiveView modules: `apps/<app>/lib/<app>_web/live/**/*.ex`

## Step 3: Analyse against checklist

Work through each category below. Only report genuine issues — skip categories where everything is fine.

### Structure and semantics (WCAG 1.3.1, 2.4.1, 2.4.2, 2.4.6)

| Check | Requirement |
|-------|-------------|
| `<html lang="en">` | Set in root layout — tells assistive tech the page language |
| Single `<h1>` per page | Each page/view has exactly one `<h1>` describing the page topic |
| Heading hierarchy | No skipped levels (h1 → h3 without h2). Headings describe the content they precede |
| Landmarks | `<main>`, `<nav>`, `<header>`, `<footer>` used correctly. Multiple `<nav>` elements have `aria-label` |
| Skip link | "Skip to main content" link exists as first focusable element in root layout |
| Page title | `assign(:page_title, ...)` is set in every LiveView `mount/3` and `handle_params/3` |
| Lists | Groups of related items use `<ul>`/`<ol>`, not styled `<div>`s |
| Tables | Data tables use `<th>` with `scope`. No tables for layout |

### Keyboard and focus (WCAG 2.1.1, 2.1.2, 2.4.3, 2.4.7, 2.4.11)

| Check | Requirement |
|-------|-------------|
| All interactive elements keyboard-operable | Buttons, links, form controls are natively focusable. No `phx-click` on `<div>` or `<span>` without `tabindex="0"`, `role`, and keyboard handler |
| Visible focus indicator | All interactive elements have visible focus styles. **Never `outline-none` without a replacement** — check for `focus:ring-*` or `focus-visible:outline-*` |
| Focus not obscured | Focused elements are not hidden behind sticky headers, overlays, or sheets |
| No keyboard traps | Focus can always move away from any component. Modals trap focus but release on close |
| Tab order logical | No `tabindex` values > 0. DOM order matches visual order — check for Tailwind `order-*` mismatches |
| Modal focus management | `<.modal>` traps focus, returns focus to trigger on close, closes with Escape |
| LiveView focus preservation | After DOM patches, focus is not lost. `phx-update="stream"` containers preserve focus. Form submissions move focus to result or first error |

### Forms (WCAG 1.3.5, 3.3.1, 3.3.2, 3.3.3, 3.3.4, 4.1.2)

| Check | Requirement |
|-------|-------------|
| Label association | Every `<input>`, `<select>`, `<textarea>` has a `<label>` via `for`/`id` pairing. Check that `<.input>` component renders this correctly |
| Visible labels | Placeholder text alone is insufficient as a label. Labels must remain visible during and after input |
| Required fields | Indicated visually AND with `required` attribute or `aria-required="true"` |
| Error identification | Errors are in text (not just colour), include the field name, and suggest how to fix |
| Error association | `aria-describedby` links inputs to their error messages. `aria-invalid="true"` set on errored fields |
| Error focus | On form submission with errors, focus moves to first errored field or error summary |
| `autocomplete` | Common fields (name, email, phone, address) use `autocomplete` attribute |
| `phx-debounce` | Text inputs use `phx-debounce` to prevent rapid-fire validation that disorients screen readers |
| Group labels | Radio/checkbox groups use `<fieldset>` with `<legend>` |

### Colour and contrast (WCAG 1.4.1, 1.4.3, 1.4.11)

| Check | Requirement |
|-------|-------------|
| Text contrast | Normal text meets 4.5:1 against background. Large text (18pt+ or 14pt+ bold) meets 3:1 |
| UI component contrast | Buttons, inputs, icons meet 3:1 against adjacent colours |
| Focus ring contrast | Focus indicators meet 3:1 against all possible backgrounds |
| Not colour alone | Error/success/warning states use text and/or icons, not just colour |
| Placeholder contrast | Placeholder text meets 4.5:1 against input background |
| Opacity check | Tailwind opacity modifiers (`text-*-500/70`, `bg-opacity-*`) don't reduce contrast below thresholds |

**OOSTKit design system tokens to verify:**
- `text-text-dark` on `bg-surface-sheet` — must meet 4.5:1
- `text-text-muted` on `bg-surface-sheet` — must meet 4.5:1
- Error text on form backgrounds — must meet 4.5:1
- Focus ring colour on all background variants — must meet 3:1

### Images and icons (WCAG 1.1.1)

| Check | Requirement |
|-------|-------------|
| Informative images | `<img>` tags have meaningful `alt` text describing the content |
| Decorative images | `<img>` with `alt=""` (not missing `alt`). SVG icons with `aria-hidden="true"` |
| Icon-only buttons | Buttons with only an icon have `aria-label` or visually hidden text (Tailwind `sr-only` class) |
| SVG accessibility | Standalone informative SVGs have `role="img"` and `aria-label`. Inline SVGs use `currentColor` for forced-colours compatibility |

### Dynamic content and LiveView (WCAG 4.1.3, 1.3.1)

| Check | Requirement |
|-------|-------------|
| Flash messages | `<.flash>` renders with `role="alert"` (for errors) or `role="status"` (for info) |
| Live regions | `aria-live="polite"` containers exist in the DOM before content is injected |
| Loading states | `phx-loading` states communicated via `aria-busy="true"` or `role="status"` message |
| Route changes | Page title updates on `live_navigate` and `live_patch` via `assign(:page_title, ...)` |
| ARIA state management | `aria-expanded` toggles on disclosure/accordion triggers. `aria-selected` on tabs. `aria-current="page"` on active nav items |
| ARIA correctness | No ARIA where native HTML suffices. Referenced `id`s in `aria-labelledby`/`aria-describedby`/`aria-controls` exist in the DOM |

### Responsive and motion (WCAG 1.4.4, 1.4.10, 2.3.1)

| Check | Requirement |
|-------|-------------|
| Text resizable | Text can resize to 200% without content loss. No fixed pixel heights on text containers |
| Reflow at 320px | Content reflows without horizontal scrolling at 320px width (except data tables, maps) |
| Reduced motion | Animations/transitions respect `prefers-reduced-motion`. Use Tailwind `motion-reduce:` variants |
| Target size | Interactive targets are at least 24x24 CSS pixels (WCAG 2.5.8) |

### App-specific accessibility

**Portal — Auth forms:**
- Login/register forms have proper label association and error handling
- Magic link flow communicates status changes to screen readers
- Admin dashboard has proper heading hierarchy and landmark structure
- Settings page sections are navigable via headings

**Pulse — Workshop interface:**
- Carousel navigation is keyboard-operable (arrow keys between slides)
- Scoring grid is navigable via keyboard (consider `role="grid"` with arrow key navigation)
- Timer state changes are announced via live region
- Observer/participant mode switch is communicated to assistive tech
- Sheet components (`<.sheet>`) have proper `role="dialog"` and focus management
- Real-time score updates announce changes without stealing focus

**WRT — Multi-step flows:**
- Campaign creation wizard has proper step indication and progress communication
- Nomination forms have clear labels and error recovery
- Tenant-scoped data tables have proper `<th>` associations
- Admin role switching is communicated to assistive tech

## Step 4: Present the review

### Summary
2-3 sentences: what was reviewed, overall accessibility posture, most important finding.

### Issues

Number each issue. For each:

```
### #1 [severity] — Short title

**File:** `path/to/file.ex:42` (or `.heex`)
**Category:** (from checklist above)
**WCAG:** SC [number] Level [A/AA]

Description of the accessibility barrier.

**Impact:** Who is affected and how (keyboard users, screen reader users, low vision users, etc.).

**Fix:**
```heex
<!-- recommended change -->
```
```

Severity levels:
- **must fix** — blocks access for some users: missing labels, keyboard traps, no alt text, broken focus
- **should fix** — degrades experience: poor heading hierarchy, missing live regions, weak contrast
- **consider** — enhancement: better ARIA patterns, improved focus order, motion reduction

### What's solid

Brief list of accessibility measures already in place. Good semantic structure, proper component usage, etc.

### Verification steps

For each finding, suggest how to verify the fix:
- Keyboard test: describe the tab/enter/escape sequence to verify
- Screen reader test: what announcement to listen for (NVDA/VoiceOver)
- Visual test: what to check at 200% zoom or with forced colours

### App audit summary (if app audit mode)

| Page/Component | Issues | Worst severity | Top concern |
|---------------|--------|---------------|-------------|
| Login form | 2 | should fix | Missing autocomplete attributes |
| Scoring grid | 3 | must fix | Not keyboard navigable |

Prioritised remediation plan:
1. Must-fix items blocking access
2. Should-fix items degrading experience
3. Consider items for progressive improvement
