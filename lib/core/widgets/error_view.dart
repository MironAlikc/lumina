import 'package:flutter/material.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/l10n/app_localizations.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.onRetry, this.message});

  /// Дополнительная подробность. Пусто или null: показывается только заголовок.
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final details = message?.trim() ?? '';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: LuminaColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              loc.somethingWentWrong,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LuminaColors.textMain,
              ),
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                details,
                textAlign: TextAlign.center,
                style: const TextStyle(color: LuminaColors.textSecondary),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(loc.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}
