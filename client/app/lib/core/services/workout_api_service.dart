import 'package:dio/dio.dart';
import 'package:app/core/models/workout.dart';

/// A failed call: either the server answered with [statusCode], or it could
/// not be reached ([isNetworkError]) and the call may be retried as is.
class ApiRequestException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;

  const ApiRequestException(this.message, {this.statusCode, this.isNetworkError = false});

  /// The server refused the request itself: sending it again won't help.
  /// Session (401, 403), timeout (408) and rate limit (429) answers are
  /// worth retrying later.
  bool get isRejected {
    final code = statusCode;
    return code != null && code >= 400 && code < 500 && !const {401, 403, 408, 429}.contains(code);
  }

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}

/// Workout API service for managing workouts and exercises
class WorkoutApiService {
  final Dio _dio;

  /// [dio] replaces the HTTP client, e.g. in tests.
  WorkoutApiService({String baseUrl = 'http://10.0.2.2:8080', Dio? dio}) : _dio = dio ?? Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 90),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  ) {
    // Add interceptor for debugging
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => print('[API] $obj'),
      ),
    );
  }

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
    } catch (e) {
      throw _unexpectedResponse(e);
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
    } catch (e) {
      throw _unexpectedResponse(e);
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
    } catch (e) {
      throw _unexpectedResponse(e);
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
    } catch (e) {
      throw _unexpectedResponse(e);
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
    } catch (e) {
      throw _unexpectedResponse(e);
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
    } catch (e) {
      throw _unexpectedResponse(e);
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
    } catch (e) {
      throw _unexpectedResponse(e);
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
    } catch (e) {
      throw _unexpectedResponse(e);
    }
  }

  // ==================== ERROR HANDLING ====================

  /// A body that is not the expected JSON, e.g. the page of a Wi-Fi portal:
  /// treated like a network failure, so the call is retried later.
  ApiRequestException _unexpectedResponse(Object error) =>
      ApiRequestException('Unexpected response: $error', isNetworkError: true);

  ApiRequestException _handleError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;
      final message = (data is Map ? data['error'] : null) ?? 'Unknown error';

      final text = switch (statusCode) {
        400 => 'Bad request: $message',
        401 => 'Unauthorized: $message',
        403 => 'Forbidden: $message',
        404 => 'Not found: $message',
        409 => 'Conflict: $message',
        422 => 'Validation error: $message',
        500 => 'Server error: $message',
        _ => 'Error: $message',
      };
      return ApiRequestException(text, statusCode: statusCode);
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const ApiRequestException('Connection timeout', isNetworkError: true);
    }

    if (error.type == DioExceptionType.connectionError) {
      return const ApiRequestException(
        'Connection error. Please check your internet connection.',
        isNetworkError: true,
      );
    }

    return ApiRequestException('Unknown error: ${error.message}', isNetworkError: true);
  }
}
