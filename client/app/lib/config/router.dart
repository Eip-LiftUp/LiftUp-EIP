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

// Custom page with slide transition
CustomTransitionPage<void> _buildPage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.05, 0.0);
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: Curves.easeOut),
      );
      return Container(
        color: const Color(0xFF0D1B2A),
        child: SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
      );
    },
  );
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
          pageBuilder: (context, state) => _buildPage(const HomePage(), state),
          name: 'home',
        ),
        GoRoute(
          path: '/movement-analysis',
          pageBuilder: (context, state) => _buildPage(const MovementAnalysisPage(), state),
          name: 'movement-analysis',
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => _buildPage(const ProfilePage(), state),
          name: 'profile',
        ),
        GoRoute(
          path: '/program',
          pageBuilder: (context, state) => _buildPage(const ProgramPage(), state),
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
