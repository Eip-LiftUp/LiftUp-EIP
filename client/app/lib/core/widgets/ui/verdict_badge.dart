import 'package:flutter/material.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/core/models/review_record.dart';
import 'package:app/core/widgets/ui/day_marker.dart';
import 'package:app/core/widgets/ui/pill.dart';

extension ReviewVerdictStyle on ReviewVerdict {
  String get label => switch (this) {
        ReviewVerdict.perfect => 'Parfait',
        ReviewVerdict.improvable => 'Améliorable',
        ReviewVerdict.toFix => 'À corriger',
      };

  Color get color => switch (this) {
        ReviewVerdict.perfect => AppColors.success,
        ReviewVerdict.improvable => AppColors.warning,
        ReviewVerdict.toFix => AppColors.error,
      };

  /// Green and orange are too close for protanopia: the shape tells them apart.
  DayMarkerShape get markerShape => switch (this) {
        ReviewVerdict.perfect => DayMarkerShape.square,
        ReviewVerdict.improvable => DayMarkerShape.diamond,
        ReviewVerdict.toFix => DayMarkerShape.triangle,
      };
}

class VerdictBadge extends StatelessWidget {
  final ReviewVerdict verdict;

  const VerdictBadge(this.verdict, {super.key});

  @override
  Widget build(BuildContext context) => Pill(text: verdict.label, color: verdict.color, dense: true);
}
