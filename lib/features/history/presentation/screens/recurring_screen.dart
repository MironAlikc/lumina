import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/presentation/cubits/currency/currency_cubit.dart';
import '../../data/models/recurring_expense_model.dart';
import '../../data/services/recurring_service.dart';
import '../cubits/categories_cubit.dart';
import '../cubits/categories_state.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  late Box<RecurringExpenseModel> _box;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    if (!Hive.isBoxOpen(RecurringService.boxName)) {
      _box = await Hive.openBox<RecurringExpenseModel>(
        RecurringService.boxName,
      );
    } else {
      _box = Hive.box<RecurringExpenseModel>(RecurringService.boxName);
    }
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<CurrencyCubit>().state.symbol;

    return Scaffold(
      backgroundColor: LuminaColors.background,
      appBar: AppBar(
        title: const Text(
          'Регулярные платежи',
          style: TextStyle(
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
              builder: (context, Box<RecurringExpenseModel> box, _) {
                final items = box.values.toList();

                if (items.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: LuminaDimensions.paddingXL,
                      ),
                      child: Text(
                        'Нет регулярных платежей.\nНажмите кнопку ниже, чтобы добавить.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: LuminaColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
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
                                    (item.isIncome
                                            ? LuminaColors.success
                                            : LuminaColors.error)
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
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: LuminaColors.inputFill,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          '${item.dayOfMonth}-е число',
                                          style: const TextStyle(
                                            color: LuminaColors.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${item.isIncome ? '+' : '-'}${item.price.toStringAsFixed(0)} $currencySymbol',
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
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    item.delete();
                                  },
                                  child: const Text(
                                    'Удалить',
                                    style: TextStyle(
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
                  },
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton.extended(
          backgroundColor: LuminaColors.primary,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Добавить шаблон',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            _showAddRecurringBottomSheet(context, currencySymbol);
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _showAddRecurringBottomSheet(
    BuildContext context,
    String currencySymbol,
  ) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    int selectedDay = 1;
    bool isIncome = false;
    String? selectedCategoryId;

    showModalBottomSheet(
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
          builder: (context, setStateModal) {
            final catState = context.watch<CategoriesCubit>().state;
            final categories = catState is CategoriesLoaded
                ? catState.categories
                : [];

            if (selectedCategoryId == null && categories.isNotEmpty) {
              selectedCategoryId = categories.first.id;
            }

            return Padding(
              padding: EdgeInsets.only(
                left: LuminaDimensions.paddingXL,
                right: LuminaDimensions.paddingXL,
                top: LuminaDimensions.paddingXL,
                bottom:
                    MediaQuery.of(sheetContext).viewInsets.bottom +
                    LuminaDimensions.paddingXL,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Новый регулярный платеж',
                      style: TextStyle(
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
                        labelText: 'Название (например: Аренда, Зарплата)',
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
                        labelText: 'Сумма ($currencySymbol)',
                        border: OutlineInputBorder(
                          borderRadius: LuminaDimensions.borderRadiusMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: LuminaDimensions.paddingM),
                    const Text(
                      'Категория:',
                      style: TextStyle(
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
                          final isSelected = cat.id == selectedCategoryId;
                          return GestureDetector(
                            onTap: () {
                              setStateModal(() {
                                selectedCategoryId = cat.id;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? LuminaColors.primary
                                    : LuminaColors.inputFill,
                                borderRadius:
                                    LuminaDimensions.borderRadiusMedium,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    cat.icon,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    cat.name,
                                    style: TextStyle(
                                      color: isSelected
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
                        const Text(
                          'День месяца списания: ',
                          style: TextStyle(color: LuminaColors.textMain),
                        ),
                        Expanded(
                          child: Slider(
                            value: selectedDay.toDouble(),
                            min: 1,
                            max: 31,
                            divisions: 30,
                            label: '$selectedDay-е',
                            activeColor: LuminaColors.primary,
                            onChanged: (val) {
                              setStateModal(() {
                                selectedDay = val.toInt();
                              });
                            },
                          ),
                        ),
                        Text(
                          '$selectedDay-е',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: LuminaColors.textMain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: LuminaDimensions.paddingS + 4),
                    SwitchListTile(
                      title: const Text(
                        'Это доход',
                        style: TextStyle(color: LuminaColors.textMain),
                      ),
                      value: isIncome,
                      activeColor: LuminaColors.success,
                      onChanged: (val) {
                        setStateModal(() {
                          isIncome = val;
                        });
                      },
                    ),
                    const SizedBox(height: LuminaDimensions.paddingM),
                    SizedBox(
                      width: double.infinity,
                      height: LuminaDimensions.buttonHeight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LuminaColors.success,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: LuminaDimensions.borderRadiusMedium,
                          ),
                        ),
                        onPressed: () async {
                          if (nameController.text.trim().isNotEmpty &&
                              priceController.text.trim().isNotEmpty) {
                            final price =
                                double.tryParse(priceController.text) ?? 0.0;
                            if (price > 0) {
                              await RecurringService.addRecurring(
                                productName: nameController.text.trim(),
                                price: price,
                                categoryId: selectedCategoryId ?? 'default',
                                isIncome: isIncome,
                                dayOfMonth: selectedDay,
                              );
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            }
                          }
                        },
                        child: const Text(
                          'Сохранить шаблон',
                          style: TextStyle(
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
    ).then((_) {
      nameController.dispose();
      priceController.dispose();
    });
  }
}
