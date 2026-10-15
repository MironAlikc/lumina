import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/features/budgets/presentation/widgets/budget_limit_tile.dart';
import 'package:lumina/features/settings/presentation/widgets/currency_settings_tile.dart';
import 'package:lumina/features/settings/presentation/widgets/language_settings_tile.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_state.dart';
import 'package:lumina/l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static double _spentThisMonth(HistoryState state) {
    final now = DateTime.now();
    var sum = 0.0;
    for (final r in state.allRecords) {
      if (r.isExpense && r.date.year == now.year && r.date.month == now.month) {
        sum += r.price;
      }
    }
    return (sum * 100).round() / 100;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isTablet = MediaQuery.sizeOf(context).width > 600;

    return Scaffold(
      backgroundColor: LuminaColors.background,
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 700 : double.infinity,
            ),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.paddingOf(context).bottom + 120,
              ),
              children: [
                const ProfileCard(),
                const SizedBox(height: 28),
                SettingsSectionTitle(loc.budgetManagement),
                SettingsTile(
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: LuminaColors.success,
                  title: loc.myAccounts,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.pushNamed('accounts');
                  },
                ),
                BlocBuilder<HistoryCubit, HistoryState>(
                  buildWhen: (p, n) =>
                      p.budgetLimit != n.budgetLimit ||
                      !listEquals(p.allRecords, n.allRecords),
                  builder: (context, state) => BudgetLimitTile(
                    limit: state.budgetLimit,
                    spentThisMonth: _spentThisMonth(state),
                  ),
                ),
                SettingsTile(
                  icon: Icons.pie_chart_outline_rounded,
                  iconColor: LuminaColors.primary,
                  title: loc.categoryBudgets,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.pushNamed('budgets');
                  },
                ),
                SettingsTile(
                  icon: Icons.savings_rounded,
                  iconColor: LuminaColors.success,
                  title: loc.goalsAndSavings,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.pushNamed('goals');
                  },
                ),
                const SizedBox(height: 16),
                SettingsSectionTitle(loc.appSection),
                SettingsTile(
                  icon: Icons.repeat_rounded,
                  iconColor: LuminaColors.primary,
                  title: loc.recurringPayments,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.pushNamed('recurring');
                  },
                ),
                const ExportSettingsTile(),
                const CurrencySettingsTile(),
                const LanguageSettingsTile(),
                const AppLockTile(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
