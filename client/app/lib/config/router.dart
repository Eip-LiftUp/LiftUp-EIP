import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/features/home/presentation/pages/home_page.dart';
import 'package:app/features/movement_analysis/presentation/pages/movement_analysis_page.dart';
import 'package:app/features/profile/presentation/pages/profile_page.dart';
import 'package:app/features/program/presentation/pages/program_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
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
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(
      child: Text('Page not found: ${state.uri}'),
    ),
  ),
);
