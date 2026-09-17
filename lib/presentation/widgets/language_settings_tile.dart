import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/presentation/cubits/language/language_cubit.dart';

class LanguageSettingsTile extends StatelessWidget {
  const LanguageSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return BlocBuilder<LanguageCubit, Locale>(
      builder: (context, currentLocale) {
        return _SettingsCard(
          icon: Icons.language_rounded,
          iconColor: const Color(0xFF8B5CF6),
          title: loc.interfaceLanguage,
          trailing: _languageDisplayName(currentLocale),
          onTap: () {
            HapticFeedback.lightImpact();
            _showLanguageDialog(context, currentLocale);
          },
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context, Locale currentLocale) {
    final languageCubit = context.read<LanguageCubit>();
    final loc = AppLocalizations.of(context)!;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: LuminaColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.selectLanguage,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: LuminaColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _LanguageOption(
                    cubit: languageCubit,
                    dialogContext: dialogContext,
                    code: 'uk',
                    label: 'Українська',
                    selected: currentLocale.languageCode == 'uk',
                  ),
                  const SizedBox(height: 8),
                  _LanguageOption(
                    cubit: languageCubit,
                    dialogContext: dialogContext,
                    code: 'ru',
                    label: 'Русский',
                    selected: currentLocale.languageCode == 'ru',
                  ),
                  const SizedBox(height: 8),
                  _LanguageOption(
                    cubit: languageCubit,
                    dialogContext: dialogContext,
                    code: 'en',
                    label: 'English',
                    selected: currentLocale.languageCode == 'en',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _languageDisplayName(Locale locale) {
    return switch (locale.languageCode) {
      'ru' => 'Русский',
      'uk' => 'Українська',
      'en' => 'English',
      _ => locale.languageCode.toUpperCase(),
    };
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.cubit,
    required this.dialogContext,
    required this.code,
    required this.label,
    required this.selected,
  });

  final LanguageCubit cubit;
  final BuildContext dialogContext;
  final String code;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        cubit.changeLanguage(code);
        Navigator.pop(dialogContext);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? LuminaColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? LuminaColors.primary : LuminaColors.textMain,
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                color: LuminaColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: LuminaColors.textMain,
          ),
        ),
        trailing: Text(
          trailing,
          style: const TextStyle(
            color: LuminaColors.textSecondary,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
