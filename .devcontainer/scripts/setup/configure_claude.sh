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

# Require jq for JSON operations (installed via Dockerfile)
if ! command -v jq &> /dev/null; then
   log "ERROR: jq is required but not found. Install with: apt install jq"
   log "The devcontainer Dockerfile includes jq - rebuild the container if running inside one."
   exit 1
fi

log "=== Starting Project Claude configuration script ==="
log "Configuration mode: USE_CLAUDE_CODE=$USE_CLAUDE_CODE, USE_CLAUDE=$USE_CLAUDE, USE_CLAUDE_MARKETPLACE=$USE_CLAUDE_MARKETPLACE"

# Enable debug mode
set -x

##############################################
# Option 1: Ensure .claude folder structure (no clone)
##############################################
if [ "$USE_CLAUDE" = "true" ]; then
   log "=== Configuring Claude project structure ==="

   if [ -d "$PROJECT_ROOT/.claude" ] && [ "$(ls -A $PROJECT_ROOT/.claude 2>/dev/null)" ]; then
      log ".claude folder already exists with content, skipping"
   else
      log "Creating empty .claude folder structure (agents, skills, commands, hooks, rules)"
      mkdir -p "$PROJECT_ROOT/.claude"/{agents,skills,commands,hooks,rules}
      log "Tip: [everything-claude-code](https://github.com/affaan-m/everything-claude-code) is a great source for agents, skills, hooks, and rules — see .devcontainer/docs/claude-code.md"
   fi
fi

##############################################
# MCP Servers Configuration
##############################################
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
MCP_CONFIG="$PROJECT_ROOT/.claude/mcp/mcp.json"
PERMISSIONS_CONFIG="$PROJECT_ROOT/.claude/permissions/permissions.json"

# Create .claude directory if it doesn't exist
mkdir -p "$HOME/.claude"

# Initialize settings.json if it doesn't exist
if [ ! -f "$CLAUDE_SETTINGS" ]; then
   log "Creating new Claude settings.json"
   if ! jq -n '{} | .["$schema"] = "https://json.schemastore.org/claude-code-settings.json"' > "$CLAUDE_SETTINGS"; then
      log "ERROR: Failed to create settings.json"
      exit 1
   fi
fi

log "=== Configuring MCP servers (disabled by default - enable via /config or settings.json) ==="

# Add MCP servers
if [ -f "$MCP_CONFIG" ]; then
   log "MCP configuration found at $MCP_CONFIG"

   # Check if mcpServers section exists
   if ! grep -q '"mcpServers"' "$CLAUDE_SETTINGS" 2>/dev/null; then
      log "Adding MCP servers to settings.json"
      MCP_CONTENT=$(cat "$MCP_CONFIG")
      if ! jq --argjson mcp "$MCP_CONTENT" '. + $mcp' "$CLAUDE_SETTINGS" > "${CLAUDE_SETTINGS}.tmp"; then
         log "ERROR: Failed to merge MCP config. Check $MCP_CONFIG is valid JSON."
         rm -f "${CLAUDE_SETTINGS}.tmp"
      else
         mv "${CLAUDE_SETTINGS}.tmp" "$CLAUDE_SETTINGS"
         # Add disabled: true to each server (enable manually via /config or settings.json)
         if ! jq '.mcpServers |= (to_entries | map(.value + {"disabled": true}) | from_entries)' "$CLAUDE_SETTINGS" > "${CLAUDE_SETTINGS}.tmp"; then
            log "ERROR: Failed to set MCP servers as disabled"
            rm -f "${CLAUDE_SETTINGS}.tmp"
         else
            mv "${CLAUDE_SETTINGS}.tmp" "$CLAUDE_SETTINGS"
         fi
         log "MCP servers added to $CLAUDE_SETTINGS (disabled by default)"
      fi
   else
      log "MCP servers already configured in settings.json"
   fi
else
   log "No MCP configuration found at $MCP_CONFIG"
   # Ensure mcpServers key exists so we can add Chrome DevTools
   if [ -f "$CLAUDE_SETTINGS" ] && ! grep -q '"mcpServers"' "$CLAUDE_SETTINGS" 2>/dev/null; then
      log "Adding mcpServers section for Chrome DevTools MCP"
      if ! jq '.mcpServers = {}' "$CLAUDE_SETTINGS" > "${CLAUDE_SETTINGS}.tmp"; then
         log "ERROR: Failed to add mcpServers section"
         rm -f "${CLAUDE_SETTINGS}.tmp"
      else
         mv "${CLAUDE_SETTINGS}.tmp" "$CLAUDE_SETTINGS"
      fi
   fi
fi

# Ensure Chrome DevTools MCP is always configured (browser automation, debugging, performance)
if [ -f "$CLAUDE_SETTINGS" ] && grep -q '"mcpServers"' "$CLAUDE_SETTINGS" 2>/dev/null; then
   log "Ensuring Chrome DevTools MCP is configured"
   CHROME_MCP='{"command": "npx", "args": ["-y", "chrome-devtools-mcp@latest"], "disabled": true}'
   if ! jq --argjson chrome "$CHROME_MCP" '.mcpServers = ((.mcpServers // {}) + {"chrome-devtools": $chrome})' "$CLAUDE_SETTINGS" > "${CLAUDE_SETTINGS}.tmp"; then
      log "ERROR: Failed to add Chrome DevTools MCP"
      rm -f "${CLAUDE_SETTINGS}.tmp"
   else
      mv "${CLAUDE_SETTINGS}.tmp" "$CLAUDE_SETTINGS"
      log "Chrome DevTools MCP added/updated in settings"
   fi
fi

# Ensure Exa MCP is always configured (web search, code search, company research)
if [ -f "$CLAUDE_SETTINGS" ] && grep -q '"mcpServers"' "$CLAUDE_SETTINGS" 2>/dev/null; then
   log "Ensuring Exa MCP is configured"
   EXA_MCP='{"url": "https://mcp.exa.ai/mcp", "disabled": true}'
   if ! jq --argjson exa "$EXA_MCP" '.mcpServers = ((.mcpServers // {}) + {"exa": $exa})' "$CLAUDE_SETTINGS" > "${CLAUDE_SETTINGS}.tmp"; then
      log "ERROR: Failed to add Exa MCP"
      rm -f "${CLAUDE_SETTINGS}.tmp"
   else
      mv "${CLAUDE_SETTINGS}.tmp" "$CLAUDE_SETTINGS"
      log "Exa MCP added/updated in settings"
   fi
fi

log ""
log "MCP Servers configured (disabled by default):"
log "  - Context7: Enhanced context management (requires CONTEXT7_API_KEY)"
log "  - Playwright: Browser automation and E2E testing"
log "  - Chrome DevTools: Browser control, debugging, performance analysis"
log "  - Exa: Web search, code search, company research (https://exa.ai)"
log "  Enable via /config or edit ~/.claude/settings.json"

# Add Permissions
if [ -f "$PERMISSIONS_CONFIG" ]; then
   log ""
   log "Permissions configuration found at $PERMISSIONS_CONFIG"

   # Check if permissions section exists
   if ! grep -q '"permissions"' "$CLAUDE_SETTINGS" 2>/dev/null; then
      log "Adding permissions to settings.json"
      PERM_CONTENT=$(cat "$PERMISSIONS_CONFIG")
      if ! jq --argjson perm "$PERM_CONTENT" '. + $perm' "$CLAUDE_SETTINGS" > "${CLAUDE_SETTINGS}.tmp"; then
         log "ERROR: Failed to merge permissions. Check $PERMISSIONS_CONFIG is valid JSON."
         rm -f "${CLAUDE_SETTINGS}.tmp"
      else
         mv "${CLAUDE_SETTINGS}.tmp" "$CLAUDE_SETTINGS"
         log "Permissions added to $CLAUDE_SETTINGS"
      fi
   else
      log "Permissions already configured in settings.json"
   fi

   log ""
   log "Pre-approved commands configured (git, npm, docker, etc.)"
else
   log "No permissions configuration found at $PERMISSIONS_CONFIG"
fi

log ""
log "To set Context7 API key:"
log "  export CONTEXT7_API_KEY='your-api-key-here'"
log "  Or add to ~/.zshrc for persistence"

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
    },
    "claude-mem": {
      "source": {
        "source": "github",
        "repo": "thedotmack/claude-mem"
      }
    }
  },
  "enabledPlugins": {
    "everything-claude-code@everything-claude-code": true,
    "claude-mem@claude-mem": true
  }
}
EOF
      log "Claude settings.json created"
   else
      log "Claude settings.json already exists"
      log "Adding marketplace plugins (everything-claude-code, claude-mem) to existing settings"
      if ! jq '
         .extraKnownMarketplaces = ((.extraKnownMarketplaces // {}) + {
           "everything-claude-code": {
             "source": { "source": "github", "repo": "affaan-m/everything-claude-code" }
           },
           "claude-mem": {
             "source": { "source": "github", "repo": "thedotmack/claude-mem" }
           }
         }) |
         .enabledPlugins = ((.enabledPlugins // {}) + {
           "everything-claude-code@everything-claude-code": true,
           "claude-mem@claude-mem": true
         })
      ' "$CLAUDE_SETTINGS" > "${CLAUDE_SETTINGS}.tmp"; then
         log "ERROR: Failed to merge marketplace plugins. Check $CLAUDE_SETTINGS is valid JSON."
         rm -f "${CLAUDE_SETTINGS}.tmp"
      else
         mv "${CLAUDE_SETTINGS}.tmp" "$CLAUDE_SETTINGS"
         log "Marketplace plugins added to settings.json"
      fi
   fi
fi

log "=== Project Claude configuration completed successfully ==="
log "Log file available at: $LOGFILE"
log ""
log "Summary:"
if [ "$USE_CLAUDE" = "true" ]; then
   log "✓ Project structure: $PROJECT_ROOT/.claude/ (see docs for optional content from everything-claude-code)"
fi
if [ -f "$PROJECT_ROOT/.claude/mcp/mcp.json" ] || grep -q '"mcpServers"' "$CLAUDE_SETTINGS" 2>/dev/null; then
   log "✓ MCP Servers: Configured in $CLAUDE_SETTINGS (disabled by default)"
fi
if [ -f "$PROJECT_ROOT/.claude/permissions/permissions.json" ]; then
   log "✓ Permissions: Pre-approved commands configured"
fi
if [ "$USE_CLAUDE_MARKETPLACE" = "true" ]; then
   log "✓ Marketplace: Check $CLAUDE_SETTINGS for plugin configuration"
fi
log ""
log "Next steps:"
log "1. Review configurations in $PROJECT_ROOT/.claude/"
log "2. Set CONTEXT7_API_KEY environment variable for Context7 MCP"
log "3. Customize rules/skills/permissions for your project"
log "4. In Claude Code, verify with: /plugin list"
log "5. Test MCP servers by checking available tools"

set +x  # Disable debug mode
