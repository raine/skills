---
name: try-all
description: Delegate each of the proposed options to a separate AI agent in its own git worktree.
allowed-tools: Bash, Write
---

Delegate each of the proposed options to a separate AI agent in its own git
worktree.

For each option:

1. Construct a prompt that describes implementing that specific approach
2. Generate a short, descriptive worktree name (e.g., `banner-approach`,
   `modal-dialog`, `toast-notification`)
3. Run `workmux add <worktree-name> -b -P "<prompt-file>"` to create a worktree

IMPORTANT: If the current changes have not been committed yet, and they are
needed in the worktrees, you need to commit first.

The worktree name should:

- Be lowercase with hyphens (kebab-case)
- Be short but descriptive (2-4 words)
- Reflect the key characteristic of that approach

The prompt for each worktree should:

- Clearly state which approach to implement (e.g., "Implement the banner
  approach: ...")
- Include relevant context from the original problem
- Use RELATIVE paths only (never absolute paths, since each worktree has its own
  root directory)
- Be specific about what the agent should do
- Include any additional instructions provided by the user above (if any)
- Save the prompt to a temporary markdown file under /tmp

Example: If 3 options were proposed, run 3 separate `workmux add` commands:

```bash
workmux add banner-approach -b -P /tmp/path_to_prompt1.md
workmux add modal-dialog -b -P /tmp/path_to_prompt2.md
workmux add toast-notification -b -P /tmp/path_to_prompt3.md
```

After creating the worktrees, inform the user which branches were created so
they can review the parallel implementations.
