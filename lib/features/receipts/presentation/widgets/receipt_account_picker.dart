import 'package:flutter/material.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/features/accounts/data/models/account_model.dart';
import 'package:lumina/l10n/app_localizations.dart';

class ReceiptAccountPicker extends StatelessWidget {
  const ReceiptAccountPicker({
    super.key,
    required this.accounts,
    required this.value,
    required this.onChanged,
  });

  final List<AccountModel> accounts;
  final String? value;
  final ValueChanged<String?> onChanged;

  /// Выбранный счёт, если он ещё существует, иначе первый доступный.
  static String? resolve(List<AccountModel> accounts, String? selected) {
    if (accounts.isEmpty) return null;
    return accounts.any((a) => a.id == selected) ? selected : accounts.first.id;
  }

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: LuminaColors.surface,
        borderRadius: LuminaDimensions.borderRadiusMedium,
        border: Border.all(color: LuminaColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: resolve(accounts, value),
          isExpanded: true,
          hint: Text(loc.accountLabel),
          borderRadius: LuminaDimensions.borderRadiusMedium,
          items: [
            for (final a in accounts)
              DropdownMenuItem(
                value: a.id,
                child: Text(
                  a.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: LuminaColors.textMain,
                  ),
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
