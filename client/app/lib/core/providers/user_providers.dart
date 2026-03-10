import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/user_api_service.dart';
import 'package:app/core/repositories/user_repository.dart';
import 'package:app/core/models/user.dart';

/// Provider for UserApiService singleton
final userApiServiceProvider = Provider<UserApiService>((ref) {
  return UserApiService();
});

/// Provider for UserRepository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiService = ref.watch(userApiServiceProvider);
  return UserRepository(apiService);
});

/// State notifier for user creation
class UserCreationNotifier extends StateNotifier<AsyncValue<CreateUserResponse?>> {
  final UserRepository _repository;

  UserCreationNotifier(this._repository) : super(const AsyncValue.data(null));

  /// Create a new user
  Future<void> createUser(CreateUserRequest request) async {
    state = const AsyncValue.loading();
    
    try {
      final response = await _repository.createUser(request);
      state = AsyncValue.data(response);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for user creation
final userCreationProvider =
    StateNotifierProvider<UserCreationNotifier, AsyncValue<CreateUserResponse?>>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UserCreationNotifier(repository);
});

/// Provider for health check
final healthCheckProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.checkHealth();
});
