import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_sync_service.dart';
import '../../domain/entities/history_expense.dart';
import '../../domain/repositories/history_repository.dart';
import '../models/history_expense_model.dart';

class HistoryRepositoryImpl implements IHistoryRepository {
  final SupabaseSyncService _syncService;

  HistoryRepositoryImpl({SupabaseSyncService? syncService})
    : _syncService = syncService ?? SupabaseSyncService();

  Box<HistoryExpenseModel> get _box =>
      Hive.box<HistoryExpenseModel>('history_box');

  @override
  List<HistoryExpense> getAllExpenses() {
    final models = _box.values.toList();
    models.sort((a, b) => b.date.compareTo(a.date));
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> saveExpense(HistoryExpense expense) async {
    final model = HistoryExpenseModel.fromEntity(expense);
    await _box.put(model.id, model);
  }

  @override
  Future<void> syncWithCloud(HistoryExpense expense) async {
    if (!_syncService.isAuthenticated) return;

    final model = HistoryExpenseModel.fromEntity(expense);
    final success = await _syncService.syncRecord(model);

    if (success) {
      final syncedModel = model.copyWith(isSynced: true);
      await _box.put(syncedModel.id, syncedModel);
    } else {
      throw Exception('Failed to synchronize record with Supabase cloud.');
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> deleteFromCloud(String id) async {
    if (!_syncService.isAuthenticated) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('expenses').delete().eq('id', id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> syncUnsyncedRecords() async {
    final unsyncedModels = _box.values.where((r) => !r.isSynced).toList();
    if (unsyncedModels.isEmpty) return;

    final syncedIds = await _syncService.syncPool(unsyncedModels);
    for (var id in syncedIds) {
      final localItem = _box.get(id);
      if (localItem != null) {
        await _box.put(id, localItem.copyWith(isSynced: true));
      }
    }
  }
}
