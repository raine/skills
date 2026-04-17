---
name: consult-auto
description: Consult Gemini and Codex for high-level planning, synthesize into a detailed plan, implement, then get final review. No user interaction.
---

Consult external LLMs for planning ideas, synthesize into a detailed plan, implement, and review.

## Reviewer Configuration

**Arguments:** `$ARGUMENTS`

Check the arguments for flags:

**Reviewer flags** (mutually exclusive):
- `--gemini` → use only Gemini
- `--codex` → use only Codex
- `--claude` → use a Claude subagent (Task tool)
- No flag → use both Gemini and Codex in parallel (default)

**Mode flags:**
- `--dry-run` → plan only, skip implementation and final review (stop after Phase 3/3.5)
- `--skip-final` → skip the final review phase (Phase 5)
- `--rounds N` → after synthesizing the plan, run N-1 additional review-refine cycles (default: 1). Max: 3.
- `--skip-explore` → skip Phase 1 codebase exploration, go straight to Phase 2 with only the task description and any explicitly mentioned files

Strip all flags from arguments to get the task description.

## Phase 1: Understand the Task (No Questions)

**If `--skip-explore`:** Skip the exploration step. Use only the task description and any files the user has explicitly mentioned. Proceed directly to Phase 2 with a minimal context summary.

1. **Explore the codebase** - use Glob, Grep, Read to understand:
   - Relevant files and their structure
   - Existing patterns and conventions
   - Dependencies and interfaces

2. **Make reasonable assumptions** - do NOT ask clarifying questions
   - Use best judgment based on codebase context
   - Prefer simpler solutions when ambiguous
   - Follow existing patterns in the codebase

3. **Prepare context summary** - create a brief summary of:
   - The task to be implemented
   - Relevant files discovered
   - Key patterns and conventions in the codebase
   - Any constraints or considerations

## Phase 2: Consult for High-Level Planning

Based on the reviewer flag from arguments, consult external LLMs for high-level planning ideas.

**Planning prompt (include your context summary and relevant file contents):**
```
I need to implement the following task:

[Task description]

Here's what I found in the codebase:
[Context summary - relevant files, patterns, conventions]

Provide a high-level implementation plan:
- What approach would you recommend?
- What files need to be created or modified?
- What are the key implementation steps?
- Any edge cases or concerns to address?
- Any architectural decisions to consider?

Be specific about file paths and implementation details. Focus on the approach, not boilerplate.
```

### If `--gemini`: Gemini only

Call `mcp__consult-llm__consult_llm` with:
- `model`: "gemini"
- `prompt`: Planning prompt above
- `files`: Array of relevant source files discovered in Phase 1

### If `--codex`: Codex only

Call `mcp__consult-llm__consult_llm` with:
- `model`: "openai"
- `prompt`: Planning prompt above
- `files`: Array of relevant source files discovered in Phase 1

### If `--claude`: Claude subagent

Use the Task tool with `subagent_type: "general-purpose"` and a prompt like:
```
I need a high-level implementation plan for: [task description]

Explore the codebase and provide:
- Recommended approach
- Files to create or modify
- Key implementation steps
- Edge cases and concerns
- Architectural decisions

Be specific about file paths. Focus on the approach, not boilerplate.
```

### If no flag (default): Both Gemini and Codex in parallel

Spawn BOTH as parallel subagents (`Agent` tool, `subagent_type: "general-purpose"`, `model: "sonnet"`). NEVER run subagents in the background — always run them in the foreground so you can process their results immediately. Each subagent prompt must include the full planning prompt and file list so it can make the MCP call independently.

**Gemini subagent** — prompt must include:
- Call `mcp__consult-llm__consult_llm` with `model: "gemini"`, `prompt`: the planning prompt, `files`: [array of relevant source files]
- Return the COMPLETE response including any `[thread_id:xxx]` prefix

**Codex subagent** — prompt must include:
- Call `mcp__consult-llm__consult_llm` with `model: "openai"`, `prompt`: the planning prompt, `files`: [array of relevant source files]
- Return the COMPLETE response including any `[thread_id:xxx]` prefix

### Maintaining conversation context with `thread_id`

After each MCP call, check the response for a `[thread_id:xxx]` prefix. Extract and store the thread ID per model (e.g., `gemini_thread_id`, `codex_thread_id`). Pass the corresponding `thread_id` in all subsequent calls to the same model (Phase 3.5 rounds, Phase 5) so the reviewer retains full context from the planning phase without resending all files.

## Phase 3: Synthesize and Write Detailed Plan

After receiving planning ideas from the LLM(s):

1. **Compare approaches** - if using both LLMs:
   - Identify common recommendations (high confidence)
   - Note where they differ
   - Evaluate trade-offs of conflicting suggestions

2. **Synthesize the best approach** using your judgment:
   - Take the strongest ideas from each LLM
   - Resolve conflicts by preferring simpler solutions
   - Ensure consistency with codebase patterns
   - Fill in gaps neither LLM addressed

3. **Write the detailed plan** following this structure:

````markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence describing what this builds]

**Approach:** [2-3 sentences about the synthesized approach]

**Sources:**
- Gemini suggested: [key idea taken]
- Codex suggested: [key idea taken]
- Agent decision: [any conflicts resolved]

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
- **Credit sources** - note which LLM influenced each major decision

Save the plan to `history/<date>-plan-<feature-name>.md` (e.g. `history/2026-02-15-plan-user-auth.md`).

## Phase 3.5: Refine Plan (if `--rounds N` where N > 1)

If `--rounds N` is specified and N > 1, run N-1 additional review-refine cycles on the synthesized plan.

For each additional round:

1. **Send plan for review** using the same reviewer(s) with this prompt, passing the `thread_id` from the previous call. The reviewer already has context from the planning phase, so you don't need to resend files — just include the updated plan file:
   ```
   This is revision [N] of the implementation plan. Review the plan:
   - Are the tasks correctly ordered and sized?
   - Any missing steps or edge cases?
   - Are the file paths and code snippets accurate?
   - Any architectural concerns?
   - Is this ready for implementation?

   Focus on issues worth fixing. Be concise.
   ```

2. **Apply improvements** - synthesize feedback and update the plan:
   - Fix issues both reviewers identified
   - Address valid concerns from either reviewer
   - Discard conflicting or minor suggestions

3. **Track changes** - add a "Revision History" section to the plan noting what changed each round

4. **Stop early** if reviewers indicate no further changes needed

5. **Update thread_id** after each round — use the latest `thread_id` from the response

After completing all rounds (or stopping early), proceed to Phase 4.

## Phase 4: Implement

**If `--dry-run`:** Skip to Phase 6 (Summary) - report the plan without implementing.

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

## Phase 5: Final Review

**If `--skip-final`:** Skip to Phase 6 (Summary).

After implementation is complete, get a final review using the same reviewer(s) from Phase 2.

1. **Generate the diff** - get the full diff of all changes made

2. **Consult the reviewer(s)** based on the flag:

### If `--gemini`: Gemini only

Call `mcp__consult-llm__consult_llm` with:
- `model`: "gemini"
- `prompt`: Final review prompt below
- `git_diff`: `{ "files": [list of changed files], "base_ref": "HEAD~N" }` (where N is number of commits)
- `thread_id`: The `gemini_thread_id` from Phase 2/3.5 (reviewer already knows the plan)

### If `--codex`: Codex only

Call `mcp__consult-llm__consult_llm` with:
- `model`: "openai"
- `prompt`: Final review prompt below
- `git_diff`: `{ "files": [list of changed files], "base_ref": "HEAD~N" }`
- `thread_id`: The `codex_thread_id` from Phase 2/3.5

### If `--claude`: Claude subagent

Use the Task tool with `subagent_type: "general-purpose"` and instruct it to run `git diff` to see changes.

### If no flag (default): Both Gemini and Codex in parallel

Spawn BOTH as parallel subagents (`Agent` tool, `subagent_type: "general-purpose"`, `model: "sonnet"`). NEVER run subagents in the background — always run them in the foreground so you can process their results immediately. Each subagent prompt must include the full review prompt, git_diff details, and thread_id.

**Gemini subagent** — prompt must include:
- Call `mcp__consult-llm__consult_llm` with `model: "gemini"`, `prompt`: the final review prompt, `git_diff`: `{ "files": [list of changed files], "base_ref": "HEAD~N" }`, `thread_id`: `gemini_thread_id` from Phase 2/3.5
- Return the COMPLETE response including any `[thread_id:xxx]` prefix

**Codex subagent** — prompt must include:
- Call `mcp__consult-llm__consult_llm` with `model: "openai"`, `prompt`: the final review prompt, `git_diff`: `{ "files": [list of changed files], "base_ref": "HEAD~N" }`, `thread_id`: `codex_thread_id` from Phase 2/3.5
- Return the COMPLETE response including any `[thread_id:xxx]` prefix

---

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
   - Commit each fix separately with clear messages

4. **Skip minor style suggestions** - don't refactor for style alone

## Phase 6: Summary

Present a final summary to the user:

```
## Summary

**Implemented:** [One sentence describing what was built]

**Planning sources:**
- Gemini contributed: [key idea]
- Codex contributed: [key idea]
- Resolved conflicts: [if any]

**Post-implementation fixes:**
- [Fix applied after final review, if any]

**Commits:**
- `abc1234` - [commit message]
- `def5678` - [commit message]
```
