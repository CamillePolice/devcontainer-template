#!/bin/bash

# Use env vars from devcontainer.json, with fallback for manual execution
SCRIPT_DIR="${DEVCONTAINER_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
PROJECT_NAME="${PROJECT_NAME:-project}"

# Claude Code installation options from environment
USE_CLAUDE_CODE="${USE_CLAUDE_CODE:-true}"
CLAUDE_CODE_CHANNEL="${CLAUDE_CODE_CHANNEL:-latest}"  # Options: latest, stable, or specific version

# Create log directory if it doesn't exist
LOG_DIR="$PROJECT_ROOT/.devcontainer/.log"
mkdir -p "$LOG_DIR"

# Set up logging
LOGFILE="$LOG_DIR/claude_code_install.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

function log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check if Claude Code installation is enabled
if [ "$USE_CLAUDE_CODE" != "true" ]; then
    log "Claude Code installation disabled (USE_CLAUDE_CODE=false)"
    exit 0
fi

log "=== Starting Claude Code installation script ==="
log "Installation channel: $CLAUDE_CODE_CHANNEL"

# Check if claude is already installed
if command -v claude &> /dev/null; then
    INSTALLED_VERSION=$(claude --version 2>/dev/null | head -n 1 || echo "unknown")
    log "✅ Claude Code is already installed: $INSTALLED_VERSION"
    log "   To update, run: claude update"
    log "   To reinstall, uninstall first: rm -f ~/.local/bin/claude && rm -rf ~/.local/share/claude"
    exit 0
fi

log "📥 Installing Claude Code..."

# Create temporary directory for installation
TEMP_DIR=$(mktemp -d)
trap "rm -rf '$TEMP_DIR'" EXIT

cd "$TEMP_DIR" || {
    log "❌ Failed to create temporary directory"
    exit 1
}

# Download the installation script
log "📦 Downloading Claude Code installer..."
if ! curl -fsSL https://claude.ai/install.sh -o install.sh; then
    log "❌ Failed to download Claude Code installer"
    log "   Check your internet connection and try again"
    exit 1
fi

# Make the installer executable
chmod +x install.sh

# Run the installer with the specified channel/version
log "🚀 Running Claude Code installer..."
if [ "$CLAUDE_CODE_CHANNEL" = "latest" ]; then
    # Install latest version (default)
    if bash install.sh; then
        log "✅ Claude Code installed successfully"
    else
        log "❌ Claude Code installation failed"
        exit 1
    fi
elif [ "$CLAUDE_CODE_CHANNEL" = "stable" ]; then
    # Install stable channel
    if bash install.sh stable; then
        log "✅ Claude Code (stable channel) installed successfully"
    else
        log "❌ Claude Code installation failed"
        exit 1
    fi
else
    # Install specific version
    log "   Installing version: $CLAUDE_CODE_CHANNEL"
    if bash install.sh "$CLAUDE_CODE_CHANNEL"; then
        log "✅ Claude Code version $CLAUDE_CODE_CHANNEL installed successfully"
    else
        log "❌ Claude Code installation failed"
        exit 1
    fi
fi

# Verify installation
log ""
log "🔍 Verifying installation..."
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null | head -n 1 || echo "unknown")
    log "✅ Claude Code verified: $CLAUDE_VERSION"
    
    # Create CLAUDE.md template at project root if it doesn't exist
    log ""
    log "📄 Creating CLAUDE.md template..."
    if [ ! -f "$PROJECT_ROOT/CLAUDE.md" ]; then
        cat > "$PROJECT_ROOT/CLAUDE.md" << 'EOF'
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Project Name:** ${PROJECT_NAME}

[Provide a brief description of your project, its purpose, and main technologies used]

## Architecture

```
[Describe your project structure, key directories, and their purposes]
```

## Key Commands

### Development

```bash
# Start development server
[your-command]

# Run tests
[your-command]

# Build for production
[your-command]
```

### Common Tasks

[List frequently used commands and workflows]

## Coding Standards

### File Organization

- [Your file naming conventions]
- [Directory structure guidelines]
- [Module organization patterns]

### Code Style

- [Language-specific style guidelines]
- [Formatting rules]
- [Naming conventions]

## Testing Guidelines

[Your testing approach, frameworks, and requirements]

## Git Workflow

### Branch Naming

[Your branch naming conventions]

### Commit Format

[Your commit message format]

### Pull Request Process

[Your PR workflow and requirements]

## Environment Variables

[Document important environment variables and their purposes]

## Deployment

[Deployment process and considerations]

## Troubleshooting

### Common Issues

[List common problems and solutions]

### Debug Tips

[Debugging strategies specific to your project]

## Resources

- [Links to relevant documentation]
- [API references]
- [Design documents]

---

**Note:** This file helps Claude Code understand your project better. Keep it updated as your project evolves.
EOF
        
        # Replace ${PROJECT_NAME} with actual project name
        if [ -n "$PROJECT_NAME" ] && [ "$PROJECT_NAME" != "PROJECT_NAME" ]; then
            sed -i "s/\${PROJECT_NAME}/$PROJECT_NAME/g" "$PROJECT_ROOT/CLAUDE.md" 2>/dev/null || \
            sed -i '' "s/\${PROJECT_NAME}/$PROJECT_NAME/g" "$PROJECT_ROOT/CLAUDE.md" 2>/dev/null
        fi
        
        log "✅ Created CLAUDE.md template at project root"
        log "   📝 Customize this file with your project-specific information"
    else
        log "ℹ️  CLAUDE.md already exists at project root"
    fi
    
    # Add 'cc' alias to zshrc for convenient Claude Code access
    log ""
    log "⚙️  Setting up 'cc' alias for Claude Code..."
    if [ -f ~/.zshrc ]; then
        # Remove any existing cc alias for claude (avoid duplicates)
        sed -i '/^alias cc=.*claude/d' ~/.zshrc 2>/dev/null || true
        
        # Add the alias
        if ! grep -q "alias cc='claude'" ~/.zshrc 2>/dev/null; then
            echo "" >> ~/.zshrc
            echo "# Claude Code CLI shortcut" >> ~/.zshrc
            echo "alias cc='claude'" >> ~/.zshrc
            log "✅ Added 'cc' alias to ~/.zshrc"
            log "   You can now use 'cc' as a shortcut for 'claude'"
        else
            log "ℹ️  'cc' alias already exists in ~/.zshrc"
        fi
    else
        log "⚠️  ~/.zshrc not found, skipping alias setup"
    fi
    
    log ""
    log "📝 Next steps:"
    log "   1. Customize CLAUDE.md with your project details"
    log "   2. Authenticate Claude Code:"
    log "      cd $PROJECT_ROOT"
    log "      claude"
    log "   3. Choose authentication method:"
    log "      - Claude Pro/Max account (recommended for individuals)"
    log "      - Claude Console with active billing"
    log "      - Claude for Teams/Enterprise (for organizations)"
    log "   4. Run 'claude doctor' to verify your setup"
    log ""
    log "📚 Documentation: https://code.claude.com/docs/"
else
    log "⚠️  Claude Code installation completed but 'claude' command not found in PATH"
    log "   You may need to restart your shell or add ~/.local/bin to your PATH"
    log "   Add to your shell profile: export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

log ""
log "=== Claude Code installation complete ==="
log "📋 View log: $LOGFILE"
