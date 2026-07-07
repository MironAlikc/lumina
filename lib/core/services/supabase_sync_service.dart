import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/history/data/models/history_expense_model.dart';

class SupabaseSyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool get isAuthenticated => _supabase.auth.currentUser != null;
  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<bool> syncRecord(HistoryExpenseModel expense) async {
    if (!isAuthenticated) return false;

    try {
      final userId = currentUserId;
      if (userId == null) return false;

      await _supabase.from('expenses').upsert(expense.toSupabaseMap(userId));

      return true;
    } catch (e) {
      print('🌐 Supabase Sync Error for record ${expense.id}: $e');
      return false;
    }
  }

  Future<List<String>> syncPool(
    List<HistoryExpenseModel> unSyncedExpenses,
  ) async {
    if (!isAuthenticated || unSyncedExpenses.isEmpty) return [];

    try {
      final userId = currentUserId;
      if (userId == null) return [];

      final List<Map<String, dynamic>> recordsToUpsert = unSyncedExpenses
          .map((expense) => expense.toSupabaseMap(userId))
          .toList();
      await _supabase.from('expenses').upsert(recordsToUpsert);

      print(
        '📦 [SupabaseSyncService] Пул из ${unSyncedExpenses.length} записей успешно отправлен в облако!',
      );

      // 3. Возвращаем ID записей, которые только что успешно синхронизировались
      return unSyncedExpenses.map((e) => e.id).toList();
    } catch (e) {
      print('🌐 Supabase Batch Sync Error: $e');
      return [];
    }
  }
}
