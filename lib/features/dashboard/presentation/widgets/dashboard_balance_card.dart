import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_state.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';

class DashboardBalanceCard extends StatefulWidget {
  const DashboardBalanceCard({
    super.key,
    required this.state,
    this.onIncomeTap,
    this.onExpenseTap,
    this.onLimitTap,
  });

  final HistoryState state;
  final VoidCallback? onIncomeTap;
  final VoidCallback? onExpenseTap;
  final VoidCallback? onLimitTap;

  static Widget sliver({
    required HistoryState state,
    VoidCallback? onIncomeTap,
    VoidCallback? onExpenseTap,
    VoidCallback? onLimitTap,
    Key? key,
  }) {
    return SliverToBoxAdapter(
      key: key,
      child: DashboardBalanceCard(
        state: state,
        onIncomeTap: onIncomeTap,
        onExpenseTap: onExpenseTap,
        onLimitTap: onLimitTap,
      ),
    );
  }

  @override
  State<DashboardBalanceCard> createState() => _DashboardBalanceCardState();
}

class _DashboardBalanceCardState extends State<DashboardBalanceCard> {
  bool _isBalanceHidden = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final symbol = context.watch<CurrencyCubit>().state.symbol;

    final precise = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = 2
      ..maximumFractionDigits = 2;
    final whole = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = 0;

    final limit = widget.state.budgetLimit;
    final totalExpense = widget.state.totalExpenses;
    final hasLimit = limit > 0;
    final progress = hasLimit ? (totalExpense / limit).clamp(0.0, 1.0) : 0.0;
    final isOverLimit = hasLimit && totalExpense > limit;
    final isNegative = widget.state.totalBalance < 0;

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
          // Шапка карточки
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
              Expanded(
                child: Text(
                  loc.pureBalance.toUpperCase(),
                  style: const TextStyle(
                    color: LuminaColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              // Кликабельный бейдж лимита
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onLimitTap?.call();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasLimit
                              ? '${loc.limit}: ${whole.format(limit)} $symbol'
                              : '+ ${loc.limit}',
                          style: const TextStyle(
                            color: LuminaColors.accentDeep,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.edit_rounded,
                          size: 12,
                          color: LuminaColors.accentDeep,
                        ),
                      ],
                    ),
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
                  Expanded(
                    child: Text(
                      loc.overLimit,
                      style: const TextStyle(
                        color: LuminaColors.errorDeep,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Баланс с кнопкой скрытия/показа
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isBalanceHidden = !_isBalanceHidden;
              });
            },
            child: Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _isBalanceHidden
                              ? '••••••••'
                              : '${isNegative ? '-' : ''}${precise.format(widget.state.totalBalance.abs())}',
                          style: TextStyle(
                            color: isNegative
                                ? LuminaColors.error
                                : LuminaColors.textMain,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (!_isBalanceHidden) ...[
                          const SizedBox(width: 6),
                          Text(
                            symbol,
                            style: const TextStyle(
                              color: LuminaColors.textSecondary,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isBalanceHidden
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 20,
                  color: LuminaColors.textSecondary.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Мини-статистика доходов и расходов
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  title: loc.income,
                  amount: '+${whole.format(widget.state.totalIncomes)} $symbol',
                  icon: Icons.arrow_downward_rounded,
                  color: LuminaColors.success,
                  onTap: widget.onIncomeTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  title: loc.expenses,
                  amount:
                      '-${whole.format(widget.state.totalExpenses)} $symbol',
                  icon: Icons.arrow_upward_rounded,
                  color: LuminaColors.error,
                  onTap: widget.onExpenseTap,
                ),
              ),
            ],
          ),
          // Прогресс-бар лимита с возможностью клика для редактирования
          if (hasLimit) ...[
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onLimitTap?.call();
              },
              child: Column(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${whole.format(totalExpense)} / ${whole.format(limit)} $symbol',
                        style: TextStyle(
                          color: isOverLimit
                              ? LuminaColors.error
                              : LuminaColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: isOverLimit
                              ? LuminaColors.error
                              : LuminaColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: LuminaColors.cardMintBorder.withValues(alpha: 0.7),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: LuminaColors.textMain,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
