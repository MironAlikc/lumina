import '../../data/models/history_expense_model.dart';

class HistoryState {
  final List<HistoryExpenseModel> allExpenses;
  final List<HistoryExpenseModel> expenses;
  final List<String> dateFilters;
  final String selectedFilter;
  final double totalSpent;
  final double budgetLimit; // ДОБАВЛЕНО: Лимит бюджета
  final List<String> autocompleteSuggestions;
  final double suggestedPrice;

  HistoryState({
    required this.allExpenses,
    required this.expenses,
    required this.dateFilters,
    required this.selectedFilter,
    required this.totalSpent,
    required this.budgetLimit, // ДОБАВЛЕНО
    required this.autocompleteSuggestions,
    required this.suggestedPrice,
  });

  // Вычисляемое свойство: процент заполнения бюджета от 0.0 до 1.0
  double get budgetProgress {
    if (budgetLimit <= 0) return 0.0;
    final progress = totalSpent / budgetLimit;
    return progress > 1.0 ? 1.0 : progress;
  }

  HistoryState copyWith({
    List<HistoryExpenseModel>? allExpenses,
    List<HistoryExpenseModel>? expenses,
    List<String>? dateFilters,
    String? selectedFilter,
    double? totalSpent,
    double? budgetLimit, // ДОБАВЛЕНО
    List<String>? autocompleteSuggestions,
    double? suggestedPrice,
  }) {
    return HistoryState(
      allExpenses: allExpenses ?? this.allExpenses,
      expenses: expenses ?? this.expenses,
      dateFilters: dateFilters ?? this.dateFilters,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      totalSpent: totalSpent ?? this.totalSpent,
      budgetLimit: budgetLimit ?? this.budgetLimit, // ДОБАВЛЕНО
      autocompleteSuggestions:
          autocompleteSuggestions ?? this.autocompleteSuggestions,
      suggestedPrice: suggestedPrice ?? this.suggestedPrice,
    );
  }
}
