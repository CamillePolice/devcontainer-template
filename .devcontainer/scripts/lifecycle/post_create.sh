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

log "=== Starting Project initialization script ==="

# Clean up status file on rebuild to ensure fresh installation
PROJECT_STATUS_FILE=".devcontainer/scripts/project_status"
if [ -f "$PROJECT_STATUS_FILE" ]; then
    log "Removing previous status file to ensure fresh installation"
    rm -f "$PROJECT_STATUS_FILE"
fi

# Enable debug mode
set -x

log "Create .ssh directory"
mkdir -p /home/vscode/.ssh

# Only attempt chown if running as root or with sudo access
if [ "$EUID" -eq 0 ] || sudo -n true 2>/dev/null; then
    sudo chown -R vscode:vscode /commandhistory 2>/dev/null || log "Warning: Could not change ownership of /commandhistory"
fi

touch /commandhistory/.bash_history 2>/dev/null || log "Warning: Could not create /commandhistory/.bash_history"

log "Create .bash_history file"
echo /commandhistory/.bash_history_host >> /commandhistory/.bash_history 2>/dev/null || log "Warning: Could not write to bash_history"

log "Copy .ssh directory from host"
# Check if source directory exists and has files
if [ -d /home/vscode/.sshhost ] && [ "$(ls -A /home/vscode/.sshhost 2>/dev/null)" ]; then
    cp -r /home/vscode/.sshhost/* /home/vscode/.ssh/ 2>/dev/null || log "Warning: Could not copy some SSH files"
    chmod -R 600 /home/vscode/.ssh/* 2>/dev/null || log "Warning: Could not set SSH permissions"
else
    log "Warning: No SSH files found in /home/vscode/.sshhost"
fi

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

log "Installing rtk (Rust Token Killer — LLM token optimizer)"
if "$SCRIPT_DIR/setup/install_rtk.sh"; then
    log "Successfully executed install_rtk.sh script"
else
    log "WARNING: install_rtk.sh failed (non-critical)"
fi

# -----------------------------------------------------------------------------
# RAG (Retrieval-Augmented Generation) — Supabase-backed agent context
# -----------------------------------------------------------------------------
# When USE_RAG=true and RAG_DSN is set, agents/skills/rules can be stored in
# Supabase and retrieved at runtime for Claude/Cursor (RAG-First agents).
#
# Scripts:
#   setup_rag.sh  — Run at init: checks Supabase connection (non-blocking).
#   seed_rag.py   — Run once manually: indexes any .md/.py files into
#                   rag_agent_instructions for a given --agent and --project.
#
# Env (devcontainer.json / host): USE_RAG, RAG_DSN, RAG_PROJECT (optional).
#
# Verify connection:  .devcontainer/scripts/ai/setup_rag.sh
# Index agents once:  RAG_PROJECT="global" python3 .devcontainer/scripts/ai/seed_rag.py \
#                       --file angular-expert-rag.md --agent angular-expert
# Inspect index:      psql "$RAG_DSN" -c "SELECT * FROM rag_audit;"
# -----------------------------------------------------------------------------
log "Setting up RAG connection"
if "$SCRIPT_DIR/ai/setup_rag.sh"; then
    log "Successfully connected to RAG"
else
    log "WARNING: RAG setup failed (non-critical, continuing)"
fi

# -----------------------------------------------------------------------------
# Editor MCP Configuration (Cursor / VSCode RAG integration)
# -----------------------------------------------------------------------------
# Copies the appropriate MCP config for rag-supabase to .cursor/ or .vscode/
# based on WHICH_EDITOR env var. Requires USE_RAG=true.
#
# Env vars:
#   WHICH_EDITOR  cursor|vscode  (set in .devcontainer/.env)
#   USE_RAG       true|false
#
# Tools exposed to the editor via MCP:
#   rag_load            — load agent instructions from Supabase
#   rag_save_learning   — persist a learned skill to Supabase
#   rag_audit           — list all indexed agents
#   rag_search          — keyword search across all RAG sections
# -----------------------------------------------------------------------------
log "Setting up editor RAG MCP configuration"
if "$SCRIPT_DIR/ai/setup_editor_rag_mcp.sh"; then
    log "Successfully configured RAG MCP for $WHICH_EDITOR"
else
    log "WARNING: Editor RAG MCP setup failed (non-critical, continuing)"
fi

log "Configuring VS Code environment"
if "$SCRIPT_DIR/setup/configure_vscode.sh"; then
    log "Successfully executed configure_vscode.sh script"
else
    log "ERROR: Failed to execute configure_vscode.sh script"
    exit 1
fi

log "Installing Ollama local LLM"
if "$SCRIPT_DIR/ollama/install_ollama.sh"; then
    log "Successfully executed install_ollama.sh script"
else
    log "WARNING: Failed to execute install_ollama.sh script (non-critical)"
fi

log "Updating project status initialization to true"
echo "project_status_initialization=true" > .devcontainer/scripts/project_status

log "=== Initialization completed successfully $(date) ==="
log "Log file available at: $LOGFILE"

set +x  # Disable debug mode
