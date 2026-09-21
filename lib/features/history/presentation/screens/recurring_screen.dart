import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/data/models/recurring_expense_model.dart';
import 'package:lumina/features/history/data/services/recurring_service.dart';
import 'package:lumina/features/history/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/categories_state.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/presentation/cubits/currency/currency_cubit.dart';

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
                      padding: const EdgeInsets.symmetric(
                        horizontal: LuminaDimensions.paddingXL,
                      ),
                      child: Text(
                        loc.noRecurringPayments,
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
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _RecurringCard(
                      item: item,
                      symbol: symbol,
                      loc: loc,
                      onDelete: () => _confirmDelete(item, loc),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: LuminaColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          loc.addTemplate,
          style: const TextStyle(color: Colors.white),
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          _showAddSheet(symbol, loc);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _confirmDelete(
    RecurringExpenseModel item,
    AppLocalizations loc,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.delete),
        content: Text(item.productName),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
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

  void _showAddSheet(String symbol, AppLocalizations loc) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    var selectedDay = 1;
    var isIncome = false;
    String? selectedCategoryId;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LuminaColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LuminaDimensions.radiusLarge),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModal) {
            final catState = context.watch<CategoriesCubit>().state;
            final all = catState is CategoriesLoaded
                ? catState.categories
                : const <CustomCategory>[];
            final categories = all
                .where((c) => c.type == (isIncome ? 'income' : 'expense'))
                .toList();

            selectedCategoryId ??= categories.isNotEmpty
                ? categories.first.id
                : null;
            if (selectedCategoryId != null &&
                categories.every((c) => c.id != selectedCategoryId)) {
              selectedCategoryId = categories.isNotEmpty
                  ? categories.first.id
                  : null;
            }

            return Padding(
              padding: EdgeInsets.only(
                left: LuminaDimensions.paddingXL,
                right: LuminaDimensions.paddingXL,
                top: LuminaDimensions.paddingXL,
                bottom:
                    MediaQuery.viewInsetsOf(sheetContext).bottom +
                    LuminaDimensions.paddingXL,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.addTemplate,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: LuminaColors.textMain,
                      ),
                    ),
                    const SizedBox(height: LuminaDimensions.paddingM),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: loc.goalsNameHint,
                        border: OutlineInputBorder(
                          borderRadius: LuminaDimensions.borderRadiusMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: LuminaDimensions.paddingS + 4),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.goalsDepositAmount(symbol),
                        border: OutlineInputBorder(
                          borderRadius: LuminaDimensions.borderRadiusMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: LuminaDimensions.paddingM),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        loc.incomeType,
                        style: const TextStyle(color: LuminaColors.textMain),
                      ),
                      value: isIncome,
                      activeThumbColor: LuminaColors.success,
                      onChanged: (val) {
                        setModal(() {
                          isIncome = val;
                          selectedCategoryId = null;
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
                    SizedBox(
                      height: 45,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final selected = cat.id == selectedCategoryId;
                          return GestureDetector(
                            onTap: () =>
                                setModal(() => selectedCategoryId = cat.id),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? LuminaColors.primary
                                    : LuminaColors.inputFill,
                                borderRadius:
                                    LuminaDimensions.borderRadiusMedium,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    cat.icon,
                                    size: 16,
                                    color: selected ? Colors.white : cat.color,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    cat.localizedName(loc),
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : LuminaColors.textMain,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: LuminaDimensions.paddingS + 4),
                    Row(
                      children: [
                        Text(
                          '${loc.day}: ',
                          style: const TextStyle(color: LuminaColors.textMain),
                        ),
                        Expanded(
                          child: Slider(
                            value: selectedDay.toDouble(),
                            min: 1,
                            max: 31,
                            divisions: 30,
                            label: '$selectedDay',
                            activeColor: LuminaColors.primary,
                            onChanged: (val) =>
                                setModal(() => selectedDay = val.toInt()),
                          ),
                        ),
                        Text(
                          '$selectedDay',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: LuminaColors.textMain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: LuminaDimensions.paddingM),
                    SizedBox(
                      width: double.infinity,
                      height: LuminaDimensions.buttonHeight,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final price =
                              double.tryParse(
                                priceController.text.replaceAll(',', '.'),
                              ) ??
                              0;
                          if (name.isEmpty ||
                              price <= 0 ||
                              selectedCategoryId == null) {
                            HapticFeedback.heavyImpact();
                            return;
                          }
                          await RecurringService.addRecurring(
                            productName: name,
                            price: price,
                            categoryId: selectedCategoryId!,
                            isIncome: isIncome,
                            dayOfMonth: selectedDay,
                          );
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        },
                        child: Text(
                          loc.save,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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
      nameController.dispose();
      priceController.dispose();
    });
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  '${item.isIncome ? '+' : '-'}${item.price.toStringAsFixed(0)} $symbol',
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
