import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../history/presentation/cubits/history_cubit.dart';
import '../../../history/presentation/cubits/history_state.dart';
import '../cubits/analytics_cubit.dart';
import '../cubits/analytics_state.dart';

class AnalyticsView extends StatelessWidget {
  const AnalyticsView({Key? key}) : super(key: key);

  // Палитра мягких стильных цветов для секторов диаграммы
  List<Color> get _chartColors => const [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
  ];

  @override
  Widget build(BuildContext context) {
    // Важнейшая связка: Триггерим расчет аналитики каждый раз, когда меняются данные в основном HistoryCubit
    final historyExpenses = context.watch<HistoryCubit>().state.expenses;
    context.read<AnalyticsCubit>().calculateAnalytics(historyExpenses);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Аналитика трат',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: BlocBuilder<AnalyticsCubit, AnalyticsState>(
        builder: (context, state) {
          if (state.categoryData.isEmpty) {
            return const Center(
              child: Text('Добавьте расходы, чтобы увидеть графики аналитики'),
            );
          }

          // Преобразуем сгруппированные данные в сектора PieChartSectionData
          int colorIndex = 0;
          final List<PieChartSectionData> sections = state.categoryData.entries
              .map((entry) {
                final color = _chartColors[colorIndex % _chartColors.length];
                colorIndex++;

                final double percentage = state.totalSpent > 0
                    ? (entry.value / state.totalSpent) * 100
                    : 0.0;

                return PieChartSectionData(
                  color: color,
                  value: entry.value,
                  title: percentage > 8
                      ? '${percentage.toStringAsFixed(0)}%'
                      : '',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              })
              .toList();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // КАРТОЧКА УМНОЙ АНАЛИТИКИ И ТРЕНДОВ
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF), // Нежно-голубой фон
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFBFDBFE),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          state.insightMessage,
                          style: const TextStyle(
                            color: Color(0xFF1E40AF),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                const Text(
                  'Распределение по продуктам',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 20),

                // ГРАФИК PIE CHART
                Container(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 50,
                      sections: sections,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ЛЕГЕНДА ДЛЯ ДИАГРАММЫ (Список элементов)
                Column(
                  children: (() {
                    int idx = 0;
                    return state.categoryData.entries.map((entry) {
                      final color = _chartColors[idx % _chartColors.length];
                      idx++;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${entry.value.toStringAsFixed(2)} ₴',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  })(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
