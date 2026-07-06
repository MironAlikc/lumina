import 'package:flutter/foundation.dart';
import '../../data/models/history_expense_model.dart';

enum HistoryFilterType { all, expense, income }

enum DateFilterType { all, today, yesterday, thisWeek }

class HistoryState {
  final List<HistoryExpenseModel> allRecords;
  final List<HistoryExpenseModel> filteredRecords;
  final double totalBalance;
  final double totalIncomes;
  final double totalExpenses;
  final HistoryFilterType activeFilter;
  final DateFilterType dateFilter;
  final double budgetLimit;
  final bool isLoading;

  HistoryState({
    this.allRecords = const [],
    this.filteredRecords = const [],
    this.totalBalance = 0.0,
    this.totalIncomes = 0.0,
    this.totalExpenses = 0.0,
    this.activeFilter = HistoryFilterType.all,
    this.dateFilter = DateFilterType.all,
    this.budgetLimit = 30000.0,
    this.isLoading = false,
  });

  HistoryState copyWith({
    List<HistoryExpenseModel>? allRecords,
    List<HistoryExpenseModel>? filteredRecords,
    double? totalBalance,
    double? totalIncomes,
    double? totalExpenses,
    HistoryFilterType? activeFilter,
    DateFilterType? dateFilter,
    double? budgetLimit,
    bool? isLoading,
  }) {
    return HistoryState(
      allRecords: allRecords ?? this.allRecords,
      filteredRecords: filteredRecords ?? this.filteredRecords,
      totalBalance: totalBalance ?? this.totalBalance,
      totalIncomes: totalIncomes ?? this.totalIncomes,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      activeFilter: activeFilter ?? this.activeFilter,
      dateFilter: dateFilter ?? this.dateFilter,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      isLoading: isLoading ?? this.isLoading,
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
          budgetLimit == other.budgetLimit &&
          isLoading == other.isLoading;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(allRecords),
    Object.hashAll(filteredRecords),
    totalBalance,
    totalIncomes,
    totalExpenses,
    activeFilter,
    dateFilter,
    budgetLimit,
    isLoading,
  );
}
