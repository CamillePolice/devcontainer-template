# VS Code Extensions

Automatically installed extensions for enhanced development experience.

## 🤖 AI & Productivity

| Extension | Description |
|-----------|-------------|
| **Claude Code** | Official Anthropic AI coding assistant |

## ✨ Code Quality

| Extension | Description |
|-----------|-------------|
| **Prettier** | Code formatter |
| **ESLint** | JavaScript linter |
| **EditorConfig** | Consistent coding styles |
| **Code Spell Checker** | Spelling checker |

## 🔀 Git

| Extension | Description |
|-----------|-------------|
| **GitLens** | Git supercharged |
| **Git Graph** | Visual git history |

## 🐳 Docker & DevOps

| Extension | Description |
|-----------|-------------|
| **Docker** | Container management |
| **Remote Containers** | Dev container support |
| **Remote SSH** | SSH development |

## 🔧 Utilities

| Extension | Description |
|-----------|-------------|
| **Path Intellisense** | Autocomplete paths |
| **Auto Rename Tag** | Sync HTML/XML tags |
| **Todo Tree** | Track TODO comments |
| **Better Comments** | Annotated comments |
| **Error Lens** | Inline error display |
| **Material Icon Theme** | File icons |

## 📝 Documentation

| Extension | Description |
|-----------|-------------|
| **Markdown All in One** | Markdown toolkit |
| **Markdown Mermaid** | Diagram support |
| **YAML** | YAML language support |
| **REST Client** | API testing |

---

## 📦 Extension Installation by Stack

Install extensions based on your project's tech stack automatically.

### Usage

```bash
# Run from project root
.vscode/extensions/install_by_stack.sh [stack1] [stack2] ...
```

### Available Stacks

| Stack | Description | Detection |
|-------|-------------|-----------|
| `base` | Base extensions (always included) | Always |
| `angular` | Angular development extensions | `angular.json` |
| `vue` | Vue.js development extensions | `vue.config.js` or package.json |
| `react` | React development extensions | package.json (no Next.js) |
| `nextjs` | Next.js development extensions | `next.config.js` |
| `symfony` | Symfony/PHP development extensions | `symfony.lock` or `composer.json` |
| `go` | Go development extensions | `go.mod` |
| `all` | All available extensions | Manual |

### Examples

```bash
# Automatic detection (recommended)
.vscode/extensions/install_by_stack.sh

# Install specific stacks
.vscode/extensions/install_by_stack.sh angular symfony

# Install all extensions
.vscode/extensions/install_by_stack.sh all

# Show help
.vscode/extensions/install_by_stack.sh --help
```

### Features

- ✅ **Automatic detection** - Detects project type from config files
- ✅ **Skip installed** - Won't reinstall already present extensions
- ✅ **Progress tracking** - Shows installation progress with colors
- ✅ **Summary report** - Displays installed/skipped/failed counts

---

## 🔧 Manual Installation

To manually install an extension:

1. Open VS Code Command Palette (`Ctrl+Shift+P` or `Cmd+Shift+P`)
2. Select **"Extensions: Install Extensions"**
3. Search for the extension name
4. Click **Install**

Or via command line:
```bash
code --install-extension extension-id
```
