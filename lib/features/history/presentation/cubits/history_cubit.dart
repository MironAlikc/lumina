import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/history_expense_model.dart';
import '../../data/repositories/history_repository.dart';
import 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  final HistoryRepository repository;

  HistoryCubit(this.repository)
    : super(
        HistoryState(
          allExpenses: [],
          expenses: [],
          dateFilters: ['All'],
          selectedFilter: 'All',
          totalSpent: 0.0,
          budgetLimit: 10000.0, // ДОБАВЛЕНО: Лимит по умолчанию 10 000 ₴
          autocompleteSuggestions: [],
          suggestedPrice: 0.0,
        ),
      ) {
    refreshData(locale: 'uk');
  }

  Future<void> deleteExpense(String id, String locale) async {
    await repository.deleteExpense(id);
    refreshData(locale: locale);
  }

  // Метод изменения лимита бюджета
  void updateBudgetLimit(double newLimit) {
    emit(state.copyWith(budgetLimit: newLimit));
  }

  void refreshData({required String locale}) {
    final list = repository.loadAllExpenses();
    final currentFilter = state.selectedFilter;

    final List<String> availableFilters = ['All'];
    availableFilters.addAll(
      list
          .map((e) => DateFormat('MMMM yyyy', locale).format(e.date))
          .toSet()
          .toList(),
    );

    if (currentFilter == 'All') {
      final total = list.fold<double>(0.0, (sum, item) => sum + item.price);
      emit(
        HistoryState(
          allExpenses: list,
          expenses: list,
          dateFilters: availableFilters,
          selectedFilter: 'All',
          totalSpent: total,
          budgetLimit: state.budgetLimit, // СОХРАНЯЕМ
          autocompleteSuggestions: [],
          suggestedPrice: 0.0,
        ),
      );
    } else {
      final filtered = list.where((e) {
        final key = DateFormat('MMMM yyyy', locale).format(e.date);
        return key == currentFilter;
      }).toList();

      final total = filtered.fold<double>(0.0, (sum, item) => sum + item.price);
      emit(
        HistoryState(
          allExpenses: list,
          expenses: filtered,
          dateFilters: availableFilters,
          selectedFilter: currentFilter,
          totalSpent: total,
          budgetLimit: state.budgetLimit, // СОХРАНЯЕМ
          autocompleteSuggestions: [],
          suggestedPrice: 0.0,
        ),
      );
    }
  }

  void changeFilter(String month, String locale) {
    if (month == 'All') {
      final total = state.allExpenses.fold<double>(
        0.0,
        (sum, item) => sum + item.price,
      );
      emit(
        state.copyWith(
          expenses: state.allExpenses,
          selectedFilter: 'All',
          totalSpent: total,
        ),
      );
      return;
    }

    final filtered = state.allExpenses.where((e) {
      final key = DateFormat('MMMM yyyy', locale).format(e.date);
      return key == month;
    }).toList();

    final total = filtered.fold<double>(0.0, (sum, item) => sum + item.price);
    emit(
      state.copyWith(
        expenses: filtered,
        selectedFilter: month,
        totalSpent: total,
      ),
    );
  }

  void searchAutocomplete(String query) {
    if (query.isEmpty) {
      emit(state.copyWith(autocompleteSuggestions: [], suggestedPrice: 0.0));
      return;
    }
    final matches = state.allExpenses
        .where((e) => e.productName.toLowerCase().contains(query.toLowerCase()))
        .map((e) => e.productName)
        .toSet()
        .toList();

    double pastPrice = 0.0;
    try {
      pastPrice = state.allExpenses
          .firstWhere(
            (e) => e.productName.toLowerCase() == query.toLowerCase().trim(),
          )
          .price;
    } catch (_) {}

    emit(
      state.copyWith(
        autocompleteSuggestions: matches,
        suggestedPrice: pastPrice,
      ),
    );
  }

  Future<void> addRecord(String name, double price, String locale) async {
    final newItem = HistoryExpenseModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: DateTime.now(),
      productName: name,
      price: price,
    );
    await repository.saveNewExpense(newItem);
    refreshData(locale: locale);
  }
}
