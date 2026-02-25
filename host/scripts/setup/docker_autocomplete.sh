#!/bin/bash
# Docker and Docker Compose bash/zsh completions. Uses HOST_DIR. Linux/macOS.

set -e

HOST_DIR="${HOST_DIR:?}"
LOG_DIR="$HOST_DIR/.log"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/docker_autocomplete.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

if [ "${USE_DOCKER_AUTOCOMPLETE:-true}" != "true" ]; then
    log "USE_DOCKER_AUTOCOMPLETE is false; skipping."
    exit 0
fi

log "Configuring Docker autocomplete..."

mkdir -p "$HOME/.local/share/bash-completion/completions"
mkdir -p "$HOME/.zsh/completions"

for url in \
    "https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker|$HOME/.local/share/bash-completion/completions/docker" \
    "https://raw.githubusercontent.com/docker/compose/master/contrib/completion/bash/docker-compose|$HOME/.local/share/bash-completion/completions/docker-compose" \
    "https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker|$HOME/.zsh/completions/_docker" \
    "https://raw.githubusercontent.com/docker/compose/master/contrib/completion/zsh/_docker-compose|$HOME/.zsh/completions/_docker-compose"; do
    src="${url%%|*}"; dest="${url##*|}"
    if [ ! -f "$dest" ]; then
        if curl -fsSL "$src" -o "$dest" 2>/dev/null; then
            log "Downloaded $(basename "$dest")"
        else
            log "Warning: could not download $(basename "$dest")"
        fi
    fi
done

# Ensure zsh fpath includes completions
if [ -f "$HOME/.zshrc" ] && ! grep -q '\.zsh/completions' "$HOME/.zshrc" 2>/dev/null; then
    printf '\n# Docker completions\nfpath=(~/.zsh/completions $fpath)\nautoload -Uz compinit && compinit\n' >> "$HOME/.zshrc"
    log "Added zsh completion fpath to .zshrc"
fi

log "Docker autocomplete done."
