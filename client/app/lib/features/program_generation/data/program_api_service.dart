import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/models/user.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/services/api_client.dart';
import 'package:app/core/services/auth_api_service.dart';
import 'package:app/features/program_generation/data/example_program.dart';
import 'package:app/features/program_generation/data/generated_program.dart';

class ProgramGenerationException implements Exception {
  final String message;
  final bool isTimeout;
  final bool profileIncomplete;

  const ProgramGenerationException(
    this.message, {
    this.isTimeout = false,
    this.profileIncomplete = false,
  });

  @override
  String toString() => message;
}

abstract class ProgramApiService {
  Future<GeneratedProgram> generateProgram(String userId);
}

/// Stand-in until the backend endpoint exists (#65): returns the example
/// program, sized to the user's activity frequency like the real engine.
class MockProgramApiService implements ProgramApiService {
  final AuthApiService _authApi;

  MockProgramApiService(this._authApi);

  @override
  Future<GeneratedProgram> generateProgram(String userId) async {
    final profile = await _authApi.getUserProfile(userId);
    await Future<void>.delayed(const Duration(seconds: 3));
    return GeneratedProgram.fromJson(
      exampleProgramJson(
        now: DateTime.now(),
        sessionsPerWeek: _sessionsPerWeek(profile.activityFrequency),
      ),
    );
  }

  static int _sessionsPerWeek(ActivityFrequency? frequency) => switch (frequency) {
        ActivityFrequency.active => 5,
        ActivityFrequency.veryActive => 6,
        ActivityFrequency.moderate => 4,
        _ => 3,
      };
}

/// `GET /users/:user_id/workouts/program` (API_CONTRACT.md §2).
class RealProgramApiService implements ProgramApiService {
  final Dio _dio = ApiClient.instance;

  @override
  Future<GeneratedProgram> generateProgram(String userId) async {
    try {
      final response = await _dio.get(
        '/users/$userId/workouts/program',
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      return GeneratedProgram.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const ProgramGenerationException('Le coach IA met trop de temps à répondre.', isTimeout: true);
      }
      if (e.response?.statusCode == 422) {
        throw const ProgramGenerationException('Ton profil est incomplet.', profileIncomplete: true);
      }
      throw const ProgramGenerationException('Le service de génération est indisponible.');
    }
  }
}

final programApiServiceProvider = Provider<ProgramApiService>((ref) {
  // Switch to RealProgramApiService() once the backend endpoint is live.
  return MockProgramApiService(ref.watch(authApiServiceProvider));
});
