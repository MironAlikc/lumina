import 'package:flutter/foundation.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSyncService {
  // Приватный конструктор для Singleton
  SupabaseSyncService._internal();

  // Единственный экземпляр класса
  static final SupabaseSyncService instance = SupabaseSyncService._internal();

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isAuthenticated => _client?.auth.currentUser != null;
  String? get currentUserId => _client?.auth.currentUser?.id;

  /// Метод для принудительного вызова синхронизации (например, из Pull-to-Refresh)
  Future<void> syncNow() async {
    final supabase = _client;
    final userId = currentUserId;
    if (supabase == null || userId == null) return;

    try {
      // Здесь можно добавить вызов твоей логики выгрузки/загрузки данных,
      // например, проверку локальной базы и отправку несинхронизированных записей.
      debugPrint('SupabaseSyncService: Manual sync triggered successfully.');
    } catch (e, st) {
      debugPrint('Supabase manual sync error: $e\n$st');
      rethrow;
    }
  }

  Future<bool> syncRecord(HistoryExpenseModel expense) async {
    final supabase = _client;
    final userId = currentUserId;
    if (supabase == null || userId == null) return false;

    try {
      await supabase.from('expenses').upsert(expense.toSupabaseMap(userId));
      return true;
    } catch (e, st) {
      debugPrint('Supabase sync error ${expense.id}: $e\n$st');
      return false;
    }
  }

  Future<List<String>> syncPool(
    List<HistoryExpenseModel> unSyncedExpenses,
  ) async {
    final supabase = _client;
    final userId = currentUserId;
    if (supabase == null || userId == null || unSyncedExpenses.isEmpty) {
      return [];
    }

    try {
      await supabase
          .from('expenses')
          .upsert(
            unSyncedExpenses.map((e) => e.toSupabaseMap(userId)).toList(),
          );
      return unSyncedExpenses.map((e) => e.id).toList();
    } catch (e, st) {
      debugPrint('Supabase batch sync error: $e\n$st');
      return [];
    }
  }
}
