#!/bin/bash

# Use env vars from devcontainer.json, with fallback for manual execution
SCRIPT_DIR="${DEVCONTAINER_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
PROJECT_NAME="${PROJECT_NAME:-project}"

# VS Code configuration options from environment
USE_VSCODE_CONFIG="${USE_VSCODE_CONFIG:-true}"

# Create log directory if it doesn't exist
LOG_DIR="$PROJECT_ROOT/.devcontainer/.log"
mkdir -p "$LOG_DIR"

# Set up logging
LOGFILE="$LOG_DIR/vscode_config.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

function log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check if VS Code configuration is enabled
if [ "$USE_VSCODE_CONFIG" != "true" ]; then
    log "VS Code configuration disabled (USE_VSCODE_CONFIG=false)"
    exit 0
fi

log "=== Starting VS Code configuration script ==="
log "Configuration mode: USE_VSCODE_CONFIG=$USE_VSCODE_CONFIG"

# Source directory (inside devcontainer)
SOURCE_DIR="$PROJECT_ROOT/.devcontainer/.vscode"
# Target directory (workspace root)
TARGET_VSCODE_DIR="$PROJECT_ROOT/.vscode"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    log "❌ Source directory not found: $SOURCE_DIR"
    exit 1
fi

log "📂 Source directory: $SOURCE_DIR"
log "📂 Target directory: $TARGET_VSCODE_DIR"

# Create target .vscode directory if it doesn't exist
if [ ! -d "$TARGET_VSCODE_DIR" ]; then
    log "Creating .vscode directory in workspace root..."
    mkdir -p "$TARGET_VSCODE_DIR"
fi

# Function to safely copy file, skipping if target exists
copy_if_not_exists() {
    local src="$1"
    local dest="$2"
    local file_name=$(basename "$src")
    
    if [ -f "$dest" ]; then
        log "ℹ️  File already exists, skipping: $file_name"
        return 0
    fi
    
    cp "$src" "$dest"
    log "✅ Copied: $file_name"
}

# Function to copy directory contents recursively
copy_directory() {
    local src="$1"
    local dest="$2"
    local dir_name=$(basename "$src")
    
    if [ ! -d "$src" ]; then
        log "⚠️  Directory not found: $src"
        return 1
    fi
    
    mkdir -p "$dest"
    cp -r "$src"/* "$dest/" 2>/dev/null || true
    log "✅ Copied directory: $dir_name -> $dest"
}

# 1. Copy main settings.json
log ""
log "📝 Copying VS Code settings..."
if [ -f "$SOURCE_DIR/settings.json" ]; then
    copy_if_not_exists "$SOURCE_DIR/settings.json" "$TARGET_VSCODE_DIR/settings.json"
else
    log "⚠️  settings.json not found in source directory"
fi

# 2. Copy tasks.json from config folder
log ""
log "📋 Copying VS Code tasks..."
if [ -f "$SOURCE_DIR/config/tasks.json" ]; then
    copy_if_not_exists "$SOURCE_DIR/config/tasks.json" "$TARGET_VSCODE_DIR/tasks.json"
else
    log "⚠️  tasks.json not found in config directory"
fi

# 3. Copy launch.json if it exists (and is not .example)
log ""
log "🐛 Copying debug configurations..."
if [ -f "$SOURCE_DIR/config/launch.json" ]; then
    # User has created their own launch.json from the example
    copy_if_not_exists "$SOURCE_DIR/config/launch.json" "$TARGET_VSCODE_DIR/launch.json"
    log "✅ Using user-created launch.json"
elif [ -f "$SOURCE_DIR/config/launch.json.example" ]; then
    log "ℹ️  Found launch.json.example only (no user-created launch.json)"
    log "   To create your own: cp .devcontainer/.vscode/config/launch.json.example .devcontainer/.vscode/config/launch.json"
    log "   Then rebuild container to apply"
else
    log "⚠️  No launch.json or launch.json.example found"
fi

# 4. Copy extensions.json
log ""
log "🧩 Copying VS Code extensions recommendations..."
if [ -f "$SOURCE_DIR/extensions/extensions.json" ]; then
    copy_if_not_exists "$SOURCE_DIR/extensions/extensions.json" "$TARGET_VSCODE_DIR/extensions.json"
else
    log "⚠️  extensions.json not found in extensions directory"
fi

# 5. Copy linting configuration files to workspace root
log ""
log "📏 Copying linting configuration files..."

if [ -f "$SOURCE_DIR/linting/.editorconfig" ]; then
    copy_if_not_exists "$SOURCE_DIR/linting/.editorconfig" "$PROJECT_ROOT/.editorconfig"
else
    log "⚠️  .editorconfig not found in linting directory"
fi

if [ -f "$SOURCE_DIR/linting/.prettierrc" ]; then
    copy_if_not_exists "$SOURCE_DIR/linting/.prettierrc" "$PROJECT_ROOT/.prettierrc"
else
    log "⚠️  .prettierrc not found in linting directory"
fi

if [ -f "$SOURCE_DIR/linting/.prettierignore" ]; then
    copy_if_not_exists "$SOURCE_DIR/linting/.prettierignore" "$PROJECT_ROOT/.prettierignore"
else
    log "⚠️  .prettierignore not found in linting directory"
fi

# 6. Handle .pre-commit-config.yaml (user-created or example)
log ""
log "🪝 Copying Git pre-commit configuration..."
if [ -f "$SOURCE_DIR/git/.pre-commit-config.yaml" ]; then
    # User has created their own .pre-commit-config.yaml from the example
    copy_if_not_exists "$SOURCE_DIR/git/.pre-commit-config.yaml" "$PROJECT_ROOT/.pre-commit-config.yaml"
    log "✅ Using user-created .pre-commit-config.yaml"
elif [ -f "$SOURCE_DIR/git/.pre-commit-config.yaml.example" ]; then
    # Only example file exists
    if [ ! -f "$PROJECT_ROOT/.pre-commit-config.yaml.example" ]; then
        log "ℹ️  Copying .pre-commit-config.yaml.example to workspace root"
        cp "$SOURCE_DIR/git/.pre-commit-config.yaml.example" "$PROJECT_ROOT/.pre-commit-config.yaml.example"
        log "   To create your own: cp .devcontainer/.vscode/git/.pre-commit-config.yaml.example .devcontainer/.vscode/git/.pre-commit-config.yaml"
        log "   Then rebuild container to apply"
    else
        log "ℹ️  .pre-commit-config.yaml.example already exists in workspace root"
    fi
else
    log "⚠️  No .pre-commit-config.yaml or .pre-commit-config.yaml.example found"
fi

# 7. Copy workspace file to .vscode folder
log ""
log "📁 Copying VS Code workspace file..."
WORKSPACE_FILENAME="${PROJECT_NAME}.code-workspace"
if [ -f "$SOURCE_DIR/config/project.code-workspace" ]; then
    # Copy workspace file to .vscode directory instead of project root
    if [ ! -f "$TARGET_VSCODE_DIR/$WORKSPACE_FILENAME" ]; then
        cp "$SOURCE_DIR/config/project.code-workspace" "$TARGET_VSCODE_DIR/$WORKSPACE_FILENAME"
        log "✅ Copied workspace file to .vscode/$WORKSPACE_FILENAME"
    else
        log "ℹ️  Workspace file already exists in .vscode/"
    fi
else
    log "⚠️  project.code-workspace not found in config directory"
fi

# Summary
log ""
log "=== VS Code configuration complete ==="
log "✅ Configuration files copied to:"
log "   - VS Code settings: $TARGET_VSCODE_DIR/"
log "   - Linting config: $PROJECT_ROOT/"
log ""
log "📝 Next steps:"
log "   1. Reload VS Code window to apply settings"
log "   2. Install recommended extensions (if prompted)"
log "   3. Review and customize settings as needed"
log ""
log "📋 View log: $LOGFILE"
