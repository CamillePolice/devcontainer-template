# Claude Code Configuration

Claude Code setup with optional marketplace plugins. The devcontainer creates an empty `.claude/` structure by default; it does not clone external repositories.

## 📖 Overview

**Tip:** [everything-claude-code](https://github.com/affaan-m/everything-claude-code) is a great source for agents, skills, commands, hooks, and rules — a battle-tested collection from an Anthropic hackathon winner. Use it as a reference or copy content into your project's `.claude/` folder as needed.

---

## 🎛️ Configuration Modes

Control Claude Code setup via environment variables in `devcontainer.json`:

```json
"containerEnv": {
    "USE_CLAUDE_CODE": "true",         // Master toggle
    "USE_CLAUDE": "true",              // Create .claude/ structure (no clone)
    "USE_CLAUDE_MARKETPLACE": "true",  // Plugin marketplace setup
}
```

### Configuration Matrix

| Mode | USE_CLAUDE | USE_CLAUDE_MARKETPLACE | Description |
|------|------------|------------------------|-------------|
| **Both** (recommended) | `true` | `true` | Empty `.claude/` structure + marketplace plugin |
| **Structure Only** | `true` | `false` | Empty `.claude/` dirs only (add content from everything-claude-code if desired) |
| **Marketplace Only** | `false` | `true` | Lightweight, easy updates via plugin |
| **Disabled** | `false` | `false` | No Claude configuration |

---

## 📦 Project structure (when USE_CLAUDE=true)

Empty directories are created; add your own files or copy from [everything-claude-code](https://github.com/affaan-m/everything-claude-code):

```
.claude/
├── agents/              # Specialized subagents (e.g. planner, code-reviewer)
├── skills/              # Workflow definitions
├── commands/            # Slash commands
├── hooks/               # hooks.json — PreToolUse, PostToolUse, etc.
├── rules/               # Always-follow guidelines
└── (optional: scripts/, contexts/, mcp/, permissions/)
```

---

## 🚀 Usage

### Slash Commands

Available after setup:

```bash
/tdd                # Start test-driven development workflow
/plan               # Create implementation plan
/code-review        # Request code quality review
/e2e                # Generate E2E tests
/build-fix          # Fix build errors
/verify             # Run verification loop
```

### Agents

Delegate tasks to specialized agents:

- **planner** - Feature implementation planning
- **architect** - System design decisions
- **code-reviewer** - Quality and security review
- **tdd-guide** - Test-driven development
- **security-reviewer** - Vulnerability analysis

### Skills

Reusable workflow definitions:

- **TDD Workflow** - Red-Green-Refactor methodology
- **Security Review** - Security checklist
- **Coding Standards** - Language-specific best practices
- **Continuous Learning** - Auto-extract patterns from sessions

---

## ⚙️ Project structure (USE_CLAUDE)

When `USE_CLAUDE=true`:

### What It Does
- Creates an empty `.claude/` folder structure (agents, skills, commands, hooks, rules)
- Does **not** clone any repository

**Great source for content:** [everything-claude-code](https://github.com/affaan-m/everything-claude-code) is an excellent reference for agents, skills, hooks, and rules. Copy what you need into your project's `.claude/` or use the marketplace plugin (see below).

---

## 🔌 Marketplace Mode

When `USE_CLAUDE_MARKETPLACE=true`:

### What It Does
- Creates/updates `~/.claude/settings.json`
- Registers everything-claude-code and claude-mem marketplaces
- Enables both plugins automatically

### Pros
- ✅ Easy to update (just update the plugin)
- ✅ Smaller project footprint
- ✅ Recommended by repository authors

### Cons
- ❌ Requires Claude Code to be properly configured
- ❌ Rules need manual installation (plugin limitation)

### Manual Setup

If `~/.claude/settings.json` already exists, add manually:

```json
{
  "extraKnownMarketplaces": {
    "everything-claude-code": {
      "source": {
        "source": "github",
        "repo": "affaan-m/everything-claude-code"
      }
    },
    "claude-mem": {
      "source": {
        "source": "github",
        "repo": "thedotmack/claude-mem"
      }
    }
  },
  "enabledPlugins": {
    "everything-claude-code@everything-claude-code": true,
    "claude-mem@claude-mem": true
  }
}
```

Or use Claude Code commands:
```bash
/plugin marketplace add affaan-m/everything-claude-code
/plugin install everything-claude-code@everything-claude-code
/plugin marketplace add thedotmack/claude-mem
/plugin install claude-mem
```

---

## 📝 Logs

Check installation logs:

```bash
cat /tmp/project_claude_config.log
```

---

## 🔄 Updates

### Direct Copy Mode
```bash
# Delete old configs
rm -rf .claude/

# Re-run script
.devcontainer/scripts/setup/configure_claude.sh
```

### Marketplace Mode
```bash
# In Claude Code
/plugin update everything-claude-code@everything-claude-code
/plugin update claude-mem@claude-mem
```

---

## 📚 Resources

- **everything-claude-code**: [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code)
- **claude-mem**: [thedotmack/claude-mem](https://github.com/thedotmack/claude-mem) — Persistent memory across sessions, web viewer at http://localhost:37777
- **Quick Guide**: [The Shorthand Guide](https://x.com/affaanmustafa/status/2012378465664745795)
- **Advanced Guide**: [The Longform Guide](https://x.com/affaanmustafa/status/2014040193557471352)
