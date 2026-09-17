import 'package:hive/hive.dart';
import '../models/recurring_expense_model.dart';
import '../models/history_expense_model.dart';
import 'package:uuid/uuid.dart';

class RecurringService {
  static const String boxName = 'recurring_expenses_box';

  static Future<Box<RecurringExpenseModel>> _openBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<RecurringExpenseModel>(boxName);
    }
    return Hive.box<RecurringExpenseModel>(boxName);
  }

  // Проверка и автодобавление платежей при запуске приложения
  static Future<void> checkAndProcessRecurring(
    Function(HistoryExpenseModel) onAddTransaction,
  ) async {
    final box = await _openBox();
    final now = DateTime.now();

    for (var recurring in box.values) {
      if (now.day >= recurring.dayOfMonth &&
          (recurring.lastProcessedYear < now.year ||
              recurring.lastProcessedMonth < now.month)) {
        final newTransaction = HistoryExpenseModel(
          id: const Uuid().v4(),
          date: DateTime(now.year, now.month, recurring.dayOfMonth),
          productName: '${recurring.productName} (авто)',
          price: recurring.price,
          categoryId: recurring.categoryId,
          type: recurring.isIncome
              ? TransactionType.income
              : TransactionType.expense,
        );

        onAddTransaction(newTransaction);

        final updated = recurring.copyWith(
          lastProcessedMonth: now.month,
          lastProcessedYear: now.year,
        );
        await updated.save();
      }
    }
  }

  // Добавить новый шаблон
  static Future<void> addRecurring({
    required String productName,
    required double price,
    required String categoryId,
    required bool isIncome,
    required int dayOfMonth,
  }) async {
    final box = await _openBox();

    final item = RecurringExpenseModel(
      id: const Uuid().v4(),
      productName: productName,
      price: price,
      categoryId: categoryId,
      isIncome: isIncome,
      dayOfMonth: dayOfMonth,
      typeName: isIncome ? 'income' : 'expense',
      lastProcessedMonth: 0,
      lastProcessedYear: 0,
    );

    await box.add(item);
  }
}
