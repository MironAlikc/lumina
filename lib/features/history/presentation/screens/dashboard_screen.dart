import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/core/widgets/responsive_layout.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/categories_state.dart';
import 'package:lumina/features/history/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/history_state.dart';
import 'package:lumina/features/history/presentation/widgets/category_filter_chips.dart';
import 'package:lumina/features/history/presentation/widgets/dashboard/dashboard_balance_card.dart';
import 'package:lumina/features/history/presentation/widgets/dashboard/recent_transactions_list.dart';
import 'package:lumina/l10n/app_localizations.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: LuminaColors.background,
      body: SafeArea(
        bottom: false,
        child: ResponsiveLayout(
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
                      DashboardBalanceCard.sliver(state: historyState),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      SliverToBoxAdapter(
                        child: CategoryFilterChips(
                          categories: categories,
                          selectedCategoryKey: historyState.selectedCategoryKey,
                          onCategorySelected: (categoryKey) {
                            context.read<HistoryCubit>().changeCategoryFilter(
                              categoryKey,
                            );
                          },
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                loc.recentTransactions,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: LuminaTheme.textColor,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.push('/history'),
                                child: Text(
                                  loc.seeAll,
                                  style: const TextStyle(
                                    color: LuminaTheme.accentColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      RecentTransactionsList(state: historyState, limit: 5),
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
