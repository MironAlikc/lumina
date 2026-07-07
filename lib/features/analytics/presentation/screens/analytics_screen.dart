import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lumina/core/widgets/error_view.dart';
import 'package:lumina/core/widgets/lumina_loading_widget.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_state.dart';
import '../../../history/presentation/cubits/history_cubit.dart';
import '../cubits/analytics_cubit.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    // Принудительный запуск расчета при создании экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final records = context.read<HistoryCubit>().state.allRecords;
      context.read<AnalyticsCubit>().calculateAnalytics(records);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HistoryCubit, dynamic>(
      listenWhen: (prev, curr) => prev.allRecords != curr.allRecords,
      listener: (context, state) {
        context.read<AnalyticsCubit>().calculateAnalytics(state.allRecords);
      },
      child: Scaffold(
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
        ),
        body: BlocBuilder<AnalyticsCubit, AnalyticsState>(
          builder: (context, state) {
            if (state.isLoading) return const LuminaLoadingWidget();

            if (state.errorMessage != null) {
              return ErrorView(
                message: state.errorMessage!,
                onRetry: () =>
                    context.read<AnalyticsCubit>().calculateAnalytics(
                      context.read<HistoryCubit>().state.allRecords,
                    ),
              );
            }

            if (state.categoryData.isEmpty) {
              return const Center(
                child: Text(
                  'Нет данных для анализа',
                  style: TextStyle(color: Colors.black45),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildInsightCard(state.insightMessage),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: _generateSections(state),
                        centerSpaceRadius: 50,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLegend(state.categoryData),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<PieChartSectionData> _generateSections(AnalyticsState state) {
    const colors = [
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF06B6D4),
    ];
    return state.categoryData.entries.toList().asMap().entries.map((entry) {
      final color = colors[entry.key % colors.length];
      final percent = (entry.value.value / state.totalSpent) * 100;
      return PieChartSectionData(
        color: color,
        value: entry.value.value,
        title: percent > 8 ? '${percent.toStringAsFixed(0)}%' : '',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildInsightCard(String message) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFBFDBFE)),
    ),
    child: Row(
      children: [
        const Text('💡', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Color(0xFF1E40AF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildLegend(Map<String, double> data) {
    const colors = [
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF06B6D4),
    ];
    return Column(
      children: data.entries
          .toList()
          .asMap()
          .entries
          .map(
            (e) => Container(
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
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: colors[e.key % colors.length],
                      ),
                      const SizedBox(width: 12),
                      Text(e.value.key),
                    ],
                  ),
                  Text(
                    '${e.value.value.toStringAsFixed(2)} ₴',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
