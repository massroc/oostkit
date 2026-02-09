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

Run the CI watch as a **background** Bash task:
```
gh pr checks <PR_NUMBER> --watch
```

Then tell me the PR URL and that CI is running in the background.

Once I confirm or you check and CI has passed, merge with:
```
gh pr merge <PR_NUMBER> --squash --delete-branch
```
Then: `git checkout main && git pull`

## Error handling

- If there are no changes to commit, inform me instead of creating an empty PR.
- If CI checks fail, report the failure and do NOT attempt to merge. Show the failed check output so I can fix the issue.
