import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/history_expense_model.dart';
import '../../data/repositories/history_repository.dart';
import 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  final HistoryRepository _repository;

  HistoryCubit(this._repository) : super(HistoryState()) {
    loadRecords();
  }

  void updateBudgetLimit(double newLimit) {
    _calculateAndEmit(
      state.allRecords,
      state.activeFilter,
      state.dateFilter,
      currentLimit: newLimit,
    );
  }

  void loadRecords() {
    emit(state.copyWith(isLoading: true));
    _calculateAndEmit(
      _repository.getAllExpenses(),
      state.activeFilter,
      state.dateFilter,
      currentLimit: state.budgetLimit,
    );
    _syncOfflineRecords();
  }

  void changeFilter(HistoryFilterType typeFilter) {
    _calculateAndEmit(
      state.allRecords,
      typeFilter,
      state.dateFilter,
      currentLimit: state.budgetLimit,
    );
  }

  void changeDateFilter(DateFilterType dateFilter) {
    _calculateAndEmit(
      state.allRecords,
      state.activeFilter,
      dateFilter,
      currentLimit: state.budgetLimit,
    );
  }

  void _calculateAndEmit(
    List<HistoryExpenseModel> records,
    HistoryFilterType typeFilter,
    DateFilterType dateFilter, {
    required double currentLimit,
  }) {
    final now = DateTime.now();

    // 1. Сортировка: новые записи сверху
    final sortedRecords = List<HistoryExpenseModel>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    // 2. Фильтр по дате
    final dateFiltered = sortedRecords.where((r) {
      return switch (dateFilter) {
        DateFilterType.today => _isSameDay(r.date, now),
        DateFilterType.yesterday => _isSameDay(
          r.date,
          now.subtract(const Duration(days: 1)),
        ),
        DateFilterType.thisWeek => r.date.isAfter(
          now.subtract(Duration(days: now.weekday - 1)),
        ),
        DateFilterType.all => true,
      };
    }).toList();

    // 3. Фильтр по типу (используем enum TransactionType из модели)
    final finalFiltered = switch (typeFilter) {
      HistoryFilterType.expense =>
        dateFiltered.where((e) => e.type == TransactionType.expense).toList(),
      HistoryFilterType.income =>
        dateFiltered.where((e) => e.type == TransactionType.income).toList(),
      HistoryFilterType.all => dateFiltered,
    };

    // 4. Аналитика: считаем всё за один проход по списку
    double incomes = 0;
    double expenses = 0;
    for (var r in sortedRecords) {
      if (r.type == TransactionType.income) {
        incomes += r.price;
      } else {
        expenses += r.price;
      }
    }

    emit(
      state.copyWith(
        allRecords: sortedRecords,
        filteredRecords: finalFiltered,
        totalBalance: incomes - expenses,
        totalIncomes: incomes,
        totalExpenses: expenses,
        activeFilter: typeFilter,
        dateFilter: dateFilter,
        budgetLimit: currentLimit,
        isLoading: false,
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> addRecord(HistoryExpenseModel record) async {
    await _repository.saveExpense(record);
    _refreshState();
    try {
      await _repository.syncWithCloud(record);
      _refreshState();
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  Future<void> removeRecord(String id) async {
    await _repository.deleteExpense(id);
    _refreshState();
    try {
      await _repository.deleteFromCloud(id);
    } catch (_) {}
  }

  void _refreshState() {
    _calculateAndEmit(
      _repository.getAllExpenses(),
      state.activeFilter,
      state.dateFilter,
      currentLimit: state.budgetLimit,
    );
  }

  Future<void> _syncOfflineRecords() async {
    final unsynced = _repository
        .getAllExpenses()
        .where((r) => !r.isSynced)
        .toList();
    for (var record in unsynced) {
      await _repository.syncWithCloud(record);
    }
    _refreshState();
  }
}
