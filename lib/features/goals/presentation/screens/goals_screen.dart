import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/core/utils/money.dart';
import 'package:lumina/core/widgets/lumina_dialog.dart';
import 'package:lumina/features/accounts/presentation/cubits/account_cubit.dart';
import 'package:lumina/features/goals/data/models/goal_expense_model.dart';
import 'package:lumina/features/goals/data/services/goal_service.dart';
import 'package:lumina/features/receipts/presentation/widgets/receipt_account_picker.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';
import 'package:lumina/features/transactions/domain/entities/history_expense.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

const _icons = ['🎯', '✈️', '💻', '🚗', '🏠', '🎁'];

typedef _NewGoal = ({String title, double target, String icon});
typedef _DepositInput = ({double amount, String? accountId});

bool _isDone(GoalExpenseModel g) => g.currentAmount >= g.targetAmount;

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  Future<void> _create(BuildContext context, String symbol) async {
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;

    final input = await showLuminaDialog<_NewGoal>(
      context: context,
      child: _CreateGoalDialog(symbol: symbol),
    );
    if (input == null) return;

    try {
      await GoalService.addGoal(
        title: input.title,
        targetAmount: input.target,
        icon: input.icon,
        colorValue: LuminaColors.primary.toARGB32(),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(loc.saveFailed)));
    }
  }

  Future<void> _deposit(
    BuildContext context,
    GoalExpenseModel goal,
    String symbol,
  ) async {
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;
    final history = context.read<HistoryCubit>();

    final input = await showLuminaDialog<_DepositInput>(
      context: context,
      child: _DepositDialog(goal: goal, symbol: symbol),
    );
    if (input == null) return;

    try {
      // Расход со счёта записывается через HistoryCubit: баланс счёта
      // обновляется. Если запись не удалась, цель откатывается сервисом.
      await GoalService.depositToGoal(
        goal,
        input.amount,
        recordExpense: (applied) => history.addRecord(
          HistoryExpense(
            id: const Uuid().v4(),
            date: DateTime.now(),
            productName: goal.title,
            price: applied,
            category: GoalService.goalsCategoryId,
            type: 'expense',
            isSynced: false,
            accountId: input.accountId,
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(loc.saveFailed)));
    }
  }

  Future<void> _delete(BuildContext context, GoalExpenseModel goal) async {
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;

    final confirmed = await showLuminaDialog<bool>(
      context: context,
      child: _DeleteGoalDialog(title: goal.title),
    );
    if (confirmed != true) return;

    HapticFeedback.mediumImpact();
    try {
      await GoalService.deleteGoal(goal);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(loc.saveFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final symbol = context.watch<CurrencyCubit>().state.symbol;

    return Scaffold(
      backgroundColor: LuminaColors.background,
      appBar: AppBar(title: Text(loc.goalsTitle)),
      // Бокс открывает HiveClient при старте.
      body: ValueListenableBuilder<Box<GoalExpenseModel>>(
        valueListenable:
            Hive.box<GoalExpenseModel>(GoalService.boxName).listenable(),
        builder: (context, box, _) {
          // Порядок ключей в Hive случайный (UUID): сортируем явно.
          final goals = box.values.toList()
            ..sort((a, b) {
              final byDone =
                  _isDone(a) == _isDone(b) ? 0 : (_isDone(a) ? 1 : -1);
              return byDone != 0
                  ? byDone
                  : a.title.toLowerCase().compareTo(b.title.toLowerCase());
            });

          if (goals.isEmpty) {
            return _EmptyState(onCreate: () => _create(context, symbol));
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              return _GoalCard(
                key: ValueKey(goal.id),
                goal: goal,
                symbol: symbol,
                onDeposit: () => _deposit(context, goal, symbol),
                onDelete: () => _delete(context, goal),
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ValueListenableBuilder<Box<GoalExpenseModel>>(
        valueListenable:
            Hive.box<GoalExpenseModel>(GoalService.boxName).listenable(),
        builder: (context, box, _) => box.isEmpty
            ? const SizedBox.shrink()
            : FloatingActionButton.extended(
                backgroundColor: LuminaColors.primary,
                foregroundColor: Colors.white,
                onPressed: () => _create(context, symbol),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  loc.goalsNew,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 54)),
            const SizedBox(height: 16),
            Text(
              loc.goalsEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: LuminaColors.textSecondary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                loc.goalsNew,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    super.key,
    required this.goal,
    required this.symbol,
    required this.onDeposit,
    required this.onDelete,
  });

  final GoalExpenseModel goal;
  final String symbol;
  final VoidCallback onDeposit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    final done = _isDone(goal);
    final progress = goal.targetAmount <= 0
        ? 0.0
        : (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
    final color = done ? LuminaColors.success : LuminaColors.primary;
    // floor: 99,6% не должно выглядеть как «100%».
    final percent = done ? 100 : (progress * 100).floor();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LuminaColors.surface,
        borderRadius: LuminaDimensions.borderRadiusLarge,
        boxShadow: LuminaTheme.premiumShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(goal.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  goal.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: LuminaColors.textMain,
                  ),
                ),
              ),
              if (done)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: LuminaColors.success,
                  ),
                ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: LuminaColors.inputFill,
                color: color,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  loc.goalsSaved(
                    Money.format(goal.currentAmount, locale, symbol: symbol),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LuminaColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                loc.goalsTarget(
                  Money.format(goal.targetAmount, locale, symbol: symbol),
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: LuminaColors.textMain,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: done ? null : onDeposit,
                  child: Text(loc.goalsTopUp),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: loc.goalsDelete,
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: LuminaColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- dialogs

class _CreateGoalDialog extends StatefulWidget {
  const _CreateGoalDialog({required this.symbol});

  final String symbol;

  @override
  State<_CreateGoalDialog> createState() => _CreateGoalDialogState();
}

class _CreateGoalDialogState extends State<_CreateGoalDialog> {
  final _title = TextEditingController();
  final _target = TextEditingController();
  String _icon = _icons.first;
  bool _titleError = false;
  bool _targetError = false;

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    final target = Money.parse(_target.text);

    setState(() {
      _titleError = title.isEmpty;
      _targetError = target == null || target <= 0;
    });
    if (_titleError || _targetError) {
      HapticFeedback.heavyImpact();
      return;
    }
    Navigator.of(context).pop<_NewGoal>(
      (title: title, target: target!, icon: _icon),
    );
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
            loc.goalsCreateTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: LuminaColors.textMain,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_titleError) setState(() => _titleError = false);
            },
            decoration: InputDecoration(
              labelText: loc.goalsNameHint,
              counterText: '',
              errorText: _titleError ? loc.accountNameRequired : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
            ],
            onChanged: (_) {
              if (_targetError) setState(() => _targetError = false);
            },
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: loc.goalsAmountHint(widget.symbol),
              errorText: _targetError ? loc.amountRequired : null,
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
              for (final icon in _icons)
                _IconChoice(
                  icon: icon,
                  selected: _icon == icon,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _icon = icon);
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: LuminaDimensions.buttonHeight,
            child: ElevatedButton(
              onPressed: _submit,
              child: Text(
                loc.goalsCreate,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: icon,
      child: Material(
        color: selected
            ? LuminaColors.primary.withValues(alpha: 0.2)
            : LuminaColors.inputFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? LuminaColors.primary : Colors.transparent,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
        ),
      ),
    );
  }
}

class _DepositDialog extends StatefulWidget {
  const _DepositDialog({required this.goal, required this.symbol});

  final GoalExpenseModel goal;
  final String symbol;

  @override
  State<_DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends State<_DepositDialog> {
  final _amount = TextEditingController();
  String? _accountId;
  bool _error = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit(String? accountId) {
    final value = Money.parse(_amount.text);
    if (value == null || value <= 0) {
      HapticFeedback.heavyImpact();
      setState(() => _error = true);
      return;
    }
    Navigator.of(context).pop<_DepositInput>(
      (amount: value, accountId: accountId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final accounts = context.watch<AccountCubit>().state.accounts;
    final accountId = ReceiptAccountPicker.resolve(accounts, _accountId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.goalsDepositTitle(widget.goal.title),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: LuminaColors.textMain,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
            ],
            onChanged: (_) {
              if (_error) setState(() => _error = false);
            },
            onSubmitted: (_) => _submit(accountId),
            decoration: InputDecoration(
              labelText: loc.goalsDepositAmount(widget.symbol),
              errorText: _error ? loc.amountRequired : null,
            ),
          ),
          if (accounts.isNotEmpty) ...[
            const SizedBox(height: 12),
            ReceiptAccountPicker(
              accounts: accounts,
              value: accountId,
              onChanged: (id) => setState(() => _accountId = id),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(loc.goalsCancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _submit(accountId),
                  child: Text(loc.goalsDeposit),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeleteGoalDialog extends StatelessWidget {
  const _DeleteGoalDialog({required this.title});

  final String title;

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
            loc.goalsDeleteTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: LuminaColors.textMain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            loc.goalsDeleteConfirm(title),
            style: const TextStyle(color: LuminaColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(loc.goalsCancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LuminaColors.error,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(loc.goalsDelete),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
