import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/core/widgets/responsive_layout.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_state.dart';
import 'package:lumina/features/dashboard/presentation/widgets/dashboard_filter_row.dart';
import 'package:lumina/features/transactions/presentation/widgets/month_chips_bar.dart';
import 'package:lumina/features/transactions/presentation/widgets/grouped_transactions_list.dart';
import 'package:lumina/features/transactions/presentation/widgets/matrix/monthly_matrix_widget.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

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
                final isTable = historyState.viewMode == HistoryViewMode.table;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 4)),
                    const SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(child: MonthChipsBar()),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    if (!isTable)
                      const SliverToBoxAdapter(child: DashboardFilterRow()),
                    if (!isTable)
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    if (isTable)
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
                      )
                    else
                      GroupedTransactionsList(
                        records: historyState.filteredRecords
                            .map(HistoryExpenseModel.fromEntity)
                            .toList(),
                        categories: categories,
                        currencySymbol: currencySymbol,
                      ),
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
