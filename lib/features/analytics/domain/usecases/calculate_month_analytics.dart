import 'package:lumina/features/analytics/domain/entities/analytics_report.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';

class CalculateMonthAnalytics {
  const CalculateMonthAnalytics();

  static const _unknownKey = 'unknown';

  /// Округление до копеек, чтобы не копились ошибки double.
  static double _r2(double v) => (v * 100).round() / 100;

  AnalyticsReport call({
    required List<HistoryExpenseModel> records,
    required DateTime selected,
  }) {
    final month = selected.month;
    final year = selected.year;
    final prev = DateTime(year, month - 1);

    final monthExpenses = <HistoryExpenseModel>[];
    var previousTotal = 0.0;

    // Один проход по данным. Переводы и доходы в расходы не попадают.
    for (final e in records) {
      if (!_isExpense(e)) continue;
      if (e.date.year == year && e.date.month == month) {
        monthExpenses.add(e);
      } else if (e.date.year == prev.year && e.date.month == prev.month) {
        previousTotal += e.price;
      }
    }

    final totals = <String, double>{};
    final names = <String, String?>{};
    for (final e in monthExpenses) {
      final key = e.categoryId.isEmpty ? _unknownKey : e.categoryId;
      totals[key] = (totals[key] ?? 0) + e.price;
      names[key] ??= e.categoryName;
    }

    final byCategory = [
      for (final entry in totals.entries)
        CategorySpend(
          categoryId: entry.key,
          amount: _r2(entry.value),
          storedName: names[entry.key],
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final perDay = List<double>.filled(daysInMonth, 0);
    for (final e in monthExpenses) {
      final day = e.date.day;
      if (day >= 1 && day <= daysInMonth) perDay[day - 1] += e.price;
    }

    return AnalyticsReport(
      year: year,
      month: month,
      totalSpent: _r2(monthExpenses.fold<double>(0, (s, e) => s + e.price)),
      previousMonthTotal: _r2(previousTotal),
      byCategory: byCategory,
      daily: [
        for (var i = 0; i < daysInMonth; i++)
          DailySpend(day: i + 1, amount: _r2(perDay[i])),
      ],
      monthExpenses: monthExpenses,
    );
  }

  bool _isExpense(HistoryExpenseModel e) => e.type == TransactionType.expense;
}
