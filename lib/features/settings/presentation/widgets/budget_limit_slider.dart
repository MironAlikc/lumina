import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_state.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';

class BudgetLimitSlider extends StatelessWidget {
  const BudgetLimitSlider({super.key, required this.state});

  final HistoryState state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final whole = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = 0;
    final symbol = context.watch<CurrencyCubit>().state.symbol;
    final limit = state.budgetLimit.clamp(0, 100000).toDouble();
    final label = limit == 0
        ? loc.limitNotSet
        : '${whole.format(limit)} $symbol';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
