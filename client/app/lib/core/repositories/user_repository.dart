import 'package:app/core/models/user.dart';
import 'package:app/core/models/api_response.dart';
import 'package:app/core/services/user_api_service.dart';

/// Repository for user data management
class UserRepository {
  final UserApiService _apiService;

  UserRepository(this._apiService);

  /// Check backend health
  Future<bool> checkHealth() async {
    try {
      final response = await _apiService.healthCheck();
      return response.status == 'ok';
    } catch (e) {
      print('[UserRepository] Health check failed: $e');
      return false;
    }
  }

  /// Create a new user account
  Future<CreateUserResponse> createUser(CreateUserRequest request) async {
    try {
      return await _apiService.createUser(request);
    } on ApiException catch (e) {
      // Re-throw with context
      throw ApiException(
        message: 'Failed to create user: ${e.message}',
        statusCode: e.statusCode,
        error: e.error,
      );
    }
  }
}
