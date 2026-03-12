import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/constants/app_constants.dart';

class AppColors {
  AppColors._();
  
  static const Color background = Color(0xFF0D1B2A);
  static const Color cardBackground = Color(0xFF1B2838);
  static const Color navBarBackground = Color(0xFF1B2838);
  static const Color navBarBorder = Color(0xFF2D3E50);
  static const Color primary = Color(0xFF3B82F6);
  static const Color secondary = Color(0xFF10B981);
  static const Color accent = Color(0xFFF59E0B);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white54;
}

class MainScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBarBackground,
        border: Border(
          top: BorderSide(
            color: AppColors.navBarBorder,
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
                isSelected: currentIndex == 0,
                onTap: () => context.go('/home'),
              ),
              _buildNavItem(
                context,
                icon: Icons.videocam_rounded,
                label: 'Analyse',
                isSelected: currentIndex == 1,
                onTap: () => context.go('/movement-analysis'),
              ),
              _buildNavItem(
                context,
                icon: Icons.calendar_month_rounded,
                label: 'Programme',
                isSelected: currentIndex == 2,
                onTap: () => context.go('/program'),
              ),
              _buildNavItem(
                context,
                icon: Icons.person_rounded,
                label: 'Profil',
                isSelected: currentIndex == 3,
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
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

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
