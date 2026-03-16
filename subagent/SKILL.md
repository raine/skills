---
name: subagent
description:
  Use it when the user asks to "use a subagent", "spawn an agent", or "run this
  in background"
allowed-tools: Read, Glob, Grep, Task
---

When the user wants to delegate a task to a subagent:

**1. Analyze the Request**:

- Determine what the user wants accomplished
- Identify if context gathering is needed first
- Use Glob/Grep/Read to gather relevant files if needed

**2. Choose the Right Subagent Type**:

| Type              | Use When                                                                  |
| ----------------- | ------------------------------------------------------------------------- |
| `Explore`         | Searching codebase, finding patterns, answering "where/how" questions     |
| `general-purpose` | Complex multi-step tasks, code changes, research requiring multiple tools |
| `Plan`            | Planning implementations, exploring before designing solutions            |

**3. Launch the Subagent**:

Use the `Task` tool with:

- `subagent_type`: One of the types above
- `description`: Short 3-5 word summary (e.g., "Find auth implementations")
- `prompt`: Detailed instructions including:
  - What to search for or accomplish
  - What information to return
  - Any constraints or focus areas
- `model`: Always use `opus`

**Example prompts**:

```
For exploration:
"Search the codebase for all API endpoint definitions. Look in route files,
controllers, and any framework-specific patterns. Return a list of endpoints
with their HTTP methods, paths, and file locations."

For general tasks:
"Investigate how error handling works in this codebase. Find:
1. Custom error classes
2. Global error handlers
3. How errors are logged
Return a summary with file paths and line numbers for each finding."

For planning:
"Explore the authentication system to understand how to add OAuth support.
Find current auth implementations, middleware patterns, and session handling.
Return architectural recommendations for adding OAuth."
```

**5. Present Results**:

- Summarize the subagent's findings clearly
- Include file references (path:line_number format)
- Highlight actionable items or next steps

**Critical Rules**:

- Write detailed, specific prompts - the subagent works autonomously
- Specify exactly what information should be returned
- For parallel independent tasks, launch multiple subagents in one message
- Subagents cannot ask follow-up questions, so frontload all instructions
