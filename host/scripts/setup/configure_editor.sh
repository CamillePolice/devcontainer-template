#!/bin/bash
# Configure both Cursor and VSCode user-level: merge editor-config/cursor and editor-config/vscode
# into CURSOR_USER_DIR and VSCODE_USER_DIR. Uses HOST_DIR, HOST_SCRIPTS; sources detect_os.

set -e

HOST_DIR="${HOST_DIR:?}"
HOST_SCRIPTS="${HOST_SCRIPTS:?}"
LOG_DIR="$HOST_DIR/.log"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/configure_editor.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

# shellcheck source=../lib/detect_os.sh
source "$HOST_SCRIPTS/lib/detect_os.sh"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

copy_into() {
    local src_dir="$1"
    local dest_dir="$2"
    local name="$3"
    if [ ! -d "$src_dir" ]; then
        log "Skip $name: source $src_dir not found"
        return 0
    fi
    mkdir -p "$dest_dir"
    for f in "$src_dir"/*; do
        [ -e "$f" ] || continue
        b=$(basename "$f")
        if [ -f "$f" ]; then
            cp "$f" "$dest_dir/$b"
            log "Copied $name: $b"
        elif [ -d "$f" ]; then
            cp -r "$f" "$dest_dir/"
            log "Copied $name dir: $b"
        fi
    done
}

# Cursor user
log "Configuring Cursor user config at $CURSOR_USER_DIR"
copy_into "$HOST_DIR/editor-config/cursor" "$CURSOR_USER_DIR" "Cursor"

# VSCode user
log "Configuring VSCode user config at $VSCODE_USER_DIR"
copy_into "$HOST_DIR/editor-config/vscode" "$VSCODE_USER_DIR" "VSCode"

log "Both Cursor and VSCode user configs updated."
