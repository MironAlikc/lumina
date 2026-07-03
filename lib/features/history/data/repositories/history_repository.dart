import 'package:hive/hive.dart';
import '../../../../core/database/hive_client.dart';
import '../models/history_expense_model.dart'; // Импортируем модель из соседней папки

class HistoryRepository {
  // Открываем коробку, используя наше централизованное имя из HiveClient
  final Box _box = Hive.box(HiveClient.boxName);

  // Загрузка всех расходов из базы
  List<HistoryExpenseModel> loadAllExpenses() {
    final List<HistoryExpenseModel> expenses = [];

    for (var key in _box.keys) {
      final dynamic data = _box.get(key);
      if (data != null) {
        // Безопасно преобразуем динамический Map из Hive в Map<String, dynamic>
        final Map<String, dynamic> map = Map<String, dynamic>.from(data as Map);
        expenses.add(HistoryExpenseModel.fromMap(map));
      }
    }

    // Сортируем расходы: самые новые транзакции будут отображаться вверху списка
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  // Сохранение нового расхода в Hive
  Future<void> saveNewExpense(HistoryExpenseModel expense) async {
    await _box.put(expense.id, expense.toMap());
  }

  // Удаление расхода по его уникальному ID (ключу)
  Future<void> deleteExpense(String id) async {
    await _box.delete(id);
  }
}
