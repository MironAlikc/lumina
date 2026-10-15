import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lumina/features/accounts/data/models/account_model.dart';
import 'package:lumina/features/budgets/data/models/budget_model.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/goals/data/models/goal_expense_model.dart';
import 'package:lumina/features/recurring/data/models/recurring_expense_model.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';

/// Единственная точка инициализации Hive.
/// Перед вызовом нужен Hive.initFlutter().
///
/// Адаптеры (typeId указан в самих моделях, здесь он только проверяется):
/// TransactionType, HistoryExpenseModel, CustomCategory, GoalExpenseModel,
/// BudgetModel, RecurringExpenseModel, AccountModel.
class HiveClient {
  static const historyBox = 'history_box';
  static const accountsBox = 'accounts_box';
  static const settingsBox = 'settings_box';
  static const categoriesBox = 'categories_box';
  static const goalsBox = 'savings_goals_box';
  static const budgetsBox = 'budgets_box';
  static const recurringBox = 'recurring_expenses_box';

  /// typeId -> тип модели: ловит два адаптера с одним номером.
  static final _adapterOwners = <int, Type>{};

  Future<void> init() async {
    _registerAdapters();

    try {
      // Боксы независимы, открываем параллельно: старт быстрее.
      await Future.wait([
        _openTyped<HistoryExpenseModel>(historyBox),
        _openTyped<AccountModel>(accountsBox),
        _openTyped<CustomCategory>(categoriesBox),
        _openTyped<GoalExpenseModel>(goalsBox),
        _openTyped<BudgetModel>(budgetsBox),
        _openTyped<RecurringExpenseModel>(recurringBox),
        _openUntyped(settingsBox),
      ]);
    } catch (e, st) {
      debugPrint('HiveClient initialization failed: $e\n$st');
      // Закрываем только в памяти: файлы на диске не трогаем.
      await Hive.close();
      rethrow;
    }
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
    final owner = _adapterOwners[adapter.typeId];
    if (owner != null && owner != T) {
      final message =
          'Hive typeId ${adapter.typeId} используют и $owner, и $T. '
          'Запись $T будет падать: дайте моделям разные typeId.';
      if (kDebugMode) throw StateError(message);
      debugPrint(message);
      return;
    }
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter<T>(adapter);
    }
    _adapterOwners[adapter.typeId] = T;
  }

  Future<void> _openTyped<T>(String name) async {
    if (Hive.isBoxOpen(name)) return;
    await Hive.openBox<T>(name);
  }

  Future<void> _openUntyped(String name) async {
    if (Hive.isBoxOpen(name)) return;
    await Hive.openBox<dynamic>(name);
  }
}
