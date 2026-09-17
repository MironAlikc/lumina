import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../history/data/models/history_expense_model.dart';
import '../../../history/data/models/custom_category_model.dart';
import 'analytics_state.dart';

class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit() : super(AnalyticsState(selectedDate: DateTime.now()));

  void changeDate(
    DateTime newDate,
    List<HistoryExpenseModel> records,
    List<CustomCategory> categories,
  ) {
    emit(state.copyWith(selectedDate: newDate));
    calculateAnalytics(records, categories);
  }

  void calculateAnalytics(
    List<HistoryExpenseModel> records,
    List<CustomCategory> categories,
  ) {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));

      final expenses = records.where((r) {
        if (r.type != TransactionType.expense) return false;
        return r.date.year == state.selectedDate.year &&
            r.date.month == state.selectedDate.month;
      }).toList();

      if (expenses.isEmpty) {
        emit(
          state.copyWith(
            categoryData: {},
            totalSpent: 0.0,
            insightMessage: 'Нет данных о расходах за этот месяц.',
            isLoading: false,
          ),
        );
        return;
      }

      final double total = expenses.fold(0.0, (sum, item) => sum + item.price);
      final Map<String, double> grouped = {};

      for (var exp in expenses) {
        final category = categories.firstWhere(
          (c) => c.id == exp.categoryId,
          orElse: () => CustomCategory(
            id: 'unknown',
            name: 'Другое',
            iconKey: 'category',
            colorHex: 0xFF999999,
            type: 'expense',
          ),
        );

        grouped[category.name] = (grouped[category.name] ?? 0.0) + exp.price;
      }

      String insight =
          'Вы распределили бюджет на ${grouped.keys.length} категорий расходов.';

      final topEntry = grouped.entries.fold<MapEntry<String, double>?>(
        null,
        (max, e) => (max == null || e.value > max.value) ? e : max,
      );

      if (topEntry != null && total > 0) {
        final percent = (topEntry.value / total) * 100;
        insight =
            '🔥 Больше всего тратите на "${topEntry.key}" (${percent.toStringAsFixed(0)}% от расходов).';
      }

      emit(
        state.copyWith(
          categoryData: grouped,
          totalSpent: total,
          insightMessage: insight,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Не удалось рассчитать аналитику.',
        ),
      );
    }
  }
}
