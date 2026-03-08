# CLAUDE.md

## Project Overview
${PROJECT_NAME} — [description courte]

## Key Commands
```bash
[start]
[test]
[build]
```

---
## Coding Standards
- [conventions non-standard uniquement]

---

## Task Tracking (Beads)

Use `bd` (Beads) for task tracking and persistent agent memory across sessions.
Always check `bd ready` before starting a new task.

| Command | Action |
|---------|--------|
| `bd ready` | List tasks with no open blockers — start here |
| `bd create "Title" -p 0` | Create a P0 (critical) task |
| `bd update <id> --claim` | Atomically claim a task (sets assignee + in_progress) |
| `bd dep add <child> <parent>` | Link tasks (blocks, related, parent-child) |
| `bd show <id>` | View task details and audit trail |

Beads uses hash-based IDs (`bd-a1b2`) to prevent merge collisions.
Run `bd init --stealth` if you want local-only tracking without committing to the repo.

---

## AI Agent Behavior
After every non-trivial task (unexpected error, project-specific convention, reusable pattern), invoke `capture-learning` before responding "done".

At the start of any task, load relevant context from the RAG knowledge base before writing code.

--- 