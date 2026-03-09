import 'package:flutter_riverpod/flutter_riverpod.dart';

// Example AppState Provider
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>(
  (ref) => AppStateNotifier(),
);

class AppState {
  final bool isDarkMode;
  final String? userToken;
  final bool isAuthenticated;
  final String? userName;
  final String? userEmail;

  AppState({
    this.isDarkMode = false,
    this.userToken,
    this.isAuthenticated = false,
    this.userName,
    this.userEmail,
  });

  AppState copyWith({
    bool? isDarkMode,
    String? userToken,
    bool? isAuthenticated,
    String? userName,
    String? userEmail,
  }) {
    return AppState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      userToken: userToken ?? this.userToken,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
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

  void setIsAuthenticated(bool value) {
    state = state.copyWith(isAuthenticated: value);
  }

  void setUserInfo({String? name, String? email}) {
    state = state.copyWith(userName: name, userEmail: email);
  }

  void logout() {
    state = AppState(isDarkMode: state.isDarkMode);
  }
}
