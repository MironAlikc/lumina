import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lumina/features/accounts/data/models/account_model.dart';
import 'package:lumina/features/budgets/data/models/budget_model.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/goals/data/models/goal_expense_model.dart';
import 'package:lumina/features/recurring/data/models/recurring_expense_model.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';

/// Единственная точка Hive.
///
/// typeId:
/// 0 TransactionType
/// 1 HistoryExpenseModel
/// 2 CustomCategory
/// 3 GoalExpenseModel
/// 4 BudgetModel
/// 5 RecurringExpenseModel
/// 6 AccountModel
class HiveClient {
  static const historyBox = 'history_box';
  static const accountsBox = 'accounts_box';
  static const settingsBox = 'settings_box';
  static const categoriesBox = 'categories_box';
  static const goalsBox = 'savings_goals_box';
  static const budgetsBox = 'budgets_box';
  static const recurringBox = 'recurring_expenses_box';

  /// Старое имя. Не удалять — HistoryRepositoryImpl на него ссылается.
  static const String boxName = historyBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _registerAdapters();
    await Future.wait([
      _openTyped<HistoryExpenseModel>(historyBox),
      _openTyped<AccountModel>(accountsBox),
      _openTyped<CustomCategory>(categoriesBox),
      _openTyped<GoalExpenseModel>(goalsBox),
      _openTyped<BudgetModel>(budgetsBox),
      _openTyped<RecurringExpenseModel>(recurringBox),
      _openUntyped(settingsBox),
    ]);
  }

  void _registerAdapters() {
    _register(TransactionTypeAdapter());
    _register(HistoryExpenseModelAdapter());
    _register(CustomCategoryAdapter());
    _register(GoalExpenseModelAdapter());
    _register(BudgetModelAdapter());
    _register(RecurringExpenseModelAdapter());
    _register(AccountModelAdapter());
  }

  void _register<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter<T>(adapter);
    }
  }

  Future<void> _openTyped<T>(String name) async {
    if (Hive.isBoxOpen(name)) return;
    try {
      await Hive.openBox<T>(name);
    } catch (e) {
      debugPrint('Typed $name open failed: $e');
      try {
        final raw = await Hive.openBox(name);
        final recovered = <dynamic, T>{};
        for (final entry in raw.toMap().entries) {
          final value = entry.value;
          if (value is T) recovered[entry.key] = value;
        }
        await raw.close();
        await Hive.deleteBoxFromDisk(name);
        final box = await Hive.openBox<T>(name);
        if (recovered.isNotEmpty) await box.putAll(recovered);
      } catch (e2, st) {
        debugPrint('$name recovery failed: $e2\n$st');
        await Hive.deleteBoxFromDisk(name);
        await Hive.openBox<T>(name);
      }
    }
  }

  Future<void> _openUntyped(String name) async {
    try {
      if (!Hive.isBoxOpen(name)) await Hive.openBox(name);
    } catch (e, st) {
      debugPrint('$name damaged, recreating: $e\n$st');
      await Hive.deleteBoxFromDisk(name);
      await Hive.openBox(name);
    }
  }
}
