#!/bin/bash
# install_beads.sh — Install Beads CLI and initialize in the project
#
# Controlled by USE_BEADS env var (default: false).
# See: https://github.com/steveyegge/beads

SCRIPT_DIR="${DEVCONTAINER_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

function log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [install_beads] $1"
}

if [ "${USE_BEADS}" != "true" ]; then
    log "USE_BEADS is not set to 'true', skipping Beads installation."
    exit 0
fi

log "Installing Beads CLI (@beads/bd) via npm..."
if npm install -g @beads/bd; then
    log "Beads CLI installed successfully: $(bd --version 2>/dev/null || echo 'version unknown')"
else
    log "ERROR: Failed to install @beads/bd via npm"
    exit 1
fi

log "Initializing Beads in project root: $PROJECT_ROOT"
cd "$PROJECT_ROOT" || exit 1

if [ -d ".beads" ]; then
    log "Beads already initialized (.beads directory exists), skipping bd init."
    exit 0
fi

if bd init; then
    log "Beads initialized successfully."
else
    log "WARNING: bd init failed — Beads CLI is installed but project was not initialized."
    log "Run 'bd init' manually in the project root when ready."
    exit 0
fi