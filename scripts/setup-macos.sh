#!/usr/bin/env bash
# setup-macos.sh — Deploy Claude Code features on a fresh macOS machine
# Usage: ./scripts/setup-macos.sh
# Run from the root of the devcontainer-template repo

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_GLOBAL="$HOME/.claude"
RTK_BIN="$HOME/.local/bin/rtk"
RAG_DEST="$HOME/claude-mcp-rag"

log() { echo "[setup] $*"; }
ok()  { echo "[ok]    $*"; }
skip(){ echo "[skip]  $*"; }

# ─── Phase 1 — .claude/ global structure ────────────────────────────────────
log "Phase 1 — Copying .claude/ global structure"

mkdir -p "$CLAUDE_GLOBAL/agents" "$CLAUDE_GLOBAL/skills" "$CLAUDE_GLOBAL/rules" "$CLAUDE_GLOBAL/hooks"

# Agents
for agent in angular-expert archforge build-error-resolver code-reviewer \
             git-diff-reviewer git-smart-commit planner security-expert symfony-expert; do
  src="$REPO_DIR/.claude/agents/$agent.md"
  if [ -f "$src" ]; then
    cp "$src" "$CLAUDE_GLOBAL/agents/"
    ok "Agent: $agent"
  fi
done

# Skills (preserving directory structure)
for skill in capture-learning git-diff-review security strategy-compact verification-loop; do
  src="$REPO_DIR/.claude/skills/$skill/SKILL.md"
  if [ -f "$src" ]; then
    mkdir -p "$CLAUDE_GLOBAL/skills/$skill"
    cp "$src" "$CLAUDE_GLOBAL/skills/$skill/"
    ok "Skill: $skill"
  fi
done

# Rules
for rule in agents performance security; do
  src="$REPO_DIR/.claude/rules/$rule.md"
  if [ -f "$src" ]; then
    cp "$src" "$CLAUDE_GLOBAL/rules/"
    ok "Rule: $rule"
  fi
done

# Hooks
cp "$REPO_DIR/.claude/hooks/hooks.json" "$CLAUDE_GLOBAL/hooks/"
ok "Hooks: hooks.json"

# settings.json with hooks (only if it doesn't exist yet)
SETTINGS="$CLAUDE_GLOBAL/settings.json"
if [ ! -f "$SETTINGS" ]; then
  cat > "$SETTINGS" <<'EOF'
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "tool_name == \"Bash\" && tool_result contains \"error\" || tool_result contains \"Error\"",
        "hooks": [
          {
            "type": "command",
            "command": "echo '[gotcha] Build/runtime error encountered' >> /tmp/learning-notes.md"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "if [ -s /tmp/learning-notes.md ]; then echo '[session-end] Learning notes present - run capture-learning before closing' >&2; fi"
          }
        ]
      }
    ]
  }
}
EOF
  ok "Created ~/.claude/settings.json"
else
  skip "~/.claude/settings.json already exists — skipping (backup first if you want to reset)"
fi

echo ""

# ─── Phase 2 — RTK Token Optimizer ──────────────────────────────────────────
log "Phase 2 — RTK Token Optimizer"

ARCH="$(uname -m)"
if [ "$ARCH" = "arm64" ]; then
  RTK_ASSET="rtk-aarch64-apple-darwin.tar.gz"
else
  RTK_ASSET="rtk-x86_64-apple-darwin.tar.gz"
fi

if [ -f "$RTK_BIN" ]; then
  skip "RTK already installed: $("$RTK_BIN" --version)"
else
  mkdir -p "$HOME/.local/bin"
  RTK_VERSION=$(curl -fsSL "https://api.github.com/repos/rtk-ai/rtk/releases/latest" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['tag_name'])")
  RTK_URL="https://github.com/rtk-ai/rtk/releases/download/${RTK_VERSION}/${RTK_ASSET}"
  log "Downloading RTK ${RTK_VERSION} (${ARCH})"
  curl -fsSL "$RTK_URL" -o /tmp/rtk.tar.gz
  tar -xzf /tmp/rtk.tar.gz -C /tmp rtk
  mv /tmp/rtk "$RTK_BIN"
  chmod +x "$RTK_BIN"
  ok "RTK installed: $("$RTK_BIN" --version)"
fi

# Add to PATH in .zshrc if not already there
if ! grep -q '\.local/bin' "$HOME/.zshrc" 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
  ok "Added ~/.local/bin to PATH in ~/.zshrc"
fi

# Register hook in ~/.claude/settings.json (backup first)
if ! grep -q "rtk-rewrite" "$SETTINGS" 2>/dev/null; then
  cp "$SETTINGS" "${SETTINGS}.bak"
  "$RTK_BIN" init -g --auto-patch
  ok "RTK hook registered in settings.json"
else
  skip "RTK hook already registered"
fi

echo ""

# ─── Phase 3 — RAG MCP Server ───────────────────────────────────────────────
log "Phase 3 — RAG MCP Server"

# Find node binary (nvm or system)
NODE_BIN=""
if [ -s "$HOME/.nvm/nvm.sh" ] || [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
  NVM_SH="${HOME}/.nvm/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && NVM_SH="/opt/homebrew/opt/nvm/nvm.sh"
  set +u
  source "$NVM_SH" 2>/dev/null
  set -u
  NODE_BIN="$(which node 2>/dev/null || true)"
fi
[ -z "$NODE_BIN" ] && NODE_BIN="$(which node 2>/dev/null || true)"

if [ -z "$NODE_BIN" ]; then
  echo "[warn]  node not found — skipping RAG MCP server setup"
  echo "        Install Node.js via: nvm install --lts"
else
  ok "Node.js found: $NODE_BIN ($($NODE_BIN --version))"

  if [ -d "$RAG_DEST" ]; then
    skip "~/claude-mcp-rag already exists"
  else
    cp -r "$REPO_DIR/.devcontainer/mcp/rag" "$RAG_DEST"
    (cd "$RAG_DEST" && npm install --silent)
    ok "MCP RAG server installed at ~/claude-mcp-rag"
  fi

  # Register MCP server in Claude Code CLI
  if claude mcp list 2>/dev/null | grep -q "rag"; then
    skip "MCP server 'rag' already registered (claude mcp list)"
  else
    if [ -n "${RAG_DSN:-}" ]; then
      claude mcp add rag -s user \
        -e RAG_DSN="$RAG_DSN" \
        -e RAG_PROJECT="${RAG_PROJECT:-global}" \
        -- "$NODE_BIN" "$RAG_DEST/mcp-rag-server.js"
      ok "MCP server 'rag' registered in ~/.claude.json"
    else
      echo "[warn]  RAG_DSN not set — skipping claude mcp add"
      echo "        Set RAG_DSN in ~/.zshrc then run:"
      echo "        claude mcp add rag -s user -e RAG_DSN=\$RAG_DSN -e RAG_PROJECT=global -- node $RAG_DEST/mcp-rag-server.js"
    fi
  fi
fi

echo ""

# ─── Phase 4 — Beads CLI ────────────────────────────────────────────────────
log "Phase 4 — Beads CLI"

if command -v bd &>/dev/null; then
  skip "Beads already installed: $(bd --version 2>&1)"
else
  if command -v npm &>/dev/null; then
    npm install -g @beads/bd --silent
    ok "Beads installed: $(bd --version 2>&1)"
  else
    echo "[warn]  npm not found — skipping Beads install"
  fi
fi

echo ""

# ─── Phase 5 — Summary ──────────────────────────────────────────────────────
echo "══════════════════════════════════════════════════════"
echo "  Setup complete — checklist"
echo "══════════════════════════════════════════════════════"
printf "  %-35s %s\n" "claude --version" "$(claude --version 2>/dev/null || echo 'NOT FOUND')"
printf "  %-35s %s\n" "~/.claude/agents/" "$(ls ~/.claude/agents/ 2>/dev/null | wc -l | tr -d ' ') agents"
printf "  %-35s %s\n" "~/.claude/skills/" "$(ls ~/.claude/skills/ 2>/dev/null | wc -l | tr -d ' ') skills"
printf "  %-35s %s\n" "~/.claude/rules/" "$(ls ~/.claude/rules/ 2>/dev/null | wc -l | tr -d ' ') rules"
printf "  %-35s %s\n" "rtk --version" "$("$RTK_BIN" --version 2>/dev/null || echo 'NOT FOUND')"
printf "  %-35s %s\n" "rtk hook" "$("$RTK_BIN" init --show 2>&1 | grep 'settings.json:' | sed 's/.*: //' || echo 'unknown')"
printf "  %-35s %s\n" "MCP rag server" "$(ls ~/claude-mcp-rag/mcp-rag-server.js 2>/dev/null && echo 'installed' || echo 'NOT FOUND')"
printf "  %-35s %s\n" "bd --version" "$(bd --version 2>/dev/null || echo 'NOT FOUND')"
echo "══════════════════════════════════════════════════════"
echo ""
echo "  Next steps:"
echo "  1. Restart Claude Code to activate hooks and MCP servers"
echo "  2. In a new terminal, verify: rtk --version (should work without full path)"
echo "  3. Test RAG: ask Claude '@angular-expert Quel est le pattern signal store?'"
echo "  4. Set RAG_PROJECT per repo in .devcontainer/.env or ~/.zshrc"
