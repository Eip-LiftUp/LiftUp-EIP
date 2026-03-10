import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/auth_api_service.dart';
import 'package:app/core/models/user.dart';

/// Provider for AuthApiService
final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService();
});

/// Auth state to track authentication status
class AuthState {
  final bool isAuthenticated;
  final String? token;
  final String? userId;
  final String? email;
  final String? username;
  final String? displayName;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.isAuthenticated = false,
    this.token,
    this.userId,
    this.email,
    this.username,
    this.displayName,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? token,
    String? userId,
    String? email,
    String? username,
    String? displayName,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApiService _authService;

  AuthNotifier(this._authService) : super(AuthState());

  /// Register a new user
  Future<bool> register({
    required String email,
    required String username,
    required String password,
    String? displayName,
    FitnessLevel? fitnessLevel,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.register(
        email: email,
        username: username,
        password: password,
        displayName: displayName,
        fitnessLevel: fitnessLevel,
      );

      // After registration, automatically login
      final loginSuccess = await login(email: email, password: password);
      return loginSuccess;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Registration failed: $e');
      return false;
    }
  }

  /// Login with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      state = state.copyWith(
        isAuthenticated: true,
        token: response.token,
        userId: response.userId,
        email: response.email,
        username: response.username,
        displayName: response.displayName,
        isLoading: false,
        errorMessage: null,
      );

      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Login failed: $e');
      return false;
    }
  }

  /// Logout
  void logout() {
    state = AuthState();
  }

  /// Update display name in auth state
  void updateDisplayName(String displayName) {
    state = state.copyWith(displayName: displayName);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for auth state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authApiServiceProvider);
  return AuthNotifier(authService);
});
