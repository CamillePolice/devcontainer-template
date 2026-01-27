# Claude Code CLI Installation Script

## Overview

The `install_claude_code.sh` script automates the installation of the Claude Code CLI using the official native installer from Anthropic. This provides the command-line interface for Claude Code, enabling AI-powered coding assistance directly from your terminal.

## Location

```
.devcontainer/scripts/setup/install_claude_code.sh
```

## When It Runs

- **Automatically**: During container creation (via `post_create.sh`)
- **Manually**: Can be executed directly when needed
- **Before**: `configure_claude.sh` (which configures the Claude Code environment)

## What It Does

1. **Checks Installation Status**: Skips if Claude Code is already installed
2. **Downloads Installer**: Fetches the official installation script from `https://claude.ai/install.sh`
3. **Installs Claude Code**: Runs the installer with the specified channel/version
4. **Verifies Installation**: Confirms the `claude` command is available
5. **Creates CLAUDE.md Template**: Generates a project-specific guidance file at the project root
6. **Provides Next Steps**: Shows authentication instructions and customization guidance

## Environment Variables

### `USE_CLAUDE_CODE`

Master toggle for Claude Code CLI installation.

| Value | Behavior |
|-------|----------|
| `true` | Installs Claude Code CLI (default) |
| `false` | Skips Claude Code CLI installation entirely |

### `CLAUDE_CODE_CHANNEL`

Controls which version/channel of Claude Code to install.

| Value | Behavior |
|-------|----------|
| `latest` | Install the latest version (default, auto-updates) |
| `stable` | Install the stable channel (~1 week behind latest) |
| `1.0.58` | Install a specific version number |

**Set in `devcontainer.json`:**
```json
{
  "containerEnv": {
    "USE_CLAUDE_CODE": "true",
    "CLAUDE_CODE_CHANNEL": "latest"
  }
}
```

## Installation Channels

### Latest Channel (Recommended)

```json
"CLAUDE_CODE_CHANNEL": "latest"
```

- Receive new features as soon as they're released
- Auto-updates in the background
- Best for staying current with Claude Code development

### Stable Channel

```json
"CLAUDE_CODE_CHANNEL": "stable"
```

- Uses a version that's ~1 week old
- Skips versions with major regressions
- Better for production/team environments

### Specific Version

```json
"CLAUDE_CODE_CHANNEL": "1.0.58"
```

- Pin to a specific version
- Useful for reproducible builds
- Won't auto-update (until channel is changed)

## Authentication Methods

After installation, you'll need to authenticate Claude Code. The script provides guidance for:

### For Individuals

1. **Claude Pro or Max** (Recommended)
   - Subscribe at [claude.ai/pricing](https://claude.ai/pricing)
   - Unified subscription for Claude Code and Claude web
   - Login with your Claude.ai account

2. **Claude Console**
   - Login via [console.anthropic.com](https://console.anthropic.com)
   - Requires active billing in the Console
   - Auto-creates a "Claude Code" workspace

### For Teams and Organizations

1. **Claude for Teams/Enterprise** (Recommended)
   - Centralized billing and team management
   - Access to both Claude Code and Claude web
   - Login with Claude.ai accounts

2. **Claude Console with Team Billing**
   - Setup shared organization with team billing
   - Invite team members with role assignments

3. **Cloud Providers**
   - Amazon Bedrock
   - Google Vertex AI
   - Microsoft Foundry

## Manual Execution

Run the script manually:

```bash
# From workspace root
./.devcontainer/scripts/setup/install_claude_code.sh

# Or from anywhere
bash /workspace/.devcontainer/scripts/setup/install_claude_code.sh
```

## Log Location

```
.devcontainer/.log/claude_code_install.log
```

View the log:
```bash
cat .devcontainer/.log/claude_code_install.log
tail -f .devcontainer/.log/claude_code_install.log  # Follow in real-time
```

## After Installation

### 1. Customize CLAUDE.md

The script automatically creates a `CLAUDE.md` template at your project root. This file helps Claude Code understand your project better.

**Template includes sections for:**
- Project overview and architecture
- Key commands and workflows
- Coding standards and conventions
- Testing guidelines
- Git workflow
- Environment variables
- Deployment process
- Troubleshooting tips

**Edit the template:**
```bash
# Open and customize with your project details
vim CLAUDE.md
# or
code CLAUDE.md
```

**Why CLAUDE.md matters:**
- Provides context to Claude Code about your project
- Documents conventions and patterns
- Helps Claude generate consistent code
- Serves as onboarding documentation for team members

### 2. Authenticate Claude Code

```bash
cd /workspace
claude
```

Follow the prompts to authenticate with your preferred method.

### 2. Verify Installation

```bash
# Check version
claude --version

# Run diagnostic check
claude doctor
```

### 3. Start Using Claude Code

```bash
# Start Claude Code in your project
cd /path/to/project
claude

# Or use specific commands
claude chat "Help me debug this error"
```

## Updating Claude Code

### Automatic Updates

Claude Code automatically updates in the background by default.

### Manual Update

```bash
claude update
```

### Disable Auto-Updates

Set environment variable in `devcontainer.json`:
```json
{
  "containerEnv": {
    "DISABLE_AUTOUPDATER": "1"
  }
}
```

Or in your shell:
```bash
export DISABLE_AUTOUPDATER=1
```

## Troubleshooting

### Script Skips Installation

**Problem:** Script exits immediately with "Claude Code installation disabled"

**Solution:** Check environment variable:
```bash
echo $USE_CLAUDE_CODE  # Should be "true"
```

Set in `devcontainer.json` if needed.

### Claude Already Installed

**Problem:** Script reports Claude Code is already installed

**Solution:** This is normal behavior. To reinstall:
```bash
# Uninstall first
rm -f ~/.local/bin/claude
rm -rf ~/.local/share/claude

# Then rebuild container
```

### Installation Failed

**Problem:** Installer fails to download or install

**Solution:**
1. Check internet connection
2. Verify you can access `https://claude.ai`
3. Check the log for specific error messages:
   ```bash
   cat .devcontainer/.log/claude_code_install.log
   ```
4. Try manual installation:
   ```bash
   curl -fsSL https://claude.ai/install.sh | bash
   ```

### Command Not Found After Installation

**Problem:** `claude` command not found after installation

**Solution:**
1. Restart your shell:
   ```bash
   exec $SHELL
   ```
2. Check if `~/.local/bin` is in your PATH:
   ```bash
   echo $PATH | grep -q ".local/bin" && echo "✅ In PATH" || echo "❌ Not in PATH"
   ```
3. Add to PATH if needed:
   ```bash
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

### Authentication Issues

**Problem:** Cannot authenticate after installation

**Solution:**
1. Ensure you have an active Claude subscription or Console billing
2. Check supported countries: [anthropic.com/supported-countries](https://www.anthropic.com/supported-countries)
3. Run `claude doctor` to diagnose issues
4. See [Claude Code Troubleshooting](https://code.claude.com/docs/troubleshooting)

### CLAUDE.md Not Created

**Problem:** CLAUDE.md template was not created at project root

**Solution:**
1. Check if file already exists:
   ```bash
   ls -la CLAUDE.md
   ```
2. Create it manually:
   ```bash
   .devcontainer/scripts/setup/install_claude_code.sh
   ```
3. Or create from scratch using the template structure documented above

## System Requirements

- **OS**: macOS 13.0+, Ubuntu 20.04+/Debian 10+, Windows 10+ (WSL)
- **RAM**: 4GB+
- **Network**: Internet connection required
- **Shell**: Bash or Zsh (works best)

## Related Documentation

- [Environment Variables](./environment-variables.md) - Complete variable reference
- [Claude Code Configuration](../../docs/claude-code.md) - Detailed Claude Code setup
- [Official Claude Code Docs](https://code.claude.com/docs/) - Anthropic documentation
- [Best Practices](./best-practices.md) - Script development guidelines

## Script Structure

```bash
#!/bin/bash

# 1. Initialize environment and logging
# 2. Check if Claude Code installation is enabled (USE_CLAUDE_CODE)
# 3. Check if claude is already installed (skip if yes)
# 4. Create temporary directory for installation
# 5. Download official installer from claude.ai
# 6. Run installer with specified channel/version
# 7. Verify installation (check claude command)
# 8. Create CLAUDE.md template at project root (if not exists)
# 9. Log authentication instructions and next steps
```

**Key Features:**
- **CLAUDE.md Generation**: Automatically creates a project guidance template
- **Smart Skip**: Won't overwrite existing CLAUDE.md files
- **Variable Substitution**: Replaces `${PROJECT_NAME}` with actual project name
- **Template Sections**: Includes all recommended sections for Claude Code context

## Binary Integrity

Claude Code binaries are verified for security:

- **SHA256 Checksums**: Published in release manifests
- **Code Signing**:
  - macOS: Signed by "Anthropic PBC" and notarized by Apple
  - Windows: Signed by "Anthropic, PBC"

## Advanced Configuration

### Enterprise Deployments

For enterprise deployments with managed settings:

```json
{
  "containerEnv": {
    "CLAUDE_CODE_CHANNEL": "stable",
    "DISABLE_AUTOUPDATER": "1"
  }
}
```

This ensures:
- Consistent stable version across team
- No unexpected updates
- Controlled version management

### Version Pinning for CI/CD

For reproducible builds in CI/CD:

```json
{
  "containerEnv": {
    "CLAUDE_CODE_CHANNEL": "1.0.58"
  }
}
```

### Custom Installation Path

By default, Claude Code installs to `~/.local/bin/`. To verify:

```bash
which claude
# Should output: /home/vscode/.local/bin/claude
```

## Integration with Other Scripts

The Claude Code installation script works alongside:

- **`configure_claude.sh`**: Configures Claude Code with skills, agents, hooks
- **`configure_vscode.sh`**: Sets up VS Code integration
- **Post-creation workflow**: Runs automatically during container setup

---

**For more information, see:**
- [Official Installation Guide](https://code.claude.com/docs/setup)
- [Main Devcontainer README](../../README.md)
