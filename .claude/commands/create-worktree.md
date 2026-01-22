---
allowed-tools: Bash(sh .claude/scripts/setup-worktree.sh :*), Bash(gh :*)
description: Create a worktree for a given feature.
---

If issues is provided, fetch it to get the information about the issues with `gh` CLI.

Run `sh .claude/scripts/setup-worktree.sh <name-of-the-branch>` for the given feature.

- `name-of-the-branch` should not include `/` because it will be used as a folder name
