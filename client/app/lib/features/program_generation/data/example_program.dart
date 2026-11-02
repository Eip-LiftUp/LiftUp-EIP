/// Example program served while the generation engine is not plugged in —
/// the Figma prototype's program, in French. Same JSON shape as the API.
Map<String, dynamic> exampleProgramJson({required DateTime now, required int sessionsPerWeek}) {
  final sessions = _exampleSessions.take(sessionsPerWeek.clamp(1, _exampleSessions.length)).map((s) {
    return {
      'name': s.name,
      'workoutDate': _date(_nextWeekday(now, s.weekday)),
      'durationMinutes': s.minutes,
      'focus': s.focus,
      'exercises': [
        for (final (name, sets, reps) in s.exercises)
          {'exerciseName': name, 'sets': sets, 'reps': reps, 'weight': null, 'weightUnit': 'kg'},
      ],
    };
  }).toList()
    ..sort((a, b) => (a['workoutDate'] as String).compareTo(b['workoutDate'] as String));

  return {
    'programId': 'exemple',
    'generatedAt': now.toUtc().toIso8601String(),
    'fromCache': false,
    'name': 'LiftUp Force & Volume',
    'weeks': 6,
    'rationale':
        'Ce programme privilégie les mouvements polyarticulaires pour développer la force, puis ajoute '
        'du volume ciblé pour une progression équilibrée. La charge est répartie sur la semaine pour que '
        'chaque groupe musculaire récupère avant sa prochaine séance.',
    'workouts': sessions,
  };
}

/// First occurrence of [weekday] strictly after today.
DateTime _nextWeekday(DateTime now, int weekday) {
  final delta = (weekday - now.weekday + 7) % 7;
  return DateTime(now.year, now.month, now.day + (delta == 0 ? 7 : delta));
}

String _date(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

typedef _Session = ({
  int weekday,
  String name,
  int minutes,
  List<String> focus,
  List<(String, int, int)> exercises,
});

const List<_Session> _exampleSessions = [
  (
    weekday: DateTime.monday,
    name: 'Haut du corps — Force',
    minutes: 60,
    focus: ['Pectoraux', 'Dos', 'Épaules'],
    exercises: [
      ('Développé couché', 4, 5),
      ('Tractions lestées', 4, 6),
      ('Développé militaire', 3, 6),
      ('Rowing poitrine appuyée', 3, 8),
      ('Élévations latérales à la poulie', 3, 12),
    ],
  ),
  (
    weekday: DateTime.tuesday,
    name: 'Bas du corps — Force',
    minutes: 65,
    focus: ['Quadriceps', 'Fessiers', 'Ischios'],
    exercises: [
      ('Squat', 4, 5),
      ('Soulevé de terre roumain', 4, 6),
      ('Fentes bulgares', 3, 8),
      ('Leg curl assis', 3, 10),
      ('Mollets debout', 3, 12),
    ],
  ),
  (
    weekday: DateTime.thursday,
    name: 'Haut du corps — Volume',
    minutes: 55,
    focus: ['Dos', 'Pectoraux', 'Bras'],
    exercises: [
      ('Développé incliné haltères', 3, 10),
      ('Tirage vertical', 3, 10),
      ('Rowing assis à la poulie', 3, 12),
      ('Curl haltères', 3, 12),
      ('Extension triceps à la corde', 3, 12),
    ],
  ),
  (
    weekday: DateTime.saturday,
    name: 'Bas du corps — Volume',
    minutes: 60,
    focus: ['Fessiers', 'Quadriceps', 'Abdos'],
    exercises: [
      ('Soulevé de terre trap bar', 4, 6),
      ('Presse à cuisses', 3, 10),
      ('Fentes marchées', 3, 12),
      ('Hip thrust', 3, 10),
      ('Relevés de genoux suspendu', 3, 12),
    ],
  ),
  (
    weekday: DateTime.sunday,
    name: 'Conditionnement athlétique',
    minutes: 45,
    focus: ['Full body', 'Abdos'],
    exercises: [
      ('Kettlebell swing', 4, 12),
      ('Burpees', 4, 10),
      ('Mountain climbers', 3, 20),
      ('Pallof press', 3, 12),
    ],
  ),
  (
    weekday: DateTime.wednesday,
    name: 'Technique & mobilité',
    minutes: 40,
    focus: ['Full body', 'Mobilité'],
    exercises: [
      ('Goblet squat tempo', 3, 8),
      ('Pompes', 3, 12),
      ('Rowing inversé', 3, 10),
    ],
  ),
];
