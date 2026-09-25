import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';

class IconGrid extends StatelessWidget {
  final String selectedIcon;
  final int activeColor;
  final ValueChanged<String> onChanged;

  static const Map<String, IconData> _iconsMap = {
    'health': Icons.medical_services_rounded,
    'education': Icons.school_rounded,
    'home': Icons.home_rounded,
    'food': Icons.fastfood_rounded,
    'transport': Icons.directions_car_rounded,
    'shopping': Icons.local_mall_rounded,
    'entertainment': Icons.confirmation_number_rounded,
    'work': Icons.work_rounded,
    'sport': Icons.fitness_center_rounded,
    'gifts': Icons.card_giftcard_rounded,
  };

  const IconGrid({
    super.key,
    required this.selectedIcon,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ИКОНКА КАТЕГОРИИ',
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
          itemCount: _iconsMap.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final String key = _iconsMap.keys.elementAt(index);
            final bool isSelected = selectedIcon == key;

            return _IconItem(
              iconData: _iconsMap[key]!,
              isSelected: isSelected,
              activeColor: Color(activeColor),
              onTap: () {
                HapticFeedback.lightImpact();
                onChanged(key);
              },
            );
          },
        ),
      ],
    );
  }
}

class _IconItem extends StatelessWidget {
  final IconData iconData;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _IconItem({
    required this.iconData,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : LuminaColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.transparent : LuminaColors.border,
            width: 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: activeColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Icon(
          iconData,
          color: isSelected ? Colors.white : LuminaColors.textSecondary,
          size: 22,
        ),
      ),
    );
  }
}
