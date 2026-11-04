import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/models/workout.dart';
import 'package:app/core/providers/workout_provider.dart';
import 'package:app/core/sync/pending_operation.dart';
import 'package:app/core/sync/workout_repository.dart';
import 'package:app/core/sync/workout_store.dart';

import 'fake_server.dart';

void main() {
  late FakeServer server;
  late WorkoutRepository repo;

  WorkoutRepository newRepository() =>
      WorkoutRepository(userId: 'u1', api: server, clock: () => server.now);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    server = FakeServer();
    repo = newRepository();
    await repo.restore();
  });

  // Same requests as ApiWorkoutNotifier builds.
  Future<String> createWorkout(String name, {DateTime? date}) async {
    final id = repo.newLocalId();
    await repo.record(PendingOperation(
      id: repo.newLocalId(),
      type: OperationType.createWorkout,
      workoutId: id,
      fields: CreateWorkoutRequest(name: name, workoutDate: date ?? DateTime(2026, 11, 3)).toJson(),
      createdAt: server.now,
    ));
    return id;
  }

  Future<String> addExercise(String workoutId, String name) async {
    final id = repo.newLocalId();
    await repo.record(PendingOperation(
      id: repo.newLocalId(),
      type: OperationType.createExercise,
      workoutId: workoutId,
      exerciseId: id,
      fields: CreateExerciseRequest(exerciseName: name, sets: 3, reps: 8, weight: 60).toJson(),
      createdAt: server.now,
    ));
    return id;
  }

  Future<void> updateWorkout(String workoutId, UpdateWorkoutRequest request) => repo.record(PendingOperation(
        id: repo.newLocalId(),
        type: OperationType.updateWorkout,
        workoutId: workoutId,
        fields: request.toJson(),
        createdAt: server.now,
        baseUpdatedAt: repo.serverVersion(workoutId)?.updatedAt,
      ));

  Future<void> updateExercise(String workoutId, String exerciseId, List<SetModel> sets) =>
      repo.record(PendingOperation(
        id: repo.newLocalId(),
        type: OperationType.updateExercise,
        workoutId: workoutId,
        exerciseId: exerciseId,
        fields: UpdateExerciseRequest(setsData: sets).toJson(),
        createdAt: server.now,
      ));

  Future<void> deleteWorkout(String workoutId) => repo.record(PendingOperation(
        id: repo.newLocalId(),
        type: OperationType.deleteWorkout,
        workoutId: workoutId,
        createdAt: server.now,
      ));

  WorkoutModel visible(String name) => repo.workouts.singleWhere((w) => w.name == name);

  group('offline use', () {
    test('changes made offline show at once and reach the server once back online', () async {
      server.offline = true;
      final workoutId = await createWorkout('Jambes');
      final exerciseId = await addExercise(workoutId, 'Squat');
      await updateExercise(workoutId, exerciseId, [SetModel(setNumber: 1, reps: 5, weight: 100, isCompleted: true)]);

      expect(visible('Jambes').exercises.single.sets.single.weight, 100);
      expect(repo.pendingCount, 3);

      final offlineRun = await repo.sync();
      expect(offlineRun.interrupted, isTrue);
      expect(server.workouts, isEmpty);

      server.offline = false;
      final report = await repo.sync();

      expect(report.completed, isTrue);
      expect(repo.pendingCount, 0);
      final saved = server.workouts.values.single;
      expect(saved.name, 'Jambes');
      expect(saved.exercises.single.sets.single.weight, 100);
      // The device copy now uses the server ids.
      expect(visible('Jambes').id, saved.id);
      expect(repo.resolve(workoutId), saved.id);
    });

    test('pending changes survive an app restart', () async {
      server.offline = true;
      await createWorkout('Haut du corps');
      await repo.sync();

      final restarted = newRepository();
      await restarted.restore();

      expect(restarted.pendingCount, 1);
      expect(restarted.workouts.single.name, 'Haut du corps');

      server.offline = false;
      await restarted.sync();
      expect(server.workouts.values.single.name, 'Haut du corps');
    });

    test('the last server copy is kept on the device', () async {
      server.seed('Full body');
      await repo.sync();
      server.offline = true;

      final restarted = newRepository();
      await restarted.restore();

      expect(restarted.hasData, isTrue);
      expect(restarted.workouts.single.name, 'Full body');
    });
  });

  group('fewer requests', () {
    test('a workout created then deleted offline never reaches the server', () async {
      server.offline = true;
      final id = await createWorkout('Brouillon');
      await addExercise(id, 'Squat');
      await deleteWorkout(id);
      expect(repo.pendingCount, 0);

      server.offline = false;
      await repo.sync();
      expect(server.calls.where((c) => c.startsWith('POST')), isEmpty);
    });

    test('several edits of a workout are sent as one request', () async {
      final seeded = server.seed('Jambes');
      await repo.sync();
      server.offline = true;
      await updateWorkout(seeded.id, UpdateWorkoutRequest(name: 'Jambes lourdes'));
      await updateWorkout(seeded.id, UpdateWorkoutRequest(notes: 'Genou ok'));
      await updateWorkout(seeded.id, UpdateWorkoutRequest(isCompleted: true));
      expect(repo.pendingCount, 1);

      server.offline = false;
      server.calls.clear();
      await repo.sync();

      expect(server.calls.where((c) => c.startsWith('PATCH')), hasLength(1));
      final saved = server.workouts[seeded.id]!;
      expect((saved.name, saved.notes, saved.isCompleted), ('Jambes lourdes', 'Genou ok', true));
    });
  });

  group('conflicts', () {
    test('the device version wins, field by field, and the conflict is reported', () async {
      final seeded = server.seed('Jambes');
      await repo.sync();
      server.offline = true;
      await updateWorkout(seeded.id, UpdateWorkoutRequest(isCompleted: true, notes: 'Fait'));
      server.editElsewhere(seeded.id, name: 'Jambes (autre appareil)');
      // Offline for a while before the network comes back.
      server.now = server.now.add(const Duration(minutes: 10));

      server.offline = false;
      final report = await repo.sync();

      final saved = server.workouts[seeded.id]!;
      expect(saved.isCompleted, isTrue);
      expect(saved.notes, 'Fait');
      // Not edited on the device: the other device's change stays.
      expect(saved.name, 'Jambes (autre appareil)');
      expect(report.conflicts, 1);
      expect(report.notices.single, contains('ta version a été gardée'));
    });

    test('a change sent right away is not checked for conflicts nor followed by a full reload', () async {
      final seeded = server.seed('Jambes');
      await repo.sync();
      server.calls.clear();

      await updateWorkout(seeded.id, UpdateWorkoutRequest(isCompleted: true));
      await repo.sync(refresh: false);

      expect(server.calls, ['PATCH /workouts/${seeded.id}']);
    });

    test('an edit recorded while the previous one is being sent is not a conflict', () async {
      final seeded = server.seed('Jambes');
      await repo.sync();
      await updateWorkout(seeded.id, UpdateWorkoutRequest(notes: 'Genou ok'));

      server.hold = Completer<void>();
      final run = repo.sync(refresh: false);
      await pumpEventQueue();
      // The first PATCH is on its way: this one cannot be merged into it.
      await updateWorkout(seeded.id, UpdateWorkoutRequest(isCompleted: true));
      server.now = server.now.add(const Duration(minutes: 5));
      server.release();
      final report = await run;

      expect(report.conflicts, 0);
      expect(server.workouts[seeded.id]!.isCompleted, isTrue);
    });

    test('a deletion on another device wins over an offline edit', () async {
      final seeded = server.seed('Jambes');
      await repo.sync();
      server.offline = true;
      await updateWorkout(seeded.id, UpdateWorkoutRequest(isCompleted: true));
      server.workouts.remove(seeded.id);

      server.offline = false;
      final report = await repo.sync();

      expect(repo.workouts, isEmpty);
      expect(repo.pendingCount, 0);
      expect(report.notices.single, contains('supprimée sur un autre appareil'));
    });

    test('a deletion on the device wins over an edit made elsewhere', () async {
      final seeded = server.seed('Jambes');
      await repo.sync();
      server.offline = true;
      await deleteWorkout(seeded.id);
      server.editElsewhere(seeded.id, name: 'Jambes v2');

      server.offline = false;
      await repo.sync();
      expect(server.workouts, isEmpty);
    });

    test('an exercise deleted elsewhere drops the offline edit on it', () async {
      final seeded = server.seed('Jambes', exercises: ['Squat']);
      await repo.sync();
      final exerciseId = seeded.exercises.single.id;
      server.offline = true;
      await updateExercise(seeded.id, exerciseId, [SetModel(setNumber: 1, reps: 3, weight: 120)]);
      server.workouts[seeded.id] = server.workouts[seeded.id]!.copyWith(exercises: []);

      server.offline = false;
      final report = await repo.sync();

      expect(visible('Jambes').exercises, isEmpty);
      expect(report.notices.single, contains('Un exercice'));
    });
  });

  group('failures', () {
    test('a refused change is set aside and the others still go through', () async {
      server.offline = true;
      await createWorkout('Refusée');
      await createWorkout('Acceptée');

      server.offline = false;
      server.refuseNext = 422;
      final report = await repo.sync();

      expect(report.completed, isTrue);
      expect(server.workouts.values.single.name, 'Acceptée');
      expect(repo.rejected.single.rejection, 'Error 422');
      // Still visible on the device until the user decides.
      expect(repo.workouts.map((w) => w.name), containsAll(['Refusée', 'Acceptée']));

      await repo.retryRejected();
      await repo.sync();
      expect(server.workouts.values.map((w) => w.name), containsAll(['Refusée', 'Acceptée']));
      expect(repo.rejected, isEmpty);
    });

    test('changes on a refused workout are refused too', () async {
      server.offline = true;
      final id = await createWorkout('Refusée');
      await addExercise(id, 'Squat');

      server.offline = false;
      server.refuseNext = 422;
      await repo.sync();

      expect(repo.rejected, hasLength(2));
      expect(repo.rejected.last.rejection, contains('Dépend'));

      await repo.discardRejected();
      expect(repo.workouts, isEmpty);
    });

    test('a lost answer does not create the workout twice', () async {
      await createWorkout('Jambes');
      server.loseNextAnswer = true;

      final first = await repo.sync();
      expect(first.interrupted, isTrue);
      expect(server.workouts, hasLength(1));

      await repo.sync();
      expect(server.workouts, hasLength(1));
      expect(server.calls.where((c) => c == 'POST /workouts'), hasLength(1));
      expect(visible('Jambes').id, server.workouts.keys.single);
    });

    test('a server error keeps the change for a later retry', () async {
      await createWorkout('Jambes');
      server.refuseNext = 503;

      final report = await repo.sync();
      expect(report.interrupted, isTrue);
      expect(repo.pendingCount, 1);
      expect(repo.rejected, isEmpty);

      await repo.sync();
      expect(server.workouts.values.single.name, 'Jambes');
    });

    test('retries wait longer after each failure, up to 5 minutes', () {
      expect(
        [for (final n in [1, 2, 3, 4, 8, 20, 64, 100000]) ApiWorkoutNotifier.retryDelay(n).inSeconds],
        [2, 4, 8, 16, 256, 300, 300, 300],
      );
    });

    test('an unreadable answer interrupts the sync without breaking it', () async {
      server.seed('Jambes');
      server.garbleNext = true;

      final report = await repo.sync();
      expect(report.interrupted, isTrue);

      final next = await repo.sync();
      expect(next.completed, isTrue);
      expect(repo.workouts.single.name, 'Jambes');
    });

    test('a corrupted device copy is ignored instead of blocking the app', () async {
      SharedPreferences.setMockInitialValues({'workouts.u1': '{not json', 'sync.u1': '[{"id": 1}]'});
      final stored = await const WorkoutStore('u1').load();
      expect(stored.workouts, isNull);
      expect(stored.operations, isEmpty);
    });
  });
}
