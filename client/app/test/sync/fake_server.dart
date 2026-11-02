import 'dart:async';

import 'package:app/core/models/workout.dart';
import 'package:app/core/services/workout_api_service.dart';

/// In-memory backend that can be cut off, refuse a request, or lose an
/// answer after doing the work — the cases offline sync has to survive.
class FakeServer extends WorkoutApiService {
  final Map<String, WorkoutModel> workouts = {};
  final List<String> calls = [];
  bool offline = false;
  DateTime now = DateTime(2026, 11, 2, 18);
  int _ids = 0;

  /// Status code of the next request (then back to normal).
  int? refuseNext;

  /// The next request is applied but its answer never arrives.
  bool loseNextAnswer = false;

  /// Requests wait until this completes (slow network).
  Completer<void>? hold;

  /// The next answer is not JSON (e.g. a Wi-Fi portal page) and fails to
  /// parse, as a raw client would.
  bool garbleNext = false;

  String _id(String prefix) => '$prefix-${++_ids}';

  Future<T> _call<T>(String name, T Function() action) async {
    calls.add(name);
    final held = hold;
    if (held != null) await held.future;
    if (offline) throw const ApiRequestException('Connection error', isNetworkError: true);
    if (garbleNext) {
      garbleNext = false;
      throw const FormatException('<html>Connexion au Wi-Fi</html>');
    }
    final refused = refuseNext;
    if (refused != null) {
      refuseNext = null;
      throw ApiRequestException('Error $refused', statusCode: refused);
    }
    final result = action();
    if (loseNextAnswer) {
      loseNextAnswer = false;
      throw const ApiRequestException('Connection timeout', isNetworkError: true);
    }
    return result;
  }

  WorkoutModel _workout(String id) {
    final workout = workouts[id];
    if (workout == null) throw const ApiRequestException('Not found', statusCode: 404);
    return workout;
  }

  /// A workout as another device would have left it on the server.
  WorkoutModel seed(String name, {DateTime? date, List<String> exercises = const []}) {
    final id = _id('w');
    final workout = WorkoutModel(
      id: id,
      userId: 'u1',
      name: name,
      workoutDate: date ?? DateTime(2026, 11, 2),
      exercises: [
        for (final (i, e) in exercises.indexed)
          ExerciseModel(
            id: _id('e'),
            workoutId: id,
            exerciseName: e,
            sets: [SetModel(setNumber: 1, reps: 8, weight: 60)],
            orderIndex: i,
            createdAt: now,
          ),
      ],
      createdAt: now,
      updatedAt: now,
    );
    workouts[id] = workout;
    return workout;
  }

  /// Lets the held requests through.
  void release() {
    final held = hold;
    hold = null;
    held?.complete();
  }

  void editElsewhere(String id, {String? name}) {
    now = now.add(const Duration(minutes: 1));
    workouts[id] = workouts[id]!.copyWith(name: name, updatedAt: now);
  }

  @override
  Future<List<WorkoutModel>> getUserWorkouts({required String userId}) =>
      _call('GET /workouts', () => workouts.values.toList());

  @override
  Future<WorkoutModel> getWorkout({required String userId, required String workoutId}) =>
      _call('GET /workouts/$workoutId', () => _workout(workoutId));

  @override
  Future<WorkoutModel> createWorkout({required String userId, required CreateWorkoutRequest request}) =>
      _call('POST /workouts', () {
        final id = _id('w');
        now = now.add(const Duration(seconds: 1));
        return workouts[id] = WorkoutModel(
          id: id,
          userId: userId,
          name: request.name,
          workoutDate: request.workoutDate ?? now,
          durationMinutes: request.durationMinutes,
          notes: request.notes,
          createdAt: now,
          updatedAt: now,
        );
      });

  @override
  Future<WorkoutModel> updateWorkout({
    required String userId,
    required String workoutId,
    required UpdateWorkoutRequest request,
  }) =>
      _call('PATCH /workouts/$workoutId', () {
        final w = _workout(workoutId);
        now = now.add(const Duration(seconds: 1));
        return workouts[workoutId] = w.copyWith(
          name: request.name,
          workoutDate: request.workoutDate,
          durationMinutes: request.durationMinutes,
          notes: request.notes,
          isCompleted: request.isCompleted,
          updatedAt: now,
        );
      });

  @override
  Future<void> deleteWorkout({required String userId, required String workoutId}) =>
      _call('DELETE /workouts/$workoutId', () {
        _workout(workoutId);
        workouts.remove(workoutId);
      });

  @override
  Future<ExerciseModel> addExercise({
    required String userId,
    required String workoutId,
    required CreateExerciseRequest request,
  }) =>
      _call('POST /workouts/$workoutId/exercises', () {
        final w = _workout(workoutId);
        final exercise = ExerciseModel(
          id: _id('e'),
          workoutId: workoutId,
          exerciseName: request.exerciseName,
          sets: [
            for (var i = 1; i <= request.sets; i++) SetModel(setNumber: i, reps: request.reps, weight: request.weight),
          ],
          orderIndex: request.orderIndex ?? w.exercises.length,
          notes: request.notes,
          createdAt: now,
        );
        workouts[workoutId] = w.copyWith(exercises: [...w.exercises, exercise]);
        return exercise;
      });

  @override
  Future<ExerciseModel> updateExercise({
    required String userId,
    required String exerciseId,
    required UpdateExerciseRequest request,
  }) =>
      _call('PATCH /exercises/$exerciseId', () {
        for (final w in workouts.values) {
          for (final e in w.exercises) {
            if (e.id != exerciseId) continue;
            final updated = e.copyWith(
              exerciseName: request.exerciseName,
              sets: request.setsData,
              notes: request.notes,
            );
            workouts[w.id] = w.copyWith(exercises: [for (final x in w.exercises) x.id == e.id ? updated : x]);
            return updated;
          }
        }
        throw const ApiRequestException('Not found', statusCode: 404);
      });

  @override
  Future<void> deleteExercise({required String userId, required String exerciseId}) =>
      _call('DELETE /exercises/$exerciseId', () {
        for (final w in workouts.values) {
          if (w.exercises.any((e) => e.id == exerciseId)) {
            workouts[w.id] = w.copyWith(exercises: [for (final e in w.exercises) if (e.id != exerciseId) e]);
            return;
          }
        }
        throw const ApiRequestException('Not found', statusCode: 404);
      });
}
