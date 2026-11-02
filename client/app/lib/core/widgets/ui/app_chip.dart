import 'package:flutter/material.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/widgets/ui/min_tap_target.dart';

/// Figma `Chip`: 36px pill, primary when selected, surface-2 otherwise.
/// Its touch area is 44px high.
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      child: MinTapTarget(
        child: Material(
          color: selected ? AppColors.primary : AppColors.surface2,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            hoverColor: selected
                ? AppColors.primaryStrong
                : AppColors.surface2.withValues(alpha: 0.7),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                widthFactor: 1,
                child: Text(
                  label,
                  style: AppText.caption.copyWith(
                    color: selected
                        ? AppColors.onPrimary
                        : AppColors.textSecondary,
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
