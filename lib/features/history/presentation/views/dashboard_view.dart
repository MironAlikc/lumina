import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/lumina_theme.dart';
import '../../../../core/localization/lumina_localizations.dart';
import '../cubits/history_cubit.dart';
import '../cubits/history_state.dart';
import 'expense_item_widget.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LuminaLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<HistoryCubit, HistoryState>(
          builder: (context, state) {
            final double currentLimit = state.budgetLimit;
            final double usageRatio = currentLimit > 0
                ? (state.totalExpenses / currentLimit)
                : 0.0;

            // Определяем цвет прогресс-бара
            final Color progressColor = usageRatio >= 1.0
                ? const Color(0xFFEF4444)
                : const Color(0xFFFF9F43);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(loc),
                _buildFilterRow(context, state, loc),
                _buildBalanceCard(
                  state,
                  currentLimit,
                  usageRatio,
                  progressColor,
                  loc,
                ),
                _buildTransactionList(state, loc),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(LuminaLocalizations loc) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      sliver: SliverToBoxAdapter(
        child: Text(
          loc.translate('appName'),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: LuminaTheme.textColor,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(
    BuildContext context,
    HistoryState state,
    LuminaLocalizations loc,
  ) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 42,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          scrollDirection: Axis.horizontal,
          children: [
            _buildFilterChip(
              context,
              state,
              HistoryFilterType.all,
              loc.translate('allFilter'),
            ),
            _buildFilterChip(
              context,
              state,
              HistoryFilterType.expense,
              loc.translate('expenseFilter'),
            ),
            _buildFilterChip(
              context,
              state,
              HistoryFilterType.income,
              loc.translate('incomeFilter'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    HistoryState state,
    double limit,
    double ratio,
    Color color,
    LuminaLocalizations loc,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [LuminaTheme.accentColor, Color(0xFF0096B4)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: LuminaTheme.accentColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.translate('pureBalance'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  Text(
                    '${loc.translate('limit')}: ${limit.toStringAsFixed(0)} ₴',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${state.totalBalance.toStringAsFixed(2)} ₴',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              // Индикаторы доход/расход
              Row(
                children: [
                  _buildTrend(
                    Icons.south_east_rounded,
                    '+${state.totalIncomes.toStringAsFixed(0)} ₴',
                    const Color(0xFF4ADE80),
                  ),
                  const SizedBox(width: 20),
                  _buildTrend(
                    Icons.north_east_rounded,
                    '-${state.totalExpenses.toStringAsFixed(0)} ₴',
                    const Color(0xFFFF8787),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrend(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList(HistoryState state, LuminaLocalizations loc) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ExpenseItemWidget(item: state.filteredRecords[index]),
          ),
          childCount: state.filteredRecords.length,
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    HistoryState state,
    HistoryFilterType type,
    String label,
  ) {
    final bool isSelected = state.activeFilter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          HapticFeedback.lightImpact();
          context.read<HistoryCubit>().changeFilter(type);
        },
        color: WidgetStateProperty.resolveWith(
          (states) => isSelected
              ? LuminaTheme.accentColor.withValues(alpha: 0.12)
              : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isSelected ? Colors.transparent : const Color(0xFFF1F5F9),
          ),
        ),
      ),
    );
  }
}
