import 'package:flutter/material.dart';
import 'package:lumina/core/theme/lumina_theme.dart';

class AirKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AirKey({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isDeleteKey = label == '⌫';
    final bool isDotKey = label == '.';

    // Цветовая схема
    final Color bgColor = isDeleteKey
        ? const Color(0xFFFFF1F2)
        : const Color(0xFFF8FAFC);
    final Color iconColor = isDeleteKey
        ? const Color(0xFFEF4444)
        : LuminaTheme.textColor;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: bgColor,
          boxShadow: [
            // Тень для неоморфизма (справа-снизу)
            BoxShadow(
              color: isDeleteKey
                  ? const Color(0xFFFCA5A5).withValues(alpha: 0.18)
                  : const Color(0xFF1E293B).withValues(alpha: 0.09),
              blurRadius: 10,
              offset: const Offset(4, 5),
            ),
            // Светлый блик (слева-сверху)
            const BoxShadow(
              color: Colors.white,
              blurRadius: 6,
              offset: Offset(-3, -3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            splashColor: isDeleteKey
                ? const Color(0xFFFFE4E6)
                : const Color(0xFFE2E8F0),
            highlightColor: Colors.transparent,
            child: Center(
              child: isDeleteKey
                  ? const Icon(
                      Icons.backspace_rounded,
                      color: Color(0xFFEF4444),
                      size: 22,
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: isDotKey ? 28 : 24,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
