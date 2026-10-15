import 'package:flutter/material.dart';
import 'package:lumina/core/theme/lumina_colors.dart';

Future<T?> showLuminaDialog<T>({
  required BuildContext context,
  required Widget child,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          color: LuminaColors.background,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    ),
  );
}
