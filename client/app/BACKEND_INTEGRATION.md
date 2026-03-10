# Backend Integration - LiftUp Flutter App

## 🎯 Vue d'ensemble

Le client Flutter est maintenant connecté au backend Rust/Axum. Cette intégration permet de :
- Créer des utilisateurs
- Vérifier la santé du backend
- Gérer les erreurs et les réponses

## 📦 Architecture

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart       # Configuration API (URL, timeouts)
│   ├── models/
│   │   ├── user.dart                # Modèles User et DTOs
│   │   └── api_response.dart        # Réponses API génériques
│   ├── services/
│   │   ├── api_client.dart          # Configuration Dio
│   │   └── user_api_service.dart    # Endpoints utilisateur
│   ├── repositories/
│   │   └── user_repository.dart     # Logique métier
│   └── providers/
│       └── user_providers.dart      # Riverpod providers
└── features/
    └── home/
        └── backend_test_screen.dart # Écran de test
```

## 🚀 Installation

### 1. Installer les dépendances

```bash
cd /home/arthur/Eip/client/app
flutter pub get
```

### 2. Générer le code (Freezed + JSON Serialization)

```bash
dart run build_runner build --delete-conflicting-outputs
```

Cette commande génère :
- `*.freezed.dart` - Classes immutables avec Freezed
- `*.g.dart` - Sérialisation JSON

### 3. Configurer l'URL du backend

Le fichier [app_constants.dart](lib/core/constants/app_constants.dart) contient :

```dart
// Pour Android Emulator
static const String baseUrl = 'http://10.0.2.2:8080';

// Pour iOS Simulator
// static const String baseUrl = 'http://localhost:8080';

// Pour device réel (remplacer par votre IP locale)
// static const String baseUrl = 'http://192.168.x.x:8080';
```

**Note importante :** Sur Android Emulator, `10.0.2.2` pointe vers le `localhost` de votre machine hôte.

## 🧪 Test de l'intégration

### 1. Démarrer le backend

```bash
cd /home/arthur/Eip/back
docker-compose up -d
```

Vérifier que le backend fonctionne :
```bash
curl http://localhost:8080/health
# Devrait retourner: {"status":"ok","service":"liftup-backend"}
```

### 2. Lancer l'application Flutter

```bash
cd /home/arthur/Eip/client/app

# Android
flutter run

# iOS
flutter run

# Web (pour test rapide)
flutter run -d chrome
```

### 3. Accéder à l'écran de test

L'écran `BackendTestScreen` vous permet de :
- ✅ Vérifier la santé du backend
- ✅ Créer un nouvel utilisateur
- ✅ Voir les réponses en temps réel
- ✅ Gérer les erreurs

## 📝 Utilisation du code

### Health Check

```dart
// Dans un widget
final healthCheck = ref.watch(healthCheckProvider);

healthCheck.when(
  data: (isHealthy) => Text(isHealthy ? 'OK' : 'Error'),
  loading: () => CircularProgressIndicator(),
  error: (error, _) => Text('Error: $error'),
);
```

### Créer un utilisateur

```dart
// 1. Créer la requête
final request = CreateUserRequest(
  email: 'test@example.com',
  username: 'testuser',
  displayName: 'Test User',
  heightCm: 175,
  weightKg: 70.5,
  fitnessLevel: FitnessLevel.beginner,
);

// 2. Appeler le provider
ref.read(userCreationProvider.notifier).createUser(request);

// 3. Observer le résultat
final userCreationState = ref.watch(userCreationProvider);

userCreationState.when(
  data: (response) {
    if (response != null) {
      print('User created: ${response.id}');
    }
  },
  loading: () => showLoader(),
  error: (error, _) => showError(error),
);
```

### Accès direct au service

```dart
final apiService = ref.read(userApiServiceProvider);

try {
  final response = await apiService.createUser(request);
  print('Success: ${response.username}');
} on ApiException catch (e) {
  print('Error: ${e.message} (${e.statusCode})');
}
```

## 🔧 Configuration réseau

### Android

Ajoutez les permissions dans `android/app/src/main/AndroidManifest.xml` :

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Pour autoriser les connexions HTTP non sécurisées (développement uniquement), ajoutez :

```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

### iOS

Dans `ios/Runner/Info.plist`, ajoutez :

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## 🐛 Débogage

### Vérifier la connexion

```bash
# Sur Android Emulator
adb shell ping -c 4 10.0.2.2

# Tester l'API depuis l'émulateur
adb shell curl http://10.0.2.2:8080/health
```

### Logs de l'application

Les logs Dio affichent :
- 📤 Requêtes sortantes (URL, headers, body)
- 📥 Réponses (status, body)
- ❌ Erreurs

Recherchez `[API]` dans les logs :
```bash
flutter logs | grep API
```

## 📚 Dépendances ajoutées

```yaml
dependencies:
  dio: ^5.7.0                    # Client HTTP
  json_annotation: ^4.9.0        # Annotations JSON

dev_dependencies:
  json_serializable: ^6.8.0      # Génération code JSON
```

## ✅ Checklist avant production

- [ ] Changer `baseUrl` pour l'URL de production
- [ ] Retirer `usesCleartextTraffic` (Android)
- [ ] Retirer `NSAllowsArbitraryLoads` (iOS)
- [ ] Ajouter authentification (tokens JWT)
- [ ] Implémenter retry logic
- [ ] Configurer certificate pinning
- [ ] Désactiver les logs en production

## 🔗 Endpoints disponibles

| Method | Endpoint    | Description           |
|--------|-------------|-----------------------|
| GET    | /health     | Health check          |
| POST   | /users      | Créer un utilisateur  |

## 💡 Prochaines étapes

1. Implémenter l'authentification (JWT)
2. Ajouter la gestion des sessions
3. Créer les endpoints pour les programmes d'entraînement
4. Ajouter l'upload de vidéos
5. Implémenter l'analyse de mouvement

---

**Auteur :** Backend Integration  
**Date :** Mars 2026  
**Backend :** Rust/Axum on port 8080  
**Frontend :** Flutter avec Riverpod
