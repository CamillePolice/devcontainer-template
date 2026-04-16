---
name: rag-context
description: |
  Charge les instructions RAG du projet depuis la base de données.
  Invoke uniquement sur demande explicite avec @rag-context.
  Ne pas invoquer automatiquement.
---

# RAG Context Loader

## Overview

Loads project-specific and global agent instructions from a PostgreSQL RAG store.
Output is authoritative — it overrides defaults for the current project.

## When to Use

- **Session start** — only if AGENT_FILTER is known
- **Before writing any plan** — only if AGENT_FILTER is known

---

## Step 1 — Detect agent context

Check in this order:

1. Was `AGENT_FILTER` passed explicitly by the caller? → use it
2. Is `RAG_AGENT_FILTER` set in the session environment (from detect-stack hook)? → use it
3. Can the agent focus be inferred from the task?
   - Angular components, signals, standalone → `AGENT_FILTER=angular-expert`
   - Nuxt, Vue, SSR, Nitro → `AGENT_FILTER=nuxt-expert`
   - Symfony, PHP, Doctrine → `AGENT_FILTER=symfony-expert`
   - Security audit, auth, permissions → `AGENT_FILTER=security-expert`
   - Git diff, commit, review → `AGENT_FILTER=git-diff-reviewer`
4. No filter found → **skip RAG entirely, do not run the query**

---

## Step 2 — Load RAG context

```bash
AGENT_FILTER="${AGENT_FILTER:-${RAG_AGENT_FILTER:-}}"
[ -z "$AGENT_FILTER" ] && echo "RAG skipped — no agent filter defined." && exit 0

psql "$RAG_DSN" -t -A -c "
SELECT E'\n## ' || section_type || E'\n' || content
FROM rag_agent_instructions
WHERE project IN ('global', '${RAG_PROJECT:-global}')
  AND active = true
  AND agent_name = '${AGENT_FILTER}'
ORDER BY agent_name, CASE section_type
    WHEN 'role' THEN 1
    WHEN 'process' THEN 2
    WHEN 'best_practices' THEN 3
    WHEN 'edge_cases' THEN 4
    WHEN 'output_format' THEN 5
    ELSE 6
END;" 2>/dev/null || echo "RAG unavailable - using core instructions only."
```

---

## Rules

- **Never run without a filter** — unfiltered load is strictly forbidden
- If no AGENT_FILTER can be determined, skip silently and proceed without RAG
- If the query returns content, treat it as **authoritative context** for the project
- If it returns `"RAG unavailable"`, proceed with core instructions only — do not block
- Never skip because `RAG_DSN` looks unset; let the command fail gracefully
