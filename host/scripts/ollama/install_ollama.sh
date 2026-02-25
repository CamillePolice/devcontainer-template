#!/bin/bash
# Install Ollama via Docker (Linux) or document native app (macOS/Windows). Uses HOST_DIR.
set -e
HOST_DIR="${HOST_DIR:?}"
HOST_SCRIPTS="${HOST_SCRIPTS:?}"
OLLAMA_DIR="$HOST_DIR/ollama"
LOG_DIR="$HOST_DIR/.log"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/ollama_install.log"
exec 1> >(tee -a "$LOGFILE") 2>&1
# shellcheck source=../lib/detect_os.sh
source "$HOST_SCRIPTS/lib/detect_os.sh"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
USE_OLLAMA="${USE_OLLAMA:-false}"
OLLAMA_REPO="${OLLAMA_REPO:-CamillePolice/ollama}"
OLLAMA_DEFAULT_MODEL="${OLLAMA_DEFAULT_MODEL:-qwen2.5-coder:7b}"
[ "$USE_OLLAMA" != "true" ] && { log "USE_OLLAMA is false; skipping."; exit 0; }
if [ "$OS" = "macos" ] || [ "$OS" = "windows" ]; then
    log "On $OS install Ollama from https://ollama.com and run it. Skipping Docker."
    exit 0
fi
if ! command -v docker &>/dev/null; then
    log "Docker not found; install Docker first for Ollama."
    exit 0
fi
if [ -d "$OLLAMA_DIR" ] && [ -f "$OLLAMA_DIR/docker-compose.yml" ]; then
    log "Ollama config already at $OLLAMA_DIR"
else
    mkdir -p "$OLLAMA_DIR"
    TMP=$(mktemp -d)
    git clone --depth 1 "https://github.com/${OLLAMA_REPO}.git" "$TMP/repo" 2>/dev/null || { log "Could not clone $OLLAMA_REPO"; rm -rf "$TMP"; exit 0; }
    cp "$TMP/repo/docker-compose.yml" "$OLLAMA_DIR/" 2>/dev/null || true
    rm -rf "$TMP"
fi
[ ! -f "$OLLAMA_DIR/docker-compose.yml" ] && { log "docker-compose.yml not found."; exit 0; }
cd "$OLLAMA_DIR"
docker compose --profile ollama up -d 2>/dev/null || docker-compose --profile ollama up -d 2>/dev/null || log "Start Ollama manually: cd $OLLAMA_DIR && docker compose up -d"
log "Ollama setup done. API: http://localhost:11434"
