import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/presentation/cubits/language/language_cubit.dart';

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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: LuminaColors.surface,
        borderRadius: LuminaDimensions.borderRadiusMedium,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.language_rounded,
            color: Color(0xFF8B5CF6),
            size: 20,
          ),
        ),
        title: Text(
          loc.interfaceLanguage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: LuminaColors.textMain,
          ),
        ),
        trailing: Text(
          currentName,
          style: const TextStyle(color: LuminaColors.textSecondary),
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          _openDialog(context, loc, current);
        },
      ),
    );
  }

  void _openDialog(BuildContext context, AppLocalizations loc, String current) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(loc.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in _options)
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                selected: option.code == current,
                selectedTileColor: LuminaColors.primary.withValues(alpha: 0.08),
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
                    ? const Icon(
                        Icons.check_rounded,
                        color: LuminaColors.primary,
                      )
                    : null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.read<LanguageCubit>().changeLanguage(option.code);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }
}
