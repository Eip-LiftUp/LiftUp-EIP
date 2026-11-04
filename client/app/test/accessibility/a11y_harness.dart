import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/config/providers.dart';
import 'package:app/config/router.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/models/user.dart';
import 'package:app/core/models/workout.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/providers/connectivity_provider.dart';
import 'package:app/core/services/auth_api_service.dart';
import 'package:app/core/services/workout_api_service.dart';

const testUserId = 'user-a11y';

/// Phone portrait viewport, in logical pixels.
const phone = Size(390, 844);

/// WCAG 1.4.10 reflow width.
const narrow = Size(320, 640);

/// Tall enough to lay out every section of a page at once.
const wholePage = Size(390, 3000);

class FakeAuthApiService extends AuthApiService {
  @override
  Future<UserProfileResponse> getUserProfile(String userId) async {
    final now = DateTime.now();
    return UserProfileResponse(
      userId: userId,
      email: 'testeur@liftup.test',
      username: 'testeur',
      displayName: 'Testeur',
      birthDate: DateTime(1998, 4, 12),
      heightCm: 178,
      weightKg: 74,
      fitnessLevel: FitnessLevel.intermediate,
      fitnessGoals: 'Prise de force',
      activityFrequency: ActivityFrequency.moderate,
      hasInjuries: false,
      onboardingCompleted: true,
      createdAt: now.subtract(const Duration(days: 60)),
      updatedAt: now,
    );
  }
}

class FakeWorkoutApiService extends WorkoutApiService {
  final List<WorkoutModel> workouts;

  FakeWorkoutApiService(this.workouts);

  @override
  Future<List<WorkoutModel>> getUserWorkouts({required String userId}) async => workouts;
}

class _SignedInAuthNotifier extends AuthNotifier {
  _SignedInAuthNotifier(super.authService) {
    state = AuthState(
      isAuthenticated: true,
      token: 'token',
      userId: testUserId,
      email: 'testeur@liftup.test',
      username: 'testeur',
      displayName: 'Testeur',
      onboardingCompleted: true,
    );
  }
}

/// A month of training around today: finished sessions with progressing
/// loads, one session planned today and one later this week.
List<WorkoutModel> sampleWorkouts() {
  final today = DateTime.now();
  final day = DateTime(today.year, today.month, today.day, 18);

  ExerciseModel exercise(String workoutId, String name, int order, double weight, {bool done = true}) =>
      ExerciseModel(
        id: '$workoutId-$order',
        workoutId: workoutId,
        exerciseName: name,
        orderIndex: order,
        createdAt: day,
        sets: [
          for (var i = 1; i <= 3; i++) SetModel(setNumber: i, reps: 8, weight: weight, isCompleted: done),
        ],
      );

  WorkoutModel workout(String id, String name, int daysAgo, {required bool done, double load = 60}) {
    final date = day.subtract(Duration(days: daysAgo));
    return WorkoutModel(
      id: id,
      userId: testUserId,
      name: name,
      workoutDate: date,
      durationMinutes: 60,
      isCompleted: done,
      exercises: [
        exercise(id, 'Squat', 0, load + 20, done: done),
        exercise(id, 'Développé couché', 1, load, done: done),
      ],
      createdAt: date,
      updatedAt: date,
    );
  }

  return [
    for (var i = 0; i < 8; i++) workout('past-$i', 'Haut du corps', 3 + i * 3, done: true, load: 50.0 + (8 - i) * 2.5),
    workout('today', 'Jambes', 0, done: false),
    workout('later', 'Full body', -2, done: false),
  ];
}

Map<String, Object> _storedData() {
  String ymd(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
  final now = DateTime.now();
  return {
    'reviews.$testUserId': [
      '${ymd(now.subtract(const Duration(days: 3)))}|squat|86',
      '${ymd(now.subtract(const Duration(days: 6)))}|bench_press|68',
    ],
    'program.$testUserId': 'LiftUp Force & Volume|${ymd(now.subtract(const Duration(days: 10)))}|6|4',
  };
}

/// Same locale as the app (main.dart).
const _locale = Locale('fr', 'FR');

bool _fontsLoaded = false;

/// Real Inter glyphs, so overflow checks measure what users see instead of
/// the much wider test font.
Future<void> _loadFonts() async {
  if (_fontsLoaded) return;
  final inter = FontLoader('Inter');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    inter.addFont(rootBundle.load('lib/assets/fonts/Inter-$weight.ttf'));
  }
  await inter.load();
  await initializeDateFormatting('fr_FR');
  Intl.defaultLocale = 'fr_FR';
  _fontsLoaded = true;
}

void _setViewport(WidgetTester tester, Size size, double textScale) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Network state seen by the app; flip it during a test with [setOnline].
final testOnlineProvider = StateProvider<bool>((ref) => true);

List<Override> _overrides({required bool signedIn, required bool online, WorkoutApiService? api}) => [
      authApiServiceProvider.overrideWithValue(FakeAuthApiService()),
      workoutApiServiceProvider.overrideWithValue(api ?? FakeWorkoutApiService(sampleWorkouts())),
      testOnlineProvider.overrideWith((ref) => online),
      isOnlineProvider.overrideWith((ref) => ref.watch(testOnlineProvider)),
      if (signedIn) authProvider.overrideWith((ref) => _SignedInAuthNotifier(ref.watch(authApiServiceProvider))),
    ];

ProviderContainer appContainer(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Navigator).first));

Future<void> setOnline(WidgetTester tester, bool online) async {
  appContainer(tester).read(testOnlineProvider.notifier).state = online;
  await settle(tester);
}

/// Starts the whole app at [location] with fake APIs and a signed-in user.
Future<void> pumpRoute(
  WidgetTester tester,
  String location, {
  Size size = phone,
  double textScale = 1,
  bool signedIn = true,
  bool online = true,
  WorkoutApiService? api,
  List<Override> overrides = const [],
}) async {
  await _loadFonts();
  SharedPreferences.setMockInitialValues(_storedData());
  _setViewport(tester, size, textScale);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [..._overrides(signedIn: signedIn, online: online, api: api), ...overrides],
      child: MaterialApp.router(
        theme: AppTheme.dark,
        locale: _locale,
        supportedLocales: const [_locale],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: buildAppRouter(initialLocation: location),
      ),
    ),
  );
  await settle(tester);
}

/// Pumps a page that is pushed with Navigator rather than a route path.
Future<void> pumpPage(
  WidgetTester tester,
  Widget page, {
  Size size = phone,
  double textScale = 1,
}) async {
  await _loadFonts();
  SharedPreferences.setMockInitialValues(_storedData());
  _setViewport(tester, size, textScale);
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(signedIn: true, online: true),
      child: MaterialApp(
        theme: AppTheme.dark,
        locale: _locale,
        supportedLocales: const [_locale],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: page,
      ),
    ),
  );
  await settle(tester);
}

/// Lets futures, route transitions and loaders finish without waiting on
/// endless animations (skeletons, spinners).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// ACCESSIBILITY_STRATEGY.md: 44×44 pt touch targets, labelled controls,
/// 4.5:1 text contrast. Reports every failing guideline at once.
Future<void> expectAccessible(WidgetTester tester) async {
  final failures = <String>[];
  for (final guideline in [iOSTapTargetGuideline, labeledTapTargetGuideline, textContrastGuideline]) {
    final result = await guideline.evaluate(tester);
    if (!result.passed) failures.add('${guideline.description}\n${result.reason}');
  }
  expect(failures, isEmpty, reason: failures.join('\n\n'));
}

/// WCAG 1.4.4 / 1.4.10: text at 200% on a 320px wide screen loses nothing.
/// [pump] builds the screen at the given size and 200% text.
Future<void> expectNoOverflowAtLargeText(WidgetTester tester, Future<void> Function(Size size) pump) async {
  final failures = <String>[];
  for (final size in const [narrow, Size(320, 2400)]) {
    // Collected here rather than by the test binding, to report where each
    // overflow comes from.
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      final where = RegExp(r'lib/[^\s]+\.dart:\d+').firstMatch(details.toString())?.group(0);
      failures.add(
        '${size.width.toInt()}×${size.height.toInt()}: '
        '${details.exceptionAsString().split('\n').first}${where == null ? '' : ' ($where)'}',
      );
    };
    try {
      await pump(size);
    } finally {
      FlutterError.onError = original;
    }
  }
  expect(failures, isEmpty, reason: failures.join('\n'));
}
