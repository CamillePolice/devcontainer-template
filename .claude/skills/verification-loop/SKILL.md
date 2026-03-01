# Skill: verification-loop

Vérifie qu'une tâche est réellement terminée et qu'aucune régression n'a été introduite.

## Quand déclencher ce skill

- Après un refacto significatif
- Après une migration de pattern (ex: BehaviorSubject → signal)
- Après une suppression de code (dead code removal)
- Avant de déclarer une tâche "done"
- Quand l'utilisateur dit "vérifie que tout fonctionne"

## Process

### Étape 1 — Inventaire des changements

```bash
git diff --name-only HEAD~1
# ou pour les changements staged :
git diff --staged --name-only
```

Lister chaque fichier modifié et classifier : `created | modified | deleted`

### Étape 2 — Vérification statique

**Angular / TypeScript**
```bash
npx tsc --noEmit
npx ng build --configuration=development 2>&1 | tail -20
```

**Symfony / PHP**
```bash
php bin/console cache:clear
composer dump-autoload
php vendor/bin/phpstan analyse --level=8 src/ 2>&1 | tail -20
```

### Étape 3 — Vérification des tests

```bash
# Angular
npx ng test --watch=false --browsers=ChromeHeadless 2>&1 | tail -30

# Symfony
php bin/phpunit --testdox 2>&1 | tail -30
```

### Étape 4 — Vérification fonctionnelle

Pour chaque fichier modifié :
- [ ] Le composant/service s'instancie sans erreur
- [ ] Les imports sont corrects (pas de circulaire)
- [ ] Les types sont cohérents (pas de `any` introduit)
- [ ] Les signals sont correctement typés
- [ ] Pas de console.error au runtime

### Étape 5 — Rapport

```
## Verification Report

### Build
- TypeScript : ✅ / ❌ [erreurs]
- Angular build : ✅ / ❌ [erreurs]

### Tests
- Passing : X/Y
- Failed : [liste]

### Regressions détectées
- [régression] → [action corrective]

### Verdict
✅ DONE — aucune régression
❌ BLOCKED — [raison]
```

## Règles

- Ne jamais sauter l'étape build même si "ça semble évident"
- Si un test échoue, ne pas marquer la tâche done
- Documenter toute régression dans le learning notepad