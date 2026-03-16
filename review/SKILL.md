---
name: review
description: Review pending changes with external LLMs (Gemini, Codex, Claude, or all).
allowed-tools: Bash, Glob, Grep, Read, Task, mcp__consult-llm__consult_llm
disable-model-invocation: true
---

Review pending changes with external LLMs.

**Arguments:** `$ARGUMENTS`

## Flags

Check arguments for reviewer flags (mutually exclusive):
- `--gemini` → review with Gemini only
- `--codex` → review with Codex only
- `--claude` → review with a Claude subagent
- No flag → review with both Gemini and Codex in parallel (default)

Strip flags from arguments. Remaining text is optional scope/focus for the review.

## Phase 1: Gather Changes

1. Run `git diff` to get unstaged changes and `git diff --cached` for staged changes
2. If there are no changes, check `git log main..HEAD` for committed changes on the branch
3. If the user provided scope text (e.g. "auth changes"), use it to focus on relevant files
4. Read key files that are changed to understand context

## Phase 2: Send for Review

Based on the flag, consult the reviewer(s):

### If `--gemini`: Gemini only

Call `mcp__consult-llm__consult_llm` with:
- `model`: "gemini"
- `prompt`: Review prompt below
- `task_mode`: "review"
- `git_diff`: `{"files": [<changed files>], "base_ref": "HEAD"}`
- `files`: Array of relevant source files for context

### If `--codex`: Codex only

Call `mcp__consult-llm__consult_llm` with:
- `model`: "openai"
- `prompt`: Review prompt below
- `task_mode`: "review"
- `git_diff`: `{"files": [<changed files>], "base_ref": "HEAD"}`
- `files`: Array of relevant source files for context

### If `--claude`: Claude subagent

Use the Task tool with `subagent_type: "general-purpose"` and a prompt like:
```
Review the pending changes in this repository.

Run `git diff` and `git diff --cached` to see the changes, then read relevant files for context.

Consider:
- Any obvious bugs or edge cases missed?
- Code quality issues (error handling, naming, structure)?
- Deviations from best practices or existing patterns?
- Security concerns?

Provide specific, actionable feedback. Be concise.
```

### If no flag (default): Both Gemini and Codex in parallel

Spawn BOTH as parallel subagents (`Agent` tool, `subagent_type: "general-purpose"`, `model: "sonnet"`). Each subagent prompt must include the full review prompt, git_diff details, and file list so it can make the MCP call independently.

**Gemini subagent** — prompt must include:
- Call `mcp__consult-llm__consult_llm` with `model: "gemini"`, `prompt`: the review prompt, `task_mode: "review"`, `git_diff`: `{"files": [<changed files>], "base_ref": "HEAD"}`, `files`: [array of relevant source files]
- Return the COMPLETE response

**Codex subagent** — prompt must include:
- Call `mcp__consult-llm__consult_llm` with `model: "openai"`, `prompt`: the review prompt, `task_mode: "review"`, `git_diff`: `{"files": [<changed files>], "base_ref": "HEAD"}`, `files`: [array of relevant source files]
- Return the COMPLETE response

---

**Review prompt:**
```
Review these changes. Consider:
- Any obvious bugs or edge cases missed?
- Code quality issues (error handling, naming, structure)?
- Deviations from best practices or existing patterns?
- Security concerns?
- Anything that could break existing functionality?

Provide specific, actionable feedback. Be concise. Only flag issues worth fixing.
```

If the user provided scope/focus text, append it to the review prompt.

## Phase 3: Present Results

Present the feedback to the user:
- If both reviewers were used, organize by reviewer (Gemini / Codex)
- Highlight common concerns flagged by both
- Note any conflicting feedback
- Ask if the user wants to apply any suggested fixes
