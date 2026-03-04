import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/widgets/main_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          children: [
            const SizedBox(height: AppConstants.spacingXl),
            // Header
            _buildHeader(context),
            const SizedBox(height: AppConstants.spacingXl * 2),
            // Navigation buttons
            Expanded(
              child: _buildNavigationButtons(context),
            ),
            // Version
            Text(
              'Version ${AppConstants.appVersion}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.fitness_center,
          size: 72,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppConstants.spacingM),
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildWorkoutButton(
          context,
          icon: Icons.videocam_rounded,
          title: 'ANALYSE MOUVEMENT',
          route: '/movement-analysis',
          color: AppColors.primary,
        ),
        const SizedBox(height: AppConstants.spacingL),
        _buildWorkoutButton(
          context,
          icon: Icons.calendar_month_rounded,
          title: 'PROGRAMME',
          route: '/program',
          color: AppColors.secondary,
        ),
        const SizedBox(height: AppConstants.spacingL),
        _buildWorkoutButton(
          context,
          icon: Icons.person_rounded,
          title: 'PROFIL',
          route: '/profile',
          color: AppColors.accent,
        ),
      ],
    );
  }

  Widget _buildWorkoutButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: Material(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingL),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
