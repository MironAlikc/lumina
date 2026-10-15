import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/features/accounts/presentation/cubits/account_cubit.dart';
import 'package:lumina/features/recurring/data/services/recurring_service.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';
import 'package:lumina/features/transactions/domain/entities/history_expense.dart';
import 'package:lumina/features/transactions/domain/repositories/history_repository.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._repository, {AccountCubit? accountCubit})
      : _accountCubit = accountCubit,
        super(HistoryState()) {
    loadRecords();
  }

  final IHistoryRepository _repository;
  final AccountCubit? _accountCubit;

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

  bool _loading = false;

  Box<dynamic> get _settings => Hive.box(HiveClient.settingsBox);

  static double _r2(double v) => (v * 100).round() / 100;

  double _getStoredBudgetLimit() {
    try {
      final raw = _settings.get(_budgetLimitKey, defaultValue: 0.0);
      return raw is num ? raw.toDouble() : 0.0;
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

  Future<void> processRecurring() async {
    await _checkRecurringPayments();
    _refreshState();
  }

  void toggleViewMode(HistoryViewMode mode) {
    if (state.viewMode == mode) return;
    emit(state.copyWith(viewMode: mode));
  }

  void refresh() => _refreshState();
  void updateBudgetLimit(double newLimit) {
    unawaited(_saveBudgetLimitToStore(newLimit));
    _recalculate(currentLimit: newLimit);
  }

  void changeSearchQuery(String query) {
    _calculateAndEmit(
      state.allRecords,
      state.activeFilter,
      state.dateFilter,
      state.selectedCategoryKey,
      state.selectedMonth,
      state.selectedYear,
      searchQuery: query,
      currentLimit: state.budgetLimit,
    );
  }

  Future<void> loadRecords() async {
    if (isClosed || _loading) return;
    _loading = true;
    try {
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
        searchQuery: state.searchQuery,
        currentLimit: _getStoredBudgetLimit(),
      );

      await _syncOfflineRecords();
    } finally {
      _loading = false;
    }
  }

  Future<void> _checkRecurringPayments() async {
    try {
      await RecurringService.checkAndProcessRecurring((newRecordModel) async {
        final entity = newRecordModel.toEntity();
        await _repository.saveExpense(entity);

        try {
          await _accountCubit?.processTransaction(newRecordModel);
        } catch (e) {
          await _repository.deleteExpense(entity.id);
          rethrow;
        }

        unawaited(_syncRecord(entity));
      });
    } catch (e, st) {
      debugPrint('Recurring payment check error: $e\n$st');
    }
  }

  void changeFilter(HistoryFilterType typeFilter) =>
      _recalculate(typeFilter: typeFilter);

  void changeDateFilter(DateFilterType dateFilter) =>
      _recalculate(dateFilter: dateFilter);

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
      searchQuery: state.searchQuery,
      currentLimit: state.budgetLimit,
    );
  }

  void changeMonth(int month, int year) {
    _recalculate(month: month, year: year, dateFilter: DateFilterType.all);
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
      searchQuery: state.searchQuery,
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
    String? searchQuery,
    required double currentLimit,
  }) {
    if (isClosed) return;

    final query = (searchQuery ?? state.searchQuery).trim().toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final sortedRecords = List<HistoryExpense>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    final monthFiltered = sortedRecords
        .where((r) => r.date.month == month && r.date.year == year)
        .toList();

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
      HistoryFilterType.expense => dateFiltered.where((e) => e.isExpense),
      HistoryFilterType.income => dateFiltered.where((e) => e.isIncome),
      HistoryFilterType.all => dateFiltered,
    }
        .toList();

    final effectiveKey = clearCategory ? null : categoryKey;
    final categoryFiltered = effectiveKey == null
        ? typeFiltered
        : typeFiltered.where((e) => _matchesCategory(e, effectiveKey)).toList();

    final finalFiltered = query.isEmpty
        ? categoryFiltered
        : categoryFiltered.where((e) {
            final nameMatch = e.productName.toLowerCase().contains(query);
            final categoryMatch = e.category.toLowerCase().contains(query);
            return nameMatch || categoryMatch;
          }).toList();

    var incomes = 0.0;
    var expenses = 0.0;
    for (final r in monthFiltered) {
      if (r.isIncome) {
        incomes += r.price;
      } else if (r.isExpense) {
        expenses += r.price;
      }
    }
    incomes = _r2(incomes);
    expenses = _r2(expenses);

    emit(
      state.copyWith(
        allRecords: sortedRecords,
        filteredRecords: finalFiltered,
        totalBalance: _r2(incomes - expenses),
        totalIncomes: incomes,
        totalExpenses: expenses,
        activeFilter: typeFilter,
        dateFilter: dateFilter,
        selectedCategoryKey: effectiveKey,
        clearCategory: clearCategory,
        searchQuery: query,
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
    return _categoryAliases[needle]?.contains(stored) ?? false;
  }

  Future<void> addRecord(HistoryExpense record) async {
    await _repository.saveExpense(record);

    try {
      await _accountCubit?.processTransaction(
        HistoryExpenseModel.fromEntity(record),
      );
    } catch (e, st) {
      debugPrint('addRecord: balance update failed, rolling back: $e\n$st');
      await _repository.deleteExpense(record.id);
      _refreshState();
      rethrow;
    }

    _refreshState();
    unawaited(_syncRecord(record));
  }

  Future<void> updateRecord(HistoryExpense updated) async {
    final old = _repository.getById(updated.id);
    if (old == null) return addRecord(updated);

    final next = updated.copyWith(isSynced: false);
    await _repository.saveExpense(next);

    try {
      final accounts = _accountCubit;
      if (accounts != null) {
        final newModel = HistoryExpenseModel.fromEntity(next);
        final oldModel = HistoryExpenseModel.fromEntity(old);

        if (old.accountId == null) {
          await accounts.processTransaction(newModel);
        } else {
          await accounts.replaceTransaction(oldModel, newModel);
        }
      }
    } catch (e, st) {
      debugPrint('updateRecord: balance update failed, restoring: $e\n$st');
      await _repository.saveExpense(old);
      _refreshState();
      rethrow;
    }

    _refreshState();
    unawaited(_syncRecord(next));
  }

  Future<void> removeRecord(String id) async {
    final record = _repository.getById(id);
    if (record == null) return;

    _calculateAndEmit(
      state.allRecords.where((r) => r.id != id).toList(),
      state.activeFilter,
      state.dateFilter,
      state.selectedCategoryKey,
      state.selectedMonth,
      state.selectedYear,
      searchQuery: state.searchQuery,
      currentLimit: state.budgetLimit,
    );

    if (record.accountId != null) {
      try {
        await _accountCubit?.rollbackTransaction(
          HistoryExpenseModel.fromEntity(record),
        );
      } catch (e, st) {
        debugPrint('removeRecord: balance rollback failed: $e\n$st');
        _refreshState();
        rethrow;
      }
    }

    try {
      await _repository.deleteExpense(id);
    } catch (e, st) {
      debugPrint('removeRecord: local delete failed: $e\n$st');
      if (record.accountId != null) {
        await _accountCubit?.processTransaction(
          HistoryExpenseModel.fromEntity(record),
        );
      }
      _refreshState();
      rethrow;
    }

    unawaited(_repository.deleteFromCloud(id));
  }

  void _refreshState() {
    _calculateAndEmit(
      _repository.getAllExpenses(),
      state.activeFilter,
      state.dateFilter,
      state.selectedCategoryKey,
      state.selectedMonth,
      state.selectedYear,
      searchQuery: state.searchQuery,
      currentLimit: state.budgetLimit,
    );
  }

  Future<void> _syncRecord(HistoryExpense record) async {
    try {
      await _repository.syncWithCloud(record);
      _refreshState();
    } catch (e, st) {
      debugPrint('Sync error: $e\n$st');
    }
  }

  Future<void> _syncOfflineRecords() async {
    try {
      await _repository.syncUnsyncedRecords();
      _refreshState();
    } catch (e, st) {
      debugPrint('Batch offline sync error: $e\n$st');
    }
  }
}
