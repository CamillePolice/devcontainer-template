
# Skill: capture-learning

Après chaque tâche non-triviale, évalue les découvertes et persiste les
connaissances réutilisables dans Supabase RAG.

## Quand déclencher ce skill

* Tu as résolu un problème inattendu
* Tu as trouvé un workaround ou un gotcha
* Tu as optimisé un processus multi-étapes répété
* Tu as découvert un pattern réutilisable (Angular, Symfony, SQL...)
* Tu as appris quelque chose sur la configuration spécifique du projet

## Process

### Étape 1 — Lire le notepad

```bash
cat /tmp/learning-notes.md 2>/dev/null || echo "(empty)"
```

### Étape 2 — Classifier chaque note : GLOBAL ou PROJECT ?

Pour chaque note dans `/tmp/learning-notes.md`, décide du scope :

**→ `project='global'`** si la découverte est :

* Un pattern Angular générique (`@if`, signals, standalone, Bootstrap 5...)
* Un pattern Symfony/PHP générique (strict types, PHPDoc, test mocks...)
* Une technique SQL/PostgreSQL générique
* Un pattern de tooling (Git, Docker, psql...)
* Toute connaissance réutilisable dans un autre projet

**→ `project='$RAG_PROJECT'`** si la découverte est :

* Spécifique à l'architecture du projet (noms de services, URLs d'API...)
* Une convention propre au projet (ex: `HttpWrapperService` dans OPVigil)
* Un bug ou comportement propre à ce codebase
* Des chemins de fichiers ou noms de modules spécifiques

En cas de doute → `global`. Une connaissance trop spécifique en global
ne fait pas de mal ; une connaissance générique enfermée dans un projet
est une opportunité de réutilisation perdue.

### Étape 3 — Vérifier la couverture existante

Pour chaque note retenue, chercher si elle est déjà couverte :

```bash
psql "$RAG_DSN" -c "
SELECT agent_name, project, section_title, LEFT(content, 120) as preview
FROM rag_agent_instructions
WHERE active = true
  AND project IN ('global', '${RAG_PROJECT:-global}')
  AND (
    content ILIKE '%<keyword1>%'
    OR content ILIKE '%<keyword2>%'
  )
LIMIT 5;
"
```

### Étape 4 — Matrice de décision

| Décision          | Condition                                                | Action                       |
| ------------------ | -------------------------------------------------------- | ---------------------------- |
| **NEW**      | Pas de couverture existante + connaissance réutilisable | Créer + insérer            |
| **IMPROVE**  | Section existante mais incomplète                       | UPDATE du content            |
| **OPTIMIZE** | Note `[efficiency]`+ gain significatif                 | Créer procédure optimisée |
| **NONE**     | Tâche triviale ou déjà couverte                       | Ignorer, justifier           |

### Étape 5 — Insérer la nouvelle learned-skill

Déterminer l'`agent_name` approprié :

* Connaissance Angular → `angular-expert`
* Connaissance Symfony/PHP → `symfony-expert`
* Connaissance spécifique à l'agent actif → `<nom-de-l-agent>`
* Connaissance transversale → `learned-<slug-descriptif>`

```bash
SKILL_SLUG="learned-<slug-descriptif>"
TARGET_PROJECT="global"   # ou $RAG_PROJECT si connaissance projet-spécifique
AGENT="angular-expert"    # ou symfony-expert, archforge, etc.

psql "$RAG_DSN" -c "
INSERT INTO rag_agent_instructions
    (agent_name, project, section_type, section_title, content, metadata)
VALUES (
    '$AGENT',
    '$TARGET_PROJECT',
    'learned-skill',
    '<Titre descriptif de la connaissance>',
    \$\$<contenu complet de la learned-skill>\$\$,
    '{
        \"learned_from\": \"<nom-agent-source>\",
        \"task_context\": \"<description courte de la tâche>\",
        \"scope\": \"<global|project>\",
        \"tags\": [\"<tag1>\", \"<tag2>\"]
    }'::jsonb
);
"
```

### Étape 6 — Améliorer une section existante (si IMPROVE)

```bash
psql "$RAG_DSN" -c "
UPDATE rag_agent_instructions
SET content = \$\$<nouveau contenu enrichi>\$\$,
    metadata = metadata || '{\"last_improved\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}'::jsonb
WHERE id = <id-de-la-section>
  AND active = true;
"
```

### Étape 7 — Vider le notepad

```bash
> /tmp/learning-notes.md
echo "Notepad cleared after capture."
```

### Étape 8 — Rapport

Afficher un résumé :

* Décision prise (NEW / IMPROVE / OPTIMIZE / NONE) pour chaque note
* `agent_name` et `project` de chaque section créée/modifiée
* Justification du scope choisi (global vs project)

## Exemples de classification

| Note                                                               | Scope   | Agent                | Raison                                   |
| ------------------------------------------------------------------ | ------- | -------------------- | ---------------------------------------- |
| `[pattern] linkedSignal pour filtres de carte`                   | global  | angular-expert       | Pattern Angular générique              |
| `[gotcha] HttpWrapperService ne supporte pas les headers custom` | opvigil | angular-expert       | Spécifique à l'implémentation OPVigil |
| `[pattern] (int) cast obligatoire pour les IDs en Symfony 7`     | global  | symfony-expert       | Pattern PHP générique                  |
| `[efficiency] seed_rag.py --force réindexe en une commande`     | global  | learned-rag-workflow | Connaissance transversale                |
| `[gotcha] Le service SpcRepository attend un int, pas un string` | opvigil | symfony-expert       | Spécifique au repo OPVigil              |
