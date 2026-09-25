import 'package:flutter/material.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';

class CategoryNameField extends StatelessWidget {
  final TextEditingController controller;

  const CategoryNameField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'НАЗВАНИЕ КАТЕГОРИИ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: LuminaColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: LuminaDimensions.paddingS),
        TextField(
          controller: controller,
          style: const TextStyle(
            color: LuminaColors.textMain,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Введите название...',
            hintStyle: TextStyle(
              color: LuminaColors.textSecondary.withValues(alpha: 0.6),
              fontSize: 15,
            ),
            filled: true,
            fillColor: LuminaColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: LuminaDimensions.paddingM,
              vertical: LuminaDimensions.paddingM,
            ),
            border: OutlineInputBorder(
              borderRadius: LuminaDimensions.borderRadiusMedium,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: LuminaDimensions.borderRadiusMedium,
              borderSide: const BorderSide(
                color: LuminaColors.border,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: LuminaDimensions.borderRadiusMedium,
              borderSide: const BorderSide(
                color: LuminaColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
