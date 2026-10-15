import 'package:flutter/foundation.dart';
import 'package:lumina/features/accounts/data/models/account_model.dart';

@immutable
class AccountState {
  final List<AccountModel> accounts;
  final bool isLoading;
  final String? errorMessage;

  const AccountState({
    this.accounts = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// Общий баланс по всем счетам (сумма балансов каждого счета)
  double get totalBalance {
    return accounts.fold(0.0, (sum, account) => sum + account.balance);
  }

  AccountState copyWith({
    List<AccountModel>? accounts,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AccountState(
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountState &&
        listEquals(other.accounts, accounts) &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(accounts, isLoading, errorMessage);
}
