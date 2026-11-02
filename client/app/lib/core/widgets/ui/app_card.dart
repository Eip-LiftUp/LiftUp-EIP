import 'package:flutter/material.dart';
import 'package:app/config/app_colors.dart';

/// Figma `Card`: rounded-2xl, 20px padding, surface-1 (surface-2 when
/// [elevated]); hover lightens to surface-2 when tappable.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool elevated;

  /// 4px left border, as in the Figma `border-l-4` highlight cards.
  final Color? accentColor;
  final EdgeInsetsGeometry padding;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.elevated = false,
    this.accentColor,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: padding, child: child);

    if (accentColor != null) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: accentColor!, width: 4)),
        ),
        child: content,
      );
    }

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        hoverColor: AppColors.surface2,
        splashColor: AppColors.surface2,
        highlightColor: AppColors.surface2.withValues(alpha: 0.6),
        child: content,
      );
    }

    return Material(
      color: elevated ? AppColors.surface2 : AppColors.surface1,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}
