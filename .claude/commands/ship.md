Create a pull request for the current changes.

IMPORTANT: This command uses subagents to avoid exhausting the main context window.
Follow these steps in order.

## Step 1: Assess changes (main context — keep it lightweight)

Run `git status` and `git diff --stat` to get an overview of what changed.
Then run a detailed diff **excluding compiled assets** to understand the code changes:
```
git diff -- ":(exclude)*.css" ":(exclude)*.js"
```
Compiled CSS/JS in `priv/static/assets/` can be **thousands of lines** and WILL exhaust context.
NEVER run an unfiltered `git diff` when asset files are modified.

Determine the affected app(s) based on file paths.
Write a short summary of the changes (2-3 sentences) for use in later steps.

## Step 2: Update documentation (delegate to a subagent)

Use the Task tool (subagent_type: "general-purpose") to update documentation.
Give the subagent:
- The list of changed files
- Your short summary of what changed
- The affected app path(s) (e.g., `apps/wrt`)

The subagent prompt should instruct it to:
- First check which doc files exist (Glob for `*.md` in the app directory and `docs/`)
- Only read and update docs that **exist AND are relevant** to the changes:
  1. REQUIREMENTS.md — if product behaviour changed
  2. SOLUTION_DESIGN.md — if architecture or design decisions changed
  3. TECHNICAL_SPEC.md — if implementation details changed
  4. docs/ux-design.md — if visual design or accessibility changed
  5. docs/ux-implementation.md — if CSS, JS hooks, or UI components changed
  6. README.md — if setup instructions or usage patterns changed
- Skip docs that don't exist — do NOT create new doc files
- Skip docs that are irrelevant to the changes
- For large doc files (500+ lines), only read the relevant sections, not the whole file
- Read the changed **source** files if needed to understand what to document
- NEVER read compiled asset files (`priv/static/assets/*`) — they are build artifacts

Wait for the subagent to finish before proceeding.

## Step 3: Branch, commit, push, create PR (main context)

1. Create a descriptive branch name with app prefix (e.g., `feature/wrt-email-workers`)
2. Stage the relevant files — be specific, avoid `git add -A` or `git add .`
   - Include both the code changes AND any doc files the subagent updated
3. Commit with a clear message describing the changes
4. Push the branch with `-u` flag
5. Create a PR using `gh pr create` with:
   - A concise title (under 70 chars)
   - A summary of changes in the body
   - Test plan if applicable

## Step 4: Watch CI and merge (background task)

**IMPORTANT:** Do NOT use `gh pr checks --watch`. It shows stale runs from prior
force-pushes and exits with false failures. Instead, poll check runs for the
**exact commit SHA** that was pushed.

Run the following as a **single background** Bash task (replace `<SHA>` with the
actual commit SHA from the push, and `<PR_NUMBER>` with the PR number):

```bash
SHA="<SHA>"
PR="<PR_NUMBER>"
REPO="massroc/oostkit"

echo "Watching CI for commit $SHA (PR #$PR)..."
while true; do
  # Get check runs for this specific commit (excludes stale runs from old pushes)
  # NOTE: use "| not" instead of "!=" to avoid bash escaping issues with !
  result=$(gh api "repos/$REPO/commits/$SHA/check-runs" \
    --jq '[.check_runs[] | select(.name | test("Deploy") | not)] |
      { total: length,
        done: [.[] | select(.status == "completed")] | length,
        failed: [.[] | select(.status == "completed" and (.conclusion == "success" or .conclusion == "skipped") | not)] | length,
        checks: [.[] | "\(.name): \(.status)/\(.conclusion // empty)"] }')

  total=$(echo "$result" | jq -r '.total')
  done_count=$(echo "$result" | jq -r '.done')
  failed=$(echo "$result" | jq -r '.failed')

  echo "[$done_count/$total complete, $failed failed]"
  echo "$result" | jq -r '.checks[]'

  # Wait for checks to appear (GitHub may take a few seconds)
  if [ "$total" -eq 0 ]; then
    echo "Waiting for checks to start..."
    sleep 10
    continue
  fi

  # All done?
  if [ "$done_count" -eq "$total" ]; then
    if [ "$failed" -gt 0 ]; then
      echo "CI FAILED"
      gh api "repos/$REPO/commits/$SHA/check-runs" \
        --jq '.check_runs[] | select(.status == "completed" and (.conclusion == "success" or .conclusion == "skipped") | not) | "\(.name): \(.conclusion) \(.html_url)"'
      exit 1
    else
      echo "CI PASSED — merging..."
      gh pr merge "$PR" --squash --delete-branch && git checkout main && git pull && git remote prune origin
      exit 0
    fi
  fi

  sleep 10
done
```

Then tell me the PR URL and that CI is running in the background.

If CI fails, report the failure and do NOT attempt to merge. Show the failed
check URLs so I can investigate.

## Error handling

- If there are no changes to commit, inform me instead of creating an empty PR.
- If CI checks fail, report the failure and do NOT attempt to merge. Show the failed check output so I can fix the issue.
