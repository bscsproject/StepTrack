import 'package:flutter/material.dart';

class StepTrackPalette {
  final bool isLight;
  final Color accent;

  const StepTrackPalette._({
    required this.isLight,
    required this.accent,
  });

  factory StepTrackPalette.resolve(
    BuildContext context, {
    required String themeMode,
    required Color accent,
  }) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final light = themeMode == 'light' ||
        (themeMode == 'system' && brightness == Brightness.light);
    return StepTrackPalette._(isLight: light, accent: accent);
  }

  Color get scaffoldBg =>
      isLight ? const Color(0xFFF3F5F8) : const Color(0xFF06080A);
  Color get screenBg =>
      isLight ? const Color(0xFFF5F7FA) : const Color(0xFF07090C);
  Color get cardBg => isLight ? Colors.white : const Color(0xFF12151A);
  Color get tileBg => isLight ? Colors.white : const Color(0xFF12161C);
  Color get elevatedBg =>
      isLight ? const Color(0xFFE7ECF2) : const Color(0xFF1A2028);
  Color get chipBg => isLight ? const Color(0xFFE5EAF0) : const Color(0xFF15191F);
  Color get activeChipBg =>
      isLight ? Colors.white : const Color(0xFF282F3A);
  Color get buttonSecondaryBg =>
      isLight ? const Color(0xFFE2E7EE) : const Color(0xFF232B36);
  Color get borderColor =>
      isLight ? const Color(0xFFD6DEE8) : const Color(0xFF232B36);
  Color get textPrimary =>
      isLight ? const Color(0xFF0E131A) : Colors.white;
  Color get textSecondary =>
      isLight ? const Color(0xFF5A6573) : const Color(0xFF9EA7B3);
  Color get textMuted =>
      isLight ? const Color(0xFF778290) : const Color(0xFF8C96A2);
  Color get onAccent =>
      accent.computeLuminance() > 0.45
          ? const Color(0xFF081016)
          : Colors.white;
}