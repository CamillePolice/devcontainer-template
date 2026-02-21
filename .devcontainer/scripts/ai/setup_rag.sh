#!/bin/bash
# setup_rag.sh — Check Supabase RAG connection (USE_RAG, RAG_DSN).
# Run automatically from post_create.sh; can be run manually to verify.
# See post_create.sh RAG doc block for full workflow and seed_rag.sh.

SCRIPT_DIR="${DEVCONTAINER_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

USE_RAG="${USE_RAG:-false}"
LOG_DIR="$PROJECT_ROOT/.devcontainer/.log"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/rag_setup.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

function log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

log "=== Starting RAG setup ==="

if [ "$USE_RAG" != "true" ]; then
    log "RAG disabled (USE_RAG=false)"
    exit 0
fi

if [ -z "$RAG_DSN" ]; then
    log "WARNING: RAG_DSN not set"
    log "  Add to your host ~/.zshrc: export RAG_DSN='postgresql://...'"
    exit 0
fi

# Install psql client if missing
if ! command -v psql &> /dev/null; then
    log "Installing postgresql-client..."
    sudo apt-get update -qq && sudo apt-get install -y -qq postgresql-client
fi

# Test connection
if ! psql "$RAG_DSN" -c "SELECT 1;" &>/dev/null; then
    log "WARNING: Cannot reach Supabase - agents will work in degraded mode"
    exit 0
fi

# Stats
SECTIONS=$(psql "$RAG_DSN" -t -A -c \
    "SELECT COUNT(*) FROM rag_agent_instructions WHERE active = true;" 2>/dev/null || echo "?")
PROJECTS=$(psql "$RAG_DSN" -t -A -c \
    "SELECT COUNT(DISTINCT project) FROM rag_agent_instructions WHERE active = true;" 2>/dev/null || echo "?")

log "✅ Supabase RAG connected"
log "   $SECTIONS sections actives / $PROJECTS projets"
log "=== RAG setup complete ==="
