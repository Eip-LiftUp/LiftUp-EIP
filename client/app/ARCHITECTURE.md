# LiftUp Frontend - Architecture Structure Documentation

**Date:** March 3, 2026  
**Version:** 1.0  
**Architecture Pattern:** Feature-Based Clean Architecture

---

## 📁 Complete Project Structure

```
lib/
│
├── 📄 main.dart
│   └── Application entry point with ProviderScope and MaterialApp.router
│
├── 📁 config/
│   ├── 📄 router.dart
│   │   └── GoRouter configuration for all app routes
│   ├── 📄 theme.dart
│   │   └── Material 3 light and dark theme definitions
│   └── 📄 providers.dart
│       └── Global Riverpod state providers for app-level state
│
├── 📁 features/
│   └── 📁 home/
│       ├── 📁 presentation/
│       │   ├── 📁 pages/
│       │   │   └── 📄 home_page.dart
│       │   │       └── Main home screen UI
│       │   └── 📁 widgets/
│       │       ├── [TBD] workout_card_widget.dart
│       │       ├── [TBD] progress_widget.dart
│       │       └── [TBD] stats_widget.dart
│       ├── 📁 data/
│       │   ├── 📁 datasources/
│       │   │   ├── [TBD] remote_datasource.dart
│       │   │   └── [TBD] local_datasource.dart
│       │   ├── 📁 models/
│       │   │   └── [TBD] home_model.dart
│       │   └── 📁 repositories/
│       │       └── [TBD] home_repository_impl.dart
│       └── 📁 domain/
│           ├── 📁 entities/
│           │   └── [TBD] workout.dart
│           ├── 📁 repositories/
│           │   └── [TBD] home_repository.dart
│           └── 📁 usecases/
│               └── [TBD] get_workouts_usecase.dart
│
├── 📁 core/
│   ├── 📁 constants/
│   │   └── 📄 app_constants.dart
│   │       └── App-wide constants and spacing utilities
│   ├── 📁 extensions/
│   │   ├── [TBD] context_extensions.dart
│   │   ├── [TBD] string_extensions.dart
│   │   └── [TBD] num_extensions.dart
│   ├── 📁 utils/
│   │   ├── [TBD] logger.dart
│   │   └── [TBD] validators.dart
│   └── 📁 widgets/
│       ├── [TBD] custom_app_bar.dart
│       ├── [TBD] loading_widget.dart
│       └── [TBD] error_widget.dart
│
└── 📁 build/
    └── Gradle build artifacts (generated)
```

---

## 🏗️ Architecture Layers Explained

### Presentation Layer (UI)
**Location:** `features/[feature]/presentation/`

- **Pages:** Full-screen UI components
  - Stateless/Stateful widgets representing complete screens
  - Connected to Riverpod providers for state
  - Handle navigation logic

- **Widgets:** Reusable UI components
  - Cards, buttons, dialogs, custom widgets
  - Receive data as parameters
  - Stateless when possible

**Example:**
```
features/home/presentation/
├── pages/
│   └── home_page.dart          # Full home screen
└── widgets/
    ├── workout_card_widget.dart
    ├── progress_chart.dart
    └── daily_stats_widget.dart
```

### Data Layer
**Location:** `features/[feature]/data/`

- **Models:** DTO (Data Transfer Objects)
  - Extend domain entities
  - Include JSON serialization
  - Handle API response mapping

- **DataSources:** Data access abstraction
  - Remote: API calls
  - Local: Database/SharedPreferences

- **Repositories Implementation:** Implements domain repository interface
  - Combines multiple datasources
  - Handles error transformation
  - Business logic orchestration

**Example:**
```
features/home/data/
├── models/
│   └── workout_model.dart      # DTO for Workout entity
├── datasources/
│   ├── home_remote_datasource.dart
│   └── home_local_datasource.dart
└── repositories/
    └── home_repository_impl.dart
```

### Domain Layer (Business Logic)
**Location:** `features/[feature]/domain/`

- **Entities:** Core business objects
  - Independent of UI/Data layers
  - Pure Dart classes
  - Represent core business concepts

- **Repository Abstractions:**
  - Define contracts for data access
  - Written as abstract classes
  - Implemented in data layer

- **Use Cases:** Business logic operations
  - Execute specific business operations
  - Use one or more repositories
  - Implement single responsibility principle

**Example:**
```
features/home/domain/
├── entities/
│   └── workout.dart            # Pure business entity
├── repositories/
│   └── home_repository.dart    # Abstract interface
└── usecases/
    ├── get_workouts_usecase.dart
    └── log_workout_usecase.dart
```

---

## 🎯 Feature Anatomy: Complete Example

### Adding the "Workouts" Feature

```
features/workouts/
│
├── presentation/
│   ├── pages/
│   │   ├── workouts_list_page.dart      # List of all workouts
│   │   └── workout_detail_page.dart     # Single workout details
│   ├── widgets/
│   │   ├── workout_card_widget.dart
│   │   ├── difficulty_badge_widget.dart
│   │   └── duration_widget.dart
│   └── providers/
│       └── workouts_provider.dart       # Riverpod providers for this feature
│
├── data/
│   ├── models/
│   │   ├── workout_model.dart
│   │   └── exercise_model.dart
│   ├── datasources/
│   │   ├── workouts_remote_datasource.dart  # API calls
│   │   └── workouts_local_datasource.dart   # Local cache
│   └── repositories/
│       └── workouts_repository_impl.dart
│
└── domain/
    ├── entities/
    │   ├── workout.dart
    │   └── exercise.dart
    ├── repositories/
    │   └── workouts_repository.dart
    └── usecases/
        ├── get_all_workouts_usecase.dart
        ├── get_workout_by_id_usecase.dart
        └── start_workout_usecase.dart
```

---

## 🔄 Data Flow

### User Action → State Update → UI Rebuild

```
┌─────────────────────────────────────────────────────────┐
│ UI Layer (Presentation)                                 │
│ ┌────────────────────────────────────────────────────┐  │
│ │ Widget builds and displays data from provider      │  │
│ │ User taps button → calls provider method           │  │
│ └────────────────────────────────────────────────────┘  │
└─────────┬───────────────────────────────────────────────┘
          │ ref.read(provider.notifier).methodCall()
          ↓
┌─────────────────────────────────────────────────────────┐
│ State Management (Riverpod)                             │
│ ┌────────────────────────────────────────────────────┐  │
│ │ StateNotifier receives method call                 │  │
│ │ Calls appropriate use case                         │  │
│ │ Updates state and UI rebuilds                      │  │
│ └────────────────────────────────────────────────────┘  │
└─────────┬───────────────────────────────────────────────┘
          │ ref.read(workoutUseCase).execute()
          ↓
┌─────────────────────────────────────────────────────────┐
│ Domain Layer (Business Logic)                           │
│ ┌────────────────────────────────────────────────────┐  │
│ │ Use case receives call                             │  │
│ │ Applies business logic                             │  │
│ │ Calls repository method                            │  │
│ └────────────────────────────────────────────────────┘  │
└─────────┬───────────────────────────────────────────────┘
          │ repository.getWorkouts()
          ↓
┌─────────────────────────────────────────────────────────┐
│ Data Layer (Repositories & Data Sources)                │
│ ┌────────────────────────────────────────────────────┐  │
│ │ Repository decides data source (Remote/Local)     │  │
│ │ Fetches data and transforms to entities            │  │
│ │ Returns to use case                                │  │
│ └────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 📊 Feature Checklist Template

When creating a new feature, use this checklist:

### Domain Layer
- [ ] Create entity classes (`domain/entities/`)
- [ ] Define repository interface (`domain/repositories/`)
- [ ] Create use cases (`domain/usecases/`)

### Data Layer
- [ ] Create models extending entities (`data/models/`)
- [ ] Create remote datasource if API needed (`data/datasources/`)
- [ ] Create local datasource if caching needed (`data/datasources/`)
- [ ] Implement repository (`data/repositories/`)

### Presentation Layer
- [ ] Create pages for main screens (`presentation/pages/`)
- [ ] Create reusable widgets (`presentation/widgets/`)
- [ ] Create Riverpod providers (`presentation/providers.dart`)

### Integration
- [ ] Add routes to `config/router.dart`
- [ ] Add providers to feature or global scope
- [ ] Test feature independently
- [ ] Update documentation

---

## 📝 File Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Page | `*_page.dart` | `home_page.dart` |
| Widget | `*_widget.dart` | `workout_card_widget.dart` |
| Provider | `*_provider.dart` | `workout_provider.dart` |
| Repository | `*_repository.dart` or `*_repository_impl.dart` | `workout_repository_impl.dart` |
| DataSource | `*_datasource.dart` | `workout_remote_datasource.dart` |
| Model | `*_model.dart` | `workout_model.dart` |
| Entity | `*.dart` | `workout.dart` |
| UseCase | `*_usecase.dart` | `get_workouts_usecase.dart` |
| Extension | `*_extension.dart` | `string_extension.dart` |

---

## 🗂️ Scaffolding a New Feature

### Quick Start Script

Create a new feature with full scaffolding:

```bash
# From project root
mkdir -p lib/features/workouts/{presentation/{pages,widgets},data/{models,datasources,repositories},domain/{entities,repositories,usecases}}

# Create template files
touch lib/features/workouts/presentation/pages/.gitkeep
touch lib/features/workouts/presentation/widgets/.gitkeep
touch lib/features/workouts/data/models/.gitkeep
touch lib/features/workouts/data/datasources/.gitkeep
touch lib/features/workouts/domain/entities/.gitkeep
```

---

## 🔗 Dependencies Between Layers

```
Presentation Layer
       ↓
       ├─→ Domain Layer (UseCase, Entity)
       └─→ State Management (Riverpod)
              ↓
              └─→ Domain Layer UseCase
                     ↓
                     └─→ Domain Layer Repository (Abstract)
                            ↓
                            └─→ Data Layer (Repository Implementation)
                                   ↓
                                   └─→ Data Sources & Models
```

### Rules

- ✅ Presentation can depend on Domain & State Management
- ✅ Domain is independent (pure Dart)
- ✅ Data implements Domain interfaces
- ❌ Domain cannot depend on Presentation or Data
- ❌ Data cannot depend on Presentation
- ❌ Presentation cannot access Data directly

---

## 🚀 Next Steps & TODOs

### Immediate (Week 1)
- [ ] Add user authentication feature
- [ ] Implement API integration
- [ ] Add local database (Hive/SQLite)
- [ ] Create comprehensive test suite

### Short Term (Month 1)
- [ ] Add workout features
- [ ] Implement progress tracking
- [ ] Add user profile management
- [ ] Integrate analytics

### Medium Term (Month 3)
- [ ] AI recommendations engine
- [ ] Social features
- [ ] Advanced analytics
- [ ] Offline sync capability

---

## 📚 Resources & References

- [Clean Architecture Guide](https://resocoder.com/flutter-clean-architecture)
- [Feature-Based Architecture](https://codewithandrea.com/articles/flutter-project-structure/)
- [SOLID Principles](https://www.toptal.com/flutter/flutter-clean-code)
- [Riverpod Best Practices](https://riverpod.dev/docs/concepts/reading)

---

**Document Version:** 1.0  
**Last Updated:** March 3, 2026  
**Maintainer:** LiftUp Frontend Team
