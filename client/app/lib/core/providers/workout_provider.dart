import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/workout_api_service.dart';
import 'package:app/core/models/workout.dart';
import 'package:app/core/providers/auth_provider.dart';

/// State for API workouts
class ApiWorkoutState {
  final List<WorkoutModel> workouts;
  final bool isLoading;
  final String? error;

  const ApiWorkoutState({
    this.workouts = const [],
    this.isLoading = false,
    this.error,
  });

  ApiWorkoutState copyWith({
    List<WorkoutModel>? workouts,
    bool? isLoading,
    String? error,
  }) {
    return ApiWorkoutState(
      workouts: workouts ?? this.workouts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// API Workout State Notifier
class ApiWorkoutNotifier extends StateNotifier<ApiWorkoutState> {
  final WorkoutApiService _apiService;
  final String userId;

  ApiWorkoutNotifier(this._apiService, this.userId) : super(const ApiWorkoutState()) {
    loadWorkouts();
  }

  /// Load all workouts for the user
  Future<void> loadWorkouts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final workouts = await _apiService.getUserWorkouts(userId: userId);
      state = state.copyWith(workouts: workouts, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create a new workout
  Future<WorkoutModel?> createWorkout({
    required String name,
    DateTime? workoutDate,
    int? durationMinutes,
    String? notes,
  }) async {
    try {
      final request = CreateWorkoutRequest(
        name: name,
        workoutDate: workoutDate,
        durationMinutes: durationMinutes,
        notes: notes,
      );
      final workout = await _apiService.createWorkout(
        userId: userId,
        request: request,
      );
      state = state.copyWith(workouts: [...state.workouts, workout]);
      return workout;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
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
    try {
      final request = UpdateWorkoutRequest(
        name: name,
        workoutDate: workoutDate,
        durationMinutes: durationMinutes,
        notes: notes,
        isCompleted: isCompleted,
      );
      final updatedWorkout = await _apiService.updateWorkout(
        userId: userId,
        workoutId: workoutId,
        request: request,
      );
      
      final workouts = state.workouts.map((w) {
        return w.id == workoutId ? updatedWorkout : w;
      }).toList();
      
      state = state.copyWith(workouts: workouts);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete a workout
  Future<bool> deleteWorkout(String workoutId) async {
    try {
      await _apiService.deleteWorkout(userId: userId, workoutId: workoutId);
      final workouts = state.workouts.where((w) => w.id != workoutId).toList();
      state = state.copyWith(workouts: workouts);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
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
    try {
      final request = CreateExerciseRequest(
        exerciseName: exerciseName,
        sets: sets,
        reps: reps,
        weight: weight,
        weightUnit: weightUnit,
        orderIndex: orderIndex,
        notes: notes,
      );
      final exercise = await _apiService.addExercise(
        userId: userId,
        workoutId: workoutId,
        request: request,
      );
      
      final workouts = state.workouts.map((w) {
        if (w.id == workoutId) {
          return w.copyWith(exercises: [...w.exercises, exercise]);
        }
        return w;
      }).toList();
      
      state = state.copyWith(workouts: workouts);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
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
  }) async {
    try {
      final request = UpdateExerciseRequest(
        exerciseName: exerciseName,
        sets: sets,
        reps: reps,
        weight: weight,
        weightUnit: weightUnit,
        orderIndex: orderIndex,
        notes: notes,
        isCompleted: isCompleted,
      );
      final updatedExercise = await _apiService.updateExercise(
        userId: userId,
        exerciseId: exerciseId,
        request: request,
      );
      
      final workouts = state.workouts.map((w) {
        final exercises = w.exercises.map((e) {
          return e.id == exerciseId ? updatedExercise : e;
        }).toList();
        return w.copyWith(exercises: exercises);
      }).toList();
      
      state = state.copyWith(workouts: workouts);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete an exercise
  Future<bool> deleteExercise(String exerciseId) async {
    try {
      await _apiService.deleteExercise(userId: userId, exerciseId: exerciseId);
      
      final workouts = state.workouts.map((w) {
        final exercises = w.exercises.where((e) => e.id != exerciseId).toList();
        return w.copyWith(exercises: exercises);
      }).toList();
      
      state = state.copyWith(workouts: workouts);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Get workout by ID
  WorkoutModel? getWorkout(String workoutId) {
    try {
      return state.workouts.firstWhere((w) => w.id == workoutId);
    } catch (e) {
      return null;
    }
  }
}

/// API Workout Provider
final apiWorkoutProvider = StateNotifierProvider.family<ApiWorkoutNotifier, ApiWorkoutState, String>(
  (ref, userId) {
    final apiService = ref.watch(workoutApiServiceProvider);
    return ApiWorkoutNotifier(apiService, userId);
  },
);
