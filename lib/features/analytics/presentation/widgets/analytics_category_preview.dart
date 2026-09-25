import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_state.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';
import 'package:lumina/l10n/app_localizations.dart';

class AnalyticsCategoryPreview extends StatelessWidget {
  const AnalyticsCategoryPreview({
    super.key,
    required this.slice,
    required this.transactions,
    required this.currencySymbol,
    required this.onViewAll,
  });

  final AnalyticsSlice slice;
  final List<HistoryExpenseModel> transactions;
  final String currencySymbol;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final whole = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    )..maximumFractionDigits = 0;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Color(slice.colorHex),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    slice.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: LuminaColors.textMain,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              loc.topTransactions,
              style: const TextStyle(
                fontSize: 11,
                color: LuminaColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            if (transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  loc.noExpensesForPeriod,
                  style: const TextStyle(color: LuminaColors.textSecondary),
                ),
              )
            else
              ...transactions.map(
                (t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.productName.isNotEmpty ? t.productName : slice.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: LuminaColors.textMain,
                          ),
                        ),
                      ),
                      Text(
                        '${whole.format(t.price)} $currencySymbol',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: LuminaColors.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  onViewAll();
                },
                style: TextButton.styleFrom(
                  backgroundColor: LuminaColors.cardMint,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  loc.seeAll,
                  style: const TextStyle(
                    color: LuminaColors.accentDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
