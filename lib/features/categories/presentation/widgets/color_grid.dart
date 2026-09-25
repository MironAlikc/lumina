import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';

class ColorGrid extends StatelessWidget {
  final int selectedColor;
  final ValueChanged<int> onChanged;

  static const List<int> _colors = [
    0xFF00B4D8,
    0xFF10B981,
    0xFFFF9F43,
    0xFFFF4757,
    0xFF9B5DE5,
    0xFF3B82F6,
    0xFFEC4899,
    0xFF6366F1,
    0xFF14B8A6,
    0xFFF59E0B,
  ];

  const ColorGrid({
    super.key,
    required this.selectedColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ЦВЕТ КАТЕГОРИИ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: LuminaColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: LuminaDimensions.paddingS),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _colors.length,
          itemBuilder: (_, i) {
            final isSelected = _colors[i] == selectedColor;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onChanged(_colors[i]);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Color(_colors[i]),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? LuminaColors.textMain
                        : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(
                        _colors[i],
                      ).withValues(alpha: isSelected ? 0.4 : 0.15),
                      blurRadius: isSelected ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      )
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }
}
