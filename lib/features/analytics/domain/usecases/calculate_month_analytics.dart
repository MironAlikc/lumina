import 'package:lumina/features/analytics/domain/entities/analytics_report.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';

class CalculateMonthAnalytics {
  const CalculateMonthAnalytics();

  AnalyticsReport call({
    required List<HistoryExpenseModel> records,
    required DateTime selected,
  }) {
    final month = selected.month;
    final year = selected.year;

    final monthExpenses = records.where((e) {
      return _isExpense(e) && e.date.month == month && e.date.year == year;
    }).toList();

    final totals = <String, double>{};
    final names = <String, String?>{};
    for (final e in monthExpenses) {
      final key = e.categoryId.isEmpty ? 'unknown' : e.categoryId;
      totals[key] = (totals[key] ?? 0) + e.price;
      names[key] ??= e.categoryName;
    }

    final byCategory =
        totals.entries
            .map(
              (e) => CategorySpend(
                categoryId: e.key,
                amount: e.value,
                storedName: names[e.key],
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    final totalSpent = monthExpenses.fold<double>(0, (s, e) => s + e.price);

    final prev = DateTime(year, month - 1);
    final previousMonthTotal = records
        .where((e) {
          return _isExpense(e) &&
              e.date.month == prev.month &&
              e.date.year == prev.year;
        })
        .fold<double>(0, (s, e) => s + e.price);

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final perDay = List<double>.filled(daysInMonth, 0);
    for (final e in monthExpenses) {
      final day = e.date.day;
      if (day >= 1 && day <= daysInMonth) {
        perDay[day - 1] += e.price;
      }
    }

    return AnalyticsReport(
      year: year,
      month: month,
      totalSpent: totalSpent,
      previousMonthTotal: previousMonthTotal,
      byCategory: byCategory,
      daily: [
        for (var i = 0; i < daysInMonth; i++)
          DailySpend(day: i + 1, amount: perDay[i]),
      ],
      monthExpenses: monthExpenses,
    );
  }

  bool _isExpense(HistoryExpenseModel e) => e.type == TransactionType.expense;
}
