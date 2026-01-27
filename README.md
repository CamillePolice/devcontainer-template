# DevContainer Template

> A production-ready VS Code DevContainer template for consistent development environments

[![Docker](https://img.shields.io/badge/Docker-enabled-2496ED?style=flat-square&logo=docker)](https://docker.com)
[![Node.js](https://img.shields.io/badge/Node.js-LTS-339933?style=flat-square&logo=node.js)](https://nodejs.org)
[![Python](https://img.shields.io/badge/Python-3.14-3776AB?style=flat-square&logo=python)](https://python.org)
[![Oh My Zsh](https://img.shields.io/badge/Oh_My_Zsh-enabled-1A2C34?style=flat-square&logo=zsh)](https://ohmyz.sh)
[![Claude Code](https://img.shields.io/badge/Claude_Code-enabled-D97757?style=flat-square&logo=anthropic)](https://claude.ai)
[![VS Code](https://img.shields.io/badge/VS_Code-optimized-007ACC?style=flat-square&logo=visual-studio-code)](https://code.visualstudio.com)

## 🚀 Quick Start

```bash
# 1. Clone and open
git clone <your-repo>
cd your-project
code .

# 2. Configure environment variables in .devcontainer/devcontainer.json
# Set PROJECT_NAME and toggle features (USE_CLAUDE_CODE, USE_GIT_PROMPT, etc.)

# 3. Launch container
# Ctrl+Shift+P → "Dev Containers: Reopen in Container"

# 4. Verify installation (optional)
bash .devcontainer/scripts/tests/run_tests.sh

# 5. Start developing!
```

## ✨ Features

- ✅ **Automated Setup** - Claude Code CLI, VS Code settings, Git prompt, CLI tools
- ✅ **Customizable** - Toggle features via environment variables
- ✅ **Claude Code Integration** - Auto-generates CLAUDE.md for project context
- ✅ **Modern Shell** - Oh My Zsh + Starship prompt with Git integration
- ✅ **VS Code Optimized** - Pre-configured settings, tasks, and extensions
- ✅ **Stack Support** - Extension packs for Angular, React, Next.js, Vue, Symfony, Go
- ✅ **Code Quality** - EditorConfig, Prettier, pre-commit hooks support
- ✅ **Test Suite** - Automated verification of installation
- ✅ **Documentation** - Comprehensive guides for all features

## 📚 Documentation

**Complete documentation:** [.devcontainer/README.md](.devcontainer/README.md)

**Quick Links:**
- [Environment Variables](.devcontainer/scripts/docs/environment-variables.md)
- [Claude Code Installation](.devcontainer/scripts/docs/install-claude-code.md)
- [VS Code Configuration](.devcontainer/scripts/docs/configure-vscode.md)
- [Test Suite](.devcontainer/scripts/tests/README.md)
- [Troubleshooting](.devcontainer/docs/troubleshooting.md)

## 🎯 What Gets Configured

| Feature | Enabled by Default | Environment Variable |
|---------|-------------------|---------------------|
| Claude Code CLI | ✅ Yes | `USE_CLAUDE_CODE` |
| VS Code Settings | ✅ Yes | `USE_VSCODE_CONFIG` |
| Git Prompt (Starship) | ✅ Yes | `USE_GIT_PROMPT` |
| Docker Autocomplete | ✅ Yes | `USE_DOCKER_AUTOCOMPLETE` |
| Claude Config/Marketplace | ✅ Yes | `USE_CLAUDE`, `USE_CLAUDE_MARKETPLACE` |

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
