# DevContainer Template

> A production-ready VS Code DevContainer template for consistent development environments

[![Docker](https://img.shields.io/badge/Docker-enabled-2496ED?style=flat-square&logo=docker)](https://docker.com)
[![Node.js](https://img.shields.io/badge/Node.js-LTS-339933?style=flat-square&logo=node.js)](https://nodejs.org)
[![Python](https://img.shields.io/badge/Python-3.14-3776AB?style=flat-square&logo=python)](https://python.org)
[![Oh My Zsh](https://img.shields.io/badge/Oh_My_Zsh-enabled-1A2C34?style=flat-square&logo=zsh)](https://ohmyz.sh)
[![Starship](https://img.shields.io/badge/Starship-prompt-DD0B78?style=flat-square&logo=starship)](https://starship.rs)
[![Claude Code](https://img.shields.io/badge/Claude_Code-enabled-D97757?style=flat-square&logo=anthropic)](https://claude.ai)
[![VS Code](https://img.shields.io/badge/VS_Code-optimized-007ACC?style=flat-square&logo=visual-studio-code)](https://code.visualstudio.com)
[![tmux](https://img.shields.io/badge/tmux-enabled-1BB91F?style=flat-square&logo=tmux)](https://github.com/tmux/tmux)

## 📦 Repositories

| Repository | Purpose |
|------------|---------|
| **This repo** (devcontainer-template) | DevContainer, Dockerfile, VS Code config, lifecycle scripts |
| **[host-template](https://github.com/CamillePolice/host-template)** | Host machine setup: terminal (zsh, Starship, tmux), CLI tools, editor config, optional Claude Code & RAG |

The `host/` directory is excluded from this repo (see `.gitignore`). Clone host-template where you need it (e.g. `~/dev-setup` or `./host`).

## 📦 Installation

### DevContainer (inside the container)

The devcontainer configures the environment **when you open the project in a container**. No manual steps required beyond opening the project.

1. **Clone and open in VS Code or Cursor**
   ```bash
   git clone <your-repo>
   cd your-project
   code .   # or: cursor .
   ```

2. **Optional:** set variables in `.devcontainer/.env` or `devcontainer.json` (e.g. `PROJECT_NAME`, `USE_GIT_PROMPT`, `USE_CLAUDE_CODE`).

3. **Reopen in container**  
   Command Palette → **Dev Containers: Reopen in Container**.

4. **First run:** post-create scripts install automatically (zsh, Oh My Zsh, Starship, tmux, Claude Code, VS Code settings, etc.).  
   Optional check: `bash .devcontainer/scripts/tests/run_tests.sh`.

**What you get in the container:** Zsh + Oh My Zsh + Starship, tmux (TPM, Catppuccin), Node/npm, Claude Code CLI, [rtk](https://github.com/rtk-ai/rtk) (LLM token optimizer), VS Code settings and extensions, Docker autocomplete, Git prompt.

### Host (your machine, outside the container)

The **host setup** is in a **separate repository** so you can use it independently (e.g. on multiple machines or outside any devcontainer project):

- **Repository:** [github.com/CamillePolice/host-template](https://github.com/CamillePolice/host-template)
- Same tooling as in the container: zsh, Starship, tmux, CLI tools, optional Claude Code and editor config.

1. **Clone the host-template repo** where you want (e.g. `~/dev-setup` or `./host` next to this project):
   ```bash
   git clone git@github.com:CamillePolice/host-template.git ~/dev-setup
   # or: git clone git@github.com:CamillePolice/host-template.git host
   ```

2. **Configure (optional)**  
   Copy `host-template/.env.example` to `.env` in that folder and set options (`USE_GIT_PROMPT`, `USE_TMUX`, `USE_CLAUDE_CODE`, etc.).

3. **Run setup**
   - **Full setup** (terminal + CLI tools + Claude Code + editor config + optional RAG/Ollama):  
     ```bash
     cd ~/dev-setup   # or: cd host
     ./run_post_create.sh
     ```
   - **Terminal only** (zsh, Oh My Zsh, Starship, tmux, fzf/ripgrep/bat/eza/zoxide/tldr):  
     ```bash
     ./run_terminal_setup.sh
     ```

4. **Optional session init** (after a fresh clone or to refresh git/pre-commit):  
   `./run_init_env.sh`

Details, env vars and layout: **[host-template README](https://github.com/CamillePolice/host-template)**.

## 🚀 Quick Start (DevContainer)

```bash
git clone <your-repo> && cd your-project && code .
# Ctrl+Shift+P → "Dev Containers: Reopen in Container"
# Wait for first-time setup, then start coding.
```

## ✨ Features

- ✅ **Automated Setup** - Claude Code CLI, VS Code settings, Git prompt, CLI tools, rtk (token optimizer)
- ✅ **Customizable** - Toggle features via environment variables
- ✅ **Claude Code Integration** - Auto-generates CLAUDE.md for project context
- ✅ **Modern Shell** - Oh My Zsh + Starship prompt with Git integration
- ✅ **VS Code Optimized** - Pre-configured settings, tasks, and extensions
- ✅ **Stack Support** - Extension packs for Angular, React, Next.js, Vue, Symfony, Go
- ✅ **Code Quality** - EditorConfig, Prettier, pre-commit hooks support
- ✅ **Test Suite** - Automated verification of installation
- ✅ **Documentation** - Comprehensive guides for all features

## 📚 Documentation

| Scope | Doc |
|-------|-----|
| **DevContainer** (structure, features, scripts) | [.devcontainer/README.md](.devcontainer/README.md) |
| **Host** (machine setup, terminal, editors) | [host-template](https://github.com/CamillePolice/host-template) |

**DevContainer quick links:**
- [Environment Variables](.devcontainer/scripts/docs/environment-variables.md)
- [Claude Code Installation](.devcontainer/scripts/docs/install-claude-code.md)
- [VS Code Configuration](.devcontainer/scripts/docs/configure-vscode.md)
- [Tmux](.devcontainer/docs/tmux.md)
- [rtk (Rust Token Killer)](.devcontainer/docs/rtk.md)
- [Test Suite](.devcontainer/scripts/tests/README.md)
- [Troubleshooting](.devcontainer/docs/troubleshooting.md)

## 🎯 What Gets Configured (DevContainer)

| Feature | Enabled by Default | Environment Variable |
|---------|-------------------|---------------------|
| Zsh + Oh My Zsh + Starship | ✅ Yes | `USE_GIT_PROMPT` |
| Tmux (TPM, Catppuccin) | ✅ Yes | — |
| Claude Code CLI | ✅ Yes | `USE_CLAUDE_CODE` |
| VS Code Settings | ✅ Yes | `USE_VSCODE_CONFIG` |
| Docker Autocomplete | ✅ Yes | `USE_DOCKER_AUTOCOMPLETE` |
| Claude Config/Marketplace | ✅ Yes | `USE_CLAUDE`, `USE_CLAUDE_MARKETPLACE` |
| rtk (Rust Token Killer) | ✅ Yes | `USE_RTK` |

For **host** options, see the [host-template](https://github.com/CamillePolice/host-template) repository.

## 🛠️ Customization

**This is a template!** Replace this README with your project-specific content.

**Keep:**
- `.devcontainer/` folder (your development environment)
- `CLAUDE.md` (helps Claude Code understand your project)

**Replace:**
- This `README.md` with your project documentation
- `PROJECT_NAME` in `.devcontainer/devcontainer.json`
- Optional configs: `launch.json`, `.pre-commit-config.yaml`

---

**Template by:** Your Team | **Version:** 1.0.0 | **Updated:** January 2026
