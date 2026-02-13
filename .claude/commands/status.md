Run a comprehensive health check across the OOSTKit platform.

Usage:
- `/status` — full check (local + CI + production)
- `/status local` — only local Docker containers
- `/status ci` — only GitHub Actions CI
- `/status prod` — only production health

If no argument is given, run all sections.

---

## Section 1: Local Docker Containers

### 1a. Check container status

For each app directory (`apps/portal`, `apps/workgroup_pulse`, `apps/wrt`), run:

```bash
docker compose ps -a --format json
```

Parse the output to determine which services are running, stopped, or missing.

### 1b. Check HTTP endpoints

Use `curl` to check these local endpoints (with a short 3-second timeout):

| App | URL |
|-----|-----|
| Portal | `http://localhost:4002/health` |
| Pulse | `http://localhost:4000/health` |
| WRT | `http://localhost:4001/health` |

### 1c. Output

Present results as a table:

```
## Local Services

| App    | Container Status | HTTP Health | Port |
|--------|-----------------|-------------|------|
| Portal | running (3h)    | 200 OK      | 4002 |
| Pulse  | not running     | -           | 4000 |
| WRT    | running (1h)    | 200 OK      | 4001 |
```

If containers are not running, that's informational (not an error) — developers
often only run the app they're working on.

---

## Section 2: GitHub Actions CI

### 2a. Fetch recent workflow runs

Use `gh api` to fetch the last 3 runs for each workflow:

```bash
gh api "repos/{owner}/{repo}/actions/workflows/portal.yml/runs?per_page=3" --jq '.workflow_runs[] | {status, conclusion, created_at, head_sha, html_url, head_branch}'
gh api "repos/{owner}/{repo}/actions/workflows/workgroup_pulse.yml/runs?per_page=3" --jq '.workflow_runs[] | {status, conclusion, created_at, head_sha, html_url, head_branch}'
gh api "repos/{owner}/{repo}/actions/workflows/wrt.yml/runs?per_page=3" --jq '.workflow_runs[] | {status, conclusion, created_at, head_sha, html_url, head_branch}'
gh api "repos/{owner}/{repo}/actions/workflows/ci-gate.yml/runs?per_page=3" --jq '.workflow_runs[] | {status, conclusion, created_at, head_sha, html_url, head_branch}'
```

### 2b. Flag problems

Flag any runs with:
- `conclusion: "failure"` — CI failed
- `conclusion: "startup_failure"` — workflow configuration error (permissions, syntax, etc.)
- `conclusion: "cancelled"` — cancelled (usually OK if superseded, but note it)
- `status: "in_progress"` — still running (informational)

### 2c. Output

Present results as a table:

```
## GitHub Actions CI

| Workflow | Run | Branch | Status | SHA | Link |
|----------|-----|--------|--------|-----|------|
| Portal | 2h ago | main | success | abc1234 | [link](url) |
| Portal | 5h ago | fix/foo | failure | def5678 | [link](url) |
| Pulse | 1d ago | main | success | ghi9012 | [link](url) |
| WRT | 3h ago | main | startup_failure | jkl3456 | [link](url) |
| CI Gate | 2h ago | main | success | abc1234 | [link](url) |
```

**Important:** If any workflow shows `startup_failure`, flag this prominently — it
usually means a workflow syntax or permissions error that affects ALL runs until fixed.

---

## Section 3: Production Health (Fly.io)

### 3a. Check production endpoints

Use `curl` with timing to check each production URL:

```bash
curl -s -o /dev/null -w "%{http_code} %{time_total}" --max-time 10 https://oostkit.com/health
curl -s -o /dev/null -w "%{http_code} %{time_total}" --max-time 10 https://pulse.oostkit.com/health
curl -s -o /dev/null -w "%{http_code} %{time_total}" --max-time 10 https://wrt.oostkit.com/health
```

### 3b. Output

Present results as a table:

```
## Production Health

| App    | URL                              | Status | Response Time |
|--------|----------------------------------|--------|---------------|
| Portal | https://oostkit.com/health       | 200 OK | 142ms         |
| Pulse  | https://pulse.oostkit.com/health | 200 OK | 238ms         |
| WRT    | https://wrt.oostkit.com/health   | 200 OK | 195ms         |
```

---

## Section 4: Summary

After all sections, provide a summary:

```
## Summary

**Overall: ALL GREEN** (or **ISSUES FOUND**)

Issues:
1. [severity] Description — what to do about it
```

Severity levels:
- **critical** — production down, CI completely broken, data at risk
- **warning** — CI failures, degraded performance, non-blocking issues
- **info** — observations, things to be aware of

### Examples of issue messages:
- **critical**: "Portal production returning 500 — check Fly.io dashboard and logs"
- **critical**: "WRT workflow has startup_failure — workflow file has syntax or permissions error"
- **warning**: "Portal CI failed on branch `fix/foo` — check test failures"
- **warning**: "Pulse production response time >2s — may need scaling"
- **info**: "WRT containers not running locally — start with `cd apps/wrt && docker compose up`"
- **info**: "No recent CI runs for Pulse — no changes pushed recently"
