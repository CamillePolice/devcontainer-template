
# Rule: Performance & Context Management

> Meta-rules applied before any agent or RAG is loaded.

## Model selection

| Task                                      | Model      |
| ----------------------------------------- | ---------- |
| Planning, architecture, complex reasoning | `opus`   |
| Coding, refactoring, reviews              | `sonnet` |
| Simple edits, formatting, renaming        | `haiku`  |

Default to `sonnet` unless the task clearly requires deep reasoning.

## Context window

* Never enable more than 10 MCP servers simultaneously
* Use `strategic-compact` skill proactively at session inflection points
* Prefer targeted reads over full file reads

```bash
# Prefer this
grep -n "functionName" src/app/service.ts
# Over this
cat src/app/service.ts
```
