# RAG (Retrieval-Augmented Generation)

This document describes the RAG-First architecture: storing agent instructions in **Supabase** (pgvector) so Claude Code can retrieve them at runtime, enabling lightweight agent files (~30 lines) with rich knowledge stored in the cloud.

## Architecture Overview

```
.claude/agents/angular-expert.md    (~30 lines bootstrap)
    │
    └── psql "$RAG_DSN" → Supabase ──► 16 sections loaded on demand
                                        (best_practices, process, reference, role...)

Learned-skills auto-captured by capture-learning skill
    └── project='global'   → available in ALL projects
    └── project='opvigil'  → available in OPVigil only
```

If RAG is disabled or the connection fails, agents fall back to their local bootstrap content only.

---

## Environment Variables

Configure in `devcontainer.json` and/or on the host (`~/.zshrc`):

| Variable        | Required | Description                                                                                          |
| --------------- | -------- | ---------------------------------------------------------------------------------------------------- |
| `USE_RAG`     | No       | Set to `"true"` to enable RAG. Default: `false`.                                                    |
| `RAG_DSN`     | Yes*     | PostgreSQL connection string for Supabase. Lives on the **host** only, never in the repo.           |
| `RAG_PROJECT` | No       | Project name for scoping (e.g. `opvigil`, `archforge`). Defaults to `PROJECT_NAME` or `global`.    |

* Required only when `USE_RAG=true`.

### Host setup (`~/.zshrc`)

```bash
export RAG_DSN="postgresql://postgres.[ref]:[password]@aws-1-eu-west-1.pooler.supabase.com:6543/postgres"
```

### devcontainer.json

```jsonc
"containerEnv": {
    "RAG_DSN": "${localEnv:RAG_DSN}"
},
"runArgs": [
    "--env-file", "${localWorkspaceFolder}/.devcontainer/.env"
]
```

### .devcontainer/.env (gitignored, local only)

```bash
USE_RAG=true
RAG_PROJECT=opvigil   # or archforge, global, etc.
```

---

## Supabase Schema

```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE rag_agent_instructions (
    id            BIGSERIAL PRIMARY KEY,
    agent_name    TEXT NOT NULL,
    project       TEXT DEFAULT 'global',
    section_type  TEXT NOT NULL,
    section_title TEXT,
    content       TEXT NOT NULL,
    embedding     vector(1536),
    metadata      JSONB DEFAULT '{}',
    active        BOOLEAN DEFAULT true,
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    expires_at    TIMESTAMPTZ
);

CREATE INDEX idx_rai_agent ON rag_agent_instructions(agent_name, project, active);
CREATE INDEX idx_rai_embedding ON rag_agent_instructions
    USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

CREATE VIEW rag_audit AS
SELECT project, agent_name, COUNT(*) as sections,
       array_agg(DISTINCT section_type ORDER BY section_type) as types,
       MAX(created_at) as last_updated
FROM rag_agent_instructions WHERE active = true
GROUP BY project, agent_name ORDER BY project, sections DESC;
```

---

## Scripts

| Script                      | When                                    | Purpose                                                                                                 |
| --------------------------- | --------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| **setup_rag.sh**            | At devcontainer init (post_create)      | Verifies Supabase connection; installs `psql` if needed. Non-blocking on failure.                      |
| **setup_editor_rag_mcp.sh** | At devcontainer init (post_create)      | When `USE_RAG=true`: installs MCP server deps, copies Cursor/VSCode MCP config and editor rules.        |
| **seed_rag.py**             | Manual, after adding/updating knowledge | Indexes `.md` and `.py` files into `rag_agent_instructions`. Generic script usable for any project.    |

Paths:

* `.devcontainer/scripts/ai/setup_rag.sh`
* `.devcontainer/scripts/ai/setup_editor_rag_mcp.sh`
* `.devcontainer/scripts/ai/seed_rag.py`

---

## Editor MCP (Cursor / VSCode)

When `USE_RAG=true`, the devcontainer configures an **MCP (Model Context Protocol) server** so Cursor or VS Code can call the RAG knowledge base directly. No need to run `psql` from the editor — the AI uses MCP tools.

### Layout

All RAG MCP assets live under `.devcontainer/mcp/rag/`:

| File                          | Purpose                                                                 |
| ----------------------------- | ----------------------------------------------------------------------- |
| `mcp-rag-server.js`           | Node.js MCP server (Supabase/pg); exposes tools to the editor.         |
| `cursor-mcp.json`             | Cursor MCP config template (copied to `.cursor/mcp.json` if missing).   |
| `vscode-mcp.json`             | VS Code MCP config template (copied to `.vscode/mcp.json` if missing).  |
| `rag-cursor-rules.mdc`        | Cursor rules for when to call RAG tools (→ `.cursor/rules-rag.mdc`).    |
| `rag-copilot-instructions.md` | GitHub Copilot instructions (→ `.github/copilot-instructions.md`).      |
| `package.json`                | Node deps for the server (e.g. `pg`).                                  |

### Environment

| Variable       | Description                                                                                          |
| -------------- | ---------------------------------------------------------------------------------------------------- |
| `USE_RAG`      | Must be `"true"` for the MCP setup to run.                                                           |
| `WHICH_EDITOR` | `cursor` \| `vscode` \| `both`. Chooses which editor gets the MCP config. Default: `cursor`.        |

Set in `.devcontainer/.env` (see `.env.example`). `RAG_DSN` and `RAG_PROJECT` are passed to the MCP server via the copied config.

### MCP tools

Once configured, the editor can use:

| Tool                | Description                                              |
| ------------------- | -------------------------------------------------------- |
| `rag_load`          | Load agent instructions from Supabase for a given agent/project. |
| `rag_save_learning` | Persist a learned skill to Supabase (e.g. from capture-learning). |
| `rag_audit`         | List indexed agents and section counts.                 |
| `rag_search`        | Keyword search across RAG sections.                     |

Logs: `.devcontainer/.log/editor_mcp.log`

---

## seed_rag.py — Generic Indexing Script

Replaces the old `seed_archforge_rag.py`. Works for any project.

```bash
# Index a single file
RAG_PROJECT="global" python3 seed_rag.py --file angular-expert-rag.md --agent angular-expert

# Index multiple files in one pass (recommended for multi-source agents)
RAG_PROJECT="global" python3 seed_rag.py \
  --files SKILL.md security-expert-rag.md \
  --agent security-expert

# Add a file to an existing agent without touching other sections
RAG_PROJECT="global" python3 seed_rag.py \
  --file new-knowledge.md --agent security-expert --append

# Index a full directory for an agent
RAG_PROJECT="archforge" python3 seed_rag.py --dir . --agent archforge

# Preview without writing
python3 seed_rag.py --dir . --agent archforge --dry-run --preview

# Reindex after source changes (wipes and re-inserts everything)
RAG_PROJECT="global" python3 seed_rag.py \
  --files SKILL.md security-expert-rag.md \
  --agent security-expert --force
```

### Flags

| Flag          | Description                                                                                  |
| ------------- | -------------------------------------------------------------------------------------------- |
| `--file`      | Index a single file.                                                                         |
| `--files`     | Index multiple files in one pass. `--force` runs once before inserting all files.           |
| `--dir`       | Index a full directory recursively.                                                          |
| `--force`     | Deactivate **all** existing sections for the agent before reinserting. Use for full reindex. |
| `--append`    | Insert without touching existing sections. Use to add a new file to an existing agent.      |
| `--dry-run`   | Parse and preview without writing to the database.                                           |
| `--preview`   | Show detail of parsed sections (combine with `--dry-run`).                                   |

> `--force` and `--append` are mutually exclusive.

### What gets indexed

* `*.md` files → split into semantic sections by H2/H3/H4 headings
* `*.py` files → indexed as a single `reference` section (full source code)
* `README.md` and `seed_rag.py` → always ignored
* `.git`, `node_modules`, `__pycache__`, `.devcontainer`, `.venv`, `.claude` → always ignored

### Section type inference

The script infers `section_type` automatically from section titles:

| Pattern in title                                          | section_type       |
| --------------------------------------------------------- | ------------------ |
| role, overview, objectif                                  | `role`             |
| step N, phase N, étape N, prompt N, workflow              | `process`          |
| language detection, criticality tier, anti-hallucination  | `process`          |
| conflict resolution, security theater, exception mgmt     | `process`          |
| best practices, règles, standards, ai-rules               | `best_practices`   |
| SBD-N, input valid, authenticat, cryptograph, rate limit  | `best_practices`   |
| layer N (SecureByDesign control groups)                   | `best_practices`   |
| edge case, fallback, gotcha, false positive               | `edge_cases`       |
| output, livrables, audit report, red flags                | `output_format`    |
| standards mapping, compliance matrix                      | `output_format`    |
| prérequis, installation, stack, architecture, owasp, nist | `reference`        |

#### H4 support

For large sections (> 4000 chars), the script now descends to H4 level. This allows proper splitting of deeply structured documents like SecureByDesign's 26 controls (each defined as `#### SBD-XX`).

### Indexation report

The report now shows sections **deactivated** by type when using `--force`, making it easy to compare before/after:

```
🗑  22 section(s) précédentes désactivées :
   - best_practices                    1
   - output_format                     1
   - process                           8
   - reference                        11
   - role                              1
✅ 38 section(s) insérées dans Supabase
```

---

## Project Scoping

Agents query both `global` and project-specific knowledge:

```sql
WHERE agent_name = 'angular-expert'
  AND project IN ('global', 'opvigil')
  AND active = true
```

This means:

* `project='global'` → available in **all** projects (generic patterns)
* `project='opvigil'` → available **only** in OPVigil (project-specific conventions)

### Current knowledge base

| project   | agent_name      | sections |
| --------- | --------------- | -------- |
| archforge | archforge       | 197      |
| global    | angular-expert  | 16       |
| global    | symfony-expert  | 7        |
| global    | security-expert | 38       |

---

## RAG-First Agent Format

Agents in `.claude/agents/` are lightweight (~30 lines). They load their knowledge from Supabase at runtime:

```markdown
---
name: angular-expert
description: Expert Angular developer for Angular 17-20 migrations and modern patterns.
model: sonnet
tools: [Read, Grep, Bash]
---

You are an expert Angular developer...

## Load Instructions
```bash
psql "$RAG_DSN" -t -A -c "
SELECT E'\n## ' || section_type || E'\n' || content
FROM rag_agent_instructions
WHERE agent_name = 'angular-expert'
  AND project IN ('global', '${RAG_PROJECT:-global}')
  AND active = true
ORDER BY CASE section_type
    WHEN 'role' THEN 1 WHEN 'process' THEN 2
    WHEN 'best_practices' THEN 3 ELSE 4
END;" 2>/dev/null || echo "RAG unavailable - using core instructions only."
```

## Learning Protocol

```bash
echo "[pattern] <discovery>" >> /tmp/learning-notes.md
echo "[gotcha] <edge case>" >> /tmp/learning-notes.md
```

After task completion, invoke the `capture-learning` skill.
```

### Multi-source agents

An agent can be fed from multiple files. Index them all in one pass with `--files`:

```bash
# security-expert loads both the SecureByDesign skill and its own RAG knowledge
RAG_PROJECT="global" python3 seed_rag.py \
  --files SKILL.md security-expert-rag.md \
  --agent security-expert

# Later, add new knowledge without touching the existing sections
RAG_PROJECT="global" python3 seed_rag.py \
  --file new-patterns.md --agent security-expert --append
```

---

## capture-learning Skill

Located at `.claude/skills/capture-learning/SKILL.md`.

After each non-trivial task, the active agent evaluates its discoveries and persists reusable knowledge to Supabase.

### Global vs Project scope decision

| Discovery type                   | Scope          | Example                                         |
| -------------------------------- | -------------- | ----------------------------------------------- |
| Generic Angular pattern          | `global`       | `linkedSignal` for dependent state              |
| Generic Symfony/PHP pattern      | `global`       | `(int)` cast for ID parameters                  |
| Generic security pattern         | `global`       | JWT storage gotcha, CORS false positive          |
| Project-specific convention      | `$RAG_PROJECT` | `HttpWrapperService` impl in OPVigil            |
| Project-specific bug/behavior    | `$RAG_PROJECT` | `SpcRepository` expects int not string          |
| Tooling/workflow pattern         | `global`       | `seed_rag.py --files` for multi-source agents   |

**When in doubt → `global`.** A generic pattern locked in a project scope is a missed reuse opportunity.

### Agent name for learned-skills

- Angular discoveries → `angular-expert`
- Symfony/PHP discoveries → `symfony-expert`
- Security discoveries → `security-expert`
- Project-specific conventions → `<agent-name>` with `project='$RAG_PROJECT'`
- Cross-cutting knowledge → `learned-<descriptive-slug>`

---

## Workflow

### 1. Verify connection

```bash
.devcontainer/scripts/ai/setup_rag.sh
```

### 2. Check current state

```bash
psql "$RAG_DSN" -c "SELECT * FROM rag_audit;"
```

### 3. Index new knowledge

```bash
# New single-source agent
RAG_PROJECT="global" python3 seed_rag.py --file my-agent-rag.md --agent my-agent

# New multi-source agent (skill + knowledge file)
RAG_PROJECT="global" python3 seed_rag.py \
  --files SKILL.md my-agent-rag.md --agent my-agent

# Add a file to an existing agent
RAG_PROJECT="global" python3 seed_rag.py \
  --file extra-knowledge.md --agent my-agent --append

# Full project reindex
RAG_PROJECT="archforge" python3 seed_rag.py --dir . --agent archforge --force
```

### 4. Remove an agent from the database

```bash
# Soft delete (reversible — sets active=false)
psql "$RAG_DSN" -c "
UPDATE rag_agent_instructions SET active = false
WHERE agent_name = 'my-agent' AND project = 'global';"

# Hard delete (irreversible)
psql "$RAG_DSN" -c "
DELETE FROM rag_agent_instructions
WHERE agent_name = 'my-agent' AND project = 'global';"
```

### 5. Test an agent query

```bash
psql "$RAG_DSN" -t -A -c "
SELECT section_type, section_title
FROM rag_agent_instructions
WHERE agent_name = 'security-expert'
  AND project = 'global'
  AND active = true
ORDER BY section_type, section_title;"
```

### 6. Inspect section distribution

```bash
psql "$RAG_DSN" -c "
SELECT section_type, COUNT(*) as nb, SUM(length(content)) as total_chars
FROM rag_agent_instructions
WHERE agent_name = 'security-expert' AND active = true
GROUP BY section_type ORDER BY nb DESC;"
```

---

## Files

```
.devcontainer/
├── devcontainer.json              # RAG_DSN via ${localEnv:RAG_DSN}
├── .env                           # USE_RAG, RAG_PROJECT, WHICH_EDITOR (gitignored)
├── .env.example                   # Template (committed)
├── mcp/
│   └── rag/                       # RAG MCP server and editor configs
│       ├── mcp-rag-server.js      # Node MCP server (Supabase)
│       ├── cursor-mcp.json        # Cursor MCP config template
│       ├── vscode-mcp.json        # VS Code MCP config template
│       ├── rag-cursor-rules.mdc   # Cursor rules for RAG tools
│       ├── rag-copilot-instructions.md
│       └── package.json           # pg, etc.
├── scripts/
│   ├── lifecycle/
│   │   └── post_create.sh         # Calls setup_rag.sh + setup_editor_rag_mcp.sh at init
│   └── ai/
│       ├── setup_rag.sh           # Connection check
│       ├── setup_editor_rag_mcp.sh # Cursor/VSCode MCP config (when USE_RAG=true)
│       └── seed_rag.py             # Generic indexing script
└── docs/
    └── rag.md                     # This file

.claude/
├── agents/
│   ├── angular-expert.md          # RAG-First agent (~30 lines)
│   ├── symfony-expert.md          # RAG-First agent (~30 lines)
│   ├── archforge.md               # RAG-First agent (~30 lines)
│   └── security-expert.md         # RAG-First agent — SecureByDesign skill + knowledge
└── skills/
    └── capture-learning/
        └── SKILL.md               # Auto-learning skill (global vs project logic)
```

---

## Troubleshooting

**RAG setup failed (non-critical)** — Either `USE_RAG` is not `true`, `RAG_DSN` is unset on the host, or Supabase is unreachable. Agents still work with their local bootstrap content.

**seed_rag.py — existing sections warning** — Use `--force` to fully reindex, or `--append` to add a new file without touching existing sections.

**Multi-source agent wiped by second `--force`** — Use `--files` to index all sources in one pass. `--force` deactivates the entire agent before inserting, so running it twice in sequence wipes the first batch.

**Wrong agent_name in base** — Happened when `--agent` wasn't specified. Fix with:

```bash
psql "$RAG_DSN" -c "
UPDATE rag_agent_instructions SET active = false
WHERE agent_name = 'wrong-name'
  AND metadata->>'source_file' = 'filename.md';"
```

**No rows in rag_audit** — Run `seed_rag.py` at least once after configuring RAG.

**Too many sections in `reference`** — The script infers `section_type` from heading titles. If your document uses non-standard titles, they fall back to `reference`. Check with `--dry-run --preview` and either rename headings or add patterns to `SECTION_TYPE_RULES` in `seed_rag.py`.