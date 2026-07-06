import 'package:flutter/material.dart';

class LuminaTheme {
  // Тот самый благородный мятно-бирюзовый из твоих заметок
  static const Color accentColor = Color(0xFF00B4D8);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textColor = Color(0xFF0F172A);
  static const Color subTitleColor = Color(0xFF64748B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily:
          'SF Pro Display', // Используем нативный шрифт Apple для презентабельности

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

      // Стиль для кастомных текстовых полей (как на твоих скринах)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: Colors.black26, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),

      // Глобальный стиль для текста
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textColor, fontSize: 16),
        bodyMedium: TextStyle(color: subTitleColor, fontSize: 14),
      ),
    );
  }

  // Удобный хелпер для создания тех самых "парящих" теней вокруг карточек
  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: accentColor.withOpacity(0.01),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
}
