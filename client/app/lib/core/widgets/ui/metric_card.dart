import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/widgets/ui/app_card.dart';
import 'package:app/core/widgets/ui/icon_tile.dart';

enum MetricTrend { up, down }

/// Figma `MetricCard`: label, big tabular value, optional trend and icon.
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final MetricTrend? trend;
  final String? trendValue;
  final IconData? icon;
  final VoidCallback? onTap;

  /// Stacks the icon above the texts, for three-column grids where a side
  /// icon leaves no room for the value.
  final bool compact;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.trend,
    this.trendValue,
    this.icon,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: AppText.metric),
        ),
        if (trend != null && trendValue != null) ...[
          const SizedBox(height: 4),
          _TrendLabel(trend: trend!, value: trendValue!),
        ],
      ],
    );

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: icon == null
          ? texts
          : compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconTile(icon: icon!, size: 32, iconSize: 16, background: AppColors.surface2),
                    const SizedBox(height: 12),
                    texts,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: texts),
                    const SizedBox(width: 8),
                    IconTile(icon: icon!, background: AppColors.surface2),
                  ],
                ),
    );
  }
}

class _TrendLabel extends StatelessWidget {
  final MetricTrend trend;
  final String value;

  const _TrendLabel({required this.trend, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = trend == MetricTrend.up ? AppColors.success : AppColors.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          trend == MetricTrend.up ? LucideIcons.trendingUp : LucideIcons.trendingDown,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(value, style: AppText.caption.copyWith(color: color)),
      ],
    );
  }
}
