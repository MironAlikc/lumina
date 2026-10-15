import 'package:equatable/equatable.dart';

/// Доменная сущность операции. Equatable нужен, чтобы состояние не
/// считалось «изменённым» при каждом пересоздании объектов из Hive.
class HistoryExpense extends Equatable {
  const HistoryExpense({
    required this.id,
    required this.date,
    required this.productName,
    required this.price,
    required this.isSynced,
    required this.category,
    required this.type,
    this.accountId,
    this.targetAccountId,
  });

  final String id;
  final DateTime date;
  final String productName;
  final double price;
  final bool isSynced;
  final String category;

  /// 'income', 'expense' или 'transfer'.
  final String type;
  final String? accountId;
  final String? targetAccountId;

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get isTransfer => type == 'transfer';

  HistoryExpense copyWith({
    String? id,
    DateTime? date,
    String? productName,
    double? price,
    bool? isSynced,
    String? category,
    String? type,
    String? accountId,
    String? targetAccountId,
  }) {
    return HistoryExpense(
      id: id ?? this.id,
      date: date ?? this.date,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      isSynced: isSynced ?? this.isSynced,
      category: category ?? this.category,
      type: type ?? this.type,
      accountId: accountId != null
          ? (accountId.isEmpty ? null : accountId)
          : this.accountId,
      targetAccountId: targetAccountId != null
          ? (targetAccountId.isEmpty ? null : targetAccountId)
          : this.targetAccountId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        date,
        productName,
        price,
        isSynced,
        category,
        type,
        accountId,
        targetAccountId,
      ];
}
