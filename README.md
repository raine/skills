# claude-skills

- **[auto](auto/SKILL.md)** — Autonomously create a plan, consult Gemini and
  Codex for improvements, apply feedback, and implement. No user interaction.
- **[bash-script-writer](bash-script-writer/SKILL.md)** — Write clean, reliable,
  standards-compliant bash scripts (lowercase variables, no `.sh` extension,
  strict mode).
- **[blog-media-processor](blog-media-processor/SKILL.md)** — Convert photos and
  videos to web-optimized formats and place them in the right blog post
  directory.
- **[brainstorm](brainstorm/SKILL.md)** — Turn an idea into a concrete design
  through structured dialogue, asking clarifying questions one at a time.
- **[collab](collab/SKILL.md)** — Have Gemini and Codex collaboratively
  brainstorm solutions across rounds, building on each other's ideas. Agent
  synthesizes the best ideas into a plan.
- **[collab-vs](collab-vs/SKILL.md)** — Brainstorm collaboratively with one
  opponent LLM (Gemini or Codex) in alternating turns, then synthesize the best
  ideas.
- **[commit](commit/SKILL.md)** — Commit the staged changes. If there are no
  staged changes, stage all changes first.
- **[consult](consult/SKILL.md)** — Consult an external LLM (Gemini, Codex, or
  both) with the user's query.
- **[consult-auto](consult-auto/SKILL.md)** — Consult Gemini and Codex for
  high-level planning, synthesize into a detailed plan, implement, then get a
  final review. No user interaction.
- **[coordinator](coordinator/SKILL.md)** — Orchestrate multiple worktree agents
  — spawn, monitor, communicate, and merge — without implementing tasks itself.
- **[copy-to-slack](copy-to-slack/SKILL.md)** — Convert a markdown file to
  Slack-ready rich text and copy it to the clipboard.
- **[cs](cs/SKILL.md)** — Commit all pending changes as separate, logical
  commits using git-surgeon for hunk-by-hunk grouping.
- **[debate](debate/SKILL.md)** — Have Gemini and Codex debate the best
  approach. Agent moderates, synthesizes the best solution, and implements it.
- **[debate-vs](debate-vs/SKILL.md)** — Debate one opponent LLM (Gemini or
  Codex) through multi-turn MCP conversation, then synthesize and implement.
- **[debate3](debate3/SKILL.md)** — Three-way debate between Gemini, Codex, and
  MiniMax. Each proposes, critiques the others, then the agent moderates and
  implements.
- **[deep-investigate](deep-investigate/SKILL.md)** — Multi-phase investigation
  that produces a directory of deeply-researched section documents instead of
  one shallow summary.
- **[git-surgeon](git-surgeon/SKILL.md)** — Non-interactive hunk-level git
  staging, unstaging, discarding, undoing, fixup, amend, squash, splitting, and
  reordering by hunk ID.
- **[merge](merge/SKILL.md)** — Commit, rebase, and merge the current branch via
  `workmux merge`.
- **[open](open/SKILL.md)** — Find dev servers running in tmux panes and open
  them in the browser. Accepts freetext or a path.
- **[pilot](pilot/SKILL.md)** — Autonomous agent that takes a task from
  understanding to implementation to review, adaptively consulting external LLMs
  based on task complexity.
- **[qc](qc/SKILL.md)** — Stage all changes and commit directly without checking
  status or diff first.
- **[rebase](rebase/SKILL.md)** — Rebase the current branch onto local main,
  origin/main, or another branch.
- **[review](review/SKILL.md)** — Review pending changes with external LLMs
  (Gemini, Codex, Claude, or all in parallel).
- **[step](step/SKILL.md)** — Walk through a multi-point topic step by step,
  pausing after each point to discuss with the user.
- **[step-verify](step-verify/SKILL.md)** — Verify review findings one by one,
  pausing after each to discuss with the user before continuing.
- **[test-writer](test-writer/SKILL.md)** — Write clear, maintainable test
  suites with assertive present-tense naming and consistent structure.
- **[tmux-dev](tmux-dev/SKILL.md)** — Develop and test TUI/CLI applications by
  driving a secondary tmux pane as a live test terminal.
- **[try-all](try-all/SKILL.md)** — Delegate each of several proposed options to
  a separate AI agent in its own git worktree, so they can be compared.
- **[update-pr](update-pr/SKILL.md)** — Update the current PR description based
  on the latest changes in the session.
- **[verify](verify/SKILL.md)** — Manually verify review findings one by one by
  running code, writing ad-hoc scripts, and comparing actual behavior instead of
  implementing blindly.
- **[workmux](workmux/SKILL.md)** — Reference for the `workmux` CLI that pairs
  git worktrees with tmux windows as isolated dev environments.
- **[worktree](worktree/SKILL.md)** — Launch one or more tasks in new git
  worktrees using workmux. Pure dispatcher: writes prompt files and runs
  `workmux add`.
- **[write-plan](write-plan/SKILL.md)** — Create an implementation plan for a
  multi-step task. Optionally review the plan with external LLMs.
- **[write-plan-consult](write-plan-consult/SKILL.md)** — Create an
  implementation plan by brainstorming with Gemini and Codex, synthesizing the
  best ideas, then getting their review.
