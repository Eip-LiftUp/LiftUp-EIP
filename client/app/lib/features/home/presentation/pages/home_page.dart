import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/constants/app_constants.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
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
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.fitness_center,
          size: 72,
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(height: AppConstants.spacingL),
        _buildWorkoutButton(
          context,
          icon: Icons.calendar_month_rounded,
          title: 'PROGRAMME',
          route: '/program',
          color: const Color(0xFF10B981),
        ),
        const SizedBox(height: AppConstants.spacingL),
        _buildWorkoutButton(
          context,
          icon: Icons.person_rounded,
          title: 'PROFIL',
          route: '/profile',
          color: const Color(0xFFF59E0B),
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
        color: const Color(0xFF1B2838),
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
                      color: Colors.white,
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

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1B2838),
        border: Border(
          top: BorderSide(
            color: Color(0xFF2D3E50),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home_rounded,
                label: 'Accueil',
                isSelected: true,
                onTap: () {},
              ),
              _buildNavItem(
                context,
                icon: Icons.videocam_rounded,
                label: 'Analyse',
                isSelected: false,
                onTap: () => context.go('/movement-analysis'),
              ),
              _buildNavItem(
                context,
                icon: Icons.calendar_month_rounded,
                label: 'Programme',
                isSelected: false,
                onTap: () => context.go('/program'),
              ),
              _buildNavItem(
                context,
                icon: Icons.person_rounded,
                label: 'Profil',
                isSelected: false,
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? const Color(0xFF3B82F6) : Colors.white54;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
