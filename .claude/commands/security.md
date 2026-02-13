Audit code for security vulnerabilities with high-confidence, low-noise findings.

Usage:
- `/security` — review all uncommitted changes for security issues
- `/security <file or directory>` — audit specific files or modules
- `/security audit <app>` — security posture review for an entire app

If no argument is given, default to reviewing uncommitted changes.

## Step 1: Determine mode and gather code

Parse `$ARGUMENTS`:

- **Blank** → **Change review** mode: run `git diff` and `git diff --cached` (excluding `*.css`, `*.js`)
- **File/directory path** → **Module audit** mode: read the specified files (Glob for `.ex`, `.exs`, `.heex` if directory)
- **"audit" followed by app name** → **App audit** mode: scan across the app

Identify the affected app from file paths:
- `apps/portal/` → Portal
- `apps/workgroup_pulse/` → Pulse
- `apps/wrt/` → WRT
- `apps/oostkit_shared/` → Shared (review impact on all consuming apps)

## Step 2: Load security context

Read these files for the affected app:
- The app's `router.ex` — pipelines, plugs, route definitions
- The app's `endpoint.ex` — session config, plug pipeline, CSP headers
- The app's `.sobelow-conf` — what's already been checked/excluded
- `config/config.exs` and `config/runtime.exs` — secrets, session config, force_ssl

For **app audit** mode, also Glob for:
- All context modules: `apps/<app>/lib/<app>/*.ex`
- All LiveView modules: `apps/<app>/lib/<app>_web/live/**/*.ex`
- All controller modules: `apps/<app>/lib/<app>_web/controllers/**/*.ex`

## Step 3: Analyse against checklist

Work through each category below. **Only report findings where you are >80% confident of actual exploitability.** Skip categories where everything is fine. Do NOT report theoretical issues, style concerns, or low-impact findings.

### Injection

| Pattern | Severity | What to check |
|---------|----------|---------------|
| `fragment("#{` | CRITICAL | String interpolation in Ecto fragment — must use `fragment("... ? ...", ^var)` |
| `Ecto.Adapters.SQL.query` with `#{}` | CRITICAL | Raw SQL with interpolation — must use `$1` params |
| `raw/1` or `Phoenix.HTML.raw/1` | HIGH | Every use must be with static strings or pre-sanitised content, never user input |
| `String.to_atom/1` | HIGH | With user input causes atom exhaustion DoS — use `String.to_existing_atom/1` |
| `Code.eval_string` / `Code.eval_quoted` | CRITICAL | Remote code execution if any user input reaches these |
| `EEx.eval_string` / `EEx.eval_file` | CRITICAL | Template injection |
| `System.cmd` / `System.shell` / `:os.cmd` | CRITICAL | Command injection if arguments include user input |
| `:erlang.binary_to_term/1` | CRITICAL | Unsafe deserialization — use `Plug.Crypto.non_executable_binary_to_term/2` |

### Authentication & authorisation

- `mount/3` authenticates on both HTTP and WebSocket connect (LiveView security)
- `handle_event/3` treats all params as untrusted — validates and authorises per event
- Resources fetched by ID check ownership/authorisation (not just "does it exist?")
- `cast/3` changesets for user-facing forms don't include admin/role/permission fields
- Admin routes are behind the correct pipeline (`require_super_admin` in Portal)
- Session config has `:max_age` set and cookie has `:secure` flag in production

### Security headers & config

- `protect_from_forgery` is in the `:browser` pipeline
- `put_secure_browser_headers` is in the `:browser` pipeline
- CSP header is set (check `put_secure_browser_headers` options) — LiveView needs `connect-src 'self' wss:`
- `force_ssl` is enabled in production endpoint config
- No hardcoded secrets in committed config files (check `config/*.exs` for plain-text keys)
- HSTS header is set (`Strict-Transport-Security`)

### Data exposure

- No PII in application logs — check `Logger.info/debug/error` calls for user data
- `filter_parameters` configured in endpoint to redact sensitive params
- Error responses don't leak internal state (stacktraces, schema details)
- API responses don't over-expose data (only return what the client needs)

### Dependency security

- `mix_audit` / `mix deps.audit` is available (check if `mix_audit` dep exists in root `mix.exs`)
- `mix hex.audit` checks for retired packages
- Sobelow is configured per app (`.sobelow-conf` exists)
- These are included in the `mix quality` alias

### App-specific security rules

**WRT — Tenant isolation (CRITICAL):**
- Every `Repo` call touching tenant data uses `prefix: tenant`
- Tenant is derived from session/connection, NEVER from user params or URL
- Org admin queries are scoped to their org's tenant — no cross-tenant access
- Super admin queries use the public schema explicitly
- File uploads (if any) are namespaced by tenant

**Portal — Authentication boundaries:**
- Magic link tokens are single-use and expire
- Password reset tokens expire and are invalidated after use
- Cross-app session cookies use appropriate domain scope
- Sudo mode (`token_authenticated_at`) is checked for sensitive operations
- Failed login attempts don't reveal whether an email exists

**Pulse — Real-time security:**
- PubSub topic subscriptions verify the user is a participant in that session
- WebSocket connections authenticate the user (not just the session code)
- Score submissions validate the participant is allowed to score (not an observer)
- Session state transitions are validated server-side (not just UI-gated)

## Step 4: False positive filtering

Before including a finding, verify:

1. **Is there a concrete attack path?** Can you describe how an attacker would exploit this?
2. **Is user input actually involved?** Internal/trusted data flowing through a pattern doesn't make it a vulnerability.
3. **Does the framework already protect against this?** Phoenix/HEEx escapes output by default. Ecto parameterises queries by default. CSRF tokens are automatic on forms.
4. **Is this in test code only?** Test files, fixtures, and factories are not attack surface.

**Hard exclusions — do NOT report:**
- DoS / rate limiting / resource exhaustion (out of scope for code review)
- Secrets in `.env.example` or test config (not real secrets)
- Missing audit logging (observation, not a vulnerability)
- Dependency version warnings without a known CVE
- UUIDs assumed guessable (they are not)
- Environment variables / Docker secrets (trusted values)
- Compiled CSS/JS assets

## Step 5: Present the review

### Summary
2-3 sentences: what was reviewed, overall security posture, most important finding (if any).

### Findings

Number each finding. For each:

```
### #1 [severity] — Short title

**File:** `path/to/file.ex:42`
**Category:** (from checklist above)
**Confidence:** (high / very high)

Description of the vulnerability.

**Attack scenario:** How an attacker would exploit this.

**Fix:**
```elixir
# recommended change
```
```

Severity levels:
- **critical** — directly exploitable: RCE, SQL injection, auth bypass, data breach
- **high** — exploitable under specific conditions: XSS with user input, privilege escalation, tenant leak
- **medium** — requires specific conditions but has significant impact if exploited
- **info** — defence-in-depth improvement, not currently exploitable

### What's solid

Brief list of security measures already in place. This helps the user understand their baseline.

### Recommendations

If in **app audit** mode, provide a prioritised list of improvements:
1. Critical/high findings to fix immediately
2. Missing tooling to add (`mix_audit`, CSP headers, etc.)
3. Patterns to adopt project-wide

### Run commands

```bash
# Run Sobelow (from app directory)
cd apps/<app>
docker compose exec <prefix>_app mix sobelow --config

# Run dependency audit (if mix_audit is installed)
docker compose exec <prefix>_app mix deps.audit
docker compose exec <prefix>_app mix hex.audit

# Compile with warnings as errors (catches unused vars that may indicate logic bugs)
docker compose exec <prefix>_app mix compile --warnings-as-errors
```
