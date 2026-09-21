import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/l10n/app_localizations.dart';

class CategoryFilterChips extends StatelessWidget {
  const CategoryFilterChips({
    super.key,
    required this.categories,
    required this.selectedCategoryKey,
    required this.onCategorySelected,
  });

  final List<CustomCategory> categories;
  final String? selectedCategoryKey;
  final ValueChanged<String?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        children: [
          _ChipItem(
            label: loc.allFilter,
            icon: Icons.grid_view_rounded,
            isSelected: selectedCategoryKey == null,
            onTap: () {
              HapticFeedback.selectionClick();
              onCategorySelected(null);
            },
          ),
          const SizedBox(width: 6),
          ...categories.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _ChipItem(
                label: cat.localizedName(loc),
                icon: cat.icon,
                isSelected: selectedCategoryKey == cat.id,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onCategorySelected(
                    selectedCategoryKey == cat.id ? null : cat.id,
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ChipItem extends StatelessWidget {
  const _ChipItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? LuminaColors.accent.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: isSelected ? 6 : 4,
                offset: const Offset(0, 2),
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
