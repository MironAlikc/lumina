import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/features/analytics/data/models/analytics_daily_point.dart';
import 'package:lumina/features/analytics/domain/usecases/calculate_month_analytics.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_state.dart';
import 'package:lumina/features/analytics/presentation/mappers/category_display_mapper.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';
import 'package:lumina/l10n/app_localizations.dart';

class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit({
    required CalculateMonthAnalytics calculateMonthAnalytics,
    CategoryDisplayMapper categoryDisplayMapper = const CategoryDisplayMapper(),
  }) : _calculate = calculateMonthAnalytics,
       _mapper = categoryDisplayMapper,
       super(AnalyticsState.initial());

  final CalculateMonthAnalytics _calculate;
  final CategoryDisplayMapper _mapper;

  void toggleChartMode(bool isLine) {
    emit(state.copyWith(isLineChartMode: isLine));
  }

  void calculateAnalytics(
    List<HistoryExpenseModel> records,
    List<CustomCategory> categories,
    AppLocalizations loc,
  ) {
    _run(records, categories, loc, state.selectedDate);
  }

  void changeDate(
    DateTime date,
    List<HistoryExpenseModel> records,
    List<CustomCategory> categories,
    AppLocalizations loc,
  ) {
    _run(records, categories, loc, DateTime(date.year, date.month));
  }

  void _run(
    List<HistoryExpenseModel> records,
    List<CustomCategory> categories,
    AppLocalizations loc,
    DateTime selected,
  ) {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final report = _calculate(records: records, selected: selected);

      final slices = report.byCategory.map((item) {
        final display = _mapper.resolve(
          categoryId: item.categoryId,
          storedName: item.storedName,
          categories: categories,
          loc: loc,
        );
        return AnalyticsSlice(
          categoryId: item.categoryId,
          name: display.name,
          amount: item.amount,
          colorHex: display.colorHex,
        );
      }).toList();

      final insight = slices.isEmpty
          ? ''
          : _topInsight(
              loc,
              slices.first.name,
              slices.first.percentOf(report.totalSpent).toStringAsFixed(0),
            );

      emit(
        state.copyWith(
          selectedDate: DateTime(report.year, report.month),
          isLoading: false,
          clearError: true,
          insightMessage: insight,
          totalSpent: report.totalSpent,
          previousMonthTotal: report.previousMonthTotal,
          slices: slices,
          dailyPoints: [
            for (final d in report.daily)
              AnalyticsDailyPoint(day: d.day, amount: d.amount),
          ],
          monthExpenses: report.monthExpenses,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  String _topInsight(AppLocalizations loc, String name, String percent) {
    final code = loc.localeName;
    if (code.startsWith('uk')) {
      return '🔥 Найбільше витрачаєте на «$name» ($percent% від витрат).';
    }
    if (code.startsWith('en')) {
      return '🔥 You spend the most on “$name” ($percent% of expenses).';
    }
    return '🔥 Больше всего тратите на «$name» ($percent% от расходов).';
  }
}
