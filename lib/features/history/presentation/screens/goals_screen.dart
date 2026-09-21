import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/features/history/data/models/goal_expense_model.dart';
import 'package:lumina/features/history/data/services/goal_service.dart';
import 'package:lumina/features/history/presentation/cubits/history_cubit.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/presentation/cubits/currency/currency_cubit.dart';

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
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        loc.goalsEmpty,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: LuminaColors.textSecondary,
                          fontSize: 15,
                        ),
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
                        : (goal.currentAmount / goal.targetAmount).clamp(
                            0.0,
                            1.0,
                          );
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: LuminaColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(loc.goalsNew, style: const TextStyle(color: Colors.white)),
        onPressed: () {
          HapticFeedback.lightImpact();
          _showAddGoalBottomSheet(loc, symbol);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _confirmDelete(
    GoalExpenseModel goal,
    AppLocalizations loc,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(loc.goalsDeleteTitle),
        content: Text(loc.goalsDeleteConfirm(goal.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.goalsCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(loc.goalsDepositTitle(goal.title)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: loc.goalsDepositAmount(symbol),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.goalsCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount =
                  double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
              if (amount <= 0) {
                HapticFeedback.heavyImpact();
                return;
              }
              final applied = await GoalService.depositToGoal(goal, amount);
              if (ctx.mounted) Navigator.pop(ctx);
              if (applied > 0) await _reloadHistory();
            },
            child: Text(loc.goalsDeposit),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _showAddGoalBottomSheet(AppLocalizations loc, String symbol) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    var selectedIcon = _icons.first;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LuminaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.goalsCreateTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: LuminaColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(labelText: loc.goalsNameHint),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.goalsAmountHint(symbol),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      loc.goalsIconLabel,
                      style: const TextStyle(color: LuminaColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (final icon in _icons)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setModal(() => selectedIcon = icon);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: selectedIcon == icon
                                    ? LuminaColors.primary.withValues(
                                        alpha: 0.2,
                                      )
                                    : LuminaColors.inputFill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedIcon == icon
                                      ? LuminaColors.primary
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                icon,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: LuminaDimensions.buttonHeight,
                      child: ElevatedButton(
                        onPressed: () async {
                          final title = titleController.text.trim();
                          final target =
                              double.tryParse(
                                targetController.text.replaceAll(',', '.'),
                              ) ??
                              0;
                          if (title.isEmpty || target <= 0) {
                            HapticFeedback.heavyImpact();
                            return;
                          }
                          await GoalService.addGoal(
                            title: title,
                            targetAmount: target,
                            icon: selectedIcon,
                            colorValue: 0xFF4CAF50,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Text(
                          loc.goalsCreate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      titleController.dispose();
      targetController.dispose();
    });
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
