import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/program_generation/data/example_program.dart';
import 'package:app/features/program_generation/data/generated_program.dart';
import 'package:app/features/program_generation/data/program_api_service.dart';

import '../../accessibility/a11y_harness.dart';
import '../../sync/fake_server.dart';

class _IncompleteProfileApi implements ProgramApiService {
  @override
  Future<GeneratedProgram> generateProgram(String userId) async =>
      throw const ProgramGenerationException('Ton profil est incomplet.', profileIncomplete: true);
}

void main() {
  test('sessionsPerWeek comes from the API, or from the week of sessions when absent', () {
    final json = exampleProgramJson(now: DateTime(2026, 11, 2), sessionsPerWeek: 3);
    expect(GeneratedProgram.fromJson(json).sessionsPerWeek, 3);
    expect(GeneratedProgram.fromJson({...json, 'sessionsPerWeek': 5}).sessionsPerWeek, 5);
    expect(GeneratedProgram.fromJson({...json}..remove('sessionsPerWeek')).sessionsPerWeek, 3);
  });

  testWidgets('starting a program does not wait for the server', (tester) async {
    final server = FakeServer();
    await pumpRoute(tester, '/training/generate', api: server, size: wholePage);
    await tester.tap(find.text('Générer mon programme'));
    await tester.pump(const Duration(seconds: 4));
    await settle(tester);
    // Moderate activity in the test profile: 4 sessions a week.
    expect(find.text('6 semaines · 4 séances par semaine'), findsOne);

    server.hold = Completer<void>();
    await tester.tap(find.text('Démarrer ce programme'));
    await settle(tester);

    expect(find.text('Programme ajouté à ton planning'), findsOne);
    expect(server.workouts, isEmpty);

    server.release();
    await settle(tester);
    expect(server.workouts, hasLength(4));
  });

  testWidgets('an incomplete profile opens the questionnaire above the page', (tester) async {
    await pumpRoute(
      tester,
      '/training/generate',
      overrides: [programApiServiceProvider.overrideWithValue(_IncompleteProfileApi())],
    );
    await tester.tap(find.text('Générer mon programme'));
    await settle(tester);
    expect(find.text('Parlons de toi'), findsOne);

    await tester.tap(find.byTooltip('Retour'));
    await settle(tester);
    expect(find.text('Récap de ton profil'), findsOne);
  });
}
