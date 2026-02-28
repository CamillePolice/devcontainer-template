#!/bin/bash

# Extension installation script by stack (Cursor and VS Code compatible)
# Usage: ./install_by_stack.sh [stack1] [stack2] ...
# Example: ./install_by_stack.sh angular symfony
# Editor: uses WHICH_EDITOR (cursor|vscode) from .devcontainer/.env, or auto-detects (cursor if in PATH, else code)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Load .devcontainer/.env so WHICH_EDITOR is available when set
SCRIPT_DIR_ABS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for try in ".devcontainer/.env" "$SCRIPT_DIR_ABS/../../.env" "$SCRIPT_DIR_ABS/../../../.devcontainer/.env"; do
    if [ -f "$try" ]; then
        set -a
        # shellcheck source=/dev/null
        source "$try"
        set +a
        break
    fi
done

# Editor CLI: cursor or code (VS Code uses same extension IDs)
if [ -n "$WHICH_EDITOR" ]; then
    case "$WHICH_EDITOR" in
        cursor) EDITOR_CMD="cursor" ; EDITOR_NAME="Cursor" ;;
        vscode) EDITOR_CMD="code"   ; EDITOR_NAME="VS Code" ;;
        *)     EDITOR_CMD="cursor" ; EDITOR_NAME="Cursor" ;;  # default
    esac
else
    if command -v cursor &> /dev/null; then
        EDITOR_CMD="cursor"
        EDITOR_NAME="Cursor"
    elif command -v code &> /dev/null; then
        EDITOR_CMD="code"
        EDITOR_NAME="VS Code"
    else
        echo -e "${RED}Neither 'cursor' nor 'code' CLI found in PATH. Install Cursor or VS Code CLI.${NC}" >&2
        exit 1
    fi
fi

VSCODE_DIR=".vscode"
INSTALLED_COUNT=0
SKIPPED_COUNT=0
FAILED_COUNT=0

echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  📦 Extension Installation by Stack                ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to install extensions from a JSON file
install_from_json() {
    local json_file=$1
    local stack_name=$2
    
    if [ ! -f "$json_file" ]; then
        echo -e "${RED}✗${NC} File not found: $json_file"
        return 1
    fi
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}📦 Installing $stack_name extensions${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Extract extensions with jq
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}⚠️  jq not installed, using basic installation...${NC}"
        # Fallback without jq
        grep -oP '"[^"]+\.[^"]+"' "$json_file" | tr -d '"' | while read -r ext; do
            echo -e "   Installing: ${CYAN}$ext${NC}"
            if $EDITOR_CMD --install-extension "$ext" > /dev/null 2>&1; then
                echo -e "   ${GREEN}✓${NC} Installed: $ext"
                ((INSTALLED_COUNT++))
            else
                echo -e "   ${YELLOW}⊘${NC} Already installed or failed: $ext"
                ((SKIPPED_COUNT++))
            fi
        done
    else
        # With jq
        jq -r '.recommendations[]' "$json_file" | while read -r ext; do
            # Check if already installed
            if $EDITOR_CMD --list-extensions 2>/dev/null | grep -qi "^$ext$"; then
                echo -e "   ${YELLOW}⊘${NC} Already installed: ${CYAN}$ext${NC}"
                ((SKIPPED_COUNT++))
            else
                echo -e "   ${BLUE}↓${NC} Installing: ${CYAN}$ext${NC}"
                if $EDITOR_CMD --install-extension "$ext" > /dev/null 2>&1; then
                    echo -e "   ${GREEN}✓${NC} Installed: $ext"
                    ((INSTALLED_COUNT++))
                else
                    echo -e "   ${RED}✗${NC} Failed: $ext"
                    ((FAILED_COUNT++))
                fi
            fi
        done
    fi
    
    echo ""
}

# Automatic stack detection if no arguments provided
detect_stacks() {
    local detected_stacks=()
    
    echo -e "${BLUE}🔍 Automatic stack detection...${NC}"
    echo ""
    
    # Angular
    if [ -f "angular.json" ]; then
        detected_stacks+=("angular")
        echo -e "${GREEN}✓${NC} Angular detected"
    fi
    
    # Vue
    if [ -f "vue.config.js" ] || grep -q "vue" package.json 2>/dev/null; then
        detected_stacks+=("vue")
        echo -e "${GREEN}✓${NC} Vue.js detected"
    fi
    
    # React
    if grep -q "react" package.json 2>/dev/null && [ ! -f "next.config.js" ]; then
        detected_stacks+=("react")
        echo -e "${GREEN}✓${NC} React detected"
    fi
    
    # Next.js
    if [ -f "next.config.js" ] || [ -f "next.config.mjs" ]; then
        detected_stacks+=("nextjs")
        echo -e "${GREEN}✓${NC} Next.js detected"
    fi
    
    # Symfony
    if [ -f "symfony.lock" ] || [ -d "config/packages" ] || [ -f "composer.json" ]; then
        detected_stacks+=("symfony")
        echo -e "${GREEN}✓${NC} Symfony/PHP detected"
    fi
    
    # Go
    if [ -f "go.mod" ]; then
        detected_stacks+=("go")
        echo -e "${GREEN}✓${NC} Go detected"
    fi
    
    echo ""
    echo "${detected_stacks[@]}"
}

# Display help
show_help() {
    echo "Usage: $0 [stack1] [stack2] ..."
    echo ""
    echo "Available stacks:"
    echo "  base      - Base extensions (always included)"
    echo "  angular   - Angular extensions"
    echo "  vue       - Vue.js extensions"
    echo "  react     - React extensions"
    echo "  nextjs    - Next.js extensions"
    echo "  symfony   - Symfony/PHP extensions"
    echo "  go        - Go extensions"
    echo "  all       - All extensions"
    echo ""
    echo "Examples:"
    echo "  $0                    # Automatic detection"
    echo "  $0 angular symfony    # Install Angular + Symfony"
    echo "  $0 all                # Complete installation"
    echo ""
}

# Check arguments
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# Install base extensions (always)
echo -e "${YELLOW}📌 Installing base extensions...${NC}"
echo ""
install_from_json "$VSCODE_DIR/extensions.json" "Base"

# Determine which stacks to install
if [ $# -eq 0 ]; then
    # Automatic detection
    STACKS=$(detect_stacks)
    if [ -z "$STACKS" ]; then
        echo -e "${YELLOW}⚠️  No stack automatically detected${NC}"
        echo -e "${YELLOW}   Only base extensions installed${NC}"
        exit 0
    fi
else
    STACKS="$@"
fi

# Install each requested stack
for stack in $STACKS; do
    case $stack in
        base)
            # Already done
            ;;
        angular)
            install_from_json "$VSCODE_DIR/extensions-angular.json" "Angular"
            ;;
        vue)
            install_from_json "$VSCODE_DIR/extensions-vue.json" "Vue.js"
            ;;
        react)
            install_from_json "$VSCODE_DIR/extensions-react.json" "React"
            ;;
        nextjs)
            install_from_json "$VSCODE_DIR/extensions-nextjs.json" "Next.js"
            ;;
        symfony|php)
            install_from_json "$VSCODE_DIR/extensions-symfony.json" "Symfony/PHP"
            ;;
        go|golang)
            install_from_json "$VSCODE_DIR/extensions-go.json" "Go"
            ;;
        all)
            install_from_json "$VSCODE_DIR/extensions-angular.json" "Angular"
            install_from_json "$VSCODE_DIR/extensions-vue.json" "Vue.js"
            install_from_json "$VSCODE_DIR/extensions-react.json" "React"
            install_from_json "$VSCODE_DIR/extensions-nextjs.json" "Next.js"
            install_from_json "$VSCODE_DIR/extensions-symfony.json" "Symfony/PHP"
            install_from_json "$VSCODE_DIR/extensions-go.json" "Go"
            ;;
        *)
            echo -e "${RED}✗${NC} Unknown stack: $stack"
            echo ""
            show_help
            exit 1
            ;;
    esac
done

echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  📊 Installation Summary                           ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓ Installed:${NC}        $INSTALLED_COUNT"
echo -e "${YELLOW}⊘ Already present:${NC}  $SKIPPED_COUNT"
if [ $FAILED_COUNT -gt 0 ]; then
    echo -e "${RED}✗ Failed:${NC}           $FAILED_COUNT"
fi
echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo ""
echo -e "${BLUE}💡 Tip:${NC} Restart ${EDITOR_NAME} to activate all extensions"
echo -e "   ${CYAN}Ctrl+Shift+P${NC} → ${CYAN}'Developer: Reload Window'${NC}"
echo ""
