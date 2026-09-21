import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/l10n/app_localizations.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/custom_category_model.dart';
import '../../data/services/budget_service.dart';
import '../../data/models/history_expense_model.dart';

class BudgetsScreen extends StatefulWidget {
  final List<CustomCategory> categories;
  final List<HistoryExpenseModel> allRecords;

  const BudgetsScreen({
    super.key,
    required this.categories,
    required this.allRecords,
  });

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late Box<BudgetModel> _box;
  bool _isInitialized = false;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    if (!Hive.isBoxOpen(BudgetService.boxName)) {
      _box = await Hive.openBox<BudgetModel>(BudgetService.boxName);
    } else {
      _box = Hive.box<BudgetModel>(BudgetService.boxName);
    }
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  CustomCategory? _findCategory(String categoryId) {
    for (final c in widget.categories) {
      if (c.id == categoryId) return c;
    }
    return null;
  }

  String _getMonthName(AppLocalizations loc, int month) {
    switch (month) {
      case 1:
        return loc.january;
      case 2:
        return loc.february;
      case 3:
        return loc.march;
      case 4:
        return loc.april;
      case 5:
        return loc.may;
      case 6:
        return loc.june;
      case 7:
        return loc.july;
      case 8:
        return loc.august;
      case 9:
        return loc.september;
      case 10:
        return loc.october;
      case 11:
        return loc.november;
      case 12:
        return loc.december;
      default:
        return '';
    }
  }

  void _showMonthPicker() {
    HapticFeedback.lightImpact();
    final loc = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: LuminaColors.surface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LuminaDimensions.radiusLarge),
        ),
      ),
      builder: (context) {
        int tempMonth = _selectedMonth;
        int tempYear = _selectedYear;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                LuminaDimensions.paddingL,
                LuminaDimensions.paddingM,
                LuminaDimensions.paddingL,
                MediaQuery.of(context).viewInsets.bottom +
                    LuminaDimensions.paddingL,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.budgetPeriod,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: LuminaColors.textMain,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: LuminaColors.textSecondary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: LuminaDimensions.paddingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$tempYear',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: LuminaColors.textMain,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              color: LuminaColors.textSecondary,
                            ),
                            onPressed: () => setModalState(() => tempYear--),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                              color: LuminaColors.textSecondary,
                            ),
                            onPressed: () => setModalState(() => tempYear++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final monthIndex = index + 1;
                      // Сравнивается только месяц — год в этом гриде один и
                      // тот же (tempYear), сравнивать его с самим собой не нужно.
                      final isSelected = monthIndex == tempMonth;

                      return GestureDetector(
                        onTap: () =>
                            setModalState(() => tempMonth = monthIndex),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? LuminaColors.primary
                                : LuminaColors.inputFill,
                            borderRadius: LuminaDimensions.borderRadiusMedium,
                          ),
                          child: Text(
                            _getMonthName(loc, monthIndex),
                            style: TextStyle(
                              color: isSelected
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
                  const SizedBox(height: LuminaDimensions.paddingXL),
                  SizedBox(
                    width: double.infinity,
                    height: LuminaDimensions.buttonHeight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LuminaColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: LuminaDimensions.borderRadiusMedium,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = tempMonth;
                          _selectedYear = tempYear;
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        loc.confirm,
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final periodString = '${_getMonthName(loc, _selectedMonth)} $_selectedYear';

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
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder(
              valueListenable: _box.listenable(),
              builder: (context, Box<BudgetModel> box, _) {
                final currentBudgets = box.values.where((b) {
                  return b.month == _selectedMonth && b.year == _selectedYear;
                }).toList();

                final Map<String, double> spentByCategory = {};
                for (var record in widget.allRecords) {
                  if (!record.isIncome &&
                      record.date.month == _selectedMonth &&
                      record.date.year == _selectedYear) {
                    spentByCategory[record.categoryId] =
                        (spentByCategory[record.categoryId] ?? 0.0) +
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: LuminaColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                periodString,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: LuminaColors.textMain,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: _showMonthPicker,
                            style: TextButton.styleFrom(
                              foregroundColor: LuminaColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              backgroundColor: LuminaColors.primary.withValues(
                                alpha: 0.1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              loc.change,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
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
                      ),
                    ...currentBudgets.map((budget) {
                      final category = _findCategory(budget.categoryId);
                      // Фолбэк на "otherCategory" — семантически верно, когда
                      // категория была удалена, в отличие от loc.expense
                      // ("Расход"), который не про отсутствие категории.
                      final categoryName =
                          category?.localizedName(loc) ?? loc.otherCategory;
                      final spent = spentByCategory[budget.categoryId] ?? 0.0;
                      final progress = (spent / budget.limitAmount).clamp(
                        0.0,
                        1.0,
                      );
                      final isOverLimit = spent > budget.limitAmount;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: LuminaColors.surface,
                          borderRadius: LuminaDimensions.borderRadiusMedium,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    Text(
                                      categoryName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: LuminaColors.textMain,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${spent.toStringAsFixed(0)} / ${budget.limitAmount.toStringAsFixed(0)} ₴',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isOverLimit
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
                              color: isOverLimit
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
        elevation: 2,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          loc.addLimit,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          _showAddBudgetBottomSheet(context);
        },
      ),
    );
  }

  void _showAddBudgetBottomSheet(BuildContext context) {
    String? selectedCategoryId;
    final limitController = TextEditingController();
    final loc = AppLocalizations.of(context)!;

    final expenseCategories = widget.categories
        .where((c) => c.type == 'expense')
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: LuminaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.setCategoryLimit,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: LuminaColors.textMain,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: LuminaColors.textSecondary,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategoryId,
                      hint: Text(loc.chooseCategory),
                      dropdownColor: LuminaColors.surface,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: LuminaColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: LuminaDimensions.borderRadiusMedium,
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      items: expenseCategories.map<DropdownMenuItem<String>>((
                        cat,
                      ) {
                        return DropdownMenuItem<String>(
                          value: cat.id,
                          child: Row(
                            children: [
                              Icon(cat.icon, size: 16, color: cat.color),
                              const SizedBox(width: 10),
                              Text(
                                cat.localizedName(loc),
                                style: const TextStyle(
                                  color: LuminaColors.textMain,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setStateModal(() => selectedCategoryId = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: limitController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: loc.monthlyLimitLabel,
                        filled: true,
                        fillColor: LuminaColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: LuminaDimensions.borderRadiusMedium,
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: LuminaDimensions.buttonHeight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LuminaColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: LuminaDimensions.borderRadiusMedium,
                          ),
                        ),
                        onPressed: () async {
                          if (selectedCategoryId != null &&
                              limitController.text.isNotEmpty) {
                            final limit =
                                double.tryParse(limitController.text) ?? 0.0;
                            if (limit > 0) {
                              await BudgetService.setBudget(
                                categoryId: selectedCategoryId!,
                                limitAmount: limit,
                                month: _selectedMonth,
                                year: _selectedYear,
                              );
                              if (context.mounted) Navigator.pop(context);
                            }
                          }
                        },
                        child: Text(
                          loc.saveLimit,
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
    );
  }
}
