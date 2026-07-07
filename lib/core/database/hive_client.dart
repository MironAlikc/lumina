import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../features/history/data/models/history_expense_model.dart';

class HiveClient {
  static const String boxName = 'history_box';

  Future<void> init() async {
    await Hive.initFlutter();

    // 1. Регистрируем адаптеры, если они еще не зарегистрированы
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionTypeAdapter()); // Адаптер для ENUM
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HistoryExpenseModelAdapter());
    }

    // 2. БЕЗОПАСНОСТЬ: Очистка старой структуры при смене типов
    // При переходе на Enum лучше сбросить кэш, чтобы не было конфликтов типов данных
    final boxExists = await Hive.boxExists(boxName);
    if (boxExists) {
      final rawBox = await Hive.openBox(boxName);
      // Если структура данных устарела, очищаем
      if (rawBox.isNotEmpty && rawBox.values.first is! HistoryExpenseModel) {
        await rawBox.clear();
        debugPrint('🧹 Кэш Hive очищен: структура модели обновлена.');
      }
      await rawBox.close();
    }

    // 3. Открываем строго типизированную коробку
    final box = await Hive.openBox<HistoryExpenseModel>(boxName);

    // 4. Заполнение демо-данными (с использованием ENUM)
    if (box.isEmpty) {
      final demo = [
        HistoryExpenseModel(
          id: '1',
          date: DateTime(2026, 7, 3),
          productName: 'Зарплата (Аванс)',
          price: 45000.0,
          category: 'Доход',
          type: TransactionType.income, // Используем ENUM!
        ),
        HistoryExpenseModel(
          id: '2',
          date: DateTime(2026, 7, 3),
          productName: 'Супермаркет Сильпо',
          price: 1250.0,
          category: 'Продукты',
          type: TransactionType.expense, // Используем ENUM!
        ),
        HistoryExpenseModel(
          id: '3',
          date: DateTime(2026, 7, 2),
          productName: 'Заправка ОККО',
          price: 2100.0,
          category: 'Транспорт',
          type: TransactionType.expense,
        ),
        HistoryExpenseModel(
          id: '4',
          date: DateTime(2026, 7, 2),
          productName: 'Ужин в ресторане',
          price: 850.0,
          category: 'Кафе',
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
