#!/bin/bash
# Install Claude Code CLI (global). Uses HOST_DIR.

set -e
HOST_DIR="${HOST_DIR:?}"
LOG_DIR="$HOST_DIR/.log"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/claude_code_install.log"
exec 1> >(tee -a "$LOGFILE") 2>&1
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
if [ "${USE_CLAUDE_CODE:-true}" != "true" ]; then log "USE_CLAUDE_CODE is false; skipping."; exit 0; fi
if command -v claude &>/dev/null; then log "Claude Code already installed."; exit 0; fi
log "Installing Claude Code CLI..."
TMP=$(mktemp -d)
cd "$TMP"
curl -fsSL https://claude.ai/install.sh -o install.sh && chmod +x install.sh
CHANNEL="${CLAUDE_CODE_CHANNEL:-latest}"
if [ "$CHANNEL" = "latest" ]; then bash install.sh; else bash install.sh "$CHANNEL"; fi
rm -rf "$TMP"
log "Claude Code install done."
