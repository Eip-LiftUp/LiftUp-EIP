import 'dart:async';
import 'dart:math';

import 'package:app/core/models/workout.dart';
import 'package:app/core/services/workout_api_service.dart';
import 'package:app/core/sync/local_workouts.dart';
import 'package:app/core/sync/pending_operation.dart';
import 'package:app/core/sync/workout_store.dart';

/// Outcome of one sync run.
class SyncReport {
  /// Operations the server accepted.
  int sent = 0;

  /// Workouts also changed on another device; the device's version was kept.
  int conflicts = 0;

  /// The queue was emptied (except refused operations) and the workouts
  /// were reloaded from the server.
  bool completed = false;

  /// The server could not be reached, or answered with an error worth
  /// retrying later.
  bool interrupted = false;

  /// Messages for the user, e.g. a workout deleted on another device.
  final List<String> notices = [];
}

/// A user's workouts, usable without network: changes apply on the device
/// at once and queue up until the server acknowledges them.
///
/// Conflicts: the device's changes win over the server's, field by field
/// (only edited fields are sent); a deletion wins over an edit, on either side.
class WorkoutRepository {
  final String userId;
  final WorkoutApiService api;
  final WorkoutStore store;
  final DateTime Function() clock;

  /// Called when a workout or exercise created on the device gets its
  /// server id.
  void Function(String localId, String serverId)? onIdChanged;

  WorkoutRepository({
    required this.userId,
    required this.api,
    WorkoutStore? store,
    DateTime Function()? clock,
  })  : store = store ?? WorkoutStore(userId),
        clock = clock ?? DateTime.now;

  List<WorkoutModel> _server = const [];
  List<PendingOperation> _operations = [];
  bool _hasData = false;
  DateTime? _syncedAt;
  final Map<String, String> _aliases = {};
  String? _inFlight;
  Future<SyncReport>? _running;
  bool _runAgain = false;
  bool _refreshAgain = false;
  final _random = Random();

  /// The workouts as the user sees them, pending changes included.
  List<WorkoutModel> get workouts => applyOperations(_server, _operations, userId: userId);

  /// Whether workouts were ever received from the server.
  bool get hasData => _hasData;

  DateTime? get syncedAt => _syncedAt;

  bool get isSyncing => _running != null;

  int get pendingCount => _operations.where((o) => !o.isRejected).length;

  List<PendingOperation> get rejected => [for (final o in _operations) if (o.isRejected) o];

  /// Server id of a workout or exercise created on the device, once known.
  String resolve(String id) => _aliases[id] ?? id;

  Map<String, String> get aliases => Map.unmodifiable(_aliases);

  WorkoutModel? serverVersion(String workoutId) {
    final id = resolve(workoutId);
    for (final w in _server) {
      if (w.id == id) return w;
    }
    return null;
  }

  Future<void> restore() async {
    final stored = await store.load();
    _server = stored.workouts ?? const [];
    _hasData = stored.workouts != null;
    _operations = [...stored.operations];
    _syncedAt = stored.syncedAt;
  }

  String newLocalId() =>
      '$localIdPrefix${clock().microsecondsSinceEpoch}-${_random.nextInt(0x7fffffff).toRadixString(36)}';

  // ==================== Recording changes ====================

  /// Queues a change made on the device, merged with the pending ones when
  /// possible so the server receives as few requests as needed.
  Future<void> record(PendingOperation operation) async {
    final op = operation.copyWith(
      workoutId: resolve(operation.workoutId),
      exerciseId: operation.exerciseId == null ? null : resolve(operation.exerciseId!),
    );
    // The operation being sent and refused ones are left as they are.
    bool editable(PendingOperation o) => o.id != _inFlight && !o.isRejected;
    bool sameTarget(PendingOperation o) => o.type.onExercise == op.type.onExercise && o.targetId == op.targetId;

    switch (op.type) {
      case OperationType.updateWorkout || OperationType.updateExercise:
        final index = _operations.lastIndexWhere((o) => editable(o) && o.type == op.type && sameTarget(o));
        if (index >= 0) {
          final previous = _operations[index];
          _operations[index] = previous.copyWith(fields: {...previous.fields, ...op.fields});
        } else {
          _operations.add(op);
        }
      case OperationType.deleteWorkout || OperationType.deleteExercise:
        // Pending changes on the deleted item (and on the exercises of a
        // deleted workout) no longer matter, refused ones included.
        bool related(PendingOperation o) =>
            sameTarget(o) || (op.type == OperationType.deleteWorkout && o.type.onExercise && o.workoutId == op.workoutId);
        final beingSent = _operations.any((o) => o.id == _inFlight && related(o));
        _operations.removeWhere((o) => o.id != _inFlight && related(o));
        // Created on the device and never sent: nothing to delete on the server.
        if (!isLocalId(op.targetId) || beingSent) _operations.add(op);
      case OperationType.createWorkout || OperationType.createExercise:
        _operations.add(op);
    }
    await store.saveOperations(_operations);
  }

  // ==================== Syncing ====================

  /// Sends the pending changes in order; with [refresh], then reloads the
  /// workouts from the server. A change only needs the push: the server's
  /// answers already update the device copy.
  ///
  /// Concurrent calls share the run in progress, which runs once more if
  /// they recorded changes or asked for a refresh meanwhile.
  Future<SyncReport> sync({bool refresh = true}) {
    final running = _running;
    if (running != null) {
      _runAgain = true;
      _refreshAgain |= refresh;
      return running;
    }
    final run = _run(refresh);
    _running = run;
    return run;
  }

  Future<SyncReport> _run(bool refresh) async {
    final report = SyncReport();
    var pull = refresh;
    try {
      do {
        _runAgain = false;
        if (!await _pushAll(report) || pull && !await _pull()) {
          report.interrupted = true;
          break;
        }
        report.completed = true;
        pull = _refreshAgain;
        _refreshAgain = false;
      } while (_runAgain);
      return report;
    } finally {
      _running = null;
    }
  }

  /// Returns false when sending had to stop (network or server trouble).
  ///
  /// The queue and the device copy are saved once at the end: after a crash
  /// mid-run, the operations already sent are simply sent again (updates and
  /// deletions are idempotent, creations are found back, see
  /// [_findCreatedWorkout]).
  Future<bool> _pushAll(SyncReport report) async {
    final sentBefore = report.sent;
    try {
      return await _pushEach(report);
    } finally {
      if (report.sent > sentBefore) {
        await store.saveOperations(_operations);
        // Everything acknowledged: the device copy matches the server.
        if (pendingCount == 0) _syncedAt = clock();
        await store.saveWorkouts(_server, syncedAt: pendingCount == 0 ? _syncedAt : null);
      }
    }
  }

  Future<bool> _pushEach(SyncReport report) async {
    while (true) {
      final next = _operations.where((o) => !o.isRejected).firstOrNull;
      if (next == null) return true;

      var op = next.copyWith(
        workoutId: resolve(next.workoutId),
        exerciseId: next.exerciseId == null ? null : resolve(next.exerciseId!),
      );
      // Still a device id after its create was processed: that create was
      // refused, so this change cannot be applied either.
      final needsServerWorkout = op.type != OperationType.createWorkout && isLocalId(op.workoutId);
      final needsServerExercise = op.type.onExercise && !op.type.isCreate && isLocalId(op.exerciseId!);
      if (needsServerWorkout || needsServerExercise) {
        await _reject(next, 'Dépend d\'un élément refusé par le serveur.');
        continue;
      }

      if (op.type.isCreate) {
        // Counted before sending: if the answer is lost, the next attempt
        // first checks whether the server created it anyway.
        op = op.copyWith(attempts: op.attempts + 1);
        _replace(next.id, op);
        await store.saveOperations(_operations);
      }

      _inFlight = op.id;
      try {
        await _send(op, report);
        _operations.removeWhere((o) => o.id == op.id);
        report.sent++;
      } on ApiRequestException catch (e) {
        if (!e.isRejected) {
          if (!op.type.isCreate) _replace(op.id, op.copyWith(attempts: op.attempts + 1));
          return false;
        }
        await _reject(op, e.message);
      } catch (e) {
        // The API turns every server or network trouble into an
        // ApiRequestException: anything else comes from the operation itself
        // and would fail again, so it is set aside instead of blocking the queue.
        await _reject(op, 'Modification illisible, impossible de l\'envoyer.');
      } finally {
        _inFlight = null;
      }
    }
  }

  Future<void> _send(PendingOperation op, SyncReport report) async {
    final fields = op.fields;
    switch (op.type) {
      case OperationType.createWorkout:
        final created = (op.attempts > 1 ? await _findCreatedWorkout(op) : null) ??
            await api.createWorkout(
              userId: userId,
              request: CreateWorkoutRequest(
                name: fields['name'] as String,
                workoutDate: _date(fields['workoutDate']),
                durationMinutes: fields['durationMinutes'] as int?,
                notes: fields['notes'] as String?,
              ),
            );
        _server = [..._server, created];
        _rename(op.workoutId, created.id);

      case OperationType.updateWorkout:
        await _ifStillOnServer(op, report, () async {
          final base = op.baseUpdatedAt;
          // Sent within a minute of the edit, another device can hardly have
          // changed the workout: no need for the extra request.
          final waited = op.attempts > 0 || clock().difference(op.createdAt) > const Duration(minutes: 1);
          if (base != null && waited) {
            final current = await api.getWorkout(userId: userId, workoutId: op.workoutId);
            if (current.updatedAt.isAfter(base)) {
              report.conflicts++;
              report.notices.add('« ${current.name} » avait aussi été modifiée ailleurs : ta version a été gardée.');
            }
          }
          final updated = await api.updateWorkout(
            userId: userId,
            workoutId: op.workoutId,
            request: UpdateWorkoutRequest(
              name: fields['name'] as String?,
              workoutDate: _date(fields['workoutDate']),
              durationMinutes: fields['durationMinutes'] as int?,
              notes: fields['notes'] as String?,
              isCompleted: fields['isCompleted'] as bool?,
            ),
          );
          _server = [for (final w in _server) w.id == updated.id ? updated : w];
          // Edits recorded while this one was being sent were based on the
          // version before it: this device's own change is not a conflict.
          _operations = [
            for (final o in _operations)
              o.type == OperationType.updateWorkout &&
                      o.workoutId == updated.id &&
                      o.baseUpdatedAt != null &&
                      o.baseUpdatedAt!.isBefore(updated.updatedAt)
                  ? o.copyWith(baseUpdatedAt: updated.updatedAt)
                  : o,
          ];
        });

      case OperationType.deleteWorkout:
        try {
          await api.deleteWorkout(userId: userId, workoutId: op.workoutId);
        } on ApiRequestException catch (e) {
          if (!e.isNotFound) rethrow;
        }
        _server = [for (final w in _server) if (w.id != op.workoutId) w];

      case OperationType.createExercise:
        await _ifStillOnServer(op, report, () async {
          final created = (op.attempts > 1 ? await _findCreatedExercise(op) : null) ??
              await api.addExercise(
                userId: userId,
                workoutId: op.workoutId,
                request: CreateExerciseRequest(
                  exerciseName: fields['exerciseName'] as String,
                  sets: fields['sets'] as int,
                  reps: fields['reps'] as int,
                  weight: (fields['weight'] as num?)?.toDouble(),
                  weightUnit: fields['weightUnit'] == 'lbs' ? WeightUnit.lbs : WeightUnit.kg,
                  orderIndex: fields['orderIndex'] as int?,
                  notes: fields['notes'] as String?,
                ),
              );
          _server = [
            for (final w in _server)
              w.id == op.workoutId ? w.copyWith(exercises: [...w.exercises, created]) : w,
          ];
          _rename(op.exerciseId!, created.id);
        });

      case OperationType.updateExercise:
        await _ifStillOnServer(op, report, exerciseOnly: true, () async {
          final updated = await api.updateExercise(
            userId: userId,
            exerciseId: op.exerciseId!,
            request: UpdateExerciseRequest(
              exerciseName: fields['exerciseName'] as String?,
              sets: fields['sets'] as int?,
              reps: fields['reps'] as int?,
              weight: (fields['weight'] as num?)?.toDouble(),
              weightUnit: switch (fields['weightUnit']) {
                'lbs' => WeightUnit.lbs,
                'kg' => WeightUnit.kg,
                _ => null,
              },
              orderIndex: fields['orderIndex'] as int?,
              notes: fields['notes'] as String?,
              isCompleted: fields['isCompleted'] as bool?,
              setsData: (fields['setsData'] as List<dynamic>?)
                  ?.map((s) => SetModel.fromJson(s as Map<String, dynamic>))
                  .toList(),
            ),
          );
          _server = [
            for (final w in _server)
              w.copyWith(exercises: [for (final e in w.exercises) e.id == updated.id ? updated : e]),
          ];
        });

      case OperationType.deleteExercise:
        try {
          await api.deleteExercise(userId: userId, exerciseId: op.exerciseId!);
        } on ApiRequestException catch (e) {
          if (!e.isNotFound) rethrow;
        }
        _server = [
          for (final w in _server) w.copyWith(exercises: [for (final e in w.exercises) if (e.id != op.exerciseId) e]),
        ];
    }
  }

  /// Runs [send]. A 404 means the workout ([exerciseOnly]: the exercise) was
  /// deleted on another device; the deletion wins and the change is dropped.
  Future<void> _ifStillOnServer(
    PendingOperation op,
    SyncReport report,
    Future<void> Function() send, {
    bool exerciseOnly = false,
  }) async {
    try {
      await send();
    } on ApiRequestException catch (e) {
      if (!e.isNotFound) rethrow;
      final name = serverVersion(op.workoutId)?.name;
      final workout = name == null ? 'une séance' : '« $name »';
      if (exerciseOnly) {
        report.notices.add('Un exercice de $workout a été supprimé sur un autre appareil : ta modification est abandonnée.');
        _server = [
          for (final w in _server) w.copyWith(exercises: [for (final e in w.exercises) if (e.id != op.exerciseId) e]),
        ];
        _operations.removeWhere((o) => o.id != op.id && o.exerciseId == op.exerciseId);
      } else {
        report.notices.add(
          '${workout[0].toUpperCase()}${workout.substring(1)} a été supprimée sur un autre appareil : '
          'tes changements hors ligne sur cette séance sont abandonnés.',
        );
        _server = [for (final w in _server) if (w.id != op.workoutId) w];
        _operations.removeWhere((o) => o.id != op.id && o.workoutId == op.workoutId);
      }
    }
  }

  /// After a lost answer: the workout may exist on the server already.
  Future<WorkoutModel?> _findCreatedWorkout(PendingOperation op) async {
    final known = {for (final w in _server) w.id};
    final date = _date(op.fields['workoutDate']);
    final remote = await api.getUserWorkouts(userId: userId);
    for (final w in remote) {
      if (known.contains(w.id) || w.name != op.fields['name']) continue;
      if (date != null && !_sameDay(w.workoutDate, date)) continue;
      if (w.createdAt.isBefore(op.createdAt.subtract(const Duration(minutes: 5)))) continue;
      return w;
    }
    return null;
  }

  Future<ExerciseModel?> _findCreatedExercise(PendingOperation op) async {
    final known = {for (final e in serverVersion(op.workoutId)?.exercises ?? const <ExerciseModel>[]) e.id};
    final remote = await api.getWorkout(userId: userId, workoutId: op.workoutId);
    for (final e in remote.exercises) {
      if (known.contains(e.id) || e.exerciseName != op.fields['exerciseName']) continue;
      final order = op.fields['orderIndex'] as int?;
      if (order != null && e.orderIndex != order) continue;
      return e;
    }
    return null;
  }

  /// Reloads the workouts from the server. Returns false when unreachable.
  Future<bool> _pull() async {
    try {
      _server = await api.getUserWorkouts(userId: userId);
    } catch (_) {
      return false;
    }
    _hasData = true;
    _syncedAt = clock();
    await store.saveWorkouts(_server, syncedAt: _syncedAt);
    return true;
  }

  // ==================== Refused operations ====================

  /// Sends the refused operations again, e.g. after the server was fixed.
  Future<void> retryRejected() async {
    _operations = [for (final o in _operations) o.isRejected ? o.copyWith(clearRejection: true, attempts: 0) : o];
    await store.saveOperations(_operations);
  }

  /// Drops the refused operations: the server's version is kept.
  Future<void> discardRejected() async {
    _operations.removeWhere((o) => o.isRejected);
    await store.saveOperations(_operations);
  }

  Future<void> _reject(PendingOperation op, String reason) async {
    _replace(op.id, op.copyWith(rejection: reason));
    await store.saveOperations(_operations);
  }

  void _replace(String id, PendingOperation op) {
    final index = _operations.indexWhere((o) => o.id == id);
    if (index >= 0) _operations[index] = op;
  }

  /// A device id became a server id: pending operations now target it.
  void _rename(String localId, String serverId) {
    if (localId == serverId) return;
    _aliases[localId] = serverId;
    _operations = [
      for (final o in _operations)
        o.copyWith(
          workoutId: o.workoutId == localId ? serverId : null,
          exerciseId: o.exerciseId == localId ? serverId : null,
        ),
    ];
    onIdChanged?.call(localId, serverId);
  }

  static DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value) : null;

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
