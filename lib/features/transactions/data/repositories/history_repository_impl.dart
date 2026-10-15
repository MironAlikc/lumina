import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/core/services/supabase_sync_service.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';
import 'package:lumina/features/transactions/domain/entities/history_expense.dart';
import 'package:lumina/features/transactions/domain/repositories/history_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryRepositoryImpl implements IHistoryRepository {
  HistoryRepositoryImpl({SupabaseSyncService? syncService})
      : _syncService = syncService ?? SupabaseSyncService.instance;

  final SupabaseSyncService _syncService;

  Box<HistoryExpenseModel> get _box =>
      Hive.box<HistoryExpenseModel>(HiveClient.historyBox);

  @override
  List<HistoryExpense> getAllExpenses() {
    final models = _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  HistoryExpense? getById(String id) => _box.get(id)?.toEntity();

  @override
  Future<void> saveExpense(HistoryExpense expense) async {
    await _box.put(expense.id, HistoryExpenseModel.fromEntity(expense));
  }

  @override
  Future<void> syncWithCloud(HistoryExpense expense) async {
    if (!_syncService.isAuthenticated) return;

    final success = await _syncService.syncRecord(
      HistoryExpenseModel.fromEntity(expense),
    );
    if (!success) return;

    // Запись могли удалить, пока шла отправка: не воскрешаем её.
    final current = _box.get(expense.id);
    if (current == null) return;
    await _box.put(expense.id, current.copyWith(isSynced: true));
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> deleteFromCloud(String id) async {
    if (!_syncService.isAuthenticated) return;
    try {
      await Supabase.instance.client.from('expenses').delete().eq('id', id);
    } catch (e, st) {
      debugPrint('deleteFromCloud failed for $id: $e\n$st');
    }
  }

  @override
  Future<void> syncUnsyncedRecords() async {
    final unsynced = _box.values.where((r) => !r.isSynced).toList();
    if (unsynced.isEmpty) return;

    final syncedIds = await _syncService.syncPool(unsynced);
    if (syncedIds.isEmpty) return;

    final updates = <String, HistoryExpenseModel>{};
    for (final id in syncedIds) {
      final local = _box.get(id);
      if (local != null) updates[id] = local.copyWith(isSynced: true);
    }
    await _box.putAll(updates);
  }
}
