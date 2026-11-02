import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';

/// Form-level error message (e.g. wrong credentials returned by the API).
class InlineError extends StatelessWidget {
  final String message;

  const InlineError(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.circleAlert, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: AppText.caption.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
