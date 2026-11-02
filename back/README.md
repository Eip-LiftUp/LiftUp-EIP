# LiftUp — Backend API

**Issue :** [#30 — User registration](https://github.com/Eip-LiftUp/LiftUp-EIP/issues/30)  
**Responsable :** Raphaël  
**Status :** In Development  
**Framework :** Axum (Rust)  
**Base de données :** PostgreSQL  

---

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Architecture du projet](#architecture-du-projet)
3. [Prérequis](#prérequis)
4. [Installation & Configuration](#installation--configuration)
5. [Migration de la base de données](#migration-de-la-base-de-données)
6. [Lancer le serveur](#lancer-le-serveur)
7. [Endpoints disponibles](#endpoints-disponibles)
8. [Structure du code](#structure-du-code)
9. [Conventions de code](#conventions-de-code)

---

## Vue d'ensemble

Ce dossier contient le backend de l'application **LiftUp**, développé en **Rust 1.76+**. Il expose une API REST permettant aux clients (Flutter mobile) de gérer les données utilisateur et les sessions d'entraînement.

L'implémentation actuelle couvre l'**issue #30** : enregistrement d'un utilisateur et persistance de ses données en base.

---

## Architecture du projet

Le backend suit une architecture en couches, conforme au C4 model documenté dans [`docs/ARCHITECTURE_UML_C4_MODEL.md`](../docs/ARCHITECTURE_UML_C4_MODEL.md).

```
back/
├── Cargo.toml                  # Dépendances du projet
├── openapi.yaml                # Contrat OpenAPI 3.0.3 (contract-first)
├── .env.example                # Template des variables d'environnement
├── migrations/
│   ├── 0001_create_users.sql   # Schéma de la table `users`
│   └── 0008_create_cached_programs.sql # Cache du dernier programme par utilisateur
└── src/
    ├── main.rs                 # Point d'entrée — wiring + démarrage du serveur
    ├── config.rs               # Chargement de la configuration depuis l'env
    ├── cors.rs                 # Couche CORS : whitelist d'origines (CORS_ALLOWED_ORIGINS)
    ├── rate_limit.rs           # Limitation de débit de POST /auth/login (par IP)
    ├── db.rs                   # Pool PostgreSQL + exécution des migrations
    ├── errors.rs               # Type d'erreur global + impl IntoResponse
    ├── routes.rs               # Déclaration de toutes les routes HTTP
    ├── auth/
    │   ├── mod.rs              # Extracteur Axum `AuthUser` (Authorization: Bearer)
    │   └── jwt.rs              # Claims, create_token, verify_token (HS256, expiration 7 j)
    ├── tests/                  # Tests avec base Postgres (#[sqlx::test]) : services + HTTP
    ├── models/
    │   ├── program.rs          # ProgramResponse (GET /workouts/program, schéma provisoire)
    │   └── user.rs             # Struct User, DTOs CreateUserRequest/Response, FitnessLevel
    ├── repositories/
    │   ├── program.rs          # Accès à `cached_programs` (upsert, find_by_user)
    │   └── user.rs             # Accès direct à la base (SQL queries via sqlx)
    ├── services/
    │   ├── program.rs          # ProgramService : appel du moteur ML (contrat provisoire) + cache
    │   └── user.rs             # Logique métier (validation, unicité email, création)
    └── handlers/
        ├── program.rs          # GET /workouts/program (moteur ML + cache, 401 sans token)
        └── user.rs             # Handlers HTTP Axum (POST /users)
```

### Flux de traitement d'une requête

```
Requête HTTP
    │
    ▼
[ Router (routes.rs) ]
    │
    ▼
[ Handler (handlers/user.rs) ]   ← extrait le JSON du body
    │
    ▼
[ Service (services/user.rs) ]   ← valide les données, vérifie l'unicité
    │
    ▼
[ Repository (repositories/user.rs) ] ← exécute les requêtes SQL
    │
    ▼
[ PostgreSQL ]
```

---

## Prérequis

| Outil | Version minimale |
|-------|-----------------|
| Rust | 1.76 (stable) |
| Cargo | *(inclus avec Rust)* |
| PostgreSQL | 14+ |
| sqlx-cli *(optionnel pour les migrations manuelles)* | 0.7+ |

Installer Rust via [rustup](https://rustup.rs/) :

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

---

## Installation & Configuration

### 1. Cloner et se placer dans le dossier

```bash
cd back/
```

### 2. Configurer les variables d'environnement

Copier le fichier template et le remplir :

```bash
cp .env.example .env
```

Contenu de `.env` à adapter :

```env
SERVER_HOST=127.0.0.1
SERVER_PORT=8080
DATABASE_URL=postgres://liftup_user:liftup_password@localhost:5432/liftup_db
DATABASE_MAX_CONNECTIONS=10
# Required, at least 32 characters (the server refuses to start otherwise)
JWT_SECRET=change-me-dummy-secret-at-least-32-chars
# Optional, token lifetime in days (default: 7)
JWT_EXPIRATION_DAYS=7
# Optional, comma-separated browser origins allowed by CORS ("*" is refused)
CORS_ALLOWED_ORIGINS=http://localhost:8090,http://127.0.0.1:8090
# Optional, login attempts per minute and per IP (default 5)
LOGIN_RATE_LIMIT_PER_MINUTE=5
# Optional, Python AI service (defaults: http://localhost:8000, 5 seconds)
AI_SERVICE_URL=http://localhost:8000
AI_TIMEOUT_SECS=5
RUST_LOG=liftup_backend=debug,tower_http=debug
```

### 3. Créer la base de données PostgreSQL

```bash
psql -U postgres -c "CREATE USER liftup_user WITH PASSWORD 'liftup_password';"
psql -U postgres -c "CREATE DATABASE liftup_db OWNER liftup_user;"
```

### 4. Installer les dépendances Cargo

```bash
cargo build
```

---

## Migration de la base de données

Les migrations sont gérées automatiquement via **sqlx** au démarrage du serveur (fichiers SQL dans `migrations/`).

Pour les appliquer manuellement via `sqlx-cli` :

```bash
cargo install sqlx-cli --no-default-features --features native-tls,postgres
sqlx migrate run --database-url "$DATABASE_URL"
```

### Schéma de la table `users`

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK, NOT NULL, DEFAULT `uuid_generate_v4()` | Identifiant unique |
| `email` | `VARCHAR(255)` | NOT NULL, UNIQUE | Email de l'utilisateur |
| `username` | `VARCHAR(100)` | NOT NULL | Pseudonyme |
| `display_name` | `VARCHAR(255)` | NULL | Nom public affiché |
| `birth_date` | `DATE` | NULL | Date de naissance |
| `height_cm` | `SMALLINT` | NULL, CHECK > 0 < 300 | Taille en cm |
| `weight_kg` | `NUMERIC(5,2)` | NULL, CHECK > 0 < 700 | Poids en kg |
| `fitness_level` | `VARCHAR(20)` | NOT NULL, DEFAULT `beginner` | `beginner` / `intermediate` / `advanced` |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT `NOW()` | Date de création |
| `updated_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT `NOW()` | Mise à jour automatique via trigger |

### Schéma de la table `cached_programs`

Dernier programme connu de chaque utilisateur, servi en secours quand le service IA est indisponible (migration `0008`). Table dédiée plutôt qu'une colonne JSONB sur `users` : `User` est lu avec `SELECT *`, un gros JSON serait chargé à chaque lecture de profil. `ON DELETE CASCADE` supprime le cache avec l'utilisateur (RGPD).

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `user_id` | `UUID` | PK, FK → `users(id)` ON DELETE CASCADE | Propriétaire ; un seul programme caché par utilisateur |
| `program` | `JSONB` | NOT NULL | `ProgramResponse` sérialisé (camelCase) |
| `generated_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT `NOW()` | Dernière génération par le service IA (remis à `NOW()` à chaque upsert) |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT `NOW()` | Date d'insertion |
| `updated_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT `NOW()` | Mise à jour automatique via trigger |

---

## Lancer le serveur

```bash
# Mode développement
cargo run

# Mode release (optimisé)
cargo run --release
```

Le serveur écoute par défaut sur `http://127.0.0.1:8080`.

---

## Endpoints disponibles

### `POST /users`

Crée un nouveau compte utilisateur.

**URL :** `POST /users`

**Headers :**
```
Content-Type: application/json
```

**Body (JSON) :**

| Champ | Type | Requis | Validation |
|-------|------|--------|-----------|
| `email` | `string` | ✅ | Format email valide |
| `username` | `string` | ✅ | 3–100 caractères |
| `display_name` | `string` | ❌ | — |
| `birth_date` | `string (YYYY-MM-DD)` | ❌ | — |
| `height_cm` | `integer` | ❌ | 1–299 |
| `weight_kg` | `float` | ❌ | 1.0–699.0 |
| `fitness_level` | `string` | ❌ | `beginner` / `intermediate` / `advanced` |

**Exemple de requête :**

```bash
curl -X POST http://127.0.0.1:8080/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "alex@liftup.io",
    "username": "alex42",
    "display_name": "Alex",
    "fitness_level": "beginner",
    "height_cm": 180,
    "weight_kg": 75.5
  }'
```

**Réponse — `201 Created` :**

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "alex@liftup.io",
  "username": "alex42",
  "display_name": "Alex",
  "fitness_level": "beginner",
  "created_at": "2026-03-04T09:00:00Z"
}
```

**Erreurs possibles :**

| Code | Cas |
|------|-----|
| `409 Conflict` | L'email est déjà utilisé |
| `422 Unprocessable Entity` | Données invalides (email malformé, username trop court, etc.) |
| `500 Internal Server Error` | Erreur serveur inattendue |

---

### `POST /auth/login` (limité en débit)

Authentifie un utilisateur et renvoie un JWT dans le champ `token`. La route est limitée **par IP** : `LOGIN_RATE_LIMIT_PER_MINUTE` tentatives (défaut 5), puis un jeton est rendu toutes les `60/N` secondes. Au-delà, la réponse est `429 Too Many Requests` avec `{"error": "Too many login attempts, please retry later"}` et les en-têtes `retry-after` / `x-ratelimit-after`.

L'IP vient de `X-Forwarded-For` / `X-Real-IP`, puis de l'IP du pair. **Derrière un reverse proxy**, celui-ci doit écraser `X-Forwarded-For` ; si le serveur est exposé directement, ce header est falsifiable et la limite peut être contournée.

---

### `GET /workouts/program`

Renvoie le programme d'entraînement de l'utilisateur authentifié (header `Authorization: Bearer <token>` obligatoire, sinon `401`). Contrat dans [`openapi.yaml`](./openapi.yaml) ; le schéma est **provisoire** (contrat du moteur ML non figé).

1. Le backend charge le profil (`404` si l'utilisateur n'existe plus) et appelle `POST {AI_SERVICE_URL}/api/v1/program/generate` (chemin **provisoire**, timeout `AI_TIMEOUT_SECS`, connexion limitée à 1 s).
2. Succès : le programme est enregistré dans `cached_programs` et renvoyé en `200` avec `"source": "generated"`.
3. Échec (timeout, connexion refusée, statut non-2xx, JSON invalide) : le dernier programme caché est renvoyé en `200` avec `"source": "cache"` et son `generatedAt` d'origine. Sans cache : `503` `{"error": "..."}`. Une panne de l'IA ne produit jamais de `500`.

`injured_zones` est une donnée de santé : les corps échangés avec le moteur ML ne sont jamais loggés.

---

## Tests

Les tests sont dans le crate (`src/tests/` et des modules `#[cfg(test)]`), car le projet est un binaire : un dossier `tests/` à la racine ne pourrait pas importer le code.

Les tests de base de données utilisent `#[sqlx::test]` : chaque test crée une base temporaire à partir de `DATABASE_URL` et y applique les migrations de `./migrations`. Le rôle Postgres doit donc avoir le droit `CREATEDB` :

```bash
sudo -u postgres psql -c "ALTER USER liftup_user CREATEDB;"
```

Lancer les tests en local :

1. Démarrer un Postgres et définir `DATABASE_URL` (dans `.env` ou dans le shell). Exemple avec Docker, l'utilisateur créé est superuser donc a `CREATEDB` :
   ```bash
   docker run -d --rm --name liftup-test-pg -e POSTGRES_USER=liftup_test -e POSTGRES_PASSWORD=test -p 55432:5432 postgres:16
   export DATABASE_URL=postgres://liftup_test:test@localhost:55432/postgres
   ```
   Avec un Postgres local, utiliser `DATABASE_URL` de `.env` et accorder `CREATEDB` comme ci-dessus.
2. Lancer `cargo test` depuis `back/`. `JWT_SECRET` n'est pas nécessaire : les tests utilisent leur propre configuration JWT.

La CI GitHub Actions ([`.github/workflows/backend.yml`](../.github/workflows/backend.yml)) fait la même chose : service `postgres:16`, puis `cargo build` et `cargo test` dans `back/`, sur chaque push et pull request touchant `back/**`.

```bash
cargo test                       # tous les tests (Postgres requis)
cargo test -- --ignored          # tests marqués #[ignore = "bug: ..."] (échouent tant que le bug existe)
```

Contenu : `src/tests/user_service.rs`, `workout_service.rs` (services appelés directement), `http.rs` (routes via `axum-test`), `program_endpoint.rs` (GET /workouts/program avec faux moteur ML), `e2e.rs` (création → login → programme, fallback cache, 401, 404, 429), `common.rs` (helpers), et les validations de DTO dans `src/models/user.rs`.

---

## Structure du code

Le code est organisé selon les principes décrits dans le C4 Model :

| Couche | Dossier | Responsabilité |
|--------|---------|----------------|
| **Domaine** | `src/models/` | Structures de données, DTOs, types métier |
| **Repository** | `src/repositories/` | Requêtes SQL, accès à la base uniquement |
| **Service** | `src/services/` | Logique métier, orchestration, validation |
| **Handler** | `src/handlers/` | Extraction HTTP, délégation au service, formatage réponse |
| **Routes** | `src/routes.rs` | Déclaration et montage de tous les endpoints |
| **Infra** | `src/config.rs`, `src/db.rs` | Configuration, pool de connexions |
| **Erreurs** | `src/errors.rs` | Type `AppError` unique, conversion en réponse HTTP |

---

## Conventions de code

Ce projet suit les conventions définies dans [`docs/GIT_WORKFLOW_AND_STANDARDS.md`](../docs/GIT_WORKFLOW_AND_STANDARDS.md).

- **Commits** : Conventional Commits — `feat(users): add create user endpoint`
- **Branches** : `feature/...`, `bugfix/...`, `hotfix/...`
- **Code** : Aucun code commenté, pas de `println!` de debug (utiliser `tracing::debug!`)
- **Formatage** : `cargo fmt` avant chaque commit
- **Lint** : `cargo clippy -- -D warnings` avant chaque PR
