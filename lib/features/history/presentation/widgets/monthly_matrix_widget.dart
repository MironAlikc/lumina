import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';
import 'package:lumina/l10n/app_localizations.dart';

class MonthlyMatrixWidget extends StatelessWidget {
  final List<HistoryExpenseModel> monthRecords;
  final List<CustomCategory> categories;
  final int month;
  final int year;
  final String currencySymbol;
  final Function(String? categoryKey)? onCategoryHeaderTap;
  final Function(int day)? onDayTap;
  final Function(HistoryExpenseModel transaction)? onDeleteTransaction;
  final Function(HistoryExpenseModel transaction)? onEditTransaction;

  const MonthlyMatrixWidget({
    super.key,
    required this.monthRecords,
    required this.categories,
    required this.month,
    required this.year,
    required this.currencySymbol,
    this.onCategoryHeaderTap,
    this.onDayTap,
    this.onDeleteTransaction,
    this.onEditTransaction,
  });

  String _categoryKeyOf(HistoryExpenseModel record) {
    return record.categoryId.isNotEmpty
        ? record.categoryId
        : (record.categoryName ?? 'other');
  }

  void _showDayDetails(
    BuildContext context,
    int day,
    List<HistoryExpenseModel> records,
  ) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    final dayRecords = records.where((r) => r.date.day == day).toList();
    dayRecords.sort((a, b) => b.date.compareTo(a.date));

    // Единственная точка поиска категории по id — то же самое, что и
    // остальные виджеты (TransactionTile, RecentTransactionsList): имя и
    // иконка берутся из CustomCategory, а не из полей модели транзакции.
    final Map<String, CustomCategory> categoryMap = {
      for (var cat in categories) cat.id: cat,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateSheet) {
            final double dayTotal = dayRecords.fold(
              0,
              (sum, item) => sum + item.price,
            );

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat(
                            'd MMMM y',
                            locale,
                          ).format(DateTime(year, month, day)),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: LuminaTheme.textColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: LuminaColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${dayTotal.toStringAsFixed(0)} $currencySymbol',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: LuminaColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Expanded(
                      child: dayRecords.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Text(
                                  loc.noExpensesForPeriod,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: dayRecords.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final record = dayRecords[index];
                                final category = categoryMap[record.categoryId];

                                final Color catColor =
                                    category?.color ?? LuminaColors.primary;
                                final IconData catIcon =
                                    category?.icon ??
                                    Icons.receipt_long_rounded;
                                // Имя категории всегда через lookup по id —
                                // categoryName в модели больше не является
                                // источником истины (см. fromEntity).
                                final String categoryLabel =
                                    category?.localizedName(loc) ??
                                    loc.otherCategory;

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: catColor.withValues(
                                            alpha: 0.12,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          catIcon,
                                          size: 18,
                                          color: catColor,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              categoryLabel,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: LuminaTheme.textColor,
                                              ),
                                            ),
                                            if (record
                                                .productName
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                record.productName,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: LuminaTheme.textColor
                                                      .withValues(alpha: 0.6),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${record.price.toStringAsFixed(0)} $currencySymbol',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: LuminaTheme.textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(6),
                                        onPressed: () =>
                                            onEditTransaction?.call(record),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: Colors.redAccent,
                                        ),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(6),
                                        onPressed: () {
                                          setStateSheet(() {
                                            dayRecords.removeAt(index);
                                          });
                                          onDeleteTransaction?.call(record);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final filteredRecords = monthRecords.where((record) {
      return record.date.month == month && record.date.year == year;
    }).toList();

    final Map<int, Map<String, double>> dailyCategoryTotals = {};
    final Map<String, double> categoryMonthTotals = {};
    final Map<int, double> dayTotals = {};

    for (var record in filteredRecords) {
      final day = record.date.day;
      final catKey = _categoryKeyOf(record);
      final amount = record.price;

      dailyCategoryTotals.putIfAbsent(day, () => {});
      dailyCategoryTotals[day]![catKey] =
          (dailyCategoryTotals[day]![catKey] ?? 0) + amount;

      categoryMonthTotals[catKey] = (categoryMonthTotals[catKey] ?? 0) + amount;
      dayTotals[day] = (dayTotals[day] ?? 0) + amount;
    }

    final activeDays = dayTotals.keys.toList()..sort();
    final double grandTotal = categoryMonthTotals.values.fold(
      0,
      (sum, val) => sum + val,
    );

    const double columnWidth = 105.0;
    const double dayColumnWidth = 65.0;
    final double totalContentWidth =
        dayColumnWidth + (categories.length * columnWidth) + 90.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: totalContentWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: LuminaColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: dayColumnWidth,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          loc.day,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: LuminaColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    ...categories.map((cat) {
                      return SizedBox(
                        width: columnWidth,
                        child: InkWell(
                          onTap: () => onCategoryHeaderTap?.call(cat.id),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 2,
                              horizontal: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(cat.icon, size: 15, color: cat.color),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    cat.localizedName(loc),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: LuminaTheme.textColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    SizedBox(
                      width: 90,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          loc.total,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: LuminaColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              if (activeDays.isEmpty)
                Container(
                  width: totalContentWidth - 32,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      loc.noExpensesForMonth,
                      style: TextStyle(
                        color: LuminaTheme.textColor.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                ...activeDays.map((day) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.015),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () {
                          _showDayDetails(context, day, filteredRecords);
                          onDayTap?.call(day);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 7,
                            horizontal: 16,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: dayColumnWidth,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: 27,
                                    height: 27,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: LuminaColors.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$day',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: LuminaColors.primary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              ...categories.map((cat) {
                                final amount =
                                    dailyCategoryTotals[day]?[cat.id] ?? 0.0;

                                return SizedBox(
                                  width: columnWidth,
                                  child: Text(
                                    amount > 0
                                        ? '${amount.toStringAsFixed(0)} $currencySymbol'
                                        : '',
                                    style: TextStyle(
                                      color: amount > 0
                                          ? LuminaTheme.textColor
                                          : Colors.transparent,
                                      fontSize: 13,
                                      fontWeight: amount > 0
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                );
                              }),
                              SizedBox(
                                width: 90,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${dayTotals[day]!.toStringAsFixed(0)} $currencySymbol',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: LuminaColors.primary,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: LuminaColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: dayColumnWidth,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          loc.total.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: LuminaColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    ...categories.map((cat) {
                      final catTotal = categoryMonthTotals[cat.id] ?? 0.0;

                      return SizedBox(
                        width: columnWidth,
                        child: Text(
                          catTotal > 0
                              ? '${catTotal.toStringAsFixed(0)} $currencySymbol'
                              : '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: catTotal > 0
                                ? LuminaTheme.textColor
                                : Colors.transparent,
                            fontSize: 13.5,
                          ),
                        ),
                      );
                    }),
                    SizedBox(
                      width: 90,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${grandTotal.toStringAsFixed(0)} $currencySymbol',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: LuminaColors.primary,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
