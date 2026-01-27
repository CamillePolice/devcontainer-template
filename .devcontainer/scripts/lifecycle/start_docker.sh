#!/bin/bash

# Use env vars from devcontainer.json, with fallback for manual execution
SCRIPT_DIR="${DEVCONTAINER_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Create log directory if it doesn't exist
LOG_DIR="$PROJECT_ROOT/.devcontainer/.log"
mkdir -p "$LOG_DIR"

# Set up logging
LOGFILE="$LOG_DIR/project_docker_startup.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

function log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Checking environment..."

if [ -z "$REMOTE_CONTAINERS" ]; then
    log "Not in devcontainer, exiting"
    exit 0
fi

log "Waiting for initialization to complete..."
while ! grep -q "project_status_initialization=true" "$SCRIPT_DIR/project_status"; do
    sleep 1
done

log "Starting docker compose..."

if [ -f "$PROJECT_ROOT/docker-compose.yml" ]; then
    docker-compose -f "$PROJECT_ROOT/docker-compose.yml" up -d --build

    if [ $? -eq 0 ]; then
        log "Docker compose started successfully"
    else
        log "Failed to start docker compose"
        exit 1
    fi
else
    log "No docker-compose.yml file found at $PROJECT_ROOT/docker-compose.yml, skipping docker compose startup"
fi
