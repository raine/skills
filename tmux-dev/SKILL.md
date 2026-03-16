---
name: tmux-dev
description: >-
  Develop and test TUI/CLI applications by driving a tmux pane as a live test
  terminal. Use this skill when building interactive terminal apps (TUIs,
  CLIs with interactive prompts, curses/ratatui apps, REPL tools) so you can
  start the app, send keystrokes, capture the screen, and verify output
  yourself — without asking the user to test manually. Also use this when the
  user says things like "check it yourself", "try running it", "see if it
  works", or when you need to visually verify terminal output.
disable-model-invocation: true
---

# tmux-dev

Develop TUI/CLI applications by controlling a secondary tmux pane as your test
terminal. This lets you start the app, interact with it, read its screen
output, and iterate — all without asking the user to do manual testing.

## When to use this

You're already running inside the user's tmux session. When developing anything
interactive (TUIs, CLI tools, curses apps, REPL-based tools), use a separate
tmux pane to run and test the application yourself instead of asking the user
to try it.

## Setup: Get a test pane

First, identify your own window. The user may switch tmux windows at any time,
so always anchor pane operations to your specific window — never rely on the
user's currently focused window.

```bash
# Get your session:window.pane address
CLAUDE_PANE=$(tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}')
CLAUDE_WINDOW=$(tmux display-message -p '#{session_name}:#{window_index}')
```

Then list panes in your window:

```bash
tmux list-panes -t "$CLAUDE_WINDOW" -F '#{pane_index}: #{pane_width}x#{pane_height} #{pane_current_command} (active=#{pane_active})'
```

You (Claude) are running in the active pane. Use a different pane for testing.

**If a free pane exists** (running just `zsh`/`bash`, not actively in use), use
it.

**If no free pane exists**, create one in your window (not the user's current
window):

```bash
tmux split-window -t "$CLAUDE_WINDOW" -h -l 80  # horizontal split, 80 columns wide
```

Store the full pane address (`session:window.pane`) for all subsequent commands.
Use `-t "$CLAUDE_WINDOW.<pane_index>"` to target it. This ensures commands reach
the right pane even if the user has switched to a different tmux window.

## Core commands

These are the building blocks. All commands target the test pane with
`-t "$CLAUDE_WINDOW.<pane_index>"` (e.g. `-t "mysession:3.1"`). Using the
fully-qualified address ensures commands go to the right pane regardless of
which window the user is looking at.

### Send a command

```bash
tmux send-keys -t <pane> 'cargo run' Enter
```

`Enter` (unquoted) sends the Enter key. You can chain keys:
```bash
tmux send-keys -t <pane> 'echo hello' Enter
```

### Send individual keystrokes

For TUI interaction — arrow keys, ctrl combos, single characters:

```bash
tmux send-keys -t <pane> Up          # arrow up
tmux send-keys -t <pane> Down        # arrow down
tmux send-keys -t <pane> Left
tmux send-keys -t <pane> Right
tmux send-keys -t <pane> Enter
tmux send-keys -t <pane> Escape
tmux send-keys -t <pane> Tab
tmux send-keys -t <pane> BSpace      # backspace
tmux send-keys -t <pane> C-c         # ctrl-c
tmux send-keys -t <pane> C-d         # ctrl-d
tmux send-keys -t <pane> C-z         # ctrl-z
tmux send-keys -t <pane> q           # single character
tmux send-keys -t <pane> Space       # space bar
```

To type a string character by character (useful for search/input fields in TUIs):
```bash
tmux send-keys -t <pane> -l 'search term'   # -l sends literal string
```

### Capture the screen

**Regular CLI output:**
```bash
tmux capture-pane -t <pane> -p
```

**TUI apps using alternate screen** (curses, ratatui, etc.):
```bash
tmux capture-pane -t <pane> -p -a
```

The `-a` flag captures the alternate screen buffer that fullscreen TUI apps use.
Without it, you'll get the shell behind the TUI. If `-a` returns an error, the
app isn't using alternate screen — fall back to plain capture.

**Robust capture** (try alternate screen first, fall back to normal):
```bash
tmux capture-pane -t <pane> -p -a -q 2>/dev/null || tmux capture-pane -t <pane> -p
```

**Capture with trailing spaces preserved** (important for layout verification):
```bash
tmux capture-pane -t <pane> -p -a -N
```

### Stop the app

```bash
tmux send-keys -t <pane> C-c
```

If the app doesn't respond to ctrl-c:
```bash
tmux send-keys -t <pane> q          # many TUIs quit on 'q'
tmux send-keys -t <pane> C-c C-c    # double ctrl-c
```

## Waiting for output: poll, don't sleep

Fixed `sleep` durations are wasteful (too long) or unreliable (too short). Use
the bundled `tmux-wait` script to poll the pane until output changes or a
specific pattern appears.

The script is at `scripts/tmux-wait` relative to this skill's directory.

### Basic usage: wait for any change

`tmux-wait` snapshots the pane before you call it, then polls every 0.5s until
the content differs. It prints the final pane capture when done.

```bash
TMUX_WAIT="<skill-dir>/scripts/tmux-wait"

# Start a command, then wait for output to change (default 30s timeout)
tmux send-keys -t <pane> 'cargo run 2>&1' Enter
$TMUX_WAIT <pane>
```

### Wait for specific content

When the pane changes during compilation but the app isn't ready yet, use
`--pattern` / `-p` to wait for a specific string:

```bash
tmux send-keys -t <pane> 'cargo run 2>&1' Enter
$TMUX_WAIT <pane> -p "Listening on"
```

### Custom timeout

Pass timeout in seconds as the last positional argument (default 30):

```bash
$TMUX_WAIT <pane> 60              # wait up to 60s for any change
$TMUX_WAIT <pane> -p "Ready" 60   # wait up to 60s for "Ready"
```

### Exit codes

- **0** — condition met (output changed or pattern found)
- **1** — timed out (prints whatever the pane shows at timeout)

### After keystrokes

For UI interactions (arrow keys, typing), a short fixed sleep is fine — the app is
already running and just needs a frame or two to update:

```bash
tmux send-keys -t <pane> Down Down Enter
sleep 0.3
tmux capture-pane -t <pane> -p -a -q 2>/dev/null || tmux capture-pane -t <pane> -p
```

## Development loop

This is the core workflow when building a TUI/CLI app:

1. **Write/edit the code**
2. **Start the app** in the test pane
3. **Poll for readiness** — capture until output changes or a ready marker appears
4. **Capture the screen** to verify it rendered correctly
5. **Send keystrokes** to interact (navigate menus, type input, trigger actions)
6. **Capture again** to verify the response
7. **Stop the app** when done testing
8. **Iterate** — fix issues and repeat

### Example: testing a Rust TUI

```bash
TMUX_WAIT="<skill-dir>/scripts/tmux-wait"

# Build and run, poll until output appears
tmux send-keys -t 1 'cargo run 2>&1' Enter
$TMUX_WAIT 1

# Interact — navigate down, select an item
tmux send-keys -t 1 Down Down Enter
sleep 0.3

# Check result
tmux capture-pane -t 1 -p -a -q 2>/dev/null || tmux capture-pane -t 1 -p

# Quit
tmux send-keys -t 1 q
```

## Tips

- **Poll, don't sleep.** Never use a fixed `sleep` to wait for a command to
  finish or an app to start. Capture the pane before, run the command, then poll
  until the capture changes. This is both faster (no wasted time) and more
  reliable (adapts to actual build/startup duration).

- **Capture is your eyes.** Read the captured output carefully — look for
  rendering glitches, misaligned columns, missing content, error messages.

- **stderr can go to a file.** If the TUI renders on stdout/alternate screen,
  redirect stderr to catch panics: `'cargo run 2>/tmp/app-stderr' Enter`, then
  read `/tmp/app-stderr` if something goes wrong.

- **Kill stuck processes.** If an app hangs and ctrl-c doesn't work:
  ```bash
  tmux send-keys -t <pane> C-c C-c C-\\
  ```
  Or as a last resort: `tmux send-keys -t <pane> C-z` then
  `tmux send-keys -t <pane> 'kill %1' Enter`

- **Resize the pane** if the TUI needs more space:
  ```bash
  tmux resize-pane -t <pane> -x 120 -y 40
  ```

- **Multiple captures.** For apps that update over time (progress bars,
  animations), capture multiple times with short sleeps between them to observe
  changes.
