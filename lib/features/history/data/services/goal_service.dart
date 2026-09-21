import 'package:hive/hive.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/features/history/data/models/goal_expense_model.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';
import 'package:uuid/uuid.dart';

class GoalService {
  static const String boxName = 'savings_goals_box';
  static const String goalsCategoryId = 'cat_goals';

  static Future<Box<GoalExpenseModel>> _openBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return Hive.openBox<GoalExpenseModel>(boxName);
    }
    return Hive.box<GoalExpenseModel>(boxName);
  }

  static Future<Box<HistoryExpenseModel>> _historyBox() async {
    if (!Hive.isBoxOpen(HiveClient.boxName)) {
      return Hive.openBox<HistoryExpenseModel>(HiveClient.boxName);
    }
    return Hive.box<HistoryExpenseModel>(HiveClient.boxName);
  }

  static Future<void> addGoal({
    required String title,
    required double targetAmount,
    required String icon,
    required int colorValue,
  }) async {
    final box = await _openBox();
    final goal = GoalExpenseModel(
      id: const Uuid().v4(),
      title: title.trim(),
      targetAmount: targetAmount,
      currentAmount: 0,
      icon: icon,
      colorValue: colorValue,
    );
    await box.put(goal.id, goal);
  }

  static Future<double> depositToGoal(
    GoalExpenseModel goal,
    double amount,
  ) async {
    if (amount <= 0) return 0;

    final remaining = goal.targetAmount - goal.currentAmount;
    if (remaining <= 0) return 0;

    final applied = amount > remaining ? remaining : amount;
    final box = await _openBox();
    final key = goal.key ?? goal.id;

    await box.put(
      key,
      goal.copyWith(currentAmount: goal.currentAmount + applied),
    );
    await _writeHistoryExpense(title: goal.title, amount: applied);
    return applied;
  }

  static Future<void> deleteGoal(GoalExpenseModel goal) async {
    final box = await _openBox();
    await box.delete(goal.key ?? goal.id);
  }

  static Future<void> _writeHistoryExpense({
    required String title,
    required double amount,
  }) async {
    final history = await _historyBox();
    final id = const Uuid().v4();
    await history.put(
      id,
      HistoryExpenseModel(
        id: id,
        date: DateTime.now(),
        productName: title,
        price: amount,
        categoryId: goalsCategoryId,
        categoryName: title,
        type: TransactionType.expense,
      ),
    );
  }
}
