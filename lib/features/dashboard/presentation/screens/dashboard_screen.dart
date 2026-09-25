import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/services/supabase_sync_service.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/core/widgets/lumina_loading_widget.dart';
import 'package:lumina/core/widgets/responsive_layout.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_state.dart';
import 'package:lumina/features/budgets/presentation/widgets/budget_limit_sheet.dart';
import 'package:lumina/features/dashboard/presentation/widgets/dashboard_balance_card.dart';
import 'package:lumina/features/dashboard/presentation/widgets/dashboard_filter_row.dart';
import 'package:lumina/features/dashboard/presentation/widgets/recent_transactions_list.dart';
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
              if (historyState.isLoading && historyState.allRecords.isEmpty) {
                return const LuminaLoadingWidget();
              }

              return RefreshIndicator(
                color: LuminaColors.accent,
                backgroundColor: LuminaColors.surface,
                strokeWidth: 2.5,
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  try {
                    await SupabaseSyncService.instance.syncNow();
                  } catch (e) {
                    debugPrint('Sync error on pull-to-refresh: $e');
                  }
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    DashboardBalanceCard.sliver(
                      state: historyState,
                      onIncomeTap: () {
                        context.read<HistoryCubit>().changeFilter(
                          HistoryFilterType.income,
                        );
                        context.push('/history');
                      },
                      onExpenseTap: () {
                        context.read<HistoryCubit>().changeFilter(
                          HistoryFilterType.expense,
                        );
                        context.push('/history');
                      },
                      onLimitTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          useRootNavigator:
                              false, // <-- Открывает шторку выше нижнего бара навигации
                          builder: (_) => BlocProvider.value(
                            value: context.read<HistoryCubit>(),
                            child: BudgetLimitSheet(
                              currentLimit: historyState.budgetLimit,
                            ),
                          ),
                        );
                      },
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    const SliverToBoxAdapter(child: DashboardFilterRow()),
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
