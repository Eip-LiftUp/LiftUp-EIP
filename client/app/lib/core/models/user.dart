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

/// Self-reported training frequency, collected on the onboarding wizard.
enum ActivityFrequency {
  sedentary,
  light,
  moderate,
  active,
  veryActive,
}

extension ActivityFrequencyApi on ActivityFrequency {
  /// snake_case value expected by the backend (matches the SQL CHECK constraint).
  String get apiValue {
    switch (this) {
      case ActivityFrequency.sedentary:
        return 'sedentary';
      case ActivityFrequency.light:
        return 'light';
      case ActivityFrequency.moderate:
        return 'moderate';
      case ActivityFrequency.active:
        return 'active';
      case ActivityFrequency.veryActive:
        return 'very_active';
    }
  }

  static ActivityFrequency? fromApiValue(String? value) {
    switch (value) {
      case 'sedentary':
        return ActivityFrequency.sedentary;
      case 'light':
        return ActivityFrequency.light;
      case 'moderate':
        return ActivityFrequency.moderate;
      case 'active':
        return ActivityFrequency.active;
      case 'very_active':
        return ActivityFrequency.veryActive;
      default:
        return null;
    }
  }
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
