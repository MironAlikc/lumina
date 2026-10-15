import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/services/supabase_sync_service.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/widgets/lumina_loading_widget.dart';
import 'package:lumina/core/widgets/responsive_layout.dart';
import 'package:lumina/features/budgets/presentation/widgets/budget_limit_sheet.dart';
import 'package:lumina/features/dashboard/presentation/widgets/dashboard_balance_card.dart';
import 'package:lumina/features/dashboard/presentation/widgets/dashboard_filter_row.dart';
import 'package:lumina/features/dashboard/presentation/widgets/dashboard_header_widget.dart';
import 'package:lumina/features/dashboard/presentation/widgets/recent_transactions_list.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_state.dart';
import 'package:lumina/l10n/app_localizations.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  /// Открывает историю. Временный фильтр типа возвращается к прежнему
  /// значению, когда пользователь вернулся: иначе он «залипал» бы на дашборде.
  Future<void> _openHistory(
    BuildContext context, {
    HistoryFilterType? type,
  }) async {
    final history = context.read<HistoryCubit>();
    final previous = history.state.activeFilter;
    if (type != null) history.changeFilter(type);

    await context.push<void>('/history');

    if (type != null) history.changeFilter(previous);
  }

  Future<void> _refresh(BuildContext context) async {
    HapticFeedback.mediumImpact();
    // Перечитывает записи, проводит регулярные платежи, отправляет операции.
    await context.read<HistoryCubit>().loadRecords();
    try {
      await SupabaseSyncService.instance.syncNow(); // счета
    } catch (e) {
      debugPrint('Account sync error on pull-to-refresh: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: LuminaColors.background,
      body: SafeArea(
        bottom: false,
        child: ResponsiveLayout(
          child: BlocSelector<HistoryCubit, HistoryState, bool>(
            selector: (s) => s.isLoading && s.allRecords.isEmpty,
            builder: (context, showSkeleton) {
              if (showSkeleton) return const LuminaLoadingWidget();

              return RefreshIndicator(
                color: LuminaColors.accent,
                backgroundColor: LuminaColors.surface,
                strokeWidth: 2.5,
                onRefresh: () => _refresh(context),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    const SliverToBoxAdapter(child: DashboardHeaderWidget()),
                    // Карточка зависит только от итогов: смена порядка
                    // или содержимого списка её не перестраивает.
                    SliverToBoxAdapter(
                      child: BlocBuilder<HistoryCubit, HistoryState>(
                        buildWhen: (p, n) =>
                            p.totalBalance != n.totalBalance ||
                            p.totalIncomes != n.totalIncomes ||
                            p.totalExpenses != n.totalExpenses ||
                            p.budgetLimit != n.budgetLimit,
                        builder: (context, s) => DashboardBalanceCard(
                          balance: s.totalBalance,
                          income: s.totalIncomes,
                          expenses: s.totalExpenses,
                          limit: s.budgetLimit,
                          onIncomeTap: () => _openHistory(
                            context,
                            type: HistoryFilterType.income,
                          ),
                          onExpenseTap: () => _openHistory(
                            context,
                            type: HistoryFilterType.expense,
                          ),
                          onLimitTap: () =>
                              BudgetLimitSheet.show(context, s.budgetLimit),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    const SliverToBoxAdapter(child: DashboardFilterRow()),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              loc.recentTransactions,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: LuminaColors.textMain,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _openHistory(context),
                              child: Text(
                                loc.seeAll,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const RecentTransactionsList(limit: 5),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.paddingOf(context).bottom + 110,
                      ),
                    ),
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
