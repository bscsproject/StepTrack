import 'package:flutter/material.dart';

/// StepTrack color palette.
/// Dark mode only.
class AppColors {
  AppColors._();

  // Brand colors
  static const Color primary = Color(0xFF8265FF);
  static const Color secondary = Color(0xFF35B9FF);
  static const Color success = Color(0xFF55E6C1);

  // Dark surfaces
  static const Color background = Color(0xFF0D1020);
  static const Color surface = Color(0xFF1D2340);
  static const Color surfaceElevated = Color(0xFF252C4B);
  static const Color border = Color(0xFF343B5C);

  // Text
  static const Color textPrimary = Color(0xFFF7F7FF);
  static const Color textSecondary = Color(0xFFA5AAC1);
  static const Color textMuted = Color(0xFF737B98);

  // Utility
  static const Color error = Color(0xFFFF647C);
  static const Color warning = Color(0xFFFFC76A);
  static const Color disabled = Color(0xFF515873);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF121832), background],
  );
}
