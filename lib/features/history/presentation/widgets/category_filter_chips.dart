import 'package:flutter/material.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/l10n/app_localizations.dart';
import '../../data/models/custom_category_model.dart';

class CategoryFilterChips extends StatelessWidget {
  final List<CustomCategory> categories;
  final String? selectedCategoryKey;
  final ValueChanged<String?> onCategorySelected;

  const CategoryFilterChips({
    super.key,
    required this.categories,
    required this.selectedCategoryKey,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bool isAllSelected = selectedCategoryKey == null;

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildChipItem(
            context: context,
            id: null,
            label: loc.allFilter,
            icon: Icons.grid_view_rounded,
            isSelected: isAllSelected,
          ),
          const SizedBox(width: 6),
          ...categories.map((cat) {
            final isSelected = selectedCategoryKey == cat.id;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _buildChipItem(
                context: context,
                id: cat.id,
                label: cat.name,
                icon: cat.icon,
                isSelected: isSelected,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChipItem({
    required BuildContext context,
    required String? id,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onCategorySelected(id),
        // Возвращаем и синхронизируем borderRadius для красивой анимации нажатия
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? LuminaColors.accent : LuminaColors.surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : LuminaColors.cardMintBorder.withValues(alpha: 0.6),
              width: 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: LuminaColors.accent.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : LuminaColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : LuminaColors.textMain,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
