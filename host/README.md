# Host: global editor and machine setup

This folder configures your **machine and both editors (VSCode and Cursor)** globally. It is **not tied to any repo** and does not depend on `.devcontainer/`.

## What it does

- **Both VSCode and Cursor**: user-level settings, recommended extensions, keybindings. RAG MCP is configured for both when `USE_RAG=true`.
- **CLI and shell**: zsh, Starship, fzf, ripgrep, bat, eza, zoxide, tldr (Unix). On Windows: optional winget CLI tools.
- **Claude Code**: CLI install and optional global `.claude` config.
- **rtk** (optional): [Rust Token Killer](https://github.com/rtk-ai/rtk) — reduces LLM token consumption 60–90%; installs hook in `~/.claude/settings.json`.
- **Ollama**: optional local LLM (Docker on Linux; on macOS/Windows you install from [ollama.com](https://ollama.com)).
- **Session**: global git config and optional pre-commit.

## Where to put this folder

Anywhere you like: `~/dev-setup`, `~/.config/dev-setup`, or a dotfiles repo. **HOST_DIR** is the directory that contains `run_post_create.sh` (and the other scripts). No git repo is required.

## Prerequisites

- **Linux/macOS**: bash, git. Optional: sudo (apt/dnf/pacman or Homebrew).
- **Windows**: PowerShell, git. Optional: winget or Chocolatey.

## One-time setup

1. Copy `.env.example` to `.env` and edit if needed (e.g. `USE_OLLAMA`, `USE_RAG`, `RAG_DSN`, `WHICH_EDITOR`).
2. Run the one-time setup:
   - **Unix (Linux/macOS)**: `./run_post_create.sh`
   - **Windows**: `.\run_post_create.ps1`

To install **only** the same terminal customizations as the devcontainer (zsh, Oh My Zsh, Starship, tmux + TPM + Catppuccin):

- **Unix**: `./run_terminal_setup.sh`

## Session init (optional)

Run after a fresh clone or when you want to refresh global git/pre-commit:

- **Unix**: `./run_init_env.sh`
- **Windows**: `.\run_init_env.ps1`

## Platforms

| Platform | Entrypoints | Package manager | Editor user dirs |
|----------|-------------|-----------------|------------------|
| Linux | `run_post_create.sh`, `run_init_env.sh` | apt / dnf / pacman | `~/.config/Cursor/User`, `~/.config/Code/User` |
| macOS | Same | Homebrew | `~/Library/Application Support/Cursor/User`, `~/Library/Application Support/Code/User` |
| Windows | `run_post_create.ps1`, `run_init_env.ps1` | winget / choco | `%APPDATA%\Cursor\User`, `%APPDATA%\Code\User` |

On Windows you can also use WSL and run the Unix scripts from the host folder.

## Environment variables (`.env`)

See `.env.example`. Main options:

- `USE_GIT_PROMPT`, `USE_TMUX`, `USE_DOCKER_AUTOCOMPLETE`, `USE_VSCODE_CONFIG` — enable/disable steps.
- `USE_CLAUDE_CODE`, `USE_CLAUDE`, `USE_CLAUDE_MARKETPLACE` — Claude CLI and config.
- **USE_RTK** — [rtk](https://github.com/rtk-ai/rtk) (Rust Token Killer): reduces LLM token use 60–90%; hook in `~/.claude/settings.json`.
- `USE_OLLAMA`, `OLLAMA_REPO`, `OLLAMA_DEFAULT_MODEL` — Ollama (Docker on Linux).
- `USE_RAG`, `RAG_DSN`, `RAG_PROJECT`, `WHICH_EDITOR` — RAG MCP for Cursor/VSCode.

## Logs

Logs are written to `host/.log/` (e.g. `post_create.log`, `init_env.log`).

## Structure (summary)

- `run_post_create.sh` / `.ps1` — one-time setup entrypoint.
- `run_terminal_setup.sh` — terminal only (zsh, Starship, tmux; same as devcontainer).
- `run_init_env.sh` / `.ps1` — session init entrypoint.
- `scripts/lifecycle/` — post_create and init_env (Unix + PowerShell).
- `scripts/setup/` — git prompt, CLI tools, Docker autocomplete, Claude Code, Claude config, editor config (both Cursor and VSCode).
- `scripts/ai/` — RAG connection and RAG MCP for both editors.
- `scripts/ollama/` — Ollama (Docker on Linux; doc on macOS/Windows).
- `editor-config/cursor/` and `editor-config/vscode/` — user settings and extensions list merged into each editor’s User directory.
- `mcp/rag/` — RAG MCP server and configs (used by both editors at user level).
