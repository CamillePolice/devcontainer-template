# DevContainer Test Suite

Automated test suite to verify devcontainer installation and configuration.

## 📋 Available Tests

### 1. Full Test Suite (`run_tests.sh`)

Comprehensive test suite that validates all installation components based on environment variables.

**Usage:**
```bash
# Run full test suite
bash .devcontainer/scripts/tests/run_tests.sh

# Or from tests directory
cd .devcontainer/scripts/tests
./run_tests.sh
```

**What it tests:**
- ✅ Environment variables configuration
- ✅ Log files creation
- ✅ Claude Code CLI installation
- ✅ Claude configuration (marketplace/direct copy)
- ✅ Git prompt (Oh My Zsh + Starship)
- ✅ Modern CLI tools (eza, bat, fd, rg, zoxide)
- ✅ Docker autocomplete
- ✅ VS Code configuration
- ✅ Project initialization status

**Output:**
- Color-coded results (✓ Pass, ✗ Fail, ⊘ Skip, ⚠ Warning)
- Detailed summary with percentages
- Log file: `.devcontainer/.log/test_suite.log`

**Exit Codes:**
- `0` - All tests passed
- `1` - One or more tests failed

### 2. Quick Health Check (`quick_test.sh`)

Fast health check for critical components.

**Usage:**
```bash
bash .devcontainer/scripts/tests/quick_test.sh
```

**What it checks:**
- DevContainer environment
- Claude Code CLI
- VS Code configuration
- Log directory
- CLAUDE.md template

**Output:**
- Quick pass/fail summary
- Runs in ~1 second

## 🎯 When to Run Tests

### After Container Creation

```bash
# Wait for initialization to complete, then run tests
bash .devcontainer/scripts/tests/run_tests.sh
```

### Quick Health Check

```bash
# Anytime you want to verify the setup
bash .devcontainer/scripts/tests/quick_test.sh
```

### Troubleshooting

```bash
# Run tests to identify issues
bash .devcontainer/scripts/tests/run_tests.sh

# Check detailed logs
cat .devcontainer/.log/test_suite.log
```

## 📊 Test Results Interpretation

### Passed (✓)
Feature installed and working correctly.

### Failed (✗)
Feature expected but not found or not working. Check:
1. Environment variables in `devcontainer.json`
2. Installation logs in `.devcontainer/.log/`
3. Script execution order in `post_create.sh`

### Skipped (⊘)
Feature disabled via environment variable - this is normal if intentional.

### Warning (⚠)
Optional feature or non-critical issue. May work as intended.

## 🔧 Environment-Based Testing

Tests automatically adapt to your configuration:

```json
// Example: Minimal setup
{
  "USE_CLAUDE_CODE": "false",
  "USE_GIT_PROMPT": "false",
  "USE_VSCODE_CONFIG": "true"
}
```

**Result:** Claude and Git tests will be skipped, VS Code tests will run.

## 📝 Test Categories

### 1. Environment Variables
- Validates required variables (`PROJECT_ROOT`, `DEVCONTAINER_SCRIPTS`)
- Reports optional variables (`PROJECT_NAME`)
- Shows all feature flags

### 2. Log Files
- Checks `.devcontainer/.log/` directory exists
- Verifies expected log files based on enabled features
- Reports missing logs (may indicate scripts haven't run)

### 3. Claude Code CLI
- Checks if `claude` command is available
- Verifies version can be retrieved
- Checks `CLAUDE.md` template creation

### 4. Claude Configuration
- **Direct Copy Mode**: Validates `.claude/` directory and subdirectories
- **Marketplace Mode**: Checks `~/.claude/settings.json` and marketplace registration

### 5. Git Prompt
- Verifies Oh My Zsh installation
- Checks Starship installation
- Validates `.zshrc` configuration

### 6. CLI Tools
- Tests each modern CLI tool (eza, bat, fd, rg, zoxide)
- Reports partial installations
- Shows tool descriptions

### 7. Docker Autocomplete
- Checks docker completion files
- Verifies docker-compose completion

### 8. VS Code Configuration
- Validates `.vscode/` directory
- Checks key files (settings.json, tasks.json, extensions.json)
- Verifies linting configs (.editorconfig, .prettierrc)
- Checks workspace file

### 9. Project Status
- Verifies project status file exists
- Checks initialization completion

## 🐛 Troubleshooting

### All Tests Failing

**Problem:** Most tests fail

**Solution:**
1. Ensure you're in the devcontainer
2. Wait for `post_create.sh` to complete
3. Check `project_status` file initialization status

### Specific Feature Tests Failing

**Problem:** One feature fails while others pass

**Solution:**
1. Check the feature's environment variable
2. Review the feature's log file in `.devcontainer/.log/`
3. Run the specific setup script manually:
   ```bash
   .devcontainer/scripts/setup/configure_claude.sh
   ```

### Tests Show "Skipped"

**Problem:** Many tests show as skipped

**Solution:** This is normal if you've disabled features via environment variables. Review your `devcontainer.json` configuration.

## 📚 Adding Custom Tests

To add your own tests, edit `run_tests.sh`:

```bash
# Add a new test section
print_header "X. My Custom Test"

if [ -f "/path/to/file" ]; then
    test_pass "My custom check passed"
else
    test_fail "My custom check failed" "Expected /path/to/file"
fi
```

## 🔗 Related Documentation

- [Environment Variables](../docs/environment-variables.md)
- [Script Best Practices](../docs/best-practices.md)
- [Troubleshooting](../../docs/troubleshooting.md)
- [Main README](../../README.md)

---

**Test Suite Version:** 1.0.0
