#!/bin/bash
# Global Claude config: clone everything-claude-code into CLAUDE_HOME (default HOST_DIR/.claude).
# Uses HOST_DIR, HOST_SCRIPTS. Requires jq (optional; skip MCP/settings if missing).

set -e

HOST_DIR="${HOST_DIR:?}"
LOG_DIR="$HOST_DIR/.log"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/configure_claude.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

CLAUDE_HOME="${CLAUDE_HOME:-$HOST_DIR/.claude}"

if [ "${USE_CLAUDE:-false}" != "true" ] && [ "${USE_CLAUDE_MARKETPLACE:-false}" != "true" ]; then
    log "USE_CLAUDE and USE_CLAUDE_MARKETPLACE are false; skipping."
    exit 0
fi

if [ -d "$CLAUDE_HOME" ] && [ -n "$(ls -A "$CLAUDE_HOME" 2>/dev/null)" ]; then
    log ".claude already exists at $CLAUDE_HOME; skipping clone."
    exit 0
fi

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
log "Cloning everything-claude-code..."
if ! git clone --depth 1 https://github.com/affaan-m/everything-claude-code.git "$TEMP_DIR/repo"; then
    log "Failed to clone repository."
    exit 1
fi

mkdir -p "$CLAUDE_HOME"/{agents,skills,commands,hooks,rules}
cp -r "$TEMP_DIR/repo/agents/"*.md "$CLAUDE_HOME/agents/" 2>/dev/null || true
cp -r "$TEMP_DIR/repo/skills/"* "$CLAUDE_HOME/skills/" 2>/dev/null || true
cp -r "$TEMP_DIR/repo/commands/"*.md "$CLAUDE_HOME/commands/" 2>/dev/null || true
cp "$TEMP_DIR/repo/hooks/hooks.json" "$CLAUDE_HOME/hooks/" 2>/dev/null || true
cp -r "$TEMP_DIR/repo/rules/"*.md "$CLAUDE_HOME/rules/" 2>/dev/null || true
cp -r "$TEMP_DIR/repo/scripts" "$CLAUDE_HOME/" 2>/dev/null || true
cp -r "$TEMP_DIR/repo/contexts" "$CLAUDE_HOME/" 2>/dev/null || true
cp -r "$TEMP_DIR/repo/.claude-plugin" "$CLAUDE_HOME/" 2>/dev/null || true

log "Claude config installed at $CLAUDE_HOME"
