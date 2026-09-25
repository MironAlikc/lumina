import 'package:equatable/equatable.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';

class CategorySpend extends Equatable {
  const CategorySpend({
    required this.categoryId,
    required this.amount,
    this.storedName,
  });

  final String categoryId;
  final double amount;
  final String? storedName;

  @override
  List<Object?> get props => [categoryId, amount, storedName];
}

class DailySpend extends Equatable {
  const DailySpend({required this.day, required this.amount});

  final int day;
  final double amount;

  @override
  List<Object?> get props => [day, amount];
}

class AnalyticsReport extends Equatable {
  const AnalyticsReport({
    required this.year,
    required this.month,
    required this.totalSpent,
    required this.previousMonthTotal,
    required this.byCategory,
    required this.daily,
    required this.monthExpenses,
  });

  final int year;
  final int month;
  final double totalSpent;
  final double previousMonthTotal;
  final List<CategorySpend> byCategory;
  final List<DailySpend> daily;
  final List<HistoryExpenseModel> monthExpenses;

  @override
  List<Object?> get props => [
    year,
    month,
    totalSpent,
    previousMonthTotal,
    byCategory,
    daily,
    monthExpenses,
  ];
}
