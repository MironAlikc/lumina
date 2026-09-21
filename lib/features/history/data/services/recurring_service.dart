import 'package:hive/hive.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';
import 'package:lumina/features/history/data/models/recurring_expense_model.dart';
import 'package:uuid/uuid.dart';

class RecurringService {
  static const String boxName = 'recurring_expenses_box';

  static Future<Box<RecurringExpenseModel>> _openBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return Hive.openBox<RecurringExpenseModel>(boxName);
    }
    return Hive.box<RecurringExpenseModel>(boxName);
  }

  static Future<void> checkAndProcessRecurring(
    Future<void> Function(HistoryExpenseModel) onAddTransaction,
  ) async {
    final box = await _openBox();
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;

    for (final recurring in box.values) {
      final alreadyDone =
          recurring.lastProcessedYear > now.year ||
          (recurring.lastProcessedYear == now.year &&
              recurring.lastProcessedMonth >= now.month);
      if (alreadyDone) continue;

      final dueDay = recurring.dayOfMonth.clamp(1, lastDay);
      if (now.day < dueDay) continue;

      final key = recurring.key;
      await onAddTransaction(
        HistoryExpenseModel(
          id: const Uuid().v4(),
          date: DateTime(now.year, now.month, dueDay),
          productName: recurring.productName,
          price: recurring.price,
          categoryId: recurring.categoryId,
          type: recurring.isIncome
              ? TransactionType.income
              : TransactionType.expense,
        ),
      );

      if (key != null) {
        await box.put(
          key,
          recurring.copyWith(
            lastProcessedMonth: now.month,
            lastProcessedYear: now.year,
          ),
        );
      }
    }
  }

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
      dayOfMonth: dayOfMonth.clamp(1, 31),
      typeName: isIncome ? 'income' : 'expense',
      lastProcessedMonth: 0,
      lastProcessedYear: 0,
    );
    await box.put(item.id, item);
  }
}
