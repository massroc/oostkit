Produce a solution design for a feature — architecture decisions, affected files, data model, module signatures, test plan, and implementation order.

Usage: `/design <feature description>`

If no argument is given, ask the user what feature to design.

## Step 1: Identify the affected app

Parse `$ARGUMENTS` to identify the target app:

- Mentions "portal", "auth", "login", "admin", "landing", "registration" → Portal
- Mentions "pulse", "workshop", "scoring", "session", "timer", "facilitator", "action plan" → Workgroup Pulse
- Mentions "wrt", "referral", "campaign", "nomination", "tenant", "org", "round", "seed group" → WRT
- Mentions "shared", "header", "component" → oostkit_shared (cross-app)
- Ambiguous → ask the user

## Step 2: Load existing design context

Read these documents (skip any that don't exist):

1. The affected app's `SOLUTION_DESIGN.md` — current architecture
2. The affected app's `TECHNICAL_SPEC.md` — current implementation patterns
3. The affected app's `REQUIREMENTS.md` — what we're building toward
4. `docs/architecture.md` — platform-wide architecture

## Step 3: Study existing patterns

Find 1-2 existing modules most similar to what we're building. Use Glob and Grep to locate them, then read them. This gives us concrete patterns to follow, not reinvent.

**App-specific places to look:**

**Portal:**
- Contexts: `apps/portal/lib/portal/` (e.g., `accounts.ex`, `tools.ex`)
- LiveViews: `apps/portal/lib/portal_web/live/`
- Controllers: `apps/portal/lib/portal_web/controllers/`
- Router: `apps/portal/lib/portal_web/router.ex`

**Workgroup Pulse:**
- Contexts: `apps/workgroup_pulse/lib/workgroup_pulse/` (e.g., `sessions.ex`, `scoring.ex`)
- LiveViews: `apps/workgroup_pulse/lib/workgroup_pulse_web/live/`
- PubSub: look for `Phoenix.PubSub.broadcast` and `handle_info` patterns
- Router: `apps/workgroup_pulse/lib/workgroup_pulse_web/router.ex`

**WRT:**
- Contexts: `apps/wrt/lib/wrt/` (e.g., `campaigns.ex`, `nominations.ex`)
- Controllers: `apps/wrt/lib/wrt_web/controllers/`
- Multi-tenancy: look for `prefix: tenant` on Repo calls
- Router: `apps/wrt/lib/wrt_web/router.ex`

## Step 4: Produce the design

### 1. Architecture decision

One paragraph explaining the chosen approach and why. If there were alternatives considered, briefly note why they were rejected.

### 2. Affected files

| File | Action | What changes |
|------|--------|-------------|
| `apps/.../lib/...` | New / Modified | Brief description |

Include migrations, test files, and config changes.

### 3. Data model changes

If the feature needs schema changes:
- New tables/fields with types and constraints
- Migration plan (especially for WRT: does it need `Triplex.migrate/2` for tenant schemas?)
- Index recommendations

If no schema changes needed, say so.

### 4. Module signatures

For each new or modified context function, show the signature and return type:

```elixir
@spec pause_timer(Session.t()) :: {:ok, Session.t()} | {:error, Ecto.Changeset.t()}
def pause_timer(%Session{} = session) do
  # ...
end
```

Follow existing conventions:
- Return `{:ok, result}` / `{:error, changeset}` for writes
- Return the struct or `nil` for reads
- WRT context functions that touch tenant data take `tenant` as first arg
- Pulse contexts that broadcast take the topic and use `Phoenix.PubSub.broadcast/3`

### 5. LiveView / Controller design

For LiveView features:
- Socket assigns needed (list with types)
- Events handled (`handle_event` names and params)
- PubSub topics subscribed/broadcast (Pulse)
- Component slots/attrs if new components are needed

For controller features:
- Routes (verb, path, action)
- Plugs needed in the pipeline

### 6. App-specific sections

**WRT — Tenant isolation:**
- Which Repo calls need `prefix: tenant`?
- Any cross-tenant queries? (These should be rare and explicit)
- Does the org admin / super admin boundary change?

**Pulse — Real-time sync:**
- What PubSub topics are involved?
- What events are broadcast?
- How do concurrent updates resolve? (Last-write-wins? Merge? CRDTs?)
- Socket assigns that change on broadcast

**Portal — Auth / Cross-app:**
- Does this affect the cross-app cookie or validation API?
- Admin-only or all users?
- Any new role checks needed?

Only include the section relevant to the affected app.

### 7. Test plan

For each module/function, list the test cases needed:

```
## Context: Sessions.pause_timer/1
- pauses a running timer → returns {:ok, session} with paused_at set
- returns error if timer not started
- returns error if timer already paused
- broadcasts "timer_paused" to session topic
```

Include the Docker command to run the relevant tests:
```bash
cd apps/<app>
docker compose --profile test run --rm <prefix>_test mix test test/path/to/test.exs
```

### 8. Implementation order

Numbered list of steps, each one a logical commit:

1. Migration + schema changes
2. Context functions + context tests
3. LiveView/controller + integration tests
4. (etc.)

This should follow TDD: tests are written alongside or before implementation at each step.

### 9. CI impact

- Will this trigger CI for other apps? (e.g., changes to `oostkit_shared`)
- Any new env vars needed in CI or production?
- Docker/Dockerfile changes?
- Does `fly.toml` need updating?

If none, say "No CI impact."

## Step 5: Present the design

Output the full design document using the sections above. Be concrete — show actual module names, actual function signatures, actual file paths. The user should be able to hand this to `/qa` for test planning and then start implementing.

If the feature is small enough that a formal design is overkill, say so and provide a lightweight version (affected files + signatures + test plan).
