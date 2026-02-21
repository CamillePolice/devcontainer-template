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

2. **Configure Your Environment**

   - Review environment variables in `devcontainer.json`:
     - Set `PROJECT_NAME` to your project name
     - Toggle features (`USE_CLAUDE_CODE`, `USE_GIT_PROMPT`, etc.)
     - See [Environment Variables](scripts/docs/environment-variables.md) for details

   - Create project-specific configurations (optional):
     ```bash
     # Copy example files to create your own configs
     cp .devcontainer/.vscode/config/launch.json.example .devcontainer/.vscode/config/launch.json
     cp .devcontainer/.vscode/git/.pre-commit-config.yaml.example .devcontainer/.vscode/git/.pre-commit-config.yaml
     ```

   - Configure RAG (optional, for AI-powered agents):
     ```bash
     # Add to your host ~/.zshrc
     export RAG_DSN="postgresql://postgres.[ref]:[password]@aws-1-eu-west-1.pooler.supabase.com:6543/postgres"

     # Create local env file (gitignored)
     cp .devcontainer/.env.example .devcontainer/.env
     # Edit .env: set USE_RAG=true, RAG_PROJECT=your-project
     ```

3. **Launch Container**

   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
   - Select **"Dev Containers: Reopen in Container"**
   - ☕ Grab coffee while it builds (first time only)

4. **Start Developing**

   ```bash
   # All services start automatically!
   # Check the terminal for service URLs
   ```

5. **Customize CLAUDE.md** (Optional but Recommended)

   After container creation, a `CLAUDE.md` template is automatically created at your project root. Customize it with your project details to help Claude Code understand your codebase better:

   ```bash
   # Edit CLAUDE.md with your project information
   vim CLAUDE.md
   ```

   This file serves as both documentation and context for Claude Code.

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
    ├── lifecycle/            # Container lifecycle hooks
    │   ├── post_create.sh        # Runs once after container creation
    │   ├── init_env.sh           # Runs on every container start
    │   └── start_docker.sh       # Starts Docker Compose services
    ├── setup/                # One-time setup scripts
    │   ├── install_claude_code.sh    # Claude Code CLI installation
    │   ├── configure_claude.sh       # Claude Code configuration
    │   ├── configure_git_prompt.sh   # Oh My Zsh + Starship setup
    │   └── install_cli_tools.sh      # Modern CLI tools installation
    ├── ai/                   # AI & RAG scripts
    │   ├── setup_rag.sh          # Supabase connection check (runs at init)
    │   └── seed_rag.py           # Generic knowledge indexing script
    ├── config/               # Configuration scripts
    │   └── docker_autocomplete.sh    # Docker bash/zsh completion
    ├── tests/                # Test scripts
    ├── docs/                 # Script documentation
    └── INDEX.md              # Scripts quick reference
```

> 📚 **Scripts Documentation**: See [scripts/INDEX.md](scripts/INDEX.md) for detailed script documentation and [scripts/docs/](scripts/docs/) for specific guides.

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
| `USE_CLAUDE_CODE` | Enable Claude Code integration (`true`/`false`) |
| `USE_CLAUDE` | Enable Claude Code direct repository copy (`true`/`false`) |
| `USE_CLAUDE_MARKETPLACE` | Enable Claude Code plugin marketplace (`true`/`false`) |
| `USE_GIT_PROMPT` | Enable Oh My Zsh + Starship prompt (`true`/`false`) |
| `USE_DOCKER_AUTOCOMPLETE` | Enable Docker autocomplete (`true`/`false`) |
| `USE_RAG` | Enable RAG-First agents via Supabase (`true`/`false`) |
| `RAG_DSN` | Supabase connection string (set on host, never in repo) |
| `RAG_PROJECT` | Project scope for RAG indexing (e.g. `opvigil`, `global`) |

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
- ✅ Configures Claude Code (if enabled)
- ✅ Verifies Supabase RAG connection (if `USE_RAG=true`)

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

## 🤖 RAG-First AI Agents

This devcontainer supports **RAG-First agents**: lightweight Claude Code agent files (~30 lines) that load their detailed knowledge from Supabase at runtime. This reduces token consumption by ~70% while keeping agent knowledge persistent and cross-project.

### How It Works

```
.claude/agents/angular-expert.md  (~30 lines)
    └── psql "$RAG_DSN" → Supabase ──► sections loaded on demand
                                        (signals, standalone, Bootstrap 5...)

capture-learning skill → auto-captures discoveries during tasks
    └── project='global'    → shared across ALL projects
    └── project='opvigil'   → scoped to current project only
```

### Setup

```bash
# 1. Add to host ~/.zshrc
export RAG_DSN="postgresql://..."

# 2. Configure .devcontainer/.env
USE_RAG=true
RAG_PROJECT=opvigil

# 3. Index knowledge for your agents (run once, then after updates)
RAG_PROJECT="global" python3 .devcontainer/scripts/ai/seed_rag.py \
  --file angular-expert-rag.md --agent angular-expert

# 4. Check what's indexed
psql "$RAG_DSN" -c "SELECT * FROM rag_audit;"
```

### Available Agents

| Agent | Project | Sections | Knowledge |
|-------|---------|----------|-----------|
| `angular-expert` | global | 16 | Angular 20, signals, standalone, Bootstrap 5, HttpWrapper |
| `symfony-expert` | global | 7 | Symfony 7, PHP 8.3, strict types, test migration |
| `archforge` | archforge | 197 | Full upgrade automation procedure |

> 📚 See [docs/rag.md](docs/rag.md) for complete RAG documentation.

---

## 📜 Scripts Organization

The devcontainer uses an organized script structure for better maintainability. All scripts are located in `.devcontainer/scripts/` with the following organization:

### Directory Structure

```
scripts/
├── lifecycle/           # Container lifecycle hooks
│   ├── post_create.sh       # One-time setup (container creation)
│   ├── init_env.sh          # Environment refresh (every start)
│   └── start_docker.sh      # Docker Compose startup
│
├── setup/               # One-time setup scripts
│   ├── install_claude_code.sh   # Claude Code CLI installation
│   ├── configure_claude.sh      # Claude Code configuration
│   ├── configure_git_prompt.sh  # Oh My Zsh + Starship setup
│   ├── configure_vscode.sh      # VS Code environment setup
│   └── install_cli_tools.sh     # Modern CLI tools installation
│
├── ai/                  # AI & RAG scripts
│   ├── setup_rag.sh         # Supabase connection check
│   └── seed_rag.py          # Generic knowledge indexing (any project)
│
├── config/              # Configuration scripts
│   └── docker_autocomplete.sh   # Docker bash/zsh completion
│
├── tests/               # Test scripts
├── docs/                # Detailed documentation
└── INDEX.md             # Quick reference guide
```

### Script Control Variables

All scripts can be individually controlled via environment variables in `devcontainer.json`:

| Variable | Controls | Default |
|----------|----------|---------|
| `USE_CLAUDE_CODE` | Master toggle for Claude Code CLI installation and integration | `true` |
| `CLAUDE_CODE_CHANNEL` | Claude Code release channel or version (`latest`, `stable`, or version number) | `latest` |
| `USE_CLAUDE` | Direct repository copy to `.claude/` folder | `true` |
| `USE_CLAUDE_MARKETPLACE` | Plugin marketplace setup in `~/.claude/settings.json` | `true` |
| `USE_GIT_PROMPT` | Oh My Zsh and Starship prompt installation | `true` |
| `USE_DOCKER_AUTOCOMPLETE` | Docker and Docker Compose autocomplete | `true` |
| `USE_VSCODE_CONFIG` | VS Code settings, tasks, extensions configuration | `true` |
| `USE_RAG` | RAG-First agents via Supabase | `false` |

### Log Files

All scripts log their output to `.devcontainer/.log/` for troubleshooting:

| Script | Log File |
|--------|----------|
| `post_create.sh` | `.devcontainer/.log/project_init.log` |
| `init_env.sh` | `.devcontainer/.log/project_init_env.log` |
| `start_docker.sh` | `.devcontainer/.log/project_docker_startup.log` |
| `install_claude_code.sh` | `.devcontainer/.log/claude_code_install.log` |
| `configure_claude.sh` | `.devcontainer/.log/claude_config.log` |
| `configure_vscode.sh` | `.devcontainer/.log/vscode_config.log` |
| `configure_git_prompt.sh` | `.devcontainer/.log/configure_git_prompt.log` |
| `install_cli_tools.sh` | `.devcontainer/.log/cli_tools_install.log` |
| `docker_autocomplete.sh` | `.devcontainer/.log/docker_autocomplete.log` |
| `setup_rag.sh` | `.devcontainer/.log/rag_setup.log` |

### Manual Execution

Scripts can be run manually when needed:

```bash
# Re-initialize environment
.devcontainer/scripts/lifecycle/init_env.sh

# Re-configure Claude Code
.devcontainer/scripts/setup/configure_claude.sh

# Verify RAG connection
.devcontainer/scripts/ai/setup_rag.sh

# Reindex knowledge after changes
RAG_PROJECT="opvigil" python3 .devcontainer/scripts/ai/seed_rag.py \
  --dir . --agent my-agent --force

# With environment variables
USE_CLAUDE=true .devcontainer/scripts/setup/configure_claude.sh
```

### Testing Installation

Verify your devcontainer setup with the automated test suite:

```bash
# Full test suite (recommended)
bash .devcontainer/scripts/tests/run_tests.sh

# Quick health check
bash .devcontainer/scripts/tests/quick_test.sh
```

**Test Results:**
- ✓ **Pass** - Feature installed and working
- ✗ **Fail** - Feature expected but not found
- ⊘ **Skip** - Feature disabled (intentional)
- ⚠ **Warn** - Optional or non-critical issue

See **[Test Suite Documentation](scripts/tests/README.md)** for details.

### Documentation

- **[scripts/INDEX.md](scripts/INDEX.md)** - Quick reference guide
- **[scripts/docs/](scripts/docs/)** - Detailed documentation for specific scripts
- **[scripts/tests/](scripts/tests/)** - Test suite documentation

---

## 📚 Additional Documentation

For detailed information on specific topics, see:

- **[Installed Tools](docs/installed-tools.md)** - Shell environment, CLI tools, and aliases
- **[VS Code Extensions](docs/vscode-extensions.md)** - Extensions and stack-based installation
- **[AI Agent Skills](docs/ai-skills.md)** - Enhance your AI coding assistants
- **[Claude Code Configuration](docs/claude-code.md)** - Comprehensive Claude Code setup
- **[RAG-First Agents](docs/rag.md)** - Supabase knowledge base for AI agents
- **[VS Code Configuration](docs/vscode-config.md)** - Tasks, debug configs, and profiles
- **[Pre-commit Hooks](docs/pre-commit-hooks.md)** - Automated code quality checks
- **[Customization](docs/customization.md)** - Customize your devcontainer
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

**Script-Specific Documentation:**

- **[Claude Code CLI Installation](scripts/docs/install-claude-code.md)** - Installing and configuring Claude Code CLI
- **[VS Code Configuration Script](scripts/docs/configure-vscode.md)** - Detailed workflow for launch.json and pre-commit configs
- **[Environment Variables](scripts/docs/environment-variables.md)** - Complete variable reference
- **[Script Best Practices](scripts/docs/best-practices.md)** - Script development guidelines

---

**Happy coding! 🎉**
