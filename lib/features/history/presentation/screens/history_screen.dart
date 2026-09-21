import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/core/widgets/month_selector_widget.dart';
import 'package:lumina/core/widgets/responsive_layout.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';
import 'package:lumina/features/history/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/categories_state.dart';
import 'package:lumina/features/history/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/history_state.dart';
import 'package:lumina/features/history/presentation/widgets/category_filter_chips.dart';
import 'package:lumina/features/history/presentation/widgets/grouped_transactions_list.dart';
import 'package:lumina/features/history/presentation/widgets/monthly_matrix_widget.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/presentation/cubits/currency/currency_cubit.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currencySymbol = context.watch<CurrencyCubit>().state.symbol;

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
              final isTable = state.viewMode == HistoryViewMode.table;
              return IconButton(
                icon: Icon(
                  isTable ? Icons.list_rounded : Icons.table_chart_rounded,
                  color: LuminaColors.primary,
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.read<HistoryCubit>().toggleViewMode(
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
                    : const <CustomCategory>[];
                final cubit = context.read<HistoryCubit>();

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 4)),
                    SliverToBoxAdapter(
                      child: MonthSelectorWidget(
                        selectedMonth: historyState.selectedMonth,
                        selectedYear: historyState.selectedYear,
                        onMonthChanged: cubit.changeMonth,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    if (historyState.viewMode == HistoryViewMode.list)
                      SliverToBoxAdapter(
                        child: CategoryFilterChips(
                          categories: categories,
                          selectedCategoryKey: historyState.selectedCategoryKey,
                          onCategorySelected: cubit.changeCategoryFilter,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    if (historyState.viewMode == HistoryViewMode.table)
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
                            Navigator.of(context).pop();
                            context.pushNamed(
                              'add',
                              extra: {
                                'name': transaction.productName,
                                'price': transaction.price,
                                'id': transaction.id,
                                'categoryId': transaction.categoryId,
                              },
                            );
                          },
                        ),
                      )
                    else
                      GroupedTransactionsList(
                        records: historyState.filteredRecords
                            .map(HistoryExpenseModel.fromEntity)
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
