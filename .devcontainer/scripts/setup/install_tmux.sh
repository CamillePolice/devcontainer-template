#!/bin/bash
# One-time setup: install tmux + xclip, clone TPM, copy tmux config to ~/.tmux.conf.
# After running, start tmux and press Ctrl-a I to install plugins.

set -e

SCRIPT_DIR="${DEVCONTAINER_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
CONFIG_SRC="$PROJECT_ROOT/.devcontainer/config/.tmux.conf"
TMUX_DIR="$HOME/.tmux"
TPM_PATH="$TMUX_DIR/plugins/tpm"

function log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "=== Tmux setup ==="

# Install tmux and xclip (for tmux-yank clipboard)
if command -v apt-get &>/dev/null && (sudo -n true 2>/dev/null || [ "$EUID" -eq 0 ]); then
    log "Installing tmux and xclip..."
    sudo apt-get update -qq
    sudo apt-get install -y tmux xclip
else
    log "Skipping apt install (no sudo or not Debian/Ubuntu). Install manually: tmux, xclip"
fi

# Copy config to home (so ~/.tmux.conf is used)
if [ -f "$CONFIG_SRC" ]; then
    mkdir -p "$TMUX_DIR"
    cp "$CONFIG_SRC" "$HOME/.tmux.conf"
    log "Copied .devcontainer/config/.tmux.conf to ~/.tmux.conf"
else
    log "Warning: Config not found at $CONFIG_SRC"
    exit 1
fi

# Clone TPM if missing
if [ ! -d "$TPM_PATH" ]; then
    log "Cloning TPM to $TPM_PATH"
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_PATH"
    log "TPM cloned. Run tmux, then press Ctrl-a I to install plugins."
else
    log "TPM already present at $TPM_PATH"
fi

log "Tmux setup done. Start tmux and press Ctrl-a I to install plugins."
