#!/bin/bash
# Configure RAG MCP for both Cursor and VSCode at user level. Uses HOST_DIR/mcp/rag.
set -e
HOST_DIR="${HOST_DIR:?}"
HOST_SCRIPTS="${HOST_SCRIPTS:?}"
MCP_RAG_DIR="$HOST_DIR/mcp/rag"
LOG_DIR="$HOST_DIR/.log"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/editor_rag_mcp.log"
exec 1> >(tee -a "$LOGFILE") 2>&1
# shellcheck source=../lib/detect_os.sh
source "$HOST_SCRIPTS/lib/detect_os.sh"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
[ "${USE_RAG:-false}" != "true" ] && { log "USE_RAG=false; skipping RAG MCP."; exit 0; }
[ ! -f "$MCP_RAG_DIR/mcp-rag-server.js" ] && { log "mcp-rag-server.js not found at $MCP_RAG_DIR"; exit 1; }
if [ ! -d "$MCP_RAG_DIR/node_modules/pg" ]; then
    (cd "$MCP_RAG_DIR" && npm install --silent)
fi
SERVER_PATH="$MCP_RAG_DIR/mcp-rag-server.js"
# Cursor user-level MCP (editor will substitute env at runtime)
mkdir -p "$CURSOR_USER_DIR"
CURSOR_MCP="$CURSOR_USER_DIR/mcp.json"
printf '%s\n' "{\"mcpServers\":{\"rag-supabase\":{\"command\":\"node\",\"args\":[\"$SERVER_PATH\"],\"env\":{\"RAG_DSN\":\"\$env:RAG_DSN\",\"RAG_PROJECT\":\"\$env:RAG_PROJECT\"}}}}" > "$CURSOR_MCP"
log "Cursor MCP config: $CURSOR_MCP"
# VSCode user-level: same structure
mkdir -p "$VSCODE_USER_DIR"
VSCODE_MCP="$VSCODE_USER_DIR/mcp.json"
printf '%s\n' "{\"mcp\":{\"servers\":{\"rag-supabase\":{\"type\":\"stdio\",\"command\":\"node\",\"args\":[\"$SERVER_PATH\"],\"env\":{\"RAG_DSN\":\"\${env:RAG_DSN}\",\"RAG_PROJECT\":\"\${env:RAG_PROJECT}\"}}}}}" > "$VSCODE_MCP"
log "VSCode MCP config: $VSCODE_MCP"
# Rules for Cursor
[ -f "$MCP_RAG_DIR/rag-cursor-rules.mdc" ] && cp "$MCP_RAG_DIR/rag-cursor-rules.mdc" "$CURSOR_USER_DIR/rules-rag.mdc" && log "Cursor rules-rag.mdc copied"
log "RAG MCP configured for both editors."
