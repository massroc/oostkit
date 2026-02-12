Plan tests for a feature, audit test coverage for a module, or survey coverage across an app.

Usage:
- `/qa <feature description>` — TDD test plan (before implementation)
- `/qa <module path>` — audit tests for an existing module
- `/qa audit <app name>` — coverage matrix for an entire app

If no argument is given, ask the user which mode they want.

## Step 1: Determine mode

Parse `$ARGUMENTS`:

- **Contains a file path** (has `/`, ends in `.ex` or `.exs`) → **Module audit** mode
- **Starts with "audit"** followed by an app name (portal, pulse, wrt) → **App audit** mode
- **Everything else** → **TDD planning** mode

## Step 2: Identify the affected app

From the argument, determine the app:
- `apps/portal/...` or mentions "portal" → Portal
- `apps/workgroup_pulse/...` or mentions "pulse" → Pulse / Workgroup Pulse
- `apps/wrt/...` or mentions "wrt" → WRT
- Ambiguous → ask the user

## Step 3: Load test infrastructure context

Based on the app, note the correct testing patterns:

**Portal:**
- Test case modules: `PortalWeb.ConnCase`, `Portal.DataCase`
- Fixtures: `Portal.AccountsFixtures` (function-based, NOT ExMachina)
  - `user_fixture/1`, `super_admin_fixture/1`, `session_manager_fixture/1`
  - `register_and_log_in_user/1`, `register_and_log_in_super_admin/1` (ConnCase setup)
  - `extract_user_token/1` for email token extraction
- Run: `cd apps/portal && docker compose --profile test run --rm portal_test`
- Single file: `docker compose --profile test run --rm portal_test mix test test/path/to/test.exs`

**Workgroup Pulse:**
- Test case modules: `WorkgroupPulseWeb.ConnCase`, `WorkgroupPulse.DataCase`, `WorkgroupPulseWeb.FeatureCase` (Wallaby browser tests)
- Factory: `WorkgroupPulse.Factory` (ExMachina)
  - `insert(:session)`, `insert(:started_session)`, `insert(:participant)`, `insert(:score)`
  - `insert(:template)`, `insert(:question)`, `insert(:maximal_question)`
  - `insert(:note)`, `insert(:action)`
- Run: `cd apps/workgroup_pulse && docker compose --profile test run --rm wp_test`
- Single file: `docker compose --profile test run --rm wp_test mix test test/path/to/test.exs`

**WRT:**
- Test case modules: `WrtWeb.ConnCase`, `Wrt.DataCase`
- Factory: `Wrt.Factory` (ExMachina) — tenant-scoped
  - Public schema: `insert(:super_admin)`, `insert(:organisation)`, `insert(:approved_organisation)`
  - Tenant-scoped: `insert_in_tenant(tenant, :campaign)`, `insert_in_tenant(tenant, :person)`
  - Campaigns: `:campaign`, `:active_campaign`, `:completed_campaign`
  - Rounds: `:round`, `:active_round`, `:closed_round`
  - People: `:person`, `:seed_person`
  - Contacts: `:contact`, `:invited_contact`, `:responded_contact`
  - Magic links: `:magic_link`, `:expired_magic_link`, `:used_magic_link`
  - Orgs: `:org_admin`, `:campaign_admin`
- ConnCase helpers: `create_org_with_tenant/0`, `log_in_portal_super_admin/2`, `log_in_portal_user/2`
- DataCase helpers: `create_test_tenant/0`, `insert_in_tenant/2`, `insert_in_tenant/3`
- Run: `cd apps/wrt && docker compose --profile test run --rm wrt_test`
- Single file: `docker compose --profile test run --rm wrt_test mix test test/path/to/test.exs`

---

## Mode: TDD Planning

For a feature description, produce a complete test plan to write BEFORE implementation.

### 3a. Read related existing tests

Find the test directory for the affected area and read 1-2 existing test files to match their style, setup patterns, and assertion patterns.

### 3b. Produce the test plan

For each module that will be created or modified:

**Context tests** (DataCase):
```
## test/<app>/<context>_test.exs

describe "function_name/arity" do
  test "happy path — describe expected outcome" do
    # Setup: what factories/fixtures to create
    # Action: call the function
    # Assert: what to check
  end

  test "returns error when <condition>" do
    # ...
  end

  test "edge case — <description>" do
    # ...
  end
end
```

**LiveView tests** (ConnCase):
```
## test/<app>_web/live/<module>_live_test.exs

describe "mount" do
  test "renders the page with expected content" do
    # Setup: create session/user, conn
    # Action: live(conn, ~p"/path")
    # Assert: html contains expected elements
  end
end

describe "handle_event 'event_name'" do
  test "updates state correctly" do
    # ...
  end
end
```

**Controller tests** (ConnCase):
```
## test/<app>_web/controllers/<controller>_test.exs

describe "GET /path" do
  test "returns 200 for authorised user" do
    # ...
  end

  test "redirects unauthenticated user" do
    # ...
  end
end
```

For each test case, include:
- Concrete factory/fixture calls (not pseudocode)
- The actual function call or conn request
- Specific assertions (`assert`, `refute`, `assert_redirect`, etc.)

### 3c. Priority ranking

Rank the test cases by importance:
1. **Critical** — verifies core business logic, catches data corruption
2. **Important** — verifies user-facing behaviour, auth boundaries
3. **Nice to have** — edge cases that are unlikely but worth covering

### 3d. Run commands

```bash
# Run all tests for this feature
cd apps/<app>
docker compose --profile test run --rm <prefix>_test mix test test/path/to/test.exs

# Run in TDD watch mode
docker compose --profile tdd run --rm <prefix>_test_watch
```

---

## Mode: Module audit

For an existing module, map every public function to its test coverage.

### 3a. Read the module and its tests

Read the target module. Then find and read its corresponding test file(s):
- Context `apps/<app>/lib/<app>/foo.ex` → `apps/<app>/test/<app>/foo_test.exs`
- LiveView `apps/<app>/lib/<app>_web/live/foo_live/show.ex` → `apps/<app>/test/<app>_web/live/foo_live/show_test.exs`
- Controller `apps/<app>/lib/<app>_web/controllers/foo_controller.ex` → `apps/<app>/test/<app>_web/controllers/foo_controller_test.exs`

### 3b. Coverage matrix

| Function | Test exists? | Cases covered | Gaps |
|----------|-------------|---------------|------|
| `create_foo/1` | Yes | happy path, invalid attrs | missing: duplicate name |
| `delete_foo/1` | No | — | needs happy path + not found |

### 3c. Gap analysis

For each gap, provide a concrete test case (same format as TDD planning mode).

### 3d. Run command

```bash
cd apps/<app>
docker compose --profile test run --rm <prefix>_test mix test test/path/to/test.exs
```

---

## Mode: App audit

Survey test coverage across an entire app.

### 3a. Discover modules and tests

Use Glob to find:
- All context modules: `apps/<app>/lib/<app>/*.ex`
- All web modules: `apps/<app>/lib/<app>_web/**/*.ex`
- All test files: `apps/<app>/test/**/*_test.exs`

### 3b. Coverage matrix

| Module | Test file | Public fns | Tested fns | Coverage |
|--------|-----------|------------|------------|----------|
| `App.Campaigns` | `campaigns_test.exs` | 12 | 10 | 83% |
| `AppWeb.CampaignController` | `campaign_controller_test.exs` | 6 | 6 | 100% |
| `App.Workers.SendEmail` | — | 2 | 0 | 0% |

### 3c. Summary

- Total modules / total with tests
- Top 3 coverage gaps (modules with lowest coverage that have the highest risk)
- Recommended next tests to write (prioritised by business impact)

### 3d. Run command

```bash
# Run all tests with coverage report
cd apps/<app>
docker compose --profile test run --rm <prefix>_test mix coveralls
```
