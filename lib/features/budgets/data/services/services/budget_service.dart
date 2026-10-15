import 'package:hive/hive.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/core/utils/money.dart';
import 'package:lumina/features/budgets/data/models/budget_model.dart';
import 'package:uuid/uuid.dart';

/// Лимиты по категориям на месяц. Бокс открывает HiveClient при старте.
class BudgetService {
  BudgetService._();

  static const String boxName = HiveClient.budgetsBox;

  static Box<BudgetModel> get _box => Hive.box<BudgetModel>(boxName);

  static BudgetModel? find({
    required String categoryId,
    required int month,
    required int year,
  }) {
    for (final b in _box.values) {
      if (b.categoryId == categoryId && b.month == month && b.year == year) {
        return b;
      }
    }
    return null;
  }

  /// Создаёт лимит или обновляет существующий для той же категории и месяца.
  static Future<void> setBudget({
    required String categoryId,
    required double limitAmount,
    required int month,
    required int year,
  }) async {
    final limit = Money.round2(limitAmount);
    if (limit <= 0 || month < 1 || month > 12 || categoryId.isEmpty) {
      throw ArgumentError('Invalid budget');
    }

    final existing = find(categoryId: categoryId, month: month, year: year);
    if (existing != null) {
      await _box.put(existing.id, existing.copyWith(limitAmount: limit));
      return;
    }

    final budget = BudgetModel(
      id: const Uuid().v4(),
      categoryId: categoryId,
      limitAmount: limit,
      month: month,
      year: year,
    );
    await _box.put(budget.id, budget);
  }

  static Future<void> delete(String id) => _box.delete(id);

  /// Возвращает удалённый лимит (для «Отменить»).
  static Future<void> restore(BudgetModel budget) =>
      _box.put(budget.id, budget);

  /// Копирует лимиты предыдущего месяца в выбранный. Уже заданные категории
  /// не перезаписываются. Возвращает число скопированных лимитов.
  static Future<int> copyFromPreviousMonth({
    required int month,
    required int year,
  }) async {
    final prev = DateTime(year, month - 1);
    final additions = <String, BudgetModel>{};

    for (final b in _box.values) {
      if (b.month != prev.month || b.year != prev.year) continue;
      if (find(categoryId: b.categoryId, month: month, year: year) != null) {
        continue;
      }
      final copy = BudgetModel(
        id: const Uuid().v4(),
        categoryId: b.categoryId,
        limitAmount: b.limitAmount,
        month: month,
        year: year,
      );
      additions[copy.id] = copy;
    }

    if (additions.isNotEmpty) await _box.putAll(additions);
    return additions.length;
  }
}
