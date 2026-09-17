import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/core/widgets/error_view.dart';
import 'package:lumina/core/widgets/lumina_loading_widget.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_state.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_cubit.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/presentation/cubits/currency/currency_cubit.dart';
import '../../../history/presentation/cubits/history_cubit.dart';
import '../../../history/presentation/cubits/history_state.dart';
import '../../../history/presentation/cubits/categories_cubit.dart';
import '../../../history/presentation/cubits/categories_state.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  static const List<Color> _chartColors = [
    LuminaColors.primary,
    LuminaColors.success,
    Color(0xFFF59E0B),
    LuminaColors.error,
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
  ];

  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAnalytics());
  }

  void _refreshAnalytics() {
    if (!mounted) return;
    final historyState = context.read<HistoryCubit>().state;
    final categoriesState = context.read<CategoriesCubit>().state;

    if (categoriesState is CategoriesLoaded) {
      final expenseModels = historyState.allRecords
          .map((entity) => HistoryExpenseModel.fromEntity(entity))
          .toList();

      context.read<AnalyticsCubit>().calculateAnalytics(
        expenseModels,
        categoriesState.categories,
      );
    }
  }

  void _changeMonth(int monthsOffset) {
    final currentState = context.read<AnalyticsCubit>().state;
    final newDate = DateTime(
      currentState.selectedDate.year,
      currentState.selectedDate.month + monthsOffset,
      1,
    );

    final historyState = context.read<HistoryCubit>().state;
    final categoriesState = context.read<CategoriesCubit>().state;

    if (categoriesState is CategoriesLoaded) {
      final expenseModels = historyState.allRecords
          .map((entity) => HistoryExpenseModel.fromEntity(entity))
          .toList();

      context.read<AnalyticsCubit>().changeDate(
        newDate,
        expenseModels,
        categoriesState.categories,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<CurrencyCubit>().state.symbol;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return MultiBlocListener(
      listeners: [
        BlocListener<HistoryCubit, HistoryState>(
          listenWhen: (prev, curr) => prev.allRecords != curr.allRecords,
          listener: (context, state) => _refreshAnalytics(),
        ),
        BlocListener<CategoriesCubit, CategoriesState>(
          listenWhen: (prev, curr) => prev != curr,
          listener: (context, state) => _refreshAnalytics(),
        ),
      ],
      child: Scaffold(
        backgroundColor: LuminaColors.background,

        body: BlocBuilder<AnalyticsCubit, AnalyticsState>(
          builder: (context, state) {
            if (state.isLoading) return const LuminaLoadingWidget();
            if (state.errorMessage != null) {
              return ErrorView(
                message: state.errorMessage!,
                onRetry: _refreshAnalytics,
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 700 : double.infinity,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(LuminaDimensions.paddingXL),
                  child: Column(
                    children: [
                      _buildMonthSelector(state.selectedDate),
                      const SizedBox(height: 20),
                      _buildInsightCard(state.insightMessage),
                      const SizedBox(height: 24),
                      if (state.categoryData.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: const [
                              Text('📊', style: TextStyle(fontSize: 48)),
                              SizedBox(height: 16),
                              Text(
                                'Нет данных за этот месяц',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: LuminaColors.textMain,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        SizedBox(
                          height: isTablet ? 320 : 250,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection ==
                                            null) {
                                      touchedIndex = -1;
                                      return;
                                    }
                                    touchedIndex = pieTouchResponse
                                        .touchedSection!
                                        .touchedSectionIndex;
                                  });
                                },
                              ),
                              sections: _generateSections(state),
                              centerSpaceRadius: isTablet ? 70 : 50,
                            ),
                          ),
                        ),
                        const SizedBox(height: LuminaDimensions.paddingXL),
                        _buildLegend(
                          state.categoryData,
                          state.totalSpent,
                          currencySymbol,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonthSelector(DateTime selectedDate) {
    final loc = AppLocalizations.of(context)!;
    // Можно использовать локализованное имя месяца или через DateFormat
    final formattedMonth = DateFormat(
      'MMMM yyyy',
      Localizations.localeOf(context).languageCode,
    ).format(selectedDate);
    final capitalizedMonth =
        formattedMonth[0].toUpperCase() + formattedMonth.substring(1);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
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
            onPressed: () => _changeMonth(-1),
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
                capitalizedMonth,
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
            onPressed: () => _changeMonth(1),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateSections(AnalyticsState state) {
    final entries = state.categoryData.entries.toList();
    return entries.asMap().entries.map((mapEntry) {
      final index = mapEntry.key;
      final entry = mapEntry.value;
      final isTouched = index == touchedIndex;
      final color = _chartColors[index % _chartColors.length];
      final percentage = state.totalSpent > 0
          ? (entry.value / state.totalSpent * 100)
          : 0.0;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: isTouched ? 65 : 52,
        titleStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(
    Map<String, double> data,
    double totalSpent,
    String currencySymbol,
  ) {
    final entries = data.entries.toList();
    return Column(
      children: entries.asMap().entries.map((mapEntry) {
        final index = mapEntry.key;
        final entry = mapEntry.value;
        final color = _chartColors[index % _chartColors.length];
        final percentage = totalSpent > 0
            ? (entry.value / totalSpent * 100)
            : 0.0;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: EdgeInsets.all(LuminaDimensions.paddingM),
          decoration: BoxDecoration(
            color: LuminaColors.surface,
            borderRadius: LuminaDimensions.borderRadiusMedium,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 12, color: color),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: LuminaColors.textMain,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: LuminaColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${entry.value.toStringAsFixed(0)} $currencySymbol',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: LuminaColors.textMain,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInsightCard(String message) => Container(
    padding: EdgeInsets.all(LuminaDimensions.paddingL),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF6FF),
      borderRadius: LuminaDimensions.borderRadiusLarge,
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
}
