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
    // Вызываем _calculateAndEmit, чтобы пересчитать данные с новым лимитом
    _calculateAndEmit(
      state.allRecords,
      state.activeFilter,
      state.dateFilter, // Если ты добавил поддержку дат
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

    // 1. Сортировка
    final sortedRecords = List<HistoryExpenseModel>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    // 2. Фильтр по дате
    List<HistoryExpenseModel> dateFiltered = sortedRecords;
    switch (dateFilter) {
      case DateFilterType.today:
        dateFiltered = sortedRecords
            .where(
              (r) =>
                  r.date.year == now.year &&
                  r.date.month == now.month &&
                  r.date.day == now.day,
            )
            .toList();
        break;
      case DateFilterType.yesterday:
        final y = now.subtract(const Duration(days: 1));
        dateFiltered = sortedRecords
            .where(
              (r) =>
                  r.date.year == y.year &&
                  r.date.month == y.month &&
                  r.date.day == y.day,
            )
            .toList();
        break;
      case DateFilterType.thisWeek:
        final start = now.subtract(Duration(days: now.weekday - 1));
        dateFiltered = sortedRecords
            .where(
              (r) => r.date.isAfter(
                DateTime(
                  start.year,
                  start.month,
                  start.day,
                ).subtract(const Duration(seconds: 1)),
              ),
            )
            .toList();
        break;
      case DateFilterType.all:
        break;
    }

    // 3. Фильтр по типу
    List<HistoryExpenseModel> finalFiltered;
    switch (typeFilter) {
      case HistoryFilterType.expense:
        finalFiltered = dateFiltered.where((e) => !e.isIncome).toList();
        break;
      case HistoryFilterType.income:
        finalFiltered = dateFiltered.where((e) => e.isIncome).toList();
        break;
      case HistoryFilterType.all:
        finalFiltered = dateFiltered;
        break;
    }

    // 4. Подсчет баланса (по всем записям)
    final incomes = sortedRecords
        .where((e) => e.isIncome)
        .fold(0.0, (sum, e) => sum + e.price);
    final expenses = sortedRecords
        .where((e) => !e.isIncome)
        .fold(0.0, (sum, e) => sum + e.price);

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

  Future<void> addRecord(HistoryExpenseModel record) async {
    await _repository.saveExpense(record);
    final updatedRecords = List<HistoryExpenseModel>.from(state.allRecords)
      ..add(record);
    _calculateAndEmit(
      updatedRecords,
      state.activeFilter,
      state.dateFilter,
      currentLimit: state.budgetLimit,
    );

    try {
      await _repository.syncWithCloud(record);
      _calculateAndEmit(
        _repository.getAllExpenses(),
        state.activeFilter,
        state.dateFilter,
        currentLimit: state.budgetLimit,
      );
    } catch (e) {
      print('Sync error: $e');
    }
  }

  Future<void> removeRecord(String id) async {
    await _repository.deleteExpense(id);
    final updatedRecords = state.allRecords.where((r) => r.id != id).toList();
    _calculateAndEmit(
      updatedRecords,
      state.activeFilter,
      state.dateFilter,
      currentLimit: state.budgetLimit,
    );
    try {
      await _repository.deleteFromCloud(id);
    } catch (_) {}
  }

  Future<void> _syncOfflineRecords() async {
    final unsynced = _repository
        .getAllExpenses()
        .where((r) => !r.isSynced)
        .toList();
    for (var record in unsynced) {
      await _repository.syncWithCloud(record);
    }
    _calculateAndEmit(
      _repository.getAllExpenses(),
      state.activeFilter,
      state.dateFilter,
      currentLimit: state.budgetLimit,
    );
  }
}
