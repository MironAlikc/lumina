import 'package:flutter/material.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/l10n/app_localizations.dart';

class AnalyticsComparisonBadge extends StatelessWidget {
  const AnalyticsComparisonBadge({super.key, required this.percentChange});

  final double percentChange;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isIncrease = percentChange > 0;
    final color = isIncrease ? LuminaColors.error : LuminaColors.success;
    final absPercent = percentChange.abs().toStringAsFixed(0);
    final label = isIncrease
        ? loc.moreThanLastMonth(absPercent)
        : loc.lessThanLastMonth(absPercent);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isIncrease
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
