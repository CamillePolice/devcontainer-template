# Nuxt Expert — RAG Knowledge Base

## Overview

Expert Nuxt 4+ / Vue 3.5+ / Composition API. Enforce modern SSR-first patterns, file-based routing, auto-imports, Nitro server routes, Drizzle ORM (PostgreSQL), nuxt-auth-utils (Auth0, Microsoft OIDC), Nuxt UI v4.

Répondre en français. Le code et les noms techniques restent en anglais.

---

## Process — Workflow de développement Nuxt

### Étape 1 — Cadrage

Avant de coder, identifier :
- SSR ou client-only ? (défaut : SSR)
- Quelle route ? (`app/pages/`) ou composant réutilisable ? (`app/components/`)
- Besoin d'un server route ? (`server/api/`)
- Besoin d'auth ? (middleware + `requireUserSession`)

### Étape 2 — Implémentation

1. Créer le server route si besoin (validation Zod, Drizzle query)
2. Créer le composable si logique réutilisable
3. Créer la page/composant avec `<script setup lang="ts">`
4. Connecter via `useFetch` / `useAsyncData` (jamais fetch brut)
5. Protéger avec middleware auth si nécessaire

### Étape 3 — Vérification

- `pnpm dev` : vérifier SSR + hydration sans erreur console
- `pnpm typecheck` : pas d'erreur TypeScript
- Tester le refresh navigateur (les données doivent être présentes dès le HTML serveur)

---

## Best Practices — Composants Vue

- Toujours `<script setup lang="ts">` — jamais Options API
- Props : reactive destructuring avec defaults → `const { title = 'Default' } = defineProps<{ title?: string }>()`
- Emits : typés → `const emit = defineEmits<{ update: [value: string] }>()`
- v-model : `defineModel<T>()` — pas le pattern manuel prop + emit
- Slots : `defineSlots<{ default(props: { item: T }): any }>()` pour typage
- Préférer `<NuxtLink>` sur `<a>`, `<NuxtImg>` sur `<img>`, `<NuxtTime>` pour les dates
- Lazy loading : `<LazyMyComponent />` (préfixe auto) pour les composants lourds

## Best Practices — Composables

- Nommage : préfixe `use` → `useInvoice()`, `useAuth()`
- Auto-importés depuis `app/composables/` : pas de `import` nécessaire
- SSR-safe : code browser-only dans `onMounted()` ou derrière `import.meta.client`
- Vérifier VueUse avant d'écrire un composable custom — la plupart des patterns existent déjà
- Async : toujours via `useAsyncData` / `useFetch`, jamais `await` brut dans setup

## Best Practices — Data Fetching

- **SSR + client** : `useFetch('/api/items')` ou `useAsyncData('key', () => $fetch('/api/items'))`
- **Client-only** : `useFetch('/api/items', { lazy: true, server: false })`
- **Mutations** : `$fetch('/api/items', { method: 'POST', body })` — pas useFetch pour POST/PUT/DELETE
- **Refresh** : `const { refresh } = useFetch(...)` puis `refresh()` — jamais dupliquer l'appel
- **Cache key** : toujours une clé unique string dans `useAsyncData` pour éviter data leaking entre routes
- **Payload** : `pick: ['id', 'name']` pour réduire le payload transféré
- **Deep reactivity** : `useAsyncData` avec `deep: false` pour les gros objets

## Best Practices — Server Routes

- File-based : `server/api/invoices.get.ts` → `GET /api/invoices`
- Helpers h3 v1 : `defineEventHandler`, `readBody`, `getQuery`, `createError`
- Validation : schemas Zod avec `readValidatedBody(event, schema.parse)` et `getValidatedQuery(event, schema.parse)`
- Erreurs : toujours `createError({ statusCode, statusMessage })` — jamais throw brut
- Database : Drizzle ORM via server utils (`server/utils/db.ts`)
- Pas de logique métier dans les handlers — extraire dans `server/utils/` ou `server/services/`

## Best Practices — Drizzle ORM

- Schema : `server/database/schema.ts` avec `pgTable()` definitions
- Migrations : `drizzle-kit generate` puis `drizzle-kit migrate`
- Queries : préférer le query builder (`db.select().from(table).where(...)`)
- Relations : définir avec `relations()`, query via `db.query.table.findMany({ with: {...} })`
- Types : exporter `InferSelectModel<typeof table>` et `InferInsertModel<typeof table>` pour réutilisation
- Transactions : `db.transaction(async (tx) => { ... })` pour les opérations multi-tables
- Pas de SQL brut sauf cas extrême — toujours Drizzle query builder

## Authentication — nuxt-auth-utils

- Session côté client : `useUserSession()` composable (auto-importé)
- Login Auth0 : `server/routes/auth/auth0.get.ts` → `defineOAuthAuth0EventHandler({ ... })`
- Login Microsoft : `server/routes/auth/microsoft.get.ts` → `defineOAuthMicrosoftEventHandler({ ... })`
- Protection route client : `app/middleware/auth.ts` → `const { loggedIn } = useUserSession(); if (!loggedIn.value) navigateTo('/login')`
- Protection API serveur : `const { user } = await requireUserSession(event)` — obligatoire dans chaque route protégée
- Config : secrets dans `runtimeConfig` (jamais `runtimeConfig.public`), domaines dans `runtimeConfig.public`

## Conventions — Nuxt Config

```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  future: { compatibilityVersion: 4 },
  modules: ['@nuxt/ui', 'nuxt-auth-utils'],
  css: ['~/assets/css/main.css'],
  runtimeConfig: {
    auth0ClientSecret: '',
    microsoftClientSecret: '',
    public: {
      auth0Domain: '',
      auth0ClientId: '',
    },
  },
})
```

## Conventions — Code Style

- Auto-imports : ne pas écrire `import { ref, computed } from 'vue'` — Nuxt les auto-importe
- Fichiers : kebab-case pour les pages (`invoice-list.vue`), PascalCase pour les composants (`InvoiceCard.vue`)
- Composables : camelCase avec préfixe use (`useInvoiceList.ts`)
- Server routes : kebab-case avec suffixe méthode (`invoices.get.ts`, `invoices.post.ts`)
- Pas d'index barrels (`index.ts` re-exports) — Nuxt auto-importe tout

---

## Architecture — Structure Nuxt 4

```
project-root/
├── app/                          # srcDir (Nuxt 4 default)
│   ├── pages/                    # File-based routing
│   │   ├── index.vue             # /
│   │   ├── login.vue             # /login
│   │   └── invoices/
│   │       ├── index.vue         # /invoices
│   │       └── [id].vue          # /invoices/:id
│   ├── components/               # Auto-imported components
│   │   ├── InvoiceCard.vue
│   │   └── ui/
│   ├── composables/              # Auto-imported composables
│   │   ├── useInvoice.ts
│   │   └── useAuth.ts
│   ├── middleware/                # Route middleware
│   │   └── auth.ts
│   ├── layouts/                  # Page layouts
│   │   └── default.vue
│   ├── plugins/                  # App plugins
│   └── assets/
│       └── css/main.css
├── server/                       # Nitro server (stays at root)
│   ├── api/                      # API routes
│   │   ├── invoices.get.ts
│   │   ├── invoices.post.ts
│   │   └── invoices/[id].get.ts
│   ├── routes/
│   │   └── auth/
│   │       ├── auth0.get.ts
│   │       └── microsoft.get.ts
│   ├── middleware/                # Server middleware
│   ├── utils/
│   │   └── db.ts                 # Drizzle instance
│   └── database/
│       └── schema.ts             # Drizzle schema
├── nuxt.config.ts
├── drizzle.config.ts
└── package.json
```

---

## Gotchas — Hydration SSR

- `useFetch` / `useAsyncData` dans `onMounted()` ne s'exécutent pas côté serveur → les appeler au top-level du `<script setup>`
- `localStorage` / `sessionStorage` dans le setup → crash SSR. Toujours garder derrière `if (import.meta.client)` ou dans `onMounted()`
- `useAsyncData` sans clé unique → les données d'une route polluent une autre route dynamique
- Composants qui accèdent au DOM dans setup → wraper dans `onMounted()` ou utiliser `<ClientOnly>`
- `window`, `document`, `navigator` → n'existent pas côté serveur. Vérifier `import.meta.client` ou utiliser `<ClientOnly>`

## Gotchas — Drizzle ORM

- `db.insert().values()` retourne `void` par défaut → ajouter `.returning()` pour récupérer l'objet inséré
- Les `timestamp()` Drizzle utilisent UTC par défaut — attention aux comparaisons avec des dates locales
- `db.select()` sans `.from()` ne compile pas — toujours chaîner `.from(table)`
- Les migrations Drizzle ne sont pas auto-appliquées — lancer `drizzle-kit migrate` manuellement ou dans un script CI
- `InferSelectModel` et `InferInsertModel` divergent si des colonnes ont des defaults — utiliser le bon type selon le contexte

## Gotchas — nuxt-auth-utils

- `useUserSession()` côté client ne protège PAS les API routes → toujours `requireUserSession(event)` dans les server routes
- Le callback OAuth doit matcher exactement l'URL configurée dans Auth0/Azure AD — sinon redirect silencieux
- Les tokens OAuth ne sont pas exposés côté client par défaut — c'est voulu, ne pas contourner
- `clearUserSession(event)` côté serveur pour logout, pas de manipulation manuelle des cookies

## Gotchas — Vue 3.5+ Reactivity

- Reactive destructuring des props (Vue 3.5+) : `const { title } = defineProps<...>()` est réactif nativement — pas besoin de `toRefs`
- `watch()` sur une prop destructurée : utiliser un getter → `watch(() => title, ...)` pas `watch(title, ...)`
- `shallowRef` : les mutations internes ne déclenchent pas de re-render — utiliser `triggerRef()` ou réassigner
- `computed` est lazy : ne pas compter dessus pour des side effects — utiliser `watchEffect` à la place

## Breaking Changes — Migration Nuxt 3 vers Nuxt 4

- `srcDir` change de `.` à `app/` — déplacer pages, components, composables, layouts, plugins, middleware sous `app/`
- `serverDir` reste à `server/` (pas de changement)
- `future.compatibilityVersion: 4` dans nuxt.config.ts pour activer les breaking changes progressivement
- `app.vue` se déplace vers `app/app.vue`
- Les imports relatifs `~/` pointent désormais vers `app/` et non la racine du projet
- `@nuxt/kit` API changes : vérifier la doc de migration officielle

---

## Testing Standards

### Composants

```typescript
import { mountSuspended } from '@nuxt/test-utils/runtime'
import InvoiceCard from '~/components/InvoiceCard.vue'

describe('InvoiceCard', () => {
  it('renders invoice amount', async () => {
    const wrapper = await mountSuspended(InvoiceCard, {
      props: { invoice: { id: 1, amount: 1500, client: 'Acme' } },
    })
    expect(wrapper.text()).toContain('1 500')
  })
})
```

### Composables

```typescript
import { renderComposable } from '@nuxt/test-utils/runtime'

describe('useInvoice', () => {
  it('fetches invoice by id', async () => {
    const { result } = await renderComposable(() => useInvoice(1))
    expect(result.data.value).toBeDefined()
  })
})
```

### Server Routes

```typescript
import { $fetch, setup } from '@nuxt/test-utils/e2e'

describe('GET /api/invoices', () => {
  await setup({ server: true })

  it('returns invoices list', async () => {
    const invoices = await $fetch('/api/invoices')
    expect(Array.isArray(invoices)).toBe(true)
  })
})
```

---

## Checklist — Nouveau composant

- [ ] `<script setup lang="ts">` (pas Options API)
- [ ] Props typées avec `defineProps<T>()`
- [ ] Emits typés avec `defineEmits<T>()` si applicable
- [ ] Data fetching via `useFetch` / `useAsyncData` au top-level
- [ ] Pas d'import Vue explicite (auto-importé)
- [ ] `<NuxtLink>` au lieu de `<a>` pour la navigation interne
- [ ] `<NuxtImg>` au lieu de `<img>` pour les images
- [ ] Pas d'accès DOM/browser dans le setup (SSR-safe)

## Checklist — Nouvelle API route

- [ ] Fichier dans `server/api/` avec suffixe méthode (`.get.ts`, `.post.ts`)
- [ ] `defineEventHandler(async (event) => { ... })`
- [ ] Validation input avec Zod (`readValidatedBody` / `getValidatedQuery`)
- [ ] `requireUserSession(event)` si route protégée
- [ ] Erreurs via `createError({ statusCode, statusMessage })`
- [ ] Queries via Drizzle ORM (pas de SQL brut)
- [ ] Types de retour explicites

## Checklist — Nouveau composable

- [ ] Fichier dans `app/composables/` avec préfixe `use`
- [ ] Pas d'import nécessaire (auto-importé)
- [ ] SSR-safe : code browser-only dans `onMounted()` ou derrière `import.meta.client`
- [ ] Vérifier VueUse avant d'implémenter — le pattern existe peut-être déjà
- [ ] Retourner des refs/computed pour la réactivité
- [ ] Documenter les paramètres et le retour avec JSDoc

---

## Ne pas utiliser — Anti-patterns

- ❌ Options API (`data()`, `methods`, `computed` object)
- ❌ `axios` ou `fetch()` brut dans les composants — utiliser `useFetch` / `$fetch`
- ❌ `import { ref, computed } from 'vue'` — auto-importé par Nuxt
- ❌ `localStorage` dans setup sans guard `import.meta.client`
- ❌ `useAsyncData` sans clé string unique
- ❌ `await` top-level dans setup sans `useFetch` / `useAsyncData`
- ❌ `throw new Error()` dans les server routes — utiliser `createError()`
- ❌ SQL brut — utiliser Drizzle ORM
- ❌ Gestion manuelle des cookies de session — utiliser nuxt-auth-utils
- ❌ Re-export barrels (`index.ts`) — Nuxt auto-importe
- ❌ `<a href>` pour navigation interne — utiliser `<NuxtLink>`
- ❌ `require()` — utiliser `import` ESM
- ❌ Logique métier dans les event handlers — extraire dans `server/utils/` ou `server/services/`

---

## Skills Reference (onmax/nuxt-skills)

Quand une guidance plus profonde est nécessaire, consulter ces skills (installés via `npx skills add onmax/nuxt-skills`) :

| Contexte de travail           | Skill à charger   | Fichiers de référence clés                      |
|-------------------------------|--------------------|--------------------------------------------------|
| `.vue` composants             | `vue`              | components.md, composables.md                    |
| Routing / config Nuxt         | `nuxt`             | routing.md, nuxt-config.md, server.md            |
| UI / composants stylés        | `nuxt-ui`          | components.md, theming.md, forms.md              |
| Composables utilitaires       | `vueuse`           | composables.md                                   |
| Composants headless accessibles | `reka-ui`        | components.md                                    |
| Développement de modules Nuxt | `nuxt-modules`     | module-development.md                            |

**NE PAS charger tous les fichiers de référence en même temps — charger uniquement ce qui est pertinent pour la tâche en cours.**
