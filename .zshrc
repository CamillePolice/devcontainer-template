# === PATH ===
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
export PATH="$PATH:/Applications/Cursor.app/Contents/Resources/app/bin"
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# === RAG ===
#export RAG_DSN=postgresql://postgres.qfkfrfjoxrgdvkrdtubc:6hDbJ#BaqafSAnpp@aws-1-eu-west-1.pooler.supabase.com:6543/postgres
export RAG_DSN=postgresql://postgres:6hDbJ#BaqafSAnpp@localhost:5435/rag
export RAG_PROJECT='global'
source /opt/homebrew/opt/nvm/nvm.sh

# === Oh My Zsh ===
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(
    git
    docker
    docker-compose
    node
    npm
    zsh-autosuggestions
    zsh-syntax-highlighting
    colored-man-pages
)
source $ZSH/oh-my-zsh.sh

# === Aliases — CLI modernes ===
alias ls='eza'
alias ls2='command ls'
alias ll='eza -lah --git'
alias lt='eza --tree --level=2'
alias cat='bat --paging=never'
alias cat2='command cat'
alias rgrep='rg'
alias rgrep2='command grep'
alias ffind='fd'
alias ffind2='command find'

# === Git ===
alias gsw='git switch'
alias gswc='git switch -c'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gb='git branch'
alias gco='git checkout'

# === Docker ===
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcb='docker compose build'
alias dcl='docker compose logs --tail=100'
alias dclf='docker compose logs -f'

# === XH ===
alias xhs='xh --https'

# === fzf ===
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ==== Lazygit ===
alias lg='lazygit'
lgs() {
  tmux split-window -h -c "${1:-.}" "lazygit"
}

# === fzf custom bindings ===
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -50'"
bindkey '^F' fzf-cd-widget

# === claude ===
alias toon='npx @toon-format/cli'
alias cccoi='clara onellm info'

ccco() {
  if [ -f .claude/.env ]; then
      local rag=$(grep RAG_PROJECT .claude/.env | cut -d= -f2)
      ZDOTDIR=/dev/null RAG_PROJECT="$rag" clara onellm claude-code --dangerously-skip-permissions "$@"
  else
      clara onellm claude-code --dangerously-skip-permissions "$@"
  fi
}

cccor() {
  if [ -f .claude/.env ]; then
      local rag=$(grep RAG_PROJECT .claude/.env | cut -d= -f2)
      ZDOTDIR=/dev/null RAG_PROJECT="$rag" clara onellm claude-code --dangerously-skip-permissions --resume "$@"
  else
      clara onellm claude-code --dangerously-skip-permissions --resume "$@"
  fi
}

review() {
  local base_dir="$HOME/.claude/reviews"
  local project="$1"

  # Couleurs
  local BOLD='\033[1m'
  local CYAN='\033[0;36m'
  local GREEN='\033[0;32m'
  local YELLOW='\033[0;33m'
  local DIM='\033[2m'
  local RESET='\033[0m'

  # Choix du projet
  if [[ -z "$project" ]]; then
    local projects=($(ls "$base_dir"))
    if [[ ${#projects[@]} -eq 0 ]]; then
      echo -e "${YELLOW}⚠ Aucun projet trouvé dans ~/.claude/reviews/${RESET}"
      return 1
    fi
    echo -e "\n${BOLD}${CYAN}📁 Projets disponibles${RESET}"
    echo -e "${DIM}─────────────────────${RESET}"
    local i=1
    for p in $projects; do
      echo -e "  ${CYAN}$i)${RESET} $p"
      ((i++))
    done
    echo -e "${DIM}─────────────────────${RESET}"
    echo -ne "${BOLD}Choix : ${RESET}"
    read choice
    project="${projects[$choice]}"
  fi

  local review_dir="$base_dir/$project"
  if [[ ! -d "$review_dir" ]]; then
    echo -e "${YELLOW}⚠ Projet '${project}' introuvable${RESET}"
    return 1
  fi

  # Choix de la review
  local files=($(ls "$review_dir"))
  if [[ ${#files[@]} -eq 0 ]]; then
    echo -e "${YELLOW}⚠ Aucune review trouvée pour '${project}'${RESET}"
    return 1
  fi

  echo -e "\n${BOLD}${GREEN}📝 Reviews — ${project}${RESET}"
  echo -e "${DIM}─────────────────────${RESET}"
  local j=1
  for f in $files; do
    echo -e "  ${GREEN}$j)${RESET} $f"
    ((j++))
  done
  echo -e "${DIM}─────────────────────${RESET}"
  echo -ne "${BOLD}Choix : ${RESET}"
  read choice

  local file="${files[$choice]}"
  echo -e "\n${DIM}Ouverture de ${file}...${RESET}"
  code "$review_dir/$file"
}

review-plan() {
  local base_dir="$HOME/.claude/plans"

  # Couleurs
  local BOLD='\033[1m'
  local CYAN='\033[0;36m'
  local GREEN='\033[0;32m'
  local YELLOW='\033[0;33m'
  local DIM='\033[2m'
  local RESET='\033[0m'

  # Liste des plans
  local files=($(ls "$base_dir" 2>/dev/null))
  if [[ ${#files[@]} -eq 0 ]]; then
    echo -e "${YELLOW}⚠ Aucun plan trouvé dans ~/.claude/plans/${RESET}"
    return 1
  fi

  echo -e "\n${BOLD}${CYAN}📋 Plans Claude Code${RESET}"
  echo -e "${DIM}─────────────────────${RESET}"
  local i=1
  for f in $files; do
    echo -e "  ${CYAN}$i)${RESET} $f"
    ((i++))
  done
  echo -e "${DIM}─────────────────────${RESET}"
  echo -ne "${BOLD}Choix : ${RESET}"
  read choice

  local file="${files[$(($choice-1))]}"
  if [[ -z "$file" ]]; then
    echo -e "${YELLOW}⚠ Choix invalide${RESET}"
    return 1
  fi

  echo -e "\n${DIM}Ouverture de ${file}...${RESET}"
  code "$base_dir/$file"
}

# ── direnv ──────────────────────────────────────────────────────────────────
eval "$(direnv hook zsh)"



# === Node Version Manager (NVM) ===
autoload -U add-zsh-hook
load-nvmrc() {
  local nvmrc_path="$(nvm_find_nvmrc)"
  if [ -n "$nvmrc_path" ]; then
    nvm use
  elif [ "$(nvm version)" != "$(nvm version default)" ]; then
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# === Starship ===
eval "$(starship init zsh)"

# === Gitlab Token ===
export GITLAB_NPM_TOKEN="m0lZKwODVJPlsX_Dxmx6g286MQp1Ojc4Ygk.01.0z0onwbxl"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/cpo/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# === Zoxide (smart cd) ===
# Must be at the end of zshrc to properly override cd alias
eval "$(zoxide init zsh)"
alias cd='z'
alias cd2='builtin cd'

# bun completions
[ -s "/Users/cpo/.bun/_bun" ] && source "/Users/cpo/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

alias claude-mem='bun "/Users/cpo/.claude/plugins/cache/thedotmack/claude-mem/10.6.2/scripts/worker-service.cjs"'

eval "$(direnv hook zsh)"
