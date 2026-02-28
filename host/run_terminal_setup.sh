#!/bin/bash
# Install terminal customizations on host (same as devcontainer: zsh, Starship, tmux).
# Usage: ./run_terminal_setup.sh   or   bash run_terminal_setup.sh

set -e

HOST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export HOST_DIR
export HOST_SCRIPTS="$HOST_DIR/scripts"

if [ -f "$HOST_DIR/.env" ]; then
    set -a
    # shellcheck source=/dev/null
    source "$HOST_DIR/.env"
    set +a
fi

"$HOST_SCRIPTS/setup/install_terminal_setup.sh"
