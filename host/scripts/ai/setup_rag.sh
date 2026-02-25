#!/bin/bash
# Check Supabase RAG connection (USE_RAG, RAG_DSN). Install psql per OS if needed.
set -e
HOST_DIR="${HOST_DIR:?}"
HOST_SCRIPTS="${HOST_SCRIPTS:?}"
LOG_DIR="$HOST_DIR/.log"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/rag_setup.log"
exec 1> >(tee -a "$LOGFILE") 2>&1
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
[ "${USE_RAG:-false}" != "true" ] && { log "RAG disabled."; exit 0; }
[ -z "$RAG_DSN" ] && { log "WARNING: RAG_DSN not set. Set in host/.env or shell."; exit 0; }
# shellcheck source=../lib/detect_os.sh
source "$HOST_SCRIPTS/lib/detect_os.sh"
if ! command -v psql &>/dev/null; then
    case "$PKG_MGR" in
        apt) sudo apt-get update -qq && sudo apt-get install -y -qq postgresql-client ;;
        brew) brew install libpq && (command -v psql &>/dev/null || export PATH="/opt/homebrew/opt/libpq/bin:$PATH") ;;
        *) log "Install PostgreSQL client (psql) manually for RAG." ;;
    esac
fi
if ! psql "$RAG_DSN" -c "SELECT 1;" &>/dev/null; then
    log "WARNING: Cannot reach Supabase."
    exit 0
fi
log "Supabase RAG connected."
