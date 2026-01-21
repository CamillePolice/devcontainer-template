# 🐳 DevContainer Configuration

> A consistent, reproducible development environment for seamless team collaboration

[![Docker](https://img.shields.io/badge/Docker-enabled-2496ED?style=flat-square&logo=docker)](https://docker.com)
[![Node.js](https://img.shields.io/badge/Node.js-LTS-339933?style=flat-square&logo=node.js)](https://nodejs.org)
[![Python](https://img.shields.io/badge/Python-3.14-3776AB?style=flat-square&logo=python)](https://python.org)
[![Oh My Zsh](https://img.shields.io/badge/Oh_My_Zsh-enabled-1A2C34?style=flat-square&logo=zsh)](https://ohmyz.sh)
[![Starship](https://img.shields.io/badge/Starship-prompt-DD0B78?style=flat-square&logo=starship)](https://starship.rs)
[![Claude Code](https://img.shields.io/badge/Claude_Code-enabled-D97757?style=flat-square&logo=anthropic)](https://claude.ai)
[![VS Code](https://img.shields.io/badge/VS_Code-optimized-007ACC?style=flat-square&logo=visual-studio-code)](https://code.visualstudio.com)

---

## 🚀 Quick Start

### Prerequisites

- 🐳 [Docker Desktop](https://www.docker.com/products/docker-desktop)
- 💻 [VS Code](https://code.visualstudio.com/) with [Remote Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- 🔧 Git

### Get Started in 3 Steps

1. **Clone & Open**

   ```bash
   git clone <repository-url>
   cd project
   code .
   ```

2. **Launch Container**

   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
   - Select **"Dev Containers: Reopen in Container"**
   - ☕ Grab coffee while it builds (first time only)

3. **Start Developing**

   ```bash
   # All services start automatically!
   # Check the terminal for service URLs
   ```

---

## 📁 Structure

```
.devcontainer/
├── 📄 devcontainer.json      # Main configuration file
├── 🐳 Dockerfile             # Container image definition
├── 📖 README.md              # This documentation
├── 🔧 bin/                   # Binary tools (php-cs-fixer, etc.)
├── 📋 linter-conf/           # Linter configuration files
└── 📜 scripts/               # Initialization and utility scripts
    ├── post_create.sh        # Runs once after container creation
    ├── init_env.sh           # Runs on every container start
    ├── start_docker.sh       # Starts Docker Compose services
    ├── configure_git_prompt.sh   # Oh My Zsh + Starship prompt setup
    ├── install_cli_tools.sh      # Modern CLI tools (fzf, ripgrep, etc.)
    └── docker_autocomplete.sh    # Docker bash/zsh completion
```

---

## ✨ Features

### 🖼️ Base Image

| Component | Version | Description |
|-----------|---------|-------------|
| 📦 **Node.js** | LTS | JavaScript runtime |
| 🐍 **Python** | 3.14.2 | Python interpreter |
| 🔧 **Git** | Latest | Version control |

### 🌍 Environment Variables

| Variable | Description |
|----------|-------------|
| `PROJECT_ROOT` | Workspace folder path inside container |
| `DEVCONTAINER_SCRIPTS` | Path to `.devcontainer/scripts/` |
| `REMOTE_CONTAINERS` | Set to `true` when running in devcontainer |
| `DEVCONTAINER` | Set to `true` when running in devcontainer |
| `TZ` | Timezone (Europe/Paris) |

### 🔌 Forwarded Ports

| Port | Label | Behavior |
|------|-------|----------|
| 🌐 `8080` | Application | Notify on auto-forward |
| ⚙️ `8081` | Service | Silent auto-forward |

### 💾 Mounted Volumes

| Mount | Source | Target | Purpose |
|-------|--------|--------|---------|
| 🔑 **SSH Keys** | `~/.ssh` | `/home/vscode/.sshhost/` | Git authentication |
| 📜 **History** | Docker volume | `/commandhistory` | Persistent command history |

---

## 🔄 Lifecycle Scripts

### 📦 `post_create.sh` (runs once)

> Executed after the container is created for the first time

- ✅ Sets up SSH keys from host
- ✅ Configures command history persistence
- ✅ Installs Oh My Zsh with Starship prompt
- ✅ Installs modern CLI tools
- ✅ Installs Angular CLI and build tools
- ✅ Builds Docker base images
- ✅ Generates SSL keys

### ⚡ `init_env.sh` (runs on every start)

> Executed every time the container starts

- ✅ Copies SSH keys from host mount
- ✅ Configures git settings (rebase, editor, auto-push)
- ✅ Installs pre-commit hooks
- ✅ Configures git prompt and CLI tools
- ✅ Sets up Docker autocomplete
- ✅ Installs Angular CLI

### 🐳 `start_docker.sh`

> Starts Docker Compose services after initialization is complete

---

## 🛠️ Installed Tools

### 🎨 Shell Environment

| Tool | Description |
|------|-------------|
| **Oh My Zsh** | Enhanced shell framework |
| **Starship** | Fast, customizable, cross-shell prompt (written in Rust) |
| **Plugins** | git, docker, docker-compose, node, npm, zsh-autosuggestions, zsh-syntax-highlighting |

#### 🚀 Starship Prompt

Starship provides a minimal, fast, and customizable prompt that shows:

- 📁 Current directory (smart truncation)
- 🌿 Git branch and status (ahead/behind, modified, staged, untracked)
- 🐳 Docker context (when relevant)
- 💻 Language versions (Node.js, PHP, Python, Go, Rust) - only when in project
- ⏱️ Command execution time (for commands > 500ms)
- ❌ Error status on command failure

**Configuration**: `~/.config/starship.toml`

**Useful commands**:
```bash
starship explain    # Show what each prompt segment means
starship timings    # Show how long each module takes to render
```

### ⚡ Modern CLI Tools

| Tool | Description | Alias |
|------|-------------|-------|
| 📂 `eza` | Modern ls replacement with git integration | `ls` → `eza` |
| 🔍 `fzf` | Fuzzy finder | - |
| 🔎 `ripgrep` | Fast grep replacement | `rgrep` → `rg` |
| 🦇 `bat` | Better cat with syntax highlighting | `cat` → `bat` |
| 📁 `fd-find` | Better find replacement | `ffind` → `fd` |
| 🚀 `zoxide` | Smart directory jumping | `cd` → `z` |
| 🌐 `httpie` | Modern HTTP client | `http` |
| 📖 `tldr` | Simplified man pages | `help` |

### ⌨️ Aliases

#### 📂 File Listing (eza)

```bash
ls    → eza                    # Modern ls with colors
ll    → eza -lah --git         # Long listing with git status
lt    → eza --tree --level=2   # Tree view (2 levels)
```

#### 🔀 Git Shortcuts

```bash
gs    → git status
gd    → git diff
gl    → git log --oneline --graph --decorate
ga    → git add
gc    → git commit
gp    → git push
gco   → git checkout
gb    → git branch
```

#### 🐳 Docker Shortcuts

```bash
dps   → docker ps
dpa   → docker ps -a
di    → docker images
dex   → docker exec -it
dc    → docker-compose
dcu   → docker-compose up
dcd   → docker-compose down
dcb   → docker-compose build
dcl   → docker-compose logs
```

---

## 🧩 VS Code Extensions

Extensions are automatically installed when opening the container:

### 🤖 AI & Productivity

| Extension | Description |
|-----------|-------------|
| **Claude Code** | Official Anthropic AI coding assistant |

### ✨ Code Quality

| Extension | Description |
|-----------|-------------|
| Prettier | Code formatter |
| ESLint | JavaScript linter |
| EditorConfig | Consistent coding styles |
| Code Spell Checker | Spelling checker |

### 🔀 Git

| Extension | Description |
|-----------|-------------|
| GitLens | Git supercharged |
| Git Graph | Visual git history |

### 🐳 Docker & DevOps

| Extension | Description |
|-----------|-------------|
| Docker | Container management |
| Remote Containers | Dev container support |
| Remote SSH | SSH development |

### 🔧 Utilities

| Extension | Description |
|-----------|-------------|
| Path Intellisense | Autocomplete paths |
| Auto Rename Tag | Sync HTML/XML tags |
| Todo Tree | Track TODO comments |
| Better Comments | Annotated comments |
| Error Lens | Inline error display |
| Material Icon Theme | File icons |

### 📝 Documentation

| Extension | Description |
|-----------|-------------|
| Markdown All in One | Markdown toolkit |
| Markdown Mermaid | Diagram support |
| YAML | YAML language support |
| REST Client | API testing |

### 📦 Extension Installation by Stack

> Install extensions based on your project's tech stack automatically

The `install_by_stack.sh` script provides smart, stack-based extension installation:

```bash
# Run from project root
.vscode/extensions/install_by_stack.sh [stack1] [stack2] ...
```

#### Available Stacks

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

#### Usage Examples

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

#### Features

- ✅ **Automatic detection**: Detects project type from config files
- ✅ **Skip installed**: Won't reinstall already present extensions
- ✅ **Progress tracking**: Shows installation progress with colors
- ✅ **Summary report**: Displays installed/skipped/failed counts

---

## 🤖 AI Agent Skills

> Enhance your AI coding assistants with reusable capabilities from [Skills.sh](https://skills.sh)

Skills are reusable capabilities for AI agents that provide procedural knowledge and best practices. They work with **Cursor**, GitHub Copilot, Claude Code, and many other AI assistants.

### 🚀 Installation

Install skills with a single command:

```bash
npx skills add <owner/repo>
```

### ⭐ Recommended Skills

#### 🎨 Frontend Development

| Skill | Command | Description |
|-------|---------|-------------|
| **React Best Practices** | `npx skills add vercel-labs/agent-skills` | Vercel's React patterns and conventions |
| **Web Design Guidelines** | `npx skills add vercel-labs/agent-skills` | Modern web design principles |
| **Tailwind Setup** | `npx skills add expo/skills` | Tailwind CSS configuration |
| **UI/UX Pro Max** | `npx skills add nextlevelbuilder/ui-ux-pro-max-skill` | Advanced UI/UX patterns |

#### 🔧 Backend & APIs

| Skill | Command | Description |
|-------|---------|-------------|
| **Better Auth** | `npx skills add better-auth/skills` | Authentication best practices |
| **NestJS** | `npx skills add Kadajett/agent-nestjs-skills` | NestJS patterns and conventions |
| **Stripe Integration** | `npx skills add anthropics/claude-plugins-official` | Payment integration patterns |

#### 🧪 Testing & Quality

| Skill | Command | Description |
|-------|---------|-------------|
| **Test-Driven Development** | `npx skills add obra/superpowers` | TDD methodology |
| **Webapp Testing** | `npx skills add anthropics/skills` | Web application testing |
| **Systematic Debugging** | `npx skills add obra/superpowers` | Debugging methodologies |

#### 📝 Documentation & Workflow

| Skill | Command | Description |
|-------|---------|-------------|
| **Skill Creator** | `npx skills add anthropics/skills` | Create your own skills |
| **PDF Generation** | `npx skills add anthropics/skills` | PDF document handling |
| **Doc Co-authoring** | `npx skills add anthropics/skills` | Collaborative documentation |

#### 🚀 DevOps & Deployment

| Skill | Command | Description |
|-------|---------|-------------|
| **CI/CD Workflows** | `npx skills add expo/skills` | CI/CD pipeline patterns |
| **Deployment** | `npx skills add expo/skills` | Deployment strategies |

### 💡 Usage Examples

```bash
# Install React best practices for your project
npx skills add vercel-labs/agent-skills

# Install testing superpowers
npx skills add obra/superpowers

# Install authentication patterns
npx skills add better-auth/skills
```

### 🎯 Compatible Agents

Skills work with these AI coding assistants:

| Agent | Support | Note |
|-------|---------|------|
| 🧠 **Claude Code** | ✅ Full support | **Primary agent** |
| 🖱️ **Cursor** | ✅ Full support | |
| 🤖 **GitHub Copilot** | ✅ Full support | |
| 💎 **Gemini** | ✅ Full support | |
| 🌊 **Windsurf** | ✅ Full support | |
| 🦆 **Goose** | ✅ Full support | |

### 📚 More Information

- 🌐 **Website**: [skills.sh](https://skills.sh)
- 📖 **Documentation**: [skills.sh/docs](https://skills.sh)
- 🏆 **Leaderboard**: Browse trending skills on the homepage

---

## 📂 `.vscode` Folder

The `.vscode` folder contains VS Code workspace configuration:

```
.vscode/
├── 📁 config/
│   ├── tasks.json              # Build and utility tasks
│   └── launch.json.example     # Debug configurations template
├── 📁 extensions/              # Extension management by stack
│   ├── install_by_stack.sh     # Stack-based extension installer
│   ├── extensions.json         # Base extensions
│   ├── angular/extensions.json # Angular-specific extensions
│   ├── symfony/extensions.json # Symfony/PHP extensions
│   └── go/extensions.json      # Go extensions
├── 📁 git/
│   └── .pre-commit-config.yaml.example
├── 📁 linting/                 # Linter configurations
├── 📁 profiles/                # VS Code profiles
│   ├── CamilleP (Dark).code-profile
│   └── CamilleP (Light).code-profile
└── 📄 extensions.json          # Recommended extensions
```

### ⚡ Tasks (`tasks.json`)

| Task | Description | Trigger |
|------|-------------|---------|
| 🔧 **Init env** | Initialize environment | On folder open |
| 🐳 **Start docker** | Start Docker services | On folder open (after Init env) |
| 🧹 **Clean Zone.Identifier** | Remove Windows WSL artifacts | Manual |

### 🐛 Debug Configurations (`launch.json.example`)

Pre-configured debug profiles for:

| Configuration | Description |
|---------------|-------------|
| 🔧 **Xdebug (Main API)** | PHP debugging on port 9003 |
| 🔧 **Xdebug (Historic API)** | PHP debugging on port 9004 |
| 🌐 **Chrome/Edge/Firefox** | Frontend debugging |
| 🧪 **Angular Tests** | Test debugging |
| 🎯 **Full Stack** | Combined debugging |

---

## 📋 Pre-commit Hooks

> Automated code quality checks that run before each commit

### 🚀 Setup

1. **Copy the example configuration**

   ```bash
   cp .vscode/git/.pre-commit-config.yaml.example .pre-commit-config.yaml
   ```

2. **Install pre-commit** (automatically done by `init_env.sh`)

   ```bash
   pip install pre-commit
   pre-commit install
   ```

3. **Install commit-msg hook** (for commit message validation)

   ```bash
   pre-commit install --hook-type commit-msg
   ```

### 🔧 Available Hooks

#### 🐘 PHP Backend (Main API)

| Hook | Stage | Description |
|------|-------|-------------|
| 🔍 `phpstan-main` | pre-commit | Static analysis with PHPStan |
| 🎨 `php-cs-fixer-main` | pre-commit | Code style fixing |
| 🚀 `rector-fix-main` | pre-commit | Code modernization |
| ✅ `phpstan-validate-main` | pre-commit | Final PHPStan validation |

#### 📊 PHP Backend (Historic API)

| Hook | Stage | Description |
|------|-------|-------------|
| 🔍 `phpstan-historic` | pre-commit | Static analysis with PHPStan |
| 🎨 `php-cs-fixer-historic` | pre-commit | Code style fixing |
| 🚀 `rector-fix-historic` | pre-commit | Code modernization |
| ✅ `phpstan-validate-historic` | pre-commit | Final PHPStan validation |

#### 🎨 Angular Frontend

| Hook | Stage | Description |
|------|-------|-------------|
| 🔧 `eslint-angular` | pre-commit | ESLint with auto-fix |
| 🎨 `prettier-angular` | pre-commit | Code formatting |
| 🏗️ `ng-build-check` | pre-commit | Angular build verification |
| 📝 `tsc-angular` | pre-commit | TypeScript type checking |

#### ✅ Validation Hooks

| Hook | Stage | Description |
|------|-------|-------------|
| 📝 `commit-msg-format` | commit-msg | Validates commit message format |
| 🌿 `branch-name-format` | pre-commit | Validates branch naming convention |

### 📝 Commit Message Format

Valid formats:

```bash
# Standard format
OPV-[task_number]([commit_type]): message

# With ticket reference
OPV-[task_number]_Ticket-[ticket_number]([commit_type]): message

# Version release
Version [X.X.X]

# Merge commits
Merge branch 'opv_[task]-[desc]' into opv_[task]-[desc]
```

**Examples:**

```bash
OPV-123(feat): add new login feature
OPV-456(fix): resolve authentication bug
OPV-123_Ticket-789(feat): add new login feature
Version [1.2.3]
```

**Commit types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### 🌿 Branch Naming Convention

Valid formats:

```bash
# Standard format
opv_[task_number]-[description]

# With ticket reference
opv_[task_number]-ticket_[ticket_number]-[description]

# Protected branches
main, master, develop, staging
```

**Examples:**

```bash
opv_123-user_authentication
opv_123-ticket_456-login_page
opv_789-fix-login-bug
```

### ⚡ Smart Execution

All hooks include **smart file detection**:

- ✅ Only run when relevant files are changed
- ✅ Skip automatically if project not found
- ✅ Skip if dependencies not installed
- ✅ Auto-fix issues when possible

**Example output:**

```
🔍 Running PHPStan static analysis (Main API)...
ℹ️  No Main API project files changed - skipping PHPStan

🔧 Running ESLint (Angular)...
🔧 Attempting to fix ESLint issues automatically...
✅ ESLint passed (Angular)!
```

### 🔄 Manual Execution

```bash
# Run all hooks on all files
pre-commit run --all-files

# Run specific hook
pre-commit run phpstan-main --all-files

# Run only on staged files
pre-commit run

# Skip hooks temporarily (use with caution!)
git commit --no-verify -m "OPV-123(wip): work in progress"
```

---

## ⚙️ Customization

### 🌍 Adding Environment Variables

Edit `containerEnv` in `devcontainer.json`:

```json
"containerEnv": {
    "MY_VARIABLE": "value"
}
```

### 🧩 Adding VS Code Extensions

Add extension IDs to the `extensions` array in `devcontainer.json`.

### 🐳 Modifying the Container Image

Edit the `Dockerfile` and rebuild the container.

### 📜 Adding Initialization Steps

Modify `post_create.sh` (one-time setup) or `init_env.sh` (every start).

---

## 🆘 Troubleshooting

### 🐳 Container won't start

1. Check Docker is running
2. Try rebuilding: `Ctrl+Shift+P` → **"Dev Containers: Rebuild Container"**

### 🔑 SSH keys not working

1. Ensure `~/.ssh` exists on host
2. Check permissions: `chmod 600 ~/.ssh/*`

### 🧩 Extensions not installing

1. Rebuild the container
2. Check extension IDs are correct in `devcontainer.json`

### 📜 Scripts failing

Check logs in `/tmp/`:

| Log File | Script |
|----------|--------|
| `/tmp/project_init.log` | post_create.sh |
| `/tmp/project_init_env.log` | init_env.sh |
| `/tmp/project_docker_startup.log` | start_docker.sh |

---

## 🎯 Key Benefits

### 🔒 Consistent Environment

- Same setup across all team members
- No more "works on my machine" issues
- Isolated from host system

### ⚡ Blazing Fast Development

- Hot reload for all services
- Optimized Docker layers
- Cached dependencies

### 🎨 Developer Experience

- Rich VS Code integration
- Intelligent autocomplete
- Integrated debugging tools
- Modern shell with beautiful prompt

---

**Happy coding! 🎉**
