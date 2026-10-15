import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/core/utils/money.dart';
import 'package:lumina/features/recurring/data/models/recurring_expense_model.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';
import 'package:uuid/uuid.dart';

abstract final class RecurringService {
  static const String boxName = HiveClient.recurringBox;

  /// Сколько пропущенных месяцев догонять максимум.
  static const _maxCatchUpMonths = 12;

  static bool _running = false;

  // Бокс открывает HiveClient при старте.
  static Box<RecurringExpenseModel> get _box =>
      Hive.box<RecurringExpenseModel>(boxName);

  /// Детерминированный id операции для шаблона и месяца (UUID v5).
  /// Повторная попытка даёт тот же id, поэтому дубль невозможен.
  static String transactionId(String recurringId, int year, int month) {
    return const Uuid()
        .v5(Namespace.url.value, 'lumina:$recurringId:$year-$month');
  }

  // ------------------------------------------------------------- processing

  /// Проводит наступившие платежи, включая пропущенные месяцы. Платёж
  /// помечается обработанным только после успеха.
  static Future<void> checkAndProcessRecurring(
    Future<void> Function(HistoryExpenseModel) onAddTransaction,
  ) async {
    if (_running) return;
    _running = true;
    try {
      final history = Hive.isBoxOpen(HiveClient.historyBox)
          ? Hive.box<HistoryExpenseModel>(HiveClient.historyBox)
          : null;
      final now = DateTime.now();

      // toList(): бокс изменяется внутри цикла.
      for (final recurring in _box.values.toList()) {
        await _processTemplate(
          history: history,
          recurring: recurring,
          now: now,
          onAddTransaction: onAddTransaction,
        );
      }
    } catch (e, st) {
      debugPrint('Error checking recurring payments: $e\n$st');
    } finally {
      _running = false;
    }
  }

  static List<(int, int)> _dueMonths(RecurringExpenseModel r, DateTime now) {
    int year;
    int month;
    if (r.lastProcessedYear <= 0 || r.lastProcessedMonth <= 0) {
      // Новый шаблон: только текущий месяц.
      year = now.year;
      month = now.month;
    } else {
      year = r.lastProcessedYear;
      month = r.lastProcessedMonth + 1;
      if (month > 12) {
        month = 1;
        year++;
      }
    }

    final months = <(int, int)>[];
    while (year < now.year || (year == now.year && month <= now.month)) {
      months.add((year, month));
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }
    return months.length > _maxCatchUpMonths
        ? months.sublist(months.length - _maxCatchUpMonths)
        : months;
  }

  static Future<void> _processTemplate({
    required Box<HistoryExpenseModel>? history,
    required RecurringExpenseModel recurring,
    required DateTime now,
    required Future<void> Function(HistoryExpenseModel) onAddTransaction,
  }) async {
    for (final (year, month) in _dueMonths(recurring, now)) {
      final lastDay = DateTime(year, month + 1, 0).day;
      final dueDay = recurring.dayOfMonth.clamp(1, lastDay);

      // Срок в текущем месяце ещё не наступил.
      if (year == now.year && month == now.month && now.day < dueDay) break;

      final id = transactionId(recurring.id, year, month);

      try {
        // Запись уже есть (сбой между созданием и отметкой): повторно не
        // создаём, иначе баланс счёта применился бы дважды.
        if (history == null || !history.containsKey(id)) {
          await onAddTransaction(
            HistoryExpenseModel(
              id: id,
              date: DateTime(year, month, dueDay),
              productName: recurring.productName,
              price: recurring.price,
              categoryId: recurring.categoryId,
              type: recurring.isIncome
                  ? TransactionType.income
                  : TransactionType.expense,
              accountId: recurring.accountId,
            ),
          );
        }

        // Актуальная версия: шаблон могли изменить или удалить.
        final current = _box.get(recurring.id);
        if (current == null) return;
        await _box.put(
          current.id,
          current.copyWith(lastProcessedMonth: month, lastProcessedYear: year),
        );
      } catch (e, st) {
        debugPrint(
          'Recurring ${recurring.id} failed for $year-$month: $e\n$st',
        );
        return; // повторится при следующей проверке
      }
    }
  }

  // ------------------------------------------------------------------- CRUD

  static void _validate(String name, double amount) {
    if (name.isEmpty || amount <= 0) {
      throw ArgumentError('Recurring payment needs a name and positive amount');
    }
  }

  static Future<void> addRecurring({
    required String productName,
    required double price,
    required String categoryId,
    required bool isIncome,
    required int dayOfMonth,
    String? accountId,
  }) async {
    final name = productName.trim();
    final amount = Money.round2(price);
    _validate(name, amount);

    final item = RecurringExpenseModel(
      id: const Uuid().v4(),
      productName: name,
      price: amount,
      categoryId: categoryId,
      isIncome: isIncome,
      dayOfMonth: dayOfMonth.clamp(1, 31),
      typeName: isIncome ? 'income' : 'expense',
      lastProcessedMonth: 0,
      lastProcessedYear: 0,
      accountId: accountId,
    );
    await _box.put(item.id, item);
  }

  /// Изменяет шаблон. Уже проведённые месяцы не пересчитываются.
  static Future<void> update({
    required String id,
    required String productName,
    required double price,
    required String categoryId,
    required bool isIncome,
    required int dayOfMonth,
    String? accountId,
  }) async {
    final existing = _box.get(id);
    if (existing == null) return;

    final name = productName.trim();
    final amount = Money.round2(price);
    _validate(name, amount);

    // Новый объект: copyWith не умеет сбрасывать accountId в null.
    await _box.put(
      id,
      RecurringExpenseModel(
        id: id,
        productName: name,
        price: amount,
        categoryId: categoryId,
        isIncome: isIncome,
        dayOfMonth: dayOfMonth.clamp(1, 31),
        typeName: isIncome ? 'income' : 'expense',
        lastProcessedMonth: existing.lastProcessedMonth,
        lastProcessedYear: existing.lastProcessedYear,
        accountId: accountId,
      ),
    );
  }

  static Future<void> delete(String id) => _box.delete(id);

  /// Возвращает удалённый шаблон («Отменить»).
  static Future<void> restore(RecurringExpenseModel item) =>
      _box.put(item.id, item);
}
