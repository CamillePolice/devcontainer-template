#!/bin/bash
# detect_os.sh — Set OS, editor user dirs, config home, and package manager.
# Source this from host scripts; no dependency on .devcontainer.
# Output: OS=linux|macos|windows (windows when running in WSL/Git Bash we still use linux/macos for uname)

set -e

# Detect OS from uname (Linux/macOS) or WSL; PowerShell scripts use their own detection
if [ -n "$WSL_DISTRO_NAME" ] || grep -qEi 'microsoft|wsl' /proc/version 2>/dev/null; then
    OS="${OS:-linux}"
    # WSL: still use Linux paths
fi

if [ -z "$OS" ]; then
    case "$(uname -s)" in
        Linux*)   OS=linux ;;
        Darwin*) OS=macos ;;
        *)       OS=linux ;; # fallback
    esac
fi

export OS

# Config home (user-level config base)
case "$OS" in
    linux)
        CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
        CURSOR_USER_DIR="$CONFIG_HOME/Cursor/User"
        VSCODE_USER_DIR="$CONFIG_HOME/Code/User"
        ;;
    macos)
        CONFIG_HOME="$HOME/Library/Application Support"
        CURSOR_USER_DIR="$CONFIG_HOME/Cursor/User"
        VSCODE_USER_DIR="$CONFIG_HOME/Code/User"
        ;;
    windows)
        # When bash runs on Windows (Git Bash), use typical Windows paths
        if [ -n "$APPDATA" ]; then
            CURSOR_USER_DIR="$APPDATA/Cursor/User"
            VSCODE_USER_DIR="$APPDATA/Code/User"
        else
            CURSOR_USER_DIR="$HOME/.config/Cursor/User"
            VSCODE_USER_DIR="$HOME/.config/Code/User"
        fi
        CONFIG_HOME="${APPDATA:-$HOME/.config}"
        ;;
    *)
        CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
        CURSOR_USER_DIR="$CONFIG_HOME/Cursor/User"
        VSCODE_USER_DIR="$CONFIG_HOME/Code/User"
        ;;
esac

export CONFIG_HOME CURSOR_USER_DIR VSCODE_USER_DIR

# Package manager command (for install_cli_tools / git prompt)
case "$OS" in
    linux)
        if command -v apt-get &>/dev/null; then
            PKG_MGR=apt
            PKG_INSTALL="sudo apt-get update && sudo apt-get install -y"
        elif command -v dnf &>/dev/null; then
            PKG_MGR=dnf
            PKG_INSTALL="sudo dnf install -y"
        elif command -v pacman &>/dev/null; then
            PKG_MGR=pacman
            PKG_INSTALL="sudo pacman -S --noconfirm"
        else
            PKG_MGR=unknown
            PKG_INSTALL=""
        fi
        ;;
    macos)
        PKG_MGR=brew
        PKG_INSTALL="brew install"
        ;;
    windows)
        PKG_MGR=winget
        PKG_INSTALL="winget install --silent"
        ;;
    *)
        PKG_MGR=unknown
        PKG_INSTALL=""
        ;;
esac

export PKG_MGR PKG_INSTALL
