import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

  void _openCategoryHistory(BuildContext context, AnalyticsSlice slice) {
    final analyticsDate = context.read<AnalyticsCubit>().state.selectedDate;
    final historyCubit = context.read<HistoryCubit>();

    historyCubit.changeMonth(analyticsDate.month, analyticsDate.year);

    if (slice.categoryId != 'unknown') {
      historyCubit.changeCategoryFilter(slice.categoryId);
    } else {
      historyCubit.changeCategoryFilter(null);
    }

    context.push('/history');
  }

  List<HistoryExpenseModel> _topTransactionsFor(
    AnalyticsState state,
    AnalyticsSlice slice,
  ) {
    final matches = state.monthExpenses.where((e) {
      final key = e.categoryId.isEmpty ? 'unknown' : e.categoryId;
      return key == slice.categoryId;
    }).toList()..sort((a, b) => b.price.compareTo(a.price));
    return matches.take(3).toList();
  }

  void _showCategoryPreview(
    BuildContext context,
    AnalyticsState state,
    AnalyticsSlice slice,
  ) {
    final currencySymbol = context.read<CurrencyCubit>().state.symbol;
    final transactions = _topTransactionsFor(state, slice);

    showDialog(
      context: context,
      builder: (dialogContext) => _CategoryQuickPreview(
        slice: slice,
        transactions: transactions,
        currencySymbol: currencySymbol,
        onViewAll: () => _openCategoryHistory(context, slice),
      ),
    );
  }

  void _handleSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -250) {
      _changeMonth(1);
    } else if (velocity > 250) {
      _changeMonth(-1);
    }
  }

  bool _isValidSlice(int index, int length) {
    return index >= 0 && index < length;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currencySymbol = context.watch<CurrencyCubit>().state.symbol;
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final whole = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    )..maximumFractionDigits = 0;

    return MultiBlocListener(
      listeners: [
        BlocListener<HistoryCubit, HistoryState>(
          listenWhen: (prev, curr) => prev.allRecords != curr.allRecords,
          listener: (_, _) => _refreshAnalytics(),
        ),
        BlocListener<CategoriesCubit, CategoriesState>(
          listenWhen: (prev, curr) => prev != curr,
          listener: (_, _) => _refreshAnalytics(),
        ),
      ],
      child: Scaffold(
        backgroundColor: LuminaColors.background,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<AnalyticsCubit, AnalyticsState>(
            builder: (context, state) {
              if (state.isLoading) return const LuminaLoadingWidget();
              if (state.errorMessage != null) {
                return ErrorView(
                  message: state.errorMessage!,
                  onRetry: _refreshAnalytics,
                );
              }

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 700 : double.infinity,
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      MediaQuery.paddingOf(context).bottom + 120,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _MonthSelector(
                          selectedDate: state.selectedDate,
                          onPrev: () => _changeMonth(-1),
                          onNext: () => _changeMonth(1),
                        ),
                        const SizedBox(height: 16),
                        if (state.slices.isNotEmpty) ...[
                          _ChartModeSwitcher(
                            isLineMode: state.isLineChartMode,
                            categoriesLabel: loc.analyticsCategoriesTab,
                            trendLabel: loc.analyticsTrendTab,
                            onChanged: (isLine) => context
                                .read<AnalyticsCubit>()
                                .toggleChartMode(isLine),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _InsightCard(message: state.insightMessage),
                        const SizedBox(height: 24),
                        if (state.slices.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                const Text(
                                  '📊',
                                  style: TextStyle(fontSize: 48),
                                ),
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
                        else if (state.isLineChartMode) ...[
                          GestureDetector(
                            onHorizontalDragEnd: _handleSwipe,
                            child: SizedBox(
                              height: isTablet ? 320 : 250,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: 1,
                                    getDrawingHorizontalLine: (value) {
                                      return const FlLine(
                                        color: Color(0xFFE2E8F0),
                                        strokeWidth: 1,
                                        dashArray: [5, 5],
                                      );
                                    },
                                  ),
                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipColor: (_) =>
                                          LuminaColors.accent,
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
                                    getTouchedSpotIndicator:
                                        (barData, indexes) {
                                          return indexes.map((_) {
                                            return TouchedSpotIndicatorData(
                                              FlLine(
                                                color: LuminaColors.accent
                                                    .withValues(alpha: 0.3),
                                                strokeWidth: 2,
                                              ),
                                              FlDotData(
                                                getDotPainter:
                                                    (
                                                      spot,
                                                      percent,
                                                      bar,
                                                      index,
                                                    ) {
                                                      return FlDotCirclePainter(
                                                        radius: 5,
                                                        color:
                                                            LuminaColors.accent,
                                                        strokeWidth: 2,
                                                        strokeColor:
                                                            Colors.white,
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
                                            padding: const EdgeInsets.only(
                                              top: 6,
                                            ),
                                            child: Text(
                                              value.toInt().toString(),
                                              style: const TextStyle(
                                                color:
                                                    LuminaColors.textSecondary,
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
                                          .map(
                                            (p) => FlSpot(
                                              p.day.toDouble(),
                                              p.amount,
                                            ),
                                          )
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
                                        color: LuminaColors.accent.withValues(
                                          alpha: 0.15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: LuminaDimensions.paddingXL),
                        ] else ...[
                          GestureDetector(
                            onHorizontalDragEnd: _handleSwipe,
                            child: SizedBox(
                              height: isTablet ? 320 : 250,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: isTablet ? 70 : 50,
                                      pieTouchData: PieTouchData(
                                        touchCallback: (event, response) {
                                          final sectionIndex =
                                              response
                                                  ?.touchedSection
                                                  ?.touchedSectionIndex ??
                                              -1;
                                          final len = state.slices.length;

                                          if (event is FlLongPressStart) {
                                            if (_isValidSlice(
                                              sectionIndex,
                                              len,
                                            )) {
                                              HapticFeedback.mediumImpact();
                                              _showCategoryPreview(
                                                context,
                                                state,
                                                state.slices[sectionIndex],
                                              );
                                            }
                                            return;
                                          }

                                          if (!event
                                                  .isInterestedForInteractions ||
                                              sectionIndex < 0) {
                                            setState(() => touchedIndex = -1);
                                            return;
                                          }

                                          setState(
                                            () => touchedIndex = sectionIndex,
                                          );

                                          if (event is FlTapUpEvent &&
                                              _isValidSlice(
                                                sectionIndex,
                                                len,
                                              )) {
                                            _openCategoryHistory(
                                              context,
                                              state.slices[sectionIndex],
                                            );
                                          }
                                        },
                                      ),
                                      sections: _sections(state),
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
                                        '${whole.format(state.totalSpent)} $currencySymbol',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: LuminaColors.textMain,
                                        ),
                                      ),
                                      if (state.previousMonthTotal != null &&
                                          state.previousMonthTotal! > 0)
                                        _ComparisonBadge(
                                          percentChange:
                                              ((state.totalSpent -
                                                      state
                                                          .previousMonthTotal!) /
                                                  state.previousMonthTotal!) *
                                              100,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: LuminaDimensions.paddingXL),
                          _Legend(
                            slices: state.slices,
                            totalSpent: state.totalSpent,
                            currencySymbol: currencySymbol,
                            onSliceTap: (slice) =>
                                _openCategoryHistory(context, slice),
                            onSliceLongPress: (slice) =>
                                _showCategoryPreview(context, state, slice),
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

class _ComparisonBadge extends StatelessWidget {
  const _ComparisonBadge({required this.percentChange});

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

class _CategoryQuickPreview extends StatelessWidget {
  const _CategoryQuickPreview({
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
                  onPressed: () => Navigator.of(context).pop(),
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
                  Navigator.of(context).pop();
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

class _ChartModeSwitcher extends StatelessWidget {
  const _ChartModeSwitcher({
    required this.isLineMode,
    required this.categoriesLabel,
    required this.trendLabel,
    required this.onChanged,
  });

  final bool isLineMode;
  final String categoriesLabel;
  final String trendLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: LuminaColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: LuminaColors.cardMintBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !isLineMode
                      ? LuminaColors.cardMint
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  categoriesLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: !isLineMode
                        ? LuminaColors.textMain
                        : LuminaColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isLineMode
                      ? LuminaColors.cardMint
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  trendLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isLineMode
                        ? LuminaColors.textMain
                        : LuminaColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
