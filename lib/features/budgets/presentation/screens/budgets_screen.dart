import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/core/utils/money.dart';
import 'package:lumina/core/widgets/lumina_dialog.dart';
import 'package:lumina/features/budgets/data/models/budget_model.dart';
import 'package:lumina/features/budgets/data/services/services/budget_service.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/l10n/app_localizations.dart';

const _warningColor = Color(0xFFF59E0B);

typedef _BudgetInput = ({String categoryId, double limit});

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late DateTime _period;

  /// Удалённые лимиты скрываются сразу: запись в Hive асинхронна, а
  /// Dismissible требует убрать элемент из дерева в том же кадре.
  final _hidden = <String>{};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _period = DateTime(now.year, now.month);
  }

  List<CustomCategory> _expenseCategories() {
    final state = context.read<CategoriesCubit>().state;
    if (state is! CategoriesLoaded) return const [];
    return [
      for (final c in state.categories)
        if (c.type == CustomCategory.typeExpense) c,
    ];
  }

  void _shift(int delta) {
    HapticFeedback.selectionClick();
    setState(() => _period = DateTime(_period.year, _period.month + delta));
  }

  Future<void> _openEditor({
    BudgetModel? budget,
    required Set<String> takenIds,
  }) async {
    HapticFeedback.lightImpact();
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final categories = _expenseCategories();

    if (categories.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(loc.noExpenseCategories)));
      return;
    }

    final result = await showLuminaDialog<_BudgetInput>(
      context: context,
      child: _BudgetEditor(
        categories: categories,
        takenIds: takenIds,
        budget: budget,
      ),
    );
    if (result == null) return;

    try {
      await BudgetService.setBudget(
        categoryId: result.categoryId,
        limitAmount: result.limit,
        month: _period.month,
        year: _period.year,
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(loc.saveFailed)));
    }
  }

  void _delete(BudgetModel budget) {
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final backup = budget.copyWith();

    HapticFeedback.mediumImpact();
    setState(() => _hidden.add(backup.id));

    BudgetService.delete(backup.id).catchError((_) {
      if (mounted) setState(() => _hidden.remove(backup.id));
    });

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(loc.limitDeleted),
          action: SnackBarAction(
            label: loc.undo,
            onPressed: () async {
              await BudgetService.restore(backup);
              if (mounted) setState(() => _hidden.remove(backup.id));
            },
          ),
        ),
      );
  }

  Future<void> _copyPrevious() async {
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final count = await BudgetService.copyFromPreviousMonth(
        month: _period.month,
        year: _period.year,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(count > 0 ? loc.limitsCopied : loc.nothingToCopy),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(loc.saveFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final symbol = context.watch<CurrencyCubit>().state.symbol;
    final records = context.watch<HistoryCubit>().state.allRecords;
    final catState = context.watch<CategoriesCubit>().state;
    final categories = <String, CustomCategory>{
      if (catState is CategoriesLoaded)
        for (final c in catState.categories) c.id: c,
    };

    // Только расходы выбранного месяца. Переводы и доходы не считаются.
    final spent = <String, double>{};
    for (final r in records) {
      if (!r.isExpense) continue;
      if (r.date.year != _period.year || r.date.month != _period.month) {
        continue;
      }
      spent[r.category] = (spent[r.category] ?? 0) + r.price;
    }

    final rawLabel = DateFormat('LLLL y', locale).format(_period);
    final periodLabel = rawLabel.isEmpty
        ? rawLabel
        : '${rawLabel[0].toUpperCase()}${rawLabel.substring(1)}';

    return Scaffold(
      backgroundColor: LuminaColors.background,
      appBar: AppBar(
        title: Text(loc.monthlyBudgets),
        actions: [
          IconButton(
            tooltip: loc.copyFromPreviousMonth,
            icon: const Icon(Icons.content_copy_rounded, size: 20),
            onPressed: _copyPrevious,
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<BudgetModel>>(
        valueListenable:
            Hive.box<BudgetModel>(BudgetService.boxName).listenable(),
        builder: (context, box, _) {
          final budgets = [
            for (final b in box.values)
              if (b.month == _period.month &&
                  b.year == _period.year &&
                  !_hidden.contains(b.id))
                b,
          ]..sort((a, b) {
              double ratio(BudgetModel x) => x.limitAmount <= 0
                  ? 0
                  : (spent[x.categoryId] ?? 0) / x.limitAmount;
              return ratio(b).compareTo(ratio(a));
            });

          final takenIds = {for (final b in budgets) b.categoryId};
          final totalLimit =
              budgets.fold<double>(0, (s, b) => s + b.limitAmount);
          final totalSpent = budgets.fold<double>(
            0,
            (s, b) => s + (spent[b.categoryId] ?? 0),
          );

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            children: [
              _PeriodBar(
                label: periodLabel,
                onPrev: () => _shift(-1),
                onNext: () => _shift(1),
              ),
              const SizedBox(height: 16),
              if (budgets.isNotEmpty) ...[
                _SummaryCard(
                  text: loc.budgetsSummary(
                    Money.format(totalSpent, locale, symbol: symbol),
                    Money.format(totalLimit, locale, symbol: symbol),
                  ),
                  progress: totalLimit <= 0 ? 0 : (totalSpent / totalLimit),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                loc.establishedLimits,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: LuminaColors.textMain,
                ),
              ),
              const SizedBox(height: 12),
              if (budgets.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Text(
                        loc.noLimitsThisMonth,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: LuminaColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _copyPrevious,
                        icon: const Icon(Icons.content_copy_rounded, size: 18),
                        label: Text(loc.copyFromPreviousMonth),
                      ),
                    ],
                  ),
                )
              else
                for (final budget in budgets)
                  Dismissible(
                    key: ValueKey(budget.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: LuminaColors.errorSoft,
                        borderRadius: LuminaDimensions.borderRadiusMedium,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: LuminaColors.error,
                      ),
                    ),
                    onDismissed: (_) => _delete(budget),
                    child: _BudgetCard(
                      budget: budget,
                      category: categories[budget.categoryId],
                      spent: spent[budget.categoryId] ?? 0,
                      symbol: symbol,
                      locale: locale,
                      onTap: () =>
                          _openEditor(budget: budget, takenIds: takenIds),
                    ),
                  ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: LuminaColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          final taken = {
            for (final b in Hive.box<BudgetModel>(BudgetService.boxName).values)
              if (b.month == _period.month && b.year == _period.year)
                b.categoryId,
          };
          _openEditor(takenIds: taken);
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(
          loc.addLimit,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _PeriodBar extends StatelessWidget {
  const _PeriodBar({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: LuminaColors.surface,
        borderRadius: LuminaDimensions.borderRadiusLarge,
        boxShadow: LuminaTheme.subtleShadow,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: onPrev,
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: LuminaColors.textMain,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.text, required this.progress});

  final String text;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final over = progress > 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuminaColors.cardMint,
        borderRadius: LuminaDimensions.borderRadiusMedium,
        border: Border.all(color: LuminaColors.cardMintBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: LuminaColors.accentDeep,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            backgroundColor: Colors.white.withValues(alpha: 0.7),
            color: over ? LuminaColors.error : LuminaColors.primary,
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.category,
    required this.spent,
    required this.symbol,
    required this.locale,
    required this.onTap,
  });

  final BudgetModel budget;
  final CustomCategory? category;
  final double spent;
  final String symbol;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final limit = budget.limitAmount;
    final ratio = limit <= 0 ? 0.0 : spent / limit;
    final over = spent > limit;
    final color = over
        ? LuminaColors.error
        : (ratio >= 0.8 ? _warningColor : LuminaColors.primary);
    final name = category?.localizedName(loc) ?? loc.otherCategory;

    final diff = (limit - spent).abs();
    final note = over
        ? loc.budgetOver(Money.format(diff, locale, symbol: symbol))
        : loc.budgetRemaining(Money.format(diff, locale, symbol: symbol));

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: LuminaColors.surface,
        borderRadius: LuminaDimensions.borderRadiusMedium,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (category != null) ...[
                      Icon(category!.icon, size: 18, color: category!.color),
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
                      '${Money.format(spent, locale)} / '
                      '${Money.format(limit, locale, symbol: symbol)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color:
                            over ? LuminaColors.error : LuminaColors.textMain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  backgroundColor: LuminaColors.inputFill,
                  color: color,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 8),
                Text(
                  note,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        over ? LuminaColors.error : LuminaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetEditor extends StatefulWidget {
  const _BudgetEditor({
    required this.categories,
    required this.takenIds,
    this.budget,
  });

  final List<CustomCategory> categories;
  final Set<String> takenIds;
  final BudgetModel? budget;

  @override
  State<_BudgetEditor> createState() => _BudgetEditorState();
}

class _BudgetEditorState extends State<_BudgetEditor> {
  late final TextEditingController _controller;
  late String _selectedId;
  bool _error = false;

  bool get _editing => widget.budget != null;

  @override
  void initState() {
    super.initState();
    final budget = widget.budget;
    _controller = TextEditingController(
      text: budget == null ? '' : Money.forInput(budget.limitAmount),
    );
    _selectedId = budget?.categoryId ??
        (widget.categories
                    .where((c) => !widget.takenIds.contains(c.id))
                    .firstOrNull ??
                widget.categories.first)
            .id;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final limit = Money.parse(_controller.text);
    if (limit == null || limit <= 0) {
      HapticFeedback.heavyImpact();
      setState(() => _error = true);
      return;
    }
    Navigator.of(context).pop((categoryId: _selectedId, limit: limit));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final shown = _editing
        ? widget.categories.where((c) => c.id == _selectedId).toList()
        : widget.categories;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.setCategoryLimit,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: LuminaColors.textMain,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cat in shown)
                ChoiceChip(
                  selected: _selectedId == cat.id,
                  label: Text(cat.localizedName(loc)),
                  avatar: Icon(cat.icon, size: 16, color: cat.color),
                  showCheckmark: false,
                  selectedColor: LuminaColors.cardMint,
                  onSelected: _editing
                      ? null
                      : (_) {
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
            ],
            onChanged: (_) {
              if (_error) setState(() => _error = false);
            },
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: loc.monthlyLimit,
              errorText: _error ? loc.amountRequired : null,
              filled: true,
              fillColor: LuminaColors.inputFill,
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
                  child: Text(loc.saveLimit),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
