---
name: rebase
description: Rebase the current branch.
allowed-tools: Bash
disable-model-invocation: true
---

Rebase the current branch.

Arguments: $ARGUMENTS

Behavior:

- No arguments: rebase on local main
- "origin": fetch origin, rebase on origin/main
- "origin/branch": fetch origin, rebase on origin/branch
- "branch": rebase on local branch

Steps:

1. Check for uncommitted changes:
   - Run `git status --porcelain`
   - If there are changes, run `git stash push -m "rebase-temp"`
   - Remember to pop the stash after rebase completes
2. Parse arguments:
   - No args → target is "main", no fetch
   - Contains "/" (e.g., "origin/develop") → split into remote and branch, fetch
     remote, target is remote/branch
   - Just "origin" → fetch origin, target is "origin/main"
   - Anything else → target is that branch name, no fetch
3. If fetching, run: `git fetch <remote>`
4. Detect already-merged commits (see below)
5. Run: `git rebase <target>` (or `git rebase --onto` if stale commits found)
6. If conflicts occur, handle them carefully (see below)
7. Continue until rebase is complete
8. If workmux-base was used and pointed to a merged branch, update it to the
   target branch (strip remote prefix for the config value):
   ```
   git config branch.<branch>.workmux-base main
   ```
9. If changes were stashed in step 1, run `git stash pop`

Detecting already-merged base branches:

When a branch was based on another branch that was squash-merged into the
target, the old commits still appear in the branch history but their changes are
already in the target. A plain `git rebase` will try to replay them all, causing
repeated conflicts that need to be skipped one by one.

Before rebasing, detect this situation and use `--onto` to skip stale commits:

1. Check if workmux stored a base branch for the current branch:
   ```
   base=$(git config --get branch.$(git branch --show-current).workmux-base)
   ```
2. If a base branch is found and it's NOT the rebase target (e.g. base is
   `analytics-app-detail` but we're rebasing onto `origin/main`):
   - Check if the base branch has been merged into the target:
     ```
     git merge-base --is-ancestor <base> <target>
     ```
   - If it HAS been merged (exit code 0), find where our branch diverged from
     the base branch:
     ```
     fork_point=$(git merge-base <base> HEAD)
     ```
   - Then find the last commit on our branch that was part of the base branch
     (i.e. the last commit before our own work started):
     ```
     # The tip of the old base branch in our history
     last_stale=$(git rev-list --ancestry-path $fork_point..HEAD \
       --not <target> | tail -1)^
     ```
     Or more simply: the merge-base between the base branch tip and HEAD gives
     the fork point, and all commits between that and the first commit unique to
     our branch are stale. Use:
     ```
     git rebase --onto <target> <base> HEAD
     ```
     This replays only commits after the base branch tip onto the target.
   - If the base branch has NOT been merged, fall through to a normal rebase.
3. If no workmux base is found, fall back to heuristic detection: walk commits
   oldest-to-newest and check if each commit's file changes already match the
   target using `git diff --quiet`. Find the last stale commit and use
   `git rebase --onto <target> <last-stale-commit>`.
4. If no stale commits are detected by either method, use a plain
   `git rebase <target>`.

Handling conflicts:

- BEFORE resolving any conflict, understand what changes were made to each
  conflicting file in the target branch
- For each conflicting file, run `git log -p -n 3 <target> -- <file>` to see
  recent changes to that file in the target branch
- The goal is to preserve BOTH the changes from the target branch AND our
  branch's changes
- After resolving each conflict, stage the file and continue with
  `git rebase --continue`
- If a conflict is too complex or unclear, ask for guidance before proceeding
