#!/bin/bash

# Usage: ./install-extensions.sh [--editor cursor|code] [--profile NomDuProfil]
EDITOR_CMD=""
PROFILE=""

# Parsing des arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --editor) EDITOR_CMD="$2"; shift ;;
        --profile) PROFILE="$2"; shift ;;
        *) echo "Option inconnue: $1"; exit 1 ;;
    esac
    shift
done

# Auto-détection si pas spécifié
if [ -z "$EDITOR_CMD" ]; then
    if command -v cursor &> /dev/null; then
        EDITOR_CMD="cursor"
    elif command -v code &> /dev/null; then
        EDITOR_CMD="code"
    else
        echo "❌ Ni 'cursor' ni 'code' trouvé dans le PATH"
        echo "💡 Usage: ./install-extensions.sh --editor cursor|code [--profile NomDuProfil]"
        exit 1
    fi
fi

echo "🚀 Installation des extensions avec : $EDITOR_CMD"
[ -n "$PROFILE" ] && echo "👤 Profil : $PROFILE"
echo ""

EXTENSIONS=(
    # Core Development
    "anthropic.claude-code"
    "github.vscode-pull-request-github"
    # Code Quality
    "editorconfig.editorconfig"
    "esbenp.prettier-vscode"
    "dbaeumer.vscode-eslint"
    "streetsidesoftware.code-spell-checker"
    "usernamehw.errorlens"
    # Git
    "eamodio.gitlens"
    "mhutchie.git-graph"
    "gitlab.gitlab-workflow"
    "codezombiech.gitignore"
    # Docker
    "ms-azuretools.vscode-docker"
    # Utilities
    "aaron-bond.better-comments"
    "alefragnani.bookmarks"
    "gruntfuggly.todo-tree"
    "christian-kohler.path-intellisense"
    "formulahendry.auto-close-tag"
    "formulahendry.auto-rename-tag"
    "vincaslt.highlight-matching-tag"
    "chakrounanas.turbo-console-log"
    "wix.vscode-import-cost"
    # Visuals
    "johnpapa.vscode-peacock"
    "pkief.material-icon-theme"
    "pkief.material-product-icons"
    "zhuangtongfa.material-theme"
    "naumovs.color-highlight"
    "oderwat.indent-rainbow"
    # File Support
    "mikestead.dotenv"
    "redhat.vscode-yaml"
    "redhat.vscode-xml"
    "dotjoshjohnson.xml"
    "tamasfe.even-better-toml"
    # Documentation
    "yzhang.markdown-all-in-one"
    "yzane.markdown-pdf"
    "hediet.vscode-drawio"
    # REST Client
    "humao.rest-client"
    "rangav.vscode-thunder-client"
    # Database
    "mtxr.sqltools"
    # SSH
    "cweijan.vscode-ssh"
    # Miscellaneous
    "cweijan.vscode-office"
    "ibm.output-colorizer"
    "softwaredotcom.swdc-vscode"
)

TOTAL=${#EXTENSIONS[@]}
COUNT=0
FAILED=()

# Construction des arguments supplémentaires
EXTRA_ARGS=()
if [[ "$EDITOR_CMD" == *"Visual Studio Code"* ]]; then
    EXTRA_ARGS+=("--extensions-dir" "$HOME/.vscode/extensions")
fi
if [ -n "$PROFILE" ]; then
    EXTRA_ARGS+=("--profile" "$PROFILE")
fi

for EXT in "${EXTENSIONS[@]}"; do
    COUNT=$((COUNT + 1))
    echo "[$COUNT/$TOTAL] Installation de $EXT..."
    if "$EDITOR_CMD" "${EXTRA_ARGS[@]}" --install-extension "$EXT" --force &> /dev/null; then
        echo "  ✅ OK"
    else
        echo "  ❌ Échec"
        FAILED+=("$EXT")
    fi
done

echo ""
echo "================================"
echo "✅ Terminé : $((TOTAL - ${#FAILED[@]}))/$TOTAL extensions installées"

if [ ${#FAILED[@]} -gt 0 ]; then
    echo ""
    echo "❌ Extensions en échec :"
    for EXT in "${FAILED[@]}"; do
        echo "  - $EXT"
    done
fi