# Conventional Commits Plugin

Generate standardized git commit messages following the Conventional Commits specification.

## Overview

This plugin provides a skill that helps Claude Code automatically generate clean, professional commit messages that follow the Conventional Commits format.

## Features

- ✅ Automatic commit message generation following Conventional Commits
- ✅ Validates format before committing
- ✅ Analyzes git diff and status to understand changes
- ✅ Suggests appropriate type, scope, and subject
- ✅ Professional, clean commits (no AI attribution)
- ✅ Works across all project types (web, backend, infrastructure, mobile)

## Installation

### From Local Directory

```bash
# In your Claude Code settings, add this plugin
# or copy to ~/.claude/skills/
```

### As Git Repository

```bash
git clone <this-repo> ~/.claude/plugins/conventional-commits
```

## Usage

The skill activates automatically when you:
- Mention creating or generating commit messages
- Say "create a commit", "commit these changes", "ready to commit"
- Work with staged git changes
- Ask about commit message format

### Example Session

```
You: I've finished implementing the authentication feature. Create a commit for me.

Claude: I'll analyze your changes and generate a commit message.

[Runs git status and git diff --staged]

I've analyzed your changes and propose:

**feat(auth): add JWT authentication middleware**

**Rationale:**
- Type: `feat` - Adds new authentication functionality
- Scope: `auth` - Changes affect authentication module
- Subject: Clear, imperative, describes the change

**Changed files:**
- src/middleware/auth.js (JWT validation)
- src/routes/protected.js (protected routes)
- tests/auth.test.js (test coverage)

Shall I create this commit? (yes/no)

You: yes

[Creates commit]

✓ Commit successful
[abc1234] feat(auth): add JWT authentication middleware
```

## Commit Message Format

This plugin follows the Conventional Commits specification:

```
<type>(<scope>): <subject>

<body (optional)>

<footer (optional)>
```

### Types

- `feat` - New feature
- `fix` - Bug fix
- `refactor` - Code refactoring
- `docs` - Documentation changes
- `style` - Code style changes (formatting)
- `test` - Test additions or changes
- `chore` - Maintenance tasks
- `perf` - Performance improvements
- `ci` - CI/CD changes
- `build` - Build system changes

### Scope (Optional)

The scope indicates which part of the codebase is affected:
- Web apps: `auth`, `api`, `ui`, `components`
- Backend: `users`, `database`, `cache`, `api`
- Infrastructure: `terraform`, `docker`, `k8s`, `ci`

### Examples

```bash
# Simple feature
feat(api): add user search endpoint

# Bug fix with scope
fix(parser): handle malformed JSON gracefully

# Refactoring
refactor(components): extract common button logic

# Documentation
docs: update API documentation

# Performance improvement
perf(queries): optimize database indexes

# Breaking change
feat(api)!: redesign authentication endpoints

BREAKING CHANGE: OAuth endpoints moved from /auth to /api/v2/auth.
Update client integrations accordingly.
```

## Configuration

### Allowed Tools

This skill uses:
- `Bash` - Execute git commands
- `AskUserQuestion` - Confirm commit messages

### Customization

You can customize the skill behavior by:
1. Editing `skills/generating-git-commits/SKILL.md`
2. Adding project-specific scope patterns
3. Documenting team conventions in your repository

## Project-Specific Conventions

Document your project's conventions in your README:

```markdown
## Commit Message Conventions

We use Conventional Commits with these scopes:
- `platform` - Platform core
- `widgets` - Widget system
- `connectors` - External integrations
```

## Integration

### With commitlint

This skill generates messages compatible with commitlint:

```json
{
  "extends": ["@commitlint/config-conventional"]
}
```

### With Husky

Works seamlessly with pre-commit hooks:

```json
{
  "husky": {
    "hooks": {
      "commit-msg": "commitlint -E HUSKY_GIT_PARAMS"
    }
  }
}
```

### With semantic-release

Generated commits work with semantic-release for automated versioning.

## Best Practices

1. **Commit Frequently** - Small, atomic commits
2. **One Concern Per Commit** - Each commit represents one logical change
3. **Clear Subjects** - Be specific about what changed
4. **Use Body for Context** - Explain "why" not just "what"
5. **Reference Issues** - Link to issue tracker

## Troubleshooting

### Skill Not Activating

Try explicit invocation:
```
"Use the generating-git-commits skill to create a commit message"
```

### No Staged Changes

Ensure files are staged:
```bash
git add <files>
git status  # Verify staging
```

### Wrong Type Selected

The skill analyzes changes to determine type. If incorrect, you can:
1. Provide more context about the change
2. Manually specify: "This is a bug fix, not a feature"
3. Edit the commit message after creation

## License

Internal Use - Claranet

## Contributing

Contributions welcome! Please ensure:
- Follow existing code style
- Update documentation
- Test with various project types
- Keep skill instructions concise

## Support

For issues or questions:
1. Check troubleshooting section
2. Consult Conventional Commits specification: https://www.conventionalcommits.org/
