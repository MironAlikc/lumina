import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/utils/date_labels.dart';
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

  void _shift(int delta) {
    HapticFeedback.selectionClick();
    // DateTime сам переносит через границу года.
    final target = DateTime(selectedYear, selectedMonth + delta);
    onMonthChanged(target.month, target.year);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final label =
        DateLabels.monthYear(locale, DateTime(selectedYear, selectedMonth));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: LuminaColors.cardMint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: LuminaColors.cardMintBorder.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: loc.previousMonth,
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: LuminaColors.textMain,
              size: 22,
            ),
            onPressed: () => _shift(-1),
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 15,
                  color: LuminaColors.accent,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LuminaColors.textMain,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: loc.nextMonth,
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: LuminaColors.textMain,
              size: 22,
            ),
            onPressed: () => _shift(1),
          ),
        ],
      ),
    );
  }
}
