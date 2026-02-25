#!/bin/bash
# Session init: global git config, optional pre-commit. Run once per machine or after host updates.
# Uses HOST_DIR and HOST_SCRIPTS from run_init_env.sh.

set -e

HOST_DIR="${HOST_DIR:?HOST_DIR not set}"
HOST_SCRIPTS="${HOST_SCRIPTS:?HOST_SCRIPTS not set}"
LOG_DIR="$HOST_DIR/.log"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/init_env.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

log "=== Host init_env ==="

# Global git config
git config --global pull.rebase true
git config --global push.autoSetupRemote true
# Prefer Cursor as editor if available, else code
if command -v cursor &>/dev/null; then
    git config --global core.editor "cursor --wait"
elif command -v code &>/dev/null; then
    git config --global core.editor "code --wait"
fi
log "Global git config updated."

# Pre-commit: install for user if not present
if command -v pre-commit &>/dev/null; then
    log "pre-commit already installed."
else
    if command -v pip3 &>/dev/null; then
        pip3 install --user pre-commit --quiet 2>/dev/null && log "Installed pre-commit (user)." || log "Could not install pre-commit."
    elif command -v pip &>/dev/null; then
        pip install --user pre-commit --quiet 2>/dev/null && log "Installed pre-commit (user)." || log "Could not install pre-commit."
    else
        log "pip not found; skip pre-commit. Install manually if needed."
    fi
fi

log "=== Host init_env completed. Log: $LOGFILE ==="
