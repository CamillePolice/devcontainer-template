# VS Code Configuration

VS Code workspace configuration including tasks, debug profiles, and project structure.

## 📁 Structure

```
.vscode/
├── config/
│   ├── tasks.json              # Build and utility tasks
│   └── launch.json.example     # Debug configurations template
│
├── extensions/                 # Extension management by stack
│   ├── install_by_stack.sh        # Stack-based extension installer
│   ├── extensions.json            # Base extensions
│   ├── angular/extensions.json    # Angular-specific extensions
│   ├── symfony/extensions.json    # Symfony/PHP extensions
│   └── go/extensions.json         # Go extensions
│
├── git/
│   └── .pre-commit-config.yaml.example
│
├── linting/                    # Linter configurations
│
├── profiles/                   # VS Code profiles
│   ├── CamilleP (Dark).code-profile
│   └── CamilleP (Light).code-profile
│
└── extensions.json             # Recommended extensions
```

---

## ⚡ Tasks

Automated tasks configured in `tasks.json`.

### Available Tasks

| Task | Description | Trigger |
|------|-------------|---------|
| 🔧 **Init env** | Initialize environment | On folder open |
| 🐳 **Start docker** | Start Docker services | On folder open (after Init env) |
| 🧹 **Clean Zone.Identifier** | Remove Windows WSL artifacts | Manual |

### Run Tasks Manually

```bash
# Via Command Palette
Ctrl+Shift+P → Tasks: Run Task

# Or via terminal
code --list-extensions
```

---

## 🐛 Debug Configurations

Pre-configured debug profiles in `launch.json.example`.

### Available Configurations

| Configuration | Description |
|---------------|-------------|
| 🔧 **Xdebug (Main API)** | PHP debugging on port 9003 |
| 🔧 **Xdebug (Historic API)** | PHP debugging on port 9004 |
| 🌐 **Chrome/Edge/Firefox** | Frontend debugging |
| 🧪 **Angular Tests** | Test debugging |
| 🎯 **Full Stack** | Combined debugging |

### Setup

1. Copy the example configuration:
   ```bash
   cp .vscode/config/launch.json.example .vscode/config/launch.json
   ```

2. Customize for your project

3. Start debugging:
   - Press `F5`
   - Or `Ctrl+Shift+D` → Select configuration → Start

---

## 👤 Profiles

VS Code profiles for different coding preferences.

### Available Profiles

- **CamilleP (Dark)** - Dark theme profile
- **CamilleP (Light)** - Light theme profile

### Import Profile

1. Open VS Code Command Palette (`Ctrl+Shift+P`)
2. Select **"Profiles: Import Profile"**
3. Choose the profile file from `.vscode/profiles/`

---

## 🧩 Extension Management

Extensions are organized by stack for modular installation.

See [VS Code Extensions](vscode-extensions.md) for details.

---

## 🎨 Workspace Settings

Common workspace settings in `settings.json`:

- **Format on save** - Automatic code formatting
- **Auto save** - Save files automatically
- **Prettier** - Default formatter
- **ESLint** - Automatic fixing
- **File associations** - Custom file type mappings

---

## 🔧 Customization

### Add a New Task

Edit `.vscode/config/tasks.json`:

```json
{
    "label": "My Custom Task",
    "type": "shell",
    "command": "echo 'Hello World'",
    "problemMatcher": []
}
```

### Add a Debug Configuration

Edit `.vscode/config/launch.json`:

```json
{
    "name": "My Debug Config",
    "type": "node",
    "request": "launch",
    "program": "${workspaceFolder}/app.js"
}
```

### Modify Workspace Settings

Edit `.vscode/settings.json` in your project root.

---

## 📚 Learn More

- [VS Code Tasks Documentation](https://code.visualstudio.com/docs/editor/tasks)
- [VS Code Debugging](https://code.visualstudio.com/docs/editor/debugging)
- [VS Code Workspace](https://code.visualstudio.com/docs/editor/workspaces)
