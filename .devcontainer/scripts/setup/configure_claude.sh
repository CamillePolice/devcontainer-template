#!/bin/bash

# Use env vars from devcontainer.json, with fallback for manual execution
SCRIPT_DIR="${DEVCONTAINER_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Claude configuration options from environment
USE_CLAUDE_CODE="${USE_CLAUDE_CODE:-true}"
USE_CLAUDE="${USE_CLAUDE:-false}"
USE_CLAUDE_MARKETPLACE="${USE_CLAUDE_MARKETPLACE:-false}"

# Create log directory if it doesn't exist
LOG_DIR="$PROJECT_ROOT/.devcontainer/.log"
mkdir -p "$LOG_DIR"

# Set up logging
LOGFILE="$LOG_DIR/claude_config.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

function log() {
   echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check if Claude Code integration is enabled
if [ "$USE_CLAUDE_CODE" != "true" ]; then
   log "Claude Code integration disabled (USE_CLAUDE_CODE=false)"
   exit 0
fi

# Check if any Claude configuration is enabled
if [ "$USE_CLAUDE" != "true" ] && [ "$USE_CLAUDE_MARKETPLACE" != "true" ]; then
   log "Claude configuration disabled (USE_CLAUDE=false, USE_CLAUDE_MARKETPLACE=false)"
   exit 0
fi

log "=== Starting Project Claude configuration script ==="
log "Configuration mode: USE_CLAUDE_CODE=$USE_CLAUDE_CODE, USE_CLAUDE=$USE_CLAUDE, USE_CLAUDE_MARKETPLACE=$USE_CLAUDE_MARKETPLACE"

# Enable debug mode
set -x

##############################################
# Option 1: Direct Repository Copy
##############################################
if [ "$USE_CLAUDE" = "true" ]; then
   log "=== Configuring Claude via direct repository copy ==="
   
   # Skip if .claude folder already exists AND has content
   if [ -d "$PROJECT_ROOT/.claude" ] && [ "$(ls -A $PROJECT_ROOT/.claude 2>/dev/null)" ]; then
      log ".claude folder already exists with content, skipping direct copy"
   else
      # Create temporary directory for cloning
      TEMP_DIR=$(mktemp -d)
      log "Created temporary directory: $TEMP_DIR"

      # Clone repository (using HTTPS for better compatibility)
      log "Cloning everything-claude-code repository"
      if ! git clone https://github.com/affaan-m/everything-claude-code.git "$TEMP_DIR/everything-claude-code"; then
         log "ERROR: Failed to clone repository"
         rm -rf "$TEMP_DIR"
         exit 1
      fi

      # Create .claude structure
      log "Creating .claude folder structure"
      mkdir -p "$PROJECT_ROOT/.claude"/{agents,skills,commands,hooks,rules}

      # Copy only necessary components (exclude .git, tests, examples, etc.)
      log "Copying agents"
      cp -r "$TEMP_DIR/everything-claude-code/agents/"*.md "$PROJECT_ROOT/.claude/agents/" 2>/dev/null || true

      log "Copying skills"
      cp -r "$TEMP_DIR/everything-claude-code/skills/"* "$PROJECT_ROOT/.claude/skills/" 2>/dev/null || true

      log "Copying commands"
      cp -r "$TEMP_DIR/everything-claude-code/commands/"*.md "$PROJECT_ROOT/.claude/commands/" 2>/dev/null || true

      log "Copying hooks configuration"
      cp "$TEMP_DIR/everything-claude-code/hooks/hooks.json" "$PROJECT_ROOT/.claude/hooks/" 2>/dev/null || true

      log "Copying rules (project-level)"
      cp -r "$TEMP_DIR/everything-claude-code/rules/"*.md "$PROJECT_ROOT/.claude/rules/" 2>/dev/null || true

      log "Copying scripts"
      cp -r "$TEMP_DIR/everything-claude-code/scripts" "$PROJECT_ROOT/.claude/" 2>/dev/null || true

      log "Copying contexts"
      cp -r "$TEMP_DIR/everything-claude-code/contexts" "$PROJECT_ROOT/.claude/" 2>/dev/null || true

      # Copy plugin metadata
      log "Copying plugin metadata"
      cp -r "$TEMP_DIR/everything-claude-code/.claude-plugin" "$PROJECT_ROOT/.claude/" 2>/dev/null || true

      # Cleanup
      log "Cleaning up temporary directory"
      rm -rf "$TEMP_DIR"
      
      log "Direct repository copy completed"
   fi
fi

##############################################
# Option 2: Plugin Marketplace Setup
##############################################
if [ "$USE_CLAUDE_MARKETPLACE" = "true" ]; then
   log "=== Configuring Claude via plugin marketplace ==="
   
   CLAUDE_SETTINGS="$HOME/.claude/settings.json"
   
   # Create .claude directory if it doesn't exist
   mkdir -p "$HOME/.claude"
   
   # Check if settings.json exists
   if [ ! -f "$CLAUDE_SETTINGS" ]; then
      log "Creating new Claude settings.json"
      cat > "$CLAUDE_SETTINGS" << 'EOF'
{
  "extraKnownMarketplaces": {
    "everything-claude-code": {
      "source": {
        "source": "github",
        "repo": "affaan-m/everything-claude-code"
      }
    }
  },
  "enabledPlugins": {
    "everything-claude-code@everything-claude-code": true
  }
}
EOF
      log "Claude settings.json created"
   else
      log "Claude settings.json already exists"
      log "To enable the marketplace manually, add this to ~/.claude/settings.json:"
      log ""
      log "  \"extraKnownMarketplaces\": {"
      log "    \"everything-claude-code\": {"
      log "      \"source\": {"
      log "        \"source\": \"github\","
      log "        \"repo\": \"affaan-m/everything-claude-code\""
      log "      }"
      log "    }"
      log "  },"
      log "  \"enabledPlugins\": {"
      log "    \"everything-claude-code@everything-claude-code\": true"
      log "  }"
      log ""
      log "Or run these commands in Claude Code:"
      log "  /plugin marketplace add affaan-m/everything-claude-code"
      log "  /plugin install everything-claude-code@everything-claude-code"
   fi
fi

log "=== Project Claude configuration completed successfully ==="
log "Log file available at: $LOGFILE"
log ""
log "Summary:"
if [ "$USE_CLAUDE" = "true" ]; then
   log "✓ Direct copy: Configurations copied to $PROJECT_ROOT/.claude/"
fi
if [ "$USE_CLAUDE_MARKETPLACE" = "true" ]; then
   log "✓ Marketplace: Check $CLAUDE_SETTINGS for plugin configuration"
fi
log ""
log "Next steps:"
log "1. Review configurations in $PROJECT_ROOT/.claude/ (if using direct copy)"
log "2. Update MCP configs with your API keys if needed"
log "3. Customize rules/skills for your project"
log "4. In Claude Code, verify plugins with: /plugin list"

set +x  # Disable debug mode
