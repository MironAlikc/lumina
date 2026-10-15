import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lumina/core/services/biometric_service.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/l10n/app_localizations.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _authenticating = false;
  Timer? _autoStart;

  @override
  void initState() {
    super.initState();
    // Небольшая пауза, чтобы системный запрос не мигал во время анимации
    // появления. Таймер отменяется в dispose.
    _autoStart = Timer(const Duration(milliseconds: 350), _authenticate);
  }

  @override
  void dispose() {
    _autoStart?.cancel();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_authenticating || !mounted) return;
    final reason = AppLocalizations.of(context)!.unlockReason;
    setState(() => _authenticating = true);

    final success = await BiometricService.authenticate(reason);

    if (!mounted) return;
    setState(() => _authenticating = false);
    if (success) widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: LuminaColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: LuminaColors.cardMint,
                    shape: BoxShape.circle,
                    boxShadow: LuminaTheme.premiumShadow,
                    border: Border.all(
                      color: LuminaColors.cardMintBorder,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 48,
                    color: LuminaColors.accentDeep,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  loc.appName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: LuminaColors.textMain,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.unlockReason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: LuminaColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 56),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _authenticating ? null : _authenticate,
                    child: _authenticating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            loc.unlock,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: widget.onAuthenticated,
                    child: const Text(
                      '🔓 Bypass (Debug Only)',
                      style: TextStyle(
                        color: LuminaColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
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
