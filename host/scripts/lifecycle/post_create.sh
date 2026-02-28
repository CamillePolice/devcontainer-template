#!/bin/bash
# One-time host setup: git prompt, CLI tools, Docker autocomplete, Claude Code, Claude config,
# RAG, editor RAG MCP, configure both Cursor and VSCode, Ollama.
# Uses HOST_DIR and HOST_SCRIPTS from run_post_create.sh.

set -e

HOST_DIR="${HOST_DIR:?HOST_DIR not set}"
HOST_SCRIPTS="${HOST_SCRIPTS:?HOST_SCRIPTS not set}"
LOG_DIR="$HOST_DIR/.log"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/post_create.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

# OS detection (Cursor/VSCode user dirs, package manager)
# shellcheck source=../lib/detect_os.sh
source "$HOST_SCRIPTS/lib/detect_os.sh"

log "=== Starting host post_create (OS=$OS) ==="

run_script() {
    local script="$1"
    if [ -f "$script" ]; then
        if "$script"; then
            log "OK: $script"
        else
            log "FAILED: $script"
            return 1
        fi
    else
        log "SKIP (not found): $script"
    fi
    return 0
}

# Git prompt (zsh + Starship) — Linux/macOS; skip on Windows or if disabled
if [ "${USE_GIT_PROMPT:-true}" = "true" ] && [ "$OS" != "windows" ]; then
    run_script "$HOST_SCRIPTS/setup/configure_git_prompt.sh" || log "WARNING: configure_git_prompt failed (non-critical)"
    # Tmux (same config as devcontainer: TPM, Catppuccin)
    run_script "$HOST_SCRIPTS/setup/install_tmux.sh" || log "WARNING: install_tmux failed (non-critical)"
fi

# CLI tools (fzf, ripgrep, bat, eza, zoxide, tldr)
run_script "$HOST_SCRIPTS/setup/install_cli_tools.sh" || log "WARNING: install_cli_tools failed (non-critical)"

# Docker autocomplete — Unix only
if [ "${USE_DOCKER_AUTOCOMPLETE:-true}" = "true" ] && [ "$OS" != "windows" ]; then
    run_script "$HOST_SCRIPTS/setup/docker_autocomplete.sh" || log "WARNING: docker_autocomplete failed (non-critical)"
fi

# Claude Code CLI
if [ "${USE_CLAUDE_CODE:-true}" = "true" ]; then
    run_script "$HOST_SCRIPTS/setup/install_claude_code.sh" || log "WARNING: install_claude_code failed (non-critical)"
fi

# Claude config (global .claude)
if [ "${USE_CLAUDE:-false}" = "true" ] || [ "${USE_CLAUDE_MARKETPLACE:-false}" = "true" ]; then
    run_script "$HOST_SCRIPTS/setup/configure_claude.sh" || log "WARNING: configure_claude failed (non-critical)"
fi

# RAG connection check
run_script "$HOST_SCRIPTS/ai/setup_rag.sh" || true

# Editor RAG MCP (both Cursor and VSCode user-level)
run_script "$HOST_SCRIPTS/ai/setup_editor_rag_mcp.sh" || true

# Configure both Cursor and VSCode (user settings, extensions, keybindings)
if [ "${USE_VSCODE_CONFIG:-true}" = "true" ]; then
    run_script "$HOST_SCRIPTS/setup/configure_editor.sh" || log "WARNING: configure_editor failed (non-critical)"
fi

# Ollama (optional)
run_script "$HOST_SCRIPTS/ollama/install_ollama.sh" || true

log "=== Host post_create completed. Log: $LOGFILE ==="
