import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/core/widgets/error_view.dart';
import 'package:lumina/core/widgets/lumina_loading_widget.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_cubit.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_state.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';
import 'package:lumina/features/history/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/categories_state.dart';
import 'package:lumina/features/history/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/history_state.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/presentation/cubits/currency/currency_cubit.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAnalytics());
  }

  void _refreshAnalytics() {
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    final historyState = context.read<HistoryCubit>().state;
    final categoriesState = context.read<CategoriesCubit>().state;
    if (categoriesState is! CategoriesLoaded) return;

    // HistoryState хранит доменные сущности HistoryExpense (Clean Architecture),
    // а AnalyticsCubit ожидает Hive-модель HistoryExpenseModel — конвертируем.
    context.read<AnalyticsCubit>().calculateAnalytics(
      historyState.allRecords.map(HistoryExpenseModel.fromEntity).toList(),
      categoriesState.categories,
      loc,
    );
  }

  void _changeMonth(int monthsOffset) {
    final loc = AppLocalizations.of(context)!;
    final current = context.read<AnalyticsCubit>().state.selectedDate;
    final newDate = DateTime(current.year, current.month + monthsOffset);
    final historyState = context.read<HistoryCubit>().state;
    final categoriesState = context.read<CategoriesCubit>().state;
    if (categoriesState is! CategoriesLoaded) return;

    context.read<AnalyticsCubit>().changeDate(
      newDate,
      historyState.allRecords.map(HistoryExpenseModel.fromEntity).toList(),
      categoriesState.categories,
      loc,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currencySymbol = context.watch<CurrencyCubit>().state.symbol;
    final isTablet = MediaQuery.sizeOf(context).width > 600;

    return MultiBlocListener(
      listeners: [
        BlocListener<HistoryCubit, HistoryState>(
          listenWhen: (prev, curr) => prev.allRecords != curr.allRecords,
          listener: (_, __) => _refreshAnalytics(),
        ),
        BlocListener<CategoriesCubit, CategoriesState>(
          listenWhen: (prev, curr) => prev != curr,
          listener: (_, __) => _refreshAnalytics(),
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
                  padding: EdgeInsets.fromLTRB(
                    LuminaDimensions.paddingXL,
                    LuminaDimensions.paddingXL,
                    LuminaDimensions.paddingXL,
                    MediaQuery.paddingOf(context).bottom + 98,
                  ),
                  child: Column(
                    children: [
                      _MonthSelector(
                        selectedDate: state.selectedDate,
                        onPrev: () => _changeMonth(-1),
                        onNext: () => _changeMonth(1),
                      ),
                      const SizedBox(height: 20),
                      _InsightCard(message: state.insightMessage),
                      const SizedBox(height: 24),
                      if (state.slices.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              const Text('📊', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 16),
                              Text(
                                loc.noExpensesForMonth,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
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
                              sectionsSpace: 2,
                              centerSpaceRadius: isTablet ? 70 : 50,
                              pieTouchData: PieTouchData(
                                touchCallback: (event, response) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        response?.touchedSection == null) {
                                      touchedIndex = -1;
                                      return;
                                    }
                                    touchedIndex = response!
                                        .touchedSection!
                                        .touchedSectionIndex;
                                  });
                                },
                              ),
                              sections: _sections(state),
                            ),
                          ),
                        ),
                        const SizedBox(height: LuminaDimensions.paddingXL),
                        _Legend(
                          slices: state.slices,
                          totalSpent: state.totalSpent,
                          currencySymbol: currencySymbol,
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

  List<PieChartSectionData> _sections(AnalyticsState state) {
    return state.slices.asMap().entries.map((entry) {
      final index = entry.key;
      final slice = entry.value;
      final isTouched = index == touchedIndex;
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
    }).toList();
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.selectedDate,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime selectedDate;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final raw = DateFormat('LLLL yyyy', locale).format(selectedDate);
    final label = raw[0].toUpperCase() + raw.substring(1);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            onPressed: onPrev,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 15,
                color: LuminaColors.accent,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: LuminaColors.textMain,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
            onPressed: onNext,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
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
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.slices,
    required this.totalSpent,
    required this.currencySymbol,
  });

  final List<AnalyticsSlice> slices;
  final double totalSpent;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final slice in slices)
          Container(
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
                  '${slice.amount.toStringAsFixed(0)} $currencySymbol',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: LuminaColors.textMain,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
