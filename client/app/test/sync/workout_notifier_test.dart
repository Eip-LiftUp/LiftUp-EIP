import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/providers/workout_provider.dart';
import 'package:app/core/sync/workout_repository.dart';

import '../accessibility/a11y_harness.dart';
import 'fake_server.dart';

ApiWorkoutNotifier _notifier(FakeServer server) =>
    ApiWorkoutNotifier(WorkoutRepository(userId: 'u1', api: server, clock: () => server.now), 'u1');

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a change is kept on the device without waiting for the server', (tester) async {
    // The first sync never answers, as on Wi-Fi without internet.
    final server = FakeServer()..hold = Completer<void>();
    final notifier = _notifier(server);

    final created = await notifier.createWorkout(name: 'Jambes');

    expect(created?.name, 'Jambes');
    expect(notifier.state.workouts.single.name, 'Jambes');
    expect(server.workouts, isEmpty);

    server.release();
    await _flush(tester);
    expect(server.workouts.values.single.name, 'Jambes');
    notifier.dispose();
  });

  testWidgets('changes made during a failing sync count as one failure', (tester) async {
    final server = FakeServer()..hold = Completer<void>();
    final notifier = _notifier(server);
    for (var i = 0; i < 10; i++) {
      await notifier.createWorkout(name: 'Séance $i');
    }

    server.offline = true;
    server.release();
    await _flush(tester);

    expect(notifier.consecutiveFailures, 1);
    expect(notifier.state.pendingCount, 10);
    notifier.dispose();
  });

  testWidgets('signing out stops the background sync of that account', (tester) async {
    final server = FakeServer();
    await pumpRoute(tester, '/home', api: server);
    final container = appContainer(tester);

    Future<void> backToForeground() async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
    }

    server.calls.clear();
    await backToForeground();
    expect(server.calls, contains('GET /workouts'));

    container.read(authProvider.notifier).logout();
    await settle(tester);
    server.calls.clear();
    await backToForeground();
    await container.read(apiWorkoutProvider(testUserId).notifier).sync();
    await settle(tester);

    expect(server.calls, isEmpty);
  });
}
