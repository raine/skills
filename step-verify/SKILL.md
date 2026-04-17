---
name: step-verify
description: Verify review findings one by one, pausing after each to discuss with the user before continuing.
allowed-tools: Bash, Glob, Grep, Read, Write, Edit, Agent, AskUserQuestion
disable-model-invocation: true
---

Verify review findings from the current conversation step by step, pausing after each for discussion.

**Arguments:** `$ARGUMENTS`

## Phase 1: Extract Findings

1. Look at the conversation context for review findings, issues, or behavioral differences
2. If `$ARGUMENTS` specifies a subset (e.g. "items 1-5", "critical only"), filter accordingly
3. Number each finding for tracking

## Phase 2: Verify Each Finding

Go through findings **one at a time**, in order.

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
- **Check documentation**: When the claim is about library behavior, verify against actual docs or source
- **Compare outputs**: When the claim is about differing output formats, run both implementations and diff

### 2c. Report Verdict

Show progress like **"Finding 3/10:"** and report:

- **CONFIRMED**: The finding is accurate and is a real issue
- **NOT AN ISSUE**: The finding is technically correct but doesn't matter in practice (explain why)
- **INCORRECT**: The finding is wrong (show evidence)
- **UNABLE TO VERIFY**: Cannot test this without external resources/setup (explain what's needed)

Show the evidence (command output, code snippets, script results) that supports your verdict.

### 2d. Pause for Discussion

Use `AskUserQuestion` to let the user respond before continuing. Offer context-appropriate options (e.g. "Continue", "Fix this now", "Skip remaining", "Show more detail").

Wait for the user's response. If they want to fix the issue now, do so before moving on. Then proceed to the next finding.

## Phase 3: Summary

After all findings are verified, present a summary table:

```
# Verified  | # Not an Issue  | # Incorrect  | # Unable to Verify
```

List the confirmed issues and ask which ones the user wants to fix.

## Guidelines

- Be empirical, not theoretical — run code, don't just read it
- Keep adhoc scripts minimal and focused
- Clean up temp scripts when done
- If a finding is ambiguous, err on the side of testing it
- When comparing two implementations, test BOTH — don't assume one is correct
