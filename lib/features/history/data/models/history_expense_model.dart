import 'package:hive/hive.dart';
import '../../domain/entities/history_expense.dart';

part 'history_expense_model.g.dart';

// 1. Строгий тип для избежания ошибок в строках
@HiveType(typeId: 0)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

@HiveType(typeId: 1)
class HistoryExpenseModel extends HiveObject {
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
  final TransactionType type;

  HistoryExpenseModel({
    required this.id,
    required this.date,
    required this.productName,
    required this.price,
    this.isSynced = false,
    this.category = 'food',
    this.type = TransactionType.expense,
  });

  bool get isIncome => type == TransactionType.income;

  HistoryExpenseModel copyWith({
    String? id,
    DateTime? date,
    String? productName,
    double? price,
    bool? isSynced,
    String? category,
    TransactionType? type,
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

  HistoryExpense toEntity() => HistoryExpense(
    id: id,
    date: date,
    productName: productName,
    price: price,
    category: category,
    type: type.name, // Превращаем enum в строку для Entity
    isSynced: isSynced,
  );

  factory HistoryExpenseModel.fromEntity(HistoryExpense entity) =>
      HistoryExpenseModel(
        id: entity.id,
        date: entity.date,
        productName: entity.productName,
        price: entity.price,
        category: entity.category,
        type: entity.type == 'income'
            ? TransactionType.income
            : TransactionType.expense,
        isSynced: entity.isSynced,
      );

  Map<String, dynamic> toSupabaseMap(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'product_name': productName,
      'price': price,
      'date': date.toIso8601String(),
      'category': category,
      'type': type.name,
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
      type: (map['type'] as String?) == 'income'
          ? TransactionType.income
          : TransactionType.expense,
    );
  }
}
