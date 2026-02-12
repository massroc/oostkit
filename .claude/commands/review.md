Review code changes against project conventions and produce actionable feedback.

Usage:
- `/review` — review all uncommitted changes
- `/review <file or directory path>` — review specific files

## Step 1: Gather the code to review

Based on `$ARGUMENTS`:

- **No argument or blank** → run `git diff -- ":(exclude)*.css" ":(exclude)*.js"` and `git diff --cached -- ":(exclude)*.css" ":(exclude)*.js"` to get all uncommitted changes. Also run `git diff --stat` for an overview.
- **File path** → read the specified file(s). If a directory, use Glob to find `.ex`, `.exs`, and `.heex` files within it.

IMPORTANT: Never include compiled assets (`*.css`, `*.js` in `priv/static/assets/`) in the review — they are build artifacts.

## Step 2: Identify affected app and load reference patterns

Determine the app from file paths:
- `apps/portal/` → Portal
- `apps/workgroup_pulse/` → Pulse
- `apps/wrt/` → WRT
- `apps/oostkit_shared/` → Shared lib (review against all consuming apps)
- Multiple apps → note cross-app impact

Read 1-2 existing files in the same area of the codebase for pattern comparison. For example, if reviewing a new context module, read an existing context module in the same app.

## Step 3: Review against checklist

Work through each category below. Only report genuine issues — skip categories where everything is fine.

### Code quality
- Functions return `{:ok, result}` / `{:error, changeset}` consistently (not bare values for writes)
- Pattern matching used instead of conditional chains where appropriate
- No unused variables, imports, or aliases (compiler will catch these as errors in CI)
- Pipe chains are readable (not excessively long or deeply nested)
- Module naming follows Phoenix conventions (`AppWeb.FooLive.Show`, `App.Context`)

### Phoenix / LiveView conventions
- LiveView events use `handle_event/3` with descriptive event names (not generic "click")
- Socket assigns are minimal — no large data structures that don't need to be in assigns
- `phx-` bindings match handler names
- Forms use changesets for validation, not manual checking
- Routes follow RESTful conventions where applicable
- Plugs are in the right pipeline (browser vs api vs admin)

### App-specific rules

**WRT — Tenant isolation:**
- Every `Repo` call that touches tenant data uses `prefix: tenant`
- Tenant is derived from the connection/session, never from user input
- Org admin actions are scoped to their org's tenant
- Super admin queries use the public schema explicitly when needed
- `Triplex.migrate/2` is called for schema changes affecting tenant tables

**Pulse — Real-time:**
- State changes that affect other participants broadcast via PubSub
- `handle_info` handlers for PubSub messages update socket assigns
- Session topic format is consistent (e.g., `"session:#{code}"`)
- No race conditions between concurrent score submissions
- Observer mode correctly excludes observers from scoring

**Portal — Auth:**
- Admin routes are behind `require_super_admin` pipeline
- Cross-app cookie handling doesn't leak tokens
- Magic link and password flows don't interfere
- Sensitive actions check sudo mode (`token_authenticated_at`)

### Testing
- New functions have corresponding tests
- Tests follow TDD patterns: context functions have DataCase tests, web handlers have ConnCase tests
- WRT tests use `create_test_tenant()` and `insert_in_tenant/2` for tenant-scoped data
- Portal tests use `Portal.AccountsFixtures` (not ExMachina)
- Pulse tests use `WorkgroupPulse.Factory`
- Test descriptions are specific ("returns error when timer not started", not "handles error")
- Edge cases are covered (empty state, unauthorized access, concurrent operations)

### Security
- No SQL injection via raw queries (use Ecto parameterised queries)
- No XSS via `raw/1` or `Phoenix.HTML.raw/1` without sanitisation
- User input is validated through changesets before use
- File uploads (if any) are validated for type and size
- Rate limiting on public endpoints
- CSRF protection on form submissions (Phoenix handles this by default, but check custom endpoints)

### Design system (if templates changed)
- Uses semantic tokens: `bg-surface-sheet`, `shadow-sheet`, `text-text-dark`
- Cards use `ring-1 ring-zinc-950/5 rounded-xl`
- Doesn't introduce one-off colors or spacing that bypass the design system
- (For detailed UX review, suggest the user run `/ux-review` separately)

## Step 4: Present the review

### Summary
2-3 sentences: what was reviewed, overall quality assessment, most important finding.

### Issues

Number each issue. For each:

```
### #1 [severity] — Short title

**File:** `path/to/file.ex:42`
**Category:** (from the checklist above)

Description of the problem.

**Fix:**
\`\`\`elixir
# what to change
\`\`\`
```

Severity levels:
- **must fix** — will cause bugs, security issues, data corruption, or CI failure
- **should fix** — violates project conventions, will cause confusion or maintenance issues
- **consider** — minor improvement, style preference, or optimisation

### What's good

Brief list of things done well. Good patterns followed, good test coverage, clean abstractions. This isn't filler — genuine positive feedback helps the author know what to keep doing.

### Pre-ship checklist

- [ ] All issues above addressed (or intentionally deferred with a comment)
- [ ] Tests pass: `cd apps/<app> && docker compose --profile test run --rm <prefix>_test`
- [ ] Compiles without warnings: `docker compose exec <app>_app mix compile --warnings-as-errors`
- [ ] Code formatted: `docker compose exec <app>_app mix format`
- [ ] Ready for `/ship`
