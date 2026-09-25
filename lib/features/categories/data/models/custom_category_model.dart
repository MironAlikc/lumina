import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lumina/l10n/app_localizations.dart';

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

  bool get isIncome => type == 'income';
  bool get isDefault => _localizedIds.contains(id);

  Color get color => Color(colorHex);

  String localizedName(AppLocalizations loc) {
    return switch (id) {
      'cat_food' => loc.catFood,
      'cat_transport' => loc.catTransport,
      'cat_shopping' => loc.catShopping,
      'cat_entertainment' => loc.catEntertainment,
      'cat_housing' => loc.catHousing,
      'cat_salary' || 'cat_income' => loc.catSalary,
      _ => name,
    };
  }

  IconData get icon {
    const iconMap = {
      'food': Icons.fastfood_rounded,
      'transport': Icons.directions_car_rounded,
      'shopping': Icons.local_mall_rounded,
      'entertainment': Icons.confirmation_number_rounded,
      'health': Icons.medical_services_rounded,
      'education': Icons.school_rounded,
      'home': Icons.home_rounded,
      'housing': Icons.home_rounded,
      'wallet': Icons.account_balance_wallet_rounded,
      'salary': Icons.account_balance_wallet_rounded,
      'category': Icons.category_rounded,
    };
    return iconMap[iconKey] ?? Icons.category_rounded;
  }

  CustomCategory copyWith({
    String? id,
    String? name,
    String? iconKey,
    int? colorHex,
    String? type,
  }) {
    return CustomCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
      type: type ?? this.type,
    );
  }

  static const _localizedIds = {
    'cat_food',
    'cat_transport',
    'cat_shopping',
    'cat_entertainment',
    'cat_housing',
    'cat_salary',
    'cat_income',
  };

  static List<CustomCategory> defaults() => [
    CustomCategory(
      id: 'cat_food',
      name: 'Food',
      iconKey: 'food',
      colorHex: 0xFFFF9F43,
      type: 'expense',
    ),
    CustomCategory(
      id: 'cat_transport',
      name: 'Transport',
      iconKey: 'transport',
      colorHex: 0xFF3B82F6,
      type: 'expense',
    ),
    CustomCategory(
      id: 'cat_shopping',
      name: 'Shopping',
      iconKey: 'shopping',
      colorHex: 0xFFFF4757,
      type: 'expense',
    ),
    CustomCategory(
      id: 'cat_entertainment',
      name: 'Entertainment',
      iconKey: 'entertainment',
      colorHex: 0xFF8B5CF6,
      type: 'expense',
    ),
    CustomCategory(
      id: 'cat_housing',
      name: 'Housing',
      iconKey: 'home',
      colorHex: 0xFFEF4444,
      type: 'expense',
    ),
    CustomCategory(
      id: 'cat_salary',
      name: 'Salary',
      iconKey: 'wallet',
      colorHex: 0xFF2ECC71,
      type: 'income',
    ),
  ];
}
