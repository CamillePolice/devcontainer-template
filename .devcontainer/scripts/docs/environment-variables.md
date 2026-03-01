# Environment Variables Reference

Complete reference for all environment variables used in devcontainer scripts.

## Core Variables

### DEVCONTAINER_SCRIPTS
- **Type**: Path
- **Set By**: devcontainer.json
- **Default**: Auto-detected from script location
- **Purpose**: Path to the scripts directory
- **Used By**: All scripts for path resolution

### PROJECT_ROOT
- **Type**: Path
- **Set By**: devcontainer.json
- **Default**: Auto-detected (workspace folder)
- **Purpose**: Root directory of the project
- **Used By**: All scripts for file operations

### PROJECT_NAME
- **Type**: String
- **Set By**: devcontainer.json
- **Default**: `"project"`
- **Purpose**: Name of the project, used for workspace file naming
- **Used By**: `setup/configure_vscode.sh`
- **Example**: If set to `"my-app"`, creates `my-app.code-workspace`

**Example**:
```json
"PROJECT_NAME": "my-awesome-project"
```

### REPO_URLS
- **Type**: String (list)
- **Set By**: `.devcontainer/.env` (sourced by `clone_repos.sh`)
- **Default**: Empty (no clone)
- **Purpose**: Repositories to clone at workspace root (same level as `.devcontainer`). Each clone is post-processed: README removed; `CLAUDE.md`, `.claude`, `.vscode` added to that repo's `.gitignore`.
- **Format**: Comma or space separated. Short form: `owner/repo` (GitHub). Full URL: `https://github.com/owner/repo` or `git@github.com:owner/repo.git`.
- **Used By**: `lifecycle/clone_repos.sh` (called from `post_create.sh`)

**Example** (in `.devcontainer/.env`):
```bash
REPO_URLS=opvigil/opvigil-frontend,opvigil/opvigil-backend
```

### REMOTE_CONTAINERS
- **Type**: Boolean string
- **Set By**: devcontainer.json
- **Values**: `"true"` when in devcontainer
- **Purpose**: Detect if running in devcontainer
- **Used By**: Conditional logic in scripts

### DEVCONTAINER
- **Type**: Boolean string
- **Set By**: devcontainer.json
- **Values**: `"true"` when in devcontainer
- **Purpose**: Detect if running in devcontainer
- **Used By**: Conditional logic in scripts

## Feature Control Variables

### USE_CLAUDE_CODE
- **Type**: Boolean string
- **Default**: `"true"`
- **Values**: `"true"` | `"false"`
- **Purpose**: Master toggle for Claude Code CLI installation and integration
- **Affects**: `setup/install_claude_code.sh`, `setup/configure_claude.sh`
- **When disabled**: Skips Claude Code CLI installation and configuration

**Example**:
```json
"USE_CLAUDE_CODE": "false"  // Disable all Claude features
```

### CLAUDE_CODE_CHANNEL
- **Type**: String
- **Default**: `"latest"`
- **Values**: `"latest"` | `"stable"` | version number (e.g., `"1.0.58"`)
- **Purpose**: Control which Claude Code version/channel to install
- **Affects**: `setup/install_claude_code.sh`
- **Options**:
  - `"latest"` - Install latest version with auto-updates
  - `"stable"` - Install stable channel (~1 week behind latest)
  - `"1.0.58"` - Install specific version (no auto-update)

**Example**:
```json
"CLAUDE_CODE_CHANNEL": "stable"  // Use stable channel
```

### USE_CLAUDE
- **Type**: Boolean string
- **Default**: `"true"`
- **Values**: `"true"` | `"false"`
- **Purpose**: Ensure `.claude/` folder structure exists (agents, skills, commands, hooks, rules). No repository is cloned.
- **Affects**: `setup/configure_claude.sh`
- **When enabled**: Creates empty `.claude/` subdirs if missing. For ready-made agents, skills, hooks, and rules, [everything-claude-code](https://github.com/affaan-m/everything-claude-code) is a great source — see `.devcontainer/docs/claude-code.md`.

**Example**:
```json
"USE_CLAUDE": "true",  // Create .claude structure
```

### USE_CLAUDE_MARKETPLACE
- **Type**: Boolean string
- **Default**: `"true"`
- **Values**: `"true"` | `"false"`
- **Purpose**: Enable plugin marketplace mode
- **Affects**: `setup/configure_claude.sh`
- **When enabled**:
  - Creates/updates `~/.claude/settings.json`
  - Registers the everything-claude-code marketplace (great source for agents, skills, etc.)
  - Enables plugin automatically

**Example**:
```json
"USE_CLAUDE_MARKETPLACE": "true",  // Use plugin marketplace
```

### USE_RTK
- **Type**: Boolean string
- **Default**: `"true"`
- **Values**: `"true"` | `"false"`
- **Purpose**: Install [rtk](https://github.com/rtk-ai/rtk) (Rust Token Killer) — CLI proxy that reduces LLM token consumption by 60–90%
- **Affects**: `setup/install_rtk.sh` (runs after `configure_claude.sh`)
- **When enabled**: Installs rtk to `~/.local/bin`, runs `rtk init -g --auto-patch` (hook in `~/.claude/settings.json`)
- **When disabled**: Skips rtk installation and hook setup

**Example**:
```json
"USE_RTK": "false",  // Disable rtk token optimizer
```

### USE_GIT_PROMPT
- **Type**: Boolean string
- **Default**: `"true"`
- **Values**: `"true"` | `"false"`
- **Purpose**: Enable Oh My Zsh and Starship prompt
- **Affects**: `setup/configure_git_prompt.sh`
- **When disabled**: Skips shell prompt customization

**Example**:
```json
"USE_GIT_PROMPT": "false",  // Use default shell prompt
```

### USE_DOCKER_AUTOCOMPLETE
- **Type**: Boolean string
- **Default**: `"true"`
- **Values**: `"true"` | `"false"`
- **Purpose**: Enable Docker command completion
- **Affects**: `config/docker_autocomplete.sh`
- **When disabled**: Skips Docker autocomplete setup

**Example**:
```json
"USE_DOCKER_AUTOCOMPLETE": "false",  // No Docker completion
```

### USE_VSCODE_CONFIG
- **Type**: Boolean string
- **Default**: `"true"`
- **Values**: `"true"` | `"false"`
- **Purpose**: Enable VS Code configuration setup
- **Affects**: `setup/configure_vscode.sh`
- **When disabled**: Skips VS Code configuration files copy
- **When enabled**:
  - Copies settings.json, tasks.json, extensions.json
  - Copies linting configs (.editorconfig, .prettierrc)
  - Creates workspace symlinks
  - Backs up existing files automatically

**Example**:
```json
"USE_VSCODE_CONFIG": "false",  // Manual VS Code setup
```

### USE_RAG
- **Type**: Boolean string
- **Default**: `"false"`
- **Values**: `"true"` | `"false"`
- **Purpose**: Enable RAG-First agents and editor MCP (Supabase-backed knowledge)
- **Affects**: `ai/setup_rag.sh`, `ai/setup_editor_rag_mcp.sh`
- **When enabled**: Verifies Supabase connection; configures Cursor or VS Code with RAG MCP server (tools: `rag_load`, `rag_save_learning`, `rag_audit`, `rag_search`)
- **Requires**: `RAG_DSN` set on the **host** (e.g. in `~/.zshrc`), never in the repo

**Example**:
```bash
USE_RAG=true
```

### RAG_PROJECT
- **Type**: String
- **Default**: `PROJECT_NAME` or `global`
- **Purpose**: Project scope for RAG indexing and queries (e.g. `opvigil`, `archforge`, `global`)
- **Used by**: `seed_rag.py`, RAG MCP server, agents

**Example**:
```bash
RAG_PROJECT=opvigil
```

### WHICH_EDITOR
- **Type**: String
- **Default**: `"cursor"`
- **Values**: `"cursor"` | `"vscode"` | `"both"`
- **Purpose**: When `USE_RAG=true`, selects which editor(s) get the RAG MCP config and rules
- **Affects**: `ai/setup_editor_rag_mcp.sh`
- **Cursor**: Copies `.devcontainer/mcp/rag/cursor-mcp.json` → `.cursor/mcp.json`, `rag-cursor-rules.mdc` → `.cursor/rules-rag.mdc`
- **VSCode**: Copies `vscode-mcp.json` → `.vscode/mcp.json`, `rag-copilot-instructions.md` → `.github/copilot-instructions.md`

**Example**:
```bash
WHICH_EDITOR=cursor   # or vscode, both
```

## Configuration Examples

### Minimal Setup
```json
"containerEnv": {
    "PROJECT_ROOT": "${containerWorkspaceFolder}",
    "DEVCONTAINER_SCRIPTS": "${containerWorkspaceFolder}/.devcontainer/scripts",
    "USE_CLAUDE_CODE": "false",
    "USE_GIT_PROMPT": "false",
    "USE_DOCKER_AUTOCOMPLETE": "false",
    "USE_VSCODE_CONFIG": "false"
}
```

### Claude Marketplace Only
```json
"containerEnv": {
    "USE_CLAUDE_CODE": "true",
    "CLAUDE_CODE_CHANNEL": "stable",
    "USE_CLAUDE": "false",
    "USE_CLAUDE_MARKETPLACE": "true",
    "USE_VSCODE_CONFIG": "true"
}
```

### Full Features (Default)
```json
"containerEnv": {
    "USE_CLAUDE_CODE": "true",
    "CLAUDE_CODE_CHANNEL": "latest",
    "USE_CLAUDE": "true",
    "USE_CLAUDE_MARKETPLACE": "true",
    "USE_RTK": "true",
    "USE_GIT_PROMPT": "true",
    "USE_DOCKER_AUTOCOMPLETE": "true",
    "USE_VSCODE_CONFIG": "true"
}
```

### RAG + Editor MCP
Set in `.devcontainer/.env` (and `RAG_DSN` on the host only):
```bash
USE_RAG=true
RAG_PROJECT=my-project
WHICH_EDITOR=cursor   # or vscode, both
```

### Enterprise/Team Setup
```json
"containerEnv": {
    "USE_CLAUDE_CODE": "true",
    "CLAUDE_CODE_CHANNEL": "stable",
    "DISABLE_AUTOUPDATER": "1",
    "USE_CLAUDE": "true",
    "USE_CLAUDE_MARKETPLACE": "false",
    "USE_GIT_PROMPT": "true",
    "USE_DOCKER_AUTOCOMPLETE": "true",
    "USE_VSCODE_CONFIG": "true"
}
```

## Variable Hierarchy

### Claude Code Variables
```
USE_CLAUDE_CODE (master toggle for CLI + config)
  ├── CLAUDE_CODE_CHANNEL (version/channel selection)
  ├── USE_CLAUDE (create .claude/ structure, no clone)
  └── USE_CLAUDE_MARKETPLACE (marketplace setup)
```

If `USE_CLAUDE_CODE=false`, the CLI is not installed and both `USE_CLAUDE` and `USE_CLAUDE_MARKETPLACE` are ignored.

## Testing Variables

You can test variable behavior by running scripts manually:

```bash
# Test with variable disabled
USE_GIT_PROMPT=false .devcontainer/scripts/setup/configure_git_prompt.sh

# Test Claude CLI installation with stable channel
CLAUDE_CODE_CHANNEL=stable .devcontainer/scripts/setup/install_claude_code.sh

# Test Claude with only marketplace
USE_CLAUDE=false USE_CLAUDE_MARKETPLACE=true .devcontainer/scripts/setup/configure_claude.sh


# Test with all disabled
USE_CLAUDE_CODE=false .devcontainer/scripts/setup/configure_claude.sh

# Test VS Code configuration
USE_VSCODE_CONFIG=true .devcontainer/scripts/setup/configure_vscode.sh
```

## Troubleshooting

### Variable Not Recognized
- Check spelling in `devcontainer.json`
- Ensure value is a string: `"true"` not `true`
- Rebuild container after changes

### Variable Not Taking Effect
- Verify script reads the variable (check script source)
- Check log files in `.devcontainer/.log/` for variable values
- Try manual execution with the variable set

### Default Values
Most feature control variables default to `"true"` if not specified.
