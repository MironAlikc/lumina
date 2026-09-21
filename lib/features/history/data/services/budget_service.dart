import 'package:hive/hive.dart';
import 'package:lumina/features/history/data/models/budget_model.dart';
import 'package:uuid/uuid.dart';

class BudgetService {
  static const String boxName = 'budgets_box';

  static Future<Box<BudgetModel>> _openBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return Hive.openBox<BudgetModel>(boxName);
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

    for (final key in box.keys) {
      final existing = box.get(key);
      if (existing == null) continue;
      if (existing.categoryId == categoryId &&
          existing.month == month &&
          existing.year == year) {
        await box.put(key, existing.copyWith(limitAmount: limitAmount));
        return;
      }
    }

    final budget = BudgetModel(
      id: const Uuid().v4(),
      categoryId: categoryId,
      limitAmount: limitAmount,
      month: month,
      year: year,
    );
    await box.put(budget.id, budget);
  }
}
