import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_state.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/features/settings/presentation/widgets/currency_settings_tile.dart';
import 'package:lumina/features/settings/presentation/widgets/language_settings_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isTablet = MediaQuery.sizeOf(context).width > 600;

    return Scaffold(
      backgroundColor: LuminaColors.background,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<HistoryCubit, HistoryState>(
          buildWhen: (prev, next) =>
              prev.budgetLimit != next.budgetLimit ||
              prev.allRecords != next.allRecords ||
              prev.selectedMonth != next.selectedMonth ||
              prev.selectedYear != next.selectedYear,
          builder: (context, state) {
            return Align(
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
                    BudgetLimitSlider(state: state),
                    SettingsTile(
                      icon: Icons.pie_chart_outline_rounded,
                      iconColor: LuminaColors.primary,
                      title: loc.categoryBudgets,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        final catState = context.read<CategoriesCubit>().state;
                        final categories = catState is CategoriesLoaded
                            ? catState.categories
                            : const <CustomCategory>[];
                        context.pushNamed(
                          'budgets',
                          extra: {
                            'categories': categories,
                            'allRecords': state.allRecords,
                          },
                        );
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
                    ExportSettingsTile(state: state),
                    const CurrencySettingsTile(),
                    const LanguageSettingsTile(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
