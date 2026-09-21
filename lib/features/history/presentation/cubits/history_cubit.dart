import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/features/history/data/services/recurring_service.dart';
import 'package:lumina/features/history/domain/entities/history_expense.dart';
import 'package:lumina/features/history/domain/repositories/history_repository.dart';
import 'package:lumina/features/history/presentation/cubits/history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._repository) : super(HistoryState()) {
    loadRecords();
  }

  final IHistoryRepository _repository;

  static const _budgetLimitKey = 'budget_limit';

  static const _categoryAliases = <String, Set<String>>{
    'cat_food': {'food', 'food & drinks', 'еда и напитки', 'їжа та напої'},
    'cat_transport': {'transport', 'транспорт'},
    'cat_shopping': {'shopping', 'покупки'},
    'cat_entertainment': {'entertainment', 'развлечения', 'розваги'},
    'cat_housing': {'housing', 'жильё', 'житло', 'home'},
    'cat_salary': {'salary', 'зарплата', 'cat_income', 'income'},
    'cat_income': {'salary', 'зарплата', 'cat_salary', 'income'},
    'cat_goals': {'savings', 'goals', 'цели', 'цілі'},
  };

  Box<dynamic> get _settings => Hive.box(HiveClient.settingsBox);

  double _getStoredBudgetLimit() {
    try {
      final raw = _settings.get(_budgetLimitKey, defaultValue: 0.0);
      if (raw is num) return raw.toDouble();
      return 0.0;
    } catch (e, st) {
      debugPrint('budget_limit read failed: $e\n$st');
      return 0.0;
    }
  }

  Future<void> _saveBudgetLimitToStore(double limit) async {
    try {
      await _settings.put(_budgetLimitKey, limit);
    } catch (e, st) {
      debugPrint('budget_limit write failed: $e\n$st');
    }
  }

  void toggleViewMode(HistoryViewMode mode) {
    if (state.viewMode == mode) return;
    emit(state.copyWith(viewMode: mode));
  }

  void updateBudgetLimit(double newLimit) {
    _saveBudgetLimitToStore(newLimit);
    _recalculate(currentLimit: newLimit);
  }

  Future<void> loadRecords() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true));
    await _checkRecurringPayments();
    if (isClosed) return;
    _calculateAndEmit(
      _repository.getAllExpenses(),
      state.activeFilter,
      state.dateFilter,
      state.selectedCategoryKey,
      state.selectedMonth,
      state.selectedYear,
      currentLimit: _getStoredBudgetLimit(),
    );
    await _syncOfflineRecords();
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
    } catch (e, st) {
      debugPrint('Recurring payment check error: $e\n$st');
    }
  }

  void changeFilter(HistoryFilterType typeFilter) {
    _recalculate(typeFilter: typeFilter);
  }

  void changeDateFilter(DateFilterType dateFilter) {
    _recalculate(dateFilter: dateFilter);
  }

  void changeCategoryFilter(String? categoryKey) {
    final isAll = categoryKey == null || categoryKey.isEmpty;
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
    _recalculate(month: month, year: year);
  }

  void _recalculate({
    HistoryFilterType? typeFilter,
    DateFilterType? dateFilter,
    int? month,
    int? year,
    double? currentLimit,
  }) {
    _calculateAndEmit(
      state.allRecords,
      typeFilter ?? state.activeFilter,
      dateFilter ?? state.dateFilter,
      state.selectedCategoryKey,
      month ?? state.selectedMonth,
      year ?? state.selectedYear,
      currentLimit: currentLimit ?? state.budgetLimit,
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
    if (isClosed) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final sortedRecords = List<HistoryExpense>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    final monthFiltered = sortedRecords.where((r) {
      return r.date.month == month && r.date.year == year;
    }).toList();

    final dateFiltered = monthFiltered.where((r) {
      final day = DateTime(r.date.year, r.date.month, r.date.day);
      return switch (dateFilter) {
        DateFilterType.today => day == today,
        DateFilterType.yesterday =>
          day == today.subtract(const Duration(days: 1)),
        DateFilterType.thisWeek =>
          !day.isBefore(weekStart) && day.isBefore(weekEnd),
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
    final finalFiltered = (effectiveKey == null)
        ? typeFiltered
        : typeFiltered.where((e) => _matchesCategory(e, effectiveKey)).toList();

    var incomes = 0.0;
    var expenses = 0.0;
    for (final r in monthFiltered) {
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

  bool _matchesCategory(HistoryExpense e, String key) {
    final stored = e.category.trim().toLowerCase();
    final needle = key.trim().toLowerCase();
    if (stored == needle) return true;
    final aliases = _categoryAliases[needle];
    if (aliases != null && aliases.contains(stored)) return true;
    for (final entry in _categoryAliases.entries) {
      if (entry.value.contains(stored) && entry.key == needle) return true;
    }
    return false;
  }

  Future<void> addRecord(HistoryExpense record) async {
    await _repository.saveExpense(record);
    _refreshState();
    try {
      await _repository.syncWithCloud(record);
      _refreshState();
    } catch (e, st) {
      debugPrint('Sync error: $e\n$st');
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
    if (unsynced.isEmpty) return;
    for (final record in unsynced) {
      try {
        await _repository.syncWithCloud(record);
      } catch (_) {}
    }
    _refreshState();
  }
}
