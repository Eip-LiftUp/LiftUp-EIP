/// Exercises the video analysis service knows, by code (`squat`, `pushup`…).
const Map<String, String> kAnalysisExercises = {
  'squat': 'Squat',
  'pushup': 'Pompes',
  'lunge': 'Fentes',
  'bicep_curl': 'Curl biceps',
  'deadlift': 'Soulevé de terre',
  'bench_press': 'Développé couché',
  'shoulder_press': 'Développé militaire',
  'pull_up': 'Tractions',
  'other': 'Autre',
};

/// French name of an analysis exercise code, or the code made readable.
String analysisExerciseLabel(String code) {
  final known = kAnalysisExercises[code] ?? kAnalysisExercises[code.replaceAll('-', '_')];
  if (known != null) return known;
  final text = code.replaceAll(RegExp('[_-]'), ' ').trim();
  return text.isEmpty ? 'Exercice' : '${text[0].toUpperCase()}${text.substring(1)}';
}

enum ReviewVerdict {
  perfect,
  improvable,
  toFix;

  /// Same thresholds as `VideoAnalysisResult.scoreColor` (green / yellow / red).
  static ReviewVerdict fromScore(int score) {
    if (score >= 80) return perfect;
    if (score >= 60) return improvable;
    return toFix;
  }
}

/// A video review reduced to what the calendar needs: the day, the exercise
/// and the score. The verdict is derived from the score, never stored.
class ReviewRecord {
  final DateTime day;
  final String exercise;
  final int score;

  ReviewRecord({required DateTime day, required this.exercise, required this.score})
      : day = DateTime(day.year, day.month, day.day);

  ReviewVerdict get verdict => ReviewVerdict.fromScore(score);

  /// Storage form, ~20 bytes: `20261027|squat|82`.
  String encode() {
    final date = '${day.year}${_two(day.month)}${_two(day.day)}';
    return '$date|${exercise.replaceAll('|', ' ')}|$score';
  }

  static ReviewRecord? decode(String raw) {
    final parts = raw.split('|');
    if (parts.length != 3 || parts[0].length != 8) return null;
    final year = int.tryParse(parts[0].substring(0, 4));
    final month = int.tryParse(parts[0].substring(4, 6));
    final dayOfMonth = int.tryParse(parts[0].substring(6, 8));
    final score = int.tryParse(parts[2]);
    if (year == null || month == null || dayOfMonth == null || score == null) return null;
    return ReviewRecord(
      day: DateTime(year, month, dayOfMonth),
      exercise: parts[1],
      score: score.clamp(0, 100),
    );
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
