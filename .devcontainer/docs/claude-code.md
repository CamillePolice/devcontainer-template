# Claude Code Configuration

Comprehensive Claude Code setup with agents, skills, commands, hooks, and rules from [everything-claude-code](https://github.com/affaan-m/everything-claude-code).

## 📖 Overview

The devcontainer includes automatic setup for [everything-claude-code](https://github.com/affaan-m/everything-claude-code) - a battle-tested collection of Claude Code configurations from an Anthropic hackathon winner.

---

## 🎛️ Configuration Modes

Control Claude Code setup via environment variables in `devcontainer.json`:

```json
"containerEnv": {
    "USE_CLAUDE_CODE": "true",         // Master toggle
    "USE_CLAUDE": "true",              // Direct repository copy
    "USE_CLAUDE_MARKETPLACE": "true",  // Plugin marketplace setup
}
```

### Configuration Matrix

| Mode | USE_CLAUDE | USE_CLAUDE_MARKETPLACE | Description |
|------|------------|------------------------|-------------|
| **Both** (recommended) | `true` | `true` | Project-level configs + marketplace plugin |
| **Direct Copy Only** | `true` | `false` | Full offline access, manual updates |
| **Marketplace Only** | `false` | `true` | Lightweight, easy updates via plugin |
| **Disabled** | `false` | `false` | No Claude configuration |

---

## 📦 What's Included

```
.claude/
├── agents/              # Specialized subagents
│   ├── planner.md           # Feature planning
│   ├── architect.md         # System design
│   ├── tdd-guide.md         # Test-driven development
│   ├── code-reviewer.md     # Quality review
│   ├── security-reviewer.md # Security analysis
│   └── ...
│
├── skills/              # Workflow definitions
│   ├── coding-standards/    # Language best practices
│   ├── tdd-workflow/        # TDD methodology
│   ├── continuous-learning/ # Auto-extract patterns
│   └── ...
│
├── commands/            # Slash commands
│   ├── tdd.md              # /tdd - TDD workflow
│   ├── plan.md             # /plan - Planning
│   ├── code-review.md      # /code-review - Review
│   └── ...
│
├── hooks/               # Event-based automation
│   └── hooks.json          # PreToolUse, PostToolUse, etc.
│
├── rules/               # Always-follow guidelines
│   ├── security.md         # Security checks
│   ├── testing.md          # TDD requirements
│   └── ...
│
└── scripts/             # Node.js hook scripts
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

## ⚙️ Direct Copy Mode

When `USE_CLAUDE=true`:

### What It Does
- Clones everything-claude-code repository
- Copies configurations to `.claude/` folder in project
- Provides offline access to all configurations

### Pros
- ✅ Complete offline access
- ✅ Full control over customization
- ✅ No dependency on Claude Code plugin system
- ✅ Works immediately in devcontainer

### Cons
- ❌ Manual updates required (re-run script or git pull)
- ❌ Takes up project space (~5-10MB)

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
