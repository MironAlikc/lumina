import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/core/widgets/lumina_dialog.dart';
import 'package:lumina/features/accounts/data/models/account_model.dart';
import 'package:lumina/features/accounts/presentation/cubits/account_cubit.dart';
import 'package:lumina/features/accounts/presentation/cubits/account_state.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';
import 'package:lumina/features/transactions/domain/entities/history_expense.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

const _accountIcons = <String, IconData>{
  'credit_card': Icons.credit_card_rounded,
  'account_balance': Icons.account_balance_rounded,
  'payments': Icons.payments_rounded,
  'wallet': Icons.account_balance_wallet_rounded,
  'savings': Icons.savings_rounded,
};

const _accountColors = <int>[
  0xFF0D9488,
  0xFF1C1C1E,
  0xFF16A34A,
  0xFFD97706,
  0xFF2563EB,
  0xFF7C3AED,
  0xFFDB2777,
  0xFFEF4444,
];

IconData _iconFor(String code) =>
    _accountIcons[code] ?? Icons.account_balance_wallet_rounded;

String _money(double value, String locale, String symbol) {
  final text = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: 2,
  ).format(value);
  return '$text $symbol';
}

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AccountsView();
}

class _AccountsView extends StatelessWidget {
  const _AccountsView();

  Future<void> _add(BuildContext context) async {
    final cubit = context.read<AccountCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;

    final result = await showLuminaDialog<AccountModel>(
      context: context,
      child: const _AccountEditorDialog(),
    );
    if (result == null) return;

    try {
      await cubit.addAccount(result);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(loc.accountSaveFailed)));
    }
  }

  Future<void> _edit(BuildContext context, AccountModel account) async {
    final cubit = context.read<AccountCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;

    final result = await showLuminaDialog<AccountModel>(
      context: context,
      child: _AccountEditorDialog(account: account),
    );
    if (result == null) return;

    try {
      await cubit.updateAccount(result);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(loc.accountSaveFailed)));
    }
  }

  Future<void> _quickTransfer(
    BuildContext context,
    AccountModel sourceAccount,
    List<AccountModel> allAccounts,
  ) async {
    final historyCubit = context.read<HistoryCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;

    final transferData = await showLuminaDialog<_TransferResult>(
      context: context,
      child: _QuickTransferDialog(
        sourceAccount: sourceAccount,
        accounts: allAccounts,
      ),
    );

    if (transferData == null) return;

    final expense = HistoryExpense(
      id: const Uuid().v4(),
      date: DateTime.now(),
      productName: loc.transfer,
      price: transferData.amount,
      category: 'cat_transfer',
      type: 'transfer',
      isSynced: false,
      accountId: sourceAccount.id,
      targetAccountId: transferData.targetAccountId,
    );

    try {
      await historyCubit.addRecord(expense);
      messenger.showSnackBar(
        SnackBar(content: Text(loc.save)),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(loc.saveFailed)));
    }
  }

  Future<void> _delete(BuildContext context, AccountModel account) async {
    final cubit = context.read<AccountCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;

    final confirmed = await showLuminaDialog<bool>(
      context: context,
      child: _ConfirmDeleteDialog(name: account.name),
    );
    if (confirmed != true) return;

    try {
      await cubit.deleteAccount(account.id);
    } on AccountInUseException {
      messenger.showSnackBar(SnackBar(content: Text(loc.accountInUse)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(loc.accountSaveFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final symbol = context.watch<CurrencyCubit>().state.symbol;

    return Scaffold(
      backgroundColor: LuminaColors.background,
      appBar: AppBar(title: Text(loc.myAccounts)),
      body: BlocBuilder<AccountCubit, AccountState>(
        builder: (context, state) {
          if (state.isLoading && state.accounts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: LuminaColors.cardMint,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: LuminaColors.cardMintBorder),
                  boxShadow: LuminaTheme.premiumShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.accountsTotalBalance,
                      style: const TextStyle(
                        color: LuminaColors.accentDeep,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _money(state.totalBalance, locale, symbol),
                        style: const TextStyle(
                          color: LuminaColors.textMain,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                loc.accountsSectionTitle,
                style: const TextStyle(
                  color: LuminaColors.textMain,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (state.accounts.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      loc.noAccounts,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: LuminaColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              else
                for (final account in state.accounts)
                  _AccountCard(
                    account: account,
                    amountText: _money(account.balance, locale, symbol),
                    onEdit: () => _edit(context, account),
                    onTransfer: state.accounts.length > 1
                        ? () => _quickTransfer(context, account, state.accounts)
                        : null,
                    onDelete: () => _delete(context, account),
                  ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: loc.newAccount,
        backgroundColor: LuminaColors.accent,
        foregroundColor: Colors.white,
        onPressed: () => _add(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

enum _AccountAction { edit, transfer, delete }

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.amountText,
    required this.onEdit,
    this.onTransfer,
    required this.onDelete,
  });

  final AccountModel account;
  final String amountText;
  final VoidCallback onEdit;
  final VoidCallback? onTransfer;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final color = Color(account.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      decoration: BoxDecoration(
        color: LuminaColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: LuminaTheme.premiumShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconFor(account.iconCode), color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              account.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LuminaColors.textMain,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            style: TextStyle(
              color: account.balance < 0
                  ? LuminaColors.error
                  : LuminaColors.textMain,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          PopupMenuButton<_AccountAction>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: LuminaColors.textSecondary,
            ),
            onSelected: (action) => switch (action) {
              _AccountAction.edit => onEdit(),
              _AccountAction.transfer => onTransfer?.call(),
              _AccountAction.delete => onDelete(),
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _AccountAction.edit,
                child: Text(loc.change),
              ),
              if (onTransfer != null)
                PopupMenuItem(
                  value: _AccountAction.transfer,
                  child: Text(loc.transfer),
                ),
              PopupMenuItem(
                value: _AccountAction.delete,
                child: Text(
                  loc.delete,
                  style: const TextStyle(color: LuminaColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransferResult {
  const _TransferResult({
    required this.targetAccountId,
    required this.amount,
  });

  final String targetAccountId;
  final double amount;
}

class _QuickTransferDialog extends StatefulWidget {
  const _QuickTransferDialog({
    required this.sourceAccount,
    required this.accounts,
  });

  final AccountModel sourceAccount;
  final List<AccountModel> accounts;

  @override
  State<_QuickTransferDialog> createState() => _QuickTransferDialogState();
}

class _QuickTransferDialogState extends State<_QuickTransferDialog> {
  late final TextEditingController _amountController;
  late String _targetAccountId;
  bool _amountError = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    final targets =
        widget.accounts.where((a) => a.id != widget.sourceAccount.id);
    _targetAccountId = targets.first.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(raw);

    setState(() => _amountError = amount == null || amount <= 0);
    if (amount == null || amount <= 0) return;

    Navigator.of(context).pop(
      _TransferResult(
        targetAccountId: _targetAccountId,
        amount: amount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final targets =
        widget.accounts.where((a) => a.id != widget.sourceAccount.id).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${loc.transfer}: ${widget.sourceAccount.name}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: LuminaColors.textMain,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue:
                _targetAccountId, // Исправлено с value на initialValue
            decoration: InputDecoration(
              labelText: loc.targetAccountLabel,
            ),
            items: [
              for (final target in targets)
                DropdownMenuItem(
                  value: target.id,
                  child: Text(target.name),
                ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _targetAccountId = val);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: loc.amountLabel,
              errorText: _amountError ? loc.amountRequired : null,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(loc.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(loc.done),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountEditorDialog extends StatefulWidget {
  const _AccountEditorDialog({this.account});

  final AccountModel? account;

  @override
  State<_AccountEditorDialog> createState() => _AccountEditorDialogState();
}

class _AccountEditorDialogState extends State<_AccountEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late String _iconCode;
  late int _colorValue;
  bool _nameError = false;
  bool _balanceError = false;

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _nameController = TextEditingController(text: account?.name ?? '');
    _balanceController = TextEditingController(
      text: account == null || account.balance == 0
          ? ''
          : account.balance.toString(),
    );
    _iconCode = account?.iconCode ?? 'credit_card';
    _colorValue = account?.colorValue ?? _accountColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final rawBalance = _balanceController.text.trim().replaceAll(',', '.');
    final balance = rawBalance.isEmpty ? 0.0 : double.tryParse(rawBalance);

    setState(() {
      _nameError = name.isEmpty;
      _balanceError = balance == null;
    });
    if (name.isEmpty || balance == null) return;

    final existing = widget.account;
    final result = existing == null
        ? AccountModel(
            id: 'acc_${const Uuid().v4()}',
            name: name,
            balance: balance,
            iconCode: _iconCode,
            colorValue: _colorValue,
          )
        : existing.copyWith(
            name: name,
            balance: balance,
            iconCode: _iconCode,
            colorValue: _colorValue,
          );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditing ? loc.editAccount : loc.newAccount,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: LuminaColors.textMain,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            maxLength: 30,
            decoration: InputDecoration(
              labelText: loc.accountName,
              counterText: '',
              errorText: _nameError ? loc.accountNameRequired : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _balanceController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: InputDecoration(
              labelText: loc.accountBalance,
              errorText: _balanceError ? loc.invalidNumber : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loc.goalsIconLabel,
            style: const TextStyle(color: LuminaColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in _accountIcons.entries)
                _Choice(
                  selected: _iconCode == entry.key,
                  onTap: () => setState(() => _iconCode = entry.key),
                  child: Icon(
                    entry.value,
                    size: 22,
                    color: _iconCode == entry.key
                        ? Colors.white
                        : LuminaColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            loc.colorLabel,
            style: const TextStyle(color: LuminaColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in _accountColors)
                _Choice(
                  selected: _colorValue == value,
                  fill: Color(value),
                  onTap: () => setState(() => _colorValue = value),
                  child: _colorValue == value
                      ? const Icon(Icons.check_rounded,
                          size: 20, color: Colors.white)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(loc.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isEditing ? loc.save : loc.create),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.selected,
    required this.onTap,
    this.fill,
    this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Color? fill;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final background =
        fill ?? (selected ? LuminaColors.accent : LuminaColors.inputFill);

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? LuminaColors.textMain : Colors.transparent,
              width: 2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ConfirmDeleteDialog extends StatelessWidget {
  const _ConfirmDeleteDialog({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.deleteAccountTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: LuminaColors.textMain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            loc.deleteAccountConfirm(name),
            style: const TextStyle(color: LuminaColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(loc.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LuminaColors.error,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(loc.delete),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
