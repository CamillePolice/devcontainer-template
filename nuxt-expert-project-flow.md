# Nuxt Expert — Project-Flow (project-specific)

## Overview

Project-Flow est une application Nuxt 4 fullstack **CSR-only** (SSR désactivé) de gestion de lots, UOs, jalons et facturation pour Claranet. Déployée sur GCP Cloud Run, base PostgreSQL Cloud SQL.

---

## Architecture — Structure Project-Flow

```
project-flow/
├── app/                              # CSR client (srcDir Nuxt 4)
│   ├── pages/                        # File-based routing
│   │   ├── lots/
│   │   │   ├── index.vue             # /lots/
│   │   │   └── [o2i].vue            # /lots/:o2i
│   │   └── periods/
│   │       └── index.vue             # /periods/
│   ├── components/                   # Groupés par feature
│   │   ├── lot/
│   │   ├── milestone/
│   │   ├── period/
│   │   └── uo/
│   ├── stores/                       # Pinia stores
│   │   ├── useLotStore.ts
│   │   └── useCollaboratorStore.ts
│   ├── composables/                  # Wrappent stores + API + toasts
│   ├── plugins/
│   │   ├── 01.auth-integration.client.ts
│   │   └── 03.fetch-current-collaborator.client.ts
│   └── assets/
├── server/
│   ├── api/                          # Resource-based routes
│   │   ├── lots/
│   │   ├── periods/
│   │   ├── uos/
│   │   └── collaborators/
│   ├── middleware/
│   │   └── auth.ts                   # Protège /api/*, set event.context.user
│   ├── usecases/                     # Business logic extraite
│   ├── utils/
│   │   └── error.ts                  # AppError + helpers
│   └── database/
│       └── schema.ts                 # Drizzle schema
├── shared/
│   ├── types/                        # Interfaces client + serveur
│   └── utils/                        # Fonctions pures partagées
├── nuxt.config.ts
└── drizzle.config.ts
```

---

## Process — Workflow Project-Flow

### Étape 1 — Cadrage

- Mode **CSR-only** : pas de SSR, pas de `useAsyncData` avec `server: true`, pas de préoccupation hydration
- Auth via `@claranet/onion-auth` layer (pas nuxt-auth-utils)
- Business logic dans `server/usecases/`, pas dans les handlers API
- Types partagés dans `shared/types/`, pas dupliqués client/serveur

### Étape 2 — Implémentation

1. Créer/modifier le use case dans `server/usecases/` si logique métier
2. Créer/modifier le server route dans `server/api/` (validation, AppError, Drizzle)
3. Créer/modifier le Pinia store dans `app/stores/`
4. Créer/modifier le composable dans `app/composables/` (wrapper store + API + toast)
5. Créer/modifier la page/composant dans `app/pages/` ou `app/components/`

### Quand utiliser quoi

| Besoin | Où | Pattern |
|---|---|---|
| Logique métier | `server/usecases/` | Fonction pure, testable |
| Appel API serveur | `server/api/` | `defineEventHandler` + AppError |
| État client partagé | `app/stores/` | Pinia store |
| Logique UI réutilisable | `app/composables/` | Composable wrappant store + `$fetch` |
| Types API | `shared/types/` | Interfaces partagées |

---

## Best Practices — CSR-only

- **Pas de `useFetch`** pour le data fetching initial — utiliser `$fetch` dans les composables/stores (pas de SSR à alimenter)
- **Pas de `useAsyncData`** — inutile sans SSR, `$fetch` direct est plus simple
- `onMounted()` est le bon endroit pour charger les données initiales en CSR
- `localStorage` / `sessionStorage` sont accessibles directement (pas de guard `import.meta.client` nécessaire en CSR)
- Les Pinia stores sont le point central de gestion d'état — pas `useState` de Nuxt

## Best Practices — Authentication Project-Flow

- Auth gérée par le layer `@claranet/onion-auth` (pas nuxt-auth-utils)
- Plugin `01.auth-integration.client.ts` connecte `useOnionAuth()` à `useAuth()`
- Plugin `03.fetch-current-collaborator.client.ts` charge le collaborateur courant après auth
- Server middleware `auth.ts` protège toutes les routes `/api/*` et set `event.context.user`
- Côté client : `useAuth()` pour l'état auth
- Côté serveur : `event.context.user` (posé par le middleware) — ne jamais accéder à l'auth autrement

## Best Practices — Error Handling Project-Flow

- `server/utils/error.ts` exporte `AppError` avec enum typé :
  - `DATABASE` — erreur Drizzle/PostgreSQL
  - `NOT_FOUND` — ressource introuvable
  - `VALIDATION` — input invalide
  - `UNAUTHORIZED` — non authentifié
  - `FORBIDDEN` — non autorisé
  - `INTERNAL` — erreur serveur inattendue
- Helpers : `handleDatabaseError()`, `createNotFoundError()`, `createValidationError()`
- Toujours utiliser `AppError` et ses helpers — jamais `createError()` brut de h3 ni `throw new Error()`

## Best Practices — Pinia Stores

- Un store par domaine : `useLotStore`, `useCollaboratorStore`, etc.
- Les stores contiennent l'état et les actions de mutation
- Les composables wrappent les stores + ajoutent les appels `$fetch` + notifications toast
- Pas d'appel API direct dans les stores — passer par les composables
- Pas de logique UI dans les stores — c'est dans les composables ou les composants

## Conventions — Composants par feature

- Grouper les composants par domaine métier : `lot/`, `milestone/`, `period/`, `uo/`
- Pas de dossier `common/` fourre-tout — si un composant est vraiment transversal, il va à la racine de `components/`
- Nommage : `LotCard.vue`, `MilestoneTimeline.vue`, `UoTable.vue`

## Conventions — Commits

- Format : `type(scope): description [AI]`
- Toujours inclure le tag `[AI]` pour les commits assistés par IA
- Types : `feat`, `fix`, `refactor`, `chore`, `docs`, `style`, `test`
- Scopes : `lot`, `uo`, `milestone`, `period`, `billing`, `auth`, `db`, `ci`

---

## Architecture — Database Schema

### Entités principales

- **lot** — lot de travail (identifié par `o2i`)
- **uo** — unité d'œuvre (deux variantes : forfait standard/historique et régie T&M)
- **milestone** — jalon déclenche la facturation
- **collaborator** — utilisateur/collaborateur Claranet
- **period** — période de facturation
- **billing** — facturation liée aux milestones
- **worklog** — saisie de temps
- **materialQuantityDeclaration** — déclaration quantités matériel (états PENDING/BILLED)

### Vues augmentées

- `lot_augmented_view` — agrège les données lot avec jointures lourdes
- `augmented_uo_view` — agrège les données UO avec jointures lourdes
- Utiliser les vues pour les lectures (GET) — les tables pour les écritures (POST/PUT/DELETE)

### API Routes — Patterns

- Resource-based : `/api/lots/`, `/api/lots/[o2i]/`, `/api/periods/[id]/`, `/api/uos/[o2i]/`
- Identifier par `o2i` pour lots et UOs, par `id` pour le reste
- Toujours valider les params avec Zod dans les handlers

---

## Architecture — Infrastructure

- **Runtime** : GCP Cloud Run (port 3000), image Docker via Artifact Registry
- **Database** : Cloud SQL PostgreSQL avec VPC connector
- **Auth DB** : Cloud SQL IAM auth en staging/prod, `DATABASE_URL` en local
- **CI** : `.gitlab-ci.yml` étend `claranet/dos/federanapps/common-ci`
- **Release** : semantic-release (conventional commits → changelog → version bump)
- **Local** : Docker Compose pour PostgreSQL + PgAdmin

---

## Gotchas — Project-Flow

- Pas de test runner configuré — `lint` + `typecheck` sont les quality gates
- UOs ont deux variantes (forfait et régie T&M) — toujours vérifier le type avant d'appliquer une logique de calcul
- Les vues augmentées (`lot_augmented_view`, `augmented_uo_view`) sont read-only — pas d'INSERT/UPDATE dessus
- `materialQuantityDeclaration` a un état machine PENDING → BILLED — respecter la transition
- La connexion DB change entre local (`DATABASE_URL`) et GCP (`Cloud SQL Connector + IAM`) — le runtime config gère le switch
- Le plugin auth est numéroté (`01.`, `03.`) pour contrôler l'ordre d'exécution — ne pas renommer sans vérifier les dépendances

## Known Issues — CSR vs SSR

- Le RAG global `nuxt-expert` contient des patterns SSR (hydration, `useAsyncData` server-side, etc.) — **les ignorer** dans project-flow
- `useFetch` fonctionne en CSR mais `$fetch` direct est préférable car plus explicite et sans la couche SSR inutile
- Les composables Nuxt SSR-only (`useRequestHeaders`, `useRequestEvent`, `useRequestURL`) ne sont pas disponibles côté client — ne pas les utiliser dans `app/`

---

## Checklist — Quality gates avant commit

- [ ] `npm run lint` passe sans erreur
- [ ] `npm run typecheck` passe sans erreur
- [ ] Message de commit au format `type(scope): description [AI]`
- [ ] Types partagés dans `shared/types/` si utilisés client + serveur
- [ ] Business logic dans `server/usecases/` (pas dans les handlers)
- [ ] Erreurs via `AppError` helpers (pas `createError()` brut)
