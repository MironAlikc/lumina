import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/core/widgets/error_view.dart';
import 'package:lumina/core/widgets/lumina_loading_widget.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_cubit.dart';
import 'package:lumina/features/analytics/presentation/cubits/analytics_state.dart';
import 'package:lumina/features/analytics/presentation/widgets/analytics_widgets.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_state.dart';
import 'package:lumina/l10n/app_localizations.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAnalytics());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Названия категорий и инсайт считаются с учётом языка: при его смене
    // данные нужно пересчитать.
    final locale = Localizations.localeOf(context);
    final changed = _locale != null && _locale != locale;
    _locale = locale;
    if (changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAnalytics());
    }
  }

  List<HistoryExpenseModel> _records() => context
      .read<HistoryCubit>()
      .state
      .allRecords
      .map(HistoryExpenseModel.fromEntity)
      .toList();

  List<CustomCategory> _categories() {
    final state = context.read<CategoriesCubit>().state;
    return state is CategoriesLoaded ? state.categories : const [];
  }

  /// Только пересчёт. Загрузка данных - ответственность HistoryCubit:
  /// вызов loadRecords() отсюда вместе с listener'ом на allRecords создавал
  /// бесконечный цикл для пользователей без операций.
  void _refreshAnalytics() {
    if (!mounted) return;
    context.read<AnalyticsCubit>().calculateAnalytics(
          _records(),
          _categories(),
          AppLocalizations.of(context)!,
        );
  }

  void _changeMonth(int monthsOffset) {
    if (!mounted) return;
    final cubit = context.read<AnalyticsCubit>();
    final current = cubit.state.selectedDate;

    cubit.changeDate(
      DateTime(current.year, current.month + monthsOffset),
      _records(),
      _categories(),
      AppLocalizations.of(context)!,
    );
  }

  Future<void> _openCategoryHistory(AnalyticsSlice slice) async {
    final date = context.read<AnalyticsCubit>().state.selectedDate;
    final history = context.read<HistoryCubit>();

    history
      ..changeMonth(date.month, date.year)
      ..changeFilter(HistoryFilterType.expense)
      ..changeCategoryFilter(
        slice.categoryId == 'unknown' ? null : slice.categoryId,
      );

    await context.push('/history');

    // Возвращаемся: сбрасываем фильтры, чтобы они не «залипали» в истории.
    history
      ..changeCategoryFilter(null)
      ..changeFilter(HistoryFilterType.all);
  }

  void _showCategoryPreview(AnalyticsSlice slice) {
    final state = context.read<AnalyticsCubit>().state;
    final matches = state.monthExpenses.where((e) {
      final key = e.categoryId.isEmpty ? 'unknown' : e.categoryId;
      return key == slice.categoryId;
    }).toList()
      ..sort((a, b) => b.price.compareTo(a.price));

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (_) => AnalyticsCategoryPreview(
        slice: slice,
        transactions: matches.take(3).toList(),
        currencySymbol: context.read<CurrencyCubit>().state.symbol,
        onViewAll: () => _openCategoryHistory(slice),
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currencySymbol = context.watch<CurrencyCubit>().state.symbol;
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final chartHeight = isTablet ? 320.0 : 250.0;

    return MultiBlocListener(
      listeners: [
        BlocListener<HistoryCubit, HistoryState>(
          // HistoryExpense - Equatable, поэтому сравнение по значению
          // срабатывает только при реальном изменении данных.
          listenWhen: (prev, curr) =>
              !listEquals(prev.allRecords, curr.allRecords),
          listener: (_, __) => _refreshAnalytics(),
        ),
        BlocListener<CategoriesCubit, CategoriesState>(
          listenWhen: (prev, curr) => prev != curr,
          listener: (_, __) => _refreshAnalytics(),
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
                  message: loc.analyticsError,
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
                        AnalyticsMonthSelector(
                          selectedDate: state.selectedDate,
                          onPrev: () => _changeMonth(-1),
                          onNext: () => _changeMonth(1),
                        ),
                        const SizedBox(height: 16),
                        if (state.slices.isNotEmpty) ...[
                          AnalyticsChartModeSwitcher(
                            isLineMode: state.isLineChartMode,
                            categoriesLabel: loc.analyticsCategoriesTab,
                            trendLabel: loc.analyticsTrendTab,
                            onChanged: (isLine) => context
                                .read<AnalyticsCubit>()
                                .toggleChartMode(isLine),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (state.insightMessage.trim().isNotEmpty) ...[
                          AnalyticsInsightCard(message: state.insightMessage),
                          const SizedBox(height: 24),
                        ],
                        if (state.slices.isEmpty)
                          const AnalyticsEmptyMonth()
                        else if (state.isLineChartMode) ...[
                          AnalyticsTrendChart(
                            state: state,
                            currencySymbol: currencySymbol,
                            height: chartHeight,
                            onHorizontalDragEnd: _handleSwipe,
                          ),
                          const SizedBox(height: LuminaDimensions.paddingXL),
                        ] else ...[
                          AnalyticsPieChart(
                            state: state,
                            currencySymbol: currencySymbol,
                            height: chartHeight,
                            centerRadius: isTablet ? 70 : 50,
                            onSliceTap: _openCategoryHistory,
                            onSliceLongPress: _showCategoryPreview,
                            onHorizontalDragEnd: _handleSwipe,
                          ),
                          const SizedBox(height: LuminaDimensions.paddingXL),
                          AnalyticsLegend(
                            slices: state.slices,
                            totalSpent: state.totalSpent,
                            currencySymbol: currencySymbol,
                            onSliceTap: _openCategoryHistory,
                            onSliceLongPress: _showCategoryPreview,
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
}
