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
  - Type principal : Config.

- src/db.rs
  - Creation du pool PostgreSQL (sqlx) a partir de la config.

- src/routes.rs
  - Construction du routeur HTTP principal.
  - Associe endpoints users/workouts/health/analysis aux handlers.

- src/errors.rs
  - Erreurs applicatives centralisees et conversion en reponses HTTP.
  - Type principal : AppError (IntoResponse).

### 2) Handlers HTTP

- src/handlers/mod.rs
  - Module d'agregation des handlers.

- src/handlers/health.rs
  - Endpoint(s) de health check.

- src/handlers/user.rs
  - Endpoints utilisateurs (creation, login, lecture profil, etc.).

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

- src/models/workout.rs
  - Entites et DTOs workout/exercise/set.
  - Types principaux : WeightUnit, Workout, Exercise, CreateWorkoutRequest, UpdateWorkoutRequest, CreateExerciseRequest.

### 4) Repositories (acces donnees)

- src/repositories/mod.rs
  - Module d'agregation des repositories.

- src/repositories/user.rs
  - Acces DB pour utilisateurs.
  - Type principal : UserRepository.

- src/repositories/workout.rs
  - Acces DB pour workouts/exercises.
  - Type principal : WorkoutRepository.

### 5) Services (logique metier)

- src/services/mod.rs
  - Module d'agregation des services.

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

### 7) Fichiers techniques lies au code

- Cargo.toml
  - Manifest Rust (dependencies, metadata, profil de build).

- Dockerfile
  - Build et execution conteneurises du backend back.

- README.md
  - Documentation d'usage du module back.

## Notes de maintenance

- Les modules mod.rs servent de points d'entree de namespace ; garder les exports synchronises avec la structure des dossiers.
- Les migrations SQL sont ordonnees et versionnees ; eviter toute modification destructive d'une migration deja appliquee en environnement partage.
- Les contrats entre handlers, services et repositories doivent rester alignes sur les modeles de src/models.
