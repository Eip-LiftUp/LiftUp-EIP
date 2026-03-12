import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/exercise_api_service.dart';

/// Exercise list state
class ExerciseListState {
  final List<ExerciseInfo> exercises;
  final bool isLoading;
  final String? error;

  const ExerciseListState({
    this.exercises = const [],
    this.isLoading = false,
    this.error,
  });

  ExerciseListState copyWith({
    List<ExerciseInfo>? exercises,
    bool? isLoading,
    String? error,
  }) {
    return ExerciseListState(
      exercises: exercises ?? this.exercises,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Exercise API service provider
final exerciseApiServiceProvider = Provider<ExerciseApiService>((ref) {
  return ExerciseApiService();
});

/// Exercise list notifier
class ExerciseListNotifier extends StateNotifier<ExerciseListState> {
  final ExerciseApiService _apiService;

  ExerciseListNotifier(this._apiService) : super(const ExerciseListState()) {
    loadPopularExercises();
  }

  /// Load popular exercises (faster, no API call needed)
  void loadPopularExercises() {
    final exercises = _apiService.getPopularExercises();
    state = state.copyWith(exercises: exercises, isLoading: false);
  }

  /// Load all exercises from API
  Future<void> loadExercises() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final exercises = await _apiService.getExercises();
      state = state.copyWith(exercises: exercises, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        exercises: _apiService.getPopularExercises(), // Fallback
      );
    }
  }

  /// Search exercises
  Future<void> searchExercises(String query) async {
    if (query.isEmpty) {
      loadPopularExercises();
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final exercises = await _apiService.searchExercises(query);
      if (exercises.isEmpty) {
        // Fallback to local search
        final popularExercises = _apiService.getPopularExercises();
        final filtered = popularExercises
            .where((ex) => ex.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
        state = state.copyWith(exercises: filtered, isLoading: false);
      } else {
        state = state.copyWith(exercises: exercises, isLoading: false);
      }
    } catch (e) {
      // Fallback to local search
      final popularExercises = _apiService.getPopularExercises();
      final filtered = popularExercises
          .where((ex) => ex.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      state = state.copyWith(exercises: filtered, isLoading: false);
    }
  }
}

/// Exercise list provider
final exerciseListProvider = StateNotifierProvider<ExerciseListNotifier, ExerciseListState>((ref) {
  final service = ref.watch(exerciseApiServiceProvider);
  return ExerciseListNotifier(service);
});
