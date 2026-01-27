#!/bin/bash

# Quick Test - Fast verification of critical components
# Run this for a quick health check

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔍 Quick DevContainer Health Check"
echo ""

PASS=0
FAIL=0

# 1. Check if in devcontainer
if [ "$REMOTE_CONTAINERS" = "true" ] || [ "$DEVCONTAINER" = "true" ]; then
    echo -e "${GREEN}✓${NC} Running in DevContainer"
    ((PASS++))
else
    echo -e "${YELLOW}⚠${NC} Not running in DevContainer"
fi

# 2. Check Claude Code CLI
if command -v claude &> /dev/null; then
    echo -e "${GREEN}✓${NC} Claude Code CLI installed"
    ((PASS++))
else
    echo -e "${RED}✗${NC} Claude Code CLI not found"
    ((FAIL++))
fi

# 3. Check VS Code config
if [ -d ".vscode" ]; then
    echo -e "${GREEN}✓${NC} VS Code configured"
    ((PASS++))
else
    echo -e "${RED}✗${NC} VS Code not configured"
    ((FAIL++))
fi

# 4. Check logs directory
if [ -d ".devcontainer/.log" ]; then
    echo -e "${GREEN}✓${NC} Log directory exists"
    ((PASS++))
else
    echo -e "${RED}✗${NC} Log directory missing"
    ((FAIL++))
fi

# 5. Check CLAUDE.md
if [ -f "CLAUDE.md" ]; then
    echo -e "${GREEN}✓${NC} CLAUDE.md template created"
    ((PASS++))
else
    echo -e "${YELLOW}⚠${NC} CLAUDE.md not found"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ Health check passed ($PASS checks)${NC}"
else
    echo -e "${RED}✗ Health check failed ($FAIL issues)${NC}"
fi
echo ""
echo "Run 'bash .devcontainer/scripts/tests/run_tests.sh' for detailed tests"
