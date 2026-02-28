#!/bin/bash
# Install rtk (Rust Token Killer) — CLI proxy that reduces LLM token consumption by 60–90%.
# https://github.com/rtk-ai/rtk
# After install: rtk init -g --auto-patch (hook + ~/.claude/settings.json).
# Uses HOST_DIR, HOST_SCRIPTS; sources detect_os. Run after configure_claude if both are used.

set -e

HOST_DIR="${HOST_DIR:?}"
HOST_SCRIPTS="${HOST_SCRIPTS:?}"
LOG_DIR="$HOST_DIR/.log"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/install_rtk.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

# shellcheck source=../lib/detect_os.sh
source "$HOST_SCRIPTS/lib/detect_os.sh"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

if [ "${USE_RTK:-true}" != "true" ]; then
    log "USE_RTK is false; skipping."
    exit 0
fi

export PATH="$HOME/.local/bin:$PATH"
mkdir -p "$HOME/.local/bin"

# Pre-install check: correct rtk is rtk-ai/rtk (has `rtk gain`)
if command -v rtk &>/dev/null; then
    if rtk gain &>/dev/null; then
        log "rtk already installed and verified (rtk gain OK)"
        if rtk init --show &>/dev/null; then
            log "RTK hook already configured"
            exit 0
        fi
    else
        log "Wrong rtk installed (Type Kit?). Reinstalling from rtk-ai/rtk."
        rm -f "$HOME/.local/bin/rtk" 2>/dev/null || true
        if command -v brew &>/dev/null; then
            brew uninstall rtk 2>/dev/null || true
        fi
    fi
fi

# Install: Homebrew on macOS, curl script on Linux (or curl on both for consistency)
if [ "$PKG_MGR" = "brew" ]; then
    log "Installing rtk via Homebrew..."
    brew install rtk 2>/dev/null || {
        log "brew install rtk failed, trying curl install script"
        curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
    }
else
    log "Installing rtk via install script to $HOME/.local/bin"
    curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
fi

export PATH="$HOME/.local/bin:$PATH"
if ! command -v rtk &>/dev/null; then
    log "WARNING: rtk not in PATH after install. Add to shell: export PATH=\"\$HOME/.local/bin:\$PATH\""
    exit 0
fi
if ! rtk gain &>/dev/null; then
    log "WARNING: rtk gain failed (wrong package?)"
    exit 0
fi

log "Configuring rtk for Claude Code (hook + settings.json)"
mkdir -p "$HOME/.claude"
if [ -f "$HOME/.claude/settings.json" ]; then
    rtk init -g --auto-patch 2>/dev/null || log "WARNING: rtk init failed (run manually: rtk init -g)"
else
    log "Skip rtk init: ~/.claude/settings.json not found. Run configure_claude.sh first or: rtk init -g --auto-patch"
fi

log "rtk setup done. Verify: rtk gain && rtk init --show"
