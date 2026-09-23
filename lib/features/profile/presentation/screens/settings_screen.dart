import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';
import 'package:lumina/features/history/data/services/export_service.dart';
import 'package:lumina/features/history/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/categories_state.dart';
import 'package:lumina/features/history/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/history_state.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/presentation/cubits/currency/currency_cubit.dart';
import 'package:lumina/presentation/widgets/currency_settings_tile.dart';
import 'package:lumina/presentation/widgets/language_settings_tile.dart';

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
                    _ProfileCard(loc: loc),
                    const SizedBox(height: 28),
                    Text(
                      loc.budgetManagement,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: LuminaColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _BudgetSlider(state: state, loc: loc),
                    const SizedBox(height: 12),
                    _SettingsTile(
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
                    _SettingsTile(
                      icon: Icons.savings_rounded,
                      iconColor: LuminaColors.success,
                      title: loc.goalsAndSavings,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.pushNamed('goals');
                      },
                    ),
                    const SizedBox(height: 28),
                    Text(
                      loc.appSection,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: LuminaColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SettingsTile(
                      icon: Icons.repeat_rounded,
                      iconColor: LuminaColors.primary,
                      title: loc.recurringPayments,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.pushNamed('recurring');
                      },
                    ),
                    _ExportTile(state: state, loc: loc),
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.loc});

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(LuminaDimensions.paddingL),
      decoration: BoxDecoration(
        color: LuminaColors.surface,
        borderRadius: LuminaDimensions.borderRadiusLarge,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: LuminaColors.primary.withValues(alpha: 0.1),
            child: const Text('👋', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.myWallet,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: LuminaColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loc.localProfile,
                  style: const TextStyle(color: LuminaColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSlider extends StatelessWidget {
  const _BudgetSlider({required this.state, required this.loc});

  final HistoryState state;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final whole = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = 0;
    final symbol = context.watch<CurrencyCubit>().state.symbol;
    final limit = state.budgetLimit.clamp(0, 100000).toDouble();
    final label = limit == 0
        ? loc.limitNotSet
        : '${whole.format(limit)} $symbol';

    return Container(
      padding: EdgeInsets.all(LuminaDimensions.paddingL),
      decoration: BoxDecoration(
        color: LuminaColors.surface,
        borderRadius: LuminaDimensions.borderRadiusLarge,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.monthlyLimit,
                style: const TextStyle(color: LuminaColors.textMain),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: LuminaColors.primary,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: limit,
              min: 0,
              max: 100000,
              divisions: 20,
              label: label,
              activeColor: LuminaColors.primary,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                context.read<HistoryCubit>().updateBudgetLimit(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportTile extends StatefulWidget {
  const _ExportTile({required this.state, required this.loc});

  final HistoryState state;
  final AppLocalizations loc;

  @override
  State<_ExportTile> createState() => _ExportTileState();
}

class _ExportTileState extends State<_ExportTile> {
  bool _busy = false;

  Future<void> _export() async {
    if (_busy) return;
    HapticFeedback.lightImpact();
    setState(() => _busy = true);

    final loc = widget.loc;
    final state = widget.state;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final catState = context.read<CategoriesCubit>().state;
      final categories = catState is CategoriesLoaded
          ? catState.categories
          : const <CustomCategory>[];

      await ExportService.exportMonthToCSV(
        state.allRecords.map(HistoryExpenseModel.fromEntity).toList(),
        categories,
        state.selectedMonth,
        state.selectedYear,
        loc,
      );

      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
          content: Text(loc.exportSuccess),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
          content: Text(loc.exportFailed),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.table_chart_rounded,
      iconColor: LuminaColors.success,
      title: widget.loc.exportToExcel,
      trailing: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _busy ? () {} : _export,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: LuminaColors.surface,
        borderRadius: LuminaDimensions.borderRadiusMedium,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: LuminaColors.textMain,
          ),
        ),
        trailing:
            trailing ??
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: LuminaColors.textSecondary,
            ),
        onTap: onTap,
      ),
    );
  }
}
