import 'package:flutter/material.dart';
import 'package:lumina/core/theme/lumina_colors.dart';

class AnalyticsChartModeSwitcher extends StatelessWidget {
  const AnalyticsChartModeSwitcher({
    super.key,
    required this.isLineMode,
    required this.categoriesLabel,
    required this.trendLabel,
    required this.onChanged,
  });

  final bool isLineMode;
  final String categoriesLabel;
  final String trendLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: LuminaColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: LuminaColors.cardMintBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Tab(
              label: categoriesLabel,
              selected: !isLineMode,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _Tab(
              label: trendLabel,
              selected: isLineMode,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? LuminaColors.cardMint : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? LuminaColors.textMain
                : LuminaColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
