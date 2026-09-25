import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_state.dart';

class AnalyticsTrendChart extends StatelessWidget {
  const AnalyticsTrendChart({
    super.key,
    required this.state,
    required this.currencySymbol,
    required this.height,
    required this.onHorizontalDragEnd,
  });

  final AnalyticsState state;
  final String currencySymbol;
  final double height;
  final GestureDragEndCallback onHorizontalDragEnd;

  @override
  Widget build(BuildContext context) {
    final whole = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    )..maximumFractionDigits = 0;

    return GestureDetector(
      onHorizontalDragEnd: onHorizontalDragEnd,
      child: SizedBox(
        height: height,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: Color(0xFFE2E8F0),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => LuminaColors.accent,
                getTooltipItems: (spots) {
                  return spots.map((spot) {
                    return LineTooltipItem(
                      '${whole.format(spot.y)} $currencySymbol',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList();
                },
              ),
              getTouchedSpotIndicator: (barData, indexes) {
                return indexes.map((_) {
                  return TouchedSpotIndicatorData(
                    FlLine(
                      color: LuminaColors.accent.withValues(alpha: 0.3),
                      strokeWidth: 2,
                    ),
                    FlDotData(
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: LuminaColors.accent,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  );
                }).toList();
              },
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 5,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: LuminaColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: state.dailyPoints
                    .map((p) => FlSpot(p.day.toDouble(), p.amount))
                    .toList(),
                isCurved: true,
                curveSmoothness: 0.25,
                color: LuminaColors.accent,
                barWidth: 3.5,
                isStrokeCapRound: true,
                isStrokeJoinRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: LuminaColors.accent.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
