#!/bin/bash
# Install zsh, Oh My Zsh, Starship (Linux/macOS). Uses HOST_DIR, HOST_SCRIPTS; sources detect_os.
# No /commandhistory (host uses default ~/.zsh_history).

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

# Plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
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

# .zshrc (only if not already configured)
ZSHRC_MARKER="# === Starship + Oh My Zsh Configuration ==="
if [ -f "$HOME/.zshrc" ] && grep -q "$ZSHRC_MARKER" "$HOME/.zshrc" 2>/dev/null; then
    log ".zshrc already configured; skipping."
else
    log "Writing .zshrc..."
    cat > "$HOME/.zshrc" << 'ZSHEOF'
# === Starship + Oh My Zsh Configuration ===
export PATH="$HOME/.local/bin:$PATH"
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git docker node npm zsh-autosuggestions zsh-syntax-highlighting colored-man-pages)
source "$ZSH/oh-my-zsh.sh"
export LANG=en_US.UTF-8
export EDITOR="${EDITOR:-code --wait}"
alias ll='ls -alF' la='ls -A' l='ls -CF'
alias gs='git status' gd='git diff' gl='git log --oneline --graph --decorate'
if command -v starship &>/dev/null; then eval "$(starship init zsh)"; fi
ZSHEOF
fi

# Starship config (minimal)
mkdir -p "$HOME/.config"
if [ ! -f "$HOME/.config/starship.toml" ]; then
    printf 'add_newline = true\nformat = "$directory$git_branch$character"\n' > "$HOME/.config/starship.toml"
fi

log "Git prompt (zsh + Starship) configured. Run 'exec zsh' to use."
