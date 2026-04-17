---
name: consult
description: Consult an external LLM with the user's query.
allowed-tools: Glob, Grep, Read, mcp__consult-llm__consult_llm
---

Consult an external LLM with the user's query.

**Arguments:** `$ARGUMENTS`

Check the arguments for flags:

**Reviewer flags** (mutually exclusive):
- `--gemini` → consult only Gemini
- `--codex` → consult only Codex
- No flag → consult both Gemini and Codex in parallel (default)

**Mode flags:**
- `--browser` → use web mode (copy prompt to clipboard)
- `--skip-explore` → skip file exploration, consult with only the user's query and any explicitly mentioned files

Strip all flags from arguments to get the user query.

When consulting with external LLMs:

**1. Gather Context First**:

**If `--skip-explore`:** Skip file exploration. Only use files the user explicitly mentioned or referenced. Proceed directly to step 2.

- Use Glob/Grep to find relevant files
- Read key files to understand their relevance
- Select files directly related to the question

**2. Call the MCP Tool**:

Based on the reviewer flag:

### If `--gemini`: Gemini only

Call `mcp__consult-llm__consult_llm` with:
- `model`: "gemini"
- `prompt`: The user's query, passed through faithfully (see Critical Rules)
- `files`: Array of relevant file paths

### If `--codex`: Codex only

Call `mcp__consult-llm__consult_llm` with:
- `model`: "openai"
- `prompt`: The user's query, passed through faithfully (see Critical Rules)
- `files`: Array of relevant file paths

### If no flag (default): Both Gemini and Codex in parallel

Spawn BOTH as parallel subagents (`Agent` tool, `subagent_type: "general-purpose"`, `model: "sonnet"`). NEVER run subagents in the background — always run them in the foreground so you can process their results immediately. Each subagent prompt must include the full query and file list so it can make the MCP call independently.

**Gemini subagent** — prompt must include:
- Call `mcp__consult-llm__consult_llm` with `model: "gemini"`, `prompt`: the user's query (passed through faithfully), `files`: [array of relevant file paths]
- Return the COMPLETE response

**Codex subagent** — prompt must include:
- Call `mcp__consult-llm__consult_llm` with `model: "openai"`, `prompt`: the user's query (passed through faithfully), `files`: [array of relevant file paths]
- Return the COMPLETE response

### If `--browser`: Web mode

Call `mcp__consult-llm__consult_llm` with:
- `web_mode`: true
- `prompt`: The user's query, passed through faithfully (see Critical Rules)
- `files`: Array of relevant file paths
- (model parameter is ignored in web mode)

**3. Present Results**:

- **API mode**: Summarize key insights, recommendations, and considerations from
  the response. When multiple LLMs were consulted, synthesize their responses —
  highlight agreements, note disagreements, and present a unified summary.
- **Web mode**: Inform user the prompt was copied to clipboard and ask them to
  paste it into their browser-based LLM and share the response back

**Critical Rules**:

- ALWAYS gather file context before consulting
- **Pass through the user's query faithfully** — do NOT add your own theories,
  suspects, analysis, or suggested solutions to the prompt. The user's words are
  the prompt. You may lightly rephrase for clarity or add brief factual context
  (e.g. "we recently changed X to Y"), but never inject your own diagnostic
  opinions or hypotheses.
- Provide focused, relevant files (quality over quantity)
