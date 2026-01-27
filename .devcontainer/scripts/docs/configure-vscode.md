# VS Code Configuration Script

## Overview

The `configure_vscode.sh` script automates the setup of VS Code configuration files from the devcontainer template to your workspace. It copies settings, tasks, extensions recommendations, and linting configurations from `.devcontainer/.vscode/` to the appropriate locations in your project.

## Location

```
.devcontainer/scripts/setup/configure_vscode.sh
```

## When It Runs

- **Automatically**: During container creation (via `post_create.sh`)
- **Manually**: Can be executed directly when needed

## What It Configures

### 1. VS Code Settings

Copies `.devcontainer/.vscode/settings.json` → `.vscode/settings.json`

**Includes:**
- Terminal configuration (zsh, bash profiles)
- Editor settings (font, ligatures, format on save)
- File handling (auto-save, trim whitespace)
- Language-specific formatters (TypeScript, HTML, JSON)
- Git settings
- Theme and icon configurations

### 2. Tasks Configuration

Copies `.devcontainer/.vscode/config/tasks.json` → `.vscode/tasks.json`

**Provides:**
- Environment initialization task (`Init env`)
- Docker startup task (`Start docker`)
- Utility tasks (Zone.Identifier cleanup)

### 3. Debug Configuration (Optional)

**User-Created File:** `.devcontainer/.vscode/config/launch.json`

The script checks for a user-created `launch.json`:
- ✅ If `launch.json` exists → Copies to `.vscode/launch.json`
- ℹ️ If only `launch.json.example` exists → Skips, provides instructions

**To create your own:**
```bash
# 1. Copy the example file
cp .devcontainer/.vscode/config/launch.json.example .devcontainer/.vscode/config/launch.json

# 2. Customize for your project
# Edit .devcontainer/.vscode/config/launch.json

# 3. Rebuild container to apply
# Dev Containers: Rebuild Container
```

### 4. Extensions Recommendations

Copies `.devcontainer/.vscode/extensions/extensions.json` → `.vscode/extensions.json`

**Categories:**
- Core development (Claude Code, GitHub integration)
- Code quality (ESLint, Prettier, EditorConfig)
- Git tools (GitLens, Git Graph)
- Docker support
- Utilities and visuals

### 5. Linting Configuration

Copies to **workspace root**:
- `.devcontainer/.vscode/linting/.editorconfig` → `.editorconfig`
- `.devcontainer/.vscode/linting/.prettierrc` → `.prettierrc`
- `.devcontainer/.vscode/linting/.prettierignore` → `.prettierignore`

### 6. Git Pre-commit Hooks (Optional)

**User-Created File:** `.devcontainer/.vscode/git/.pre-commit-config.yaml`

The script checks for a user-created `.pre-commit-config.yaml`:
- ✅ If `.pre-commit-config.yaml` exists → Copies to workspace root
- ℹ️ If only `.pre-commit-config.yaml.example` exists → Copies example, provides instructions

**To create your own:**
```bash
# 1. Copy the example file
cp .devcontainer/.vscode/git/.pre-commit-config.yaml.example .devcontainer/.vscode/git/.pre-commit-config.yaml

# 2. Customize for your project
# Edit .devcontainer/.vscode/git/.pre-commit-config.yaml

# 3. Rebuild container to apply
# Dev Containers: Rebuild Container

# 4. After container rebuild, activate hooks
cd /workspace
pip install pre-commit
pre-commit install
```

### 7. Workspace File

Creates symlink with dynamic naming based on `PROJECT_NAME` environment variable:

`.devcontainer/.vscode/config/project.code-workspace` → `${PROJECT_NAME}.code-workspace`

**Example:** If `PROJECT_NAME="my-app"`, creates `my-app.code-workspace`

**Default:** If `PROJECT_NAME` is not set, uses `project.code-workspace`

## Workflow for Custom Configurations

This devcontainer template supports **optional user-created configurations** for project-specific needs.

### Quick Start Workflow

1. **Review Environment Variables**
   
   Before building the container, review `devcontainer.json`:
   ```json
   "containerEnv": {
     "PROJECT_NAME": "my-project",  // ← Set your project name
     "USE_VSCODE_CONFIG": "true",   // ← Enable VS Code config
     "USE_CLAUDE_CODE": "true",     // ← Toggle features as needed
     // ... other variables
   }
   ```
   
   See [Environment Variables](./environment-variables.md) for complete list.

2. **Create Custom Configurations** (Optional)
   
   If you need project-specific debug or Git hooks:
   
   ```bash
   # Debug configuration (optional)
   cp .devcontainer/.vscode/config/launch.json.example \
      .devcontainer/.vscode/config/launch.json
   # Edit launch.json for your debug needs
   
   # Pre-commit hooks (optional)
   cp .devcontainer/.vscode/git/.pre-commit-config.yaml.example \
      .devcontainer/.vscode/git/.pre-commit-config.yaml
   # Edit .pre-commit-config.yaml for your project
   ```

3. **Build/Rebuild Container**
   
   - First time: **Dev Containers: Reopen in Container**
   - After changes: **Dev Containers: Rebuild Container**

4. **Verify Configuration**
   
   Check the log to confirm files were copied:
   ```bash
   cat .devcontainer/.log/vscode_config.log
   ```

### When to Create Custom Configurations

| Configuration | When to Create | When to Skip |
|---------------|----------------|--------------|
| **launch.json** | Your project needs debugging (Node.js, Python, etc.) | Simple projects without debugging needs |
| **.pre-commit-config.yaml** | You want automated code quality checks on commits | No Git workflow automation needed |

### Updating Custom Configurations

After creating custom configurations, any changes require a container rebuild:

```bash
# 1. Edit your custom files
vim .devcontainer/.vscode/config/launch.json

# 2. Rebuild container
# Command Palette → Dev Containers: Rebuild Container
```

## Environment Variables

### `USE_VSCODE_CONFIG`

Controls whether VS Code configuration is applied.

| Value | Behavior |
|-------|----------|
| `true` | Copies all VS Code configuration files (default) |
| `false` | Skips VS Code configuration entirely |

**Set in `devcontainer.json`:**
```json
{
  "containerEnv": {
    "USE_VSCODE_CONFIG": "true"
  }
}
```

## File Handling

### Backup Strategy

When copying files, the script creates timestamped backups of existing files:

```
existing-file.json → existing-file.json.backup.20260127_143022
```

This prevents accidental overwrites of customized configurations.

### Example Files

Files with `.example` suffix are **not** automatically copied:
- `launch.json.example` - Manual copy required for debug configurations
- `.pre-commit-config.yaml.example` - Manual copy required for Git hooks

## Manual Execution

Run the script manually:

```bash
# From workspace root
./.devcontainer/scripts/setup/configure_vscode.sh

# Or from anywhere
bash /workspace/.devcontainer/scripts/setup/configure_vscode.sh
```

## Log Location

```
.devcontainer/.log/vscode_config.log
```

View the log:
```bash
cat .devcontainer/.log/vscode_config.log
tail -f .devcontainer/.log/vscode_config.log  # Follow in real-time
```

## After Configuration

### 1. Reload VS Code

Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS) and select:
```
Developer: Reload Window
```

### 2. Install Recommended Extensions

VS Code will prompt to install recommended extensions. Click **Install All** or review individually.

### 3. Verify Settings

Check that settings are applied:
- Open Settings (`Ctrl+,` or `Cmd+,`)
- Search for specific settings (e.g., "format on save")
- Verify they match the template configuration

## Customization

### Override Settings

After initial setup, customize settings in `.vscode/settings.json`:

```json
{
  // Your custom overrides
  "editor.fontSize": 16,
  "workbench.colorTheme": "GitHub Dark"
}
```

### Project-Specific Tasks

Add custom tasks to `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    // Template tasks remain here
    {
      "label": "My Custom Task",
      "type": "shell",
      "command": "npm run build"
    }
  ]
}
```

## Troubleshooting

### Script Skips Execution

**Problem:** Script exits immediately with "VS Code configuration disabled"

**Solution:** Check environment variable:
```bash
echo $USE_VSCODE_CONFIG  # Should be "true"
```

Set in `devcontainer.json` if needed.

### Files Not Copied

**Problem:** Specific configuration files are missing

**Solution:** Check source files exist:
```bash
ls -la .devcontainer/.vscode/
ls -la .devcontainer/.vscode/config/
ls -la .devcontainer/.vscode/linting/
```

### Extensions Not Recommended

**Problem:** VS Code doesn't prompt to install extensions

**Solution:** Manually trigger installation:
1. Open Extensions view (`Ctrl+Shift+X` or `Cmd+Shift+X`)
2. Look for "Recommended" section
3. Or run: `code --install-extension <extension-id>`

### Settings Not Applied

**Problem:** Settings don't match template

**Solution:**
1. Check `.vscode/settings.json` was copied:
   ```bash
   cat .vscode/settings.json
   ```
2. Reload VS Code window
3. Check for conflicting user-level settings

### Backup Files Accumulate

**Problem:** Multiple backup files created

**Solution:** This is normal behavior. Remove old backups manually:
```bash
find .vscode -name "*.backup.*" -mtime +30 -delete  # Remove backups older than 30 days
```

## Related Documentation

- [Environment Variables](./environment-variables.md) - Complete list of control variables
- [Best Practices](./best-practices.md) - Script development guidelines
- [VS Code Configuration](../docs/vscode-config.md) - Detailed VS Code setup guide
- [VS Code Extensions](../docs/vscode-extensions.md) - Extension recommendations

## Script Structure

```bash
#!/bin/bash

# 1. Initialize environment and logging
# 2. Check if configuration is enabled (USE_VSCODE_CONFIG)
# 3. Verify source directory exists
# 4. Create target directories
# 5. Copy VS Code settings (settings.json)
# 6. Copy tasks configuration (tasks.json)
# 7. Copy debug configuration (launch.json) if user created it
# 8. Copy extensions recommendations (extensions.json)
# 9. Copy linting configuration (.editorconfig, .prettierrc, .prettierignore)
# 10. Copy Git pre-commit config (.pre-commit-config.yaml) if user created it
# 11. Create workspace file symlink (${PROJECT_NAME}.code-workspace)
# 12. Log summary and next steps
```

**Key Logic:**
- **launch.json**: Only copies if user created `.devcontainer/.vscode/config/launch.json` (not the .example)
- **.pre-commit-config.yaml**: Only copies if user created `.devcontainer/.vscode/git/.pre-commit-config.yaml` (not the .example)
- **Backups**: Automatically backs up existing files before overwriting

## Best Practices

### For Template Maintainers

1. **Keep configurations in sync**: Update both template and documentation when changing configs
2. **Use examples for project-specific configs**: Files like `launch.json` should be `.example` files
3. **Document customization points**: Clearly mark which settings users should customize

### For Template Users

1. **Review before customizing**: Check the template configuration first
2. **Use backups wisely**: Don't delete backup files immediately
3. **Document your changes**: Add comments to customized settings
4. **Keep linting configs in sync**: If you modify `.editorconfig`, update `.prettierrc` accordingly

## Integration with Other Scripts

The VS Code configuration script works alongside:

- **`post_create.sh`**: Calls this script during initial container setup
- **`configure_git_prompt.sh`**: Shell prompt works with VS Code terminal settings
- **`install_cli_tools.sh`**: CLI tools integrate with VS Code tasks
- **`configure_claude.sh`**: Claude Code extension configured via extensions.json

---

**For more information, see the [main devcontainer README](../../README.md).**
