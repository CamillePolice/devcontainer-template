#!/bin/bash
# Install CLI tools (fzf, ripgrep, bat, eza, zoxide, tldr) and append aliases to .zshrc.
# Uses HOST_DIR, HOST_SCRIPTS; sources detect_os for PKG_MGR. Linux/macOS.

set -e

HOST_DIR="${HOST_DIR:?}"
HOST_SCRIPTS="${HOST_SCRIPTS:?}"
LOG_DIR="$HOST_DIR/.log"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/install_cli_tools.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

# shellcheck source=../lib/detect_os.sh
source "$HOST_SCRIPTS/lib/detect_os.sh"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

log "Installing CLI tools (OS=$OS, PKG_MGR=$PKG_MGR)..."

mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# Install via package manager
case "$PKG_MGR" in
    apt)
        if sudo -n true 2>/dev/null; then
            sudo apt-get update -qq
            for pkg in fzf ripgrep bat fd-find httpie; do
                sudo apt-get install -y -qq "$pkg" 2>/dev/null || log "Skip $pkg"
            done
            sudo apt-get install -y -qq tldr 2>/dev/null || true
            if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
                sudo ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
            fi
            # eza: add repo then install
            if ! command -v eza &>/dev/null; then
                sudo mkdir -p /etc/apt/keyrings
                wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc 2>/dev/null | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null || true
                echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" 2>/dev/null | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null 2>&1 || true
                sudo apt-get update -qq && sudo apt-get install -y -qq eza 2>/dev/null || log "eza not installed"
            fi
        fi
        ;;
    brew)
        for pkg in fzf ripgrep bat fd httpie eza; do
            brew list "$pkg" &>/dev/null || brew install "$pkg" 2>/dev/null || log "Skip $pkg"
        done
        brew list tldr &>/dev/null || brew install tldr 2>/dev/null || true
        ;;
    dnf|pacman)
        if [ "$PKG_MGR" = "dnf" ]; then
            sudo dnf install -y fzf ripgrep bat fd-find httpie 2>/dev/null || true
        else
            sudo pacman -S --noconfirm fzf ripgrep bat fd httpie 2>/dev/null || true
        fi
        ;;
    *) log "Install fzf, ripgrep, bat, fd, httpie, eza, tldr manually." ;;
esac

# tldr via npm fallback
if ! command -v tldr &>/dev/null && command -v npm &>/dev/null; then
    npm install -g tldr 2>/dev/null || true
fi
command -v tldr &>/dev/null && tldr --update 2>/dev/null || true

# zoxide (curl script)
if ! command -v zoxide &>/dev/null; then
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# Append CLI block to .zshrc if not present
touch "$HOME/.zshrc" 2>/dev/null || true
if [ -f "$HOME/.zshrc" ]; then
    sed -i.bak '/# === CLI Tools Configuration ===/,/# === End CLI Tools ===/d' "$HOME/.zshrc" 2>/dev/null || true
fi
if [ -f "$HOME/.zshrc" ] && ! grep -q "# === CLI Tools Configuration ===" "$HOME/.zshrc" 2>/dev/null; then
    cat >> "$HOME/.zshrc" << 'EOF'

# === CLI Tools Configuration ===
command -v eza &>/dev/null && alias ls='eza' && alias ll='eza -lah --git' && alias lt='eza --tree --level=2'
command -v bat &>/dev/null && alias cat='bat --paging=never'
command -v batcat &>/dev/null && ! command -v bat &>/dev/null && alias cat='batcat --paging=never'
command -v rg &>/dev/null && alias rgrep='rg'
command -v fd &>/dev/null && alias ffind='fd'; command -v fdfind &>/dev/null && ! command -v fd &>/dev/null && alias ffind='fdfind'
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)" && alias cd='z'
command -v tldr &>/dev/null && alias help='tldr'
# === End CLI Tools ===
EOF
    log "Appended CLI aliases to .zshrc"
fi

log "CLI tools setup done."
