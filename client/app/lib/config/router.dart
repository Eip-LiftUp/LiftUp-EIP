import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/widgets/main_scaffold.dart';
import 'package:app/features/home/presentation/pages/home_page.dart';
import 'package:app/features/movement_analysis/presentation/pages/movement_analysis_page.dart';
import 'package:app/features/profile/presentation/pages/profile_page.dart';
import 'package:app/features/program/presentation/pages/program_page.dart';

int _getNavIndex(String location) {
  if (location.startsWith('/movement-analysis')) return 1;
  if (location.startsWith('/program')) return 2;
  if (location.startsWith('/profile')) return 3;
  return 0;
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainScaffold(
          currentIndex: _getNavIndex(state.uri.path),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
          name: 'home',
        ),
        GoRoute(
          path: '/movement-analysis',
          builder: (context, state) => const MovementAnalysisPage(),
          name: 'movement-analysis',
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
          name: 'profile',
        ),
        GoRoute(
          path: '/program',
          builder: (context, state) => const ProgramPage(),
          name: 'program',
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    backgroundColor: const Color(0xFF0D1B2A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF1B2838),
      title: const Text('Error', style: TextStyle(color: Colors.white)),
    ),
    body: Center(
      child: Text(
        'Page not found: ${state.uri}',
        style: const TextStyle(color: Colors.white),
      ),
    ),
  ),
);
