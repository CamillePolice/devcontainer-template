#!/bin/bash
# Install zsh, Oh My Zsh, Starship (Linux/macOS). Same customizations as devcontainer.
# Uses HOST_DIR, HOST_SCRIPTS; sources detect_os. No /commandhistory (host uses ~/.zsh_history).

set -e

HOST_DIR="${HOST_DIR:?}"
HOST_SCRIPTS="${HOST_SCRIPTS:?}"
LOG_DIR="$HOST_DIR/.log"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/configure_git_prompt.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

# shellcheck source=../lib/detect_os.sh
source "$HOST_SCRIPTS/lib/detect_os.sh"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

if [ "${USE_GIT_PROMPT:-true}" != "true" ]; then
    log "USE_GIT_PROMPT is false; skipping."
    exit 0
fi

log "Configuring zsh + Starship (OS=$OS)..."

# Install zsh (Linux: apt/dnf/pacman; macOS: brew)
case "$PKG_MGR" in
    apt)
        if ! command -v zsh &>/dev/null; then
            sudo apt-get update && sudo apt-get install -y zsh || log "Warning: could not install zsh"
        fi
        ;;
    dnf)
        if ! command -v zsh &>/dev/null; then
            sudo dnf install -y zsh || log "Warning: could not install zsh"
        fi
        ;;
    pacman)
        if ! command -v zsh &>/dev/null; then
            sudo pacman -S --noconfirm zsh || log "Warning: could not install zsh"
        fi
        ;;
    brew)
        if ! command -v zsh &>/dev/null; then
            brew install zsh || log "Warning: could not install zsh"
        fi
        ;;
    *) log "Unknown package manager; ensure zsh is installed." ;;
esac

# Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    log "Oh My Zsh already installed"
fi

# Plugins (same as devcontainer)
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
log "Installing zsh plugins..."
for repo in "https://github.com/zsh-users/zsh-autosuggestions" "https://github.com/zsh-users/zsh-syntax-highlighting.git"; do
    name=$(basename "$repo" .git)
    if [ ! -d "$ZSH_CUSTOM/plugins/$name" ]; then
        git clone "$repo" "$ZSH_CUSTOM/plugins/$name" 2>/dev/null || log "Warning: could not clone $name"
    fi
done

# Starship
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
if ! command -v starship &>/dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
else
    log "Starship already installed"
fi

# .zshrc (full devcontainer-style; only if not already configured)
ZSHRC_MARKER="# === Starship + Oh My Zsh Configuration ==="
if [ -f "$HOME/.zshrc" ] && grep -q "$ZSHRC_MARKER" "$HOME/.zshrc" 2>/dev/null; then
    log ".zshrc already configured; skipping."
else
    log "Writing .zshrc..."
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
fi

# Starship config (full devcontainer-style; only if not exists)
mkdir -p "$HOME/.config"
if [ ! -f "$HOME/.config/starship.toml" ]; then
    log "Creating Starship configuration..."
    cat > "$HOME/.config/starship.toml" << 'STAREOF'
# Starship configuration - Same as devcontainer
# Documentation: https://starship.rs/config/

add_newline = true
command_timeout = 1000

format = """
[┌─](bold cyan)$username\
$directory\
$git_branch\
$git_status\
$git_metrics\
$git_state\
$package\
$docker_context\
$php\
$nodejs\
$python\
$rust\
$golang\
$jobs
[└─](bold cyan)$character"""

right_format = """$memory_usage$cmd_duration$battery$time"""

[username]
style_user = "bold dimmed blue"
format = "[$user]($style) "
disabled = false
show_always = true

[directory]
style = "bold bright-blue"
truncation_length = 4
truncate_to_repo = true
format = "[ $path]($style)[$read_only]($read_only_style) "
read_only = " 󰌾"

[git_branch]
symbol = " "
style = "bold green"
format = "[$symbol$branch]($style) "

[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'
conflicted = "⚔️ ${count}"
ahead = "⬆️ ${count}"
behind = "⬇️ ${count}"
diverged = "🔀 ${count}"
untracked = "🆕 ${count}"
stashed = "📦 ${count}"
modified = "📝 ${count}"
staged = "✅ ${count}"
renamed = "📛 ${count}"
deleted = "🗑️ ${count}"
style = "bold yellow"

[git_metrics]
disabled = false
added_style = "bold green"
deleted_style = "bold red"
format = '([+$added]($added_style) )([-$deleted]($deleted_style) )'

[git_state]
format = '[\($state( $progress_current of $progress_total)\)]($style) '
cherry_pick = "[🍒 PICKING](bold red)"
rebase = "[📶 REBASING](bold yellow)"
merge = "[🔀 MERGING](bold yellow)"
revert = "[🔄 REVERTING](bold red)"
bisect = "[🔍 BISECTING](bold blue)"
am = "[📧 AM](bold yellow)"
am_or_rebase = "[📧 AM/REBASE](bold yellow)"
style = "bold yellow"

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
vimcmd_symbol = "[❮](bold green)"

[cmd_duration]
min_time = 2_000
style = "bold yellow"
format = "[ $duration]($style) "

[memory_usage]
disabled = false
threshold = 75
symbol = "🐏 "
format = "$symbol[$ram]($style) "
style = "bold dimmed white"

[battery]
full_symbol = "🔋 "
charging_symbol = "⚡ "
discharging_symbol = "💀 "
disabled = false

[[battery.display]]
threshold = 10
style = "bold red"

[[battery.display]]
threshold = 30
style = "bold yellow"

[[battery.display]]
threshold = 100
style = "bold green"

[time]
disabled = false
style = "bold cyan"
format = "[ $time]($style)"
time_format = "%H:%M"

[docker_context]
symbol = " "
style = "bold blue"
format = "[$symbol$context]($style) "
only_with_files = true

[php]
symbol = " "
style = "147"
format = "[$symbol$version]($style) "

[nodejs]
symbol = " "
style = "bold green"
format = "[$symbol$version]($style) "

[python]
symbol = " "
style = "bold yellow"
format = "[$symbol$version]($style) "

[rust]
symbol = " "
style = "bold red"
format = "[$symbol$version]($style) "

[golang]
symbol = " "
style = "bold cyan"
format = "[$symbol$version]($style) "

[package]
symbol = "📦 "
format = "[$symbol$version]($style) "
style = "bold 208"
disabled = false

[jobs]
symbol = "✦ "
number_threshold = 1
symbol_threshold = 1
format = "[$symbol$number]($style) "
style = "bold blue"

[aws]
disabled = true

[gcloud]
disabled = true

[kubernetes]
disabled = true
STAREOF
else
    log "Starship configuration already exists - skipping"
fi

# Set zsh as default shell (optional)
CURRENT_USER=$(whoami)
if [ "$SHELL" != "/usr/bin/zsh" ] && [ "$SHELL" != "/bin/zsh" ]; then
    if command -v chsh &>/dev/null && (sudo -n true 2>/dev/null || [ "$EUID" -eq 0 ]); then
        log "Setting zsh as default shell for $CURRENT_USER..."
        sudo chsh -s "$(command -v zsh)" "$CURRENT_USER" 2>/dev/null || log "Could not chsh (run manually if desired)"
    fi
fi

# Bash fallback: PATH + Starship
if [ -f "$HOME/.bashrc" ] && ! grep -q 'local/bin' "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" << 'BASHEOF'

# Add local bin to PATH (for starship, zoxide, etc.)
export PATH="$HOME/.local/bin:$PATH"
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi
BASHEOF
fi

log "Git prompt (zsh + Starship) configured. Run 'exec zsh' to use."
