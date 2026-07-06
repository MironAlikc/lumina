import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_sync_service.dart';
import '../models/history_expense_model.dart';

class HistoryRepository {
  final SupabaseSyncService _syncService = SupabaseSyncService();

  // Обращаемся к коробке через геттер. Коробка должна быть открыта при старте приложения.
  Box<HistoryExpenseModel> get _box =>
      Hive.box<HistoryExpenseModel>('history_box');

  /// Получить все расходы из локального Hive
  List<HistoryExpenseModel> getAllExpenses() {
    final list = _box.values.toList();
    // Сортируем по дате от новых к старым (свежие покупки сверху)
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Добавление новой записи (Локальное сохранение)
  Future<void> saveExpense(HistoryExpenseModel expense) async {
    // Мгновенно сохраняем локально в Hive (UI обновится без задержек)
    await _box.put(expense.id, expense);
  }

  /// Публичный метод синхронизации ОДНОЙ конкретной записи с облаком Supabase
  /// Используется в Кубите для фонового обновления флага отправки
  Future<void> syncWithCloud(HistoryExpenseModel expense) async {
    if (_syncService.isAuthenticated) {
      final success = await _syncService.syncRecord(expense);
      if (success) {
        // Если успешно улетело в сеть, обновляем флаг локально в Hive на true
        final syncedExpense = expense.copyWith(isSynced: true);
        await _box.put(syncedExpense.id, syncedExpense);
        print(
          '📦 Запись "${expense.productName}" успешно синхронизирована с Supabase!',
        );
      } else {
        throw Exception('SupabaseSyncService вернул false при отправке записи');
      }
    } else {
      print(
        '🌐 Синхронизация пропущена: пользователь не авторизован в Supabase',
      );
    }
  }

  /// Удаление записи локально из Hive
  Future<void> deleteExpense(String id) async {
    await _box.delete(id);
  }

  /// Публичный метод удаления записи напрямую из облака Supabase
  Future<void> deleteFromCloud(String id) async {
    if (_syncService.isAuthenticated) {
      try {
        final supabase = Supabase.instance.client;
        // Название таблицы в Supabase должно строго совпадать с твоей схемой (например, 'expenses')
        await supabase.from('expenses').delete().eq('id', id);
        print('🗑️ Запись $id успешно удалена из Supabase!');
      } catch (e) {
        print('🌐 Ошибка фонового удаления из Supabase: $e');
        // Пробрасываем ошибку выше, чтобы Cubit мог залогировать или обработать её
        rethrow;
      }
    }
  }

  /// Метод полной пакетной синхронизации пула (вызывается при старте или восстановлении сети)
  Future<void> syncUnsyncedRecords() async {
    // Ищем локально все расходы, у которых флаг isSynced == false
    final unSynced = _box.values.where((e) => !e.isSynced).toList();

    if (unSynced.isEmpty) return;

    print(
      '🔄 Пакетная синхронизация: найдено ${unSynced.length} несинхронизированных записей.',
    );

    // Передаем пачку данных в сервис синхронизации
    final syncedIds = await _syncService.syncPool(unSynced);

    // Для всех успешно отправленных записей переключаем флаг локально в Hive
    for (var id in syncedIds) {
      final localItem = _box.get(id);
      if (localItem != null) {
        await _box.put(id, localItem.copyWith(isSynced: true));
      }
    }
    print('✅ Пакетная синхронизация успешно завершена!');
  }
}
