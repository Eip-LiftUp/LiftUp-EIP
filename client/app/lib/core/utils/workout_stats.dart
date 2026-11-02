import 'dart:math' as math;
import 'package:app/core/models/workout.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// A completed workout in which an exercise beat its previous best weight.
class PersonalRecord {
  final WorkoutModel workout;
  final String exerciseName;
  final double weight;
  final double previous;
  final WeightUnit unit;

  const PersonalRecord({
    required this.workout,
    required this.exerciseName,
    required this.weight,
    required this.previous,
    required this.unit,
  });

  double get gain => weight - previous;
}

/// Figures derived from the user's workouts (all computed client-side from
/// what the API already returns).
class WorkoutStats {
  /// Sorted by date, oldest first.
  final List<WorkoutModel> workouts;

  WorkoutStats(List<WorkoutModel> workouts)
      : workouts = [...workouts]..sort((a, b) => a.workoutDate.compareTo(b.workoutDate));

  List<WorkoutModel> get completed => workouts.where((w) => w.isCompleted).toList();

  List<WorkoutModel> on(DateTime day) =>
      workouts.where((w) => isSameDay(w.workoutDate, day)).toList();

  /// Workouts dated in [start, end), completed or not.
  List<WorkoutModel> scheduledIn(DateTime start, DateTime end) => workouts
      .where((w) => !w.workoutDate.isBefore(start) && w.workoutDate.isBefore(end))
      .toList();

  List<WorkoutModel> completedIn(DateTime start, DateTime end) =>
      scheduledIn(start, end).where((w) => w.isCompleted).toList();

  /// Most recent completed workouts first.
  List<WorkoutModel> recentCompleted({int limit = 3}) =>
      completed.reversed.take(limit).toList();

  /// Consecutive days with a completed workout, ending today — or yesterday
  /// while today's session is still to come.
  int streak(DateTime now) {
    final days = {for (final w in completed) dateOnly(w.workoutDate)};
    var day = dateOnly(now);
    if (!days.contains(day)) day = DateTime(day.year, day.month, day.day - 1);
    var count = 0;
    while (days.contains(day)) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  /// Workouts of the current Monday–Sunday week.
  ({int done, int planned}) week(DateTime now) {
    final start = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final end = DateTime(start.year, start.month, start.day + 7);
    final inWeek = workouts
        .where((w) => !w.workoutDate.isBefore(start) && w.workoutDate.isBefore(end))
        .toList();
    return (done: inWeek.where((w) => w.isCompleted).length, planned: inWeek.length);
  }

  /// Oldest first. An exercise's first occurrence sets the baseline and is
  /// not counted as a record.
  List<PersonalRecord> personalRecords() {
    final bestKg = <String, double>{};
    final records = <PersonalRecord>[];
    for (final workout in completed) {
      for (final exercise in workout.exercises) {
        final top = exercise.sets.fold<double>(0, (best, s) => math.max(best, s.weight ?? 0));
        if (top <= 0) continue;
        final topKg = _toKg(top, exercise.weightUnit);
        final key = exercise.exerciseName.trim().toLowerCase();
        final previousKg = bestKg[key];
        if (previousKg != null && topKg > previousKg) {
          records.add(PersonalRecord(
            workout: workout,
            exerciseName: exercise.exerciseName,
            weight: top,
            previous: _fromKg(previousKg, exercise.weightUnit),
            unit: exercise.weightUnit,
          ));
        }
        if (previousKg == null || topKg > previousKg) bestKg[key] = topKg;
      }
    }
    return records;
  }

  /// The same exercise in the most recent other completed workout, used to
  /// show what was lifted last time.
  ExerciseModel? previousPerformance(String exerciseName, {required String excludingWorkoutId}) {
    final key = exerciseName.trim().toLowerCase();
    for (final workout in completed.reversed) {
      if (workout.id == excludingWorkoutId) continue;
      for (final exercise in workout.exercises) {
        if (exercise.exerciseName.trim().toLowerCase() == key) return exercise;
      }
    }
    return null;
  }

  /// Total load lifted (reps × weight, in kg).
  static double volumeKg(WorkoutModel workout) {
    var total = 0.0;
    for (final exercise in workout.exercises) {
      for (final set in exercise.sets) {
        total += set.reps * _toKg(set.weight ?? 0, exercise.weightUnit);
      }
    }
    return total;
  }

  static double _toKg(double value, WeightUnit unit) =>
      unit == WeightUnit.lbs ? value * 0.45359237 : value;

  static double _fromKg(double value, WeightUnit unit) =>
      unit == WeightUnit.lbs ? value / 0.45359237 : value;
}
