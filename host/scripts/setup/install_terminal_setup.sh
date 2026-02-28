#!/bin/bash
# One-shot: install the same terminal customizations as the devcontainer on the host.
# - Zsh + Oh My Zsh + plugins (autosuggestions, syntax-highlighting, git, docker, etc.)
# - Starship prompt + full starship.toml
# - Tmux + TPM + Catppuccin theme + .tmux.conf
# - Optional: CLI tools (fzf, ripgrep, bat, eza, zoxide, tldr) for tmux-sessionizer etc.
#
# Usage: run from host directory:
#   ./run_terminal_setup.sh
# or:
#   HOST_DIR=/path/to/host bash scripts/setup/install_terminal_setup.sh
#
# Requires: HOST_DIR and HOST_SCRIPTS (set by run_terminal_setup.sh when present).

set -e

# HOST_DIR and HOST_SCRIPTS must be set by run_terminal_setup.sh or caller
if [ -z "${HOST_DIR}" ] || [ -z "${HOST_SCRIPTS}" ]; then
    HOST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    export HOST_DIR
    export HOST_SCRIPTS="$HOST_DIR/scripts"
fi

if [ -f "$HOST_DIR/.env" ]; then
    set -a
    # shellcheck source=/dev/null
    source "$HOST_DIR/.env"
    set +a
fi

LOG_DIR="$HOST_DIR/.log"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/install_terminal_setup.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

log "=== Installing terminal setup (same as devcontainer) ==="

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

# 1. Zsh + Oh My Zsh + Starship
run_script "$HOST_SCRIPTS/setup/configure_git_prompt.sh" || true

# 2. Tmux + TPM + Catppuccin + config
run_script "$HOST_SCRIPTS/setup/install_tmux.sh" || true

# 3. CLI tools (fzf, ripgrep, bat, eza, zoxide, tldr) — useful for tmux-sessionizer
run_script "$HOST_SCRIPTS/setup/install_cli_tools.sh" || true

log "=== Terminal setup finished. Log: $LOGFILE ==="
log "Next: run 'exec zsh', then start tmux and press Ctrl-b I to install TPM plugins."
