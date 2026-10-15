import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/core/utils/money.dart';
import 'package:lumina/features/budgets/presentation/widgets/budget_limit_sheet.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Общий месячный лимит: точный ввод по нажатию и прогресс текущего месяца.
class BudgetLimitTile extends StatelessWidget {
  const BudgetLimitTile({
    super.key,
    required this.limit,
    required this.spentThisMonth,
  });

  final double limit;
  final double spentThisMonth;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final symbol = context.watch<CurrencyCubit>().state.symbol;

    final hasLimit = limit > 0;
    final over = hasLimit && spentThisMonth > limit;
    final label = hasLimit
        ? Money.format(limit, locale, symbol: symbol)
        : loc.limitNotSet;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: LuminaColors.surface,
        borderRadius: LuminaDimensions.borderRadiusMedium,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            BudgetLimitSheet.show(context, limit);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: LuminaColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.speed_rounded,
                        size: 20,
                        color: LuminaColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        loc.monthlyLimit,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: LuminaColors.textMain,
                        ),
                      ),
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
                if (hasLimit) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (spentThisMonth / limit).clamp(0.0, 1.0),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                    backgroundColor: LuminaColors.inputFill,
                    color: over ? LuminaColors.error : LuminaColors.primary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.spentThisMonth(
                      Money.format(spentThisMonth, locale, symbol: symbol),
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: over
                          ? LuminaColors.error
                          : LuminaColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
