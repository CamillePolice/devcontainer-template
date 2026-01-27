# Troubleshooting

Common issues and solutions for devcontainer problems.

## 🐳 Container Issues

### Container Won't Start

**Symptoms:**
- Error message when opening container
- Container fails to build
- Timeout during startup

**Solutions:**

1. **Check Docker is running**
   ```bash
   docker ps
   ```

2. **Rebuild container**
   ```
   Ctrl+Shift+P → Dev Containers: Rebuild Container
   ```

3. **Check Docker resources**
   - Ensure Docker Desktop has enough memory (4GB+ recommended)
   - Check available disk space

4. **Clean Docker cache**
   ```bash
   docker system prune -a
   ```

5. **Check logs**
   ```
   Ctrl+Shift+P → Dev Containers: Show Container Log
   ```

---

### Container Starts But Errors in Scripts

**Check logs:**

```bash
# Post-create log
cat /tmp/project_init.log

# Init environment log
cat /tmp/project_init_env.log

# Docker startup log
cat /tmp/project_docker_startup.log

# Claude configuration log
cat /tmp/project_claude_config.log
```

**Common issues:**

- Network issues during package installation
- Permission problems
- Missing dependencies

**Solutions:**

1. **Re-run failed script**
   ```bash
   .devcontainer/scripts/lifecycle/post_create.sh
   ```

2. **Check internet connection**

3. **Check file permissions**
   ```bash
   ls -la /home/vscode/
   ```

---

## 🔑 SSH Keys

### SSH Keys Not Working

**Symptoms:**
- Can't git push/pull
- Permission denied errors
- SSH key not found

**Solutions:**

1. **Check SSH directory exists on host**
   ```bash
   ls -la ~/.ssh
   ```

2. **Check SSH key permissions**
   ```bash
   chmod 600 ~/.ssh/id_*
   chmod 644 ~/.ssh/*.pub
   chmod 700 ~/.ssh
   ```

3. **Verify keys copied to container**
   ```bash
   ls -la /home/vscode/.ssh/
   ```

4. **Re-run init script**
   ```bash
   .devcontainer/scripts/lifecycle/init_env.sh
   ```

5. **Test SSH connection**
   ```bash
   ssh -T git@github.com
   ```

---

## 🧩 Extensions

### Extensions Not Installing

**Symptoms:**
- Extensions missing in VS Code
- Extension installation hangs
- Extension errors on startup

**Solutions:**

1. **Rebuild container**
   ```
   Ctrl+Shift+P → Dev Containers: Rebuild Container
   ```

2. **Check extension IDs**
   - Verify IDs are correct in `devcontainer.json`
   - Check for typos

3. **Install manually**
   ```bash
   code --install-extension extension-id
   ```

4. **Check VS Code marketplace**
   - Ensure extension is available
   - Check for deprecated extensions

5. **Clear extension cache**
   ```bash
   rm -rf ~/.vscode-server/extensions/*
   ```

---

### Stack Extensions Not Installing

**Check script:**

```bash
.vscode/extensions/install_by_stack.sh --help
```

**Run manually:**

```bash
# Auto-detect and install
.vscode/extensions/install_by_stack.sh

# Specific stack
.vscode/extensions/install_by_stack.sh angular

# All extensions
.vscode/extensions/install_by_stack.sh all
```

---

## 📜 Script Failures

### Script Exits with Error

**Check which script failed:**

```bash
# View all logs
ls -lh /tmp/project_*.log

# Read specific log
cat /tmp/project_init.log
```

**Debug script:**

```bash
# Run with debug output
bash -x .devcontainer/scripts/lifecycle/post_create.sh
```

**Common issues:**

1. **Network timeouts** - Try again
2. **Permission denied** - Check file permissions
3. **Command not found** - Package not installed yet

---

### Scripts Skip Execution

**Check feature flags:**

```bash
# In container
echo $USE_CLAUDE_CODE
echo $USE_GIT_PROMPT
echo $USE_DOCKER_AUTOCOMPLETE
```

**Set in devcontainer.json:**

```json
"containerEnv": {
    "USE_CLAUDE_CODE": "true",
    "USE_GIT_PROMPT": "true",
    "USE_DOCKER_AUTOCOMPLETE": "true"
}
```

---

## 🎨 Shell & Prompt

### Prompt Not Showing Correctly

**Check Starship installation:**

```bash
which starship
starship --version
```

**Reinstall:**

```bash
.devcontainer/scripts/setup/configure_git_prompt.sh
```

**Check configuration:**

```bash
cat ~/.config/starship.toml
```

---

### Aliases Not Working

**Reload shell:**

```bash
source ~/.zshrc
```

**Check if Oh My Zsh is installed:**

```bash
ls -la ~/.oh-my-zsh
```

**Reinstall:**

```bash
.devcontainer/scripts/setup/configure_git_prompt.sh
```

---

## 🐳 Docker Compose

### Services Not Starting

**Check if docker-compose.yml exists:**

```bash
ls -la docker-compose.yml
```

**View docker startup log:**

```bash
cat /tmp/project_docker_startup.log
```

**Manual start:**

```bash
docker-compose up -d
```

**Check service logs:**

```bash
docker-compose logs
docker-compose logs service-name
```

---

## 🔧 Claude Code

### Claude Configuration Not Working

**Check if enabled:**

```bash
echo $USE_CLAUDE_CODE
```

**View log:**

```bash
cat /tmp/project_claude_config.log
```

**Check .claude folder:**

```bash
ls -la .claude/
```

**Re-run configuration:**

```bash
.devcontainer/scripts/setup/configure_claude.sh
```

---

### Marketplace Not Working

**Check settings file:**

```bash
cat ~/.claude/settings.json
```

**Manual marketplace setup:**

In Claude Code:
```
/plugin marketplace add affaan-m/everything-claude-code
/plugin install everything-claude-code@everything-claude-code
```

---

## 📋 Pre-commit Hooks

### Hooks Not Running

**Reinstall:**

```bash
pip install pre-commit
pre-commit install
pre-commit install --hook-type commit-msg
```

**Check installation:**

```bash
pre-commit --version
ls -la .git/hooks/
```

---

### Hook Failing

**Run with verbose:**

```bash
pre-commit run --all-files --verbose
```

**Skip temporarily:**

```bash
git commit --no-verify -m "message"
```

---

## 💻 Performance

### Container Slow

**Solutions:**

1. **Increase Docker resources**
   - Docker Desktop → Settings → Resources
   - Increase RAM to 6GB+
   - Increase CPUs to 4+

2. **Clean Docker**
   ```bash
   docker system prune -a --volumes
   ```

3. **Check host resources**
   - Close unnecessary applications
   - Check disk space

4. **Disable unused features**
   ```json
   "USE_CLAUDE_CODE": "false",
   "USE_GIT_PROMPT": "false"
   ```

---

## 🔄 Reset Everything

### Complete Reset

**Danger: This will delete all container data**

1. **Stop container**
   ```
   Ctrl+Shift+P → Dev Containers: Close Remote Connection
   ```

2. **Remove container and images**
   ```bash
   docker-compose down -v
   docker system prune -a --volumes
   ```

3. **Rebuild**
   ```
   Ctrl+Shift+P → Dev Containers: Rebuild Container
   ```

---

## 🆘 Still Having Issues?

1. **Check logs** - All scripts log to `/tmp/`
2. **Search issues** - GitHub repository issues
3. **Ask for help** - Create an issue with:
   - Log files
   - Steps to reproduce
   - Environment details

---

## 📚 Learn More

- [Dev Containers Documentation](https://code.visualstudio.com/docs/devcontainers/containers)
- [Docker Documentation](https://docs.docker.com/)
- [VS Code Troubleshooting](https://code.visualstudio.com/docs/supporting/troubleshoot)
