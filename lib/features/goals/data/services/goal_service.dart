import 'package:hive/hive.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/core/utils/money.dart';
import 'package:lumina/features/goals/data/models/goal_expense_model.dart';
import 'package:uuid/uuid.dart';

/// Копилки. Сервис работает только с целями; запись расхода в историю
/// делает вызывающий код через HistoryCubit (см. [depositToGoal]).
abstract final class GoalService {
  static const String boxName = HiveClient.goalsBox;

  /// Категория расходов на пополнение целей.
  static const String goalsCategoryId = 'cat_goals';

  // Бокс открывает HiveClient при старте.
  static Box<GoalExpenseModel> get _box => Hive.box<GoalExpenseModel>(boxName);

  static Future<GoalExpenseModel> addGoal({
    required String title,
    required double targetAmount,
    required String icon,
    required int colorValue,
  }) async {
    final name = title.trim();
    final target = Money.round2(targetAmount);
    if (name.isEmpty || target <= 0) {
      throw ArgumentError('A goal needs a name and a positive target');
    }

    final goal = GoalExpenseModel(
      id: const Uuid().v4(),
      title: name,
      targetAmount: target,
      currentAmount: 0,
      icon: icon,
      colorValue: colorValue,
    );
    await _box.put(goal.id, goal);
    return goal;
  }

  /// Пополняет цель и возвращает фактически внесённую сумму (не больше
  /// остатка до цели; 0, если цель уже достигнута или удалена).
  ///
  /// [recordExpense] записывает расход в историю со счёта пользователя,
  /// например через HistoryCubit.addRecord. Если он бросает исключение,
  /// пополнение цели откатывается, и данные остаются согласованными.
  static Future<double> depositToGoal(
    GoalExpenseModel goal,
    double amount, {
    required Future<void> Function(double applied) recordExpense,
  }) async {
    // Актуальная запись, а не объект с экрана: он мог устареть.
    final current = _box.get(goal.id);
    if (current == null) return 0;

    final value = Money.round2(amount);
    final remaining =
        Money.round2(current.targetAmount - current.currentAmount);
    if (value <= 0 || remaining <= 0) return 0;

    final applied = value > remaining ? remaining : value;

    await _box.put(
      current.id,
      current.copyWith(
        currentAmount: Money.round2(current.currentAmount + applied),
      ),
    );

    try {
      await recordExpense(applied);
    } catch (_) {
      await _box.put(current.id, current); // вернуть прежнюю сумму
      rethrow;
    }
    return applied;
  }

  static Future<void> deleteGoal(GoalExpenseModel goal) => _box.delete(goal.id);
}
