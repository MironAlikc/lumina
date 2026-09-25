import 'package:hive/hive.dart';

part 'goal_expense_model.g.dart';

@HiveType(typeId: 4)
class GoalExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double targetAmount;

  @HiveField(3)
  final double currentAmount;

  @HiveField(4)
  final String icon;

  @HiveField(5)
  final int colorValue;

  GoalExpenseModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.icon,
    required this.colorValue,
  });

  GoalExpenseModel copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    String? icon,
    int? colorValue,
  }) {
    return GoalExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
