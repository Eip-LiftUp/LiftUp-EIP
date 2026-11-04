import 'package:app/core/models/workout.dart';
import 'package:app/core/sync/pending_operation.dart';

/// What the user sees: the last server state with the pending changes on
/// top, so the app shows its own edits whether or not they reached the server.
List<WorkoutModel> applyOperations(
  List<WorkoutModel> server,
  Iterable<PendingOperation> operations, {
  required String userId,
}) {
  var workouts = server;
  for (final operation in operations) {
    workouts = _apply(workouts, operation, userId);
  }
  return workouts;
}

List<WorkoutModel> _apply(List<WorkoutModel> workouts, PendingOperation op, String userId) {
  final fields = op.fields;
  switch (op.type) {
    case OperationType.createWorkout:
      if (workouts.any((w) => w.id == op.workoutId)) return workouts;
      return [
        ...workouts,
        WorkoutModel(
          id: op.workoutId,
          userId: userId,
          name: fields['name'] as String,
          workoutDate: _date(fields['workoutDate']) ?? op.createdAt,
          durationMinutes: fields['durationMinutes'] as int?,
          notes: fields['notes'] as String?,
          createdAt: op.createdAt,
          updatedAt: op.createdAt,
        ),
      ];
    case OperationType.updateWorkout:
      return _mapWorkout(workouts, op.workoutId, (w) {
        return w.copyWith(
          name: fields['name'] as String?,
          workoutDate: _date(fields['workoutDate']),
          durationMinutes: fields['durationMinutes'] as int?,
          notes: fields['notes'] as String?,
          isCompleted: fields['isCompleted'] as bool?,
        );
      });
    case OperationType.deleteWorkout:
      return [for (final w in workouts) if (w.id != op.workoutId) w];
    case OperationType.createExercise:
      return _mapWorkout(workouts, op.workoutId, (w) {
        if (w.exercises.any((e) => e.id == op.exerciseId)) return w;
        final sets = fields['sets'] as int;
        final reps = fields['reps'] as int;
        final weight = (fields['weight'] as num?)?.toDouble();
        return w.copyWith(exercises: [
          ...w.exercises,
          ExerciseModel(
            id: op.exerciseId!,
            workoutId: w.id,
            exerciseName: fields['exerciseName'] as String,
            sets: [for (var i = 1; i <= sets; i++) SetModel(setNumber: i, reps: reps, weight: weight)],
            weightUnit: fields['weightUnit'] == 'lbs' ? WeightUnit.lbs : WeightUnit.kg,
            orderIndex: fields['orderIndex'] as int? ?? w.exercises.length,
            notes: fields['notes'] as String?,
            createdAt: op.createdAt,
          ),
        ]);
      });
    case OperationType.updateExercise:
      return _mapExercise(workouts, op.exerciseId!, (e) => _updateExercise(e, fields));
    case OperationType.deleteExercise:
      return [
        for (final w in workouts)
          w.exercises.any((e) => e.id == op.exerciseId)
              ? w.copyWith(exercises: [for (final e in w.exercises) if (e.id != op.exerciseId) e])
              : w,
      ];
  }
}

/// Mirrors what the backend does with an exercise update: `setsData` replaces
/// the sets, otherwise `sets` / `reps` / `weight` rebuild them.
ExerciseModel _updateExercise(ExerciseModel exercise, Map<String, dynamic> fields) {
  var sets = exercise.sets;
  final setsData = fields['setsData'] as List<dynamic>?;
  if (setsData != null) {
    sets = [for (final s in setsData) SetModel.fromJson(s as Map<String, dynamic>)];
  } else if (fields.containsKey('sets') || fields.containsKey('reps') || fields.containsKey('weight')) {
    final count = fields['sets'] as int? ?? sets.length;
    final reps = fields['reps'] as int? ?? exercise.reps;
    final weight = fields.containsKey('weight') ? (fields['weight'] as num?)?.toDouble() : exercise.weight;
    sets = [
      for (var i = 0; i < count; i++)
        SetModel(
          setNumber: i + 1,
          reps: reps,
          weight: weight,
          isCompleted: i < exercise.sets.length && exercise.sets[i].isCompleted,
        ),
    ];
  }
  final done = fields['isCompleted'] as bool?;
  if (done != null && setsData == null) {
    sets = [for (final s in sets) s.copyWith(isCompleted: done)];
  }
  return exercise.copyWith(
    exerciseName: fields['exerciseName'] as String?,
    sets: sets,
    weightUnit: switch (fields['weightUnit']) {
      'lbs' => WeightUnit.lbs,
      'kg' => WeightUnit.kg,
      _ => null,
    },
    orderIndex: fields['orderIndex'] as int?,
    notes: fields['notes'] as String?,
  );
}

List<WorkoutModel> _mapWorkout(List<WorkoutModel> workouts, String id, WorkoutModel Function(WorkoutModel) update) =>
    [for (final w in workouts) w.id == id ? update(w) : w];

List<WorkoutModel> _mapExercise(List<WorkoutModel> workouts, String id, ExerciseModel Function(ExerciseModel) update) => [
      for (final w in workouts)
        w.exercises.any((e) => e.id == id)
            ? w.copyWith(exercises: [for (final e in w.exercises) e.id == id ? update(e) : e])
            : w,
    ];

DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value) : null;
