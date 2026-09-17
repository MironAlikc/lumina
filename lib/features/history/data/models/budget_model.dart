import 'package:hive/hive.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 5)
class BudgetModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String categoryId;

  @HiveField(2)
  final double limitAmount;

  @HiveField(3)
  final int month;

  @HiveField(4)
  final int year;

  BudgetModel({
    required this.id,
    required this.categoryId,
    required this.limitAmount,
    required this.month,
    required this.year,
  });

  BudgetModel copyWith({
    String? id,
    String? categoryId,
    double? limitAmount,
    int? month,
    int? year,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      limitAmount: limitAmount ?? this.limitAmount,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }
}
