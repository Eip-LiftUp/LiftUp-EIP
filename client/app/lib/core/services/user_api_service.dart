import 'package:dio/dio.dart';
import 'package:app/core/models/user.dart';
import 'package:app/core/models/api_response.dart';
import 'package:app/core/services/api_client.dart';

/// Exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic error;

  ApiException({
    required this.message,
    this.statusCode,
    this.error,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Service for user-related API calls
class UserApiService {
  final Dio _dio = ApiClient().client;

  /// Health check endpoint
  Future<HealthCheckResponse> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return HealthCheckResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a new user
  /// POST /users
  Future<CreateUserResponse> createUser(CreateUserRequest request) async {
    try {
      final response = await _dio.post(
        '/users',
        data: request.toJson(),
      );
      return CreateUserResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle Dio errors and convert to ApiException
  ApiException _handleError(DioException error) {
    String message = 'An unexpected error occurred';
    int? statusCode = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;

      case DioExceptionType.badResponse:
        if (error.response?.data != null) {
          // Try to extract error message from backend response
          try {
            if (error.response!.data is Map<String, dynamic>) {
              final errorData = error.response!.data as Map<String, dynamic>;
              message = errorData['error'] ?? message;
            } else if (error.response!.data is String) {
              message = error.response!.data;
            }
          } catch (_) {
            message = 'Server error: ${error.response?.statusMessage}';
          }
        }
        break;

      case DioExceptionType.connectionError:
        message = 'Cannot connect to server. Please check your connection.';
        break;

      case DioExceptionType.cancel:
        message = 'Request was cancelled';
        break;

      default:
        message = error.message ?? message;
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      error: error,
    );
  }
}
