# Hurl — requêtes HTTP en texte

[Hurl](https://hurl.dev) est un outil en ligne de commande pour exécuter des requêtes HTTP décrites dans des fichiers texte (`.hurl`). Idéal pour tester des API, reproduire des appels curl, et intégrer des tests HTTP en CI.

**Installation** : fournie par le script `install_cli_tools.sh` (binaire officiel .deb). Vérifier avec `hurl --version`.

---

## Principe

Un fichier `.hurl` contient une ou plusieurs **entrées** (entries). Chaque entrée = une requête HTTP (méthode, URL, headers, body) et optionnellement des **assertions** sur la réponse (status, body, headers).

- Format lisible, proche de curl
- Pas de JSON à échapper dans le corps de requête
- Variables et chaînage d’entrées (réutiliser une réponse dans la suivante)
- Mode « test » : une assertion en échec fait échouer la commande (code de sortie non nul)

---

## Premier fichier

Exemple `api/get.hurl` :

```hurl
GET https://api.example.com/health

HTTP 200
[Asserts]
header "Content-Type" contains "application/json"
jsonpath "$.status" == "ok"
```

- Ligne 1 : méthode + URL
- `HTTP 200` : assertion sur le code de statut
- `[Asserts]` : bloc d’assertions (header, body, jsonpath, etc.)

Exécution :

```bash
hurl api/get.hurl
```

---

## Méthodes et corps de requête

```hurl
POST https://api.example.com/users
Content-Type: application/json

{
  "name": "Alice",
  "email": "alice@example.com"
}

HTTP 201
```

Pour un formulaire (form-urlencoded) :

```hurl
POST https://api.example.com/login
Content-Type: application/x-www-form-urlencoded

username=alice&password=secret

HTTP 200
```

---

## Variables et chaînage

On peut **capturer** une valeur dans la réponse et la réutiliser dans une entrée suivante (même fichier) :

```hurl
POST https://api.example.com/login
Content-Type: application/json

{"username": "alice", "password": "secret"}

HTTP 200
[Captures]
token: jsonpath "$.access_token"

GET https://api.example.com/me
Authorization: Bearer {{token}}

HTTP 200
```

`{{token}}` sera remplacé par la valeur capturée.

Variables d’**environnement** : `{{env.API_BASE}}` (ex. `{{env.API_BASE}}/health`).

Variables en **ligne de commande** :

```bash
hurl --variable name=Alice --variable env=staging api/user.hurl
```

Dans le fichier : `{{name}}`, `{{env}}`.

---

## Assertions utiles

| Assertion | Exemple |
|-----------|--------|
| Code HTTP | `HTTP 200` ou `HTTP 200 201` (plusieurs acceptés) |
| Header | `header "X-Request-Id" != ""` |
| Body contient | `body contains "success"` |
| JSON (jsonpath) | `jsonpath "$.id" == "123"` |
| Durée max | `duration < 500` (ms) |

Exemple complet :

```hurl
GET https://api.example.com/users/1

HTTP 200
[Asserts]
header "Content-Type" contains "json"
jsonpath "$.name" == "Alice"
jsonpath "$.roles" count == 2
duration < 1000
```

---

## Options CLI courantes

| Option | Description |
|--------|-------------|
| `-v, --verbose` | Détail des requêtes/réponses |
| `--variable key=value` | Définir une variable |
| `-o, --output` | Fichier de sortie (body de la dernière réponse) |
| `--test` | Mode test : arrêt à la première assertion en échec (défaut) |
| `--no-output` | Pas d’affichage du body en cas de succès |
| `--error-format short` | Messages d’erreur courts (pratique en CI) |

Exemple en CI (GitHub Actions, GitLab CI, etc.) :

```bash
hurl --test --error-format short --no-output tests/*.hurl
```

---

## Bonnes pratiques

1. **Un fichier par scénario** (ex. `auth.hurl`, `users.hurl`) ou un répertoire `tests/` avec plusieurs `.hurl`.
2. **Variables pour les URLs** : `{{base_url}}/health` avec `base_url` en variable ou `{{env.API_URL}}`.
3. **Captures pour l’auth** : une entrée login qui capture le token, les suivantes qui utilisent `Authorization: Bearer {{token}}`.
4. **Assertions explicites** : au minimum `HTTP 200` (ou le code attendu) + si besoin des checks sur le body/headers pour en faire un vrai test.

---

## Documentation officielle

- **Site** : [https://hurl.dev](https://hurl.dev)
- **Installation** : [https://hurl.dev/docs/installation.html](https://hurl.dev/docs/installation.html)
- **Manuel** : [https://hurl.dev/docs/manual.html](https://hurl.dev/docs/manual.html)
- **Exemples** : [https://hurl.dev/docs/samples.html](https://hurl.dev/docs/samples.html)
- **Tutoriels** : premier fichier, asserts, chaînage, captures, CI — [Getting Started](https://hurl.dev/docs/tutorial/your-first-hurl-file.html)
