import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';

import '../../data/models/budget_model.dart';
import '../../../categories/data/models/custom_category_model.dart';
import '../../../transactions/data/models/history_expense_model.dart';
import '../../data/services/services/budget_service.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({
    super.key,
    this.categories = const [],
    this.allRecords = const [],
  });

  final List<CustomCategory> categories;
  final List<HistoryExpenseModel> allRecords;

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  Box<BudgetModel>? _box;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    final box = Hive.isBoxOpen(BudgetService.boxName)
        ? Hive.box<BudgetModel>(BudgetService.boxName)
        : await Hive.openBox<BudgetModel>(BudgetService.boxName);
    if (mounted) setState(() => _box = box);
  }

  List<CustomCategory> get _categories {
    final state = context.read<CategoriesCubit>().state;
    if (state is CategoriesLoaded && state.categories.isNotEmpty) {
      return state.categories;
    }
    return widget.categories;
  }

  List<CustomCategory> get _expenseCategories =>
      _categories.where((c) => c.type == 'expense').toList();

  CustomCategory? _findCategory(String categoryId) {
    for (final c in _categories) {
      if (c.id == categoryId) return c;
    }
    return null;
  }

  String _monthName(AppLocalizations loc, int month) {
    return switch (month) {
      1 => loc.january,
      2 => loc.february,
      3 => loc.march,
      4 => loc.april,
      5 => loc.may,
      6 => loc.june,
      7 => loc.july,
      8 => loc.august,
      9 => loc.september,
      10 => loc.october,
      11 => loc.november,
      12 => loc.december,
      _ => '',
    };
  }

  NumberFormat _whole() {
    return NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    )..maximumFractionDigits = 0;
  }

  Future<void> _showMonthPicker() async {
    HapticFeedback.lightImpact();
    final loc = AppLocalizations.of(context)!;
    var tempMonth = _selectedMonth;
    var tempYear = _selectedYear;

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return AlertDialog(
              backgroundColor: LuminaColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(loc.budgetPeriod),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$tempYear',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded),
                              onPressed: () => setModal(() => tempYear--),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded),
                              onPressed: () => setModal(() => tempYear++),
                            ),
                          ],
                        ),
                      ],
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 12,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemBuilder: (_, index) {
                        final month = index + 1;
                        final selected = month == tempMonth;
                        return GestureDetector(
                          onTap: () => setModal(() => tempMonth = month),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? LuminaColors.primary
                                  : LuminaColors.inputFill,
                              borderRadius: LuminaDimensions.borderRadiusMedium,
                            ),
                            child: Text(
                              _monthName(loc, month),
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : LuminaColors.textMain,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(loc.goalsCancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedMonth = tempMonth;
                      _selectedYear = tempYear;
                    });
                    Navigator.pop(ctx);
                  },
                  child: Text(loc.confirm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddBudgetDialog() async {
    HapticFeedback.lightImpact();
    final loc = AppLocalizations.of(context)!;
    final cats = _expenseCategories;
    if (cats.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.noExpensesForPeriod)));
      return;
    }

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => _AddBudgetDialog(
        categories: cats,
        loc: loc,
        month: _selectedMonth,
        year: _selectedYear,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final symbol = context.watch<CurrencyCubit>().state.symbol;
    final whole = _whole();
    final box = _box;
    final period = '${_monthName(loc, _selectedMonth)} $_selectedYear';

    final historyRecords = context.watch<HistoryCubit>().state.allRecords;
    final records = historyRecords.isNotEmpty
        ? historyRecords.map(HistoryExpenseModel.fromEntity).toList()
        : widget.allRecords;

    return Scaffold(
      backgroundColor: LuminaColors.background,
      appBar: AppBar(
        title: Text(
          loc.monthlyBudgets,
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
              builder: (context, Box<BudgetModel> budgetsBox, _) {
                final currentBudgets = budgetsBox.values
                    .where(
                      (b) =>
                          b.month == _selectedMonth && b.year == _selectedYear,
                    )
                    .toList();

                final spentByCategory = <String, double>{};
                for (final record in records) {
                  final isExpense =
                      record.type == TransactionType.expense ||
                      !record.isIncome;
                  if (isExpense &&
                      record.date.month == _selectedMonth &&
                      record.date.year == _selectedYear) {
                    spentByCategory[record.categoryId] =
                        (spentByCategory[record.categoryId] ?? 0) +
                        record.price;
                  }
                }

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: LuminaColors.surface,
                        borderRadius: LuminaDimensions.borderRadiusLarge,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: LuminaColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              period,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: LuminaColors.textMain,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _showMonthPicker,
                            style: TextButton.styleFrom(
                              foregroundColor: LuminaColors.primary,
                              backgroundColor: LuminaColors.primary.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            child: Text(
                              loc.change,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      loc.establishedLimits,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: LuminaColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (currentBudgets.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            loc.noLimitsThisMonth,
                            style: const TextStyle(
                              color: LuminaColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ...currentBudgets.map((budget) {
                        final category = _findCategory(budget.categoryId);
                        final name =
                            category?.localizedName(loc) ?? loc.otherCategory;
                        final spent = spentByCategory[budget.categoryId] ?? 0.0;
                        final progress = budget.limitAmount <= 0
                            ? 0.0
                            : (spent / budget.limitAmount).clamp(0.0, 1.0);
                        final over = spent > budget.limitAmount;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: LuminaColors.surface,
                            borderRadius: LuminaDimensions.borderRadiusMedium,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  if (category != null) ...[
                                    Icon(
                                      category.icon,
                                      size: 18,
                                      color: category.color,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: LuminaColors.textMain,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${whole.format(spent)} / ${whole.format(budget.limitAmount)} $symbol',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: over
                                          ? LuminaColors.error
                                          : LuminaColors.textMain,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: LuminaColors.inputFill,
                                color: over
                                    ? LuminaColors.error
                                    : LuminaColors.primary,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: LuminaColors.primary,
        onPressed: _showAddBudgetDialog,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          loc.addLimit,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _AddBudgetDialog extends StatefulWidget {
  const _AddBudgetDialog({
    required this.categories,
    required this.loc,
    required this.month,
    required this.year,
  });

  final List<CustomCategory> categories;
  final AppLocalizations loc;
  final int month;
  final int year;

  @override
  State<_AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<_AddBudgetDialog> {
  final _controller = TextEditingController();
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.categories.first.id;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final limit = double.tryParse(_controller.text) ?? 0;
    if (_selectedId == null || limit <= 0) {
      HapticFeedback.heavyImpact();
      return;
    }
    await BudgetService.setBudget(
      categoryId: _selectedId!,
      limitAmount: limit,
      month: widget.month,
      year: widget.year,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    return AlertDialog(
      backgroundColor: LuminaColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(loc.setCategoryLimit),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cat in widget.categories)
                    ChoiceChip(
                      selected: _selectedId == cat.id,
                      label: Text(cat.localizedName(loc)),
                      avatar: Icon(cat.icon, size: 16, color: cat.color),
                      selectedColor: LuminaColors.cardMint,
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedId = cat.id);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: loc.monthlyLimit,
                  filled: true,
                  fillColor: LuminaColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: LuminaDimensions.borderRadiusMedium,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.goalsCancel),
        ),
        ElevatedButton(onPressed: _save, child: Text(loc.saveLimit)),
      ],
    );
  }
}
