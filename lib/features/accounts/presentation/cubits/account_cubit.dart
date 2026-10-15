import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/features/accounts/data/models/account_model.dart';
import 'package:lumina/features/accounts/presentation/cubits/account_state.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';

/// Бросается, когда счёт нельзя удалить, потому что к нему привязаны операции.
class AccountInUseException implements Exception {
  const AccountInUseException(this.accountId);
  final String accountId;

  @override
  String toString() => 'Account $accountId has transactions';
}

class AccountCubit extends Cubit<AccountState> {
  AccountCubit() : super(const AccountState()) {
    loadAccounts();
  }

  static const _defaultsCreatedKey = 'default_accounts_created';

  Box<AccountModel> get _accountsBox =>
      Hive.box<AccountModel>(HiveClient.accountsBox);

  Box<dynamic> get _settingsBox => Hive.box(HiveClient.settingsBox);

  bool _loading = false;

  /// Округление до копеек, чтобы не копились ошибки double (0.1 + 0.2).
  static double _r2(double v) => (v * 100).round() / 100;

  /// Загрузка счетов. Дефолтные счета создаются один раз за всё время жизни.
  Future<void> loadAccounts() async {
    if (_loading || isClosed) return;
    _loading = true;
    emit(state.copyWith(isLoading: true));
    try {
      if (_accountsBox.isEmpty &&
          _settingsBox.get(_defaultsCreatedKey, defaultValue: false) != true) {
        await _accountsBox.putAll({
          for (final acc in _defaultAccounts()) acc.id: acc,
        });
        await _settingsBox.put(_defaultsCreatedKey, true);
      }

      if (isClosed) return;
      emit(
        state.copyWith(
          accounts: _accountsBox.values.toList(),
          isLoading: false,
        ),
      );
    } catch (e, st) {
      debugPrint('Failed to load accounts: $e\n$st');
      if (!isClosed) {
        emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      }
    } finally {
      _loading = false;
    }
  }

  List<AccountModel> _defaultAccounts() => [
        AccountModel(
          id: 'acc_cash',
          name: 'Cash',
          balance: 0.0,
          iconCode: 'payments',
          colorValue: 0xFFD97706,
        ),
        AccountModel(
          id: 'acc_card',
          name: 'Card',
          balance: 0.0,
          iconCode: 'credit_card',
          colorValue: 0xFF1C1C1E,
        ),
      ];

  /// Добавление нового счёта.
  Future<void> addAccount(AccountModel account) async {
    try {
      await _accountsBox.put(account.id, account.copyWith(isSynced: false));
      _emitAccounts();
    } catch (e, st) {
      debugPrint('addAccount failed: $e\n$st');
      _emitError(e);
      rethrow;
    }
  }

  /// Обновление счёта.
  Future<void> updateAccount(AccountModel account) async {
    try {
      await _accountsBox.put(account.id, account.copyWith(isSynced: false));
      _emitAccounts();
    } catch (e, st) {
      debugPrint('updateAccount failed: $e\n$st');
      _emitError(e);
      rethrow;
    }
  }

  /// Удаление счёта с проверкой на использование в транзакциях.
  Future<void> deleteAccount(String id) async {
    try {
      final historyBox = Hive.box<HistoryExpenseModel>(HiveClient.historyBox);
      final inUse = historyBox.values.any(
        (t) => t.accountId == id || t.targetAccountId == id,
      );
      if (inUse) throw AccountInUseException(id);

      await _accountsBox.delete(id);
      _emitAccounts();
    } on AccountInUseException {
      rethrow;
    } catch (e, st) {
      debugPrint('deleteAccount failed: $e\n$st');
      _emitError(e);
      rethrow;
    }
  }

  /// Расчёт изменения балансов для транзакции. При [reverse] — откат.
  Map<String, double> _deltas(HistoryExpenseModel t, {bool reverse = false}) {
    final k = reverse ? -1.0 : 1.0;
    final src = t.accountId;

    // Если у старой транзакции нет счета, возвращаем пустые дельты во избежание сбоев
    if (src == null) return {};

    return switch (t.type) {
      TransactionType.income => {src: k * t.price},
      TransactionType.expense => {src: -k * t.price},
      TransactionType.transfer => () {
          final dst = t.targetAccountId;
          if (dst == null || dst == src) {
            // Безопасный фоллбек вместо выброса StateError в production
            debugPrint(
                'Warning: Invalid transfer detected for transaction ${t.id}');
            return {src: -k * t.price};
          }
          return {src: -k * t.price, dst: k * t.price};
        }(),
    };
  }

  /// Применяет все изменения одним putAll.
  Future<void> _apply(Map<String, double> deltas) async {
    if (deltas.isEmpty) return;
    final updates = <String, AccountModel>{};
    for (final e in deltas.entries) {
      final acc = _accountsBox.get(e.key);
      if (acc == null) throw StateError('Account ${e.key} not found');
      updates[e.key] = acc.copyWith(
        balance: _r2(acc.balance + e.value),
        isSynced: false,
      );
    }
    await _accountsBox.putAll(updates);
    _emitAccounts();
  }

  /// Новая транзакция: применить к балансам.
  Future<void> processTransaction(HistoryExpenseModel t) => _apply(_deltas(t));

  /// Удаление транзакции: вернуть балансы назад.
  Future<void> rollbackTransaction(HistoryExpenseModel t) =>
      _apply(_deltas(t, reverse: true));

  /// Редактирование: корректный откат старой версии и применение новой.
  Future<void> replaceTransaction(
    HistoryExpenseModel oldT,
    HistoryExpenseModel newT,
  ) {
    final merged = <String, double>{};
    for (final m in [_deltas(oldT, reverse: true), _deltas(newT)]) {
      m.forEach((k, v) => merged[k] = (merged[k] ?? 0) + v);
    }
    return _apply(merged);
  }

  void _emitAccounts() {
    if (isClosed) return;
    emit(
      state.copyWith(
        accounts: _accountsBox.values.toList(),
        isLoading: false,
      ),
    );
  }

  void _emitError(Object e) {
    if (isClosed) return;
    emit(state.copyWith(errorMessage: e.toString()));
  }
}
