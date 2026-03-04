import 'package:flutter_riverpod/flutter_riverpod.dart';

// Example AppState Provider
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>(
  (ref) => AppStateNotifier(),
);

class AppState {
  final bool isDarkMode;
  final String? userToken;

  AppState({
    this.isDarkMode = false,
    this.userToken,
  });

  AppState copyWith({
    bool? isDarkMode,
    String? userToken,
  }) {
    return AppState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      userToken: userToken ?? this.userToken,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState());

  void toggleDarkMode() {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
  }

  void setUserToken(String token) {
    state = state.copyWith(userToken: token);
  }

  void logout() {
    state = state.copyWith(userToken: null);
  }
}
