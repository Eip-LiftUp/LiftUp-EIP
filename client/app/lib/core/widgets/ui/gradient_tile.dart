import 'package:flutter/material.dart';
import 'package:app/config/app_colors.dart';

/// Primary → primary-strong gradient square with an icon (logo, avatar).
class GradientTile extends StatelessWidget {
  final IconData icon;
  final double size;

  const GradientTile({super.key, required this.icon, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, size: size / 2, color: AppColors.onPrimary),
    );
  }
}
