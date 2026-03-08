# Beads — Graph Issue Tracker for AI Agents

Beads is a distributed, git-backed graph issue tracker designed to give AI coding agents persistent, structured memory across long-horizon tasks.

**Repository:** [steveyegge/beads](https://github.com/steveyegge/beads)

## What it does

Beads replaces flat markdown task lists with a dependency-aware graph backed by [Dolt](https://github.com/dolthub/dolt) — a versioned SQL database with native branching and merge support. This allows agents to track tasks, dependencies, and context without losing state between sessions.

## Installation in this devcontainer

Set `USE_BEADS=true` in `devcontainer.json` → the `install_beads.sh` script runs automatically during `post_create.sh` and:

1. Installs the `bd` CLI globally via `npm install -g @beads/bd`
2. Runs `bd init` in the project root (creates the `.beads/` directory)

## Essential Commands

| Command | Action |
|---------|--------|
| `bd ready` | List tasks with no open blockers |
| `bd create "Title" -p 0` | Create a P0 task |
| `bd update <id> --claim` | Atomically claim a task |
| `bd dep add <child> <parent>` | Link tasks as dependencies |
| `bd show <id>` | View task details and audit trail |
| `bd list` | List all tasks |

## Hierarchy

Beads supports hierarchical IDs for epics:

```
bd-a3f8       (Epic)
bd-a3f8.1     (Task)
bd-a3f8.1.1   (Sub-task)
```

## Useful options

**Stealth mode** — track tasks locally without committing to the repo:
```bash
bd init --stealth
```

**Contributor mode** — routes planning issues to a separate repo (useful on open-source projects):
```bash
bd init --contributor
```

## Agent integration

`CLAUDE.md` already instructs Claude Code to use `bd` for task tracking. The key workflow for agents:

1. `bd ready` — check what's available to work on
2. `bd update <id> --claim` — claim the task before starting
3. Work on the task
4. `bd update <id> --status done` — mark as done when finished

## Environment variable

| Variable | Default | Description |
|----------|---------|-------------|
| `USE_BEADS` | `false` | Set to `true` to install and initialize Beads |