import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/core/widgets/month_selector_widget.dart';
import 'package:lumina/core/widgets/responsive_layout.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';
import 'package:lumina/presentation/cubits/currency/currency_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/categories_state.dart';
import 'package:lumina/l10n/app_localizations.dart';
import '../cubits/history_cubit.dart';
import '../cubits/history_state.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/grouped_transactions_list.dart';
import '../widgets/monthly_matrix_widget.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currencySymbol = context.watch<CurrencyCubit>().state.symbol;
    final historyCubit = context.read<HistoryCubit>();

    return Scaffold(
      backgroundColor: LuminaColors.background,
      appBar: AppBar(
        backgroundColor: LuminaColors.background,
        elevation: 0,
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
            builder: (context, state) {
              final isTable = state.viewMode == HistoryViewMode.table;
              return IconButton(
                icon: Icon(
                  isTable ? Icons.list_rounded : Icons.table_chart_rounded,
                  color: LuminaColors.primary,
                ),
                tooltip: isTable
                    ? loc.expenseFilter
                    : loc.allFilter, // либо кастомные тултипы если добавлены в ARB
                onPressed: () {
                  historyCubit.toggleViewMode(
                    isTable ? HistoryViewMode.list : HistoryViewMode.table,
                  );
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
                    : <CustomCategory>[];

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 4)),
                    SliverToBoxAdapter(
                      child: MonthSelectorWidget(
                        selectedMonth: historyState.selectedMonth,
                        selectedYear: historyState.selectedYear,
                        onMonthChanged: (month, year) {
                          historyCubit.changeMonth(month, year);
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    if (historyState.viewMode == HistoryViewMode.list)
                      SliverToBoxAdapter(
                        child: CategoryFilterChips(
                          categories: categories,
                          selectedCategoryKey: historyState.selectedCategoryKey,
                          onCategorySelected: (categoryKey) {
                            historyCubit.changeCategoryFilter(categoryKey);
                          },
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    if (historyState.viewMode == HistoryViewMode.table)
                      SliverToBoxAdapter(
                        child: MonthlyMatrixWidget(
                          monthRecords: historyState.allRecords
                              .map(
                                (entity) =>
                                    HistoryExpenseModel.fromEntity(entity),
                              )
                              .toList(),
                          categories: categories,
                          month: historyState.selectedMonth,
                          year: historyState.selectedYear,
                          currencySymbol: currencySymbol,
                          onDeleteTransaction: (transaction) {
                            historyCubit.removeRecord(transaction.id);
                          },
                          onEditTransaction: (transaction) {
                            debugPrint(
                              'Edit transaction requested: ${transaction.id}',
                            );
                          },
                        ),
                      )
                    else
                      GroupedTransactionsList(
                        records: historyState.filteredRecords
                            .map(
                              (entity) =>
                                  HistoryExpenseModel.fromEntity(entity),
                            )
                            .toList(),
                        categories: categories,
                        currencySymbol: currencySymbol,
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
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
