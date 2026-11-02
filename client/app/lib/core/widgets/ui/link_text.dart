import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/widgets/ui/min_tap_target.dart';

/// Small primary-colored link with a chevron, e.g. "Planning ›".
class LinkText extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const LinkText(this.label, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      link: true,
      child: MinTapTarget(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppText.caption.copyWith(color: AppColors.primary, fontSize: 14)),
                const SizedBox(width: 2),
                const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
