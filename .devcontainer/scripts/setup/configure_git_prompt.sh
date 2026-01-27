#!/bin/bash

# Use env vars from devcontainer.json, with fallback for manual execution
SCRIPT_DIR="${DEVCONTAINER_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Check if git prompt configuration is enabled
USE_GIT_PROMPT="${USE_GIT_PROMPT:-true}"

# Create log directory if it doesn't exist
LOG_DIR="$PROJECT_ROOT/.devcontainer/.log"
mkdir -p "$LOG_DIR"

# Set up logging
LOGFILE="$LOG_DIR/configure_git_prompt.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

function log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Skip if disabled
if [ "$USE_GIT_PROMPT" != "true" ]; then
    log "Git prompt configuration disabled (USE_GIT_PROMPT=false)"
    exit 0
fi

log "Starting Zsh and Starship installation and configuration..."

# Get current user (don't hardcode vscode)
CURRENT_USER=$(whoami)
log "Configuring for user: $CURRENT_USER"

# Install zsh if not already installed
if ! command -v zsh &> /dev/null; then
    log "Installing zsh..."
    sudo apt-get update
    sudo apt-get install -y zsh
fi

# Install oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    log "Oh My Zsh already installed"
fi

# Install popular plugins
log "Installing zsh plugins..."

# Install zsh-autosuggestions
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

# Install zsh-syntax-highlighting
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

# Install Starship prompt to local bin (no sudo required)
log "Installing Starship prompt..."
mkdir -p "$HOME/.local/bin"
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
else
    log "Starship already installed"
fi

# Create custom .zshrc configuration (only if not already configured)
ZSHRC_MARKER="# === Starship + Oh My Zsh Configuration ==="

if grep -q "$ZSHRC_MARKER" "$HOME/.zshrc" 2>/dev/null; then
    log ".zshrc already configured - skipping to preserve CLI tools aliases"
else
    log "Creating new .zshrc configuration..."
    cat > "$HOME/.zshrc" << 'EOF'
# === Starship + Oh My Zsh Configuration ===
# Add local bin to PATH FIRST (for starship, zoxide, etc.)
export PATH="$HOME/.local/bin:$PATH"

# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Disable oh-my-zsh themes (we use Starship instead)
ZSH_THEME=""

# Which plugins would you like to load?
plugins=(
    git
    docker
    docker-compose
    node
    npm
    composer
    symfony
    zsh-autosuggestions
    zsh-syntax-highlighting
    colored-man-pages
    command-not-found
)

source $ZSH/oh-my-zsh.sh

# User configuration
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
export EDITOR='code --wait'

# Custom aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Docker aliases
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dc='docker-compose'
alias dcu='docker-compose up'
alias dcd='docker-compose down'
alias dcb='docker-compose build'
alias dcl='docker-compose logs'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# Symfony aliases
alias sf='php bin/console'
alias sfc='php bin/console cache:clear'
alias sfm='php bin/console doctrine:migrations:migrate'
alias sfs='php bin/console server:run'

# History configuration
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_BEEP

# Initialize Starship prompt (with safety check)
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi
EOF
fi  # End of .zshrc creation check

# Create Starship configuration (only if not exists)
mkdir -p "$HOME/.config"

if [ ! -f "$HOME/.config/starship.toml" ]; then
    log "Creating Starship configuration..."
    cat > "$HOME/.config/starship.toml" << 'EOF'
# Starship configuration - Clean and fast prompt for devcontainers
# Documentation: https://starship.rs/config/

# Don't print a new line at the start of the prompt
add_newline = true

# Timeout for commands (in milliseconds)
command_timeout = 1000

# Format of the prompt
format = """
$directory\
$git_branch\
$git_status\
$docker_context\
$php\
$nodejs\
$python\
$rust\
$golang\
$line_break\
$character"""

# Right side of the prompt
right_format = """$cmd_duration$time"""

# Directory
[directory]
style = "blue bold"
truncation_length = 4
truncate_to_repo = true
format = "[$path]($style)[$read_only]($read_only_style) "

# Git branch
[git_branch]
symbol = ""
style = "green"
format = "[$symbol$branch(:$remote_branch)]($style) "

# Git status
[git_status]
style = "yellow"
format = '([$all_status$ahead_behind]($style) )'
conflicted = "="
ahead = "↑${count}"
behind = "↓${count}"
diverged = "↕↑${ahead_count}↓${behind_count}"
untracked = "?${count}"
stashed = "*${count}"
modified = "!${count}"
staged = "+${count}"
renamed = "»${count}"
deleted = "✘${count}"

# Prompt character
[character]
success_symbol = "[>](green)"
error_symbol = "[>](red)"
vimcmd_symbol = "[<](green)"

# Command duration
[cmd_duration]
min_time = 2_000
style = "yellow"
format = "[$duration]($style) "

# Time
[time]
disabled = false
style = "cyan"
format = "[$time]($style)"
time_format = "%H:%M"

# Docker context
[docker_context]
symbol = "docker "
style = "blue"
format = "[$symbol$context]($style) "
only_with_files = true

# PHP
[php]
symbol = "php "
style = "147"
format = "[$symbol$version]($style) "

# Node.js
[nodejs]
symbol = "node "
style = "green"
format = "[$symbol$version]($style) "

# Python
[python]
symbol = "py "
style = "yellow"
format = "[$symbol$version]($style) "

# Rust
[rust]
symbol = "rs "
style = "red"
format = "[$symbol$version]($style) "

# Go
[golang]
symbol = "go "
style = "cyan"
format = "[$symbol$version]($style) "

# Disable modules we don't need
[aws]
disabled = true

[gcloud]
disabled = true

[kubernetes]
disabled = true
EOF
else
    log "Starship configuration already exists - skipping"
fi

# Set zsh as default shell for the current user
log "Setting zsh as default shell for $CURRENT_USER..."
if [ "$SHELL" != "/usr/bin/zsh" ] && [ "$SHELL" != "/bin/zsh" ]; then
    sudo chsh -s /usr/bin/zsh "$CURRENT_USER"
fi

# Also add PATH to bashrc as fallback
if ! grep -q 'local/bin' "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" << 'BASHEOF'

# Add local bin to PATH (for starship, zoxide, etc.)
export PATH="$HOME/.local/bin:$PATH"

# Initialize Starship prompt in bash too
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi
BASHEOF
fi

# Create symlink for bash_history to preserve history
log "Setting up command history..."
if [ -f /commandhistory/.bash_history ]; then
    # Convert bash history to zsh history format if needed
    if [ ! -f /commandhistory/.zsh_history ]; then
        cp /commandhistory/.bash_history /commandhistory/.zsh_history
    fi
    # Link zsh history to persistent storage
    ln -sf /commandhistory/.zsh_history "$HOME/.zsh_history"
fi

log "============================================="
log "Zsh + Starship installation completed!"
log "============================================="
log ""
log "To start using zsh with Starship:"
log "  - Run 'exec zsh' to switch now"
log "  - Or open a new terminal"
log ""
log "Starship config: ~/.config/starship.toml"
log "Zsh config: ~/.zshrc"
log ""
log "Useful commands:"
log "  - starship explain    : Show what each part of prompt means"
log "  - starship timings    : Show how long each module takes"
log "============================================="
