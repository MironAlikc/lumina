import 'package:hive/hive.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/core/services/supabase_sync_service.dart';
import 'package:lumina/features/transactions/domain/entities/history_expense.dart';
import 'package:lumina/features/transactions/domain/repositories/history_repository.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryRepositoryImpl implements IHistoryRepository {
  HistoryRepositoryImpl({SupabaseSyncService? syncService})
    : _syncService = syncService ?? SupabaseSyncService.instance;

  final SupabaseSyncService _syncService;

  Box<HistoryExpenseModel> get _box =>
      Hive.box<HistoryExpenseModel>(HiveClient.boxName);

  @override
  List<HistoryExpense> getAllExpenses() {
    final models = _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> saveExpense(HistoryExpense expense) async {
    await _box.put(expense.id, HistoryExpenseModel.fromEntity(expense));
  }

  @override
  Future<void> syncWithCloud(HistoryExpense expense) async {
    if (!_syncService.isAuthenticated) return;

    final model = HistoryExpenseModel.fromEntity(expense);
    final success = await _syncService.syncRecord(model);
    if (!success) return;

    await _box.put(model.id, model.copyWith(isSynced: true));
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
    } catch (_) {}
  }

  @override
  Future<void> syncUnsyncedRecords() async {
    final unsynced = _box.values.where((r) => !r.isSynced).toList();
    if (unsynced.isEmpty) return;

    final syncedIds = await _syncService.syncPool(unsynced);
    for (final id in syncedIds) {
      final localItem = _box.get(id);
      if (localItem != null) {
        await _box.put(id, localItem.copyWith(isSynced: true));
      }
    }
  }
}
