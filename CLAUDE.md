# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **devcontainer template** that provides a standardized development environment for multi-project architectures. It uses VS Code Dev Containers with Docker to ensure consistent environments across team members.

**Base Image:** `mcr.microsoft.com/devcontainers/javascript-node` with Python 3.14.2 and Git added via devcontainer features.

## Architecture

```
.devcontainer/
├── devcontainer.json      # Main container configuration
├── Dockerfile             # Container image (extends Node.js base)
└── scripts/
    ├── post_create.sh     # One-time setup (SSH, CLI tools, Angular CLI)
    ├── init_env.sh        # Runs on every container start
    ├── start_docker.sh    # Starts Docker Compose services
    ├── configure_git_prompt.sh  # Oh My Zsh + Starship setup
    ├── install_cli_tools.sh     # Modern CLI tools (fzf, ripgrep, bat, etc.)
    └── docker_autocomplete.sh   # Docker completion setup

.vscode/
├── config/tasks.json      # VS Code tasks (auto-runs init on folder open)
├── extensions/            # Stack-based extension installation
│   └── install_by_stack.sh  # Auto-detect project type and install extensions
├── settings.json          # Editor settings (Prettier, ESLint, format on save)
└── profiles/              # VS Code profiles
```

## Key Commands

### Extension Installation by Stack

```bash
# Auto-detect project type and install extensions
.vscode/extensions/install_by_stack.sh

# Install for specific stacks
.vscode/extensions/install_by_stack.sh angular symfony

# Install all available extensions
.vscode/extensions/install_by_stack.sh all
```

### Pre-commit Hooks

```bash
# Setup (copy example config first)
cp .vscode/git/.pre-commit-config.yaml.example .pre-commit-config.yaml
pip install pre-commit
pre-commit install
pre-commit install --hook-type commit-msg

# Run hooks manually
pre-commit run --all-files
pre-commit run <hook-name> --all-files
```

### Logs Location

- `/tmp/project_init.log` - post_create.sh output
- `/tmp/project_init_env.log` - init_env.sh output
- `/tmp/project_docker_startup.log` - start_docker.sh output

## Environment Variables

Set in `devcontainer.json`:

`PROJECT_ROOT` - Workspace folder path inside container

`DEVCONTAINER_SCRIPTS` - Path to `.devcontainer/scripts/`

`REMOTE_CONTAINERS` / `DEVCONTAINER` - Set to `true` in container

`TZ` - Timezone (Europe/Paris)

## Forwarded Ports

- `8080` - Application (notifies on auto-forward)
- `8081` - Service (silent auto-forward)

## Shell Aliases

The environment includes modern CLI tool aliases:

- `ls` → `eza`, `ll` → `eza -lah --git`, `lt` → `eza --tree --level=2`
- `cat` → `bat`, `ffind` → `fd`, `rgrep` → `rg`
- Git: `gs`, `gd`, `gl`, `ga`, `gc`, `gp`, `gco`, `gb`
- Docker: `dps`, `dpa`, `di`, `dex`, `dc`, `dcu`, `dcd`, `dcb`, `dcl`

## Commit Standards

When using this template in a project:

- Branch format: `opv_[task_number]-[description]` or `opv_[task_number]-ticket_[ticket_number]-[description]`
- Commit format: `OPV-[task_number]([commit_type]): message`
- Commit types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
