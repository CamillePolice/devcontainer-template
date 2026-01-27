# Script Development Best Practices

Guidelines for developing and maintaining devcontainer scripts.

## General Principles

### 1. Idempotency
Scripts should be safe to run multiple times without causing issues.

**Good**:
```bash
if [ -d "$TARGET_DIR" ]; then
    log "Already exists, skipping"
    exit 0
fi
mkdir -p "$TARGET_DIR"
```

**Bad**:
```bash
mkdir "$TARGET_DIR"  # Fails if already exists
```

### 2. Proper Logging
Always log to a dedicated log file for troubleshooting.

**Good**:
```bash
# Create log directory if it doesn't exist
LOG_DIR="$PROJECT_ROOT/.devcontainer/.log"
mkdir -p "$LOG_DIR"

# Set up logging
LOGFILE="$LOG_DIR/script_name.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

function log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}
```

### 3. Error Handling
Exit with proper codes and provide helpful error messages.

**Good**:
```bash
if ! command; then
    log "ERROR: Command failed - <helpful context>"
    exit 1
fi
```

**Bad**:
```bash
command  # Continues even if it fails
```

### 4. Environment Variable Checks
Always provide defaults and check for feature flags.

**Good**:
```bash
USE_FEATURE="${USE_FEATURE:-true}"

if [ "$USE_FEATURE" != "true" ]; then
    log "Feature disabled (USE_FEATURE=false)"
    exit 0
fi
```

### 5. Path Resolution
Use environment variables for path resolution.

**Good**:
```bash
SCRIPT_DIR="${DEVCONTAINER_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
```

## Script Structure Template

```bash
#!/bin/bash

# Feature flag check (if applicable)
USE_FEATURE="${USE_FEATURE:-true}"

# Create log directory if it doesn't exist
LOG_DIR="$PROJECT_ROOT/.devcontainer/.log"
mkdir -p "$LOG_DIR"

# Set up logging
LOGFILE="$LOG_DIR/script_name.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

function log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check if feature is enabled
if [ "$USE_FEATURE" != "true" ]; then
    log "Feature disabled (USE_FEATURE=false)"
    exit 0
fi

# Path resolution (if needed)
SCRIPT_DIR="${DEVCONTAINER_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

log "=== Starting script execution ==="

# Enable debug mode (optional, for troubleshooting)
set -x

# Main logic here
if [ -d "$TARGET" ]; then
    log "Already configured, skipping"
    exit 0
fi

if ! do_something; then
    log "ERROR: Failed to do something"
    exit 1
fi

log "=== Script completed successfully ==="
log "Log file available at: $LOGFILE"

set +x  # Disable debug mode
```

## Naming Conventions

### Script Files
- Use snake_case: `configure_git_prompt.sh`
- Be descriptive: `install_cli_tools.sh` not `tools.sh`
- Include action verb: `configure_`, `install_`, `start_`

### Functions
- Use snake_case: `install_package()`
- Be specific: `check_docker_installed()` not `check()`

### Variables
- Use UPPER_SNAKE_CASE for environment variables: `USE_CLAUDE_CODE`
- Use snake_case for local variables: `temp_dir`
- Use descriptive names: `config_file` not `f`

## Script Organization

### When to Create New Scripts

Create a new script when:
1. Logic is complex enough to be reusable
2. It performs a distinct, separable function
3. It might need independent testing
4. It should be optional/toggleable

### Directory Placement

```
scripts/
├── lifecycle/       # Container lifecycle hooks
│                    # - Triggered by devcontainer events
│                    # - Examples: post_create, init_env
│
├── setup/          # One-time setup scripts
│                    # - Install/configure features
│                    # - Examples: install tools, setup prompts
│
├── config/         # Configuration scripts
│                    # - Can run multiple times safely
│                    # - Examples: autocomplete, aliases
│
├── tests/          # Test scripts
│                    # - Validate script functionality
│
└── docs/           # Documentation
                     # - Detailed guides and references
```

## Testing

### Manual Testing
```bash
# Test with feature disabled
USE_FEATURE=false .devcontainer/scripts/category/script.sh

# Test syntax
bash -n .devcontainer/scripts/category/script.sh

# Test with debug output
bash -x .devcontainer/scripts/category/script.sh
```

### Automated Testing
Create test scripts in `scripts/tests/`:

```bash
#!/bin/bash

echo "=== Testing script_name.sh ==="

# Test 1: Check syntax
bash -n script_name.sh && echo "✓ Syntax valid" || echo "✗ Syntax error"

# Test 2: Check feature flag
USE_FEATURE=false script_name.sh 2>&1 | grep -q "disabled" && \
    echo "✓ Feature flag works" || echo "✗ Feature flag broken"

# Test 3: Check idempotency
script_name.sh && script_name.sh && \
    echo "✓ Idempotent" || echo "✗ Not idempotent"
```

## Documentation

### Script Header Comments
```bash
#!/bin/bash
#
# Script: configure_claude.sh
# Purpose: Configure Claude Code with agents, skills, and commands
# Environment Variables:
#   - USE_CLAUDE_CODE: Master toggle (default: true)
#   - USE_CLAUDE: Enable direct copy (default: true)
#   - USE_CLAUDE_MARKETPLACE: Enable marketplace (default: true)
# Log File: .devcontainer/.log/claude_config.log
```

### Function Documentation
```bash
# Install a package if not already installed
# Args:
#   $1 - Package name
# Returns:
#   0 if installed or already exists
#   1 if installation failed
function install_package() {
    local package="$1"
    # ... implementation
}
```

## Performance Considerations

### 1. Minimize External Commands
**Good**:
```bash
if [ -f "$file" ]; then
```

**Bad**:
```bash
if test -f "$file"; then
```

### 2. Use Built-in Commands
**Good**:
```bash
dirname=$(dirname "$path")
```

**Bad**:
```bash
dirname=$(echo "$path" | sed 's|/[^/]*$||')
```

### 3. Avoid Unnecessary Subshells
**Good**:
```bash
cd "$dir" || exit 1
```

**Bad**:
```bash
(cd "$dir" && do_something)
```

## Security

### 1. Quote Variables
**Good**:
```bash
cp "$source_file" "$dest_dir"
```

**Bad**:
```bash
cp $source_file $dest_dir  # Breaks with spaces
```

### 2. Validate Input
```bash
if [ -z "$REQUIRED_VAR" ]; then
    log "ERROR: REQUIRED_VAR not set"
    exit 1
fi
```

### 3. Use Absolute Paths
```bash
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"  # Absolute
# Not: PROJECT_ROOT="../.."  # Relative
```

## Debugging

### Enable Debug Mode
```bash
set -x  # Enable
# ... commands to debug
set +x  # Disable
```

### Check Variable Values
```bash
log "DEBUG: USE_FEATURE=$USE_FEATURE"
log "DEBUG: SCRIPT_DIR=$SCRIPT_DIR"
log "DEBUG: PROJECT_ROOT=$PROJECT_ROOT"
```

### Check Exit Codes
```bash
command
log "Command exit code: $?"
```

### Read Log Files
```bash
cat .devcontainer/.log/project_init.log
tail -f .devcontainer/.log/project_init.log  # Follow live
```

## Common Pitfalls

### 1. Not Handling Spaces in Paths
Always quote variables containing paths.

### 2. Hardcoding Paths
Use environment variables and path resolution.

### 3. Not Checking Exit Codes
Always check if critical commands succeeded.

### 4. Missing Shebang
Always start scripts with `#!/bin/bash`.

### 5. Not Making Scripts Executable
Remember: `chmod +x script.sh`

### 6. Assuming Working Directory
Always use absolute paths or change directory explicitly.

## Maintenance

### Regular Review
- Review logs periodically for errors
- Update scripts when dependencies change
- Test scripts after major system updates

### Version Control
- Commit scripts with descriptive messages
- Document breaking changes
- Tag releases when making major changes

### Deprecation
When deprecating a script:
1. Add deprecation warning to log output
2. Update documentation
3. Remove after reasonable transition period
