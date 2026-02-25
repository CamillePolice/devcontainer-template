#!/bin/bash
# One-time host setup (Unix: Linux/macOS). Run from host directory.
# Usage: ./run_post_create.sh   or   bash run_post_create.sh

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

"$HOST_SCRIPTS/lifecycle/post_create.sh"
