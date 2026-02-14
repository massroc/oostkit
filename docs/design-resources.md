# Design Resources & Recommendations

**Context:** You have an established design system (Virtual Wall, paper textures, OOSTKit palette, DM Sans + Caveat), Phoenix LiveView, Tailwind with a shared preset, and Petal Components already integrated. You prefer backend work and want off-the-shelf structure without paying Tailwind UI prices or locking into a theme that doesn’t fit.

This doc summarises options and a practical way to use them.

---

## Strategy in short

- **Don’t adopt a full theme.** Use components and templates for **structure and patterns** (markup, layout, behaviour), then restyle with your tokens (`bg-surface-sheet`, `text-ink-blue`, `accent-purple`, etc.).
- **Maximise what you already have:** Petal is in the stack and themed; use more of it before adding new systems.
- **Prefer “copy and adapt” over “install and theme.”** Copy HTML/HEEx, swap Tailwind classes to your preset, wrap in your components. You keep full control and no ongoing subscription.

---

## Options (by cost and fit)

### 1. Petal Components (already in use) — **free tier**

You already use Petal (Button, Field, Form, Input, Link) with OOSTKit brand mapping in the preset.

- **What it gives you:** 100+ LiveView/HEEx components (modals, dropdowns, cards, tables, alerts, etc.), all Tailwind-based and themable via your config.
- **Cost:** Free for the open-source library. Petal Pro (starter/boilerplate with auth, etc.) is paid (~$299/yr single project).
- **Recommendation:** Before paying elsewhere, **browse the full Petal component list** and use more of the free set (e.g. Modal, Dropdown, Card, Table, Alert). Your preset already maps Petal’s semantic colours to OOSTKit; new components will pick that up. Use the free Petal Components **Figma kit** (if still offered) for layout reference only; implement in LiveView with your design system.

**Action:** In each app, check [Petal Components docs](https://hexdocs.pm/petal_components/readme.html) and add imports for any component you need (e.g. `PetalComponents.Modal`, `PetalComponents.Card`). Style overrides via class props or your CSS where needed.

---

### 2. Free Tailwind component libraries (copy‑paste, no dependency)

Use these for **markup and layout ideas**, then restyle with your design system. No npm/Hex dependency; you own the code.

| Resource   | What you get | Tailwind | Fit for you |
|-----------|--------------|----------|-------------|
| **Flowbite** | 600+ components, blocks, pages; Figma available | v3 | Copy HTML → convert to HEEx, replace classes with your tokens. Good for forms, tables, modals, nav. |
| **HyperUI**  | Copy‑paste components (accordions, modals, tables, app UI) | v4 (may need small class tweaks for v3) | Same approach: copy structure, restyle. Free, no attribution. |
| **Preline**   | 840+ components, blocks; Figma; some JS for interactivity | Tailwind | Good for layouts and patterns; you’d reimplement behaviour in LiveView (no Alpine/React). |

**Workflow:** Open the component in the browser, copy the HTML, paste into a LiveView/component, then replace their classes with yours (e.g. `bg-white` → `bg-surface-sheet`, `text-gray-900` → `text-ink-blue`, primary buttons → your gradient/primary). You get structure and responsiveness without adopting their look.

**Flowbite + Phoenix:** There is a [flowbite_phoenix](https://hex.pm/packages/flowbite_phoenix) package (newer). Only add it if you want Flowbite’s JS behaviour; otherwise copy‑paste + your styling is enough.

---

### 3. Headless / behaviour-only

For complex behaviour (modals, dropdowns, tabs) without visual opinions:

- **Headless UI** (Tailwind Labs): Unstyled, accessible components. You wrap them (e.g. in a LiveView hook or via Alpine if you use it) and style entirely with your design system. No theme to fight.

Use when you need robust a11y and behaviour and are happy to write the HEEx + Tailwind yourself. Petal already offers Modal/Dropdown etc., so only reach for Headless UI if Petal doesn’t cover a pattern.

---

### 4. Tailwind UI — if you ever want to splurge

- **Cost:** ~$149 USD (one-time) or similar for limited access; full Tailwind UI is more.
- **Use case:** If you later want a “try a few screens” phase, one short subscription, grab the components/pages that match your mental model (dashboard, forms, auth), copy the markup and adapt classes to your preset. Then cancel. Not necessary while Petal + free libraries cover your needs.

---

### 5. Figma: reference, not source of truth

You don’t need an expensive Figma kit to benefit from design resources.

- **Use Figma for:** Layout, hierarchy, and “what should this screen contain?” Use a **simple, generic** dashboard or app kit (Figma Community has free ones) so you’re not fighting someone else’s brand. Sketch once, then implement in LiveView with your design system.
- **Don’t:** Try to pixel‑match a random theme. Your design system (docs/design-system.md) is the source of truth; Figma is inspiration.
- **Petal:** If Petal still provides a Figma kit, use it to see what components exist and how they’re intended to be composed; then build in code with your colours and typography.

---

## Recommended order of operations

1. **Use more Petal (free)**  
   Add Modal, Card, Table, Alert, etc., where they fit. Your preset already themes them. Reduces the need for net-new components.

2. **Use one free Tailwind library as a “pattern mine”**  
   Pick one (e.g. **Flowbite** or **HyperUI**). When you need a pattern (e.g. settings page layout, table with actions, auth card), copy the HTML, convert to HEEx, replace classes with your tokens. No commitment, no subscription.

3. **Keep design system as single source of truth**  
   Any new component should use your colours, type scale, spacing, and sheet/card language. That way “trying a few” means trying a few **structures**, not a few full themes.

4. **Figma only when you want to think in layout**  
   Use a minimal dashboard/app kit for wireframing or clarifying a flow; then implement with your system and Petal/free components.

---

## Summary table

| Goal                         | Option              | Cost   | Action |
|-----------------------------|---------------------|--------|--------|
| More components in your stack | Petal (more components) | Free   | Add Petal Modal, Card, Table, etc.; style with preset. |
| New patterns / layouts      | Flowbite or HyperUI | Free   | Copy HTML → HEEx, swap to your Tailwind tokens. |
| Complex behaviour + a11y    | Headless UI         | Free   | Use where Petal doesn’t fit; style yourself. |
| “Try before commit” premium | Tailwind UI         | ~$149+ | Optional short sub; grab patterns; restyle with preset. |
| Layout / flow thinking      | Any simple Figma kit | Free  | Reference only; implement in LiveView + your system. |

Your design system and Petal integration already do the hard part (consistent language and theming). The main leverage is: **reuse structure from free libraries and Petal, and always restyle into your system** so you’re not maintaining a third-party theme. That keeps design effort low and avoids the “try five WordPress themes” trap, because you’re only trying structures and patterns, not whole visual themes.
