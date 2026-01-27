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

log "=== Starting Project environment initialization script ==="

# Enable debug mode
set -x

log "Create .ssh directory"
mkdir -p /home/vscode/.ssh

log "Copy .ssh directory from host"
cp -r /home/vscode/.sshhost/* /home/vscode/.ssh/
chmod -R 600 /home/vscode/.ssh/*

log "Setting up git config"
git config --global pull.rebase true
git config --global core.editor "cursor --wait"
git config --global push.autoSetupRemote true

log "Installing pre-commit"
pip install pre-commit
pre-commit install

log "Configuring git prompt"
if "$SCRIPT_DIR/setup/configure_git_prompt.sh"; then
    log "Successfully executed configure_git_prompt.sh script"
else
    log "ERROR: Failed to execute configure_git_prompt.sh script"
    exit 1
fi

log "Installing CLI tools"
if "$SCRIPT_DIR/setup/install_cli_tools.sh"; then
    log "Successfully executed install_cli_tools.sh script"
else
    log "ERROR: Failed to execute install_cli_tools.sh script"
    exit 1
fi

log "Configuring Docker autocomplete"
if "$SCRIPT_DIR/config/docker_autocomplete.sh"; then
    log "Successfully executed docker_autocomplete.sh script"
else
    log "ERROR: Failed to execute docker_autocomplete.sh script"
    exit 1
fi

log "=== Environment initialization completed successfully $(date) ==="
log "Log file available at: $LOGFILE"

set +x  # Disable debug mode
