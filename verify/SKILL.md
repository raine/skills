---
name: verify
description: Manually verify review findings one by one by running code, writing adhoc scripts, and comparing actual behavior instead of implementing blindly.
allowed-tools: Bash, Glob, Grep, Read, Write, Edit, Agent, AskUserQuestion
---

Verify review findings from the current conversation by actually testing each one.

**Arguments:** `$ARGUMENTS`

## Context

The conversation contains review findings (e.g. from `/review`, `/consult`, or a manual code review). These are claims about bugs, behavioral differences, missing features, or other issues. Your job is to **verify each finding empirically** before anyone implements fixes.

## Phase 1: Extract Findings

1. Look at the conversation context for a list of review findings, issues, or behavioral differences
2. If `$ARGUMENTS` specifies a subset (e.g. "items 1-5", "critical only"), filter accordingly
3. Number each finding for tracking

## Phase 2: Verify Each Finding

**Mode:** If `$ARGUMENTS` contains `--parallel`, verify all findings concurrently using parallel Agent calls (one agent per finding). Otherwise, go through findings **one at a time**, in order.

For each finding:

### 2a. Understand the Claim

Read the relevant source files to understand what the finding is actually claiming.

### 2b. Test It

Choose the most appropriate verification method:

- **Read and compare code**: When the claim is about code structure, missing features, or API differences — read both sides and confirm
- **Run the program**: When feasible, run the actual program with inputs that would expose the issue
- **Write an adhoc script**: When the claim involves runtime behavior (env var handling, string formatting, edge cases), write a small throwaway script that isolates and tests the specific behavior
  - Put scripts in `/tmp/verify-*.{sh,ts,py,rs}` or similar
  - Keep them minimal — test exactly the claim, nothing more
- **Check documentation**: When the claim is about library behavior (e.g. "SDK provides automatic retries"), verify against actual docs or source
- **Compare outputs**: When the claim is about differing output formats, run both implementations and diff

### 2c. Report Verdict

For each finding, report:

- **CONFIRMED**: The finding is accurate and is a real issue
- **NOT AN ISSUE**: The finding is technically correct but doesn't matter in practice (explain why)
- **INCORRECT**: The finding is wrong (show evidence)
- **UNABLE TO VERIFY**: Cannot test this without external resources/setup (explain what's needed)

Show the evidence (command output, code snippets, script results) that supports your verdict.

### 2d. Continue

After reporting the verdict for one finding, immediately proceed to the next. Do NOT ask the user between findings — verify all of them in one pass.

## Phase 3: Summary

After all findings are verified, present a summary table:

```
# Verified  | # Not an Issue  | # Incorrect  | # Unable to Verify
```

List the confirmed issues and ask the user which ones they want to fix.

## Guidelines

- Be empirical, not theoretical — run code, don't just read it
- Keep adhoc scripts minimal and focused
- Clean up temp scripts when done
- If a finding is ambiguous, err on the side of testing it
- When comparing two implementations, test BOTH — don't assume one is correct
- With `--parallel`, launch one Agent per finding simultaneously — each agent verifies independently and returns its verdict. Collect all results before producing the summary.
