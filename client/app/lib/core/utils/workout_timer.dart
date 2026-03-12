import 'dart:async';
import 'package:flutter/foundation.dart';

/// Timer state for active workouts
class WorkoutTimerState {
  final String? workoutId;
  final Duration elapsed;
  final bool isRunning;
  final DateTime? startTime;

  const WorkoutTimerState({
    this.workoutId,
    this.elapsed = Duration.zero,
    this.isRunning = false,
    this.startTime,
  });

  WorkoutTimerState copyWith({
    String? workoutId,
    Duration? elapsed,
    bool? isRunning,
    DateTime? startTime,
  }) {
    return WorkoutTimerState(
      workoutId: workoutId ?? this.workoutId,
      elapsed: elapsed ?? this.elapsed,
      isRunning: isRunning ?? this.isRunning,
      startTime: startTime ?? this.startTime,
    );
  }
}

/// Workout timer controller
class WorkoutTimer extends ChangeNotifier {
  Timer? _timer;
  WorkoutTimerState _state = const WorkoutTimerState();

  WorkoutTimerState get state => _state;

  void start(String workoutId) {
    if (_state.isRunning && _state.workoutId == workoutId) {
      return; // Already running for this workout
    }

    stop(); // Stop any existing timer

    _state = WorkoutTimerState(
      workoutId: workoutId,
      elapsed: Duration.zero,
      isRunning: true,
      startTime: DateTime.now(),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _state = _state.copyWith(
        elapsed: Duration(seconds: _state.elapsed.inSeconds + 1),
      );
      notifyListeners();
    });

    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _state = _state.copyWith(isRunning: false);
    notifyListeners();
  }

  void reset() {
    stop();
    _state = const WorkoutTimerState();
    notifyListeners();
  }

  Duration getElapsed() => _state.elapsed;

  int getDurationMinutes() => (_state.elapsed.inSeconds / 60).ceil();

  String getFormattedTime() {
    final hours = _state.elapsed.inHours;
    final minutes = _state.elapsed.inMinutes.remainder(60);
    final seconds = _state.elapsed.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
