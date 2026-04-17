# claude-skills

- **auto** — Autonomously create a plan, consult Gemini and Codex for
  improvements, apply feedback, and implement. No user interaction.
- **bash-script-writer** — Write clean, reliable, standards-compliant bash
  scripts (lowercase variables, no `.sh` extension, strict mode).
- **blog-media-processor** — Convert photos and videos to web-optimized formats
  and place them in the right blog post directory.
- **brainstorm** — Turn an idea into a concrete design through structured
  dialogue, asking clarifying questions one at a time.
- **collab** — Have Gemini and Codex collaboratively brainstorm solutions across
  rounds, building on each other's ideas. Agent synthesizes the best ideas into
  a plan.
- **collab-vs** — Brainstorm collaboratively with one opponent LLM (Gemini or
  Codex) in alternating turns, then synthesize the best ideas.
- **commit** — Commit the staged changes. If there are no staged changes, stage
  all changes first.
- **consult** — Consult an external LLM (Gemini, Codex, or both) with the user's
  query.
- **consult-auto** — Consult Gemini and Codex for high-level planning,
  synthesize into a detailed plan, implement, then get a final review. No user
  interaction.
- **coordinator** — Orchestrate multiple worktree agents — spawn, monitor,
  communicate, and merge — without implementing tasks itself.
- **copy-to-slack** — Convert a markdown file to Slack-ready rich text and copy
  it to the clipboard.
- **cs** — Commit all pending changes as separate, logical commits using
  git-surgeon for hunk-by-hunk grouping.
- **debate** — Have Gemini and Codex debate the best approach. Agent moderates,
  synthesizes the best solution, and implements it.
- **debate-vs** — Debate one opponent LLM (Gemini or Codex) through multi-turn
  MCP conversation, then synthesize and implement.
- **debate3** — Three-way debate between Gemini, Codex, and MiniMax. Each
  proposes, critiques the others, then the agent moderates and implements.
- **deep-investigate** — Multi-phase investigation that produces a directory of
  deeply-researched section documents instead of one shallow summary.
- **git-surgeon** — Non-interactive hunk-level git staging, unstaging,
  discarding, undoing, fixup, amend, squash, splitting, and reordering by hunk
  ID.
- **merge** — Commit, rebase, and merge the current branch via `workmux merge`.
- **open** — Find dev servers running in tmux panes and open them in the
  browser. Accepts freetext or a path.
- **pilot** — Autonomous agent that takes a task from understanding to
  implementation to review, adaptively consulting external LLMs based on task
  complexity.
- **qc** — Stage all changes and commit directly without checking status or diff
  first.
- **rebase** — Rebase the current branch onto local main, origin/main, or
  another branch.
- **review** — Review pending changes with external LLMs (Gemini, Codex, Claude,
  or all in parallel).
- **step** — Walk through a multi-point topic step by step, pausing after each
  point to discuss with the user.
- **step-verify** — Verify review findings one by one, pausing after each to
  discuss with the user before continuing.
- **test-writer** — Write clear, maintainable test suites with assertive
  present-tense naming and consistent structure.
- **tmux-dev** — Develop and test TUI/CLI applications by driving a secondary
  tmux pane as a live test terminal.
- **try-all** — Delegate each of several proposed options to a separate AI agent
  in its own git worktree, so they can be compared.
- **update-pr** — Update the current PR description based on the latest changes
  in the session.
- **verify** — Manually verify review findings one by one by running code,
  writing ad-hoc scripts, and comparing actual behavior instead of implementing
  blindly.
- **workmux** — Reference for the `workmux` CLI that pairs git worktrees with
  tmux windows as isolated dev environments.
- **worktree** — Launch one or more tasks in new git worktrees using workmux.
  Pure dispatcher: writes prompt files and runs `workmux add`.
- **write-plan** — Create an implementation plan for a multi-step task.
  Optionally review the plan with external LLMs.
- **write-plan-consult** — Create an implementation plan by brainstorming with
  Gemini and Codex, synthesizing the best ideas, then getting their review.
