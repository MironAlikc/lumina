import 'package:flutter/material.dart';
import 'package:lumina/core/theme/lumina_colors.dart';

class LuminaFormDialog extends StatelessWidget {
  const LuminaFormDialog({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight =
        (size.height - padding.top - keyboard - 32).clamp(220.0, 640.0);

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, padding.top + 8, 24, 12 + keyboard),
          child: Material(
            color: LuminaColors.surface,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 420, maxHeight: maxHeight),
              child: Column(
                // min + Flexible: диалог по высоте равен содержимому,
                // а не всегда максимальной высоте, как с Expanded.
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 4, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: LuminaColors.textMain,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: LuminaColors.textSecondary,
                          ),
                          onPressed: onClose ??
                              () => Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop(),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
