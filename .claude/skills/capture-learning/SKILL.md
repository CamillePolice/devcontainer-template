---
name: capture-learning
description: |
  Après chaque tâche non-triviale, évalue les découvertes et persiste les
  connaissances réutilisables dans Supabase RAG via seed-rag.
  Invoquer après toute résolution de problème inattendu, découverte d'un pattern,
  gotcha, workaround, ou optimisation de processus.
---

# Skill : capture-learning

Après chaque tâche non-triviale, évalue les découvertes et persiste les
connaissances réutilisables dans le RAG via le skill `seed-rag`.

---

## Étape 0 — Filtrer les notes inutilisables

Rejeter automatiquement (décision **NONE**) toute note qui :

- Contient un placeholder non rempli : `<...>`, `<tag>`, `<description>`
- Est trop générique : "Build/runtime error encountered", "edge case found"
- Fait moins de 40 caractères après le tag `[xxx]`
- Ne suit pas le format `[tag] technologie — description — solution`

Signaler ces notes dans le rapport final comme `REJECTED (too generic)`.

---

## Étape 1 — Lire le notepad

```bash
cat /tmp/learning-notes.md 2>/dev/null || echo "(empty)"
```

---

## Étape 2 — Classifier chaque note : GLOBAL ou PROJECT ?

**→ `project='global'`** si la découverte est :
- Un pattern Angular / Nuxt / Symfony générique
- Une technique SQL / PostgreSQL / Docker générique
- Un pattern de tooling (Git, psql, CI/CD…)
- Toute connaissance réutilisable dans un autre projet

**→ `project='$RAG_PROJECT'`** si la découverte est :
- Spécifique à l'architecture du projet (noms de services, URLs d'API…)
- Une convention propre au projet (ex: `HttpWrapperService` dans OPVigil)
- Un bug ou comportement propre à ce codebase

**En cas de doute → `global`.**

---

## Étape 3 — Matrice de décision

| Décision      | Condition                                              | Action              |
|---------------|--------------------------------------------------------|---------------------|
| **NEW**       | Pas de couverture existante + connaissance réutilisable | Créer et indexer    |
| **IMPROVE**   | Section existante mais incomplète                      | `--force` sur le fichier |
| **NONE**      | Tâche triviale, déjà couverte, ou note rejetée         | Ignorer, justifier  |

Vérifier la couverture existante avant d'insérer :

```bash
psql "$RAG_DSN" -c "
SELECT agent_name, project, section_title, LEFT(content, 120) as preview
FROM rag_agent_instructions
WHERE active = true
  AND project IN ('global', '${RAG_PROJECT:-global}')
  AND content ILIKE '%<keyword>%'
LIMIT 5;
"
```

---

## Étape 4 — Écrire le fichier Markdown de la connaissance

Pour chaque note retenue, écrire un fichier `.md` structuré dans `/tmp/` :

```bash
cat > /tmp/learned-<slug>.md << 'EOF'
---
name: <Titre descriptif de la connaissance>
---

## <Titre descriptif>

[tag] technologie — description précise — solution appliquée

### Contexte

<Description du problème rencontré>

### Solution

<Ce qui a été appliqué et pourquoi ça fonctionne>

### Exemple

```<lang>
<code ou commande illustrant la solution>
```
EOF
```

**Règle de nommage** : `learned-<technologie>-<slug-court>.md`
Exemples : `learned-angular-signal-context.md`, `learned-symfony-cast-int.md`

---

## Étape 5 — Indexer via seed-rag

Déléguer l'insertion à `seed-rag` plutôt que d'écrire du SQL manuellement :

```bash
# Déterminer l'agent cible
# Connaissance Angular → angular-expert
# Connaissance Symfony/PHP → symfony-expert
# Connaissance Nuxt → nuxt-expert
# Connaissance transversale → learned-<slug>

AGENT="angular-expert"          # adapter selon la technologie
TARGET_PROJECT="global"         # ou $RAG_PROJECT si connaissance projet-spécifique
SLUG="signal-context"

# Dry-run d'abord — toujours
python .claude/skills/seed-rag/seed_rag.py \
  --file /tmp/learned-${SLUG}.md \
  --agent "$AGENT" \
  --project "$TARGET_PROJECT" \
  --dry-run --preview

# Si le dry-run est satisfaisant → insérer
python .claude/skills/seed-rag/seed_rag.py \
  --file /tmp/learned-${SLUG}.md \
  --agent "$AGENT" \
  --project "$TARGET_PROJECT" \
  --append
```

---

## Étape 6 — Améliorer une section existante (si IMPROVE)

Si une section existante couvre déjà le sujet mais incomplètement :

1. Récupérer l'`id` de la section via psql
2. Mettre à jour le fichier `.md` source avec le contenu enrichi
3. Relancer avec `--force` pour réindexer l'agent complet

```bash
# Réindexer tout l'agent après mise à jour du fichier source
python .claude/skills/seed-rag/seed_rag.py \
  --file angular-expert-rag.md \
  --agent angular-expert \
  --force
```

---

## Étape 7 — Vider le notepad

```bash
> /tmp/learning-notes.md
echo "Notepad vidé après capture."
```

---

## Étape 8 — Rapport

Afficher :

- Décision prise (NEW / IMPROVE / NONE) pour chaque note
- `agent_name` et `project` de chaque section indexée
- Fichier `.md` créé (chemin `/tmp/learned-*.md`)
- Justification du scope (global vs project)
- Notes rejetées avec raison

---

## Exemples de classification rapide

| Note                                                               | Scope   | Agent          |
|--------------------------------------------------------------------|---------|----------------|
| `[pattern] linkedSignal pour filtres de carte`                    | global  | angular-expert |
| `[gotcha] HttpWrapperService ne supporte pas les headers custom`  | project | angular-expert |
| `[pattern] (int) cast obligatoire pour les IDs en Symfony 7`      | global  | symfony-expert |
| `[gotcha] Le service SpcRepository attend un int, pas un string`  | project | symfony-expert |
