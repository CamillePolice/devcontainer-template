# Customization Guide

Customize your devcontainer to fit your project's needs.

## 🌍 Environment Variables

Add custom environment variables in `devcontainer.json`:

```json
"containerEnv": {
    "MY_VARIABLE": "value",
    "API_URL": "https://api.example.com",
    "DEBUG_MODE": "true"
}
```

### Access in Scripts

```bash
echo $MY_VARIABLE
```

### Access in Code

**Node.js:**
```javascript
process.env.MY_VARIABLE
```

**Python:**
```python
import os
os.environ.get('MY_VARIABLE')
```

---

## 🧩 VS Code Extensions

Add extensions to `devcontainer.json`:

```json
"customizations": {
    "vscode": {
        "extensions": [
            "publisher.extension-name"
        ]
    }
}
```

### Find Extension ID

1. Open VS Code Marketplace
2. Search for extension
3. Copy the ID from the extension page URL

Or use Command Palette:
```
Extensions: Show Installed Extensions
```

---

## 🐳 Container Image

### Modify Dockerfile

Edit `.devcontainer/Dockerfile`:

```dockerfile
# Install additional packages
RUN apt-get update && apt-get install -y \
    package-name \
    another-package

# Install global npm packages
RUN npm install -g package-name

# Set custom environment variables
ENV MY_VAR=value
```

### Change Base Image

In `devcontainer.json`:

```json
"build": {
    "dockerfile": "Dockerfile",
    "args": {
        "VARIANT": "3.14"
    }
}
```

### Rebuild Container

After changes:

```
Ctrl+Shift+P → Dev Containers: Rebuild Container
```

---

## 📜 Initialization Scripts

### One-time Setup

Edit `.devcontainer/scripts/lifecycle/post_create.sh`:

```bash
log "Installing custom tools"
npm install -g your-tool

log "Configuring custom settings"
echo "alias myalias='command'" >> ~/.zshrc
```

### Every Start

Edit `.devcontainer/scripts/lifecycle/init_env.sh`:

```bash
log "Refreshing custom configuration"
source ~/.custom_config
```

---

## 🔌 Ports

### Forward Additional Ports

In `devcontainer.json`:

```json
"forwardPorts": [
    8080,
    8081,
    3000,  // Add your port
    5432   // Add another port
],
"portsAttributes": {
    "3000": {
        "label": "Frontend",
        "onAutoForward": "notify"
    }
}
```

---

## 💾 Volumes

### Mount Additional Volumes

In `devcontainer.json`:

```json
"runArgs": [
    "--mount",
    "type=bind,source=/host/path,target=/container/path"
]
```

### Create Named Volumes

```json
"runArgs": [
    "--mount",
    "type=volume,source=my_volume,target=/container/path"
]
```

---

## 🎨 Shell Configuration

### Add Custom Aliases

In `.devcontainer/scripts/setup/install_cli_tools.sh`:

```bash
cat >> ~/.zshrc << 'EOF'
# Custom aliases
alias dev='npm run dev'
alias test='npm run test'
alias deploy='./deploy.sh'
EOF
```

### Configure Starship Prompt

Edit `~/.config/starship.toml`:

```toml
[character]
success_symbol = "[➜](bold green)"
error_symbol = "[✗](bold red)"

[directory]
truncation_length = 3
truncate_to_repo = false
```

---

## 🔧 Git Configuration

### Custom Git Settings

In `.devcontainer/scripts/lifecycle/init_env.sh`:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global core.editor "code --wait"
git config --global alias.st "status"
```

---

## 📦 Node.js Configuration

### Change Node Version

Edit `devcontainer.json` features:

```json
"features": {
    "ghcr.io/devcontainers/features/node:1": {
        "version": "20"  // Change version
    }
}
```

### Add Global Packages

In `post_create.sh`:

```bash
npm install -g \
    typescript \
    nodemon \
    pm2
```

---

## 🐍 Python Configuration

### Change Python Version

Edit `devcontainer.json` features:

```json
"features": {
    "ghcr.io/devcontainers/features/python:1": {
        "version": "3.11"  // Change version
    }
}
```

### Add Python Packages

In `post_create.sh`:

```bash
pip install \
    flask \
    django \
    requests
```

---

## 🎯 Feature Toggles

Disable features via environment variables:

```json
"containerEnv": {
    "USE_CLAUDE_CODE": "false",        // Disable Claude
    "USE_GIT_PROMPT": "false",          // Disable custom prompt
    "USE_DOCKER_AUTOCOMPLETE": "false"  // Disable Docker completion
}
```

---

## 🔄 Apply Changes

### Rebuild Container

For Dockerfile or feature changes:

```
Ctrl+Shift+P → Dev Containers: Rebuild Container
```

### Reload Window

For config-only changes:

```
Ctrl+Shift+P → Developer: Reload Window
```

### Re-run Scripts

```bash
# Re-initialize environment
.devcontainer/scripts/lifecycle/init_env.sh

# Re-configure specific feature
.devcontainer/scripts/setup/configure_git_prompt.sh
```

---

## 📚 Best Practices

1. **Document Changes** - Add comments explaining customizations
2. **Test Changes** - Rebuild and test before committing
3. **Version Control** - Commit configuration changes
4. **Team Communication** - Inform team of major changes
5. **Keep It Simple** - Avoid over-customization

---

## 💡 Examples

### Add Redis

```json
// devcontainer.json
"features": {
    "ghcr.io/devcontainers-contrib/features/redis-server:1": {}
}
```

### Add PostgreSQL

```json
// devcontainer.json
"features": {
    "ghcr.io/devcontainers/features/postgres:1": {
        "version": "15"
    }
}
```

### Add Custom Tool

```bash
# post_create.sh
log "Installing custom tool"
curl -sSL https://example.com/install.sh | bash
```

---

## 📚 Learn More

- [Dev Container Features](https://containers.dev/features)
- [Dev Container Specification](https://containers.dev/implementors/spec/)
- [Docker Documentation](https://docs.docker.com/)
