# Pre-commit Hooks

Automated code quality checks that run before each commit.

## 🚀 Setup

### 1. Copy Example Configuration

```bash
cp .vscode/git/.pre-commit-config.yaml.example .pre-commit-config.yaml
```

### 2. Install Pre-commit

Automatically done by `init_env.sh`, or manually:

```bash
pip install pre-commit
pre-commit install
```

### 3. Install Commit-msg Hook

For commit message validation:

```bash
pre-commit install --hook-type commit-msg
```

---

## 🔧 Available Hooks

### 🐘 PHP Backend (Main API)

| Hook | Stage | Description |
|------|-------|-------------|
| 🔍 `phpstan-main` | pre-commit | Static analysis with PHPStan |
| 🎨 `php-cs-fixer-main` | pre-commit | Code style fixing |
| 🚀 `rector-fix-main` | pre-commit | Code modernization |
| ✅ `phpstan-validate-main` | pre-commit | Final PHPStan validation |

### 📊 PHP Backend (Historic API)

| Hook | Stage | Description |
|------|-------|-------------|
| 🔍 `phpstan-historic` | pre-commit | Static analysis with PHPStan |
| 🎨 `php-cs-fixer-historic` | pre-commit | Code style fixing |
| 🚀 `rector-fix-historic` | pre-commit | Code modernization |
| ✅ `phpstan-validate-historic` | pre-commit | Final PHPStan validation |

### 🎨 Angular Frontend

| Hook | Stage | Description |
|------|-------|-------------|
| 🔧 `eslint-angular` | pre-commit | ESLint with auto-fix |
| 🎨 `prettier-angular` | pre-commit | Code formatting |
| 🏗️ `ng-build-check` | pre-commit | Angular build verification |
| 📝 `tsc-angular` | pre-commit | TypeScript type checking |

### ✅ Validation Hooks

| Hook | Stage | Description |
|------|-------|-------------|
| 📝 `commit-msg-format` | commit-msg | Validates commit message format |
| 🌿 `branch-name-format` | pre-commit | Validates branch naming convention |

---

## 📝 Commit Message Format

### Valid Formats

```bash
# Standard format
OPV-[task_number]([commit_type]): message

# With ticket reference
OPV-[task_number]_Ticket-[ticket_number]([commit_type]): message

# Version release
Version [X.X.X]

# Merge commits
Merge branch 'opv_[task]-[desc]' into opv_[task]-[desc]
```

### Examples

```bash
OPV-123(feat): add new login feature
OPV-456(fix): resolve authentication bug
OPV-123_Ticket-789(feat): add new login feature
Version [1.2.3]
```

### Commit Types

- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Code style changes (formatting, etc.)
- `refactor` - Code refactoring
- `test` - Adding or updating tests
- `chore` - Maintenance tasks

---

## 🌿 Branch Naming Convention

### Valid Formats

```bash
# Standard format
opv_[task_number]-[description]

# With ticket reference
opv_[task_number]-ticket_[ticket_number]-[description]

# Protected branches
main, master, develop, staging
```

### Examples

```bash
opv_123-user_authentication
opv_123-ticket_456-login_page
opv_789-fix-login-bug
```

---

## ⚡ Smart Execution

All hooks include **smart file detection**:

- ✅ Only run when relevant files are changed
- ✅ Skip automatically if project not found
- ✅ Skip if dependencies not installed
- ✅ Auto-fix issues when possible

### Example Output

```
🔍 Running PHPStan static analysis (Main API)...
ℹ️  No Main API project files changed - skipping PHPStan

🔧 Running ESLint (Angular)...
🔧 Attempting to fix ESLint issues automatically...
✅ ESLint passed (Angular)!
```

---

## 🔄 Manual Execution

```bash
# Run all hooks on all files
pre-commit run --all-files

# Run specific hook
pre-commit run phpstan-main --all-files

# Run only on staged files
pre-commit run

# Skip hooks temporarily (use with caution!)
git commit --no-verify -m "OPV-123(wip): work in progress"
```

---

## 🔧 Customization

### Add a New Hook

Edit `.pre-commit-config.yaml`:

```yaml
- repo: local
  hooks:
    - id: my-custom-hook
      name: My Custom Hook
      entry: ./scripts/my-hook.sh
      language: script
      pass_filenames: false
```

### Disable a Hook

Comment out in `.pre-commit-config.yaml`:

```yaml
# - id: phpstan-main  # Disabled
```

---

## 🆘 Troubleshooting

### Hooks Not Running

```bash
# Reinstall hooks
pre-commit uninstall
pre-commit install
pre-commit install --hook-type commit-msg
```

### Hook Failing

```bash
# Run with verbose output
pre-commit run --all-files --verbose

# Check specific hook
pre-commit run phpstan-main --all-files --verbose
```

### Update Hooks

```bash
# Update to latest versions
pre-commit autoupdate
```

---

## 📚 Learn More

- [Pre-commit Documentation](https://pre-commit.com/)
- [Pre-commit Hooks List](https://pre-commit.com/hooks.html)
