import 'package:flutter/material.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';

abstract final class LuminaTheme {
  // Алиасы оставлены, пока экраны не переведены на LuminaColors.
  // Новый код должен использовать LuminaColors напрямую.
  static const Color accentColor = LuminaColors.accent;
  static const Color primaryColor = LuminaColors.primary;
  static const Color accentDeepColor = LuminaColors.accentDeep;
  static const Color accentSoftColor = LuminaColors.accentSoft;
  static const Color accentMutedColor = LuminaColors.accentMuted;
  static const Color backgroundColor = LuminaColors.background;
  static const Color textColor = LuminaColors.textMain;
  static const Color subTitleColor = LuminaColors.textSecondary;
  static const Color titleColor = LuminaColors.textMain;
  static const Color errorColor = LuminaColors.error;
  static const Color errorDeepColor = LuminaColors.errorDeep;
  static const Color errorSoftColor = LuminaColors.errorSoft;

  /// Создаётся один раз, а не при каждой перестройке MaterialApp.
  static final ThemeData lightTheme = _build();

  static ThemeData _build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: LuminaColors.accent,
      brightness: Brightness.light,
    ).copyWith(
      primary: LuminaColors.accent,
      secondary: LuminaColors.accentDeep,
      error: LuminaColors.error,
      surface: LuminaColors.surface,
      onSurface: LuminaColors.textMain,
      surfaceTint: Colors.transparent,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    const radius = LuminaDimensions.borderRadiusMedium;
    final roundedShape = RoundedRectangleBorder(borderRadius: radius);

    return base.copyWith(
      scaffoldBackgroundColor: LuminaColors.background,
      // Текст по умолчанию тёмный: раньше bodyMedium был серым, и любой
      // Text без явного стиля выглядел блёклым.
      textTheme: base.textTheme.apply(
        bodyColor: LuminaColors.textMain,
        displayColor: LuminaColors.textMain,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: IconThemeData(color: LuminaColors.textMain, size: 20),
        titleTextStyle: TextStyle(
          color: LuminaColors.textMain,
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
        hintStyle: TextStyle(
          color: LuminaColors.textSecondary.withValues(alpha: 0.7),
          fontSize: 15,
        ),
        border: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: LuminaColors.accent, width: 1.6),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: LuminaColors.error, width: 1.2),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: LuminaColors.error, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LuminaColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 48),
          shape: roundedShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LuminaColors.accent,
          shape: roundedShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LuminaColors.accentDeep,
          shape: roundedShape,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: LuminaColors.textMain,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: LuminaColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: LuminaColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? LuminaColors.accent
              : null,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: LuminaColors.accent,
        linearTrackColor: LuminaColors.border,
      ),
    );
  }

  // static final: список создаётся один раз, а не при каждом build.
  static final List<BoxShadow> premiumShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: LuminaColors.accent.withValues(alpha: 0.15),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static final List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
}
