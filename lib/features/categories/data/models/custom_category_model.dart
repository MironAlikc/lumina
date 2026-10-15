import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lumina/l10n/app_localizations.dart';

part 'custom_category_model.g.dart';

@HiveType(typeId: 2)
class CustomCategory extends HiveObject {
  CustomCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorHex,
    required this.type,
  });

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

  static const typeExpense = 'expense';
  static const typeIncome = 'income';
  static const typeTransfer = 'transfer';
  static const transferId = 'cat_transfer';

  /// cat_income - устаревший id, оставлен для старых установок.
  static const _defaultIds = {
    'cat_food',
    'cat_transport',
    'cat_shopping',
    'cat_entertainment',
    'cat_housing',
    'cat_salary',
    'cat_income',
    transferId,
  };

  static const _icons = <String, IconData>{
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
    'transfer': Icons.swap_horiz_rounded,
    'category': Icons.category_rounded,
  };

  bool get isIncome => type == typeIncome;
  bool get isTransfer => type == typeTransfer;
  bool get isDefault => _defaultIds.contains(id);

  /// Альфа форсируется: значение вида 0x0D9488 иначе было бы прозрачным.
  Color get color => Color(0xFF000000 | (colorHex & 0xFFFFFF));

  IconData get icon => _icons[iconKey] ?? Icons.category_rounded;

  /// Стандартные категории показываются на языке интерфейса.
  /// Переименование стандартной категории пока не отображается.
  String localizedName(AppLocalizations loc) {
    return switch (id) {
      'cat_food' => loc.catFood,
      'cat_transport' => loc.catTransport,
      'cat_shopping' => loc.catShopping,
      'cat_entertainment' => loc.catEntertainment,
      'cat_housing' => loc.catHousing,
      'cat_salary' || 'cat_income' => loc.catSalary,
      transferId => loc.transfer,
      _ => name,
    };
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomCategory &&
          other.id == id &&
          other.name == name &&
          other.iconKey == iconKey &&
          other.colorHex == colorHex &&
          other.type == type;

  @override
  int get hashCode => Object.hash(id, name, iconKey, colorHex, type);

  static List<CustomCategory> defaults() => [
        CustomCategory(
          id: 'cat_food',
          name: 'Food',
          iconKey: 'food',
          colorHex: 0xFFFF9F43,
          type: typeExpense,
        ),
        CustomCategory(
          id: 'cat_transport',
          name: 'Transport',
          iconKey: 'transport',
          colorHex: 0xFF3B82F6,
          type: typeExpense,
        ),
        CustomCategory(
          id: 'cat_shopping',
          name: 'Shopping',
          iconKey: 'shopping',
          colorHex: 0xFFFF4757,
          type: typeExpense,
        ),
        CustomCategory(
          id: 'cat_entertainment',
          name: 'Entertainment',
          iconKey: 'entertainment',
          colorHex: 0xFF8B5CF6,
          type: typeExpense,
        ),
        CustomCategory(
          id: 'cat_housing',
          name: 'Housing',
          iconKey: 'home',
          colorHex: 0xFFEF4444,
          type: typeExpense,
        ),
        CustomCategory(
          id: 'cat_salary',
          name: 'Salary',
          iconKey: 'wallet',
          colorHex: 0xFF2ECC71,
          type: typeIncome,
        ),
        CustomCategory(
          id: transferId,
          name: 'Transfer',
          iconKey: 'transfer',
          colorHex: 0xFF0D9488,
          type: typeTransfer,
        ),
      ];
}
