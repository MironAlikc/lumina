import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/widgets/lumina_dialog.dart';
import 'package:lumina/features/settings/presentation/cubits/language_cubit.dart';
import 'package:lumina/features/settings/presentation/widgets/settings_tile.dart';
import 'package:lumina/l10n/app_localizations.dart';

class LanguageSettingsTile extends StatelessWidget {
  const LanguageSettingsTile({super.key});

  static const _options = [
    (code: 'uk', nativeName: 'Українська'),
    (code: 'ru', nativeName: 'Русский'),
    (code: 'en', nativeName: 'English'),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final current = context.watch<LanguageCubit>().state.languageCode;
    final currentName = _options
        .firstWhere((o) => o.code == current, orElse: () => _options.first)
        .nativeName;

    return SettingsTile(
      icon: Icons.language_rounded,
      iconColor: const Color(0xFF8B5CF6),
      title: loc.interfaceLanguage,
      trailing: Text(
        currentName,
        style: const TextStyle(color: LuminaColors.textSecondary),
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        _openDialog(context, current);
      },
    );
  }

  void _openDialog(BuildContext context, String current) {
    final cubit = context.read<LanguageCubit>();
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
                  loc.selectLanguage,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: LuminaColors.textMain,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final option in _options)
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  selected: option.code == current,
                  selectedTileColor:
                      LuminaColors.primary.withValues(alpha: 0.08),
                  title: Text(
                    option.nativeName,
                    style: TextStyle(
                      fontWeight: option.code == current
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: option.code == current
                          ? LuminaColors.primary
                          : LuminaColors.textMain,
                    ),
                  ),
                  trailing: option.code == current
                      ? const Icon(Icons.check_rounded,
                          color: LuminaColors.primary)
                      : null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(dialogContext).pop();
                    cubit.changeLanguage(option.code);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
