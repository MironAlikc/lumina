import 'package:hive_flutter/hive_flutter.dart';
import '../../../features/history/data/models/history_expense_model.dart';

class HiveClient {
  static const String boxName = 'history_box';

  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HistoryExpenseModelAdapter());
    }

    // БЕЗОПАСНОСТЬ: Если коробка уже существует, сначала открываем её в сыром виде и чистим,
    // чтобы старые записи без полей category/type не крашили адаптер.
    if (await Hive.boxExists(boxName)) {
      final rawBox = await Hive.openBox(boxName);
      // Если внутри лежат старые Map или объекты без новых полей — сбрасываем коробку
      if (rawBox.isNotEmpty) {
        final firstItem = rawBox.values.first;
        if (firstItem is! HistoryExpenseModel || firstItem.category == null) {
          await rawBox.clear();
          print(
            '🧹 Старый кэш Hive успешно очищен для новой структуры данных!',
          );
        }
      }
      await rawBox.close();
    }

    // Открываем чистую строго типизированную коробку
    final box = await Hive.openBox<HistoryExpenseModel>(boxName);

    // Заполняем новыми красивыми данными для аналитики
    if (box.isEmpty) {
      final demo = [
        HistoryExpenseModel(
          id: '1',
          date: DateTime(2026, 7, 3),
          productName: 'Зарплата (Аванс)',
          price: 45000.0,
          isSynced: false,
          category: 'Доход',
          type: 'income',
        ),
        HistoryExpenseModel(
          id: '2',
          date: DateTime(2026, 7, 3),
          productName: 'Супермаркет Сильпо',
          price: 1250.0,
          isSynced: false,
          category: 'Продукты',
          type: 'expense',
        ),
        HistoryExpenseModel(
          id: '3',
          date: DateTime(2026, 7, 2),
          productName: 'Заправка ОККО',
          price: 2100.0,
          isSynced: false,
          category: 'Транспорт',
          type: 'expense',
        ),
        HistoryExpenseModel(
          id: '4',
          date: DateTime(2026, 7, 2),
          productName: 'Ужин в ресторане',
          price: 850.0,
          isSynced: false,
          category: 'Кафе',
          type: 'expense',
        ),
        HistoryExpenseModel(
          id: '5',
          date: DateTime(2026, 7, 1),
          productName: 'Курсы по Flutter',
          price: 3400.0,
          isSynced: false,
          category: 'Образование',
          type: 'expense',
        ),
        HistoryExpenseModel(
          id: '6',
          date: DateTime(2026, 6, 28),
          productName: 'Фриланс (Дизайн)',
          price: 12000.0,
          isSynced: false,
          category: 'Доход',
          type: 'income',
        ),
        HistoryExpenseModel(
          id: '7',
          date: DateTime(2026, 6, 27),
          productName: 'Аренда квартиры',
          price: 15000.0,
          isSynced: false,
          category: 'Жилье',
          type: 'expense',
        ),
      ];

      for (var expense in demo) {
        await box.put(expense.id, expense);
      }
    }
  }
}
