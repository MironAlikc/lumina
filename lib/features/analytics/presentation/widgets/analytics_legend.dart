import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_state.dart';

class AnalyticsLegend extends StatelessWidget {
  const AnalyticsLegend({
    super.key,
    required this.slices,
    required this.totalSpent,
    required this.currencySymbol,
    required this.onSliceTap,
    required this.onSliceLongPress,
  });

  final List<AnalyticsSlice> slices;
  final double totalSpent;
  final String currencySymbol;
  final ValueChanged<AnalyticsSlice> onSliceTap;
  final ValueChanged<AnalyticsSlice> onSliceLongPress;

  @override
  Widget build(BuildContext context) {
    final whole = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    )..maximumFractionDigits = 0;

    return Column(
      children: [
        for (final slice in slices)
          Material(
            color: Colors.transparent,
            borderRadius: LuminaDimensions.borderRadiusMedium,
            child: InkWell(
              onTap: () => onSliceTap(slice),
              onLongPress: () {
                HapticFeedback.mediumImpact();
                onSliceLongPress(slice);
              },
              borderRadius: LuminaDimensions.borderRadiusMedium,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: EdgeInsets.all(LuminaDimensions.paddingM),
                decoration: BoxDecoration(
                  color: LuminaColors.surface,
                  borderRadius: LuminaDimensions.borderRadiusMedium,
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 12, color: Color(slice.colorHex)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slice.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: LuminaColors.textMain,
                            ),
                          ),
                          Text(
                            '${slice.percentOf(totalSpent).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: LuminaColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${whole.format(slice.amount)} $currencySymbol',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: LuminaColors.textMain,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: LuminaColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
