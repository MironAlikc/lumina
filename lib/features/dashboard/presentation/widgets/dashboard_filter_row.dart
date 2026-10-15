import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_cubit.dart';
import 'package:lumina/features/transactions/presentation/cubits/history_state.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Фильтры списка: тип операции и категория. Используется на дашборде
/// и в истории (общее состояние HistoryCubit).
class DashboardFilterRow extends StatelessWidget {
  const DashboardFilterRow({super.key});

  static bool _fits(HistoryFilterType type, CustomCategory c) => switch (type) {
        HistoryFilterType.all => true,
        HistoryFilterType.expense => c.type == CustomCategory.typeExpense,
        HistoryFilterType.income => c.isIncome,
      };

  void _selectType(
    BuildContext context,
    HistoryFilterType type,
    List<CustomCategory> all,
    String? selectedKey,
  ) {
    HapticFeedback.selectionClick();
    final cubit = context.read<HistoryCubit>();
    cubit.changeFilter(type);

    // Выбранная категория другого типа дала бы пустой список без подсказки.
    final selected = all.where((c) => c.id == selectedKey).firstOrNull;
    if (selected != null && !_fits(type, selected)) {
      cubit.changeCategoryFilter(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return BlocBuilder<HistoryCubit, HistoryState>(
      buildWhen: (p, n) =>
          p.activeFilter != n.activeFilter ||
          p.selectedCategoryKey != n.selectedCategoryKey,
      builder: (context, history) {
        return BlocBuilder<CategoriesCubit, CategoriesState>(
          builder: (context, catState) {
            final all = catState is CategoriesLoaded
                ? catState.categories
                : const <CustomCategory>[];
            final visible = [
              for (final c in all)
                if (_fits(history.activeFilter, c)) c,
            ];

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<HistoryFilterType>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: LuminaColors.surface,
                        foregroundColor: LuminaColors.textMain,
                        selectedBackgroundColor: LuminaColors.accent,
                        selectedForegroundColor: Colors.white,
                        side: const BorderSide(color: LuminaColors.border),
                      ),
                      segments: [
                        ButtonSegment(
                          value: HistoryFilterType.all,
                          label: Text(loc.allFilter),
                        ),
                        ButtonSegment(
                          value: HistoryFilterType.expense,
                          label: Text(loc.expenseFilter),
                        ),
                        ButtonSegment(
                          value: HistoryFilterType.income,
                          label: Text(loc.incomeFilter),
                        ),
                      ],
                      selected: {history.activeFilter},
                      onSelectionChanged: (selection) => _selectType(
                        context,
                        selection.first,
                        all,
                        history.selectedCategoryKey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: visible.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _FilterChip(
                          label: loc.allFilter,
                          icon: Icons.grid_view_rounded,
                          selected: history.selectedCategoryKey == null,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context
                                .read<HistoryCubit>()
                                .changeCategoryFilter(null);
                          },
                        );
                      }
                      final cat = visible[index - 1];
                      return _FilterChip(
                        label: cat.localizedName(loc),
                        icon: cat.icon,
                        iconColor: cat.color,
                        selected: history.selectedCategoryKey == cat.id,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context
                              .read<HistoryCubit>()
                              .changeCategoryFilter(cat.id);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.iconColor,
  });

  final String label;
  final IconData icon;
  final Color? iconColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);

    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: selected ? LuminaColors.accent : LuminaColors.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected
                ? Colors.transparent
                : LuminaColors.cardMintBorder.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? LuminaColors.accent.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: selected ? 6 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        // Прозрачный Material поверх декорации: рябь видна.
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: selected
                          ? Colors.white
                          : (iconColor ?? LuminaColors.textSecondary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: selected ? Colors.white : LuminaColors.textMain,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
