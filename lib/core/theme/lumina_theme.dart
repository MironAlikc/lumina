import 'package:flutter/material.dart';

class LuminaTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      fontFamily: 'SF Pro Display',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6),
        primary: const Color(0xFF3B82F6),
        surface: Colors.white,
      ),
      useMaterial3: true,
    );
  }
}
