import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

// Указываем имя сгенерированного файла.
// После создания этого файла выполни в терминале:
// dart run build_runner build --delete-conflicting-outputs
part 'custom_category_model.g.dart';

@HiveType(
  typeId: 2,
) // Убедись, что typeId (2) свободен и не занят моделью HistoryExpenseModel
class CustomCategory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String iconKey; // Строковый ключ для иконки (например, 'food')

  @HiveField(3)
  final int colorHex; // Hex-код цвета (например, 0xFFFF9F43)

  @HiveField(4)
  final String type; // 'expense' или 'income'

  CustomCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorHex,
    required this.type,
  });

  // Удобный геттер для получения цвета в UI виджетах
  Color get color => Color(colorHex);

  // Геттер для маппинга сохраненной строки в реальный IconData
  IconData get icon {
    switch (iconKey) {
      case 'food':
        return Icons.fastfood_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.local_mall_rounded;
      case 'entertainment':
        return Icons.confirmation_number_rounded;
      case 'health':
        return Icons.medical_services_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'home':
        return Icons.home_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
