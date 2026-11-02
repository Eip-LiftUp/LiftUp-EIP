import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/widgets/ui/ui.dart';
import 'package:app/features/auth/presentation/widgets/auth_link.dart';

/// Welcome screen shown before login / registration.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  static const _features = [
    (
      icon: LucideIcons.sparkles,
      color: AppColors.primary,
      title: 'Coach IA',
      subtitle: 'Un programme qui s\'adapte à votre progression',
    ),
    (
      icon: LucideIcons.video,
      color: AppColors.accent,
      title: 'Analyse vidéo',
      subtitle: 'Des conseils pour perfectionner votre technique',
    ),
    (
      icon: LucideIcons.trendingUp,
      color: AppColors.success,
      title: 'Suivi des progrès',
      subtitle: 'Séances, records et évolution',
    ),
  ];

  static const _padding = EdgeInsets.fromLTRB(20, 48, 20, 32);

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        const GradientTile(icon: LucideIcons.dumbbell, size: 80),
        const SizedBox(height: 32),
        const Text('Bienvenue sur LiftUp', style: AppText.h1, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          'Votre coach personnel alimenté par l\'IA pour améliorer vos performances sportives.',
          style: AppText.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            children: [
              for (final feature in _features) ...[
                _FeatureRow(
                  icon: feature.icon,
                  color: feature.color,
                  title: feature.title,
                  subtitle: feature.subtitle,
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );

    final actions = Column(
      children: [
        const SizedBox(height: 24),
        AppButton(
          label: 'Commencer',
          fullWidth: true,
          onPressed: () => context.go('/register'),
        ),
        const SizedBox(height: 8),
        AuthLink(link: 'J\'ai déjà un compte', onTap: () => context.go('/login')),
      ],
    );

    // No IntrinsicHeight: it measures text at the full width and ignores the
    // narrower boxes below, which made this page overflow on wide windows.
    // spaceBetween around an empty first child centers the content above the
    // actions, and the page still scrolls when the window is short.
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: SizedBox(
              width: math.min(constraints.maxWidth, 448 + _padding.horizontal),
              child: SingleChildScrollView(
                padding: _padding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0, constraints.maxHeight - _padding.vertical),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [const SizedBox.shrink(), content, actions],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconTile(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.bodyMedium),
                Text(subtitle, style: AppText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
