import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/config/router.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/providers/workout_provider.dart';
import 'package:app/core/services/auth_api_service.dart';

import '../accessibility/a11y_harness.dart';
import 'fake_server.dart';

class _LoginApi extends AuthApiService {
  @override
  Future<LoginResponse> login({required String email, required String password}) async => LoginResponse(
        token: 'secret-token',
        userId: 'u1',
        email: email,
        username: 'testeur',
        onboardingCompleted: true,
      );
}

void main() {
  group('app without network', () {
    testWidgets('works from the device copy and sends the changes once back online', (tester) async {
      final server = FakeServer()..seed('Jambes');
      await pumpRoute(tester, '/training', api: server, size: wholePage);
      expect(find.text('Jambes'), findsWidgets);

      await setOnline(tester, false);
      expect(find.text('Hors ligne · tes séances restent disponibles'), findsOne);

      await appContainer(tester)
          .read(apiWorkoutProvider(testUserId).notifier)
          .createWorkout(name: 'Séance hors ligne', workoutDate: DateTime.now());
      await settle(tester);

      expect(find.text('Séance hors ligne'), findsWidgets);
      expect(find.text('Hors ligne · 1 modification en attente'), findsOne);
      expect(server.workouts.values.map((w) => w.name), isNot(contains('Séance hors ligne')));

      await setOnline(tester, true);

      expect(server.workouts.values.map((w) => w.name), contains('Séance hors ligne'));
      expect(find.textContaining('Hors ligne'), findsNothing);
      expect(find.textContaining('en attente'), findsNothing);
    });

    testWidgets('a first start without network says so instead of showing an empty list', (tester) async {
      await pumpRoute(tester, '/training', api: FakeServer(), online: false);
      expect(find.textContaining('tes séances s\'afficheront à la première connexion'), findsOne);
    });

    testWidgets('the profile shows the sync state and the refused changes', (tester) async {
      final server = FakeServer();
      await pumpRoute(tester, '/profile', api: server, size: wholePage);
      expect(find.textContaining('À jour · synchronisé'), findsOne);

      server.refuseNext = 422;
      await appContainer(tester).read(apiWorkoutProvider(testUserId).notifier).createWorkout(name: 'Refusée');
      await settle(tester);

      expect(find.text('1 modification refusée par le serveur'), findsWidgets);
      expect(find.textContaining('Création de la séance « Refusée » — Error 422'), findsOne);

      await tester.tap(find.text('Réessayer'));
      await settle(tester);
      expect(server.workouts.values.single.name, 'Refusée');
      expect(find.textContaining('refusée'), findsNothing);
    });

    testWidgets('online-only actions explain why they cannot run', (tester) async {
      await pumpRoute(tester, '/training/generate', online: false);
      await tester.tap(find.text('Générer mon programme'));
      await settle(tester);
      expect(find.textContaining('Tu es hors ligne'), findsOne);
    });
  });

  group('session', () {
    test('a login is remembered for the next start, without the token', () async {
      SharedPreferences.setMockInitialValues({});
      final auth = AuthNotifier(_LoginApi());
      await auth.login(email: 'testeur@liftup.test', password: 'x');

      final restored = await AuthNotifier.restoreSession();
      expect(restored?.userId, 'u1');
      expect(restored?.isAuthenticated, isTrue);
      expect(restored?.token, isNull);
      expect(startLocation(restored), '/home');

      auth.logout();
      await Future<void>.delayed(Duration.zero);
      expect(await AuthNotifier.restoreSession(), isNull);
      expect(startLocation(null), '/onboarding');
    });

    test('an unfinished onboarding resumes the questionnaire', () {
      expect(startLocation(AuthState(isAuthenticated: true, userId: 'u1')), '/profile-setup');
    });
  });
}
