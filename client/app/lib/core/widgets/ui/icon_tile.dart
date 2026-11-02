import 'package:flutter/material.dart';
import 'package:app/config/app_colors.dart';

/// Rounded square holding an icon, e.g. `w-10 h-10 rounded-xl bg-accent/10`.
class IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;

  /// Defaults to [color] at 10% opacity.
  final Color? background;
  final double size;
  final double iconSize;

  const IconTile({
    super.key,
    required this.icon,
    this.color = AppColors.primary,
    this.background,
    this.size = 40,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size >= 56 ? 16 : 12),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}
