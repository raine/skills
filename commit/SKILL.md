---
name: commit
description: Commit the staged changes. If there are no staged changes, stage all changes first.
allowed-tools: Bash
disable-model-invocation: true
---

Run `git status`, `git diff`, and `git diff --cached` in parallel to understand
the current state. Then:

- If there are staged changes, commit only what's staged.
- If there are no staged changes, stage all changes first, then commit.
