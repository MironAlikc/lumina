import 'package:flutter/foundation.dart';
import '../../domain/entities/history_expense.dart';

enum HistoryFilterType { all, expense, income }

enum DateFilterType { all, today, yesterday, thisWeek }

enum HistoryViewMode { list, table }

class HistoryState {
  final List<HistoryExpense> allRecords;
  final List<HistoryExpense> filteredRecords;
  final double totalBalance;
  final double totalIncomes;
  final double totalExpenses;
  final HistoryFilterType activeFilter;
  final DateFilterType dateFilter;
  final String? selectedCategoryKey;
  final int selectedMonth;
  final int selectedYear;
  final double budgetLimit;
  final bool isLoading;
  final HistoryViewMode viewMode;

  HistoryState({
    this.allRecords = const [],
    this.filteredRecords = const [],
    this.totalBalance = 0.0,
    this.totalIncomes = 0.0,
    this.totalExpenses = 0.0,
    this.activeFilter = HistoryFilterType.all,
    this.dateFilter = DateFilterType.all,
    this.selectedCategoryKey,
    int? selectedMonth,
    int? selectedYear,
    this.budgetLimit = 0.0,
    this.isLoading = false,
    this.viewMode = HistoryViewMode.list,
  }) : selectedMonth = selectedMonth ?? DateTime.now().month,
       selectedYear = selectedYear ?? DateTime.now().year;

  HistoryState copyWith({
    List<HistoryExpense>? allRecords,
    List<HistoryExpense>? filteredRecords,
    double? totalBalance,
    double? totalIncomes,
    double? totalExpenses,
    HistoryFilterType? activeFilter,
    DateFilterType? dateFilter,
    String? selectedCategoryKey,
    bool clearCategory = false,
    int? selectedMonth,
    int? selectedYear,
    double? budgetLimit,
    bool? isLoading,
    HistoryViewMode? viewMode,
  }) {
    return HistoryState(
      allRecords: allRecords ?? this.allRecords,
      filteredRecords: filteredRecords ?? this.filteredRecords,
      totalBalance: totalBalance ?? this.totalBalance,
      totalIncomes: totalIncomes ?? this.totalIncomes,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      activeFilter: activeFilter ?? this.activeFilter,
      dateFilter: dateFilter ?? this.dateFilter,
      selectedCategoryKey: clearCategory
          ? null
          : (selectedCategoryKey ?? this.selectedCategoryKey),
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      isLoading: isLoading ?? this.isLoading,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryState &&
          listEquals(allRecords, other.allRecords) &&
          listEquals(filteredRecords, other.filteredRecords) &&
          totalBalance == other.totalBalance &&
          totalIncomes == other.totalIncomes &&
          totalExpenses == other.totalExpenses &&
          activeFilter == other.activeFilter &&
          dateFilter == other.dateFilter &&
          selectedCategoryKey == other.selectedCategoryKey &&
          selectedMonth == other.selectedMonth &&
          selectedYear == other.selectedYear &&
          budgetLimit == other.budgetLimit &&
          isLoading == other.isLoading &&
          viewMode == other.viewMode;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(allRecords),
    Object.hashAll(filteredRecords),
    totalBalance,
    totalIncomes,
    totalExpenses,
    activeFilter,
    dateFilter,
    selectedCategoryKey,
    selectedMonth,
    selectedYear,
    budgetLimit,
    isLoading,
    viewMode,
  );
}
