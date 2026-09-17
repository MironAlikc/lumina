import 'package:hive/hive.dart';

part 'recurring_expense_model.g.dart';

@HiveType(typeId: 3)
class RecurringExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String productName;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final String categoryId;

  @HiveField(4)
  final bool isIncome;

  @HiveField(5)
  final int dayOfMonth;

  @HiveField(6)
  final String typeName;

  @HiveField(7)
  final int lastProcessedMonth;

  @HiveField(8)
  final int lastProcessedYear;

  RecurringExpenseModel({
    required this.id,
    required this.productName,
    required this.price,
    required this.categoryId,
    required this.isIncome,
    required this.dayOfMonth,
    required this.typeName,
    required this.lastProcessedMonth,
    required this.lastProcessedYear,
  });

  RecurringExpenseModel copyWith({
    String? id,
    String? productName,
    double? price,
    String? categoryId,
    bool? isIncome,
    int? dayOfMonth,
    String? typeName,
    int? lastProcessedMonth,
    int? lastProcessedYear,
  }) {
    return RecurringExpenseModel(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      isIncome: isIncome ?? this.isIncome,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      typeName: typeName ?? this.typeName,
      lastProcessedMonth: lastProcessedMonth ?? this.lastProcessedMonth,
      lastProcessedYear: lastProcessedYear ?? this.lastProcessedYear,
    );
  }
}
