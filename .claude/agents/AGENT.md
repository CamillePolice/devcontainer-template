# AGENTS.md

Use `bd` for task tracking.

## Workflow

1. **Before starting any task** — run `bd ready` to see available tasks with no blockers.
2. **Claim a task** — run `bd update <id> --claim` before working on it.
3. **Create a task** — run `bd create "Title" -p <priority>` if the task doesn't exist yet (0 = critical, 3 = low).
4. **Link dependencies** — run `bd dep add <child> <parent>` to express blocking relationships.
5. **Complete a task** — run `bd update <id> --status done` when finished.

## Rules

* Always check `bd ready` before starting a new task — never work on a blocked task.
* Always claim a task before working on it to avoid conflicts in multi-agent workflows.
* Use `bd show <id>` to inspect task details and audit trail before making decisions.
* Prefer updating existing tasks over creating duplicates — search with `bd list` first.

# AGENTS.md

Use `bd` for task tracking.

## Workflow

1. **Before starting any task** — run `bd ready` to see available tasks with no blockers.
2. **Claim a task** — run `bd update <id> --claim` before working on it.
3. **Create a task** — run `bd create "Title" -p <priority>` if the task doesn't exist yet (0 = critical, 3 = low).
4. **Link dependencies** — run `bd dep add <child> <parent>` to express blocking relationships.
5. **Complete a task** — run `bd update <id> --status done` when finished.

## Rules

* Always check `bd ready` before starting a new task — never work on a blocked task.
* Always claim a task before working on it to avoid conflicts in multi-agent workflows.
* Use `bd show <id>` to inspect task details and audit trail before making decisions.
* Prefer updating existing tasks over creating duplicates — search with `bd list` first.
