# Documentation des fichiers de code (client/app)

## Portée
Ce document couvre les fichiers Dart de `client/app` considérés comme du code applicatif écrit dans le projet.

Sont exclus volontairement :
- les fichiers générés (`*.g.dart`, `*.freezed.dart`),
- les artefacts de build,
- les fichiers plateformes générés automatiquement (Android/iOS/macOS/etc.).

## Arborescence documentée

### 1) Démarrage et configuration

- `lib/main.dart`
  - Point d'entrée Flutter.
  - Définit l'app racine avec Riverpod (`MyApp`) et branche thème + routing.

- `lib/config/router.dart`
  - Configuration centralisée de navigation via `GoRouter`.
  - Déclare routes d'authentification (`/onboarding`, `/login`, `/register`) et routes principales dans `ShellRoute`.
  - Gère transitions personnalisées (`_buildPage`, `_buildAuthPage`) et index de navigation (`_getNavIndex`).

- `lib/config/theme.dart`
  - Définit le thème global de l'application via `AppTheme`.

- `lib/config/providers.dart`
  - Regroupe des modèles d'état et notifiers globaux.
  - Classes clés : `UserProfile`, `Exercise`, `Workout`, `WorkoutDay`, `AppState`, `AppStateNotifier`, `WorkoutState`, `WorkoutStateNotifier`.

### 2) Core (configuration, modèles, services, providers, utilitaires)

- `lib/core/config/api_config.dart`
  - Paramètres de configuration API (URL de base, endpoints, constantes réseau).
  - Classe : `ApiConfig`.

- `lib/core/constants/app_constants.dart`
  - Centralise constantes globales UI/métier.
  - Classe : `AppConstants`.

- `lib/core/examples/backend_integration_examples.dart`
  - Exemples d'intégration backend et widgets de démonstration.
  - Classes : `HealthCheckWidget`, `CreateUserButton`, `UserRegistrationForm`, `ApiResponseHandler`.

- `lib/core/models/api_response.dart`
  - Modèles standard de réponse API.
  - Classes : `ApiResponse<T>`, `HealthCheckResponse`, `ErrorResponse`.

- `lib/core/models/user.dart`
  - Modèles utilisateur et payloads d'inscription.
  - Types : `FitnessLevel`, `User`, `CreateUserRequest`, `CreateUserResponse`.

- `lib/core/models/workout.dart`
  - Modèles entraînement/exercice/séries et requêtes API associées.
  - Types : `WeightUnit`, `SetModel`, `ExerciseModel`, `WorkoutModel`, `CreateWorkoutRequest`, `UpdateWorkoutRequest`, `CreateExerciseRequest`, `UpdateExerciseRequest`.

- `lib/core/providers/auth_provider.dart`
  - Gestion d'état d'authentification avec Riverpod.
  - Types : `AuthState`, `AuthNotifier`.

- `lib/core/providers/exercise_provider.dart`
  - Gestion d'état liste d'exercices.
  - Types : `ExerciseListState`, `ExerciseListNotifier`.

- `lib/core/providers/user_providers.dart`
  - Providers orientés création utilisateur.
  - Type : `UserCreationNotifier`.

- `lib/core/providers/workout_provider.dart`
  - Gestion d'état des données workout côté API.
  - Types : `ApiWorkoutState`, `ApiWorkoutNotifier`.

- `lib/core/repositories/user_repository.dart`
  - Repository utilisateur (abstraction accès données/services).
  - Classe : `UserRepository`.

- `lib/core/services/api_client.dart`
  - Client HTTP de base et logique commune de requêtes.
  - Classe : `ApiClient`.

- `lib/core/services/auth_api_service.dart`
  - Appels backend liés à l'authentification.
  - Types : `AuthApiService`, `ApiException`, `LoginResponse`, `UserProfileResponse`.

- `lib/core/services/exercise_api_service.dart`
  - Appels backend des exercices.
  - Types : `ExerciseInfo`, `ExerciseApiService`.

- `lib/core/services/user_api_service.dart`
  - Appels backend utilisateur (CRUD/profil).
  - Types : `ApiException`, `UserApiService`.

- `lib/core/services/video_analysis_service.dart`
  - Service d'analyse vidéo (requêtes, parsing, objets de résultat).
  - Types : `VideoAnalysisService`, `VideoAnalysisResult`, `FormScores`, `FeedbackComment`, `AnalysisMetrics`, `VideoAnalysisException`.

- `lib/core/services/workout_api_service.dart`
  - Appels backend workouts/programmes.
  - Classe : `WorkoutApiService`.

- `lib/core/utils/date_utils.dart`
  - Utilitaires de formatage/manipulation de dates.
  - Classe : `AppDateUtils`.

- `lib/core/utils/workout_timer.dart`
  - Timer d'entraînement + état associé.
  - Types : `WorkoutTimerState`, `WorkoutTimer`.

- `lib/core/widgets/main_scaffold.dart`
  - Scaffold principal de l'app (structure de layout/navigation).
  - Types : `AppColors`, `MainScaffold`.

### 3) Feature Auth

- `lib/features/auth/auth.dart`
  - Barrel file d'exports publics du module Auth.

- `lib/features/auth/presentation/pages/onboarding_page.dart`
  - Écran d'onboarding/introduction.
  - Types : `OnboardingPage`, `_OnboardingPageState`, `_OnboardingData`.

- `lib/features/auth/presentation/pages/login_page.dart`
  - Écran de connexion (formulaire + actions sociales).
  - Types : `LoginPage`, `_LoginPageState`, `_SocialLoginButton`.

- `lib/features/auth/presentation/pages/register_page.dart`
  - Écran d'inscription (formulaire + actions sociales).
  - Types : `RegisterPage`, `_RegisterPageState`, `_SocialRegisterButton`.

### 4) Feature Camera

- `lib/features/camera/presentation/pages/camera_page.dart`
  - Écran caméra principal.
  - Gère l'état caméra/commentaires et l'initialisation caméra.
  - Types : `CameraPage`, `_CameraPageState`.

- `lib/features/camera/presentation/widgets/camera_preview_widget.dart`
  - Widget d'aperçu caméra + overlay visuel.
  - Types : `CameraPreviewWidget`, `_CameraOverlayPainter`.

- `lib/features/camera/presentation/widgets/lm_comments_section.dart`
  - Section commentaires/feedback "LM Coach".
  - Types : `LMCommentsSection`, `_LMCommentsSectionState`, `_CommentTypeIcon`, `LMComment`, `CommentType`.

### 5) Feature Home

- `lib/features/home/presentation/pages/home_page.dart`
  - Écran d'accueil principal (`HomePage`).

- `lib/features/home/backend_test_screen.dart`
  - Écran de test manuel d'intégration backend.
  - Types : `BackendTestScreen`, `_BackendTestScreenState`.

### 6) Feature Movement Analysis

- `lib/features/movement_analysis/presentation/pages/movement_analysis_page.dart`
  - Écran d'analyse de mouvement (flux principal).
  - Types : `MovementAnalysisPage`, `_MovementAnalysisPageState`.

- `lib/features/movement_analysis/presentation/pages/video_analysis_results_page.dart`
  - Écran d'affichage des résultats d'analyse vidéo.
  - Contient aussi une page d'analyse et un painter de ligne pointillée.
  - Types : `VideoAnalysisResultsPage`, `_VideoAnalysisResultsPageState`, `VideoAnalysisPage`, `_VideoAnalysisPageState`, `DashedLinePainter`.

### 7) Feature Profile

- `lib/features/profile/presentation/pages/profile_page.dart`
  - Écran profil utilisateur.
  - Types : `ProfilePage`, `_ProfilePageState`.

### 8) Feature Program

- `lib/features/program/presentation/pages/program_page.dart`
  - Écran programme/entraînement principal (version active).
  - Gère affichage des workouts, interaction active workout, sheets de détails.
  - Types : `ProgramPage`, `_ProgramPageState`, `_ActiveWorkoutSheet`, `_WorkoutDetailsSheet`.

- `lib/features/program/presentation/pages/program_page_backup.dart`
  - Version backup historique de la page programme.
  - Types : `ProgramPage`, `_ProgramPageState`, `_WorkoutDetailsSheet`.

- `lib/features/program/presentation/pages/program_page_old.dart`
  - Ancienne version conservée de la page programme.
  - Types : `ProgramPage`, `_ProgramPageState`, `_ActiveWorkoutSheet`, `_ActiveWorkoutSheetState`, `_WorkoutDetailsSheet`.

### 9) Feature Video

- `lib/features/video/video.dart`
  - Barrel file d'exports publics du module vidéo.

- `lib/features/video/domain/entities/video_entity.dart`
  - Entité domaine d'une vidéo et statut d'upload.
  - Types : `VideoEntity`, `VideoUploadStatus`.

- `lib/features/video/domain/repositories/video_repository.dart`
  - Contrat repository du domaine vidéo.
  - Type : `VideoRepository` (abstrait).

- `lib/features/video/data/models/video_model.dart`
  - Modèle data vidéo (implémentation de l'entité domaine).
  - Type : `VideoModel`.

- `lib/features/video/presentation/pages/video_selection_page.dart`
  - Écran de sélection du mode/source vidéo.
  - Types : `VideoSelectionPage`, `_VideoOptionCard`.

- `lib/features/video/presentation/pages/video_recording_page.dart`
  - Écran d'enregistrement vidéo.
  - Types : `VideoRecordingPage`, `_VideoRecordingPageState`.

- `lib/features/video/presentation/pages/video_preview_page.dart`
  - Écran de prévisualisation avant upload/analyse.
  - Types : `VideoPreviewPage`, `_VideoPreviewPageState`.

- `lib/features/video/presentation/pages/video_upload_page.dart`
  - Écran d'upload et de suivi d'état d'envoi/analyse.
  - Types : `VideoUploadPage`, `_VideoUploadPageState`, `_UploadState`, `_ExerciseTypeSelector`.

- `lib/features/video/presentation/widgets/video_card.dart`
  - Carte UI de représentation d'une vidéo.
  - Type : `VideoCard`.

- `lib/features/video/presentation/widgets/video_list.dart`
  - Liste UI de vidéos.
  - Type : `VideoList`.

### 10) Tests Flutter

- `test/features/camera/presentation/pages/camera_page_test.dart`
  - Tests widget de `CameraPage` : rendu initial, app bar, toggle, accessibilité, cycle de vie.

- `test/features/camera/presentation/widgets/lm_comments_section_test.dart`
  - Tests widget de `LMCommentsSection` : rendu UI, interactions, modèle `LMComment`, enum `CommentType`.

- `test/widget_test.dart`
  - Test Flutter "smoke" généré à l'initialisation (counter).
  - À aligner avec l'UI réelle actuelle si nécessaire.

## Notes de maintenance

- Les fichiers `program_page_backup.dart` et `program_page_old.dart` sont utiles comme historique, mais peuvent créer de la confusion si la version active n'est pas explicitement référencée.
- Les fichiers barrel (`auth.dart`, `video.dart`) simplifient les imports et doivent rester synchronisés avec les exports réels du module.
- `test/widget_test.dart` semble être un test template Flutter par défaut et mérite d'être remplacé par un test métier de l'écran d'entrée réel.
