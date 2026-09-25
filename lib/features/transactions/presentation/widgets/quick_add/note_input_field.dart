import 'package:flutter/material.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/l10n/app_localizations.dart';

class NoteInputField extends StatelessWidget {
  final TextEditingController controller;

  const NoteInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
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
          cursorColor: LuminaTheme.accentColor,
          style: const TextStyle(fontSize: 16, color: LuminaTheme.textColor),
          decoration: InputDecoration(
            hintText: loc.addNote,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 15),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
