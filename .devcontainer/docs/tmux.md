# Using tmux in this devcontainer

This devcontainer includes a tmux configuration for terminal multiplexing (mouse, vi copy mode, status bar, TPM plugins). Key bindings use tmux **defaults** (prefix **`Ctrl-b`**).

**Prefix key:** `Ctrl-b` (hold Control, press b). Every shortcut below that says “Prefix” means press `Ctrl-b` first, then the next key.

---

## Most common shortcuts

| Action | Keys |
|--------|------|
| **Prefix** | `Ctrl-b` |
| **Split horizontal** (panes side by side) | Prefix then `%` |
| **Split vertical** (panes stacked top/bottom) | Prefix then `"` |
| **New window** | Prefix then `c` |
| **Next window** | Prefix then `n` |
| **Previous window** | Prefix then `p` |
| **Switch to window by number** | Prefix then `0`–`9` |
| **Move focus to pane** | Prefix then arrow keys (or mouse click) |
| **Resize pane** | Drag the border with the **mouse**, or Prefix then `:` and run `resize-pane -L 5` (or `-R` / `-U` / `-D`) |
| **Copy mode** (scroll & copy) | Prefix then `[` → move with arrows → copy with plugin |
| **Paste** | Prefix then `]` |
| **Rename current window** | Prefix then `,` |
| **Detach** (leave tmux running) | Prefix then `d` |
| **Reload config** | Prefix then `:` then type `source-file ~/.tmux.conf` and Enter |
| **Save session** (resurrect) | Prefix then `Ctrl-s` |
| **Restore session** (resurrect) | Prefix then `Ctrl-r` |

---

## Restore a tmux session

- **Attach to an existing session** (e.g. after reconnecting to the devcontainer):
  ```bash
  tmux attach
  ```
  Or attach to a named session: `tmux attach -t session_name`. List sessions: `tmux ls`.

- **Save / restore layout (tmux-resurrect):**
  - **Save** current session (windows & panes layout): Prefix then **`Ctrl-s`**. A message confirms the save.
  - **Restore** last saved layout: Prefix then **`Ctrl-r`**. Restores next time you start tmux in that environment (e.g. after a reboot, start tmux and use Prefix `Ctrl-r`, or see continuum below).

- **Auto-restore (tmux-continuum):** The config has `@continuum-restore 'on'`, so when you **start tmux** (e.g. `tmux` or open a new terminal that runs tmux), the last saved state can be restored automatically if continuum has a saved state. Resurrect must have been used at least once (Prefix `Ctrl-s`) for there to be something to restore.

---

## Default config (how tmux loads your config)

Tmux loads **one** config file automatically when the server starts:

- **File:** `~/.tmux.conf` (in your home directory).
- **When:** Every time you run `tmux` (or the first time in a session), tmux reads this file. Changing it has no effect on already-running tmux until you reload it (Prefix `:` then `source-file ~/.tmux.conf`) or restart tmux.

To use this devcontainer’s config as your default:

1. Copy the repo config into your home (one-time):
   ```bash
   cp "$PROJECT_ROOT/.devcontainer/config/.tmux.conf" ~/.tmux.conf
   ```
2. Or run the setup script (also copies the config and installs TPM):
   ```bash
   .devcontainer/scripts/setup/install_tmux.sh
   ```

After that, every new tmux session will use this config by default.

---

## Installing tmux and plugins

### 1. Prerequisites

Inside the devcontainer, ensure **tmux** and **xclip** (for clipboard) are installed:

```bash
sudo apt-get update && sudo apt-get install -y tmux xclip
```

### 2. Use this config and install TPM

- **Copy the config** from the repo to your home:

  ```bash
  mkdir -p ~/.tmux
  cp "$PROJECT_ROOT/.devcontainer/config/.tmux.conf" ~/.tmux.conf
  ```

- **Clone TPM** once:

  ```bash
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  ```

- **Clone Catppuccin theme** once (status bar / appearance):

  ```bash
  mkdir -p ~/.config/tmux/plugins/catppuccin
  git clone -b v2.1.3 https://github.com/catppuccin/tmux.git \
    ~/.config/tmux/plugins/catppuccin/tmux
  ```

- **Install plugins** (no key binding by default): run once from a shell:

  ```bash
  ~/.tmux/plugins/tpm/bin/install_plugins
  ```

- Restart tmux so the config and plugins load.

### 3. Optional: automated setup

Run once (e.g. after rebuilding the devcontainer):

```bash
.devcontainer/scripts/setup/install_tmux.sh
```

Then run `~/.tmux/plugins/tpm/bin/install_plugins` and restart tmux.

---

## Plugins included

| Plugin | What it does |
|--------|----------------|
| **tmux-yank** | In copy mode, copy selection to system clipboard (needs `xclip`). |
| **tmux-resurrect** | Save/restore session (windows & panes). Check plugin docs for its key bindings (often Prefix `Ctrl-s` / `Ctrl-r`). |
| **tmux-continuum** | Auto-save and optional auto-restore on tmux start. |

Copy mode is **vi-style**: Prefix `[` to enter, then `v` to start selection, move, `y` to copy (with tmux-yank that goes to system clipboard). Prefix `]` to paste.

---

## Core concepts

- **Session** — One tmux “instance” (e.g. one dev session).
- **Window** — A tab inside a session (like browser tabs).
- **Pane** — A split inside a window.

---

## Copy mode (vi-style)

1. Enter copy mode: Prefix then `[`
2. Move: vi keys (`h`/`j`/`k`/`l`) or arrow keys
3. Start selection: `v`
4. Adjust: move cursor
5. Copy: `y` (exits copy mode; with tmux-yank, copies to system clipboard)
6. Paste: Prefix then `]`

---

## Mouse

Mouse is enabled: click to focus a pane, **drag borders to resize**, scroll to browse history.

---

## Quick reference (default bindings)

| Task | Keys |
|------|------|
| Prefix | `Ctrl-b` |
| Split horizontal (side by side) | `Ctrl-b` `%` |
| Split vertical (stacked) | `Ctrl-b` `"` |
| New window | `Ctrl-b` `c` |
| Next / previous window | `Ctrl-b` `n` / `Ctrl-b` `p` |
| Move focus to pane | `Ctrl-b` + arrow keys |
| Resize pane | Mouse drag on border, or Prefix `:` → `resize-pane -L 5` (etc.) |
| Copy mode | `Ctrl-b` `[` → `v` → move → `y` |
| Paste | `Ctrl-b` `]` |
| Rename window | `Ctrl-b` `,` |
| Detach | `Ctrl-b` `d` |
| Command prompt | `Ctrl-b` `:` |
| Save session (resurrect) | `Ctrl-b` `Ctrl-s` |
| Restore session (resurrect) | `Ctrl-b` `Ctrl-r` |
