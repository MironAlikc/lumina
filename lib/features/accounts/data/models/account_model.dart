import 'package:hive/hive.dart';

part 'account_model.g.dart';

@HiveType(typeId: 6)
class AccountModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double balance;

  @HiveField(3)
  final String
      iconCode; // Строковое представление иконки (например, 'credit_card')

  @HiveField(4)
  final int colorValue; // Цвет счета в HEX

  @HiveField(5)
  final bool isSynced;

  AccountModel({
    required this.id,
    required this.name,
    required this.balance,
    required this.iconCode,
    required this.colorValue,
    this.isSynced = false,
  });

  AccountModel copyWith({
    String? id,
    String? name,
    double? balance,
    String? iconCode,
    int? colorValue,
    bool? isSynced,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toSupabaseMap(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'balance': balance,
      'icon_code': iconCode,
      'color_value': colorValue,
    };
  }

  factory AccountModel.fromSupabase(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] as String,
      name: map['name'] as String,
      balance: (map['balance'] as num).toDouble(),
      iconCode: (map['icon_code'] as String?) ?? 'wallet',
      colorValue: ((map['color_value'] as num?) ?? 0xFF2E7D32).toInt(),
      isSynced: true,
    );
  }
}
