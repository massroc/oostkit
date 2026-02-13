Audit data handling practices against the Australian Privacy Principles and GDPR.

Usage:
- `/data` — review all uncommitted changes for data handling issues
- `/data <file or directory>` — audit specific files or modules
- `/data audit <app>` — data handling posture review for an entire app
- `/data inventory <app>` — map all personal data collected by an app

If no argument is given, default to reviewing uncommitted changes.

## Step 1: Determine mode and gather code

Parse `$ARGUMENTS`:

- **Blank** → **Change review** mode: run `git diff` and `git diff --cached` (excluding `*.css`, `*.js`)
- **File/directory path** → **Module audit** mode: read the specified files
- **"audit" followed by app name** → **App audit** mode: review data practices across the app
- **"inventory" followed by app name** → **Data inventory** mode: catalogue all personal data

Identify the affected app from file paths:
- `apps/portal/` → Portal
- `apps/workgroup_pulse/` → Pulse
- `apps/wrt/` → WRT
- `apps/oostkit_shared/` → Shared lib

## Step 2: Load context

Read these files for the affected app:
- Ecto schemas: Glob `apps/<app>/lib/<app>/**/*.ex` and look for `use Ecto.Schema`
- Migration files: Glob `apps/<app>/priv/repo/migrations/*.exs` (for data inventory mode)
- The app's `endpoint.ex` — `filter_parameters` config
- `config/runtime.exs` — database SSL, secret management
- The app's `REQUIREMENTS.md` — what data collection is documented

For **data inventory** mode, also read:
- All context modules to understand data flows
- Seeds file if it exists

## Step 3: Analyse against checklist

### Collection minimisation (APP 3 / GDPR Art. 5(1)(c))

Every field storing personal data must be justified by a documented purpose.

| Check | What to verify |
|-------|---------------|
| Schema fields justified | Each column collecting personal data has a clear purpose — no "just in case" fields |
| Collection matches purpose | Forms and LiveView events only collect data needed for the stated function |
| No secondary use | Personal data is not reused for analytics, marketing, or other purposes without basis |
| Sensitive data identified | Fields containing sensitive information (health, ethnicity, political opinions) have heightened protections |

### Data classification

Classify data found in schemas:

| Level | Label | Examples in OOSTKit |
|-------|-------|---------------------|
| Public | Intended for public view | Workshop descriptions, organisation names |
| Internal | Not sensitive but not public | Workshop templates, aggregate counts |
| Confidential | Personal data, disclosure causes harm | Participant names, emails, scores, facilitator notes |
| Restricted | Sensitive personal data, regulatory obligations | Credentials, tokens, health information |

### PII handling in code

| Check | What to verify |
|-------|---------------|
| No PII in logs | `Logger.info/debug/error/warning` calls do not log names, emails, tokens, or other personal data |
| `filter_parameters` configured | Endpoint filters sensitive params from request logs (password, token, email, name) |
| No PII in URLs | Personal data is not passed as URL query parameters (appears in server logs, browser history, referrer headers) |
| Inspect protocol | Schemas with PII fields implement custom `Inspect` to redact sensitive fields, or PII is not passed to `inspect/1` |
| Error tracking | If using Sentry/Honeybadger, scrubbers configured to strip PII |
| No PII in assigns unless needed | LiveView socket assigns don't hold more personal data than the current view requires |

### Encryption and storage

| Check | What to verify |
|-------|---------------|
| Passwords hashed | Using `Bcrypt` or `Argon2` (check for `Bcrypt.hash_pwd_salt` or `Argon2` in accounts context) |
| TLS enforced | `force_ssl` in production endpoint config |
| DB connections use SSL | `ssl: true` in production Repo config |
| Tokens are short-lived | Session tokens, magic links, and password reset tokens have defined expiration |
| Secrets externalised | No hardcoded keys in committed config — all in env vars or runtime config |

### Retention and deletion

| Check | What to verify |
|-------|---------------|
| Retention documented | Each data category has a defined retention period (check REQUIREMENTS.md) |
| Deletion mechanism exists | There is a code path to delete or anonymise a user's personal data on request |
| Cascading deletion | Deleting a user cascades to all associated personal data (check `on_delete` on associations) |
| Soft delete + follow-up | If soft delete is used, a hard-delete or anonymisation step follows within a defined period |
| Backup rotation noted | Deletion policy notes backup retention (data isn't truly gone until backups rotate) |

### Consent and rights

| Check | What to verify |
|-------|---------------|
| Consent is granular | If consent is collected, each purpose has its own control (not bundled acceptance) |
| Consent recorded | Timestamps, purpose, and method of consent are stored |
| Withdrawal works | Users can revoke consent and the system stops processing for that purpose |
| Access mechanism | Users can request a copy of their personal data |
| Correction mechanism | Users can request corrections to their data |
| Data export | Users can export their data in a machine-readable format (JSON/CSV) |

### App-specific data handling

**Portal — User accounts:**
- Account data (name, email, password hash) — what retention after account deletion?
- Session/token data — are expired tokens cleaned up?
- Admin access logs — do they contain PII?
- Cross-app identity — what personal data is shared between apps via session?

**Pulse — Workshop data:**
- Participant names/emails — collected at join or pre-registered?
- Scores and ratings — linked to identifiable participants or anonymised?
- Facilitator notes — retention period after workshop completion?
- Session recordings or transcripts (if any) — consent and retention?
- PubSub messages — do they contain PII that persists in logs?

**WRT — Tenant-scoped data:**
- Tenant isolation — PII in one tenant's schema is inaccessible from another
- Nominee/referral data — consent for collection, right to erasure
- Contact information — collected with purpose limitation
- Campaign data after completion — retention and anonymisation policy
- Organisation admin access — scoped to their tenant's data only

## Step 4: Present findings

### Summary
2-3 sentences: what was reviewed, overall data handling posture, most important finding.

### Data inventory (if inventory mode)

| Schema | Personal data fields | Classification | Purpose | Retention |
|--------|---------------------|---------------|---------|-----------|
| `User` | email, name, password_hash | Confidential/Restricted | Authentication | Account lifetime + 30 days |
| `Participant` | name, email | Confidential | Workshop participation | Per retention policy |

### Issues

Number each issue. For each:

```
### #1 [severity] — Short title

**File:** `path/to/file.ex:42`
**Category:** (from checklist above)
**Principle:** APP [number] / GDPR Art. [number]

Description of the data handling concern.

**Risk:** What could go wrong (regulatory, reputational, user harm).

**Fix:**
```elixir
# recommended change
```
```

Severity levels:
- **must fix** — regulatory non-compliance, PII exposure, missing deletion capability
- **should fix** — missing documentation, incomplete consent, over-collection
- **consider** — defence-in-depth improvement, encryption enhancement

### What's solid

Brief list of good data handling practices already in place.

### Recommendations

Prioritised list of improvements:
1. Regulatory compliance gaps (must fix)
2. Missing privacy controls (should fix)
3. Best practice enhancements (consider)

If in **app audit** mode, include:
- Data flow diagram (text-based): where PII enters, is stored, is shared, and exits
- Recommended retention schedule
- Missing privacy documentation to create
