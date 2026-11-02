import 'dart:convert';

import 'package:app/core/models/review_record.dart';
import 'package:app/core/models/user.dart';
import 'package:app/core/models/workout.dart';
import 'package:app/core/providers/active_program_provider.dart';
import 'package:app/core/services/auth_api_service.dart';
import 'package:app/core/utils/date_utils.dart';
import 'package:app/core/widgets/ui/verdict_badge.dart';
import 'package:app/features/profile/data/save_export_stub.dart'
    if (dart.library.js_interop) 'package:app/features/profile/data/save_export_web.dart';

/// Everything the app knows about the user, as readable JSON: profile,
/// workouts with their sets, video review verdicts and the started program.
String buildDataExport({
  required UserProfileResponse profile,
  required List<WorkoutModel> workouts,
  required List<ReviewRecord> reviews,
  required ActiveProgram? program,
}) {
  String? date(DateTime? d) => d == null ? null : AppDateUtils.formatDateKey(d);

  final data = {
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'profile': {
      'email': profile.email,
      'username': profile.username,
      'displayName': profile.displayName,
      'birthDate': date(profile.birthDate),
      'heightCm': profile.heightCm,
      'weightKg': profile.weightKg,
      'fitnessLevel': profile.fitnessLevel?.name,
      'fitnessGoals': profile.fitnessGoals,
      'activityFrequency': profile.activityFrequency?.apiValue,
      'hasInjuries': profile.hasInjuries,
      'injuredZones': profile.injuredZones,
      'medicalNotes': profile.medicalNotes,
      'trainingFocus': profile.trainingFocus,
      'memberSince': date(profile.createdAt),
    },
    'workouts': [
      for (final w in workouts)
        {
          'name': w.name,
          'date': date(w.workoutDate),
          'durationMinutes': w.durationMinutes,
          'completed': w.isCompleted,
          'notes': w.notes,
          'exercises': [
            for (final e in w.exercises)
              {
                'name': e.exerciseName,
                'unit': e.weightUnit.displayName,
                'notes': e.notes,
                'sets': [
                  for (final s in e.sets)
                    {'set': s.setNumber, 'reps': s.reps, 'weight': s.weight, 'done': s.isCompleted},
                ],
              },
          ],
        },
    ],
    'videoReviews': [
      for (final r in reviews)
        {
          'date': date(r.day),
          'exercise': analysisExerciseLabel(r.exercise),
          'score': r.score,
          'verdict': r.verdict.label,
        },
    ],
    'activeProgram': program == null
        ? null
        : {
            'name': program.name,
            'startDate': date(program.startDate),
            'weeks': program.weeks,
            'sessionsPerWeek': program.sessionsPerWeek,
          },
  };

  return const JsonEncoder.withIndent('  ').convert(data);
}

/// Downloads the export on the web, copies it to the clipboard elsewhere.
/// Returns the message to show to the user.
Future<String> saveDataExport(String json) {
  return saveExport('liftup-export-${AppDateUtils.formatDateKey(DateTime.now())}.json', json);
}
