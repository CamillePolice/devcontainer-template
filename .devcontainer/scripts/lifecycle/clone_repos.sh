#!/bin/bash
# clone_repos.sh — Clone repositories listed in REPO_URLS into workspace root (same level as .devcontainer).
# For each clone: remove README; add CLAUDE.md, .claude, .vscode to that repo's .gitignore.
# REPO_URLS is read from .devcontainer/.env (comma or space separated; short form owner/repo or full URL).

SCRIPT_DIR="${DEVCONTAINER_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

LOG_DIR="$PROJECT_ROOT/.devcontainer/.log"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/clone_repos.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

function log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

# Load .devcontainer/.env so REPO_URLS is available
if [ -f "$PROJECT_ROOT/.devcontainer/.env" ]; then
    set -a
    # shellcheck source=/dev/null
    source "$PROJECT_ROOT/.devcontainer/.env"
    set +a
fi

REPO_URLS="${REPO_URLS:-}"

if [ -z "$REPO_URLS" ]; then
    log "REPO_URLS not set, skipping clone_repos"
    exit 0
fi

log "=== Clone repositories (REPO_URLS) ==="

# Normalize: replace commas with spaces
REPO_URLS="${REPO_URLS//,/ }"

for raw in $REPO_URLS; do
    [ -z "$raw" ] && continue

    # Resolve URL
    if [[ "$raw" =~ ^https?:// ]] || [[ "$raw" =~ ^git@ ]]; then
        url="$raw"
        # Ensure .git suffix for URL parsing
        if [[ "$url" =~ ^https?://.*\.git$ ]]; then
            :
        elif [[ "$url" =~ ^https?:// ]]; then
            url="${url%/}"
            url="${url}.git"
        fi
        # Dir name: last path component without .git (e.g. https://github.com/opvigil/opvigil-frontend.git -> opvigil-frontend)
        base="${url##*/}"
        dir_name="${base%.git}"
    else
        # Short form: owner/repo
        url="https://github.com/${raw}.git"
        dir_name="${raw##*/}"
    fi

    dest="$PROJECT_ROOT/$dir_name"

    if [ -d "$dest" ]; then
        log "Already exists, skipping: $dir_name"
        # Still run post-process (README + .gitignore) in case of partial previous run
    else
        log "Cloning $url -> $dest"
        if ! git clone --depth 1 "$url" "$dest"; then
            log "WARNING: git clone failed for $url"
            continue
        fi
    fi

    # Post-process cloned repo
    if [ ! -d "$dest/.git" ]; then
        log "Not a git repo, skipping post-process: $dest"
        continue
    fi

    # Remove README (README.md, README, and common variants)
    for readme in README.md README Readme.md readme.md; do
        if [ -f "$dest/$readme" ]; then
            rm -f "$dest/$readme"
            log "Removed $dir_name/$readme"
        fi
    done

    # Ensure .gitignore has devcontainer-related entries
    GITIGNORE="$dest/.gitignore"
    for entry in "CLAUDE.md" ".claude" ".vscode"; do
        if [ -f "$GITIGNORE" ]; then
            if grep -qFx "$entry" "$GITIGNORE" 2>/dev/null; then
                : # already present
            else
                echo "$entry" >> "$GITIGNORE"
                log "Added $entry to $dir_name/.gitignore"
            fi
        else
            echo "$entry" >> "$GITIGNORE"
            log "Created $dir_name/.gitignore with $entry"
        fi
    done
done

log "=== Clone repositories done ==="
