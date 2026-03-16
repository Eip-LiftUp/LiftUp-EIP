import 'package:app/core/models/user.dart';
import 'package:app/core/services/api_client.dart';
import 'package:dio/dio.dart';

/// Authentication API service
class AuthApiService {
  final Dio _dio = ApiClient.instance;

  /// Register a new user
  /// POST /users
  Future<CreateUserResponse> register({
    required String email,
    required String username,
    required String password,
    String? displayName,
    FitnessLevel? fitnessLevel,
  }) async {
    try {
      final response = await _dio.post(
        '/users',
        data: {
          'email': email,
          'username': username,
          'password': password,
          if (displayName != null) 'displayName': displayName,
          if (fitnessLevel != null) 'fitnessLevel': fitnessLevel.name,
        },
      );

      return CreateUserResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Login with email and password
  /// POST /auth/login
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user profile by ID
  /// GET /users/:id
  Future<UserProfileResponse> getUserProfile(String userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      return UserProfileResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update user profile
  /// PATCH /users/:id
  Future<UserProfileResponse> updateProfile({
    required String userId,
    String? displayName,
    DateTime? birthDate,
    int? heightCm,
    double? weightKg,
    FitnessLevel? fitnessLevel,
    String? fitnessGoals,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (displayName != null) data['displayName'] = displayName;
      if (birthDate != null) data['birthDate'] = birthDate.toIso8601String();
      if (heightCm != null) data['heightCm'] = heightCm;
      if (weightKg != null) data['weightKg'] = weightKg;
      if (fitnessLevel != null) data['fitnessLevel'] = fitnessLevel.name;
      if (fitnessGoals != null) data['fitnessGoals'] = fitnessGoals;

      final response = await _dio.patch('/users/$userId', data: data);
      return UserProfileResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Convert DioException to ApiException with user-friendly messages
  Exception _handleError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final message = error.response!.data?['error'] ?? 'Unknown error';

      switch (statusCode) {
        case 400:
          return ApiException('Invalid request: $message');
        case 401:
          return ApiException(message); // "Invalid email or password"
        case 409:
          return ApiException(message); // "Email already registered"
        case 422:
          return ApiException('Validation error: $message');
        case 500:
          return ApiException('Server error, please try again later');
        default:
          return ApiException('Error: $message');
      }
    } else {
      return ApiException('Network error: ${error.message}');
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// Login response model
class LoginResponse {
  final String token;
  final String userId;
  final String email;
  final String username;
  final String? displayName;

  LoginResponse({
    required this.token,
    required this.userId,
    required this.email,
    required this.username,
    this.displayName,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      userId: json['userId'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
    );
  }
}

/// Helper function to parse fitness level from string
FitnessLevel? _parseFitnessLevel(String level) {
  switch (level.toLowerCase()) {
    case 'beginner':
      return FitnessLevel.beginner;
    case 'intermediate':
      return FitnessLevel.intermediate;
    case 'advanced':
      return FitnessLevel.advanced;
    default:
      return FitnessLevel.beginner;
  }
}

/// User profile response model
class UserProfileResponse {
  final String userId;
  final String email;
  final String username;
  final String? displayName;
  final DateTime? birthDate;
  final int? heightCm;
  final double? weightKg;
  final FitnessLevel? fitnessLevel;
  final String? fitnessGoals;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfileResponse({
    required this.userId,
    required this.email,
    required this.username,
    this.displayName,
    this.birthDate,
    this.heightCm,
    this.weightKg,
    this.fitnessLevel,
    this.fitnessGoals,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      userId: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      heightCm: json['heightCm'] as int?,
      weightKg: json['weightKg'] != null
          ? (json['weightKg'] as num).toDouble()
          : null,
      fitnessLevel: json['fitnessLevel'] != null
          ? _parseFitnessLevel(json['fitnessLevel'] as String)
          : null,
      fitnessGoals: json['fitnessGoals'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
