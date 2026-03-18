import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/config/router.dart';
import 'package:app/config/theme.dart';
import 'package:app/config/providers.dart';
import 'package:app/core/constants/app_constants.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
      themeAnimationDuration: appState.reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 250),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(appState.textScaleFactor),
              highContrast: appState.highContrast,
              boldText: appState.highContrast,
              disableAnimations: appState.reduceMotion,
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
