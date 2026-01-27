#!/bin/bash

# Use env vars from devcontainer.json, with fallback for manual execution
SCRIPT_DIR="${DEVCONTAINER_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Create log directory if it doesn't exist
LOG_DIR="$PROJECT_ROOT/.devcontainer/.log"
mkdir -p "$LOG_DIR"

# Set up logging
LOGFILE="$LOG_DIR/project_init.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

function log() {
   echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

PROJECT_STATUS_FILE=".devcontainer/scripts/project_status"
if [ -f "$PROJECT_STATUS_FILE" ]; then
    INIT_STATUS=$(grep "project_status_initialization" "$PROJECT_STATUS_FILE" | cut -d'=' -f2)
    if [ "$INIT_STATUS" = "true" ]; then
        log "Project already initialized. Skipping initialization."
        exit 0
    fi
fi

log "=== Starting Project initialization script ==="

# Enable debug mode
set -x

log "Create .ssh directory"
mkdir -p /home/vscode/.ssh
sudo chown vscode:vscode -R /commandhistory
touch /commandhistory/.bash_history

log "Create .bash_history file"
echo /commandhistory/.bash_history_host >> /commandhistory/.bash_history

log "Copy .ssh directory from host"
cp -r /home/vscode/.sshhost/* /home/vscode/.ssh/
chmod -R 600 /home/vscode/.ssh/*

log "Create project status file"
touch .devcontainer/scripts/project_status
echo "project_status_initialization=false" > .devcontainer/scripts/project_status

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

log "Installing docker autocomplete"
if "$SCRIPT_DIR/config/docker_autocomplete.sh"; then
    log "Successfully executed docker_autocomplete.sh script"
else
    log "ERROR: Failed to execute docker_autocomplete.sh script"
    exit 1
fi

log "Installing Claude Code CLI"
if "$SCRIPT_DIR/setup/install_claude_code.sh"; then
    log "Successfully executed install_claude_code.sh script"
else
    log "ERROR: Failed to execute install_claude_code.sh script"
    exit 1
fi

log "Creating claude configuration directory"
if "$SCRIPT_DIR/setup/configure_claude.sh"; then
    log "Successfully executed configure_claude.sh script"
else
    log "ERROR: Failed to execute configure_claude.sh script"
    exit 1
fi

log "Configuring VS Code environment"
if "$SCRIPT_DIR/setup/configure_vscode.sh"; then
    log "Successfully executed configure_vscode.sh script"
else
    log "ERROR: Failed to execute configure_vscode.sh script"
    exit 1
fi

log "Updating project status initialization to true"
echo "project_status_initialization=true" > .devcontainer/scripts/project_status

log "=== Initialization completed successfully $(date) ==="
log "Log file available at: $LOGFILE"

set +x  # Disable debug mode
