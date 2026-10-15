import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';
import 'package:lumina/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:lumina/l10n/app_localizations.dart';

class MonthlyCalendarWidget extends StatefulWidget {
  const MonthlyCalendarWidget({
    super.key,
    required this.monthRecords,
    required this.categories,
    required this.month,
    required this.year,
    required this.currencySymbol,
    required this.onDeleteTransaction,
    required this.onEditTransaction,
  });

  final List<HistoryExpenseModel> monthRecords;
  final List<CustomCategory> categories;
  final int month;
  final int year;
  final String currencySymbol;
  final ValueChanged<HistoryExpenseModel> onDeleteTransaction;
  final ValueChanged<HistoryExpenseModel> onEditTransaction;

  @override
  State<MonthlyCalendarWidget> createState() => _MonthlyCalendarWidgetState();
}

class _MonthlyCalendarWidgetState extends State<MonthlyCalendarWidget> {
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (now.month == widget.month && now.year == widget.year) {
      _selectedDay = DateTime(now.year, now.month, now.day);
    } else {
      _selectedDay = DateTime(widget.year, widget.month, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final daysInMonth = DateUtils.getDaysInMonth(widget.year, widget.month);
    final firstDayOfWeek =
        DateTime(widget.year, widget.month, 1).weekday; // 1 = Пн

    final dayMap = <int, List<HistoryExpenseModel>>{};
    for (final record in widget.monthRecords) {
      dayMap.putIfAbsent(record.date.day, () => []).add(record);
    }

    final selectedDayRecords = _selectedDay != null
        ? (dayMap[_selectedDay!.day] ?? [])
        : <HistoryExpenseModel>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _weekdayLabel(loc.mon),
              _weekdayLabel(loc.tue),
              _weekdayLabel(loc.wed),
              _weekdayLabel(loc.thu),
              _weekdayLabel(loc.fri),
              _weekdayLabel(loc.sat),
              _weekdayLabel(loc.sun),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.85,
            ),
            itemCount: (firstDayOfWeek - 1) + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstDayOfWeek - 1) {
                return const SizedBox.shrink();
              }

              final day = index - (firstDayOfWeek - 1) + 1;
              final date = DateTime(widget.year, widget.month, day);
              final dayRecords = dayMap[day] ?? [];
              final isSelected = _selectedDay != null &&
                  _selectedDay!.year == date.year &&
                  _selectedDay!.month == date.month &&
                  _selectedDay!.day == date.day;

              var dayExpenseSum = 0.0;
              var dayIncomeSum = 0.0;
              for (final r in dayRecords) {
                if (r.type == TransactionType.expense) {
                  dayExpenseSum += r.price;
                } else if (r.type == TransactionType.income) {
                  dayIncomeSum += r.price;
                }
              }

              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDay = date);
                },
                borderRadius: LuminaDimensions.borderRadiusMedium,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? LuminaColors.primary.withValues(alpha: 0.15)
                        : LuminaColors.surface,
                    borderRadius: LuminaDimensions.borderRadiusMedium,
                    border: Border.all(
                      color: isSelected
                          ? LuminaColors.primary
                          : LuminaColors.border.withValues(alpha: 0.5),
                      width: isSelected ? 1.6 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? LuminaColors.primary
                              : LuminaColors.textMain,
                        ),
                      ),
                      if (dayExpenseSum > 0)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '-${dayExpenseSum.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: LuminaColors.error,
                            ),
                          ),
                        )
                      else if (dayIncomeSum > 0)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '+${dayIncomeSum.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: LuminaColors.accent,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          if (_selectedDay != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${_selectedDay!.day} ${_monthName(loc, _selectedDay!.month)} ${_selectedDay!.year}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: LuminaColors.textMain,
                ),
              ),
            ),
            if (selectedDayRecords.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    loc.noExpensesForPeriod,
                    style: const TextStyle(
                      color: LuminaColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedDayRecords.length,
                itemBuilder: (context, index) {
                  final transaction = selectedDayRecords[index];
                  final matchedCategory = widget.categories
                      .where((c) => c.id == transaction.categoryId)
                      .firstOrNull;

                  return TransactionTile(
                    record: transaction,
                    category: matchedCategory,
                    currencySymbol: widget.currencySymbol,
                    onDelete: () => widget.onDeleteTransaction(transaction),
                    onEdit: () => widget.onEditTransaction(transaction),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _weekdayLabel(String label) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: LuminaColors.textSecondary,
          ),
        ),
      ),
    );
  }

  String _monthName(AppLocalizations loc, int month) => switch (month) {
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
