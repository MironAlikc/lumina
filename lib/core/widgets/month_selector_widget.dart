import 'package:flutter/material.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/l10n/app_localizations.dart';

class MonthSelectorWidget extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final Function(int month, int year) onMonthChanged;

  const MonthSelectorWidget({
    super.key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onMonthChanged,
  });

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

  void _previousMonth() {
    if (selectedMonth > 1) {
      onMonthChanged(selectedMonth - 1, selectedYear);
    } else {
      onMonthChanged(12, selectedYear - 1);
    }
  }

  void _nextMonth() {
    if (selectedMonth < 12) {
      onMonthChanged(selectedMonth + 1, selectedYear);
    } else {
      onMonthChanged(1, selectedYear + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final String monthName = _getMonthName(loc, selectedMonth);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: LuminaColors.cardMint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: LuminaColors.cardMintBorder.withValues(alpha: 0.6),
          width: 1,
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
