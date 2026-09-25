import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/features/accounts/data/models/account_model.dart';
import 'package:lumina/features/accounts/presentation/cubits/account_state.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';

class AccountCubit extends Cubit<AccountState> {
  AccountCubit() : super(const AccountState()) {
    loadAccounts();
  }

  Box<AccountModel> get _accountsBox =>
      Hive.box<AccountModel>(HiveClient.accountsBox);

  /// Загрузка счетов из Hive. Если счетов нет — создаем дефолтные.
  Future<void> loadAccounts() async {
    emit(state.copyWith(isLoading: true));
    try {
      var accountsList = _accountsBox.values.toList();

      if (accountsList.isEmpty) {
        final defaultAccounts = [
          AccountModel(
            id: 'acc_mono',
            name: 'Monobank',
            balance: 0.0,
            iconCode: 'credit_card',
            colorValue: 0xFF1C1C1E,
          ),
          AccountModel(
            id: 'acc_privat',
            name: 'PrivatBank',
            balance: 0.0,
            iconCode: 'account_balance',
            colorValue: 0xFF16A34A,
          ),
          AccountModel(
            id: 'acc_cash',
            name: 'Наличные',
            balance: 0.0,
            iconCode: 'payments',
            colorValue: 0xFFD97706,
          ),
        ];

        for (var acc in defaultAccounts) {
          await _accountsBox.put(acc.id, acc);
        }
        accountsList = _accountsBox.values.toList();
      }

      emit(state.copyWith(accounts: accountsList, isLoading: false));
    } catch (e, st) {
      debugPrint('Failed to load accounts: $e\n$st');
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  /// Добавление нового счета
  Future<void> addAccount(AccountModel account) async {
    try {
      await _accountsBox.put(account.id, account);
      emit(state.copyWith(accounts: _accountsBox.values.toList()));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  /// Обновление счета
  Future<void> updateAccount(AccountModel account) async {
    try {
      await _accountsBox.put(account.id, account);
      emit(state.copyWith(accounts: _accountsBox.values.toList()));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  /// Удаление счета
  Future<void> deleteAccount(String id) async {
    try {
      await _accountsBox.delete(id);
      emit(state.copyWith(accounts: _accountsBox.values.toList()));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  /// Обработка транзакции (Доход, Расход, Перевод) с изменением баланса счетов
  Future<void> processTransaction(HistoryExpenseModel transaction) async {
    try {
      final accountId = transaction.accountId;
      if (accountId == null) return;

      final account = _accountsBox.get(accountId);
      if (account == null) return;

      double newBalance = account.balance;

      if (transaction.type == TransactionType.income) {
        newBalance += transaction.price;
        await _accountsBox.put(
          accountId,
          account.copyWith(balance: newBalance),
        );
      } else if (transaction.type == TransactionType.expense) {
        newBalance -= transaction.price;
        await _accountsBox.put(
          accountId,
          account.copyWith(balance: newBalance),
        );
      } else if (transaction.type == TransactionType.transfer) {
        final targetId = transaction.targetAccountId;
        if (targetId != null) {
          final targetAccount = _accountsBox.get(targetId);
          if (targetAccount != null) {
            // Снимаем со счета-источника
            newBalance -= transaction.price;
            await _accountsBox.put(
              accountId,
              account.copyWith(balance: newBalance),
            );

            // Зачисляем на целевой счет
            final targetNewBalance = targetAccount.balance + transaction.price;
            await _accountsBox.put(
              targetId,
              targetAccount.copyWith(balance: targetNewBalance),
            );
          }
        }
      }

      emit(state.copyWith(accounts: _accountsBox.values.toList()));
    } catch (e) {
      debugPrint('Error processing transaction for accounts: $e');
    }
  }
}
