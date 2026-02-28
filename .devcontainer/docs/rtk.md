# rtk (Rust Token Killer)

[rtk](https://github.com/rtk-ai/rtk) is a CLI proxy that **reduces LLM token consumption by 60–90%** by filtering and compressing command outputs before they reach Claude’s context (e.g. `git status`, `ls`, `cargo test`, `docker ps`).

## Installation in this devcontainer

rtk is installed automatically during **post_create** (after `configure_claude.sh`), when `USE_RTK=true` (default).

- **Binary**: `~/.local/bin/rtk` (already on PATH via `.zshrc`)
- **Claude hook**: `rtk init -g --auto-patch` registers a PreToolUse hook in `~/.claude/settings.json` so that commands like `git status` are transparently rewritten to `rtk git status`

## Verify

```bash
rtk --version
rtk gain          # Token savings stats (must work — confirms rtk-ai/rtk, not Type Kit)
rtk init --show  # Hook installed and executable
```

## Usage

With the hook enabled, you don’t need to type `rtk` yourself: Claude’s executed commands are rewritten automatically. Manual examples:

```bash
rtk git status
rtk ls .
rtk git diff
rtk docker ps
```

## Disable

In `.devcontainer/.env`: `USE_RTK=false`  
To remove hook and context: `rtk init -g --uninstall`  
Restore settings: `cp ~/.claude/settings.json.bak ~/.claude/settings.json`

## Links

- [GitHub rtk-ai/rtk](https://github.com/rtk-ai/rtk)
- [Install guide](https://github.com/rtk-ai/rtk/blob/master/INSTALL.md)
