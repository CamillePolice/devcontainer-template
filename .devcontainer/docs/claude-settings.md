# Claude Code Settings Configuration

This document explains the Claude Code configuration architecture for this devcontainer template.

## 📁 Architecture

### Project-Level Configuration (`.claude/`)

All Claude Code configuration lives in the project's `.claude/` folder, making it:
- ✅ **Version controlled** - Shared with your team
- ✅ **Project-specific** - Each project has its own setup
- ✅ **Self-contained** - Everything in one place

```
.claude/
├── .claude-plugin/          # Plugin metadata
│   ├── plugin.json          # Plugin definition
│   └── marketplace.json     # Marketplace metadata
├── agents/                  # 12 specialized AI agents
├── commands/                # 23 custom commands
├── skills/                  # 16 reusable patterns
├── rules/                   # 8 coding standards
├── hooks/                   # Workflow automation
│   └── hooks.json
├── mcp/                     # MCP server configurations
│   ├── mcp.json             # MCP server definitions
│   └── README.md
└── scripts/                 # Hook implementations
```

### User-Level Configuration (`~/.claude/`)

Only user-specific settings (copied from `.claude/mcp/mcp.json`):
```
~/.claude/
└── settings.json           # MCP servers with API keys
```

## 🔌 Components

### 1. Plugin (Local)

**Source**: Everything Claude Code (battle-tested configs from Anthropic hackathon winner)

**Auto-loaded from**: `.claude/.claude-plugin/plugin.json`

**Auto-loaded from**: `.claude/.claude-plugin/plugin.json`

**Provides**:
- **12 Specialized Agents**: architect, code-reviewer, security-reviewer, tdd-guide, planner, etc.
- **23 Custom Commands**: `/plan`, `/code-review`, `/tdd`, `/e2e`, `/build-fix`, etc.
- **16 Skills**: backend-patterns, frontend-patterns, golang-patterns, security-review, etc.
- **8 Rules**: coding-style, git-workflow, patterns, security, testing, etc.
- **Advanced Hooks**: Automated workflows and code quality checks

**No setup required** - Claude Code automatically detects `.claude/.claude-plugin/plugin.json`

### 2. MCP Servers

**Configured in**: `.claude/mcp/mcp.json` (copied to `~/.claude/settings.json` during setup)

#### Context7 MCP Server
**Purpose**: Enhanced context management and retrieval

**Configuration** (in `.claude/mcp/mcp.json`):
```json
{
  "command": "npx",
  "args": ["-y", "@context7/mcp-server"],
  "env": {
    "CONTEXT7_API_KEY": "${CONTEXT7_API_KEY}"
  }
}
```

**Setup Required**:
1. Get API key from [context7.com](https://context7.com)
2. Add to your environment:
   ```bash
   export CONTEXT7_API_KEY="your-api-key-here"
   ```
3. Or add to `~/.zshrc` for persistence:
   ```bash
   echo 'export CONTEXT7_API_KEY="your-api-key-here"' >> ~/.zshrc
   ```

**Features**:
- Advanced semantic search
- Context summarization
- Knowledge base integration

#### Playwright MCP Server
**Purpose**: Browser automation and E2E testing

**Configuration** (in `.claude/mcp/mcp.json`):
```json
{
  "command": "npx",
  "args": ["-y", "@executeautomation/playwright-mcp-server"]
}
```

**Features**:
- Browser automation
- E2E test creation and execution
- Screenshot and video capture
- Network interception
- Mobile device emulation

**No setup required** - works out of the box!

---

## 🚀 Setup Process

The devcontainer automatically configures everything during initialization:

1. **Clone plugin**: `.devcontainer/scripts/setup/configure_claude.sh` copies everything-claude-code to `.claude/`
2. **Copy MCP config**: Copies `.claude/mcp/mcp.json` to `~/.claude/settings.json`
3. **Auto-detection**: Claude Code automatically loads plugin from `.claude/.claude-plugin/plugin.json`

### Manual Setup (if needed)

```bash
# Re-run Claude configuration
.devcontainer/scripts/setup/configure_claude.sh

# Set Context7 API key
export CONTEXT7_API_KEY="your-api-key-here"

# Restart Claude Code
```

---

## 📝 Configuration Files

### `.claude/mcp/mcp.json`
**Purpose**: Define MCP servers for the project  
**Location**: Project root (version controlled)  
**Copied to**: `~/.claude/settings.json` during setup

### `~/.claude/settings.json`
**Purpose**: User-specific settings and MCP servers  
**Location**: User home directory (not version controlled)  
**Auto-created**: By configure_claude.sh script

---

## 🔧 Customization

### Adding MCP Servers

1. Edit `.claude/mcp/mcp.json`:
   ```json
   "your-server-name": {
     "command": "npx",
     "args": ["-y", "@your/mcp-server"],
     "env": {
       "YOUR_API_KEY": "${YOUR_API_KEY}"
     },
     "disabled": false,
     "description": "Your MCP server description"
   }
   ```

2. Re-run configuration:
   ```bash
   .devcontainer/scripts/setup/configure_claude.sh
   ```

3. Restart Claude Code

### Disabling MCP Servers

In `.claude/mcp/mcp.json`:
```json
"server-name": {
  "disabled": true
}
```

### Customizing Hooks

Edit `.claude/hooks/hooks.json` - changes are automatically loaded by the plugin.

### Audio Notifications

**Location**: `.claude/songs/` (finish.mp3, need-human.mp3)

**Features**:
- 🔊 Plays sound when Claude finishes a response
- 🔔 Plays sound when user input is needed

**Audio Players** (auto-detected, in order):
- ffplay (ffmpeg) - Pre-installed in devcontainer
- mpg123, aplay, afplay, paplay

**Customization**:
- Replace `.claude/songs/finish.mp3` with your own sound
- Replace `.claude/songs/need-human.mp3` with your own alert
- Adjust volume in `.claude/scripts/hooks/play-sound.sh`

**Disable**: Remove audio hooks from `.claude/hooks/hooks.json` or delete sound files

See `.claude/songs/README.md` for detailed audio configuration.

---

## 🪝 Hooks System

Your configuration includes comprehensive hooks that automate workflows and enforce best practices:

### PreToolUse Hooks (Before Actions)

#### 1. **Dev Server Protection**
- **Trigger**: Running dev servers (`npm run dev`, `yarn dev`, etc.)
- **Action**: Blocks execution, requires tmux
- **Purpose**: Ensures you can access logs and manage long-running processes

#### 2. **Long-Running Command Reminder**
- **Trigger**: Package installs, tests, builds, docker commands
- **Action**: Suggests using tmux
- **Purpose**: Session persistence for long operations

#### 3. **Git Push Review**
- **Trigger**: `git push`
- **Action**: Reminder to review changes
- **Purpose**: Prevents accidental pushes

#### 4. **Documentation Consolidation**
- **Trigger**: Creating new `.md` or `.txt` files
- **Action**: Blocks creation (except README, CLAUDE, AGENTS, CONTRIBUTING)
- **Purpose**: Keeps documentation consolidated

#### 5. **Compaction Suggestions**
- **Trigger**: Edit or Write operations
- **Action**: Suggests manual compaction at logical intervals
- **Purpose**: Manages context window efficiently

### PostToolUse Hooks (After Actions)

#### 1. **PR Creation Logger**
- **Trigger**: `gh pr create`
- **Action**: Logs PR URL and provides review command
- **Purpose**: Easy PR tracking and review workflow

#### 2. **Build Analysis**
- **Trigger**: Build commands
- **Action**: Async analysis in background
- **Purpose**: Non-blocking build insights

#### 3. **Auto-Format JS/TS**
- **Trigger**: Editing `.js`, `.jsx`, `.ts`, `.tsx` files
- **Action**: Runs Prettier automatically
- **Purpose**: Consistent code formatting

#### 4. **TypeScript Type Checking**
- **Trigger**: Editing `.ts`, `.tsx` files
- **Action**: Runs `tsc --noEmit` and shows errors
- **Purpose**: Catch type errors immediately

#### 5. **Console.log Detection**
- **Trigger**: Editing JS/TS files
- **Action**: Warns about `console.log` statements
- **Purpose**: Prevent debug statements in commits

### Session Lifecycle Hooks

#### SessionStart
- Loads previous context
- Detects package manager
- Restores session state

#### PreCompact
- Saves state before context compaction
- Preserves important information

#### Stop
- Checks for console.log in modified files
- Final quality check after each response

#### SessionEnd
- Persists session state
- Evaluates session for extractable patterns
- Continuous learning system

---

## 📁 Project Structure

```
.claude/
├── agents/           # Specialized AI agents (12)
├── commands/         # Custom commands (23)
├── skills/           # Reusable patterns (16)
├── rules/            # Coding standards (8)
├── hooks/            # Hook definitions
├── scripts/          # Hook implementations
└── contexts/         # Context templates
```

---

## 🚀 Usage Examples

### Using Custom Commands

```bash
# Plan a feature
/plan Implement user authentication

# Code review
/code-review

# Test-driven development
/tdd Add login functionality

# E2E testing
/e2e Test checkout flow

# Fix build errors
/build-fix

# Security review
/security-review

# Update documentation
/update-docs
```

### Using Specialized Agents

Agents automatically activate based on context:
- **architect**: System design and architecture decisions
- **code-reviewer**: Code quality review (proactive after edits)
- **security-reviewer**: Security vulnerability detection
- **tdd-guide**: Test-driven development guidance
- **planner**: Feature planning and task breakdown
- **database-reviewer**: PostgreSQL optimization
- **e2e-runner**: End-to-end testing

### Using MCP Servers

#### Context7:
```
# Enhanced semantic search
Find all authentication-related code

# Context summarization
Summarize the API architecture
```

#### Playwright:
```
# Create E2E test
Create a test for the login flow

# Automate browser actions
Open the app and click the signup button

# Capture screenshot
Take a screenshot of the dashboard
```

---

## 🔧 Customization

### Adding Your Own Hooks

Edit `~/.claude/settings.json` and add to the appropriate hook section:

```json
{
  "matcher": "tool == \"Bash\" && tool_input.command matches \"your-pattern\"",
  "hooks": [
    {
      "type": "command",
      "command": "your-command-here"
    }
  ],
  "description": "Your hook description"
}
```

### Disabling Hooks

Set `"disabled": true` for specific hooks or comment them out.

### Adding MCP Servers

Add to the `mcpServers` section:

```json
"your-server-name": {
  "command": "npx",
  "args": ["-y", "@your/mcp-server"],
  "disabled": false
}
```

---

## 🐛 Troubleshooting

### Hooks Not Working
1. Check Node.js is installed: `node --version`
2. Verify hook scripts exist in `.claude/scripts/hooks/`
3. Check permissions: `chmod +x .claude/scripts/hooks/*.sh`

### MCP Server Issues

#### Context7 Not Working
- Verify API key is set: `echo $CONTEXT7_API_KEY`
- Check server status: `npx @context7/mcp-server --help`

#### Playwright Not Working
- Install dependencies: `npx playwright install`
- Check logs: Look in `~/.claude/debug/` folder

### General Debugging
- Enable debug logging: Add `"debug": true` to settings.json
- Check logs: `~/.claude/debug/`
- Test MCP connection: Restart Claude Code after settings changes

---

## 📚 Resources

- **Everything Claude Code**: https://github.com/affaan-m/everything-claude-code
- **Context7 MCP**: https://context7.com
- **Playwright MCP**: https://github.com/executeautomation/playwright-mcp-server
- **Claude Code Docs**: https://code.claude.com/docs/
- **MCP Protocol**: https://modelcontextprotocol.io/

---

## 💡 Tips

1. **Use tmux** for long-running processes (hooks will enforce this)
2. **Run `/code-review`** after making changes
3. **Use `/plan`** before starting complex features
4. **Let hooks auto-format** your code (Prettier integration)
5. **Check TypeScript errors** immediately after edits
6. **Set CONTEXT7_API_KEY** for enhanced context features
7. **Use Playwright MCP** for browser automation tasks

---

## 🔄 Updating Configuration

To update your configuration:

1. Edit `~/.claude/settings.json`
2. Restart Claude Code or reload the window
3. Test changes with a simple command

To update the everything-claude-code plugin:

```bash
cd /workspaces/devcontainer-template/.claude
git pull origin main  # If cloned as git repo
# Or re-run the configure_claude.sh script
```

---

*This configuration is designed to enhance productivity, enforce best practices, and provide powerful automation capabilities while you code.*
