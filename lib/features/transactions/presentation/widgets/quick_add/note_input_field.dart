import 'package:flutter/material.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/l10n/app_localizations.dart';

class NoteInputField extends StatelessWidget {
  const NoteInputField({
    super.key,
    required this.controller,
    this.maxLength = 80,
  });

  final TextEditingController controller;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          maxLines: 1,
          maxLength: maxLength,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          cursorColor: LuminaColors.accent,
          style: const TextStyle(fontSize: 16, color: LuminaColors.textMain),
          decoration: InputDecoration(
            hintText: loc.addNote,
            hintStyle: TextStyle(
              color: LuminaColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 15,
            ),
            counterText: '',
            filled: true,
            fillColor: LuminaColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: LuminaColors.accent,
                width: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
