#!/bin/bash
# setup_editor_rag_mcp.sh — Configure MCP RAG server for Cursor or VSCode
#
# Reads WHICH_EDITOR env var (cursor|vscode|both) and ensures the MCP config
# and editor rules are in place at the project root.
#
# Called from post_create.sh when USE_RAG=true.

SCRIPT_DIR="${DEVCONTAINER_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
# RAG MCP: server, configs and editor rules live under .devcontainer/mcp/rag/
MCP_RAG_DIR="$PROJECT_ROOT/.devcontainer/mcp/rag"

LOG_DIR="$PROJECT_ROOT/.devcontainer/.log"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/editor_mcp.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

function log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

WHICH_EDITOR="${WHICH_EDITOR:-cursor}"
USE_RAG="${USE_RAG:-false}"

log "=== Setting up editor MCP configuration ==="
log "  Editor   : $WHICH_EDITOR"
log "  USE_RAG  : $USE_RAG"

if [ "$USE_RAG" != "true" ]; then
    log "USE_RAG=false — skipping MCP editor setup"
    exit 0
fi

if [ ! -f "$MCP_RAG_DIR/mcp-rag-server.js" ]; then
    log "ERROR: mcp-rag-server.js not found at $MCP_RAG_DIR"
    exit 1
fi

# Install pg dependency if not already present
if [ ! -d "$MCP_RAG_DIR/node_modules/pg" ]; then
    log "Installing pg dependency for MCP server..."
    cd "$MCP_RAG_DIR" && npm install --silent
    log "pg installed"
fi

setup_cursor() {
    log "--- Configuring Cursor ---"
    CURSOR_DIR="$PROJECT_ROOT/.cursor"
    mkdir -p "$CURSOR_DIR"

    # MCP config
    if [ ! -f "$CURSOR_DIR/mcp.json" ]; then
        cp "$MCP_RAG_DIR/cursor-mcp.json" "$CURSOR_DIR/mcp.json"
        log "✅ .cursor/mcp.json created"
    else
        log "ℹ  .cursor/mcp.json already exists — skipping"
    fi

    # Rules RAG
    if [ ! -f "$CURSOR_DIR/rules-rag.mdc" ]; then
        cp "$MCP_RAG_DIR/rag-cursor-rules.mdc" "$CURSOR_DIR/rules-rag.mdc" 2>/dev/null \
            && log "✅ .cursor/rules-rag.mdc created" \
            || log "⚠  rag-cursor-rules.mdc not found in $MCP_RAG_DIR — skipping"
    else
        log "ℹ  .cursor/rules-rag.mdc already exists — skipping"
    fi
}

setup_vscode() {
    log "--- Configuring VSCode ---"
    VSCODE_DIR="$PROJECT_ROOT/.vscode"
    GITHUB_DIR="$PROJECT_ROOT/.github"
    mkdir -p "$VSCODE_DIR" "$GITHUB_DIR"

    # MCP config
    if [ ! -f "$VSCODE_DIR/mcp.json" ]; then
        cp "$MCP_RAG_DIR/vscode-mcp.json" "$VSCODE_DIR/mcp.json"
        log "✅ .vscode/mcp.json created"
    else
        log "ℹ  .vscode/mcp.json already exists — skipping"
    fi

    # Copilot instructions
    if [ ! -f "$GITHUB_DIR/copilot-instructions.md" ]; then
        cp "$MCP_RAG_DIR/rag-copilot-instructions.md" "$GITHUB_DIR/copilot-instructions.md" 2>/dev/null \
            && log "✅ .github/copilot-instructions.md created" \
            || log "⚠  rag-copilot-instructions.md not found in $MCP_RAG_DIR — skipping"
    else
        log "ℹ  .github/copilot-instructions.md already exists — skipping"
    fi
}

case "$WHICH_EDITOR" in
    cursor)        setup_cursor ;;
    vscode)        setup_vscode ;;
    both)          setup_cursor; setup_vscode ;;
    *)
        log "ERROR: Unknown WHICH_EDITOR='$WHICH_EDITOR' — expected cursor|vscode|both"
        exit 1
        ;;
esac

log "=== Editor MCP setup complete ==="
log "  Tools : rag_load, rag_save_learning, rag_audit, rag_search"
