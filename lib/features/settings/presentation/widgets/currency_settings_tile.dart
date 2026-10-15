import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/enums/app_currency.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/widgets/lumina_dialog.dart';
import 'package:lumina/features/settings/presentation/cubits/currency_cubit.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_tile.dart';
import 'package:lumina/l10n/app_localizations.dart';

class CurrencySettingsTile extends StatelessWidget {
  const CurrencySettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currency = context.watch<CurrencyCubit>().state;

    return SettingsTile(
      icon: Icons.currency_exchange_rounded,
      iconColor: LuminaColors.success,
      title: loc.interfaceCurrency,
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
        _openDialog(context, currency);
      },
    );
  }

  void _openDialog(BuildContext context, AppCurrency current) {
    final cubit = context.read<CurrencyCubit>();
    final loc = AppLocalizations.of(context)!;

    showLuminaDialog<void>(
      context: context,
      child: Builder(
        builder: (dialogContext) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  loc.selectCurrency,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: LuminaColors.textMain,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  // Суммы не конвертируются: пользователь должен это знать.
                  loc.currencyChangeNote,
                  style: const TextStyle(
                    fontSize: 12,
                    color: LuminaColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final item in AppCurrency.values)
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  selected: item == current,
                  selectedTileColor:
                      LuminaColors.primary.withValues(alpha: 0.1),
                  title: Text(
                    '${item.localizedName(loc)} (${item.symbol})',
                    style: TextStyle(
                      fontWeight:
                          item == current ? FontWeight.bold : FontWeight.w500,
                      color: item == current
                          ? LuminaColors.primary
                          : LuminaColors.textMain,
                    ),
                  ),
                  trailing: item == current
                      ? const Icon(Icons.check_rounded,
                          color: LuminaColors.primary)
                      : null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(dialogContext).pop();
                    cubit.changeCurrency(item);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
