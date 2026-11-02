import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/utils/workout_timer.dart';

/// The session in progress and its timer. Lives above the pages so it
/// survives tab switches and can be started from the home screen.
class ActiveWorkoutController extends ChangeNotifier {
  final WorkoutTimer timer = WorkoutTimer();
  String? _workoutId;

  String? get workoutId => _workoutId;
  bool get isActive => _workoutId != null;

  void start(String workoutId) {
    if (_workoutId == workoutId) return;
    _workoutId = workoutId;
    timer.start(workoutId);
    notifyListeners();
  }

  /// Ends the session and returns its duration in minutes.
  int finish() {
    final minutes = timer.getDurationMinutes();
    timer.reset();
    _workoutId = null;
    notifyListeners();
    return minutes;
  }

  @override
  void dispose() {
    timer.dispose();
    super.dispose();
  }
}

final activeWorkoutProvider =
    ChangeNotifierProvider<ActiveWorkoutController>((ref) => ActiveWorkoutController());
