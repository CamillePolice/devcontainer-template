# Installed Tools

Modern CLI tools and shell environment configuration.

## 🎨 Shell Environment

| Tool | Description |
|------|-------------|
| **Oh My Zsh** | Enhanced shell framework |
| **Starship** | Fast, customizable, cross-shell prompt (written in Rust) |
| **Plugins** | git, docker, docker-compose, node, npm, zsh-autosuggestions, zsh-syntax-highlighting |

### 🚀 Starship Prompt

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

## ⚡ Modern CLI Tools

| Tool | Description | Alias |
|------|-------------|-------|
| 📂 `eza` | Modern ls replacement with git integration | `ls` → `eza` |
| 🔍 `fzf` | Fuzzy finder | - |
| 🔎 `ripgrep` | Fast grep replacement | `rgrep` → `rg` |
| 🦇 `bat` | Better cat with syntax highlighting | `cat` → `bat` |
| 📁 `fd-find` | Better find replacement | `ffind` → `fd` |
| 🚀 `zoxide` | Smart directory jumping | `cd` → `z` |
| 🌐 `httpie` | Modern HTTP client | `http` |
| 📋 `hurl` | HTTP requests defined in plain text (`.hurl` files) | `hurl` |
| 📖 `tldr` | Simplified man pages | `help` |

## ⌨️ Aliases

### 📂 File Listing (eza)

```bash
ls    → eza                    # Modern ls with colors
ll    → eza -lah --git         # Long listing with git status
lt    → eza --tree --level=2   # Tree view (2 levels)
```

### 🔀 Git Shortcuts

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

### 🐳 Docker Shortcuts

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

## 🔧 Tool Installation

Tools are installed via the `install_cli_tools.sh` script, which runs:
- During container creation (`post_create.sh`)
- On every container start (`init_env.sh`)

To disable: Set `USE_CLI_TOOLS="false"` in devcontainer.json (if implemented).

## 📚 Learn More

- **Starship**: https://starship.rs
- **eza**: https://github.com/eza-community/eza
- **fzf**: https://github.com/junegunn/fzf
- **ripgrep**: https://github.com/BurntSushi/ripgrep
- **bat**: https://github.com/sharkdp/bat
- **zoxide**: https://github.com/ajeetdsouza/zoxide
- **hurl**: https://hurl.dev
