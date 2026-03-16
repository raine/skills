---
name: update-pr
description: Update the current PR description based on the latest changes in context.
allowed-tools: Read, Bash, Glob, Grep, Edit
---

Update the current PR description to reflect the latest changes made in this
session.

## Steps

1. Get the current PR body and write to a temp file, stripping Windows line
   endings:

   ```bash
   gh pr view --json body --jq '.body' | tr -d '\r' | tee /tmp/pr-body.md > /dev/null
   ```

   NOTE: Use `tee` instead of `>` to avoid zsh `noclobber` errors when the
   file already exists. The `>|` operator also doesn't work in the Bash tool's
   eval context.

2. Gather context about recent changes:

   - Use the conversation context to understand what was changed and why
   - Get the diff since the PR was opened: `git diff origin/main...HEAD`
   - Review recent commits: `git log origin/main...HEAD --format="%s"`

3. Use the Edit tool to make incremental changes to the temp file:

   - Use Edit to make specific, targeted changes - do NOT rewrite the entire file
   - Keep the existing structure and sections
   - Update the Summary and Changes sections to reflect the latest work
   - Add any new testing steps if applicable
   - Preserve any existing context that is still relevant

4. Update the PR with the edited description:

   ```bash
   gh pr edit --body-file /tmp/pr-body.md
   ```

IMPORTANT: Use the context of the current conversation to inform the updates.
The discussion, decisions, and work done in this session provide valuable
context for explaining what changed and why.

IMPORTANT: Preserve the existing PR template structure. Only update the content
within the sections, don't remove or restructure sections unless specifically
asked.

CRITICAL: Always use the Edit tool to make changes to the PR description file.
Never rewrite the entire file - make incremental edits so the user can see
diffs.
