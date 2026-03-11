# Testing Guide

## Overview

This guide covers how to write, run, and maintain tests for the LiftUp Flutter application. The project uses Flutter's built-in testing framework with comprehensive unit and widget tests.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Test Structure](#test-structure)
3. [Running Tests](#running-tests)
4. [Writing Tests](#writing-tests)
5. [Test Coverage](#test-coverage)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

## Quick Start

### Running All Tests

```bash
# Navigate to the app directory
cd client/app

# Run all tests
flutter test

# Run tests with verbose output
flutter test --reporter expanded
```

### Running Specific Tests

```bash
# Run a specific test file
flutter test test/features/camera/presentation/pages/camera_page_test.dart

# Run tests matching a name pattern
flutter test --name "CameraPage"

# Run tests in a specific directory
flutter test test/features/camera/
```

### Running Tests with Coverage

```bash
# Generate coverage report
flutter test --coverage

# View coverage in terminal (requires lcov)
lcov --list coverage/lcov.info

# Generate HTML coverage report (requires genhtml)
genhtml coverage/lcov.info -o coverage/html
# Then open coverage/html/index.html in a browser
```

## Test Structure

The test directory mirrors the lib directory structure:

```
test/
├── features/
│   ├── camera/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── camera_page_test.dart
│   │       └── widgets/
│   │           ├── camera_preview_widget_test.dart
│   │           └── lm_comments_section_test.dart
│   └── home/
│       └── presentation/
│           └── pages/
│               └── home_page_test.dart
└── widget_test.dart
```

## Running Tests

### Command Line Options

#### Basic Commands

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific file
flutter test test/features/camera/presentation/pages/camera_page_test.dart

# Run tests matching a pattern
flutter test --plain-name "should display"
```

#### Output Formats

```bash
# Compact output (default)
flutter test

# Expanded output (shows each test)
flutter test --reporter expanded

# JSON output (for CI/CD)
flutter test --reporter json
```

#### Performance Options

```bash
# Run tests in parallel (faster)
flutter test --concurrency=6

# Run specific number of tests
flutter test --total-shards=2 --shard-index=0
```

### IDE Integration

#### VS Code

1. Install "Flutter" extension
2. Click the green play button next to test groups
3. Or use Command Palette: "Flutter: Run Tests"

#### Android Studio / IntelliJ

1. Right-click on test file
2. Select "Run tests in 'filename'"
3. Or click the green arrow in the gutter next to test groups

### Continuous Integration

Example GitHub Actions workflow:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: cd client/app && flutter pub get
      - run: cd client/app && flutter test --coverage
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: client/app/coverage/lcov.info
```

## Writing Tests

### Test Types

#### 1. Unit Tests

Test individual functions and methods:

```dart
test('should create LMComment with all required fields', () {
  // Arrange
  final timestamp = DateTime.now();
  
  // Act
  final comment = LMComment(
    id: '1',
    text: 'Test comment',
    timestamp: timestamp,
    type: CommentType.positive,
  );

  // Assert
  expect(comment.id, '1');
  expect(comment.text, 'Test comment');
  expect(comment.type, CommentType.positive);
});
```

#### 2. Widget Tests

Test UI components:

```dart
testWidgets('should display loading indicator initially', (WidgetTester tester) async {
  // Arrange & Act
  await tester.pumpWidget(
    const MaterialApp(
      home: CameraPage(),
    ),
  );

  // Assert
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

#### 3. Integration Tests (Future)

For end-to-end testing (in `integration_test/` directory):

```dart
testWidgets('complete camera flow', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  
  // Navigate to camera
  await tester.tap(find.text('Camera'));
  await tester.pumpAndSettle();
  
  // Interact with camera
  await tester.tap(find.byIcon(Icons.comment));
  await tester.pumpAndSettle();
  
  // Verify comments displayed
  expect(find.text('LM Coach Comments'), findsOneWidget);
});
```

### Test Structure Best Practices

Use the **Arrange-Act-Assert** pattern:

```dart
testWidgets('should call callback when button pressed', (WidgetTester tester) async {
  // Arrange
  bool wasCalled = false;
  await tester.pumpWidget(
    MaterialApp(
      home: MyWidget(onPressed: () => wasCalled = true),
    ),
  );

  // Act
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();

  // Assert
  expect(wasCalled, isTrue);
});
```

### Common Test Patterns

#### Testing User Interactions

```dart
// Tap a button
await tester.tap(find.text('Button Text'));
await tester.pump(); // Rebuild widget

// Enter text
await tester.enterText(find.byType(TextField), 'Hello');
await tester.pump();

// Scroll
await tester.drag(find.byType(ListView), const Offset(0, -300));
await tester.pump();
```

#### Finding Widgets

```dart
// By type
find.byType(ElevatedButton)

// By text
find.text('Submit')

// By icon
find.byIcon(Icons.camera)

// By key
find.byKey(const Key('submit_button'))

// Partial text match
find.textContaining('Error')

// Widget with icon
find.widgetWithIcon(IconButton, Icons.menu)
```

#### Assertions

```dart
// Widget count
expect(find.byType(Card), findsOneWidget);
expect(find.byType(ListTile), findsNWidgets(3));
expect(find.text('Deleted'), findsNothing);
expect(find.byType(ErrorWidget), findsWidgets); // At least one

// Values
expect(comment.type, CommentType.positive);
expect(isLoading, isFalse);
expect(items, isEmpty);
expect(errorMessage, isNull);

// Async
expect(future, completion(equals(42)));
expect(stream, emits(someValue));
```

## Test Coverage

### Viewing Coverage

After running tests with coverage:

```bash
# Generate coverage
flutter test --coverage

# View summary
lcov --summary coverage/lcov.info

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
```

### Coverage Goals

- **Target**: 80%+ overall coverage
- **Critical paths**: 100% coverage (authentication, payments, etc.)
- **UI widgets**: 70%+ coverage
- **Utilities**: 90%+ coverage

### Excluding Files from Coverage

Add to file to exclude:

```dart
// coverage:ignore-file
```

Exclude specific lines:

```dart
// coverage:ignore-start
void debugFunction() {
  print('Debug info');
}
// coverage:ignore-end
```

## Best Practices

### 1. Test Naming

Use descriptive names that explain what is being tested:

```dart
✅ Good:
testWidgets('should display error message when camera initialization fails', ...)
test('should create LMComment with all required fields', ...)

❌ Bad:
testWidgets('test1', ...)
test('comment test', ...)
```

### 2. Test Organization

Group related tests:

```dart
group('CameraPage', () {
  group('Widget Tests', () {
    testWidgets('should display loading indicator', ...);
    testWidgets('should show error message', ...);
  });
  
  group('State Management', () {
    testWidgets('should update state on toggle', ...);
  });
});
```

### 3. Setup and Teardown

Use setUp and tearDown for common initialization:

```dart
group('MyWidget', () {
  late MyController controller;
  
  setUp(() {
    controller = MyController();
  });
  
  tearDown(() {
    controller.dispose();
  });
  
  testWidgets('test 1', ...);
  testWidgets('test 2', ...);
});
```

### 4. Mock Dependencies

Use mockito for mocking (add to dev_dependencies if needed):

```dart
class MockCameraController extends Mock implements CameraController {}

testWidgets('should handle camera errors', (tester) async {
  final mockCamera = MockCameraController();
  when(mockCamera.initialize()).thenThrow(CameraException('error', 'desc'));
  
  // Test with mocked camera
});
```

### 5. Test Data Builders

Create helper functions for test data:

```dart
LMComment createTestComment({
  String id = '1',
  String text = 'Test comment',
  CommentType type = CommentType.positive,
}) {
  return LMComment(
    id: id,
    text: text,
    timestamp: DateTime.now(),
    type: type,
  );
}
```

### 6. Async Testing

Always await async operations:

```dart
testWidgets('should load data', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Wait for animations
  await tester.pumpAndSettle();
  
  // Wait for specific duration
  await tester.pump(const Duration(seconds: 2));
});
```

## Camera Feature Tests

### Current Test Coverage

#### CameraPage Tests (`camera_page_test.dart`)
- ✅ Loading state display
- ✅ App bar rendering
- ✅ Toggle button functionality
- ✅ View switching (camera ↔ comments)
- ✅ State management
- ✅ Widget disposal
- ✅ Accessibility features

#### LMCommentsSection Tests (`lm_comments_section_test.dart`)
- ✅ Header display
- ✅ Comment rendering
- ✅ Comment type indicators
- ✅ Timestamp formatting
- ✅ Back button callback
- ✅ Data model creation
- ✅ All comment types
- ✅ UI accessibility

### Running Camera Tests

```bash
# All camera tests
flutter test test/features/camera/

# Specific test file
flutter test test/features/camera/presentation/pages/camera_page_test.dart

# Specific test by name
flutter test --name "should display loading indicator"

# With coverage
flutter test test/features/camera/ --coverage
```

## Troubleshooting

### Common Issues

#### Issue: "Bad state: No element"

**Cause**: Widget not found
**Solution**: Verify widget exists, use pump() to rebuild

```dart
await tester.pumpWidget(MyWidget());
await tester.pump(); // Rebuild
expect(find.text('Hello'), findsOneWidget);
```

#### Issue: Tests timing out

**Cause**: Async operations not completing
**Solution**: Use pumpAndSettle() or increase timeout

```dart
await tester.pumpAndSettle(const Duration(seconds: 10));
```

#### Issue: "A Timer is still pending"

**Cause**: Unfinished async operations
**Solution**: Properly dispose controllers

```dart
tearDown(() {
  controller.dispose();
});
```

#### Issue: Camera tests failing in CI

**Cause**: No camera available in CI environment
**Solution**: Mock camera or skip platform-specific tests

```dart
testWidgets('camera test', (tester) async {
  // Skip on CI
  if (Platform.environment.containsKey('CI')) {
    return;
  }
  // Test code
});
```

### Debug Mode

Run tests with verbose output:

```bash
# Verbose output
flutter test --reporter expanded

# Print debugging info
flutter test --verbose

# Show platform messages
flutter test --show-test-device
```

### Performance

Speed up tests:

```bash
# Run in parallel
flutter test --concurrency=6

# Update golden files without running tests
flutter test --update-goldens

# Skip slow tests
flutter test --exclude-tags=slow
```

## Additional Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Widget Testing Guide](https://docs.flutter.dev/cookbook/testing/widget)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Mockito Package](https://pub.dev/packages/mockito)
- [Test Coverage](https://docs.flutter.dev/testing/code-coverage)

## Summary of Commands

```bash
# Essential commands
flutter test                              # Run all tests
flutter test --coverage                   # Run with coverage
flutter test test/path/to/file_test.dart # Run specific file
flutter test --name "test name"          # Run specific test
flutter test --reporter expanded         # Verbose output

# Coverage
lcov --list coverage/lcov.info           # View coverage
genhtml coverage/lcov.info -o coverage/html # HTML report

# Development
flutter test --watch                     # Watch mode (requires package)
flutter test --update-goldens           # Update golden files
```

---

**Next Steps:**
1. Run `flutter test` to verify all tests pass
2. Check coverage with `flutter test --coverage`
3. Review test output for any failures
4. Add tests for new features as you build them
