---
name: open
description: Find dev servers running in tmux panes and open them in the browser. Accepts optional freetext to identify which server, or a path starting with /. Use when the user wants to open a dev server, find running servers, or open localhost.
allowed-tools: Bash
disable-model-invocation: true
---

# Open dev server

Find dev servers running in tmux panes and open in browser.

## Usage

`/open` - list servers, open if only one found
`/open /api/docs` - open with path appended
`/open my app` - match server by freetext (match against pane name or command)

## Steps

1. Run the discovery script:

```bash
./find-servers.sh
```

2. Parse the tab-separated output: `PANE\tPORT\tCOMMAND`

3. Decide what to open:
   - If `ARGUMENTS` starts with `/`, it's a literal path - append to the chosen server
   - Otherwise, `ARGUMENTS` is freetext - use it to match against pane names and commands to pick the right server
   - If no arguments given, use conversation context to infer which server and path to open
   - If one server found, use it
   - If multiple servers found and context doesn't clarify, show a table and ask the user to pick
   - If no servers found, tell the user

4. Open in browser:

```bash
open "http://localhost:$PORT$PATH"
```

Arguments: $ARGUMENTS
