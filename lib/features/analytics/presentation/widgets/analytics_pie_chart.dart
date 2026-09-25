import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_state.dart';
import 'package:lumina/features/analytics/presentation/widgets/analytics_comparison_badge.dart';
import 'package:lumina/l10n/app_localizations.dart';

class AnalyticsPieChart extends StatefulWidget {
  const AnalyticsPieChart({
    super.key,
    required this.state,
    required this.currencySymbol,
    required this.height,
    required this.centerRadius,
    required this.onSliceTap,
    required this.onSliceLongPress,
    required this.onHorizontalDragEnd,
  });

  final AnalyticsState state;
  final String currencySymbol;
  final double height;
  final double centerRadius;
  final ValueChanged<AnalyticsSlice> onSliceTap;
  final ValueChanged<AnalyticsSlice> onSliceLongPress;
  final GestureDragEndCallback onHorizontalDragEnd;

  @override
  State<AnalyticsPieChart> createState() => _AnalyticsPieChartState();
}

class _AnalyticsPieChartState extends State<AnalyticsPieChart> {
  int _touchedIndex = -1;

  bool _isValid(int index) => index >= 0 && index < widget.state.slices.length;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final whole = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    )..maximumFractionDigits = 0;
    final state = widget.state;

    return GestureDetector(
      onHorizontalDragEnd: widget.onHorizontalDragEnd,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: widget.centerRadius,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    final sectionIndex =
                        response?.touchedSection?.touchedSectionIndex ?? -1;

                    if (event is FlLongPressStart) {
                      if (_isValid(sectionIndex)) {
                        HapticFeedback.mediumImpact();
                        widget.onSliceLongPress(state.slices[sectionIndex]);
                      }
                      return;
                    }

                    if (!event.isInterestedForInteractions ||
                        sectionIndex < 0) {
                      setState(() => _touchedIndex = -1);
                      return;
                    }

                    setState(() => _touchedIndex = sectionIndex);

                    if (event is FlTapUpEvent && _isValid(sectionIndex)) {
                      widget.onSliceTap(state.slices[sectionIndex]);
                    }
                  },
                ),
                sections: state.slices.asMap().entries.map((entry) {
                  final isTouched = entry.key == _touchedIndex;
                  final slice = entry.value;
                  final percent = slice.percentOf(state.totalSpent);
                  return PieChartSectionData(
                    color: Color(slice.colorHex),
                    value: slice.amount,
                    title: percent >= 8 ? '${percent.toStringAsFixed(0)}%' : '',
                    radius: isTouched ? 65 : 52,
                    titleStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.total,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: LuminaColors.textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${whole.format(state.totalSpent)} ${widget.currencySymbol}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: LuminaColors.textMain,
                  ),
                ),
                if (state.previousMonthTotal != null &&
                    state.previousMonthTotal! > 0)
                  AnalyticsComparisonBadge(
                    percentChange:
                        ((state.totalSpent - state.previousMonthTotal!) /
                            state.previousMonthTotal!) *
                        100,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
