Analyse requirements for a feature or validate implementation against documented requirements.

Usage: `/ba <feature description or file path>`

If no argument is given, ask the user what feature or file to analyse.

## Step 1: Determine mode and identify the affected app

Parse `$ARGUMENTS` to determine the mode:

- **File path** (contains `/` or ends in `.ex`/`.exs`/`.heex`) → **Implementation audit** mode
- **Everything else** → **Feature analysis** mode

Identify the affected app from the argument:
- `apps/portal/...` or mentions "portal", "auth", "login", "admin", "landing" → Portal
- `apps/workgroup_pulse/...` or mentions "pulse", "workshop", "scoring", "session", "timer", "facilitator" → Workgroup Pulse
- `apps/wrt/...` or mentions "wrt", "referral", "campaign", "nomination", "tenant", "org" → WRT
- Ambiguous → ask the user

## Step 2: Load context

Read these documents (skip any that don't exist):

1. `docs/product-vision.md` — overall product direction
2. `docs/ROADMAP.md` — current status and planned work
3. The affected app's `REQUIREMENTS.md` (e.g., `apps/workgroup_pulse/REQUIREMENTS.md`)
4. `docs/portal-requirements.md` if Portal is the affected app

For **implementation audit** mode, also read the target file(s).

Do NOT read `SOLUTION_DESIGN.md` or `TECHNICAL_SPEC.md` — those are for `/design`, not `/ba`.

## Step 3: Analyse

### Feature analysis mode

1. **Feature summary** — one paragraph describing what the feature does and who it serves
2. **Requirements status** — table showing which existing requirements this feature relates to:

| Requirement | Status | Gap |
|------------|--------|-----|
| (existing requirement) | Covered / Partial / Missing | What's missing |

3. **Roadmap check** — is this feature on the roadmap? If so, what's its current status? If not, where does it fit?
4. **User stories** — 2-5 user stories in the format: _As a [facilitator/participant/admin], I want to [action] so that [benefit]_
5. **Acceptance criteria** — concrete, testable criteria for each user story
6. **Edge cases** — things that could go wrong or need special handling. Be specific to this monorepo:
   - WRT: tenant isolation, multi-org scenarios, magic link expiry, nomination constraints
   - Pulse: concurrent scoring, PubSub race conditions, observer vs participant, session state transitions
   - Portal: auth flows (magic link + password), cross-app cookie, admin vs regular user, tool status states
7. **Open questions** — anything ambiguous that needs a product decision before implementation
8. **Doc impact** — which documentation files would need updating if this feature is built

### Implementation audit mode

1. **Feature identification** — what feature does this code implement?
2. **Requirements mapping** — table comparing each function/handler to documented requirements:

| Function/Handler | Requirement | Status |
|-----------------|-------------|--------|
| `handle_event("save", ...)` | "Users can save..." | Matches / Diverges / Undocumented |

3. **Coverage gaps** — requirements that exist in docs but have no corresponding implementation
4. **Undocumented behaviour** — implementation that exists but isn't captured in requirements (this isn't necessarily bad — flag it for the user to decide)
5. **Consistency check** — does the implementation match how similar features work in the same app?

## Step 4: Present findings

Output a structured report using the sections above. Be specific and actionable — reference exact requirement text, exact function names, exact line numbers.

Keep the tone analytical, not prescriptive. The BA identifies gaps and raises questions; the user decides what to do about them.

If the feature is well-covered by existing requirements with no gaps, say so clearly. Do NOT invent problems.
