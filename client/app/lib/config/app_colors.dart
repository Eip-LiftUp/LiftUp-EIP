import 'package:flutter/material.dart';

/// Design tokens of the Figma prototype (`src/styles/theme.css`).
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0B1020);
  static const Color surface1 = Color(0xFF111A33);
  static const Color surface2 = Color(0xFF17244A);
  static const Color border = Color(0xFF22325E);

  /// Outline of form controls (fields, radio circles): `border` is too faint
  /// to make out a field on the background (WCAG 1.4.11 asks for 3:1).
  static const Color borderStrong = Color(0xFF5A6CA3);

  static const Color primary = Color(0xFF2FB6FF);
  static const Color primaryStrong = Color(0xFF1C86FF);
  static const Color onPrimary = Color(0xFF0B1020);
  static const Color accent = Color(0xFFFF8A2A);

  static const Color textPrimary = Color(0xFFF2F5FF);
  static const Color textSecondary = Color(0xFFB7C0D9);

  static const Color success = Color(0xFF2ED573);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFFF4D4D);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryStrong],
  );

  // Pre-Figma names, still used by pages that have not been migrated yet.
  static const Color cardBackground = surface1;
  static const Color navBarBackground = surface1;
  static const Color navBarBorder = border;
  static const Color secondary = success;
}
