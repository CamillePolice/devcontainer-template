#!/bin/bash

# Use env vars from devcontainer.json, with fallback for manual execution
SCRIPT_DIR="${DEVCONTAINER_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Check if docker autocomplete configuration is enabled
USE_DOCKER_AUTOCOMPLETE="${USE_DOCKER_AUTOCOMPLETE:-true}"

# Create log directory if it doesn't exist
LOG_DIR="$PROJECT_ROOT/.devcontainer/.log"
mkdir -p "$LOG_DIR"

# Set up logging
LOGFILE="$LOG_DIR/docker_autocomplete.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

function log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Skip if disabled
if [ "$USE_DOCKER_AUTOCOMPLETE" != "true" ]; then
    log "Docker autocomplete configuration disabled (USE_DOCKER_AUTOCOMPLETE=false)"
    exit 0
fi

log "=== Starting Docker autocomplete configuration script ==="

# Enable debug mode
set -x

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    log "WARNING: Docker is not installed. Autocomplete will be configured but may not work until Docker is installed."
else
    log "Docker is installed: $(docker --version)"
fi

# Configure bash autocompletion
log "Configuring bash autocompletion..."
mkdir -p ~/.local/share/bash-completion/completions

# Docker bash completion
if [ ! -f ~/.local/share/bash-completion/completions/docker ]; then
    log "Downloading Docker bash completion..."
    if curl -fsSL https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker -o ~/.local/share/bash-completion/completions/docker; then
        log "Successfully downloaded Docker bash completion"
    else
        log "ERROR: Failed to download Docker bash completion"
        exit 1
    fi
else
    log "Docker bash completion already exists, skipping download"
fi

# Docker Compose bash completion
if [ ! -f ~/.local/share/bash-completion/completions/docker-compose ]; then
    log "Downloading Docker Compose bash completion..."
    if curl -fsSL https://raw.githubusercontent.com/docker/compose/master/contrib/completion/bash/docker-compose -o ~/.local/share/bash-completion/completions/docker-compose; then
        log "Successfully downloaded Docker Compose bash completion"
    else
        log "WARNING: Failed to download Docker Compose bash completion (may not be available)"
    fi
else
    log "Docker Compose bash completion already exists, skipping download"
fi

# Configure zsh autocompletion (since the project uses zsh)
log "Configuring zsh autocompletion..."
mkdir -p ~/.zsh/completions

# Docker zsh completion
if [ ! -f ~/.zsh/completions/_docker ]; then
    log "Downloading Docker zsh completion..."
    if curl -fsSL https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker -o ~/.zsh/completions/_docker; then
        log "Successfully downloaded Docker zsh completion"
    else
        log "WARNING: Failed to download Docker zsh completion"
    fi
else
    log "Docker zsh completion already exists, skipping download"
fi

# Docker Compose zsh completion
if [ ! -f ~/.zsh/completions/_docker-compose ]; then
    log "Downloading Docker Compose zsh completion..."
    if curl -fsSL https://raw.githubusercontent.com/docker/compose/master/contrib/completion/zsh/_docker-compose -o ~/.zsh/completions/_docker-compose; then
        log "Successfully downloaded Docker Compose zsh completion"
    else
        log "WARNING: Failed to download Docker Compose zsh completion (may not be available)"
    fi
else
    log "Docker Compose zsh completion already exists, skipping download"
fi

# Add zsh completion directory to fpath if not already present
if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "/usr/bin/zsh" ] || [ "$SHELL" = "/bin/zsh" ]; then
    log "Configuring zsh fpath for completions..."
    if ! grep -q "fpath=(~/.zsh/completions" ~/.zshrc 2>/dev/null; then
        cat >> ~/.zshrc << 'EOF'

# Docker autocompletion
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit
EOF
        log "Added zsh completion configuration to .zshrc"
    else
        log "Zsh completion configuration already exists in .zshrc"
    fi
fi

# Source bash completion in .bashrc if it exists
if [ -f ~/.bashrc ]; then
    log "Configuring bash completion in .bashrc..."
    if ! grep -q "bash-completion/completions" ~/.bashrc 2>/dev/null; then
        cat >> ~/.bashrc << 'EOF'

# Docker autocompletion
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi
if [ -d ~/.local/share/bash-completion/completions ]; then
    for file in ~/.local/share/bash-completion/completions/*; do
        [ -f "$file" ] && . "$file"
    done
fi
EOF
        log "Added bash completion configuration to .bashrc"
    else
        log "Bash completion configuration already exists in .bashrc"
    fi
fi

log "=== Docker autocomplete configuration completed successfully $(date) ==="
log "Log file available at: $LOGFILE"
log "Note: Restart your shell or run 'source ~/.zshrc' (for zsh) or 'source ~/.bashrc' (for bash) to enable autocompletion"

set +x  # Disable debug mode
