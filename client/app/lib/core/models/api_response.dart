import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_response.freezed.dart';
part 'api_response.g.dart';

/// Generic API response wrapper
@Freezed(genericArgumentFactories: true)
class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse.success(T data) = ApiSuccess<T>;
  
  const factory ApiResponse.error({
    required String message,
    int? statusCode,
    dynamic error,
  }) = ApiError<T>;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);
}

/// Health check response
@freezed
class HealthCheckResponse with _$HealthCheckResponse {
  const factory HealthCheckResponse({
    required String status,
    required String service,
  }) = _HealthCheckResponse;

  factory HealthCheckResponse.fromJson(Map<String, dynamic> json) =>
      _$HealthCheckResponseFromJson(json);
}

/// Error response from backend
@freezed
class ErrorResponse with _$ErrorResponse {
  const factory ErrorResponse({
    required String error,
  }) = _ErrorResponse;

  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseFromJson(json);
}
