import '../entities/history_expense.dart';

abstract class IHistoryRepository {
  /// Получить все локальные записи расходов и доходов
  List<HistoryExpense> getAllExpenses();

  /// Получить одну запись по id (null, если её нет)
  HistoryExpense? getById(String id);

  /// Сохранить или обновить запись локально
  Future<void> saveExpense(HistoryExpense expense);

  /// Синхронизировать конкретную запись с облаком
  Future<void> syncWithCloud(HistoryExpense expense);

  /// Удалить запись локально по ее ID
  Future<void> deleteExpense(String id);

  /// Удалить запись из облака по ее ID
  Future<void> deleteFromCloud(String id);

  /// Массовая синхронизация всех несинхронизированных записей
  Future<void> syncUnsyncedRecords();
}
