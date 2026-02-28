#!/bin/bash
# Install rtk (Rust Token Killer) — CLI proxy that reduces LLM token consumption by 60–90%.
# https://github.com/rtk-ai/rtk
# After install: rtk init -g --auto-patch (hook + ~/.claude/settings.json).
# Must run after configure_claude.sh so ~/.claude/settings.json exists.

set -e

SCRIPT_DIR="${DEVCONTAINER_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
LOG_DIR="$PROJECT_ROOT/.devcontainer/.log"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/install_rtk.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

function log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

USE_RTK="${USE_RTK:-true}"
if [ "$USE_RTK" != "true" ]; then
    log "RTK disabled (USE_RTK=false)"
    exit 0
fi

# Ensure ~/.local/bin is on PATH for this script
export PATH="$HOME/.local/bin:$PATH"
mkdir -p "$HOME/.local/bin"

# Pre-install check: correct rtk is rtk-ai/rtk (has `rtk gain`), not reachingforthejack/rtk
if command -v rtk &>/dev/null; then
    if rtk gain &>/dev/null; then
        log "rtk already installed and verified (rtk gain OK)"
        if rtk init --show &>/dev/null; then
            log "RTK hook already configured"
            exit 0
        fi
        # Hook not configured, run init below
    else
        log "Wrong rtk installed (Type Kit?). Reinstall from rtk-ai/rtk."
        rm -f "$HOME/.local/bin/rtk" 2>/dev/null || true
    fi
fi

log "Installing rtk (rtk-ai/rtk) to $HOME/.local/bin"
if ! curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh; then
    log "WARNING: rtk install failed (non-critical)"
    exit 0
fi

export PATH="$HOME/.local/bin:$PATH"
if ! command -v rtk &>/dev/null; then
    log "WARNING: rtk not in PATH after install"
    exit 0
fi
if ! rtk gain &>/dev/null; then
    log "WARNING: rtk gain failed (wrong package?)"
    exit 0
fi

log "Configuring rtk for Claude Code (hook + settings.json)"
# Creates ~/.claude/hooks/rtk-rewrite.sh, patches ~/.claude/settings.json (backup: .bak)
if [ -f "$HOME/.claude/settings.json" ]; then
    rtk init -g --auto-patch 2>/dev/null || log "WARNING: rtk init -g --auto-patch failed (run manually: rtk init -g)"
else
    log "Skip rtk init: ~/.claude/settings.json not found (run configure_claude.sh first, then rtk init -g --auto-patch)"
fi

log "rtk setup done. Verify: rtk gain && rtk init --show"
