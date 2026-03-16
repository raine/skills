---
name: brainstorm
description: Turn an idea into a concrete design through structured dialogue.
---

Turn an idea into a concrete design through structured dialogue.

User idea: $ARGUMENTS

## Phase 1: Understand the Idea

Start by understanding what exists and what the user wants.

1. If relevant, explore the codebase to understand current state
2. Use `AskUserQuestion` to ask clarifying questions **one at a time**
3. Keep asking until you have enough clarity to propose solutions

Rules for questions:

- ONE question per message (never batch multiple questions)
- Use `AskUserQuestion` with 2-4 options whenever possible
- Keep option labels concise (1-5 words), use descriptions for details
- User can always select "Other" for custom input
- If you realize you misunderstood something, acknowledge it and course-correct

## Phase 2: Explore Approaches

Once you understand the idea, propose 2-3 different approaches.

Present them conversationally:

- Lead with your recommended approach and explain why
- Describe alternatives with their trade-offs
- Be honest about complexity, limitations, and unknowns
- Apply YAGNI ruthlessly - remove features that aren't essential

Format:

```
**Recommended: [Approach Name]**
[Why this is the best fit for your needs]

**Alternative: [Approach Name]**
[When you'd choose this instead]

**Alternative: [Approach Name]** (if applicable)
[Different trade-offs this offers]
```

Use `AskUserQuestion` to get buy-in on which approach to design.

## Phase 3: Present the Design

Break the design into digestible sections (200-300 words each).

After each section, use `AskUserQuestion` to validate before continuing.

Cover as appropriate:

- Architecture and structure
- Key components and their responsibilities
- Data flow and state management
- Error handling strategy
- Testing approach
- Migration path (if changing existing code)

## Phase 4: Document (Optional)

If the user wants to preserve the design:

- Write to a markdown file at `history/<date>-design-<topic>.md` (e.g. `history/2026-02-15-design-auth-flow.md`)
- Include context, decisions made, and rationale

## Principles

- **One question at a time** - never batch multiple questions
- **Use AskUserQuestion** - provides clickable options, faster for the user
- **YAGNI** - ruthlessly cut unnecessary features
- **Explore alternatives** - don't anchor on the first idea
- **Validate incrementally** - check understanding at each step
- **Stay flexible** - adapt when you learn you misunderstood
- **Design before code** - resist the urge to implement prematurely
