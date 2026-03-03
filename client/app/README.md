# LiftUp Mobile App - Frontend Documentation

**Status:** Active Development (March 3, 2026)  
**Framework:** Flutter 3.11.0+  
**Architecture:** Feature-Based Clean Architecture  

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Setup & Installation](#setup--installation)
- [Development Guidelines](#development-guidelines)
- [State Management](#state-management)
- [Navigation](#navigation)
- [Building & Testing](#building--testing)
- [Project Dependencies](#project-dependencies)

---

## Overview

The LiftUp Mobile App is a feature-rich Flutter application providing personalized AI-powered fitness coaching. Built with modern Flutter best practices, the app implements clean architecture principles and reactive state management using Riverpod.

**Key Features:**
- 🏋️ Adaptive workout programs
- 📊 Progress tracking and analytics
- 🤖 AI-powered personalization
- 🎯 Nutrition management
- 📱 Multi-platform support (iOS, Android, Web, Desktop)

---

## Architecture

### Architecture Approach: Feature-Based Clean Architecture

The project uses **feature-based clean architecture** which organizes code by feature rather than by layer. This approach:

- **Improves Scalability**: Each feature is self-contained and independent
- **Enhances Maintainability**: Changes to one feature don't affect others
- **Facilitates Testing**: Features can be tested in isolation
- **Enables Team Collaboration**: Teams can work on different features independently

### Layered Structure Within Each Feature

```
feature/
├── presentation/        # UI Layer
│   ├── pages/          # Full-page screens
│   ├── widgets/        # Reusable UI components
│   └── providers.dart   # Riverpod providers for this feature
├── data/               # Data Layer
│   ├── datasources/    # Remote/Local data sources
│   ├── models/         # Data transfer objects
│   └── repositories/   # Repository implementations
└── domain/             # Business Logic Layer
    ├── entities/       # Core business objects
    ├── repositories/   # Repository abstractions
    └── usecases/       # Business use cases
```

---

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── config/                      # Global configuration
│   ├── router.dart             # GoRouter configuration
│   ├── theme.dart              # Theme definitions
│   └── providers.dart          # Global Riverpod providers
├── features/                    # Feature modules
│   └── home/                   # Home feature
│       ├── presentation/        # UI layer
│       │   ├── pages/
│       │   │   └── home_page.dart
│       │   └── widgets/
│       ├── data/               # Data layer
│       └── domain/             # Business logic layer
└── core/                        # Shared utilities
    ├── constants/
    │   └── app_constants.dart  # App-wide constants
    └── extensions/             # Dart extensions
```

---

## Setup & Installation

### Prerequisites

- Flutter SDK: ^3.11.0
- Dart: ^3.11.0
- Android SDK (for Android development)
- Xcode (for iOS development)
- IDE: VS Code, Android Studio, or IntelliJ IDEA

### Installation Steps

1. **Navigate to the project directory:**
   ```bash
   cd client/app
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run code generators (for Riverpod & Freezed):**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app:**
   ```bash
   # On connected device
   flutter run

   # Specify device
   flutter run -d <device-id>

   # Release build
   flutter run --release
   ```

---

## Development Guidelines

### Creating a New Feature

1. **Create feature directory structure:**
   ```bash
   mkdir -p lib/features/my_feature/{presentation/{pages,widgets},data,domain}
   ```

2. **Create domain layer first (business logic):**
   - Define entities
   - Define repository abstractions
   - Implement use cases

3. **Create data layer (data sources):**
   - Define models extending entities
   - Create data sources (Remote/Local)
   - Implement repositories

4. **Create presentation layer (UI):**
   - Create screens/pages
   - Create widgets
   - Define providers for state management

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable names
- Add comments for complex logic
- Keep functions/methods focused on single responsibility

### File Naming Conventions

- Pages: `*_page.dart` (e.g., `home_page.dart`)
- Widgets: `*_widget.dart` (e.g., `workout_card_widget.dart`)
- Models: `*_model.dart` (e.g., `user_model.dart`)
- Repositories: `*_repository.dart` (e.g., `workout_repository.dart`)
- Providers: `*_provider.dart` (e.g., `home_provider.dart`)

---

## State Management

### Technology: Riverpod

We use **Riverpod** for state management for its:
- ✅ Type safety and code generation
- ✅ Simple API and less boilerplate
- ✅ Excellent testing support
- ✅ Provider composition and reusability
- ✅ Built-in dependencies injection

### Provider Types Used

1. **Simple Providers:**
   ```dart
   final counterProvider = StateProvider<int>((ref) => 0);
   ```

2. **Future Providers (for async operations):**
   ```dart
   final userProvider = FutureProvider<User>((ref) async {
     return await fetchUser();
   });
   ```

3. **State Notifier Providers (for complex state):**
   ```dart
   final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>(
     (ref) => AppStateNotifier(),
   );
   ```

4. **Family Providers (parameterized):**
   ```dart
   final userProvider = FutureProvider.family<User, String>((ref, userId) async {
     return await fetchUser(userId);
   });
   ```

### Managing State

Access state in widgets using `ConsumerWidget` or `ref.watch`:

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myProvider);
    
    return Text(state.toString());
  }
}
```

---

## Navigation

### Technology: GoRouter

We use **GoRouter** for navigation with its:
- ✅ Declarative routing
- ✅ Deep linking support
- ✅ Easy state preservation
- ✅ Powerful error handling
- ✅ Type-safe routes

### Route Configuration

Routes are defined in [lib/config/router.dart](lib/config/router.dart):

```dart
GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
      name: 'home',
    ),
  ],
);
```

### Navigating Between Routes

```dart
// Navigate to route
context.go('/home');

// Navigate with name
context.goNamed('home');

// Navigate with parameters
context.go('/workout/123');

// Pop navigation
context.pop();
```

---

## Building & Testing

### Run on Android

```bash
# Debug build
flutter run -d android

# Release build
flutter build apk --release

# App bundle for Play Store
flutter build appbundle --release
```

### Run on iOS

```bash
# Debug build
flutter run -d ios

# Release build
flutter build ios --release
```

### Run Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Watch mode
flutter test --watch
```

### Check Code Quality

```bash
# Analyze code
flutter analyze

# Format code
dart format lib/

# Run lints
flutter pub get && flutter analyze
```

---

## Project Dependencies

### Core Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| **flutter_riverpod** | ^2.4.0 | State management |
| **go_router** | ^13.2.0 | Navigation routing |
| **freezed_annotation** | ^2.4.1 | Immutable data classes |
| **cupertino_icons** | ^1.0.8 | iOS-style icons |

### Dev Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| **build_runner** | ^2.4.0 | Code generation |
| **riverpod_generator** | ^2.3.0 | Generate Riverpod providers |
| **freezed** | ^2.4.1 | Generate immutable classes |
| **flutter_lints** | ^6.0.0 | Lint rules |

### Running Code Generators

```bash
# Build once
flutter pub run build_runner build

# Watch for changes
flutter pub run build_runner watch

# Clean and rebuild
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Folder Structure Explained

```
lib/
├── main.dart
│   └── App entry point with ProviderScope and MaterialApp.router
│
├── config/
│   ├── router.dart          # GoRouter configuration
│   ├── theme.dart           # Light/Dark theme definitions
│   └── providers.dart       # Global app state providers
│
├── features/
│   └── home/
│       ├── presentation/
│       │   ├── pages/
│       │   │   └── home_page.dart          # Home screen UI
│       │   └── widgets/                    # Reusable components
│       ├── data/                          # Data layer
│       │   ├── datasources/
│       │   ├── models/
│       │   └── repositories/
│       └── domain/                        # Business logic
│           ├── entities/
│           ├── repositories/
│           └── usecases/
│
└── core/
    ├── constants/
    │   └── app_constants.dart    # App-wide constants & spacing
    └── extensions/               # Dart/Flutter extensions
```

---

## Best Practices

### ✅ Do's

- Use Riverpod for all state management
- Keep features modular and independent
- Place UI logic in presentation layer
- Use meaningful variable and function names
- Write tests for business logic
- Use const constructors where possible
- Separate business logic from UI
- Use composition over inheritance

### ❌ Don'ts

- Don't access data layer directly from UI
- Don't put business logic in widgets
- Don't use BuildContext in providers
- Don't access one feature from another
- Don't overuse global state
- Don't create monolithic widgets
- Don't hardcode strings/values

---

## Troubleshooting

### "Riverpod code generator not running"
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### "GoRouter not found"
```bash
flutter pub get
flutter pub run build_runner build
```

### "Android build fails"
```bash
flutter clean
flutter pub get
flutter run
```

---

## Contributing

When adding new features:

1. Create feature directory following the structure
2. Implement domain layer first
3. Implement data layer
4. Implement presentation layer
5. Write tests
6. Update this README with feature documentation
7. Submit pull request with detailed description

---

## Resources

- [Flutter Documentation](https://flutter.dev)
- [Dart Documentation](https://dart.dev)
- [Riverpod Documentation](https://riverpod.dev)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Clean Architecture Guide](https://resocoder.com/clean-architecture-tdd)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | March 3, 2026 | Initial setup with feature-based architecture, Riverpod, and GoRouter |

---

**Last Updated:** March 3, 2026  
**Maintainer:** LiftUp Team
