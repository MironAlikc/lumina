import 'package:flutter/material.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // Material под ListTile: иначе рябь рисуется под цветом контейнера.
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: LuminaColors.surface,
        borderRadius: LuminaDimensions.borderRadiusMedium,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: LuminaColors.textMain,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: LuminaColors.textSecondary,
                  ),
                ),
          trailing: trailing ??
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: LuminaColors.textSecondary,
              ),
          onTap: onTap,
        ),
      ),
    );
  }
}
