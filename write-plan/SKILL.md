---
name: write-plan
description: Create an implementation plan for a multi-step task. Optionally review with external LLMs.
---

Create an implementation plan for a multi-step task.

User request: $ARGUMENTS

## Flags

Check arguments for optional review flags:
- `--review` → review with both Gemini and Codex (parallel)
- `--gemini` → review with Gemini only
- `--codex` → review with Codex only
- `--claude` → review with a Claude subagent
- No flag → skip review (default)

Strip flags from arguments to get the task description.

## Phase 1: Understand the Task

Start by understanding what exists and what the user wants.

1. If relevant, explore the codebase to understand current state
2. Use `AskUserQuestion` to ask clarifying questions **one at a time**
3. Keep asking until you have enough clarity to write a plan

Rules for questions:

- ONE question per message (never batch multiple questions)
- Use `AskUserQuestion` with 2-4 options whenever possible
- Keep option labels concise (1-5 words), use descriptions for details
- If you realize you misunderstood something, acknowledge it and course-correct

## Phase 2: Write the Plan

Create a plan document with bite-sized tasks. Each task should be a small,
focused unit of work.

### Plan Structure

````markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence describing what this builds]

**Approach:** [2-3 sentences about the approach]

---

### Task 1: [Short description]

**Files:**

- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py` (lines 123-145)

**Steps:**

1. [Specific action]
2. [Specific action]

**Code:**

```language
// Include actual code, not placeholders like "add validation"
```

---

### Task 2: [Short description]

...
````

### Guidelines

- **Exact file paths** - never "somewhere in src/"
- **Complete code** - show the actual code, not "implement the logic"
- **Small tasks** - each task should be 2-5 minutes of work
- **Assume no context** - write as if the implementer knows nothing about this
  codebase
- **DRY, YAGNI** - only what's needed, no speculative features

## Phase 3: Save

Save the plan:

- Write to a markdown file at `history/<date>-plan-<feature-name>.md` (e.g. `history/2026-02-15-plan-user-auth.md`)
- Include context, decisions made, and rationale

## Phase 4: Review (if flag provided)

**Skip this phase if no review flag was provided.**

Based on the flag, get external feedback on the plan:

### If `--gemini`: Gemini only

Call `mcp__consult-llm__consult_llm` with:
- `model`: "gemini"
- `prompt`: Review prompt below
- `files`: Array including the plan file and relevant source files

### If `--codex`: Codex only

Call `mcp__consult-llm__consult_llm` with:
- `model`: "openai"
- `prompt`: Review prompt below
- `files`: Array including the plan file and relevant source files

### If `--claude`: Claude subagent

Use the Task tool with `subagent_type: "general-purpose"` and a prompt like:
```
Review this implementation plan. The plan is in: [plan file path]

Consider:
- Are the tasks correctly ordered and sized?
- Are there any missing steps or edge cases?
- Are the file paths and code snippets accurate?
- Any architectural concerns or better approaches?

Read the plan file and relevant source files, then provide specific, actionable feedback. Be concise.
```

### If `--review`: Both Gemini and Codex in parallel

Spawn BOTH as parallel subagents (`Agent` tool, `subagent_type: "general-purpose"`, `model: "sonnet"`). Each subagent prompt must include the full review prompt and file list so it can make the MCP call independently.

**Gemini subagent** — prompt must include:
- Call `mcp__consult-llm__consult_llm` with `model: "gemini"`, `prompt`: the review prompt, `files`: [array including the plan file and relevant source files]
- Return the COMPLETE response

**Codex subagent** — prompt must include:
- Call `mcp__consult-llm__consult_llm` with `model: "openai"`, `prompt`: the review prompt, `files`: [array including the plan file and relevant source files]
- Return the COMPLETE response

---

**Review prompt:**
```
Review this implementation plan. Consider:
- Are the tasks correctly ordered and sized?
- Are there any missing steps or edge cases?
- Are the file paths and code snippets accurate?
- Any architectural concerns or better approaches?

Provide specific, actionable feedback. Be concise.
```

After receiving feedback, present it to the user and ask if they want to revise the plan.

## Principles

- **One question at a time** - never batch multiple questions
- **Use AskUserQuestion** - clickable options are faster for the user
- **YAGNI** - ruthlessly cut unnecessary features
- **Validate incrementally** - check understanding at each step
- **Concrete over abstract** - exact paths, actual code, specific commands
