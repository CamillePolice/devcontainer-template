---
name: generating-git-commits
description: Generates commit messages following Conventional Commits v1.0.0. Use when committing, staging changes, or user mentions conventional commits.
allowed-tools:
  - Bash
  - AskUserQuestion
---

# Conventional Commits Generator

## Rules

**Format:** `<type>(<scope>): <description>`

**Types:**
- `feat` - New feature (MINOR)
- `fix` - Bug fix (PATCH)
- `refactor`, `docs`, `style`, `test`, `chore`, `perf`, `ci`, `build`

**Subject line:**
- Imperative mood: "add" not "added"
- Lowercase, no period, under 72 chars
- Be specific: "add JWT validation" not "update code"

**Never include:**
- AI attribution, "Generated with", "Co-Authored-By: Claude"
- Emojis

## Workflow

1. **Check state:** `git status` and `git diff --staged`
2. **Determine type** from changes
3. **Choose scope** (optional): component/module name
4. **Write message** following rules above
5. **Ask confirmation** before committing - use AskUserQuestion
6. **Commit** only after user approval

## Breaking Changes

```
feat(api)!: redesign auth endpoints

BREAKING CHANGE: endpoints moved from /auth to /api/v2/auth
```

## Multi-line Example

```bash
git commit -m "perf(db): optimize user queries

Add composite index on (email, created_at).
Reduces query time from 450ms to 110ms.

Closes #234"
```
