---
name: qc
description: Stage all changes and commit directly without checking status or diff.
allowed-tools: Bash
---

Stage all changes and commit directly. Do not run git status, git diff, or git
log first - just stage and commit immediately.

Include a detailed commit message body that explains the "why" and provides
context useful for writing patch notes later. The body should describe:

- What problem this change solves
- Key implementation details worth noting
- Any breaking changes or important behavior differences
