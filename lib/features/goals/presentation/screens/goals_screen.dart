import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/core/widgets/lumina_form_dialog.dart';
import 'package:lumina/features/goals/data/models/goal_expense_model.dart';
import 'package:lumina/features/goals/data/services/goal_service.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/l10n/app_localizations.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  Box<GoalExpenseModel>? _box;

  static const _icons = ['🎯', '✈️', '💻', '🚗', '🏠', '🎁'];

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    final box = Hive.isBoxOpen(GoalService.boxName)
        ? Hive.box<GoalExpenseModel>(GoalService.boxName)
        : await Hive.openBox<GoalExpenseModel>(GoalService.boxName);
    if (mounted) setState(() => _box = box);
  }

  NumberFormat _whole(BuildContext context) {
    return NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    )..maximumFractionDigits = 0;
  }

  Future<void> _reloadHistory() async {
    if (!mounted) return;
    await context.read<HistoryCubit>().loadRecords();
  }

  void _close(BuildContext ctx) {
    final nav = Navigator.of(ctx, rootNavigator: true);
    if (nav.canPop()) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final symbol = context.watch<CurrencyCubit>().state.symbol;
    final box = _box;
    final whole = _whole(context);

    return Scaffold(
      backgroundColor: LuminaColors.background,
      appBar: AppBar(
        title: Text(
          loc.goalsTitle,
          style: const TextStyle(
            color: LuminaColors.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: LuminaColors.textMain),
      ),
      body: box == null
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder(
              valueListenable: box.listenable(),
              builder: (context, Box<GoalExpenseModel> goalsBox, _) {
                final goals = goalsBox.values.toList();

                if (goals.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LuminaColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: Text(
                              loc.goalsNew,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _showAddGoalDialog(symbol);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    final progress = goal.targetAmount <= 0
                        ? 0.0
                        : (goal.currentAmount / goal.targetAmount)
                              .clamp(0.0, 1.0)
                              .toDouble();
                    return _GoalCard(
                      goal: goal,
                      progress: progress,
                      symbol: symbol,
                      loc: loc,
                      whole: whole,
                      onDeposit: () => _showDepositDialog(goal, loc, symbol),
                      onDelete: () => _confirmDelete(goal, loc),
                    );
                  },
                );
              },
            ),
      floatingActionButton: box != null && box.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton.extended(
                backgroundColor: LuminaColors.primary,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(
                  loc.goalsNew,
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showAddGoalDialog(symbol);
                },
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _confirmDelete(
    GoalExpenseModel goal,
    AppLocalizations loc,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(loc.goalsDeleteTitle),
        content: Text(loc.goalsDeleteConfirm(goal.title)),
        actions: [
          TextButton(
            onPressed: () => _close(ctx),
            child: Text(loc.goalsCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true),
            child: Text(loc.goalsDelete),
          ),
        ],
      ),
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      await GoalService.deleteGoal(goal);
    }
  }

  void _showDepositDialog(
    GoalExpenseModel goal,
    AppLocalizations loc,
    String symbol,
  ) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => LuminaFormDialog(
        title: loc.goalsDepositTitle(goal.title),
        onClose: () => _close(ctx),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: loc.goalsDepositAmount(symbol),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _close(ctx),
                    child: Text(loc.goalsCancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount =
                          double.tryParse(
                            controller.text.replaceAll(',', '.'),
                          ) ??
                          0;
                      if (amount <= 0) {
                        HapticFeedback.heavyImpact();
                        return;
                      }
                      final applied = await GoalService.depositToGoal(
                        goal,
                        amount,
                      );
                      if (ctx.mounted) _close(ctx);
                      if (applied > 0) await _reloadHistory();
                    },
                    child: Text(loc.goalsDeposit),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  void _showAddGoalDialog(String symbol) {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => _CreateGoalDialog(
        icons: _icons,
        symbol: symbol,
        onClose: () => _close(ctx),
      ),
    );
  }
}

class _CreateGoalDialog extends StatefulWidget {
  const _CreateGoalDialog({
    required this.icons,
    required this.symbol,
    required this.onClose,
  });

  final List<String> icons;
  final String symbol;
  final VoidCallback onClose;

  @override
  State<_CreateGoalDialog> createState() => _CreateGoalDialogState();
}

class _CreateGoalDialogState extends State<_CreateGoalDialog> {
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  late String _selectedIcon;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.icons.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations loc) async {
    final title = _titleController.text.trim();
    final target =
        double.tryParse(_targetController.text.replaceAll(',', '.')) ?? 0;
    if (title.isEmpty || target <= 0) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _saving = true);
    try {
      await GoalService.addGoal(
        title: title,
        targetAmount: target,
        icon: _selectedIcon,
        colorValue: 0xFF4CAF50,
      );
      if (mounted) widget.onClose();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return LuminaFormDialog(
      title: loc.goalsCreateTitle,
      onClose: widget.onClose,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: loc.goalsNameHint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: loc.goalsAmountHint(widget.symbol),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
              for (final icon in widget.icons)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedIcon = icon);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selectedIcon == icon
                          ? LuminaColors.primary.withValues(alpha: 0.2)
                          : LuminaColors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedIcon == icon
                            ? LuminaColors.primary
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(icon, style: const TextStyle(fontSize: 22)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : () => _save(loc),
              style: ElevatedButton.styleFrom(
                backgroundColor: LuminaColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
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

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.progress,
    required this.symbol,
    required this.loc,
    required this.whole,
    required this.onDeposit,
    required this.onDelete,
  });

  final GoalExpenseModel goal;
  final double progress;
  final String symbol;
  final AppLocalizations loc;
  final NumberFormat whole;
  final VoidCallback onDeposit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final done = progress >= 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LuminaColors.surface,
        borderRadius: LuminaDimensions.borderRadiusLarge,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: done ? LuminaColors.success : LuminaColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: LuminaColors.inputFill,
              color: done ? LuminaColors.success : LuminaColors.primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  loc.goalsSaved('${whole.format(goal.currentAmount)} $symbol'),
                  style: const TextStyle(
                    color: LuminaColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                loc.goalsTarget('${whole.format(goal.targetAmount)} $symbol'),
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
