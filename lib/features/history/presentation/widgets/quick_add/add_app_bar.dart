import 'package:flutter/material.dart';
import '../../../../../core/theme/lumina_theme.dart';
import '../../../../../core/localization/lumina_localizations.dart';

class AddAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isLoading;
  final VoidCallback onDone;
  final bool canSave;

  const AddAppBar({
    super.key,
    required this.isLoading,
    required this.onDone,
    required this.canSave,
  });

  @override
  Widget build(BuildContext context) {
    final loc = LuminaLocalizations.of(context);
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: LuminaTheme.textColor),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        LuminaTheme.accentColor,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: canSave ? onDone : null,
                    child: Text(
                      loc.translate('done') ?? 'Готово',
                      style: TextStyle(
                        color: canSave
                            ? LuminaTheme.accentColor
                            : Colors.black26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
