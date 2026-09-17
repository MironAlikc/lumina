import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../features/history/data/models/history_expense_model.dart';

class HiveClient {
  static const String boxName = 'history_box';

  Future<void> init() async {
    await Hive.initFlutter();

    // 1. Регистрация адаптеров
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HistoryExpenseModelAdapter());
    }

    // 2. Безопасная миграция данных
    if (await Hive.boxExists(boxName)) {
      final rawBox = await Hive.openBox(boxName);
      if (rawBox.isNotEmpty && rawBox.values.first is! HistoryExpenseModel) {
        await rawBox.clear();
        debugPrint('🧹 Кэш Hive очищен: структура модели обновлена.');
      }
      await rawBox.close();
    }

    // 3. Открытие коробки
    final box = await Hive.openBox<HistoryExpenseModel>(boxName);

    // 4. Демо-данные
    if (box.isEmpty) {
      final demo = [
        HistoryExpenseModel(
          id: '1',
          date: DateTime(2026, 7, 3),
          productName: 'Зарплата',
          price: 45000.0,
          categoryId: 'cat_salary',
          categoryName: 'Salary',
          type: TransactionType.income,
        ),
        HistoryExpenseModel(
          id: '2',
          date: DateTime(2026, 7, 3),
          productName: 'Супермаркет',
          price: 1250.0,
          categoryId: 'cat_food',
          categoryName: 'Продукты',
          type: TransactionType.expense,
        ),
        HistoryExpenseModel(
          id: '3',
          date: DateTime(2026, 7, 2),
          productName: 'Заправка',
          price: 2100.0,
          categoryId: 'cat_transport',
          categoryName: 'Транспорт',
          type: TransactionType.expense,
        ),
      ];

      for (var expense in demo) {
        await box.put(expense.id, expense);
      }
      debugPrint('🚀 Демо-данные успешно загружены!');
    }
  }
}
