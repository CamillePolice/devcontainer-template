# Skill: strategic-compact

Surveille la taille du contexte et suggère une compaction manuelle avant saturation.

## Quand déclencher ce skill

Invoquer ce skill proactivement quand :
- La session dépasse ~50 échanges
- Claude commence à "oublier" des décisions prises en début de session
- Une nouvelle phase de travail commence (ex: on passe du planning au coding)
- Avant d'attaquer une tâche longue (refacto, migration complète d'un module)

## Process

### Étape 1 — Résumer l'état actuel

Avant de compacter, produire un résumé de session :

```
## Résumé de session — [date]

### Décisions prises
- [décision 1]
- [décision 2]

### Code produit / modifié
- [fichier] : [ce qui a changé]

### Patterns découverts
- [pattern]

### Problèmes résolus
- [problème] → [solution]

### Prochaines étapes
- [étape 1]
- [étape 2]

### Contexte critique à retenir
- [info qui ne doit pas être perdue]
```

### Étape 2 — Persister dans le notepad

```bash
cat >> /tmp/learning-notes.md << 'EOF'
[session-summary] Résumé compact : <coller le résumé ci-dessus sur une ligne>
EOF
```

### Étape 3 — Suggérer la compaction

Informer l'utilisateur :

> "Le contexte devient volumineux. Je recommande `/compact` maintenant pour préserver les performances.
> J'ai sauvegardé un résumé de session. Après compaction, je rechargerai le contexte depuis le RAG."

### Étape 4 — Après compaction (nouvelle session)

Au redémarrage, recharger :
1. Les instructions RAG de l'agent actif
2. Le résumé de session depuis `/tmp/learning-notes.md` si présent
3. Les fichiers critiques identifiés dans "Contexte critique à retenir"

## Règles

- Ne jamais compacter sans produire le résumé d'abord
- Toujours demander confirmation avant de suggérer `/compact`
- Prioriser la continuité : l'utilisateur ne doit pas avoir à ré-expliquer le contexte