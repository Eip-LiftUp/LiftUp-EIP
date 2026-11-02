import 'package:flutter/material.dart';
import 'package:app/config/theme.dart';

/// Small tinted label: `rounded-full px-3 py-1` by default, or the tighter
/// `rounded px-2 py-0.5` variant when [dense].
class Pill extends StatelessWidget {
  final String text;
  final Color color;

  /// Defaults to [color] at 10% opacity.
  final Color? background;
  final IconData? icon;
  final bool dense;

  const Pill({
    super.key,
    required this.text,
    required this.color,
    this.background,
    this.icon,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: dense
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(dense ? 6 : 999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              style: AppText.caption.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
