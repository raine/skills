---
name: pilot
description: Autonomous agent that navigates any task from start to finish. Explores the codebase, classifies complexity, adaptively consults external LLMs for planning or brainstorming, implements with incremental commits, and gets LLM review.
disable-model-invocation: true
---

Autonomously take a task from understanding to implementation to review,
consulting external LLMs at the right moments based on task complexity.

**Arguments:** `$ARGUMENTS`

## Configuration

Check the arguments for flags:

**Mode flags:**

- `--dry-run` → plan only, skip implementation and review
- `--no-review` → skip the final review phase

Strip all flags from arguments to get the task description.

## Phase 1: Understand & Classify

### Step 1: Explore the codebase

Use Glob, Grep, Read to understand:

- Relevant files and their structure
- Existing patterns and conventions
- Dependencies and interfaces

If anything about the task is unclear or ambiguous, ask clarifying questions
before proceeding. Use your judgment — ask when a wrong assumption would be
costly, skip when the answer is obvious from context.

### Step 2: Classify the task

Assess along two dimensions:

**Confidence** — how sure are you of the right approach?

- **High**: One obvious way to do it, well-understood problem
- **Some unknowns**: Multiple valid approaches, design decisions needed
- **Low**: Competing designs, unclear trade-offs, architectural implications

**Risk** — what's the blast radius if it goes wrong?

- **Low**: Localized change, easily reversible, no external impact
- **Moderate**: Touches multiple modules, moderate blast radius
- **High**: Cross-cutting, hard to reverse, affects APIs/data/users

Combine into a **planning level** (use judgment — this is a guideline, not a
rigid rule):

|               | High confidence | Some unknowns | Low confidence |
| ------------- | --------------- | ------------- | -------------- |
| **Low risk**  | Low             | Medium        | Medium         |
| **Moderate**  | Low             | Medium        | High           |
| **High risk** | Medium          | High          | High           |

Present your classification to the user:

```
**Task:** [one-line description]
**Confidence:** [High/Some unknowns/Low] — [why]
**Risk:** [Low/Moderate/High] — [why]
**Planning level:** [Low/Medium/High] — [what this means for LLM involvement]
```

## Phase 2: Form Your Own Approach

Before consulting any external LLM, form your own implementation plan based on
what you found in Phase 1:

1. **Approach**: Your recommended approach in 2-3 sentences
2. **Key decisions**: Main design decisions and why
3. **Files**: Files to create or modify
4. **Steps**: Implementation steps
5. **Risks**: What could go wrong

Write this out as `## Claude's Approach` and present it to the user.

## Phase 3: Consult (Adaptive)

### If Low — Skip

Your approach from Phase 2 is the plan. Proceed to Phase 4.

### If Medium — Get Feedback

Send your approach to both LLMs for critique and improvement.

**Feedback prompt:**

```
I'm implementing the following task:

[Task description]

Here's the codebase context:
[Context summary from Phase 1]

Here's my proposed approach:
[Claude's approach from Phase 2]

Review this approach:
1. **Gaps**: What am I missing or underestimating?
2. **Improvements**: How would you improve this approach?
3. **Risks**: What could go wrong that I haven't considered?
4. **Alternative**: If you'd do it differently, briefly describe your approach and why

Be specific and concise. Focus on what matters.
```

Spawn BOTH as parallel subagents (`Agent` tool, `subagent_type: "general-purpose"`, `model: "sonnet"`). NEVER run subagents in the background — always run them in the foreground so you can process their results immediately. Each subagent prompt must include the full feedback prompt text and file list so it can make the MCP call independently.

**Gemini subagent** — prompt must include:

- Call `mcp__consult-llm__consult_llm` with `model: "gemini"`, `prompt`: the
  feedback prompt, `files`: [relevant files]
- Return the COMPLETE response including any `[thread_id:xxx]` prefix

**Codex subagent** — prompt must include:

- Call `mcp__consult-llm__consult_llm` with `model: "openai"`, `prompt`: the
  feedback prompt, `files`: [relevant files]
- Return the COMPLETE response including any `[thread_id:xxx]` prefix

Integrate valid feedback into your plan. Present a brief summary:

```
**Feedback incorporated:**
- From Gemini: [what you adopted and why]
- From Codex: [what you adopted and why]
- Declined: [anything you disagreed with and why]
```

### If High — Choose Style, Then Consult

First, decide the consultation style based on the nature of the task:

- **Collab** (brainstorm): Open-ended design space, idea generation, combining
  patterns. Use when you don't know what the right approach is yet.
- **Debate** (adversarial): Competing architectures, risky trade-offs, need
  failure analysis. Use when there are clear alternatives and you need to
  stress-test them.

Present your choice: `**Style:** Collab / Debate — [why]`

#### High: Opening Round (shared by both styles)

Get both LLMs to independently propose approaches.

**Opening prompt:**

```
I need to implement the following task:

[Task description]

Here's the codebase context:
[Context summary from Phase 1]

Propose your implementation approach:
1. **Approach**: Describe your recommended approach in 2-3 sentences
2. **Key decisions**: List the main architectural/design decisions
3. **Files**: What files to create or modify
4. **Steps**: High-level implementation steps
5. **Trade-offs**: What are the pros and cons?

Be specific and opinionated. Defend your choices.
```

Spawn BOTH as parallel subagents. Extract thread IDs from `[thread_id:xxx]`
prefixes.

Present all three approaches (Claude's, Gemini's, Codex's) to the user.

#### If Collab Style — Build On

**If approaches largely agree:** Synthesize the best elements and move to
Phase 4.

**If significant disagreements exist:** Run one build-on round. Share all three
approaches with both LLMs:

**Build-on prompt:**

```
Two other engineers proposed these approaches:

**Claude's approach:**
[Claude's approach from Phase 2]

**[Other LLM]'s approach:**
[Other LLM's approach]

Build on the strongest ideas from all approaches:
1. **Best elements**: Which ideas from each approach are strongest?
2. **Synthesis**: How would you combine the best elements?
3. **Resolved concerns**: What risks or open questions are now addressed?
4. **Final recommendation**: Your refined recommendation

Refine toward the best solution.
```

Spawn BOTH as parallel subagents with `thread_id` to continue conversations.

Synthesize all input into the final approach. Be honest about where an LLM's
idea won over yours.

#### If Debate Style — Rebuttals

Run a rebuttal round where each LLM critiques the other's approach. Include
Claude's approach as additional context.

**Rebuttal prompt (same for both, swap the opponent's argument):**

```
Your opponent proposed this alternative approach:

[Opponent's opening argument]

A third engineer (Claude) proposed:

[Claude's approach from Phase 2]

Provide a rebuttal:
1. **Critique**: What are the weaknesses in your opponent's approach?
2. **Defense**: Address any weaknesses in your own approach
3. **Concessions**: Are there any good ideas from your opponent or Claude worth adopting?
4. **Updated position**: State your refined recommendation

Be constructive but thorough in your critique.
```

Spawn BOTH as parallel subagents with `thread_id` to continue conversations.

**Gemini subagent** — call with Codex's opening as the opponent.
**Codex subagent** — call with Gemini's opening as the opponent.

Present both rebuttals to the user. Then act as moderator:

- Which approach is simpler?
- Which better fits existing patterns?
- Which critiques were valid?
- What concessions were made?

Resolve disagreements and synthesize. Prefer simpler solutions when arguments
are equally strong. Be honest about which side had the stronger argument.

## Phase 4: Write the Plan

Write a concrete implementation plan:

````markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence]

## Approach

[2-3 sentences describing the final approach]

**Input sources:** [Low: Claude only / Medium: Claude + LLM feedback / High:
Claude + Gemini + Codex collab or debate]

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
// Include actual code, not placeholders
```

---
````

Guidelines:

- **Exact file paths** — never "somewhere in src/"
- **Complete code** — show the actual code
- **Small tasks** — 2-5 minutes of work each
- **DRY, YAGNI** — only what's needed

Save the plan to `history/plan-<feature-name>.md`.

**If `--dry-run`:** Skip to Phase 7 (Summary).

## Phase 5: Implement

Implement the plan without further interaction:

1. **Follow the plan exactly** — implement each task in order
2. **Commit after each logical unit** — keep commits small and focused
3. **If something is unclear** — make a reasonable decision and note it in the
   commit message
4. **If a task fails** — attempt to fix it before moving on
5. **Only stop if there's a blocking error** that cannot be resolved

Implementation rules:

- Work through tasks sequentially
- Test changes when possible (`just check` or project-appropriate commands)
- Keep commits atomic and well-documented
- Use commit messages that explain the "why"

### Escape Hatch: Mid-Implementation Consult

Consider consulting an external LLM when you encounter situations like:

- A test or command keeps failing and you're unsure of the root cause
- You're about to guess an API signature, config format, or library behavior
- The next edit depends on understanding unfamiliar code or external behavior
- You've tried multiple approaches to the same problem without progress

Call `mcp__consult-llm__consult_llm` with:

- `model`: pick whichever LLM is more likely to know — use judgment
- `prompt`: The specific question — not the whole task
- `files`: Only the files relevant to the specific problem

Use a fresh thread — don't anchor on prior planning discussion context.

Keep these consultations surgical. Ask about the specific problem, not the whole
implementation.

## Phase 6: Review

**If `--no-review`:** Skip to Phase 7 (Summary).

After all implementation commits, have both LLMs review the changes. Always use
**fresh threads** — reviewers should evaluate the code on its merits, not
through the lens of having helped design it.

**Review prompt:**

```
I implemented the following task:

[Task description]

Codebase context:
[Context summary from Phase 1 — relevant files, patterns, conventions]

Review the implementation (diff below) purely on its merits:
- Any bugs or edge cases missed?
- Code quality issues (error handling, naming, structure)?
- Security concerns?

Be concise. Only flag issues worth fixing.
```

Spawn BOTH as parallel subagents (`Agent` tool, `subagent_type: "general-purpose"`, `model: "sonnet"`). Each subagent prompt must include the review prompt and git_diff. Do NOT pass a `thread_id`.

**Gemini subagent** — prompt must include:

- Call `mcp__consult-llm__consult_llm` with `model: "gemini"`,
  `task_mode: "review"`, `prompt`: review prompt (with task description and
  context summary filled in),
  `git_diff`: `{ "files": [changed files], "base_ref": "HEAD~N" }`
- Return the COMPLETE response

**Codex subagent** — prompt must include:

- Call `mcp__consult-llm__consult_llm` with `model: "openai"`,
  `task_mode: "review"`, `prompt`: review prompt (with task description and
  context summary filled in),
  `git_diff`: `{ "files": [changed files], "base_ref": "HEAD~N" }`
- Return the COMPLETE response

### Applying Review Fixes

**Scope:** Only fix bugs, edge cases, unhandled errors, and security issues
found in review. Do not undertake refactors or architectural changes during the
review phase.

**Apply fixes** if both reviewers flag the same issue, or if one raises a
clearly valid bug or security concern. **Commit each fix as its own separate
commit** with a clear message explaining what was caught in review.

**Skip** minor style suggestions or conflicting opinions.

**Escalate:** If both reviewers flag the same architectural concern, present it
to the user and ask whether to address it now or defer.

## Phase 7: Summary

Present a final summary to the user:

```
## Summary

**Task:** [one-line description]
**Planning level:** [Low/Medium/High]

**Approach:** [2-3 sentences on what was implemented]

**LLM involvement:**
- Planning: [what LLMs contributed, or "skipped (low complexity)"]
- Mid-implementation: [any escape hatch consultations, or "none"]
- Review: [key findings, or "no issues found"]

**Key decisions:**
- [Decision 1 and source (Claude / Gemini / Codex)]
- [Decision 2 and source]

**Commits:**
- `abc1234` - [commit message]
- `def5678` - [commit message]
```
