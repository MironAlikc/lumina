import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:lumina/features/transactions/domain/entities/history_expense.dart';

// ==========================================
// STATE
// ==========================================

enum HistoryFilterType { all, expense, income }

enum DateFilterType { all, today, yesterday, thisWeek }

enum HistoryViewMode { list, table }

@immutable
class HistoryState extends Equatable {
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
  List<Object?> get props => [
    allRecords,
    filteredRecords,
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
  ];
}
