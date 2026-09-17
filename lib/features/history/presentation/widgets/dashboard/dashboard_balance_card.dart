import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/features/history/presentation/cubits/history_state.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/presentation/cubits/currency/currency_cubit.dart';

class DashboardBalanceCard extends StatelessWidget {
  final HistoryState state;

  const DashboardBalanceCard({super.key, required this.state});

  static Widget sliver({required HistoryState state, Key? key}) {
    return SliverToBoxAdapter(
      key: key,
      child: DashboardBalanceCard(state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLoc = AppLocalizations.of(context)!;
    final currencySymbol = context.watch<CurrencyCubit>().state.symbol;
    final double limit = state.budgetLimit;
    final double totalExpense = state.totalExpenses;
    final double progress = (limit > 0)
        ? (totalExpense / limit).clamp(0.0, 1.0)
        : 0.0;
    final bool isOverLimit = limit > 0 && totalExpense > limit;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: LuminaDimensions.paddingL,
        vertical: LuminaDimensions.paddingS,
      ),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: LuminaColors.cardMint,
        borderRadius: LuminaDimensions.borderRadiusLarge,
        border: Border.all(color: LuminaColors.cardMintBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: LuminaColors.accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 12,
                    decoration: BoxDecoration(
                      color: LuminaColors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: LuminaDimensions.paddingS),
                  Text(
                    appLoc.pureBalance.toUpperCase(),
                    style: const TextStyle(
                      color: LuminaColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: LuminaColors.cardMintBorder,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${appLoc.limit}: ${limit.toStringAsFixed(0)} $currencySymbol',
                  style: const TextStyle(
                    color: LuminaColors.accentDeep,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (isOverLimit) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: LuminaColors.errorSoft,
                borderRadius: LuminaDimensions.borderRadiusSmall,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: LuminaColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: LuminaDimensions.paddingS),
                  Text(
                    appLoc.overLimit,
                    style: const TextStyle(
                      color: LuminaColors.errorDeep,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${state.totalBalance < 0 ? '-' : ''}${state.totalBalance.abs().toStringAsFixed(2)}',
                style: const TextStyle(
                  color: LuminaColors.textMain,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                currencySymbol,
                style: const TextStyle(
                  color: LuminaColors.textSecondary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  title: appLoc.income,
                  amount:
                      '+${state.totalIncomes.toStringAsFixed(0)} $currencySymbol',
                  icon: Icons.arrow_downward_rounded,
                  color: LuminaColors.success,
                  cardBorder: LuminaColors.cardMintBorder,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  title: appLoc.expenses,
                  amount:
                      '-${state.totalExpenses.toStringAsFixed(0)} $currencySymbol',
                  icon: Icons.arrow_upward_rounded,
                  color: LuminaColors.error,
                  cardBorder: LuminaColors.cardMintBorder,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverLimit ? LuminaColors.error : LuminaColors.accent,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${totalExpense.toStringAsFixed(0)} / ${limit.toStringAsFixed(0)} $currencySymbol',
                style: const TextStyle(
                  color: LuminaColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    required Color cardBorder,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cardBorder.withValues(alpha: 0.7),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: LuminaColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: const TextStyle(
                    color: LuminaColors.textMain,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
