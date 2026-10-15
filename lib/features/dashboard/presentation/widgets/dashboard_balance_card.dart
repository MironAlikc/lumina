import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/core/utils/money.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';
import 'package:lumina/l10n/app_localizations.dart';

class DashboardBalanceCard extends StatefulWidget {
  const DashboardBalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expenses,
    required this.limit,
    this.onIncomeTap,
    this.onExpenseTap,
    this.onLimitTap,
  });

  final double balance;
  final double income;
  final double expenses;

  /// 0 - общий лимит не задан.
  final double limit;
  final VoidCallback? onIncomeTap;
  final VoidCallback? onExpenseTap;
  final VoidCallback? onLimitTap;

  @override
  State<DashboardBalanceCard> createState() => _DashboardBalanceCardState();
}

class _DashboardBalanceCardState extends State<DashboardBalanceCard> {
  static const _glass = Color(0xA6FFFFFF); // белый 65%
  static const _glassTrack = Color(0x80FFFFFF); // белый 50%
  static const _mask = '••••••';

  bool _hidden = false;

  void _toggleHidden() {
    HapticFeedback.lightImpact();
    setState(() => _hidden = !_hidden);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final symbol = context.select((CurrencyCubit c) => c.state.symbol);

    String money(double v) => Money.format(v, locale, symbol: symbol);
    String signed(String sign, double v) =>
        v == 0 ? money(0) : '$sign${money(v)}';

    final limit = widget.limit;
    final hasLimit = limit > 0;
    final ratio = hasLimit ? widget.expenses / limit : 0.0;
    final isOver = hasLimit && widget.expenses > limit;
    final isNegative = widget.balance < 0;

    final balanceText = _hidden
        ? _mask
        : '${isNegative ? '−' : ''}${Money.format(widget.balance.abs(), locale)}';

    final limitNote = !hasLimit || _hidden
        ? ''
        : (isOver
            ? loc.budgetOver(money(widget.expenses - limit))
            : loc.budgetRemaining(money(limit - widget.expenses)));

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: LuminaDimensions.paddingL,
        vertical: LuminaDimensions.paddingS,
      ),
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
      // Прозрачный Material поверх декорации: рябь нажатий видна.
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  Expanded(
                    child: Text(
                      loc.pureBalance.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: LuminaColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _LimitBadge(
                    label: hasLimit
                        ? '${loc.limit}: ${money(limit)}'
                        : '+ ${loc.limit}',
                    onTap: widget.onLimitTap,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (isOver) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              Semantics(
                button: true,
                label: _hidden ? loc.showBalance : loc.hideBalance,
                child: InkWell(
                  onTap: _toggleHidden,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
                                  balanceText,
                                  style: TextStyle(
                                    color: isNegative
                                        ? LuminaColors.error
                                        : LuminaColors.textMain,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                if (!_hidden) ...[
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
                          _hidden
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 20,
                          color:
                              LuminaColors.textSecondary.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      title: loc.income,
                      amount: _hidden ? _mask : signed('+', widget.income),
                      icon: Icons.arrow_downward_rounded,
                      color: LuminaColors.success,
                      onTap: widget.onIncomeTap,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStat(
                      title: loc.expenses,
                      amount: _hidden ? _mask : signed('−', widget.expenses),
                      icon: Icons.arrow_upward_rounded,
                      color: LuminaColors.error,
                      onTap: widget.onExpenseTap,
                    ),
                  ),
                ],
              ),
              if (hasLimit) ...[
                const SizedBox(height: 18),
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onLimitTap?.call();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: ratio.clamp(0.0, 1.0)),
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: value,
                            backgroundColor: _glassTrack,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOver ? LuminaColors.error : LuminaColors.accent,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              limitNote,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isOver
                                    ? LuminaColors.error
                                    : LuminaColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // Реальный процент: при перерасходе он больше 100.
                          Text(
                            '${(ratio * 100).floor()}%',
                            style: TextStyle(
                              color: isOver
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
        ),
      ),
    );
  }
}

class _LimitBadge extends StatelessWidget {
  const _LimitBadge({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xA6FFFFFF),
      shape: const StadiumBorder(
        side: BorderSide(color: LuminaColors.cardMintBorder, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LuminaColors.accentDeep,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
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
      color: const Color(0xA6FFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: LuminaColors.cardMintBorder.withValues(alpha: 0.7),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call();
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
