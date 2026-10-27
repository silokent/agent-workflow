# agent-workflow

**English** · [Tiếng Việt](README.vi.md)

Talk to one agent, get the work of five. **Claude Code is the orchestrator**: you only chat with it, and it hands research, planning, coding, image generation and review to **Codex CLI** running different models, then checks the result itself before reporting back.

```
you ──► Claude Code (Orchestrator) ──► Researcher  read-only + web search      → docs/research/
                                     ├► Planner     writes the plan              → TASK.md
                                     ├► Artist      every image (sprite, icon…)  → assets
                                     ├► Executor    writes code, never runs tests
                                     └► Reviewer    re-reads the diff, writes its own tests, ≤ 3 rounds
        ◄── Orchestrator re-runs the tests, reads the diff, does manual checks, reports
```

It was built for web, browser-game and app projects, but nothing in it is web-specific. One kit, installed once, reused across every repo.

> The rules the agents follow (`WORKFLOW.md`, `roles/*.md`, `templates/`) are written in **Vietnamese**. The models read them fine. If you want them in English, translate those files; the scripts don't care what language they're in.

## Why

Running several coding agents by hand usually breaks down in the same places:

- **Context lives in chat sessions.** Close the session, switch machines, or let a Codex thread expire, and nobody knows what was decided or what step comes next.
- **The agent that wrote the code also grades it.** It writes tests that match its own assumptions and reports "all green".
- **Copy-pasting between tools.** You plan in one agent, paste the brief into another, then paste the result back.
- **Git accidents.** An agent pulls into a dirty tree or pushes over someone else's work.

This kit takes those four problems on directly.

## How it works

### 1. One orchestrator, specialised workers
Claude Code runs the skill `orchestrate`. It calls workers through one command:

```bash
agent-run <researcher|planner|executor|reviewer|artist> [--hard] [--resume] "<brief>"
```

`agent-run` wraps `codex exec`. For each role it:
- picks the model, reasoning effort, sandbox and network access from `roles.conf`;
- puts the role's instructions (`roles/<role>.md`) in front of the brief;
- runs Codex in the background and keeps the full log in `.agent-workflow/runs/`;
- prints only Codex's final structured answer (`KẾT QUẢ: …`), so the orchestrator's context stays small.

A write lock makes sure only one role writes to the repo at a time.

Default roles, all configurable per machine or per project:

| Role | Default model (Codex) | May write |
|---|---|---|
| Orchestrator | Claude Code | nothing in the product code; coordinates, verifies, reports |
| Researcher | `gpt-6.1-sol`, high, web search | nothing (read-only sandbox); report saved by `agent-run` |
| Planner | `gpt-6-astra`, high | `TASK.md` only |
| Executor | `gpt-6.1-sol`, xhigh · `--hard`: `gpt-6-astra`, medium | product code within the plan, never test files |
| Reviewer | `gpt-6.1-sol`, high | test files + the review section |
| Artist | `gpt-6.1-sol`, high | image files + `docs/assets/PROMPTS.md` |

To change a model, edit `roles.conf`. To change it for one project only, create `.agent-workflow/roles.conf` in that project with just the lines you want to override.

### 2. State lives in files, not sessions
Everything another agent needs to pick up the work is committed to git:

- **`TASK.md`**: the one open task. It has:
  - a status block;
  - an **orchestration section**: the user's original request rewritten so it stands on its own, the current phase, the review round, what we're waiting on the user for, every decision the user made, and a coordination log;
  - the plan;
  - step-by-step progress;
  - review rounds.
- **`docs/tasks/`**: finished tasks, archived automatically when a new task is planned, plus an `INDEX.md`.
- **`docs/research/`**: research reports. **`docs/assets/PROMPTS.md`**: prompts used for images, so you can regenerate them in the same style.

`agent-run` appends a line to the coordination log after every call. `agent-task status` prints a "where are we" summary; a Claude Code **SessionStart hook** injects it into every new session. Lose the chat, lose the Codex thread, or move to another machine: pull, open Claude, say "continue".

The diff baseline is the git ref `refs/agent-base/<task-id>`. Codex's sandbox can't write `.git`, so `agent-run` creates the baseline itself. On another clone where the original baseline commit doesn't exist, it falls back to the HEAD recorded when the plan was made, and tells the reviewer.

### 3. The coder doesn't grade its own work
- The **Planner** records a test baseline (what already passes or fails) when it writes the plan. Each step says what behaviour the reviewer must test.
- The **Executor** never runs, writes or edits tests. It may run build, typecheck or lint so the code at least compiles. If it thinks a reviewer's test is wrong, it stops and explains why; it doesn't touch the test.
- The **Reviewer** re-reads the actual diff and writes **independent tests** from the plan and from the edge cases it spots in the code, not from the executor's notes. It runs them with the existing suite and compares against the baseline. Failures become numbered fix items (`R1`, `R2`…) for the executor. There are at most 3 rounds.
- The **Orchestrator** re-runs everything and does the "check by eye" items (UI, game feel) before telling you it's done.

### 4. Check git before pulling or pushing
`agent-task sync-check pull|push` fetches first, then checks:
- a merge, rebase or cherry-pick left half-done, or files still in conflict;
- uncommitted files that the remote also changed (the pull would refuse or conflict);
- a **simulated merge** with `git merge-tree`, which names the exact files that would conflict;
- whether you're behind the remote (the push would be rejected, or would overwrite with `--force`);
- whether `TASK.md` was changed remotely, meaning another agent or machine touched the task.

A Claude Code **PreToolUse hook** (`agent-task guard`) runs the check automatically and blocks `git pull` / `git push` when it fails. Codex workers never commit, pull or push. Only the orchestrator or you do.

## Requirements

- [Claude Code](https://claude.com/claude-code) and [Codex CLI](https://github.com/openai/codex), both logged in
- `git` ≥ 2.38 (for `merge-tree --write-tree`), `bash`, `jq`, `python3`
- macOS or Linux

## Install

```bash
git clone https://github.com/silokent/agent-workflow.git ~/agent-workflow
~/agent-workflow/install.sh --global              # machine-wide parts only (commands, skills, hooks)
~/agent-workflow/install.sh /path/to/your/project # wire a project (also does the machine-wide parts)
```

`install.sh` does this:

| Where | What |
|---|---|
| your project | inserts or updates the workflow block in `AGENTS.md`, copies `docs/TASK.template.md`, adds `/.agent-workflow/` to `.git/info/exclude`. It never touches `CLAUDE.md` or your project description. |
| `~/.local/bin` | symlinks `agent-run` and `agent-task` |
| `~/.claude/skills` | symlinks `orchestrate`, `plan-task`, `review-task`. An existing non-symlink folder with the same name is moved to `~/agent-workflow/.backup/` first. |
| `~/.claude/settings.json` | adds the SessionStart and PreToolUse hooks if they're missing, after saving `settings.json.bak-agent-workflow` |

You can run it as often as you like; it doesn't add anything twice. Then fill in the top of the project's `AGENTS.md`: what the project is, the test command, and **where tests live**. The planner and the reviewer rely on it.

The rules live in `AGENTS.md`, which Codex reads natively. Claude reads it through the `orchestrate` skill, so you don't need a `CLAUDE.md`.

## Use

Open Claude Code in the project and ask for what you want: "add a combo multiplier to the score", "make a 32×32 coin sprite", "continue". You can also call the tools by hand:

```bash
agent-task status                     # where are we?
agent-task sync-check pull            # safe to pull?
agent-run researcher --save phaser-webgpu "Does Phaser 4 support WebGPU yet?"
agent-run artist "assets/coin.png, 32x32, transparent PNG, pixel art"
agent-run planner --dry-run "…"       # print the codex command only
AGENT_EFFORT=low agent-run reviewer "Review the task in TASK.md."   # one-off effort override
```

Codex runs can take several minutes. The orchestrator always starts them in the background and waits for the completion notice.

## Layout

```
WORKFLOW.md            rules for every agent → inserted into each project's AGENTS.md
roles.conf             model / effort / sandbox / network per role
roles/*.md             per-role instructions sent to Codex
bin/agent-run          dispatch one role to Codex
bin/agent-task         status · archive · sync-check · guard (Claude hook)
bin/journal.py         append to the coordination log in TASK.md
skills/                orchestrate · plan-task · review-task (Claude Code skills)
templates/             TASK.md · AGENTS.project.md
```

## Safety notes

- Workers run `codex exec` with no approval prompts, inside Codex's `workspace-write` sandbox (the Researcher is `read-only`). The Executor, Reviewer and Artist have **network access** turned on so they can install packages or generate images; turn it off in `roles.conf` if you don't want that.
- Nothing is ever force-pushed. The guard hook can only be skipped by prefixing a command with `AGENT_SYNC_OK=1`, and the orchestrator is told to do that only when you explicitly say so.
- Read `install.sh` before running it: it edits `~/.claude/settings.json`, and keeps a backup next to it.

## Related projects

Other ways to make Claude Code and Codex work together:
- [openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc): official plugin to call Codex from Claude Code (review, delegation)
- [Claudexor](https://www.dsebastien.net/claudexor/): a control plane above several coding agents, with isolated worktrees
- [cc-orchestrator](https://github.com/p3nchan/cc-orchestrator), [claude-codex-orchestrator](https://github.com/junyjeon/claude-codex-orchestrator), [claude-delegate](https://github.com/TuYv/claude-delegate)

This kit's angle is a strict role split, state that survives any session, testing kept separate from the coder, and pre-flight git checks.
