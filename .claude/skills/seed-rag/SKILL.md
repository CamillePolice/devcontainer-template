---
name: seed-rag
description: |
  Indexe des fichiers Markdown ou Python dans le RAG Supabase (pgvector).
  Invoquer dès qu'un agent veut persister une connaissance, un SKILL.md, un fichier
  de documentation ou une note d'apprentissage dans la base RAG.
  Triggers : "indexe dans le RAG", "seed le RAG", "ajoute ce fichier au RAG",
  "persist cette connaissance", après toute création d'un nouveau skill ou agent,
  après capture-learning si une note dépasse le scope d'un INSERT psql direct.
---

# Skill : seed-rag

Wrapper autour de `seed_rag.py` — le script Python qui parse, classe et insère
des sections sémantiques dans `rag_agent_instructions` (Supabase + pgvector).

## Prérequis

```bash
pip install psycopg2-binary   # une seule fois
```

Variables d'environnement (déjà définies dans `.claude/.env`) :

| Variable      | Rôle                                              |
|---------------|---------------------------------------------------|
| `RAG_DSN`     | Connection string Supabase                        |
| `RAG_PROJECT` | Scope du projet (défaut : `global`)               |

---

## Commandes de référence

### Indexer un dossier entier
```bash
python .claude/skills/seed-rag/seed_rag.py \
  --dir ./docs \
  --agent <agent-name>
```

### Indexer un fichier unique
```bash
python .claude/skills/seed-rag/seed_rag.py \
  --file SKILL.md \
  --agent <agent-name>
```

### Indexer plusieurs fichiers en une passe
```bash
python .claude/skills/seed-rag/seed_rag.py \
  --files SKILL.md expert-rag.md \
  --agent <agent-name>
```

### Réindexer en écrasant l'existant
```bash
python .claude/skills/seed-rag/seed_rag.py \
  --dir . \
  --agent <agent-name> \
  --force
```

### Ajouter sans écraser les sections existantes
```bash
python .claude/skills/seed-rag/seed_rag.py \
  --file new-knowledge.md \
  --agent <agent-name> \
  --append
```

### Prévisualiser sans écrire en base (toujours faire ça en premier)
```bash
python .claude/skills/seed-rag/seed_rag.py \
  --file note.md \
  --agent <agent-name> \
  --dry-run --preview
```

---

## Choix du flag selon le contexte

| Situation                                           | Flag à utiliser |
|-----------------------------------------------------|-----------------|
| Première indexation d'un agent                      | *(aucun)*       |
| Ajout d'une note ou d'un skill sans tout réindexer  | `--append`      |
| Mise à jour complète après refonte d'un fichier     | `--force`       |
| Vérifier ce qui sera indexé avant de toucher la BDD | `--dry-run --preview` |

---

## Comment seed_rag.py parse les fichiers Markdown

1. **Supprime le frontmatter YAML** (`--- ... ---`)
2. **Preamble** (avant le premier `##`) → section de type `role`
3. **Titres `##`** → sections principales, `section_type` détecté par regex
4. **Si section > 4 000 chars** → découpage récursif sur `###` puis `####`
5. **Sections < 50 chars ou < 2 lignes significatives** → ignorées

### Types de section détectés automatiquement

| section_type    | Mots-clés dans le titre                          |
|-----------------|--------------------------------------------------|
| `role`          | rôle, overview, objectif, who you are            |
| `process`       | phase N, step N, étape N, workflow, process      |
| `best_practices`| best practices, conventions, guidelines, SBD-XX  |
| `edge_cases`    | edge case, gotcha, fallback, breaking change     |
| `output_format` | output, template, checklist, rapport             |
| `reference`     | stack, architecture, prérequis, outils           |
| `learned-skill` | (inséré manuellement par capture-learning)       |

---

## Scope : global vs project

```bash
# Connaissance réutilisable dans n'importe quel projet → global (défaut)
python .claude/skills/seed-rag/seed_rag.py \
  --file angular-patterns.md \
  --agent angular-expert \
  --project global

# Convention spécifique au projet en cours → $RAG_PROJECT
python .claude/skills/seed-rag/seed_rag.py \
  --file project-conventions.md \
  --agent nuxt-expert \
  --project "$RAG_PROJECT"
```

**Règle** : en cas de doute → `global`. Une connaissance trop spécifique en global
ne fait pas de mal ; une connaissance générique enfermée dans un project est une
opportunité de réutilisation perdue.

---

## Intégration avec capture-learning

`capture-learning` écrit un fichier `.md` temporaire puis délègue à ce skill :

```bash
# Dans capture-learning (étape 5), remplacer le psql INSERT direct par :
python .claude/skills/seed-rag/seed_rag.py \
  --file /tmp/learned-skill.md \
  --agent "$AGENT" \
  --project "$TARGET_PROJECT" \
  --append
```

---

## Workflow recommandé

```
1. dry-run --preview    →  vérifier les sections détectées
2. --append             →  ajouter si l'agent existe déjà
3. --force              →  réindexer complètement si le fichier source a changé
```

Ne jamais lancer sans `--dry-run` la première fois sur un nouvel agent.
