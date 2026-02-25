#!/bin/bash
# Session init for host (Unix: Linux/macOS). Run once per machine or after pulling host updates.
# Usage: ./run_init_env.sh   or   bash run_init_env.sh

set -e

HOST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export HOST_DIR
export HOST_SCRIPTS="$HOST_DIR/scripts"

# Source .env if present
if [ -f "$HOST_DIR/.env" ]; then
    set -a
    # shellcheck source=/dev/null
    source "$HOST_DIR/.env"
    set +a
fi

"$HOST_SCRIPTS/lifecycle/init_env.sh"
