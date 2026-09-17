import 'package:flutter/material.dart';
import 'lumina_colors.dart';
import 'lumina_dimensions.dart';

class LuminaTheme {
  static const Color accentColor = LuminaColors.accent;
  static const Color primaryColor = LuminaColors.primary;
  static const Color accentDeepColor = LuminaColors.accentDeep;
  static const Color accentSoftColor = LuminaColors.accentSoft;
  static const Color accentMutedColor = LuminaColors.accentMuted;
  static const Color backgroundColor = LuminaColors.background;
  static const Color textColor = LuminaColors.textMain;
  static const Color subTitleColor = LuminaColors.textSecondary;
  static const Color errorColor = LuminaColors.error;
  static const Color errorDeepColor = LuminaColors.errorDeep;
  static const Color errorSoftColor = LuminaColors.errorSoft;

  static Color get titleColor => textColor;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'SF Pro Display',
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.light,
        primary: accentColor,
        secondary: accentDeepColor,
        error: errorColor,
        surface: LuminaColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor, size: 20),
        titleTextStyle: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: -0.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LuminaColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: LuminaDimensions.paddingM,
          vertical: LuminaDimensions.paddingM,
        ),
        hintStyle: const TextStyle(color: Colors.black26, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: LuminaDimensions.borderRadiusMedium,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: LuminaDimensions.borderRadiusMedium,
          borderSide: const BorderSide(color: accentColor, width: 1.6),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textColor, fontSize: 16),
        bodyMedium: TextStyle(color: subTitleColor, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: LuminaDimensions.borderRadiusMedium,
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentColor,
        linearTrackColor: Color(0xFFE2E8F0),
      ),
    );
  }

  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: accentColor.withValues(alpha: 0.15),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
}
