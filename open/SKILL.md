---
name: open
description: Find dev servers running in tmux panes and open them in the browser. Accepts optional path or port arguments. Use when the user wants to open a dev server, find running servers, or open localhost.
allowed-tools: Bash
---

# Open dev server

Find dev servers running in tmux panes and open in browser.

## Usage

`/open` - list servers, open if only one found
`/open /api/docs` - open with path appended
`/open 3000` - open specific port
`/open 3000/api/docs` - open specific port with path

## Steps

1. Run the discovery script:

```bash
./find-servers.sh
```

2. Parse the tab-separated output: `PANE\tPORT\tCOMMAND`

3. Decide what to open:
   - If `$ARGUMENTS` is a number or starts with a number followed by `/`, treat the number as the target port and the rest as the path
   - If `$ARGUMENTS` starts with `/`, it's a path - append to the chosen server
   - If one server found, use it
   - If multiple servers found, show a table and ask the user to pick
   - If no servers found, tell the user

4. Open in browser:

```bash
open "http://localhost:$PORT$PATH"
```
