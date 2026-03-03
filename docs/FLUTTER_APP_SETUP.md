# LiftUp Flutter Mobile App Documentation

**Document Version:** 1.0  
**Date Created:** March 3, 2026  
**Status:** Active Development  
**Platform:** Flutter (iOS, Android, Linux, macOS, Windows)

---

## Executive Summary

The **LiftUp Flutter Mobile App** is the primary user-facing client application for the LiftUp-EIP fitness coaching platform. Created on March 3, 2026, this Flutter application provides users with access to adaptive workout programs, progress tracking, and personalized fitness coaching on their mobile devices.

---

## Project Overview

### Purpose

The Flutter app serves as the mobile interface for the LiftUp platform, enabling users to:
- Access personalized workout programs
- Track fitness progress and achievements
- View nutritional guidance and meal plans
- Interact with AI-powered coaching recommendations
- Monitor real-time workout metrics

### Project Location

```
client/
└── app/
    ├── lib/
    ├── android/
    ├── ios/
    ├── linux/
    ├── macos/
    ├── windows/
    ├── web/
    ├── test/
    ├── pubspec.yaml
    └── analysis_options.yaml
```

---

## Technical Stack

### Core Framework
- **Framework**: Flutter 3.11.0+
- **Language**: Dart 3.11.0+
- **Type Safety**: Dart with strict type checking

### Dependencies
- **Flutter SDK**: ^3.11.0
- **Cupertino Icons**: ^1.0.8 (iOS-style icons)
- **Flutter Lints**: ^6.0.0 (Code quality and best practices)

### Supported Platforms
- ✅ Android (via android/ directory)
- ✅ iOS (via ios/ directory)
- ✅ Linux (via linux/ directory)
- ✅ macOS (via macos/ directory)
- ✅ Windows (via windows/ directory)
- ✅ Web (via web/ directory)

---

## Project Structure

```
app/
├── lib/
│   └── main.dart                    # Application entry point
├── test/
│   └── widget_test.dart             # Widget tests
├── android/                         # Android platform-specific code
│   └── app/
│       └── src/                     # Android source files
├── ios/                             # iOS platform-specific code
│   └── Runner/                      # iOS runner configuration
├── linux/                           # Linux platform-specific code
├── macos/                           # macOS platform-specific code
├── windows/                         # Windows platform-specific code
├── web/                             # Web platform configuration
│   ├── index.html
│   ├── manifest.json
│   └── icons/
├── pubspec.yaml                     # Project configuration and dependencies
├── analysis_options.yaml            # Lint and analyzer configuration
├── README.md                        # Project README
└── app.iml                          # IDE configuration file
```

---

## Getting Started

### Prerequisites

- Flutter SDK 3.11.0 or higher
- Dart 3.11.0 or higher
- A supported IDE (VS Code, Android Studio, or IntelliJ IDEA)
- Platform-specific development tools:
  - **Android**: Android SDK, Android Studio
  - **iOS**: Xcode, CocoaPods
  - **Linux**: Qt development libraries
  - **macOS**: Xcode command line tools
  - **Windows**: Visual C++ build tools

### Installation

1. **Clone/Navigate to the project:**
   ```bash
   cd client/app
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

4. **Build for production:**
   ```bash
   flutter build apk       # Android
   flutter build ios       # iOS
   flutter build linux     # Linux
   flutter build macos     # macOS
   flutter build windows   # Windows
   flutter build web       # Web
   ```

---

## Development Workflow

### Code Organization

- **Entry Point**: `lib/main.dart` - Application initialization and routing
- **Widgets**: Application UI components (to be developed)
- **Tests**: Unit and widget tests in `test/` directory

### Code Quality

The project uses Flutter Lints (`flutter_lints: ^6.0.0`) for maintaining code quality and best practices. Configuration is defined in `analysis_options.yaml`.

#### Running Analysis

```bash
flutter analyze
```

#### Formatting Code

```bash
dart format lib/
```

### Testing

Run tests with:
```bash
flutter test
```

---

## Build System

### Android Build Configuration
- **Gradle**: Kotlin-based build system
- **Build File**: `android/app/build.gradle.kts`
- **Properties**: `android/gradle.properties`

### iOS Build Configuration
- **Build System**: Xcode project-based
- **Project File**: `ios/Runner.xcodeproj`
- **Workspace**: `ios/Runner.xcworkspace`

### Build Artifacts

Build outputs are generated in the `build/` directory:
```
build/
├── app/                    # Application build artifacts
├── native_assets/          # Platform-specific compiled assets
└── reports/               # Build reports and diagnostics
```

---

## Platform-Specific Considerations

### Android
- **Minimum SDK**: Configured in `android/gradle.properties`
- **App Code**: Located in `android/app/src/`
- **Build Type**: Supports Debug, Release configurations

### iOS
- **Target Device**: iPhone and iPad
- **Development**: Requires Apple Developer account for distribution
- **Framework**: Uses Flutter platform channel for native integration

### Desktop Platforms (Linux, macOS, Windows)
- **CMake**: Build system for desktop platforms
- **Flutter Runtime**: Embedded in native application wrapper

### Web
- **Assets**: Icons and manifest files in `web/`
- **Entry**: `web/index.html`

---

## CI/CD Configuration

### Build Artifacts Location
- Generated build outputs: `build/` directory
- Flutter cache: Auto-managed by Flutter CLI
- Gradle cache: `android/` subdirectories

---

## Future Development

### Planned Enhancements
1. Integration with backend API for workout data
2. Real-time user progress synchronization
3. Push notifications for workout reminders
4. Advanced UI/UX implementation
5. Analytics and crash reporting integration
6. Localization (multi-language support)

### Dependency Management

Monitor and update dependencies regularly:
```bash
flutter pub outdated
flutter pub upgrade
flutter pub upgrade --major-versions
```

---

## Documentation Resources

- [Flutter Official Documentation](https://flutter.dev)
- [Dart Language Documentation](https://dart.dev)
- [LiftUp Architecture Documentation](./ARCHITECTURE_UML_C4_MODEL.md)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | March 3, 2026 | Initial Flutter app creation and setup |

---

## Next Steps

1. Implement core UI screens for workout management
2. Set up state management (Provider, Riverpod, or Bloc pattern)
3. Integrate with backend API endpoints
4. Add user authentication flow
5. Implement local data persistence
6. Create comprehensive test coverage
