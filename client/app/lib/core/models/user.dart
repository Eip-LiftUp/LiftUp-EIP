import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// Fitness level enum matching backend
enum FitnessLevel {
  @JsonValue('beginner')
  beginner,
  @JsonValue('intermediate')
  intermediate,
  @JsonValue('advanced')
  advanced,
}

/// User entity model
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String username,
    String? displayName,
    DateTime? birthDate,
    int? heightCm,
    double? weightKg,
    required String fitnessLevel,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

/// DTO for creating a new user
@freezed
class CreateUserRequest with _$CreateUserRequest {
  const factory CreateUserRequest({
    required String email,
    required String username,
    String? displayName,
    DateTime? birthDate,
    int? heightCm,
    double? weightKg,
    FitnessLevel? fitnessLevel,
  }) = _CreateUserRequest;

  factory CreateUserRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateUserRequestFromJson(json);
}

/// DTO for user response
@freezed
class CreateUserResponse with _$CreateUserResponse {
  const factory CreateUserResponse({
    required String id,
    required String email,
    required String username,
    String? displayName,
    required String fitnessLevel,
    required DateTime createdAt,
  }) = _CreateUserResponse;

  factory CreateUserResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateUserResponseFromJson(json);
}
