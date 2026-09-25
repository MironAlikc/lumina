import 'package:hive/hive.dart';
import 'package:lumina/features/transactions/domain/entities/history_expense.dart';

part 'history_expense_model.g.dart';

@HiveType(typeId: 0)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
  @HiveField(2)
  transfer,
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
  final String categoryId;
  @HiveField(6)
  final TransactionType type;
  @HiveField(7)
  final String? categoryName;
  @HiveField(8)
  final String? accountId;
  @HiveField(9)
  final String? targetAccountId;

  HistoryExpenseModel({
    required this.id,
    required this.date,
    required this.productName,
    required this.price,
    this.isSynced = false,
    required this.categoryId,
    this.type = TransactionType.expense,
    this.categoryName,
    this.accountId,
    this.targetAccountId,
  });

  bool get isIncome => type == TransactionType.income;
  bool get isTransfer => type == TransactionType.transfer;

  HistoryExpenseModel copyWith({
    String? id,
    DateTime? date,
    String? productName,
    double? price,
    bool? isSynced,
    String? categoryId,
    TransactionType? type,
    String? categoryName,
    String? accountId,
    String? targetAccountId,
  }) {
    return HistoryExpenseModel(
      id: id ?? this.id,
      date: date ?? this.date,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      isSynced: isSynced ?? this.isSynced,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      categoryName: categoryName ?? this.categoryName,
      accountId: accountId ?? this.accountId,
      targetAccountId: targetAccountId ?? this.targetAccountId,
    );
  }

  HistoryExpense toEntity() => HistoryExpense(
    id: id,
    date: date,
    productName: productName,
    price: price,
    category: categoryId,
    type: type.name,
    isSynced: isSynced,
  );

  factory HistoryExpenseModel.fromEntity(HistoryExpense entity) {
    return HistoryExpenseModel(
      id: entity.id,
      date: entity.date,
      productName: entity.productName,
      price: entity.price,
      categoryId: entity.category,
      categoryName: null,
      type: entity.type == 'income'
          ? TransactionType.income
          : entity.type == 'transfer'
          ? TransactionType.transfer
          : TransactionType.expense,
      isSynced: entity.isSynced,
    );
  }

  Map<String, dynamic> toSupabaseMap(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'product_name': productName,
      'price': price,
      'date': date.toIso8601String(),
      'category_id': categoryId,
      'category_name': categoryName ?? '',
      'type': type.name,
      'account_id': accountId,
      'target_account_id': targetAccountId,
    };
  }

  factory HistoryExpenseModel.fromSupabase(Map<String, dynamic> map) {
    TransactionType parsedType = TransactionType.expense;
    final rawType = map['type'] as String?;
    if (rawType == 'income') {
      parsedType = TransactionType.income;
    } else if (rawType == 'transfer') {
      parsedType = TransactionType.transfer;
    }

    return HistoryExpenseModel(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      price: (map['price'] as num).toDouble(),
      productName: (map['product_name'] as String?) ?? '',
      isSynced: true,
      categoryId: (map['category_id'] as String?) ?? 'cat_food',
      categoryName: map['category_name'] as String?,
      type: parsedType,
      accountId: map['account_id'] as String?,
      targetAccountId: map['target_account_id'] as String?,
    );
  }
}
