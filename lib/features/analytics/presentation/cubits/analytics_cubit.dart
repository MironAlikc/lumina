import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_state.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';
import 'package:lumina/l10n/app_localizations.dart';

class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit() : super(AnalyticsState(selectedDate: DateTime.now()));

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

      if (expenses.isEmpty) {
        emit(
          state.copyWith(
            slices: const [],
            totalSpent: 0,
            insightMessage: loc.insightNoData,
            isLoading: false,
          ),
        );
        return;
      }

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

      final insight = slices.length == 1
          ? loc.insightTopSpend(
              slices.first.name,
              slices.first.percentOf(total).toStringAsFixed(0),
            )
          : loc.insightTopSpend(
              slices.first.name,
              slices.first.percentOf(total).toStringAsFixed(0),
            );

      emit(
        state.copyWith(
          slices: slices,
          totalSpent: total,
          insightMessage: insight,
          isLoading: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: loc.analyticsError));
    }
  }
}
