import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/history/data/models/history_expense_model.dart';

class SupabaseSyncService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Проверяем, авторизован ли пользователь в системе
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Получаем ID текущего пользователя
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Отправка локальной записи в Supabase
  Future<bool> syncRecord(HistoryExpenseModel expense) async {
    if (!isAuthenticated) return false;

    try {
      final userId = currentUserId;
      if (userId == null) return false;

      // Выполняем upsert (если записи с таким id нет — создаст, если есть — обновит)
      await _supabase.from('expenses').upsert(expense.toSupabaseMap(userId));

      return true; // Синхронизация успешна
    } catch (e) {
      // Если интернета нет или упала ошибка — логируем и возвращаем false
      print('🌐 Supabase Sync Error for record ${expense.id}: $e');
      return false;
    }
  }

  /// ИСПРАВЛЕНО: Пакетная синхронизация пула (Batch Upload) за один сетевой запрос
  Future<List<String>> syncPool(
    List<HistoryExpenseModel> unSyncedExpenses,
  ) async {
    if (!isAuthenticated || unSyncedExpenses.isEmpty) return [];

    try {
      final userId = currentUserId;
      if (userId == null) return [];

      // 1. Маппим весь список моделей в список Map за один проход
      final List<Map<String, dynamic>> recordsToUpsert = unSyncedExpenses
          .map((expense) => expense.toSupabaseMap(userId))
          .toList();

      // 2. Отправляем всю пачку данных в Postgres одним запросом
      await _supabase.from('expenses').upsert(recordsToUpsert);

      print(
        '📦 [SupabaseSyncService] Пул из ${unSyncedExpenses.length} записей успешно отправлен в облако!',
      );

      // 3. Возвращаем ID записей, которые только что успешно синхронизировались
      return unSyncedExpenses.map((e) => e.id).toList();
    } catch (e) {
      print('🌐 Supabase Batch Sync Error: $e');
      return []; // Если пачка упала, возвращаем пустой список, локальный Hive флаги не переключит
    }
  }
}
