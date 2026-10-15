import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/core/services/biometric_service.dart';
import 'package:lumina/core/services/security_storage_service.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Переключатель блокировки приложения. Включить и выключить блокировку
/// можно только после успешной проверки: иначе её можно было бы выключить
/// чужими руками или включить на устройстве, где войти невозможно.
class AppLockTile extends StatefulWidget {
  const AppLockTile({super.key});

  @override
  State<AppLockTile> createState() => _AppLockTileState();
}

class _AppLockTileState extends State<AppLockTile> {
  bool _enabled = SecurityStorageService.isBiometricEnabled;
  bool _busy = false;

  Future<void> _toggle(bool value) async {
    if (_busy) return;
    HapticFeedback.lightImpact();

    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _busy = true);
    try {
      if (!await BiometricService.isSupported()) {
        messenger.showSnackBar(SnackBar(content: Text(loc.appLockUnavailable)));
        return;
      }
      if (!await BiometricService.authenticate(loc.unlockReason)) return;

      await SecurityStorageService.setBiometricEnabled(value);
      if (mounted) setState(() => _enabled = value);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: LuminaColors.surface,
        borderRadius: LuminaDimensions.borderRadiusMedium,
        clipBehavior: Clip.antiAlias,
        child: SwitchListTile(
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LuminaColors.cardMint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              color: LuminaColors.accentDeep,
              size: 20,
            ),
          ),
          title: Text(
            loc.appLock,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: LuminaColors.textMain,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            loc.appLockSubtitle,
            style: const TextStyle(
              color: LuminaColors.textSecondary,
              fontSize: 12,
            ),
          ),
          value: _enabled,
          activeThumbColor: LuminaColors.accent,
          onChanged: _busy ? null : _toggle,
        ),
      ),
    );
  }
}
