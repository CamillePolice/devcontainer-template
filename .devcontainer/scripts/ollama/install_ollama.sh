#!/bin/bash
#
# install_ollama.sh - Install and configure Ollama local LLM via Docker
#
# This script clones the Ollama configuration repository and sets up the container.
#
# Environment Variables:
#   USE_OLLAMA           - Enable/disable installation (default: false)
#   OLLAMA_REPO          - GitHub repository for Ollama config (default: your-username/ollama-devcontainer)
#   OLLAMA_DEFAULT_MODEL - Model to pull (default: qwen2.5-coder:7b)
#   OLLAMA_GPU_ENABLED   - GPU mode: true/false/auto (default: auto)
#   OLLAMA_KEEP_ALIVE    - Model keep-alive time (default: 5m)
#   OLLAMA_MEMORY_LIMIT  - Container memory limit (default: 8G)
#
# Usage:
#   USE_OLLAMA=true ./install_ollama.sh
#

set -euo pipefail

# Use env vars from devcontainer.json, with fallback for manual execution
SCRIPT_DIR="${DEVCONTAINER_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Ollama installation options from environment
USE_OLLAMA="${USE_OLLAMA:-false}"
OLLAMA_REPO="${OLLAMA_REPO:-CamillePolice/ollama}"
OLLAMA_DEFAULT_MODEL="${OLLAMA_DEFAULT_MODEL:-qwen2.5-coder:7b}"
OLLAMA_GPU_ENABLED="${OLLAMA_GPU_ENABLED:-auto}"
OLLAMA_KEEP_ALIVE="${OLLAMA_KEEP_ALIVE:-5m}"
OLLAMA_MEMORY_LIMIT="${OLLAMA_MEMORY_LIMIT:-8G}"

# Target directory for Ollama configuration
OLLAMA_DIR="$PROJECT_ROOT/.devcontainer/ollama"

# Create log directory if it doesn't exist
LOG_DIR="$PROJECT_ROOT/.devcontainer/.log"
mkdir -p "$LOG_DIR"

# Set up logging
LOGFILE="$LOG_DIR/ollama_install.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

function log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check if Ollama installation is enabled
if [ "$USE_OLLAMA" != "true" ]; then
    log "Ollama installation disabled (USE_OLLAMA=false)"
    exit 0
fi

log "=== Starting Ollama installation script ==="
log "Repository: $OLLAMA_REPO"
log "Default model: $OLLAMA_DEFAULT_MODEL"
log "GPU enabled: $OLLAMA_GPU_ENABLED"
log "Keep alive: $OLLAMA_KEEP_ALIVE"
log "Memory limit: $OLLAMA_MEMORY_LIMIT"

##############################################
# Clone Ollama Configuration Repository
##############################################

# Skip if ollama folder already exists AND has docker-compose.yml
if [ -d "$OLLAMA_DIR" ] && [ -f "$OLLAMA_DIR/docker-compose.yml" ]; then
    log "Ollama configuration already exists at $OLLAMA_DIR, skipping clone"
else
    log "=== Cloning Ollama configuration repository ==="

    # Create temporary directory for cloning
    TEMP_DIR=$(mktemp -d)
    log "Created temporary directory: $TEMP_DIR"

    # Cleanup trap
    trap "rm -rf '$TEMP_DIR'" EXIT

    # Clone repository (try SSH first, fallback to HTTPS)
    log "Cloning $OLLAMA_REPO repository"
    SSH_URL="git@github.com:${OLLAMA_REPO}.git"
    HTTPS_URL="https://github.com/${OLLAMA_REPO}.git"

    if git clone "$SSH_URL" "$TEMP_DIR/ollama-config" 2>/dev/null; then
        log "Cloned via SSH: $SSH_URL"
    elif git clone "$HTTPS_URL" "$TEMP_DIR/ollama-config"; then
        log "Cloned via HTTPS: $HTTPS_URL"
    else
        log "ERROR: Failed to clone repository"
        log "  Tried SSH:   $SSH_URL"
        log "  Tried HTTPS: $HTTPS_URL"
        log "Please verify the repository exists and is accessible"
        exit 1
    fi

    # Create ollama directory
    log "Creating ollama configuration directory"
    mkdir -p "$OLLAMA_DIR"

    # Copy configuration files
    log "Copying Ollama configuration files"
    if [ -f "$TEMP_DIR/ollama-config/docker-compose.yml" ]; then
        cp "$TEMP_DIR/ollama-config/docker-compose.yml" "$OLLAMA_DIR/"
        log "Copied docker-compose.yml"
    else
        log "ERROR: docker-compose.yml not found in repository"
        exit 1
    fi

    # Copy any additional files (optional)
    for file in "$TEMP_DIR/ollama-config"/*.sh "$TEMP_DIR/ollama-config"/*.md "$TEMP_DIR/ollama-config"/*.env.example; do
        if [ -f "$file" ]; then
            cp "$file" "$OLLAMA_DIR/"
            log "Copied $(basename "$file")"
        fi
    done

    # Cleanup is handled by trap
    log "Repository clone completed"
fi

##############################################
# GPU Detection
##############################################

detect_gpu() {
    if [ "$OLLAMA_GPU_ENABLED" = "false" ]; then
        echo "cpu"
        return
    fi

    if [ "$OLLAMA_GPU_ENABLED" = "true" ]; then
        echo "gpu"
        return
    fi

    # Auto-detect GPU
    if command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
        log "NVIDIA GPU detected"
        echo "gpu"
    else
        log "No NVIDIA GPU detected, using CPU mode"
        echo "cpu"
    fi
}

GPU_MODE=$(detect_gpu)
log "GPU mode: $GPU_MODE"

##############################################
# Docker Validation
##############################################

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    log "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if docker compose is available
if ! docker compose version &> /dev/null; then
    log "Docker Compose is not available. Please install Docker Compose."
    exit 1
fi

# Check if docker-compose.yml exists
COMPOSE_FILE="$OLLAMA_DIR/docker-compose.yml"
if [ ! -f "$COMPOSE_FILE" ]; then
    log "docker-compose.yml not found at $COMPOSE_FILE"
    exit 1
fi

##############################################
# Start Ollama Container
##############################################

# Determine which profile to use
if [ "$GPU_MODE" = "gpu" ]; then
    PROFILE="ollama-gpu"
    CONTAINER_NAME="ollama-local-gpu"
else
    PROFILE="ollama"
    CONTAINER_NAME="ollama-local"
fi

log "Using Docker Compose profile: $PROFILE"
log "Container name: $CONTAINER_NAME"

# Check if container is already running
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    log "Ollama container ($CONTAINER_NAME) is already running"
else
    # Start Ollama container
    log "Starting Ollama container..."
    cd "$OLLAMA_DIR" || exit 1

    # Export environment variables for docker-compose
    export OLLAMA_KEEP_ALIVE
    export OLLAMA_MEMORY_LIMIT

    if docker compose --profile "$PROFILE" up -d; then
        log "Ollama container started successfully"
    else
        log "Failed to start Ollama container"
        exit 1
    fi

    # Wait for Ollama to be ready
    log "Waiting for Ollama to be ready..."
    MAX_RETRIES=30
    for ((i=1; i<=MAX_RETRIES; i++)); do
        if curl -s http://localhost:11434/api/tags &> /dev/null; then
            log "Ollama is ready"
            break
        fi
        if [ $i -eq $MAX_RETRIES ]; then
            log "Ollama did not become ready in time"
            exit 1
        fi
        sleep 2
    done
fi

##############################################
# Pull Default Model
##############################################

log "Pulling default model: $OLLAMA_DEFAULT_MODEL..."

if docker exec "$CONTAINER_NAME" ollama pull "$OLLAMA_DEFAULT_MODEL"; then
    log "Model $OLLAMA_DEFAULT_MODEL pulled successfully"
else
    log "Failed to pull model $OLLAMA_DEFAULT_MODEL (non-critical)"
fi

##############################################
# Configure Shell Aliases
##############################################

log ""
log "Setting up Ollama aliases..."
if [ -f ~/.zshrc ]; then
    # Remove existing Ollama configuration to avoid duplicates
    sed -i '/^# Ollama Local LLM/,/^$/d' ~/.zshrc 2>/dev/null || true
    sed -i '/^export OLLAMA_HOST/d' ~/.zshrc 2>/dev/null || true
    sed -i '/^alias ollama-/d' ~/.zshrc 2>/dev/null || true
    sed -i '/^alias cc1=/d' ~/.zshrc 2>/dev/null || true
    sed -i '/^_ollama_container()/,/^}/d' ~/.zshrc 2>/dev/null || true
    sed -i '/^ollama-run()/,/^}/d' ~/.zshrc 2>/dev/null || true
    sed -i '/^ollama-pull()/,/^}/d' ~/.zshrc 2>/dev/null || true
    sed -i '/^ollama-status()/,/^}/d' ~/.zshrc 2>/dev/null || true
    sed -i '/^cc1()/,/^}/d' ~/.zshrc 2>/dev/null || true

    # Add Ollama configuration with dynamic container detection
    cat >> ~/.zshrc << 'EOF'

# Ollama Local LLM
export OLLAMA_HOST="http://localhost:11434"

# Helper function to get running Ollama container name
_ollama_container() {
    docker ps --format '{{.Names}}' 2>/dev/null | grep -E '^ollama-local(-gpu)?$' | head -1
}

# Ollama management functions (auto-detect CPU/GPU container)
ollama-run() {
    local container=$(_ollama_container)
    [ -z "$container" ] && echo "Ollama not running" && return 1
    docker exec -it "$container" ollama run "$@"
}

ollama-pull() {
    local container=$(_ollama_container)
    [ -z "$container" ] && echo "Ollama not running" && return 1
    docker exec "$container" ollama pull "$@"
}

ollama-status() {
    local container=$(_ollama_container)
    [ -z "$container" ] && echo "Ollama not running" && return 1
    docker exec "$container" ollama ps
}

alias ollama-list='curl -s http://localhost:11434/api/tags | jq -r ".models[].name" 2>/dev/null || echo "Ollama not running"'
alias ollama-start='cd ${PROJECT_ROOT:-.}/.devcontainer/ollama && docker compose --profile ollama up -d'
alias ollama-stop='docker stop ollama-local 2>/dev/null; docker stop ollama-local-gpu 2>/dev/null'

# Quick model shortcuts for cost optimization
# Local (free) - use for simple tasks
cc1() {
    local container=$(_ollama_container)
    [ -z "$container" ] && echo "Ollama not running. Start with: ollama-start" && return 1
    docker exec -it "$container" ollama run "${1:-qwen2.5-coder:7b}"
}

# Claude API (paid) - use for complex tasks
# cc  -> claude (default model) - defined in install_claude_code.sh
# cc2 -> claude sonnet
# cc3 -> claude opus
EOF

    log "Added Ollama aliases to ~/.zshrc"
    log "  ollama-run   - Run interactive session with a model"
    log "  ollama-pull  - Pull a new model"
    log "  ollama-list  - List installed models"
    log "  ollama-status - Show running models"
    log "  ollama-start - Start Ollama container"
    log "  ollama-stop  - Stop Ollama container"
    log "  cc1          - Quick access to local LLM (free)"
else
    log "~/.zshrc not found, skipping alias setup"
fi

log ""
log "=== Ollama installation complete ==="
log ""
log "Configuration cloned from: https://github.com/${OLLAMA_REPO}"
log "Location: $OLLAMA_DIR"
log ""
log "Usage:"
log "  Interactive:  ollama-run $OLLAMA_DEFAULT_MODEL"
log "  Pull model:   ollama-pull codellama:7b"
log "  List models:  ollama-list"
log ""
log "Cost optimization strategy:"
log "  cc1 -> Local Ollama (free) - simple completions, explanations"
log "  cc  -> Claude (default)    - complex coding tasks"
log "  cc2 -> Claude Sonnet       - multi-file changes"
log "  cc3 -> Claude Opus         - deep reasoning, architecture"
log ""
log "API endpoint: http://localhost:11434/v1/chat/completions"
log "Log file: $LOGFILE"
