import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/core/widgets/lumina_form_dialog.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';
import 'package:lumina/features/recurring/data/models/recurring_expense_model.dart';
import 'package:lumina/features/recurring/data/services/recurring_service.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';
import 'package:lumina/l10n/app_localizations.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  Box<RecurringExpenseModel>? _box;

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    final box = Hive.isBoxOpen(RecurringService.boxName)
        ? Hive.box<RecurringExpenseModel>(RecurringService.boxName)
        : await Hive.openBox<RecurringExpenseModel>(RecurringService.boxName);
    if (mounted) setState(() => _box = box);
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

    return Scaffold(
      backgroundColor: LuminaColors.background,
      appBar: AppBar(
        title: Text(
          loc.recurringPayments,
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
              builder: (context, Box<RecurringExpenseModel> itemsBox, _) {
                final items = itemsBox.values.toList();
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            loc.noRecurringPayments,
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
                              loc.addTemplate,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _showAddDialog(symbol, loc);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _RecurringCard(
                      item: items[index],
                      symbol: symbol,
                      loc: loc,
                      onDelete: () => _confirmDelete(items[index], loc),
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
                  loc.addTemplate,
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showAddDialog(symbol, loc);
                },
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _confirmDelete(
    RecurringExpenseModel item,
    AppLocalizations loc,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(loc.delete),
        content: Text(item.productName),
        actions: [
          TextButton(onPressed: () => _close(ctx), child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      await item.delete();
    }
  }

  void _showAddDialog(String symbol, AppLocalizations loc) {
    final catState = context.read<CategoriesCubit>().state;
    final categories = catState is CategoriesLoaded
        ? catState.categories
        : const <CustomCategory>[];

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => _AddRecurringDialog(
        symbol: symbol,
        loc: loc,
        categories: categories,
        onClose: () => _close(ctx),
      ),
    );
  }
}

class _AddRecurringDialog extends StatefulWidget {
  const _AddRecurringDialog({
    required this.symbol,
    required this.loc,
    required this.categories,
    required this.onClose,
  });

  final String symbol;
  final AppLocalizations loc;
  final List<CustomCategory> categories;
  final VoidCallback onClose;

  @override
  State<_AddRecurringDialog> createState() => _AddRecurringDialogState();
}

class _AddRecurringDialogState extends State<_AddRecurringDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  var _selectedDay = 1;
  var _isIncome = false;
  String? _selectedCategoryId;
  var _saving = false;

  List<CustomCategory> get _visibleCategories => widget.categories
      .where((c) => c.type == (_isIncome ? 'income' : 'expense'))
      .toList();

  @override
  void initState() {
    super.initState();
    final first = _visibleCategories;
    _selectedCategoryId = first.isNotEmpty ? first.first.id : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final price =
        double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;
    if (name.isEmpty || price <= 0 || _selectedCategoryId == null) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _saving = true);
    try {
      await RecurringService.addRecurring(
        productName: name,
        price: price,
        categoryId: _selectedCategoryId!,
        isIncome: _isIncome,
        dayOfMonth: _selectedDay,
      );
      if (mounted) widget.onClose();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    final cats = _visibleCategories;

    return LuminaFormDialog(
      title: loc.addTemplate,
      onClose: widget.onClose,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: loc.defaultTransactionName,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: loc.goalsDepositAmount(widget.symbol),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              loc.incomeType,
              style: const TextStyle(color: LuminaColors.textMain),
            ),
            value: _isIncome,
            activeThumbColor: LuminaColors.success,
            onChanged: (val) {
              setState(() {
                _isIncome = val;
                final next = _visibleCategories;
                _selectedCategoryId = next.isNotEmpty ? next.first.id : null;
              });
            },
          ),
          Text(
            loc.chooseCategory,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: LuminaColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (cats.isEmpty)
            Text(
              loc.noExpensesForPeriod,
              style: const TextStyle(color: LuminaColors.textSecondary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in cats)
                  ChoiceChip(
                    selected: cat.id == _selectedCategoryId,
                    label: Text(cat.localizedName(loc)),
                    avatar: Icon(
                      cat.icon,
                      size: 16,
                      color: cat.id == _selectedCategoryId
                          ? Colors.white
                          : cat.color,
                    ),
                    selectedColor: LuminaColors.primary,
                    labelStyle: TextStyle(
                      color: cat.id == _selectedCategoryId
                          ? Colors.white
                          : LuminaColors.textMain,
                    ),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategoryId = cat.id);
                    },
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${loc.day}: ',
                style: const TextStyle(color: LuminaColors.textMain),
              ),
              Expanded(
                child: Slider(
                  value: _selectedDay.toDouble(),
                  min: 1,
                  max: 31,
                  divisions: 30,
                  label: '$_selectedDay',
                  activeColor: LuminaColors.primary,
                  onChanged: (val) =>
                      setState(() => _selectedDay = val.toInt()),
                ),
              ),
              Text(
                '$_selectedDay',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: LuminaColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: LuminaColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                loc.save,
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

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    required this.item,
    required this.symbol,
    required this.loc,
    required this.onDelete,
  });

  final RecurringExpenseModel item;
  final String symbol;
  final AppLocalizations loc;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final whole = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    )..maximumFractionDigits = 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: LuminaColors.surface,
        borderRadius: LuminaDimensions.borderRadiusLarge,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    (item.isIncome ? LuminaColors.success : LuminaColors.error)
                        .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.isIncome
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: item.isIncome
                    ? LuminaColors.success
                    : LuminaColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: LuminaColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${loc.day} ${item.dayOfMonth}',
                    style: const TextStyle(
                      color: LuminaColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.isIncome ? '+' : '-'}${whole.format(item.price)} $symbol',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: item.isIncome
                        ? LuminaColors.success
                        : LuminaColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onDelete,
                  child: Text(
                    loc.delete,
                    style: const TextStyle(
                      color: LuminaColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
