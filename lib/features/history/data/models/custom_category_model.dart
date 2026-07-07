import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'custom_category_model.g.dart';

@HiveType(typeId: 2)
class CustomCategory extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String iconKey;
  @HiveField(3)
  final int colorHex;
  @HiveField(4)
  final String type;

  CustomCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorHex,
    required this.type,
  });

  Color get color => Color(colorHex);

  IconData get icon {
    const iconMap = {
      'food': Icons.fastfood_rounded,
      'transport': Icons.directions_car_rounded,
      'shopping': Icons.local_mall_rounded,
      'entertainment': Icons.confirmation_number_rounded,
      'health': Icons.medical_services_rounded,
      'education': Icons.school_rounded,
      'home': Icons.home_rounded,
    };
    return iconMap[iconKey] ?? Icons.category_rounded;
  }
}
