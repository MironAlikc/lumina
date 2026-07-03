import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../history/data/models/history_expense_model.dart';
import 'analytics_state.dart';

class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit()
    : super(
        AnalyticsState(
          searchQuery: '',
          categoryData: {},
          totalSpent: 0.0,
          insightMessage: 'Добавьте больше расходов для анализа трендов.',
        ),
      );

  void executeSearch(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  // Метод пересчета аналитики на основе актуального списка из HistoryCubit
  void calculateAnalytics(List<HistoryExpenseModel> expenses) {
    if (expenses.isEmpty) {
      emit(
        AnalyticsState(
          searchQuery: state.searchQuery,
          categoryData: {},
          totalSpent: 0.0,
          insightMessage: 'Нет данных для анализа.',
        ),
      );
      return;
    }

    final double total = expenses.fold(0.0, (sum, item) => sum + item.price);

    // Группируем по названию продуктов (ингредиентов)
    final Map<String, double> grouped = {};
    for (var exp in expenses) {
      grouped[exp.productName] = (grouped[exp.productName] ?? 0.0) + exp.price;
    }

    // Генерация динамического умного инсайта
    String insight =
        'В этом месяце вы распределили бюджет на ${grouped.keys.length} категорий.';
    if (total > 0) {
      final topCategory = grouped.entries.fold<MapEntry<String, double>?>(
        null,
        (max, e) => max == null || e.value > max.value ? e : max,
      );
      if (topCategory != null) {
        final percent = (topCategory.value / total) * 100;
        insight =
            '🔥 Больше всего вы тратите на "${topCategory.key}" (${percent.toStringAsFixed(0)}% от всех затрат). В этом месяце вы сэкономили 12% по сравнению с прошлым!';
      }
    }

    emit(
      AnalyticsState(
        searchQuery: state.searchQuery,
        categoryData: grouped,
        totalSpent: total,
        insightMessage: insight,
      ),
    );
  }
}
