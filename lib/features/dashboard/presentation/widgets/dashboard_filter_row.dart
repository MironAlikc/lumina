import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_state.dart';
import 'package:lumina/l10n/app_localizations.dart';

class DashboardFilterRow extends StatelessWidget {
  const DashboardFilterRow({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return BlocBuilder<HistoryCubit, HistoryState>(
      buildWhen: (p, n) => p.selectedCategoryKey != n.selectedCategoryKey,
      builder: (context, historyState) {
        return BlocBuilder<CategoriesCubit, CategoriesState>(
          builder: (context, catState) {
            final categories = catState is CategoriesLoaded
                ? catState.categories
                : const [];

            return SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryFilterChip(
                    label: loc.allFilter,
                    icon: Icons.grid_view_rounded,
                    isSelected: historyState.selectedCategoryKey == null,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<HistoryCubit>().changeCategoryFilter(null);
                    },
                  ),
                  ...categories.map((cat) {
                    return _CategoryFilterChip(
                      label: cat.localizedName(loc),
                      icon: cat.icon,
                      iconColor: cat.color,
                      isSelected: historyState.selectedCategoryKey == cat.id,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.read<HistoryCubit>().changeCategoryFilter(
                          cat.id,
                        );
                      },
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.label,
    required this.icon,
    this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color? iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? LuminaColors.accent : LuminaColors.surface,
              borderRadius: BorderRadius.circular(20),
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
                  color: isSelected
                      ? Colors.white
                      : (iconColor ?? LuminaColors.textSecondary),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : LuminaColors.textMain,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
