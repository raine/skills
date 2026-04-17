---
name: deep-investigate
description: Orchestrates a multi-phase investigation that produces a directory of deeply-researched section documents instead of one shallow summary.
disable-model-invocation: true
---

# Deep Investigate

The problem this skill solves: when asked to investigate something non-trivial, a single agent tends to write a short, shallow markdown summary — a few bullets per topic, no file paths, no code excerpts, no edge cases. The investigation fits in one context window, so anything that doesn't fit gets compressed out. The result reads like a table of contents, not a reference document.

This skill fixes that by splitting the work. One scout pass produces an outline grounded in real exploration. Then each section is researched by its own subagent, with its own fresh context window, its own depth budget, and a clearly bounded scope. The outputs get stitched into a directory of long, concrete section files plus an index.

## When to use

Trigger when the user explicitly asks for depth on a non-trivial topic. Examples that should trigger:

- "Do a deep investigation of how authentication works in this codebase"
- "Write me a detailed report on the event loop in Node"
- "I want a thorough writeup of the payment flow"
- "Really dig into why the build is slow and document everything"
- "Research transformers in depth and give me something I can refer back to"

Do **not** trigger for quick questions ("how does X work?", "what does this function do?", "find the file that handles Y"). Those get a direct answer, not a skill invocation. If the topic is small enough to fit in a few paragraphs, don't use this skill.

## The four phases

### Phase 1 — Scout

Before drafting an outline, do a real reconnaissance pass over the topic yourself (not a subagent). The goal is to know enough about the actual material that the outline reflects reality, not a generic template.

For codebases: use Glob/Grep/Read to find the entry points, the main modules, the data structures, the tests. Collect concrete file paths you'll hand to section agents later.

For external topics: a few WebSearch / WebFetch calls to establish the real landscape — which subtopics exist, which are contested, which have good primary sources.

For mixed topics: do both.

Keep scouting lean. You're not writing anything yet — you're just loading enough context to decide how the topic actually decomposes. 10–20 tool calls is usually plenty.

### Phase 2 — Outline

Write `history/YYYY-MM-DD-<topic-slug>/00-outline.md`. The outline is not just a list of headings — it's the contract that section agents will work from. Each section entry must include:

- **Title** — what the section is called
- **Scope** — 2–4 sentences saying exactly what this section covers
- **Boundaries** — what this section does *not* cover (and which sibling section covers it instead). This is what keeps parallel agents from overlapping or contradicting each other.
- **Anchors** — concrete starting points the agent should use: file paths, function names, URLs, primary sources you found in the scout phase.
- **Key questions** — 3–6 specific questions the section must answer.

Aim for 3–8 sections. Fewer if the topic is narrow, more if it genuinely decomposes into many pieces. If you catch yourself writing a 12-section outline, the topic is either too broad or the sections are too small — reconsider.

The slug in the directory name should be short, lowercase, hyphenated, and descriptive (`auth-flow`, not `investigation-report`).

### Phase 3 — Fan out

Proceed immediately after writing the outline — no pause for approval. For each section in the outline, spawn one subagent in parallel using the `Agent` tool with `subagent_type: "Explore"` and `thoroughness: "very thorough"`. **All section agents go in a single message with multiple Agent tool calls** — that's what makes this parallel.

Each subagent prompt must be self-contained (subagents can't see this conversation). Use this structure:

```
You are writing one section of a multi-section investigation.

TOPIC: <the overall investigation topic>
YOUR SECTION: <section title>

SCOPE (what you cover):
<scope from outline>

BOUNDARIES (what you do NOT cover):
<boundaries from outline — name the sibling sections that cover adjacent material>

STARTING ANCHORS:
<file paths, URLs, function names from the outline>

KEY QUESTIONS YOU MUST ANSWER:
<the section's key questions>

DEPTH REQUIREMENTS:
Write exhaustively. This is a reference document, not a summary. For every
claim, include the concrete evidence — file paths with line numbers (path:line),
short code excerpts where they clarify, direct quotes from docs with source
URLs. Cover edge cases, error paths, and gotchas. Do not stop at "here's how
the happy path works." If you find something surprising, document the surprise.
Sections of 400+ lines are normal and expected when the material supports it;
do not pad, but do not cut for brevity either.

Do not speculate. If something is unclear after investigating, say so
explicitly and note what you'd need to resolve it.

OUTPUT:
Write your section to this exact path: <absolute path to NN-slug.md>
Use the file as the single source of truth for your findings — do not also
return a summary in your final message. Your final message should just confirm
the file was written and note anything the orchestrator needs to know
(e.g., overlaps you noticed with a sibling section, questions you couldn't
resolve).

FORMAT:
Start the file with:
# <Section Title>

Then use ## and ### for substructure as the material requires. Link generously
to file paths (as `path:line`) and external URLs.
```

Numbering: sections are written to `01-<slug>.md`, `02-<slug>.md`, … in the same directory as the outline. The numbers must match the outline order so the reader can follow along.

### Phase 4 — Stitch and index

After all section agents finish:

1. Skim each file you got back. You're looking for two things: gaps the agent flagged, and overlap/contradiction between siblings. Don't re-read exhaustively — trust the agents for the content, just check the seams.
2. Write `index.md` in the investigation directory. It contains:
   - The topic, the date, and a 2–4 sentence abstract of the overall findings
   - A linked table of contents: `- [01 — Section Title](01-slug.md) — one-line summary`
   - A "gaps and open questions" section listing anything agents flagged as unresolved
   - A "how to read this" note if the sections have a suggested reading order
3. Report back to the user with the directory path and a short summary of what's in it. Do not paste the full content of sections into the reply — the whole point is that the reference lives on disk.

## Output contract

After a successful run, the filesystem looks like this:

```
history/2026-04-13-auth-flow/
  00-outline.md        <- the outline from phase 2
  01-entry-points.md   <- section agent output
  02-session-mgmt.md
  03-token-refresh.md
  04-error-paths.md
  index.md             <- final index from phase 4
```

The directory name is `YYYY-MM-DD-<slug>` under `history/` (per the user's CLAUDE.md convention — `history/` is git-ignored and symlinked across worktrees, so this is the right place for investigation artifacts).

If `history/` doesn't exist in the current working directory, create it.

## Why this works (and common pitfalls)

**Why fresh context windows matter.** A single agent investigating five topics has to compress the first four to make room for the fifth. A subagent investigating one topic with a clear scope doesn't. That's most of the reason sections come out deeper this way — not the parallelism, the isolation.

**Why the boundaries field is essential.** Without it, two sibling agents will both explain "what a JWT is" because both feel obligated to give context. With it, section 2 says "tokens are covered in section 3, assume the reader has read it" and moves on. Name sibling sections explicitly in the boundaries.

**Why anchors matter.** A subagent with a vague scope ("error handling") will write a generic essay. A subagent told "start at `src/auth/errors.ts:1` and `src/middleware/error.ts:42`, and look at how `AuthError` is caught in the test suite" will write something concrete. The scout phase exists to gather these anchors.

**Don't let sections go meta.** Section agents should write *about the topic*, not about their own process. If you see "In this section we will explore…" delete it and replace with the actual finding. This is worth calling out in the subagent prompt if you notice it happening.

**Don't pause for outline approval.** The user opted out of this. Write the outline, start the subagents in the same turn. The user will review the final result.

**Don't write a stitched long-doc version.** The user chose the directory-of-sections layout, not the single-stitched-file layout. The `index.md` is the navigation hub; there is no separate concatenated file.
