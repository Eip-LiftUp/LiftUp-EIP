import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/widgets/main_scaffold.dart';
import 'package:app/features/home/presentation/pages/home_page.dart';
import 'package:app/features/profile/presentation/pages/profile_page.dart' show ProfilePage;
import 'package:app/features/planning/presentation/pages/planning_page.dart';
import 'package:app/features/program/presentation/pages/program_page.dart';
import 'package:app/features/program_generation/presentation/generate_program_page.dart';
import 'package:app/features/progress/presentation/pages/progress_page.dart';
import 'package:app/features/auth/auth.dart';
import 'package:app/features/profile_setup/presentation/pages/profile_setup_page.dart';

int _getNavIndex(String location) {
  if (location.startsWith('/training')) return 1;
  if (location.startsWith('/progress')) return 2;
  if (location.startsWith('/profile')) return 3;
  return 0;
}

/// Browser tab and app switcher title of each screen (WCAG 2.4.2).
const _pageTitles = {
  '/onboarding': 'Bienvenue',
  '/login': 'Connexion',
  '/register': 'Inscription',
  '/profile-setup': 'Ton profil',
  '/planning': 'Planning',
  '/profile/training': 'Profil d\'entraînement',
  '/training/generate': 'Générer un programme',
  '/home': 'Accueil',
  '/training': 'Entraînement',
  '/progress': 'Progrès',
  '/profile': 'Profil',
};

String pageTitle(String location) {
  final title = _pageTitles[location];
  return title == null ? 'LiftUp' : '$title · LiftUp';
}

// Custom page with slide transition
CustomTransitionPage<void> _buildPage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      const begin = Offset(0.05, 0.0);
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: Curves.easeOut),
      );
      return Container(
        color: AppColors.background,
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

// Custom page with fade transition for auth pages
CustomTransitionPage<void> _buildAuthPage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}

/// First screen: a session restored from the device goes straight to the app.
String startLocation(AuthState? session) {
  if (session == null) return '/onboarding';
  return session.onboardingCompleted ? '/home' : '/profile-setup';
}

/// A fresh router over the app routes; tests start it at the screen under test.
GoRouter buildAppRouter({String initialLocation = '/onboarding'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    // Auth routes (outside shell)
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => _buildAuthPage(const OnboardingPage(), state),
      name: 'onboarding',
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _buildAuthPage(const LoginPage(), state),
      name: 'login',
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => _buildAuthPage(const RegisterPage(), state),
      name: 'register',
    ),
    GoRoute(
      path: '/profile-setup',
      pageBuilder: (context, state) => _buildAuthPage(const ProfileSetupPage(), state),
      name: 'profile-setup',
    ),

    // Full-screen pages pushed above the tabs (no bottom nav)
    GoRoute(
      path: '/planning',
      pageBuilder: (context, state) => _buildPage(
        PlanningPage(
          initialDate: DateTime.tryParse(state.uri.queryParameters['date'] ?? ''),
        ),
        state,
      ),
      name: 'planning',
    ),
    GoRoute(
      path: '/profile/training',
      pageBuilder: (context, state) => _buildPage(const ProfileSetupPage(editMode: true), state),
      name: 'edit-training-profile',
    ),
    GoRoute(
      path: '/training/generate',
      pageBuilder: (context, state) => _buildPage(const GenerateProgramPage(), state),
      name: 'generate-program',
    ),

    // Main app routes (inside shell with bottom nav)
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
          path: '/training',
          pageBuilder: (context, state) => _buildPage(const ProgramPage(), state),
          name: 'training',
        ),
        GoRoute(
          path: '/progress',
          pageBuilder: (context, state) => _buildPage(const ProgressPage(), state),
          name: 'progress',
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => _buildPage(const ProfilePage(), state),
          name: 'profile',
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Page introuvable')),
    body: Center(
      child: Text(
        'Aucune page à l\'adresse ${state.uri}',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    ),
  ),
);
