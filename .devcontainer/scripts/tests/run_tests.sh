#!/bin/bash

# Test Suite Main Runner
# Verifies devcontainer installation based on environment variables

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Use env vars from devcontainer.json
SCRIPT_DIR="${DEVCONTAINER_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Create log directory for tests
LOG_DIR="$PROJECT_ROOT/.devcontainer/.log"
mkdir -p "$LOG_DIR"
TEST_LOG="$LOG_DIR/test_suite.log"

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Initialize log
echo "=== DevContainer Installation Test Suite ===" > "$TEST_LOG"
echo "Started: $(date)" >> "$TEST_LOG"
echo "" >> "$TEST_LOG"

function print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

function test_pass() {
    ((TOTAL_TESTS++))
    ((PASSED_TESTS++))
    echo -e "${GREEN}✓${NC} $1"
    echo "✓ PASS: $1" >> "$TEST_LOG"
}

function test_fail() {
    ((TOTAL_TESTS++))
    ((FAILED_TESTS++))
    echo -e "${RED}✗${NC} $1"
    echo "  ${RED}Error: $2${NC}"
    echo "✗ FAIL: $1 - $2" >> "$TEST_LOG"
}

function test_skip() {
    ((TOTAL_TESTS++))
    ((SKIPPED_TESTS++))
    echo -e "${YELLOW}⊘${NC} $1 (skipped - feature disabled)"
    echo "⊘ SKIP: $1" >> "$TEST_LOG"
}

function test_warn() {
    echo -e "${YELLOW}⚠${NC}  $1"
    echo "⚠ WARN: $1" >> "$TEST_LOG"
}

# Run test suite
clear
echo ""
print_header "DevContainer Installation Test Suite"
echo ""
echo "Testing installation based on environment configuration..."
echo ""

# ============================================================================
# 1. ENVIRONMENT VARIABLES TEST
# ============================================================================
print_header "1. Environment Variables"

# Required variables
if [ -n "$PROJECT_ROOT" ]; then
    test_pass "PROJECT_ROOT is set: $PROJECT_ROOT"
else
    test_fail "PROJECT_ROOT is not set" "Required environment variable"
fi

if [ -n "$DEVCONTAINER_SCRIPTS" ]; then
    test_pass "DEVCONTAINER_SCRIPTS is set: $DEVCONTAINER_SCRIPTS"
else
    test_warn "DEVCONTAINER_SCRIPTS not set (using auto-detection)"
fi

if [ -n "$PROJECT_NAME" ]; then
    test_pass "PROJECT_NAME is set: $PROJECT_NAME"
else
    test_warn "PROJECT_NAME not set (will use default: 'project')"
fi

# Feature flags
echo ""
echo "Feature Flags:"
USE_CLAUDE_CODE="${USE_CLAUDE_CODE:-true}"
USE_CLAUDE="${USE_CLAUDE:-false}"
USE_CLAUDE_MARKETPLACE="${USE_CLAUDE_MARKETPLACE:-false}"
USE_GIT_PROMPT="${USE_GIT_PROMPT:-true}"
USE_DOCKER_AUTOCOMPLETE="${USE_DOCKER_AUTOCOMPLETE:-true}"
USE_VSCODE_CONFIG="${USE_VSCODE_CONFIG:-true}"
CLAUDE_CODE_CHANNEL="${CLAUDE_CODE_CHANNEL:-latest}"

echo "  USE_CLAUDE_CODE: $USE_CLAUDE_CODE"
echo "  USE_CLAUDE: $USE_CLAUDE"
echo "  USE_CLAUDE_MARKETPLACE: $USE_CLAUDE_MARKETPLACE"
echo "  USE_GIT_PROMPT: $USE_GIT_PROMPT"
echo "  USE_DOCKER_AUTOCOMPLETE: $USE_DOCKER_AUTOCOMPLETE"
echo "  USE_VSCODE_CONFIG: $USE_VSCODE_CONFIG"
echo "  CLAUDE_CODE_CHANNEL: $CLAUDE_CODE_CHANNEL"

# ============================================================================
# 2. LOG FILES TEST
# ============================================================================
echo ""
print_header "2. Log Files"

if [ -d "$LOG_DIR" ]; then
    test_pass "Log directory exists: $LOG_DIR"
else
    test_fail "Log directory not found" "Expected: $LOG_DIR"
fi

# Check for expected log files
declare -a expected_logs=(
    "project_init.log"
    "project_init_env.log"
)

if [ "$USE_CLAUDE_CODE" = "true" ]; then
    expected_logs+=("claude_code_install.log")
fi

if [ "$USE_CLAUDE" = "true" ] || [ "$USE_CLAUDE_MARKETPLACE" = "true" ]; then
    expected_logs+=("claude_config.log")
fi

if [ "$USE_VSCODE_CONFIG" = "true" ]; then
    expected_logs+=("vscode_config.log")
fi

if [ "$USE_GIT_PROMPT" = "true" ]; then
    expected_logs+=("configure_git_prompt.log")
fi

if [ "$USE_DOCKER_AUTOCOMPLETE" = "true" ]; then
    expected_logs+=("docker_autocomplete.log")
fi

expected_logs+=("cli_tools_install.log")

for log_file in "${expected_logs[@]}"; do
    if [ -f "$LOG_DIR/$log_file" ]; then
        test_pass "Log file exists: $log_file"
    else
        test_warn "Log file not found: $log_file (may not have run yet)"
    fi
done

# ============================================================================
# 3. CLAUDE CODE CLI TEST
# ============================================================================
echo ""
print_header "3. Claude Code CLI"

if [ "$USE_CLAUDE_CODE" = "true" ]; then
    if command -v claude &> /dev/null; then
        CLAUDE_VERSION=$(claude --version 2>/dev/null | head -n 1 || echo "unknown")
        test_pass "Claude Code CLI installed: $CLAUDE_VERSION"
        
        # Check if CLAUDE.md was created
        if [ -f "$PROJECT_ROOT/CLAUDE.md" ]; then
            test_pass "CLAUDE.md template created"
        else
            test_fail "CLAUDE.md template not found" "Should be at project root"
        fi
    else
        test_fail "Claude Code CLI not installed" "Command 'claude' not found"
    fi
else
    test_skip "Claude Code CLI installation (USE_CLAUDE_CODE=false)"
fi

# ============================================================================
# 4. CLAUDE CONFIGURATION TEST
# ============================================================================
echo ""
print_header "4. Claude Configuration"

if [ "$USE_CLAUDE_CODE" = "true" ]; then
    if [ "$USE_CLAUDE" = "true" ]; then
        if [ -d "$PROJECT_ROOT/.claude" ]; then
            test_pass "Claude config directory exists: .claude/"
            
            # Check for key directories
            if [ -d "$PROJECT_ROOT/.claude/agents" ]; then
                test_pass "Claude agents directory exists"
            else
                test_fail "Claude agents directory not found" "Expected: .claude/agents"
            fi
            
            if [ -d "$PROJECT_ROOT/.claude/skills" ]; then
                test_pass "Claude skills directory exists"
            else
                test_fail "Claude skills directory not found" "Expected: .claude/skills"
            fi
        else
            test_fail "Claude config directory not found" "Expected: .claude/"
        fi
    else
        test_skip "Claude project structure (USE_CLAUDE=false)"
    fi
    
    if [ "$USE_CLAUDE_MARKETPLACE" = "true" ]; then
        if [ -f "$HOME/.claude/settings.json" ]; then
            test_pass "Claude marketplace settings configured"
            
            # Check if marketplace is configured
            if grep -q "everything-claude-code" "$HOME/.claude/settings.json" 2>/dev/null; then
                test_pass "everything-claude-code marketplace registered"
            else
                test_warn "Marketplace registration not found in settings.json"
            fi
        else
            test_warn "Claude settings.json not found (may need manual authentication)"
        fi
    else
        test_skip "Claude marketplace setup (USE_CLAUDE_MARKETPLACE=false)"
    fi
else
    test_skip "Claude configuration (USE_CLAUDE_CODE=false)"
fi

# ============================================================================
# 5. GIT PROMPT TEST
# ============================================================================
echo ""
print_header "5. Git Prompt Configuration"

if [ "$USE_GIT_PROMPT" = "true" ]; then
    # Check Oh My Zsh
    if [ -d "$HOME/.oh-my-zsh" ]; then
        test_pass "Oh My Zsh installed"
    else
        test_fail "Oh My Zsh not installed" "Expected directory: ~/.oh-my-zsh"
    fi
    
    # Check Starship
    if command -v starship &> /dev/null; then
        STARSHIP_VERSION=$(starship --version 2>/dev/null | head -n 1 || echo "unknown")
        test_pass "Starship installed: $STARSHIP_VERSION"
    else
        test_fail "Starship not installed" "Command 'starship' not found"
    fi
    
    # Check .zshrc configuration
    if [ -f "$HOME/.zshrc" ]; then
        if grep -q "starship init" "$HOME/.zshrc" 2>/dev/null; then
            test_pass "Starship configured in .zshrc"
        else
            test_warn "Starship not configured in .zshrc"
        fi
    else
        test_warn ".zshrc not found"
    fi
else
    test_skip "Git prompt configuration (USE_GIT_PROMPT=false)"
fi

# ============================================================================
# 6. CLI TOOLS TEST
# ============================================================================
echo ""
print_header "6. Modern CLI Tools"

declare -A cli_tools=(
    ["eza"]="Modern ls replacement"
    ["bat"]="Cat with syntax highlighting"
    ["fd"]="Modern find replacement"
    ["rg"]="Ripgrep - fast search"
    ["zoxide"]="Smart directory jumper"
    ["hurl"]="HTTP requests in plain text"
)

installed_count=0
total_tools=${#cli_tools[@]}

for tool in "${!cli_tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
        test_pass "$tool installed - ${cli_tools[$tool]}"
        ((installed_count++))
    else
        test_warn "$tool not installed - ${cli_tools[$tool]}"
    fi
done

if [ $installed_count -eq $total_tools ]; then
    echo -e "${GREEN}  All CLI tools installed ($installed_count/$total_tools)${NC}"
elif [ $installed_count -gt 0 ]; then
    echo -e "${YELLOW}  Partial installation ($installed_count/$total_tools tools)${NC}"
else
    test_fail "No CLI tools installed" "Expected at least some tools"
fi

# ============================================================================
# 7. DOCKER AUTOCOMPLETE TEST
# ============================================================================
echo ""
print_header "7. Docker Autocomplete"

if [ "$USE_DOCKER_AUTOCOMPLETE" = "true" ]; then
    # Check if docker completion files exist
    if [ -f "$HOME/.oh-my-zsh/plugins/docker/_docker" ] || \
       [ -f "$HOME/.zsh/completion/_docker" ]; then
        test_pass "Docker completion files installed"
    else
        test_warn "Docker completion files not found"
    fi
    
    # Check if docker-compose completion exists
    if [ -f "$HOME/.oh-my-zsh/plugins/docker-compose/_docker-compose" ] || \
       [ -f "$HOME/.zsh/completion/_docker-compose" ]; then
        test_pass "Docker Compose completion files installed"
    else
        test_warn "Docker Compose completion files not found"
    fi
else
    test_skip "Docker autocomplete (USE_DOCKER_AUTOCOMPLETE=false)"
fi

# ============================================================================
# 8. VS CODE CONFIGURATION TEST
# ============================================================================
echo ""
print_header "8. VS Code Configuration"

if [ "$USE_VSCODE_CONFIG" = "true" ]; then
    # Check .vscode directory
    if [ -d "$PROJECT_ROOT/.vscode" ]; then
        test_pass "VS Code directory exists: .vscode/"
        
        # Check key config files
        if [ -f "$PROJECT_ROOT/.vscode/settings.json" ]; then
            test_pass "settings.json configured"
        else
            test_fail "settings.json not found" "Expected: .vscode/settings.json"
        fi
        
        if [ -f "$PROJECT_ROOT/.vscode/tasks.json" ]; then
            test_pass "tasks.json configured"
        else
            test_fail "tasks.json not found" "Expected: .vscode/tasks.json"
        fi
        
        if [ -f "$PROJECT_ROOT/.vscode/extensions.json" ]; then
            test_pass "extensions.json configured"
        else
            test_fail "extensions.json not found" "Expected: .vscode/extensions.json"
        fi
    else
        test_fail "VS Code directory not found" "Expected: .vscode/"
    fi
    
    # Check linting config files
    if [ -f "$PROJECT_ROOT/.editorconfig" ]; then
        test_pass ".editorconfig configured"
    else
        test_warn ".editorconfig not found"
    fi
    
    if [ -f "$PROJECT_ROOT/.prettierrc" ]; then
        test_pass ".prettierrc configured"
    else
        test_warn ".prettierrc not found"
    fi
    
    # Check workspace file
    PROJECT_NAME="${PROJECT_NAME:-project}"
    if [ -f "$PROJECT_ROOT/${PROJECT_NAME}.code-workspace" ] || [ -L "$PROJECT_ROOT/${PROJECT_NAME}.code-workspace" ]; then
        test_pass "Workspace file created: ${PROJECT_NAME}.code-workspace"
    else
        test_warn "Workspace file not found: ${PROJECT_NAME}.code-workspace"
    fi
else
    test_skip "VS Code configuration (USE_VSCODE_CONFIG=false)"
fi

# ============================================================================
# 9. PROJECT STATUS TEST
# ============================================================================
echo ""
print_header "9. Project Status"

STATUS_FILE="$PROJECT_ROOT/.devcontainer/scripts/project_status"
if [ -f "$STATUS_FILE" ]; then
    test_pass "Project status file exists"
    
    INIT_STATUS=$(grep "project_status_initialization" "$STATUS_FILE" | cut -d'=' -f2)
    if [ "$INIT_STATUS" = "true" ]; then
        test_pass "Project initialization completed"
    else
        test_warn "Project initialization not completed"
    fi
else
    test_fail "Project status file not found" "Expected: $STATUS_FILE"
fi

# ============================================================================
# 10. SUMMARY
# ============================================================================
echo ""
print_header "Test Summary"
echo ""

# Calculate percentages
if [ $TOTAL_TESTS -gt 0 ]; then
    PASS_PERCENT=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    FAIL_PERCENT=$((FAILED_TESTS * 100 / TOTAL_TESTS))
    SKIP_PERCENT=$((SKIPPED_TESTS * 100 / TOTAL_TESTS))
else
    PASS_PERCENT=0
    FAIL_PERCENT=0
    SKIP_PERCENT=0
fi

echo "Total Tests:   $TOTAL_TESTS"
echo -e "${GREEN}Passed:${NC}        $PASSED_TESTS ($PASS_PERCENT%)"
echo -e "${RED}Failed:${NC}        $FAILED_TESTS ($FAIL_PERCENT%)"
echo -e "${YELLOW}Skipped:${NC}       $SKIPPED_TESTS ($SKIP_PERCENT%)"
echo ""

# Final status
if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✓ ALL TESTS PASSED${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    EXIT_CODE=0
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  ✗ SOME TESTS FAILED${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    EXIT_CODE=1
fi

echo ""
echo "Detailed log: $TEST_LOG"
echo ""

# Write summary to log
echo "" >> "$TEST_LOG"
echo "=== Test Summary ===" >> "$TEST_LOG"
echo "Total: $TOTAL_TESTS | Passed: $PASSED_TESTS | Failed: $FAILED_TESTS | Skipped: $SKIPPED_TESTS" >> "$TEST_LOG"
echo "Completed: $(date)" >> "$TEST_LOG"

exit $EXIT_CODE
