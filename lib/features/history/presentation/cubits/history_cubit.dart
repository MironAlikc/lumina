import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../../data/services/recurring_service.dart';
import '../../domain/entities/history_expense.dart';
import '../../domain/repositories/history_repository.dart';
import 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  final IHistoryRepository _repository;

  HistoryCubit(this._repository) : super(HistoryState()) {
    loadRecords();
  }

  /// Получаем сохраненный лимит бюджета из Hive (если настроено, иначе берем из state)
  double _getStoredBudgetLimit() {
    try {
      final settingsBox = Hive.box('settings_box');
      return settingsBox.get('budget_limit', defaultValue: state.budgetLimit)
          as double;
    } catch (_) {
      return state.budgetLimit;
    }
  }

  /// Сохраняем лимит бюджета в Hive, чтобы он не сбрасывался при перезапуске
  Future<void> _saveBudgetLimitToStore(double limit) async {
    try {
      final settingsBox = Hive.box('settings_box');
      await settingsBox.put('budget_limit', limit);
    } catch (_) {}
  }

  void toggleViewMode(HistoryViewMode mode) {
    emit(state.copyWith(viewMode: mode));
  }

  void updateBudgetLimit(double newLimit) {
    _saveBudgetLimitToStore(newLimit);
    _calculateAndEmit(
      state.allRecords,
      state.activeFilter,
      state.dateFilter,
      state.selectedCategoryKey,
      state.selectedMonth,
      state.selectedYear,
      currentLimit: newLimit,
    );
  }

  Future<void> loadRecords() async {
    emit(state.copyWith(isLoading: true));

    await _checkRecurringPayments();

    // Загружаем актуальный лимит из локального хранилища при старте
    final savedLimit = _getStoredBudgetLimit();

    _calculateAndEmit(
      _repository.getAllExpenses(),
      state.activeFilter,
      state.dateFilter,
      state.selectedCategoryKey,
      state.selectedMonth,
      state.selectedYear,
      currentLimit: savedLimit,
    );

    _syncOfflineRecords();
  }

  Future<void> _checkRecurringPayments() async {
    try {
      await RecurringService.checkAndProcessRecurring((newRecordModel) async {
        final entity = newRecordModel.toEntity();
        await _repository.saveExpense(entity);
        try {
          await _repository.syncWithCloud(entity);
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('Recurring payment check error: $e');
    }
  }

  void changeFilter(HistoryFilterType typeFilter) {
    _calculateAndEmit(
      state.allRecords,
      typeFilter,
      state.dateFilter,
      state.selectedCategoryKey,
      state.selectedMonth,
      state.selectedYear,
      currentLimit: state.budgetLimit,
    );
  }

  void changeDateFilter(DateFilterType dateFilter) {
    _calculateAndEmit(
      state.allRecords,
      state.activeFilter,
      dateFilter,
      state.selectedCategoryKey,
      state.selectedMonth,
      state.selectedYear,
      currentLimit: state.budgetLimit,
    );
  }

  void changeCategoryFilter(String? categoryKey) {
    final bool isAll = categoryKey == null || categoryKey.isEmpty;
    _calculateAndEmit(
      state.allRecords,
      state.activeFilter,
      state.dateFilter,
      isAll ? null : categoryKey,
      state.selectedMonth,
      state.selectedYear,
      clearCategory: isAll,
      currentLimit: state.budgetLimit,
    );
  }

  void changeMonth(int month, int year) {
    _calculateAndEmit(
      state.allRecords,
      state.activeFilter,
      state.dateFilter,
      state.selectedCategoryKey,
      month,
      year,
      currentLimit: state.budgetLimit,
    );
  }

  void _calculateAndEmit(
    List<HistoryExpense> records,
    HistoryFilterType typeFilter,
    DateFilterType dateFilter,
    String? categoryKey,
    int month,
    int year, {
    bool clearCategory = false,
    required double currentLimit,
  }) {
    final now = DateTime.now();

    final sortedRecords = List<HistoryExpense>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    final monthFiltered = sortedRecords.where((r) {
      return r.date.month == month && r.date.year == year;
    }).toList();

    final dateFiltered = monthFiltered.where((r) {
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

    final typeFiltered = switch (typeFilter) {
      HistoryFilterType.expense =>
        dateFiltered.where((e) => !e.isIncome).toList(),
      HistoryFilterType.income =>
        dateFiltered.where((e) => e.isIncome).toList(),
      HistoryFilterType.all => dateFiltered,
    };

    final effectiveKey = clearCategory ? null : categoryKey;
    final finalFiltered = (effectiveKey != null)
        ? typeFiltered.where((e) {
            return e.category.toLowerCase() == effectiveKey.toLowerCase();
          }).toList()
        : typeFiltered;

    double incomes = 0;
    double expenses = 0;
    for (var r in monthFiltered) {
      if (r.isIncome) {
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
        selectedCategoryKey: effectiveKey,
        clearCategory: clearCategory,
        selectedMonth: month,
        selectedYear: year,
        budgetLimit: currentLimit,
        isLoading: false,
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> addRecord(HistoryExpense record) async {
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
      state.selectedCategoryKey,
      state.selectedMonth,
      state.selectedYear,
      currentLimit: state.budgetLimit,
    );
  }

  Future<void> _syncOfflineRecords() async {
    final unsynced = _repository
        .getAllExpenses()
        .where((r) => !r.isSynced)
        .toList();
    for (var record in unsynced) {
      try {
        // Исправлено: теперь вызывается существующий в интерфейсе метод syncWithCloud
        await _repository.syncWithCloud(record);
      } catch (_) {}
    }
    _refreshState();
  }
}
