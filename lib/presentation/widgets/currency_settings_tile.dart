import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/enums/app_currency.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/presentation/cubits/currency/currency_cubit.dart';

class CurrencySettingsTile extends StatelessWidget {
  const CurrencySettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return BlocBuilder<CurrencyCubit, AppCurrency>(
      builder: (context, currency) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: LuminaColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: LuminaColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.currency_exchange_rounded,
                color: LuminaColors.success,
                size: 20,
              ),
            ),
            title: Text(
              loc.interfaceCurrency,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: LuminaColors.textMain,
              ),
            ),
            trailing: Text(
              '${currency.localizedName(loc)} (${currency.symbol})',
              style: const TextStyle(
                color: LuminaColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              _showCurrencyDialog(context, currency);
            },
          ),
        );
      },
    );
  }

  void _showCurrencyDialog(BuildContext context, AppCurrency current) {
    final cubit = context.read<CurrencyCubit>();
    final loc = AppLocalizations.of(context)!;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: LuminaColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.selectCurrency,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: LuminaColors.textMain,
                  ),
                ),
                const SizedBox(height: 16),
                for (final item in AppCurrency.values) ...[
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      cubit.changeCurrency(item);
                      Navigator.pop(dialogContext);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: item == current
                            ? LuminaColors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.localizedName(loc)} (${item.symbol})',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: item == current
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: item == current
                                    ? LuminaColors.primary
                                    : LuminaColors.textMain,
                              ),
                            ),
                          ),
                          if (item == current)
                            const Icon(
                              Icons.check_rounded,
                              color: LuminaColors.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
