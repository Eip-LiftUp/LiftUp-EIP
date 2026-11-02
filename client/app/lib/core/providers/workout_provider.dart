import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/models/workout.dart';
import 'package:app/core/providers/active_workout_provider.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/providers/connectivity_provider.dart';
import 'package:app/core/sync/pending_operation.dart';
import 'package:app/core/sync/workout_repository.dart';
import 'package:app/config/providers.dart';

/// State for API workouts
class ApiWorkoutState {
  final List<WorkoutModel> workouts;
  final bool isLoading;
  final String? error;

  /// Changes made on the device that the server has not received yet.
  final int pendingCount;

  /// Changes the server refused; kept until the user retries or drops them.
  final List<PendingOperation> rejected;
  final bool isSyncing;
  final DateTime? lastSyncedAt;

  /// Messages from the last sync (conflicts, deletions on another device).
  final List<String> notices;

  /// Device ids of workouts created offline → their server ids.
  final Map<String, String> aliases;

  const ApiWorkoutState({
    this.workouts = const [],
    this.isLoading = false,
    this.error,
    this.pendingCount = 0,
    this.rejected = const [],
    this.isSyncing = false,
    this.lastSyncedAt,
    this.notices = const [],
    this.aliases = const {},
  });

  /// The workout with this id, also when it was created offline and has
  /// received its server id since.
  WorkoutModel? byId(String? id) {
    if (id == null) return null;
    final resolved = aliases[id] ?? id;
    return workouts.where((w) => w.id == resolved).firstOrNull;
  }

  ApiWorkoutState copyWith({
    List<WorkoutModel>? workouts,
    bool? isLoading,
    String? error,
  }) {
    return ApiWorkoutState(
      workouts: workouts ?? this.workouts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pendingCount: pendingCount,
      rejected: rejected,
      isSyncing: isSyncing,
      lastSyncedAt: lastSyncedAt,
      notices: notices,
      aliases: aliases,
    );
  }
}

/// API Workout State Notifier
///
/// Works offline: every change is applied on the device at once and queued;
/// the queue is sent when the network is back (see [WorkoutRepository]).
class ApiWorkoutNotifier extends StateNotifier<ApiWorkoutState> {
  final WorkoutRepository _repository;
  final String userId;

  /// False once another user is signed in: the device copy stays readable
  /// but nothing is sent or reloaded any more.
  final bool active;
  bool _online;
  bool _restored = false;

  /// Completes once the device copy is read: changes never wait for the
  /// network.
  late final Future<void> _ready;
  Future<void>? _syncing;
  bool _syncAgain = false;
  bool _refreshAgain = false;
  Timer? _retryTimer;
  int _failures = 0;
  AppLifecycleListener? _lifecycle;
  List<String> _notices = const [];
  String? _error;

  ApiWorkoutNotifier(this._repository, this.userId, {bool online = true, this.active = true})
      : _online = online,
        super(const ApiWorkoutState(isLoading: true)) {
    _ready = _restore();
    if (active) {
      // Back in the foreground: send what was recorded meanwhile.
      _lifecycle = AppLifecycleListener(onResume: () => unawaited(sync()));
      unawaited(sync());
    }
  }

  Future<void> _restore() async {
    await _repository.restore();
    _restored = true;
    _publish();
  }

  /// Delay before retrying after [failures] failed attempts in a row:
  /// 2 s, 4 s, 8 s… up to 5 min.
  static Duration retryDelay(int failures) => Duration(seconds: min(300, 2 << min(max(0, failures - 1), 8)));

  @visibleForTesting
  int get consecutiveFailures => _failures;

  set online(bool value) {
    if (value == _online) return;
    _online = value;
    if (value) {
      _failures = 0;
      unawaited(sync());
    } else {
      _publish();
    }
  }

  /// Sends the pending changes; with [refresh], also reloads the workouts.
  /// Without network it returns at once: the queue goes out when the
  /// connection comes back. Calls made during a sync share it, and it runs
  /// once more if they asked for it.
  Future<void> sync({bool refresh = true}) {
    final running = _syncing;
    if (running != null) {
      _syncAgain = true;
      _refreshAgain |= refresh;
      return running;
    }
    return _syncing = _sync(refresh);
  }

  Future<void> _sync(bool refresh) async {
    try {
      await _ready;
      var pull = refresh;
      do {
        _syncAgain = false;
        if (!mounted || !active) return;
        _retryTimer?.cancel();
        if (!_online) {
          _publish();
          return;
        }
        final run = _repository.sync(refresh: pull);
        _publish();
        final report = await run;
        if (!mounted) return;
        if (report.notices.isNotEmpty) _notices = report.notices;
        _error = report.interrupted ? 'Impossible de charger tes séances : le serveur ne répond pas.' : null;
        if (report.interrupted) {
          _failures++;
          _retryTimer = Timer(retryDelay(_failures), () => unawaited(sync()));
          _publish();
          return;
        }
        _failures = 0;
        _publish();
        pull = _refreshAgain;
        _refreshAgain = false;
      } while (_syncAgain);
    } finally {
      _syncing = null;
    }
  }

  void _publish() {
    if (!mounted) return;
    // Only shown while nothing was ever loaded: afterwards the device copy is
    // displayed and the sync status says what is going on.
    final error = _repository.hasData
        ? null
        : !_online
            ? 'Hors ligne : tes séances s\'afficheront à la première connexion.'
            : _error;
    state = ApiWorkoutState(
      workouts: _repository.workouts,
      isLoading: !_restored || !_repository.hasData && error == null && _repository.pendingCount == 0,
      error: error,
      pendingCount: _repository.pendingCount,
      rejected: _repository.rejected,
      isSyncing: _repository.isSyncing,
      lastSyncedAt: _repository.syncedAt,
      notices: _notices,
      aliases: _repository.aliases,
    );
  }

  /// Applies the change on the device and sends it in the background.
  Future<void> _record(PendingOperation operation) async {
    await _ready;
    await _repository.record(operation);
    _publish();
    unawaited(sync(refresh: false));
  }

  PendingOperation _operation(
    OperationType type, {
    required String workoutId,
    String? exerciseId,
    Map<String, dynamic> fields = const {},
    DateTime? baseUpdatedAt,
  }) {
    return PendingOperation(
      id: _repository.newLocalId(),
      type: type,
      workoutId: workoutId,
      exerciseId: exerciseId,
      fields: fields,
      createdAt: _repository.clock(),
      baseUpdatedAt: baseUpdatedAt,
    );
  }

  /// Drops the messages of the last sync once shown.
  void clearNotices() {
    _notices = const [];
    _publish();
  }

  Future<void> retryRejected() async {
    await _repository.retryRejected();
    _publish();
    await sync();
  }

  Future<void> discardRejected() async {
    await _repository.discardRejected();
    _publish();
    await sync();
  }

  /// Load all workouts for the user
  Future<void> loadWorkouts() => sync();

  /// Create a new workout
  Future<WorkoutModel?> createWorkout({
    required String name,
    DateTime? workoutDate,
    int? durationMinutes,
    String? notes,
  }) async {
    final id = _repository.newLocalId();
    final request = CreateWorkoutRequest(
      name: name,
      workoutDate: workoutDate,
      durationMinutes: durationMinutes,
      notes: notes,
    );
    await _record(_operation(OperationType.createWorkout, workoutId: id, fields: request.toJson()));
    return state.byId(id);
  }

  /// Update a workout
  Future<bool> updateWorkout({
    required String workoutId,
    String? name,
    DateTime? workoutDate,
    int? durationMinutes,
    String? notes,
    bool? isCompleted,
  }) async {
    final request = UpdateWorkoutRequest(
      name: name,
      workoutDate: workoutDate,
      durationMinutes: durationMinutes,
      notes: notes,
      isCompleted: isCompleted,
    );
    await _record(_operation(
      OperationType.updateWorkout,
      workoutId: workoutId,
      fields: request.toJson(),
      baseUpdatedAt: _repository.serverVersion(workoutId)?.updatedAt,
    ));
    return true;
  }

  /// Delete a workout
  Future<bool> deleteWorkout(String workoutId) async {
    await _record(_operation(OperationType.deleteWorkout, workoutId: workoutId));
    return true;
  }

  /// Add an exercise to a workout
  Future<bool> addExercise({
    required String workoutId,
    required String exerciseName,
    required int sets,
    required int reps,
    double? weight,
    WeightUnit? weightUnit,
    int? orderIndex,
    String? notes,
  }) async {
    final request = CreateExerciseRequest(
      exerciseName: exerciseName,
      sets: sets,
      reps: reps,
      weight: weight,
      weightUnit: weightUnit,
      orderIndex: orderIndex,
      notes: notes,
    );
    await _record(_operation(
      OperationType.createExercise,
      workoutId: workoutId,
      exerciseId: _repository.newLocalId(),
      fields: request.toJson(),
    ));
    return true;
  }

  /// Update an exercise
  Future<bool> updateExercise({
    required String exerciseId,
    String? exerciseName,
    int? sets,
    int? reps,
    double? weight,
    WeightUnit? weightUnit,
    int? orderIndex,
    String? notes,
    bool? isCompleted,
    List<SetModel>? setsData,
  }) async {
    final workout = _workoutOf(exerciseId);
    if (workout == null) return false;
    final request = UpdateExerciseRequest(
      exerciseName: exerciseName,
      sets: sets,
      reps: reps,
      weight: weight,
      weightUnit: weightUnit,
      orderIndex: orderIndex,
      notes: notes,
      isCompleted: isCompleted,
      setsData: setsData,
    );
    await _record(_operation(
      OperationType.updateExercise,
      workoutId: workout.id,
      exerciseId: exerciseId,
      fields: request.toJson(),
    ));
    return true;
  }

  /// Delete an exercise
  Future<bool> deleteExercise(String exerciseId) async {
    final workout = _workoutOf(exerciseId);
    if (workout == null) return false;
    await _record(_operation(OperationType.deleteExercise, workoutId: workout.id, exerciseId: exerciseId));
    return true;
  }

  /// Get workout by ID
  WorkoutModel? getWorkout(String workoutId) => state.byId(workoutId);

  WorkoutModel? _workoutOf(String exerciseId) {
    final id = _repository.resolve(exerciseId);
    return state.workouts.where((w) => w.exercises.any((e) => e.id == id)).firstOrNull;
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }
}

/// API Workout Provider
final apiWorkoutProvider = StateNotifierProvider.family<ApiWorkoutNotifier, ApiWorkoutState, String>(
  (ref, userId) {
    // Rebuilt when the signed-in user changes, which stops the background
    // sync of the previous one.
    final signedIn = ref.watch(authProvider.select((auth) => auth.userId)) == userId;
    final repository = WorkoutRepository(userId: userId, api: ref.watch(workoutApiServiceProvider));
    // A session started on a workout created offline follows its new id.
    repository.onIdChanged = (localId, serverId) => ref.read(activeWorkoutProvider).rename(localId, serverId);
    final notifier = ApiWorkoutNotifier(repository, userId, online: ref.read(isOnlineProvider), active: signedIn);
    ref.listen<bool>(isOnlineProvider, (_, online) => notifier.online = online);
    return notifier;
  },
);
