import 'package:app/core/models/workout.dart';

/// Program returned by `GET /users/:user_id/workouts/program`
/// (docs/program_generation/API_CONTRACT.md §4).
class GeneratedProgram {
  final String programId;
  final DateTime generatedAt;
  final bool fromCache;
  final String name;
  final int weeks;

  /// Sessions in a week; [sessions] holds one week, the first one.
  final int sessionsPerWeek;
  final String? rationale;
  final List<ProgramSession> sessions;

  const GeneratedProgram({
    required this.programId,
    required this.generatedAt,
    required this.fromCache,
    required this.name,
    required this.weeks,
    required this.sessionsPerWeek,
    required this.rationale,
    required this.sessions,
  });

  factory GeneratedProgram.fromJson(Map<String, dynamic> json) {
    final sessions = [
      for (final w in json['workouts'] as List? ?? const []) ProgramSession.fromJson(w as Map<String, dynamic>),
    ];
    return GeneratedProgram(
      programId: json['programId'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      fromCache: json['fromCache'] as bool? ?? false,
      name: json['name'] as String? ?? 'Programme LiftUp',
      weeks: (json['weeks'] as num?)?.toInt() ?? 1,
      sessionsPerWeek: (json['sessionsPerWeek'] as num?)?.toInt() ?? sessions.length,
      rationale: json['rationale'] as String?,
      sessions: sessions,
    );
  }
}

/// One session of the program, shaped like a workout creation request.
class ProgramSession {
  final String name;
  final DateTime workoutDate;
  final int? durationMinutes;
  final List<String> focus;
  final List<ProgramExercise> exercises;

  const ProgramSession({
    required this.name,
    required this.workoutDate,
    required this.durationMinutes,
    required this.focus,
    required this.exercises,
  });

  factory ProgramSession.fromJson(Map<String, dynamic> json) {
    return ProgramSession(
      name: json['name'] as String,
      workoutDate: DateTime.parse(json['workoutDate'] as String),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      focus: [for (final f in json['focus'] as List? ?? const []) f as String],
      exercises: [
        for (final e in json['exercises'] as List? ?? const [])
          ProgramExercise.fromJson(e as Map<String, dynamic>),
      ],
    );
  }
}

class ProgramExercise {
  final String exerciseName;
  final int sets;
  final int reps;
  final double? weight;
  final WeightUnit weightUnit;
  final String? notes;

  const ProgramExercise({
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.weightUnit,
    required this.notes,
  });

  factory ProgramExercise.fromJson(Map<String, dynamic> json) {
    return ProgramExercise(
      exerciseName: json['exerciseName'] as String,
      sets: (json['sets'] as num).toInt(),
      reps: (json['reps'] as num).toInt(),
      weight: (json['weight'] as num?)?.toDouble(),
      weightUnit: json['weightUnit'] == 'lbs' ? WeightUnit.lbs : WeightUnit.kg,
      notes: json['notes'] as String?,
    );
  }
}
