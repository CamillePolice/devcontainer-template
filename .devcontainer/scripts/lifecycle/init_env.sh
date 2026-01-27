#!/bin/bash

# Use env vars from devcontainer.json, with fallback for manual execution
SCRIPT_DIR="${DEVCONTAINER_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Create log directory if it doesn't exist
LOG_DIR="$PROJECT_ROOT/.devcontainer/.log"
mkdir -p "$LOG_DIR"

# Set up logging
LOGFILE="$LOG_DIR/project_init_env.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

function log() {
   echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "=== Starting Project environment initialization script (runs on every start) ==="

# Enable debug mode
set -x

# Tasks that should run on every container start
# These are lightweight and ensure the environment is correctly configured

log "Refreshing SSH directory from host (in case keys changed)"
mkdir -p /home/vscode/.ssh
if [ -d /home/vscode/.sshhost ] && [ "$(ls -A /home/vscode/.sshhost 2>/dev/null)" ]; then
    # Only copy if source is newer or missing in target
    rsync -au /home/vscode/.sshhost/ /home/vscode/.ssh/ 2>/dev/null || cp -ru /home/vscode/.sshhost/* /home/vscode/.ssh/ 2>/dev/null || log "Warning: Could not sync SSH files"
    chmod -R 600 /home/vscode/.ssh/* 2>/dev/null || log "Warning: Could not set SSH permissions"
else
    log "No SSH files to sync"
fi

log "Setting up git config"
git config --global pull.rebase true
git config --global core.editor "cursor --wait"
git config --global push.autoSetupRemote true

log "Ensuring pre-commit is installed in current project"
if [ -f "$PROJECT_ROOT/.pre-commit-config.yaml" ]; then
    log "Pre-commit config found, ensuring hooks are installed"
    if command -v pre-commit &> /dev/null; then
        pre-commit install 2>/dev/null || log "Warning: Could not install pre-commit hooks"
    else
        log "Warning: pre-commit not found, installing via pip"
        pip install pre-commit --quiet
        pre-commit install 2>/dev/null || log "Warning: Could not install pre-commit hooks"
    fi
else
    log "No .pre-commit-config.yaml found, skipping pre-commit setup"
fi

log "=== Environment initialization completed successfully $(date) ==="
log "Log file available at: $LOGFILE"

set +x  # Disable debug mode
