import 'package:hive/hive.dart';

part 'history_expense_model.g.dart';

@HiveType(typeId: 0)
class HistoryExpenseModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String productName;

  @HiveField(3)
  final double price;

  @HiveField(4)
  final bool isSynced;

  @HiveField(5)
  final String category;

  @HiveField(6)
  final String type;

  HistoryExpenseModel({
    required this.id,
    required this.date,
    required this.productName,
    required this.price,
    this.isSynced = false,
    this.category =
        'food', // Дефолтное значение на английском для сопоставления с Enum
    this.type = 'expense', // Дефолтное значение: 'expense' или 'income'
  });

  bool get isIncome => type == 'income';

  HistoryExpenseModel copyWith({
    String? id,
    DateTime? date,
    String? productName,
    double? price,
    bool? isSynced,
    String? category,
    String? type,
  }) {
    return HistoryExpenseModel(
      id: id ?? this.id,
      date: date ?? this.date,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      isSynced: isSynced ?? this.isSynced,
      category: category ?? this.category,
      type: type ?? this.type,
    );
  }

  factory HistoryExpenseModel.fromMap(Map<dynamic, dynamic> map) {
    return HistoryExpenseModel(
      id: map['id'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      productName: map['productName'] as String,
      price: (map['price'] as num).toDouble(),
      isSynced: (map['isSynced'] as bool?) ?? false,
      category: (map['category'] as String?) ?? 'food',
      type: (map['type'] as String?) ?? 'expense',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.millisecondsSinceEpoch,
    'productName': productName,
    'price': price,
    'isSynced': isSynced,
    'category': category,
    'type': type,
  };

  Map<String, dynamic> toSupabaseMap(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'product_name': productName,
      'price': price,
      'date': date.toIso8601String(),
      'category': category,
      'type': type,
    };
  }

  factory HistoryExpenseModel.fromSupabase(Map<String, dynamic> map) {
    return HistoryExpenseModel(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      productName: map['product_name'] as String,
      price: (map['price'] as num).toDouble(),
      isSynced: true,
      category: (map['category'] as String?) ?? 'food',
      type: (map['type'] as String?) ?? 'expense',
    );
  }
}
