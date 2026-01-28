#!/bin/bash

# Use env vars from devcontainer.json, with fallback for manual execution
SCRIPT_DIR="${DEVCONTAINER_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Create log directory if it doesn't exist
LOG_DIR="$PROJECT_ROOT/.devcontainer/.log"
mkdir -p "$LOG_DIR"

# Set up logging
LOGFILE="$LOG_DIR/cli_tools_install.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

function log() {
   echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "=== Starting CLI tools installation script ==="

# Create local bin directory
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# Try to install apt packages (may fail without sudo)
log "Attempting to install CLI tools via apt..."
if sudo -n true 2>/dev/null; then
    log "Sudo available without password, installing apt packages..."
    sudo apt update
    # Install packages individually to avoid failing on missing packages
    for pkg in fzf ripgrep bat fd-find httpie; do
        sudo apt install -y "$pkg" || log "Warning: Could not install $pkg"
    done

    # Try to install tldr, but don't fail if it's not available
    if sudo apt install -y tldr 2>/dev/null; then
        log "Successfully installed tldr"
    else
        log "Warning: tldr package not available in repositories, skipping"
    fi

    # Install eza from official repository (not in default Ubuntu repos)
    log "Adding eza repository..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg
    sudo chmod 644 /etc/apt/sources.list.d/gierens.list
    sudo apt update
    sudo apt install -y eza

    # Create bat symlink (Debian/Ubuntu installs it as batcat)
    if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
        sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
        log "Successfully created bat symlink"
    fi

    # Update tldr database if installed via apt
    if command -v tldr &> /dev/null; then
        tldr --update || true
    fi
else
    log "Sudo requires password - skipping apt packages"
    log "Run this script with sudo access, or install manually:"
    log "  sudo apt install -y fzf ripgrep bat fd-find httpie"
    log "  # For eza, add the repository first:"
    log "  sudo mkdir -p /etc/apt/keyrings"
    log "  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg"
    log "  echo \"deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main\" | sudo tee /etc/apt/sources.list.d/gierens.list"
    log "  sudo apt update && sudo apt install -y eza"
fi

# Install tldr via npm if not already installed (fallback from apt)
log "Installing tldr via npm..."
if ! command -v tldr &> /dev/null; then
    if command -v npm &> /dev/null; then
        if npm install -g tldr; then
            log "Successfully installed tldr via npm"
            # Update tldr cache
            tldr --update 2>/dev/null || log "Note: Run 'tldr --update' to download the cache"
        else
            log "Warning: Failed to install tldr via npm"
        fi
    else
        log "Warning: npm not found, skipping tldr installation"
    fi
else
    log "tldr already installed"
fi

# Install zoxide (works without sudo)
log "Installing zoxide..."
if ! command -v zoxide &> /dev/null; then
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
else
    log "Zoxide already installed"
fi

# Add aliases and functions to zshrc (only for tools that exist)
log "Adding aliases and functions to zshrc..."

# First, remove any previous CLI tools section to avoid duplicates
sed -i '/# === CLI Tools Configuration ===/,/# === End CLI Tools ===/d' ~/.zshrc 2>/dev/null || true

cat >> ~/.zshrc << 'EOF'

# === CLI Tools Configuration ===

# Modern replacements (only if installed)
command -v eza &> /dev/null && alias ls='eza'
command -v eza &> /dev/null && alias ll='eza -lah --git'
command -v eza &> /dev/null && alias lt='eza --tree --level=2'
command -v bat &> /dev/null && alias cat='bat --paging=never'
command -v batcat &> /dev/null && ! command -v bat &> /dev/null && alias cat='batcat --paging=never'
command -v rg &> /dev/null && alias rgrep='rg'
command -v fd &> /dev/null && alias ffind='fd'
command -v fdfind &> /dev/null && ! command -v fd &> /dev/null && alias ffind='fdfind'

# Git shortcuts
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'

# Directory jumping with zoxide
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
    alias cd='z'
fi

# Quick file editing with fzf
if command -v fzf &> /dev/null; then
    alias v='vim $(fzf)'

    # Custom function: vf - fuzzy find git files and open in vim
    function vf() {
        local file
        local preview_cmd="cat {}"
        command -v bat &> /dev/null && preview_cmd="bat --color=always {}"
        command -v batcat &> /dev/null && preview_cmd="batcat --color=always {}"
        file=$(git ls-files | fzf --preview "$preview_cmd" --preview-window=right:60%:wrap)
        [ -n "$file" ] && vim "$file"
    }

    # Source fzf completions
    [ -f ~/.fzf.bash ] && source ~/.fzf.bash
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
fi

# API testing
command -v http &> /dev/null && alias http='http --style=monokai'

# Help
command -v tldr &> /dev/null && alias help='tldr'

# === End CLI Tools ===
EOF

log "Sourcing .zshrc to apply changes"
if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "/usr/bin/zsh" ] || [ "$SHELL" = "/bin/zsh" ]; then
    source ~/.zshrc 2>/dev/null || true
    log "Successfully sourced .zshrc"
else
    log "Not running in zsh, skipping source step (aliases will be available after restarting shell)"
fi

log "=== CLI tools installation completed ==="
log "Log file available at: $LOGFILE"
log ""
log "Installed tools:"
command -v zoxide &> /dev/null && log "  - zoxide (smart cd)"
command -v fzf &> /dev/null && log "  - fzf (fuzzy finder)"
command -v rg &> /dev/null && log "  - ripgrep (fast grep)"
command -v bat &> /dev/null || command -v batcat &> /dev/null && log "  - bat (better cat)"
command -v fd &> /dev/null || command -v fdfind &> /dev/null && log "  - fd (better find)"
command -v eza &> /dev/null && log "  - eza (better ls)"
command -v http &> /dev/null && log "  - httpie (better curl)"
command -v tldr &> /dev/null && log "  - tldr (simplified man pages)"

# Ensure the script exits successfully
exit 0
