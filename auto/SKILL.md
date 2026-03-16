---
name: auto
description: Autonomously create a plan, consult Gemini and Codex for improvements, apply feedback, and implement. No user interaction - uses best judgment throughout.
---

Autonomously plan and implement a feature with external LLM review.

## Reviewer Configuration

**Arguments:** `$ARGUMENTS`

Check the arguments for flags:

**Reviewer flags** (mutually exclusive):
- `--gemini` → use only Gemini for reviews
- `--codex` → use only Codex for reviews
- `--claude` → use a Claude subagent (Task tool) for reviews
- `--no-review` → skip all review phases (3, 4, and 6)
- No flag → use both Gemini and Codex in parallel (default)

**Mode flags:**
- `--dry-run` → plan only, skip implementation and final review (stop after Phase 4)
- `--skip-final` → skip the final review phase (Phase 6)
- `--rounds N` → repeat the review-refine cycle N times (default: 1). Max: 3.

Strip all flags from arguments to get the task description.

## Phase 1: Understand the Task (No Questions)

1. **Explore the codebase** - use Glob, Grep, Read to understand:
   - Relevant files and their structure
   - Existing patterns and conventions
   - Dependencies and interfaces

2. **Make reasonable assumptions** - do NOT ask clarifying questions
   - Use best judgment based on codebase context
   - Prefer simpler solutions when ambiguous
   - Follow existing patterns in the codebase

## Phase 2: Write the Plan

Create a plan document following this structure:

````markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence describing what this builds]

**Approach:** [2-3 sentences about the approach]

**Assumptions:** [List any assumptions made without asking the user]

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
- **Exact file paths** - never "somewhere in src/"
- **Complete code** - show the actual code
- **Small tasks** - 2-5 minutes of work each
- **DRY, YAGNI** - only what's needed

Save the plan to `history/<date>-plan-<feature-name>.md` (e.g. `history/2026-02-15-plan-user-auth.md`).

## Phase 3: Consult Reviewer(s)

**If `--no-review`:** Skip to Phase 5 (Implementation).

Based on the reviewer flag from arguments:

### If `--gemini`: Gemini only

Call `mcp__consult-llm__consult_llm` with:
- `model`: "gemini"
- `prompt`: See review prompt below
- `files`: Array including the plan file and relevant source files

### If `--codex`: Codex only

Call `mcp__consult-llm__consult_llm` with:
- `model`: "openai"
- `prompt`: See review prompt below
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
- Is the approach consistent with the existing codebase patterns?

Read the plan file and relevant source files, then provide specific, actionable feedback. Be concise.
```

### If no flag (default): Both Gemini and Codex in parallel

Spawn BOTH as parallel subagents (`Agent` tool, `subagent_type: "general-purpose"`, `model: "sonnet"`). Each subagent prompt must include the full review prompt and file list so it can make the MCP call independently.

**Gemini subagent** — prompt must include:
- Call `mcp__consult-llm__consult_llm` with `model: "gemini"`, `prompt`: the review prompt, `files`: [array including the plan file and relevant source files]
- Return the COMPLETE response including any `[thread_id:xxx]` prefix

**Codex subagent** — prompt must include:
- Call `mcp__consult-llm__consult_llm` with `model: "openai"`, `prompt`: the review prompt, `files`: [array including the plan file and relevant source files]
- Return the COMPLETE response including any `[thread_id:xxx]` prefix

---

**Review prompt (for Gemini/Codex):**
```
Review this implementation plan. Consider:
- Are the tasks correctly ordered and sized?
- Are there any missing steps or edge cases?
- Are the file paths and code snippets accurate?
- Any architectural concerns or better approaches?
- Is the approach consistent with the existing codebase patterns?

Provide specific, actionable feedback. Be concise.
```

### Maintaining conversation context with `thread_id`

After each MCP call, check the response for a `[thread_id:xxx]` prefix. Extract and store the thread ID per model (e.g., `gemini_thread_id`, `codex_thread_id`). Pass the corresponding `thread_id` in all subsequent calls to the same model (Phase 4 rounds, Phase 6) so the reviewer retains full context from earlier reviews without resending the plan and files.

## Phase 4: Apply Improvements

After receiving feedback from both LLMs:

1. **Synthesize feedback** - identify common suggestions and valid concerns
2. **Apply improvements automatically** - update the plan with:
   - Bug fixes or edge cases both LLMs identified
   - Architectural improvements that make sense
   - Missing steps that are clearly needed
3. **Discard conflicting advice** - if Gemini and Codex disagree, use your judgment
4. **Update the plan file** with the improvements
5. **Do NOT ask the user** - proceed with your best judgment

### Multiple Rounds (`--rounds N`)

If `--rounds N` is specified and N > 1, repeat Phases 3-4 for additional rounds:

- **Round 2+**: Send the refined plan back to reviewers with this prompt, passing the `thread_id` from the previous round. The reviewer already has context from prior rounds, so you don't need to resend files — just include the updated plan file:
  ```
  This is revision [N] of the implementation plan. Review the updated plan:
  - Were previous concerns addressed adequately?
  - Any new issues introduced by the changes?
  - Any remaining gaps or edge cases?
  - Is the plan ready for implementation?

  Focus on what changed. Be concise.
  ```
- **Apply improvements** from each round before proceeding to the next
- **Track changes** by round in the plan file under a "Revision History" section
- **Stop early** if reviewers indicate no further changes needed
- **Update thread_id** after each round — use the latest `thread_id` from the response

After completing all rounds (or stopping early), proceed to Phase 5.

## Phase 5: Implement

**If `--dry-run`:** Skip to Phase 7 (Summary) - report the plan without implementing.

Implement the plan without further interaction:

1. **Follow the plan exactly** - implement each task in order
2. **Commit after each logical unit** - keep commits small and focused
3. **If something is unclear** - make a reasonable decision and note it in the commit message
4. **If a task fails** - attempt to fix it before moving on
5. **Only stop if there's a blocking error** that cannot be resolved

Implementation rules:
- Work through tasks sequentially
- Test changes when possible
- Keep commits atomic and well-documented
- Use commit messages that explain the "why"
- Commit improvements from consultations separately from original plan tasks

## Phase 6: Final Review

**If `--no-review` or `--skip-final`:** Skip to Phase 7 (Summary).

After implementation is complete, review the changes using the same reviewer from Phase 3:

1. **Generate the diff** - get the full diff of all changes made

2. **Consult the reviewer** based on the flag:

   - **`--gemini` or no flag:** Use `mcp__consult-llm__consult_llm` with `model`: "gemini"
   - **`--codex`:** Use `mcp__consult-llm__consult_llm` with `model`: "openai"
   - **`--claude`:** Use Task tool with `subagent_type: "general-purpose"`

   Include `git_diff` (for mcp tool) or instruct the subagent to run `git diff` to see changes.

   Pass the `thread_id` from Phase 3/4 so the reviewer has full context from the plan review. The reviewer already knows the plan — the diff shows how it was implemented.

**Final review prompt:**
```
Review this implementation for bugs, issues, or improvements:
- Any obvious bugs or edge cases missed?
- Code quality issues (error handling, naming, structure)?
- Deviations from best practices?
- Security concerns?

Be concise. Only flag issues worth fixing.
```

3. **Apply fixes automatically** - if the review identifies real issues:
   - Fix bugs and edge cases
   - Improve error handling if clearly needed
   - Commit each fix separately with clear messages (not bundled with implementation commits)

4. **Skip minor style suggestions** - don't refactor for style alone

## Phase 7: Summary

Present a final summary to the user:

```
## Summary

**Implemented:** [One sentence describing what was built]

**Plan improvements applied:**
- [Improvement from Gemini/Codex feedback]
- [Another improvement]

**Post-implementation fixes:**
- [Fix applied after final review, if any]

**Commits:**
- `abc1234` - [commit message]
- `def5678` - [commit message]
```
