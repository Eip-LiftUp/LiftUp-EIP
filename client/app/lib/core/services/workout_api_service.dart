import 'package:dio/dio.dart';
import 'package:app/core/models/workout.dart';

/// Workout API service for managing workouts and exercises
class WorkoutApiService {
  final Dio _dio;

  WorkoutApiService({String baseUrl = 'http://10.73.189.64:8080'}) : _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // ==================== WORKOUTS ====================

  /// Create a new workout
  Future<WorkoutModel> createWorkout({
    required String userId,
    required CreateWorkoutRequest request,
  }) async {
    try {
      final response = await _dio.post(
        '/users/$userId/workouts',
        data: request.toJson(),
      );
      return WorkoutModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all workouts for a user
  Future<List<WorkoutModel>> getUserWorkouts({required String userId}) async {
    try {
      final response = await _dio.get('/users/$userId/workouts');
      final List<dynamic> data = response.data;
      return data.map((json) => WorkoutModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get a specific workout by ID
  Future<WorkoutModel> getWorkout({
    required String userId,
    required String workoutId,
  }) async {
    try {
      final response = await _dio.get('/users/$userId/workouts/$workoutId');
      return WorkoutModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update a workout
  Future<WorkoutModel> updateWorkout({
    required String userId,
    required String workoutId,
    required UpdateWorkoutRequest request,
  }) async {
    try {
      final response = await _dio.patch(
        '/users/$userId/workouts/$workoutId',
        data: request.toJson(),
      );
      return WorkoutModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete a workout
  Future<void> deleteWorkout({
    required String userId,
    required String workoutId,
  }) async {
    try {
      await _dio.delete('/users/$userId/workouts/$workoutId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== EXERCISES ====================

  /// Add an exercise to a workout
  Future<ExerciseModel> addExercise({
    required String userId,
    required String workoutId,
    required CreateExerciseRequest request,
  }) async {
    try {
      final response = await _dio.post(
        '/users/$userId/workouts/$workoutId/exercises',
        data: request.toJson(),
      );
      return ExerciseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update an exercise
  Future<ExerciseModel> updateExercise({
    required String userId,
    required String exerciseId,
    required UpdateExerciseRequest request,
  }) async {
    try {
      final response = await _dio.patch(
        '/users/$userId/exercises/$exerciseId',
        data: request.toJson(),
      );
      return ExerciseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete an exercise
  Future<void> deleteExercise({
    required String userId,
    required String exerciseId,
  }) async {
    try {
      await _dio.delete('/users/$userId/exercises/$exerciseId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== ERROR HANDLING ====================

  Exception _handleError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final message = error.response!.data?['error'] ?? 'Unknown error';

      switch (statusCode) {
        case 400:
          return Exception('Bad request: $message');
        case 401:
          return Exception('Unauthorized: $message');
        case 403:
          return Exception('Forbidden: $message');
        case 404:
          return Exception('Not found: $message');
        case 409:
          return Exception('Conflict: $message');
        case 422:
          return Exception('Validation error: $message');
        case 500:
          return Exception('Server error: $message');
        default:
          return Exception('Error: $message');
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return Exception('Connection timeout');
    }

    if (error.type == DioExceptionType.connectionError) {
      return Exception('Connection error. Please check your internet connection.');
    }

    return Exception('Unknown error: ${error.message}');
  }
}
