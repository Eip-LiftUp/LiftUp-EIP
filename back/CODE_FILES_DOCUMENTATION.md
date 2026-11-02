# Documentation des fichiers de code (back)

## Portee
Ce document couvre les fichiers de code du dossier back.

Inclus :
- Rust applicatif (src),
- migrations SQL,
- fichiers techniques utiles au code (Cargo, Docker).

Exclus :
- artefacts de compilation dans target.

## Arborescence documentee

### 1) Configuration et bootstrap

- src/main.rs
  - Point d'entree du backend Rust (Axum).
  - Initialise config, pool DB, middlewares, routes et lancement serveur.

- src/config.rs
  - Chargement des variables d'environnement et config runtime.
  - Type principal : Config (avec JwtConfig : JWT_SECRET obligatoire >= 32 caracteres, masque dans Debug ; JWT_EXPIRATION_DAYS optionnel, defaut 7). Contient aussi AI_SERVICE_URL (defaut http://localhost:8000) et AI_TIMEOUT_SECS (defaut 5).

- src/auth/mod.rs
  - Module d'authentification ; extracteur Axum AuthUser(pub Uuid) qui lit Authorization: Bearer <token>.
  - Pas encore applique aux routes existantes (le front n'envoie pas le header).

- src/auth/jwt.rs
  - Claims { sub, iat, exp }, create_token et verify_token (HS256, leeway 0, erreur generique 401).
  - Contient les tests unitaires JWT.

- src/cors.rs
  - build_cors_layer(&Config) : whitelist d'origines (CORS_ALLOWED_ORIGINS), methodes GET/POST/PATCH/DELETE/OPTIONS, headers Content-Type/Authorization, max_age 3600, sans credentials.
  - Le serveur ne rejette pas : une origine non listee recoit une reponse sans Access-Control-Allow-Origin et le navigateur bloque. Les apps natives n'envoient pas d'Origin.
  - Contient les tests CORS (mini-Router, sans base de donnees).

- src/rate_limit.rs
  - login_rate_limit_layer(per_minute) : rate limiting de POST /auth/login par IP (tower_governor, burst N, un jeton toutes les 60/N s).
  - Cle = SmartIpKeyExtractor (X-Forwarded-For / X-Real-IP, puis IP du pair) : falsifiable si le serveur est expose sans reverse proxy.
  - Reponse 429 JSON { "error": ... } avec les en-tetes retry de la lib ; tache tokio de nettoyage (retain_recent). Contient ses tests.

- src/db.rs
  - Creation du pool PostgreSQL (sqlx) a partir de la config.

- src/routes.rs
  - Construction du routeur HTTP principal.
  - Associe endpoints users/workouts/health/analysis aux handlers.

- src/errors.rs
  - Erreurs applicatives centralisees et conversion en reponses HTTP.
  - Type principal : AppError (IntoResponse). Inclut NotImplemented -> 501 et ServiceUnavailable -> 503.

### 2) Handlers HTTP

- src/handlers/mod.rs
  - Module d'agregation des handlers.

- src/handlers/health.rs
  - Endpoint(s) de health check.

- src/handlers/user.rs
  - Endpoints utilisateurs (creation, login, lecture profil, etc.).

- src/handlers/program.rs
  - get_program : GET /workouts/program, protege par AuthUser (401 sans token) ; delegue a ProgramService (200 generated/cache, 503).

- src/handlers/workout.rs
  - Endpoints workouts/exercises (CRUD et operations associees).

- src/handlers/analysis.rs
  - Endpoints d'analyse mouvement/video.
  - Modeles de payload/reponse exposes dans ce module : AnalyzeQuery, AnalysisResponse, FormScores, FeedbackComment, AnalysisMetrics, SupportedExercisesResponse, ErrorResponse.

### 3) Modeles metier

- src/models/mod.rs
  - Module d'agregation des modeles.

- src/models/user.rs
  - Entites et DTOs utilisateurs.
  - Types principaux : FitnessLevel, User, CreateUserRequest, CreateUserResponse, LoginRequest.

- src/models/program.rs
  - ProgramResponse, ProgramWorkout, ProgramExercise (camelCase), conformes a openapi.yaml (Serialize + Deserialize, pour relire le cache). Schema provisoire.
  - CachedProgram : ligne de cached_programs (programme en serde_json::Value).

- src/models/workout.rs
  - Entites et DTOs workout/exercise/set.
  - Types principaux : WeightUnit, Workout, Exercise, CreateWorkoutRequest, UpdateWorkoutRequest, CreateExerciseRequest.

### 4) Repositories (acces donnees)

- src/repositories/mod.rs
  - Module d'agregation des repositories.

- src/repositories/user.rs
  - Acces DB pour utilisateurs.
  - Type principal : UserRepository.

- src/repositories/program.rs
  - Acces DB pour cached_programs : upsert et find_by_user.
  - Type principal : ProgramRepository (utilise par ProgramService).

- src/repositories/workout.rs
  - Acces DB pour workouts/exercises.
  - Type principal : WorkoutRepository.

### 5) Services (logique metier)

- src/services/mod.rs
  - Module d'agregation des services.

- src/services/program.rs
  - ProgramService : appelle le moteur ML (POST {AI_SERVICE_URL}/api/v1/program/generate, contrat PROVISOIRE), convertit la reponse en ProgramResponse, ecrit/lit le cache cached_programs.
  - DTO ML provisoires (snake_case) separes de ProgramResponse. Aucun corps de requete/reponse n'est logue (injured_zones = donnee de sante).

- src/services/user.rs
  - Logique metier utilisateur (validation, orchestration repository).
  - Type principal : UserService.

- src/services/workout.rs
  - Logique metier workouts/exercises.
  - Type principal : WorkoutService.

### 6) Base de donnees (migrations)

- migrations/0001_create_users.sql
  - Creation initiale de la table users.

- migrations/0002_add_password_to_users.sql
  - Ajout du mot de passe utilisateur.

- migrations/0003_add_fitness_goals.sql
  - Ajout des objectifs fitness utilisateur.

- migrations/0004_create_workouts_exercises.sql
  - Creation des tables workouts et exercises.

- migrations/0005_add_sets_data_to_exercises.sql
  - Extension des donnees de series associees aux exercices.

- migrations/0008_create_cached_programs.sql
  - Table cached_programs (un dernier programme connu par utilisateur, JSONB, ON DELETE CASCADE) : secours si le service IA est indisponible.

### 6 bis) Tests

- src/tests/mod.rs
  - Declare les modules de tests (compiles uniquement en test) ; chaque #[sqlx::test] utilise une base temporaire creee depuis DATABASE_URL (role avec CREATEDB).

- src/tests/common.rs
  - Helpers : build_test_state, test_server (routeur reel via axum-test), register_user, test_jwt_config.

- src/tests/user_service.rs, src/tests/workout_service.rs
  - Tests des services appeles directement (creation, doublon, validation, login, COALESCE, ownership, exercices).

- src/tests/program_repository.rs
  - Tests de ProgramRepository (table, upsert, find_by_user, CASCADE).

- src/tests/program_endpoint.rs
  - Tests de GET /workouts/program avec un faux moteur ML axum (OK, ML eteint avec/sans cache, ML lent, statut 500, sans token).

- src/tests/e2e.rs
  - Tests end-to-end : POST /users -> POST /auth/login -> GET /workouts/program (generated, puis cache quand le faux moteur ML s'arrete), 401 (sans token, token altere, token expire), 429 (rate limit login).

- .github/workflows/backend.yml
  - CI GitHub Actions du backend : Postgres 16 (superuser, donc CREATEDB pour #[sqlx::test]), cargo build et cargo test dans back/, sur push et pull_request touchant back/**.

- src/tests/http.rs
  - Tests HTTP : POST /users, POST /auth/login, GET /users/:id, workouts.

### 7) Fichiers techniques lies au code

- Cargo.toml
  - Manifest Rust (dependencies, metadata, profil de build).

- openapi.yaml
  - Contrat OpenAPI 3.0.3 ecrit avant le code (contract-first) ; pour l'instant GET /workouts/program.

- Dockerfile
  - Build et execution conteneurises du backend back.

- README.md
  - Documentation d'usage du module back.

## Notes de maintenance

- Les modules mod.rs servent de points d'entree de namespace ; garder les exports synchronises avec la structure des dossiers.
- Les migrations SQL sont ordonnees et versionnees ; eviter toute modification destructive d'une migration deja appliquee en environnement partage.
- Les contrats entre handlers, services et repositories doivent rester alignes sur les modeles de src/models.
