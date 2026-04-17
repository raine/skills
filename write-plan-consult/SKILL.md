---
name: write-plan-consult
description: Create an implementation plan by brainstorming with Gemini and Codex, synthesizing the best ideas, then getting their review.
---

Create an implementation plan by consulting external LLMs throughout the process.

User request: $ARGUMENTS

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

## Phase 2: Brainstorm with External LLMs

Once you understand the task, consult Gemini and Codex **in parallel** for
approaches and ideas.

Spawn TWO parallel subagents (`Agent` tool, `subagent_type: "general-purpose"`,
`model: "sonnet"`). Each subagent makes the MCP call and returns the full
response.

**Gemini subagent:**

Call `mcp__consult-llm__consult_llm` with:
- `model`: "gemini"
- `prompt`: The brainstorm prompt below
- `files`: Array of relevant source files for context

**Codex subagent:**

Call `mcp__consult-llm__consult_llm` with:
- `model`: "openai"
- `prompt`: The brainstorm prompt below
- `files`: Array of relevant source files for context

**Brainstorm prompt:**

```
I'm planning the following task:

[Task description with full context]

Relevant files and their roles:
[List the key files and what they do]

Propose 2-3 approaches for implementing this. For each approach:
- Describe the strategy and trade-offs
- List the files to create/modify with exact paths
- Include concrete code examples showing the key parts (not pseudocode)
- Note any edge cases or gotchas

Be specific and opinionated. Recommend your preferred approach and explain why.
```

## Phase 3: Synthesize and Write the Plan

Review both LLM responses. Pick the best ideas from each and combine them with
your own analysis into a single implementation plan.

### Plan Structure

````markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence describing what this builds]

**Approach:** [2-3 sentences about the chosen approach and why]

**Sources:** [Brief note on which ideas came from Gemini vs Codex vs your own analysis]

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
- **Credit sources** - note when an idea came from a specific LLM's suggestion

## Phase 4: Save

Save the plan:

- Write to a markdown file at `history/<date>-plan-<feature-name>.md` (e.g. `history/2026-02-15-plan-user-auth.md`)
- Include context, decisions made, and rationale

## Phase 5: Review

Get Gemini and Codex to review the synthesized plan, again **in parallel**.

Spawn TWO parallel subagents (`Agent` tool, `subagent_type: "general-purpose"`,
`model: "sonnet"`). Each subagent makes the MCP call and returns the full
response.

**Gemini subagent:**

Call `mcp__consult-llm__consult_llm` with:
- `model`: "gemini"
- `prompt`: The review prompt below
- `files`: Array including the plan file and relevant source files

**Codex subagent:**

Call `mcp__consult-llm__consult_llm` with:
- `model`: "openai"
- `prompt`: The review prompt below
- `files`: Array including the plan file and relevant source files

**Review prompt:**

```
Review this implementation plan. Consider:
- Are the tasks correctly ordered and sized?
- Are there any missing steps or edge cases?
- Are the file paths and code snippets accurate?
- Any architectural concerns or better approaches?

Provide specific, actionable feedback. Be concise.
```

After receiving feedback, present it to the user and ask if they want to revise
the plan.

## Principles

- **One question at a time** - never batch multiple questions
- **Use AskUserQuestion** - clickable options are faster for the user
- **YAGNI** - ruthlessly cut unnecessary features
- **Validate incrementally** - check understanding at each step
- **Concrete over abstract** - exact paths, actual code, specific commands
- **Best of all worlds** - synthesize the strongest ideas from each LLM
