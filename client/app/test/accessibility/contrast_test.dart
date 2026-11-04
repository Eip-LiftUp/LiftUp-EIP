@Tags(['accessibility'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/config/app_colors.dart';

double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

/// A [color] tint at 10% over [surface], as drawn by Pill and IconTile.
Color tint(Color color, Color surface) => Color.alphaBlend(color.withValues(alpha: 0.1), surface);

void main() {
  const surfaces = {
    'background': AppColors.background,
    'surface1': AppColors.surface1,
    'surface2': AppColors.surface2,
  };

  group('text contrast ≥ 4.5:1 (WCAG 1.4.3)', () {
    const texts = {
      'textPrimary': AppColors.textPrimary,
      'textSecondary': AppColors.textSecondary,
      'primary': AppColors.primary,
      'accent': AppColors.accent,
      'success': AppColors.success,
      'warning': AppColors.warning,
      'error': AppColors.error,
    };
    for (final MapEntry(key: textName, value: text) in texts.entries) {
      for (final MapEntry(key: surfaceName, value: surface) in surfaces.entries) {
        test('$textName on $surfaceName', () {
          expect(contrastRatio(text, surface), greaterThanOrEqualTo(4.5));
        });
      }
      test('$textName pill on surface1', () {
        expect(contrastRatio(text, tint(text, AppColors.surface1)), greaterThanOrEqualTo(4.5));
      });
    }

    test('primary button label', () {
      expect(contrastRatio(AppColors.onPrimary, AppColors.primary), greaterThanOrEqualTo(4.5));
    });
    test('destructive button label', () {
      expect(contrastRatio(AppColors.onPrimary, AppColors.error), greaterThanOrEqualTo(4.5));
    });
    test('timer card text on the primary gradient', () {
      expect(contrastRatio(AppColors.onPrimary, AppColors.primaryStrong), greaterThanOrEqualTo(4.5));
    });
  });

  group('control outlines ≥ 3:1 (WCAG 1.4.11)', () {
    for (final MapEntry(key: surfaceName, value: surface) in surfaces.entries.take(2)) {
      test('field border on $surfaceName', () {
        expect(contrastRatio(AppColors.borderStrong, surface), greaterThanOrEqualTo(3));
      });
      test('focused field border on $surfaceName', () {
        expect(contrastRatio(AppColors.primary, surface), greaterThanOrEqualTo(3));
      });
    }
  });
}
