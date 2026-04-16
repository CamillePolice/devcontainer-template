---
name: rag-audit
description: |
  Audite le contenu du RAG Supabase : liste les agents, sections actives,
  identifie les doublons potentiels et permet de désactiver des entrées obsolètes.
  Triggers : "qu'est-ce qu'il y a dans le RAG", "audite le RAG",
  "montre le contenu du RAG", "nettoie le RAG", "désactive cette section RAG",
  "combien d'entrées dans le RAG", "doublons dans le RAG".
---

# Skill : rag-audit

Permet d'inspecter, auditer et nettoyer le contenu de `rag_agent_instructions`
sans passer par un outil externe.

---

## Vue d'ensemble du RAG courant

Liste toutes les sections actives pour le projet courant et `global` :

```bash
psql "$RAG_DSN" -c "
SELECT agent_name,
       project,
       section_type,
       LEFT(section_title, 50) AS title,
       LEFT(content, 80)       AS preview,
       updated_at::date        AS updated
FROM rag_agent_instructions
WHERE project IN ('global', '${RAG_PROJECT:-global}')
  AND active = true
ORDER BY agent_name, section_type, updated_at DESC;"
```

---

## Compter les sections par agent

```bash
psql "$RAG_DSN" -c "
SELECT agent_name, project, COUNT(*) AS sections
FROM rag_agent_instructions
WHERE project IN ('global', '${RAG_PROJECT:-global}')
  AND active = true
GROUP BY agent_name, project
ORDER BY agent_name, project;"
```

---

## Identifier les doublons potentiels

Détecte les agents ayant trop de sections du même type (signe de duplication) :

```bash
psql "$RAG_DSN" -c "
SELECT agent_name, section_type, COUNT(*) AS count
FROM rag_agent_instructions
WHERE project IN ('global', '${RAG_PROJECT:-global}')
  AND active = true
GROUP BY agent_name, section_type
HAVING COUNT(*) > 3
ORDER BY count DESC;"
```

---

## Rechercher une connaissance spécifique

Remplacer `<keyword>` par le terme à chercher :

```bash
psql "$RAG_DSN" -c "
SELECT id, agent_name, project, section_type,
       LEFT(section_title, 50) AS title,
       LEFT(content, 120)      AS preview,
       updated_at::date        AS updated
FROM rag_agent_instructions
WHERE project IN ('global', '${RAG_PROJECT:-global}')
  AND active = true
  AND content ILIKE '%<keyword>%'
ORDER BY updated_at DESC
LIMIT 10;"
```

---

## Désactiver une section obsolète

Utiliser l'`id` retourné par les requêtes ci-dessus :

```bash
psql "$RAG_DSN" -c "
UPDATE rag_agent_instructions
SET active = false
WHERE id = <id>;"
```

Pour désactiver plusieurs sections d'un coup :

```bash
psql "$RAG_DSN" -c "
UPDATE rag_agent_instructions
SET active = false
WHERE id IN (<id1>, <id2>, <id3>);"
```

---

## Désactiver toutes les sections d'un agent sur un projet

À utiliser avant une réindexation complète (`--force`) :

```bash
psql "$RAG_DSN" -c "
UPDATE rag_agent_instructions
SET active = false
WHERE agent_name = '<agent-name>'
  AND project = '${RAG_PROJECT:-global}';"
```

---

## Workflow recommandé pour nettoyer le RAG

```
1. Vue d'ensemble        → identifier les agents surchargés
2. Doublons potentiels   → cibler les section_type avec count > 3
3. Recherche keyword     → inspecter le contenu suspect
4. Désactiver            → passer active = false sur les entrées obsolètes
5. Vérifier              → relancer la vue d'ensemble pour confirmer
```

Ne jamais supprimer (`DELETE`) — toujours désactiver (`active = false`).
Cela permet de restaurer une section si la désactivation était une erreur.
