#!/usr/bin/env bash
# toon-rewrite: converts JSON file reads to TOON format for token savings
# Intercepts: cat file.json / jq . file.json

if ! command -v jq &>/dev/null; then exit 0; fi
if ! command -v toon &>/dev/null; then exit 0; fi

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$CMD" ] && exit 0

# Détecte: cat file.json ou jq . file.json
JSON_FILE=$(echo "$CMD" | grep -oP '(?<=cat\s)[\w./\-]+\.json|(?<=jq\s\.\s)[\w./\-]+\.json' | head -1)

[ -z "$JSON_FILE" ] && exit 0
[ ! -f "$JSON_FILE" ] && exit 0

# Seuil : seulement si > 2KB
[ "$(wc -c < "$JSON_FILE")" -lt 2000 ] && exit 0

# Conversion TOON
TOON_OUT=$(toon "$JSON_FILE" 2>/dev/null)
[ -z "$TOON_OUT" ] && exit 0

# Réécrit la commande en echo du résultat TOON
REWRITTEN="echo $(printf '%q' "$TOON_OUT")"

ORIGINAL_INPUT=$(echo "$INPUT" | jq -c '.tool_input')
UPDATED_INPUT=$(echo "$ORIGINAL_INPUT" | jq --arg cmd "$REWRITTEN" '.command = $cmd')

jq -n \
  --argjson updated "$UPDATED_INPUT" \
  '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "allow",
      "permissionDecisionReason": "TOON auto-rewrite",
      "updatedInput": $updated
    }
  }'
