import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/core/widgets/responsive_layout.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';
import 'package:lumina/features/dashboard/presentation/widgets/dashboard_filter_row.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_state.dart';
import 'package:lumina/features/transactions/presentation/widgets/calendar/monthly_calendar_widget.dart';
import 'package:lumina/features/transactions/presentation/widgets/grouped_transactions_list.dart';
import 'package:lumina/features/transactions/presentation/widgets/matrix/monthly_matrix_widget.dart';
import 'package:lumina/features/transactions/presentation/widgets/month_chips_bar.dart';
import 'package:lumina/l10n/app_localizations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currencySymbol = context.watch<CurrencyCubit>().state.symbol;
    final bottomGap = MediaQuery.paddingOf(context).bottom + 24;

    return Scaffold(
      backgroundColor: LuminaColors.background,
      appBar: AppBar(
        backgroundColor: LuminaColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          loc.history,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: LuminaTheme.textColor,
            fontSize: 18,
          ),
        ),
        actions: [
          BlocBuilder<HistoryCubit, HistoryState>(
            buildWhen: (p, n) => p.viewMode != n.viewMode,
            builder: (context, state) {
              return IconButton(
                icon: Icon(
                  switch (state.viewMode) {
                    HistoryViewMode.list => Icons.calendar_month_rounded,
                    HistoryViewMode.calendar => Icons.table_chart_rounded,
                    HistoryViewMode.table => Icons.format_list_bulleted_rounded,
                  },
                  color: LuminaColors.primary,
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  final nextMode = switch (state.viewMode) {
                    HistoryViewMode.list => HistoryViewMode.calendar,
                    HistoryViewMode.calendar => HistoryViewMode.table,
                    HistoryViewMode.table => HistoryViewMode.list,
                  };
                  context.read<HistoryCubit>().toggleViewMode(nextMode);
                },
              );
            },
          ),
        ],
      ),
      body: ResponsiveLayout(
        child: BlocBuilder<HistoryCubit, HistoryState>(
          builder: (context, historyState) {
            return BlocBuilder<CategoriesCubit, CategoriesState>(
              builder: (context, categoryState) {
                final categories = categoryState is CategoriesLoaded
                    ? categoryState.categories
                    : const <CustomCategory>[];
                final cubit = context.read<HistoryCubit>();
                final viewMode = historyState.viewMode;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 4)),
                    const SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(child: MonthChipsBar()),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    if (viewMode == HistoryViewMode.list) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: cubit.changeSearchQuery,
                            decoration: InputDecoration(
                              hintText: loc.search,
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: LuminaColors.textSecondary,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        cubit.changeSearchQuery('');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: LuminaColors.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      const SliverToBoxAdapter(child: DashboardFilterRow()),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      GroupedTransactionsList(
                        records: historyState.filteredRecords
                            .map(HistoryExpenseModel.fromEntity)
                            .toList(),
                        categories: categories,
                        currencySymbol: currencySymbol,
                      ),
                    ] else if (viewMode == HistoryViewMode.calendar) ...[
                      SliverToBoxAdapter(
                        child: MonthlyCalendarWidget(
                          monthRecords: historyState.allRecords
                              .map(HistoryExpenseModel.fromEntity)
                              .where(
                                (r) =>
                                    r.date.month ==
                                        historyState.selectedMonth &&
                                    r.date.year == historyState.selectedYear,
                              )
                              .toList(),
                          categories: categories,
                          month: historyState.selectedMonth,
                          year: historyState.selectedYear,
                          currencySymbol: currencySymbol,
                          onDeleteTransaction: (transaction) {
                            cubit.removeRecord(transaction.id);
                          },
                          onEditTransaction: (transaction) {
                            context.pushNamed(
                              'add-transaction',
                              extra: {
                                'name': transaction.productName,
                                'price': transaction.price,
                                'id': transaction.id,
                                'categoryId': transaction.categoryId,
                              },
                            );
                          },
                        ),
                      ),
                    ] else if (viewMode == HistoryViewMode.table) ...[
                      SliverToBoxAdapter(
                        child: MonthlyMatrixWidget(
                          monthRecords: historyState.allRecords
                              .map(HistoryExpenseModel.fromEntity)
                              .toList(),
                          categories: categories,
                          month: historyState.selectedMonth,
                          year: historyState.selectedYear,
                          currencySymbol: currencySymbol,
                          onDeleteTransaction: (transaction) {
                            cubit.removeRecord(transaction.id);
                          },
                          onEditTransaction: (transaction) {
                            context.pushNamed(
                              'add-transaction',
                              extra: {
                                'name': transaction.productName,
                                'price': transaction.price,
                                'id': transaction.id,
                                'categoryId': transaction.categoryId,
                              },
                            );
                          },
                        ),
                      ),
                    ],
                    SliverToBoxAdapter(child: SizedBox(height: bottomGap)),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
