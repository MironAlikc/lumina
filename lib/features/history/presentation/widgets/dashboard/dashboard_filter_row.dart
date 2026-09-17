import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/features/history/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/categories_state.dart';
import 'package:lumina/features/history/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/history_state.dart';
import 'package:lumina/l10n/app_localizations.dart';

class DashboardFilterRow extends StatelessWidget {
  const DashboardFilterRow({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return BlocBuilder<HistoryCubit, HistoryState>(
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
                    icon: Icons.apps_rounded,
                    isSelected: historyState.selectedCategoryKey == null,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<HistoryCubit>().changeCategoryFilter(null);
                    },
                  ),
                  ...categories.map((cat) {
                    final isSelected =
                        historyState.selectedCategoryKey == cat.id;
                    return _CategoryFilterChip(
                      label: cat.name,
                      icon: cat.icon,
                      iconColor: cat.color,
                      isSelected: isSelected,
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
  final String label;
  final IconData icon;
  final Color? iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryFilterChip({
    required this.label,
    required this.icon,
    this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? LuminaTheme.accentColor.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? LuminaTheme.accentColor.withValues(alpha: 0.5)
                    : const Color(0xFFF1F5F9),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected
                      ? LuminaTheme.accentColor
                      : (iconColor ?? LuminaTheme.subTitleColor),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? LuminaTheme.accentColor
                        : LuminaTheme.textColor,
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
