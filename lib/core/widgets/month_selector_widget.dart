import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/l10n/app_localizations.dart';

class MonthSelectorWidget extends StatelessWidget {
  const MonthSelectorWidget({
    super.key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onMonthChanged,
  });

  final int selectedMonth;
  final int selectedYear;
  final void Function(int month, int year) onMonthChanged;

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

  void _previousMonth() {
    HapticFeedback.selectionClick();
    if (selectedMonth > 1) {
      onMonthChanged(selectedMonth - 1, selectedYear);
    } else {
      onMonthChanged(12, selectedYear - 1);
    }
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    if (selectedMonth < 12) {
      onMonthChanged(selectedMonth + 1, selectedYear);
    } else {
      onMonthChanged(1, selectedYear + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final monthName = _monthName(loc, selectedMonth);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: LuminaColors.cardMint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: LuminaColors.cardMintBorder.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: LuminaColors.textMain,
              size: 20,
            ),
            onPressed: _previousMonth,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 15,
                color: LuminaColors.accent,
              ),
              const SizedBox(width: 6),
              Text(
                '$monthName $selectedYear',
                style: const TextStyle(
                  color: LuminaColors.textMain,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: LuminaColors.textMain,
              size: 20,
            ),
            onPressed: _nextMonth,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
        ],
      ),
    );
  }
}
