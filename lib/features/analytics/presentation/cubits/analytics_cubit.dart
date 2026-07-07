import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../history/data/models/history_expense_model.dart';
import 'analytics_state.dart';

class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit() : super(const AnalyticsState());

  void calculateAnalytics(List<HistoryExpenseModel> records) {
    try {
      // Сообщаем UI, что началась загрузка/расчет
      emit(state.copyWith(isLoading: true, errorMessage: null));

      final expenses = records
          .where((r) => r.type == TransactionType.expense)
          .toList();

      if (expenses.isEmpty) {
        emit(
          state.copyWith(
            categoryData: {},
            totalSpent: 0.0,
            insightMessage: 'Нет данных о расходах.',
            isLoading: false,
          ),
        );
        return;
      }

      final double total = expenses.fold(0.0, (sum, item) => sum + item.price);

      final Map<String, double> grouped = {};
      for (var exp in expenses) {
        grouped[exp.category] = (grouped[exp.category] ?? 0.0) + exp.price;
      }

      String insight =
          'Вы распределили бюджет на ${grouped.keys.length} категорий расходов.';
      final topEntry = grouped.entries.fold<MapEntry<String, double>?>(
        null,
        (max, e) => (max == null || e.value > max.value) ? e : max,
      );

      if (topEntry != null) {
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
      // В случае ошибки (например, проблемы с данными) обновляем состояние ошибкой
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Не удалось рассчитать аналитику.',
        ),
      );
    }
  }
}
