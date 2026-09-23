import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/features/analytics/data/models/analytics_daily_point.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_state.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';
import 'package:lumina/l10n/app_localizations.dart';

class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit() : super(AnalyticsState(selectedDate: DateTime.now()));

  void toggleChartMode(bool isLineMode) {
    if (state.isLineChartMode == isLineMode) return;
    emit(state.copyWith(isLineChartMode: isLineMode));
  }

  void changeDate(
    DateTime newDate,
    List<HistoryExpenseModel> records,
    List<CustomCategory> categories,
    AppLocalizations loc,
  ) {
    emit(state.copyWith(selectedDate: newDate));
    calculateAnalytics(records, categories, loc);
  }

  void calculateAnalytics(
    List<HistoryExpenseModel> records,
    List<CustomCategory> categories,
    AppLocalizations loc,
  ) {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final selected = state.selectedDate;
      final expenses = records.where((r) {
        return r.type == TransactionType.expense &&
            r.date.year == selected.year &&
            r.date.month == selected.month;
      }).toList();

      // Сумма расходов за предыдущий месяц — для бейджа сравнения.
      // DateTime(year, month - 1) сам корректно переносит январь в декабрь
      // предыдущего года — дополнительная арифметика не нужна.
      final prevMonthDate = DateTime(selected.year, selected.month - 1);
      final prevExpenses = records.where((r) {
        return r.type == TransactionType.expense &&
            r.date.year == prevMonthDate.year &&
            r.date.month == prevMonthDate.month;
      });
      final double? previousMonthTotal = prevExpenses.isEmpty
          ? null
          : prevExpenses.fold(0.0, (sum, e) => sum! + e.price);

      if (expenses.isEmpty) {
        emit(
          state.copyWith(
            slices: const [],
            dailyPoints: const [],
            monthExpenses: const [],
            totalSpent: 0,
            previousMonthTotal: previousMonthTotal,
            clearPreviousMonthTotal: previousMonthTotal == null,
            insightMessage: loc.insightNoData,
            isLoading: false,
          ),
        );
        return;
      }

      // 1. Расчёт категорий для круговой диаграммы
      final totals = <String, double>{};
      for (final exp in expenses) {
        final id = exp.categoryId.isEmpty ? 'unknown' : exp.categoryId;
        totals[id] = (totals[id] ?? 0) + exp.price;
      }

      final total = totals.values.fold(0.0, (sum, v) => sum + v);

      final slices = totals.entries.map((entry) {
        final category = categories.cast<CustomCategory?>().firstWhere(
          (c) => c!.id == entry.key,
          orElse: () => null,
        );
        return AnalyticsSlice(
          categoryId: entry.key,
          name:
              category?.localizedName(loc) ??
              (entry.key == 'unknown' ? loc.otherCategory : entry.key),
          amount: entry.value,
          colorHex: category?.colorHex ?? 0xFF94A3B8,
        );
      }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

      // 2. Расчёт динамики по дням для линейного графика
      final daysInMonth = DateTime(selected.year, selected.month + 1, 0).day;
      final dailyMap = <int, double>{};
      for (var i = 1; i <= daysInMonth; i++) {
        dailyMap[i] = 0.0;
      }
      for (final exp in expenses) {
        final day = exp.date.day;
        dailyMap[day] = (dailyMap[day] ?? 0.0) + exp.price;
      }
      final dailyPoints = dailyMap.entries
          .map((e) => AnalyticsDailyPoint(day: e.key, amount: e.value))
          .toList();

      final insight = slices.isEmpty
          ? loc.insightNoData
          : loc.insightTopSpend(
              slices.first.name,
              slices.first.percentOf(total).toStringAsFixed(0),
            );

      emit(
        state.copyWith(
          slices: slices,
          dailyPoints: dailyPoints,
          monthExpenses: expenses,
          totalSpent: total,
          previousMonthTotal: previousMonthTotal,
          clearPreviousMonthTotal: previousMonthTotal == null,
          insightMessage: insight,
          isLoading: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: loc.analyticsError));
    }
  }
}
