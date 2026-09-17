import 'package:hive/hive.dart';
import '../models/budget_model.dart';
import 'package:uuid/uuid.dart';

class BudgetService {
  static const String boxName = 'budgets_box';

  static Future<Box<BudgetModel>> _openBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<BudgetModel>(boxName);
    }
    return Hive.box<BudgetModel>(boxName);
  }

  static Future<void> setBudget({
    required String categoryId,
    required double limitAmount,
    required int month,
    required int year,
  }) async {
    final box = await _openBox();

    // Проверяем, есть ли уже лимит на эту категорию в текущем месяце
    final existingIndex = box.values.toList().indexWhere(
      (b) => b.categoryId == categoryId && b.month == month && b.year == year,
    );

    if (existingIndex != -1) {
      final existingBudget = box.getAt(existingIndex);
      if (existingBudget != null) {
        final updated = existingBudget.copyWith(limitAmount: limitAmount);
        await updated.save();
        return;
      }
    }

    // Если нет, создаем новый
    final newBudget = BudgetModel(
      id: const Uuid().v4(),
      categoryId: categoryId,
      limitAmount: limitAmount,
      month: month,
      year: year,
    );
    await box.add(newBudget);
  }
}
