Create a pull request for the current changes:

1. Run `git status` to see what's changed
2. Create a descriptive branch name based on the changes (e.g., `feature/add-logout-button`, `fix/timer-display-bug`)
3. Stage the relevant files (be specific, avoid `git add -A`)
4. Commit with a clear message describing the changes
5. Push the branch with `-u` flag
6. Create a PR using `gh pr create` with:
   - A concise title (under 70 chars)
   - A summary of changes in the body
   - Test plan if applicable
7. Return the PR URL

If there are no changes to commit, inform me instead of creating an empty PR.
