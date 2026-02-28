#!/bin/bash
# Install tmux, TPM, Catppuccin theme, and copy config to ~/.tmux.conf.
# Same setup as devcontainer terminal. Uses HOST_DIR, HOST_SCRIPTS; sources detect_os.
# After running: start tmux and press Ctrl-b I to install TPM plugins.

set -e

HOST_DIR="${HOST_DIR:?}"
HOST_SCRIPTS="${HOST_SCRIPTS:?}"
CONFIG_SRC="$HOST_DIR/config/.tmux.conf"
TMUX_DIR="$HOME/.tmux"
TPM_PATH="$TMUX_DIR/plugins/tpm"
CATPUCIN_PATH="$HOME/.config/tmux/plugins/catppuccin/tmux"

LOG_DIR="$HOST_DIR/.log"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/install_tmux.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

# shellcheck source=../lib/detect_os.sh
source "$HOST_SCRIPTS/lib/detect_os.sh"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

if [ "${USE_TMUX:-true}" != "true" ]; then
    log "USE_TMUX is false; skipping."
    exit 0
fi

log "=== Tmux setup (OS=$OS) ==="

# Install tmux (and xclip on Linux for tmux-yank clipboard)
case "$PKG_MGR" in
    apt)
        if ! command -v tmux &>/dev/null || ! command -v xclip &>/dev/null; then
            log "Installing tmux and xclip..."
            sudo apt-get update -qq
            sudo apt-get install -y tmux xclip
        fi
        ;;
    dnf)
        if ! command -v tmux &>/dev/null; then
            sudo dnf install -y tmux xclip 2>/dev/null || sudo dnf install -y tmux
        fi
        ;;
    pacman)
        if ! command -v tmux &>/dev/null; then
            sudo pacman -S --noconfirm tmux xclip 2>/dev/null || sudo pacman -S --noconfirm tmux
        fi
        ;;
    brew)
        if ! command -v tmux &>/dev/null; then
            brew install tmux
        fi
        # macOS: reattach-to-user-namespace for clipboard; xclip not needed if using pbcopy
        if ! command -v reattach-to-user-namespace &>/dev/null; then
            brew install reattach-to-user-namespace 2>/dev/null || true
        fi
        ;;
    *)
        log "Unknown package manager. Install tmux and xclip (Linux) manually."
        ;;
esac

if ! command -v tmux &>/dev/null; then
    log "tmux not found after install. Install it manually then re-run this script."
    exit 1
fi

# Copy config to home
if [ ! -f "$CONFIG_SRC" ]; then
    log "Warning: Config not found at $CONFIG_SRC"
    exit 1
fi
mkdir -p "$TMUX_DIR"
cp "$CONFIG_SRC" "$HOME/.tmux.conf"
log "Copied $CONFIG_SRC to ~/.tmux.conf"

# Clone TPM if missing
if [ ! -d "$TPM_PATH" ]; then
    log "Cloning TPM to $TPM_PATH"
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_PATH"
else
    log "TPM already present at $TPM_PATH"
fi

# Catppuccin theme (required by .tmux.conf)
if [ ! -f "$CATPUCIN_PATH/catppuccin.tmux" ]; then
    log "Installing Catppuccin tmux theme..."
    mkdir -p "$(dirname "$CATPUCIN_PATH")"
    git clone -b v2.1.3 --depth 1 https://github.com/catppuccin/tmux.git "$CATPUCIN_PATH"
else
    log "Catppuccin theme already present"
fi

log "Tmux setup done. Start tmux and press Ctrl-b I to install plugins."
