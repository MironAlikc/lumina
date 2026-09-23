import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/categories_state.dart';
import 'package:lumina/features/history/presentation/screens/create_category_screen.dart';
import 'package:lumina/l10n/app_localizations.dart';

class CategorySelector extends StatefulWidget {
  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  final CustomCategory? selectedCategory;
  final ValueChanged<CustomCategory> onSelected;

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  late String _selectedType;
  var _didAutoSelect = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedCategory?.type ?? 'expense';
  }

  void _selectType(String type) {
    if (_selectedType == type) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedType = type);

    final state = context.read<CategoriesCubit>().state;
    if (state is! CategoriesLoaded) return;
    final next = state.categories.where((c) => c.type == type);
    if (next.isNotEmpty) {
      Future.microtask(() => widget.onSelected(next.first));
    }
  }

  void _autoSelectIfNeeded(List<CustomCategory> categories) {
    if (_didAutoSelect ||
        widget.selectedCategory != null ||
        categories.isEmpty) {
      return;
    }
    _didAutoSelect = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.selectedCategory != null) return;
      widget.onSelected(categories.first);
    });
  }

  Future<void> _openCreateCategory() async {
    HapticFeedback.lightImpact();
    final cubit = context.read<CategoriesCubit>();
    final before = cubit.state is CategoriesLoaded
        ? (cubit.state as CategoriesLoaded).categories.map((c) => c.id).toSet()
        : <String>{};

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: CreateCategoryScreen(initialType: _selectedType),
        ),
      ),
    );

    if (!mounted) return;
    final state = cubit.state;
    if (state is! CategoriesLoaded) return;
    final created = state.categories.where(
      (c) => !before.contains(c.id) && c.type == _selectedType,
    );
    if (created.isNotEmpty) {
      Future.microtask(() => widget.onSelected(created.last));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
          child: Row(
            children: [
              _TypeTabButton(
                title: loc.expense,
                isSelected: _selectedType == 'expense',
                onTap: () => _selectType('expense'),
              ),
              const SizedBox(width: 12),
              _TypeTabButton(
                title: loc.incomeType,
                isSelected: _selectedType == 'income',
                onTap: () => _selectType('income'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 82,
          child: BlocBuilder<CategoriesCubit, CategoriesState>(
            builder: (context, state) {
              if (state is CategoriesLoading) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              }

              final categories = state is CategoriesLoaded
                  ? state.categories
                        .where((cat) => cat.type == _selectedType)
                        .toList()
                  : const <CustomCategory>[];

              _autoSelectIfNeeded(categories);

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == categories.length) {
                    return _AddCategoryButton(onTap: _openCreateCategory);
                  }

                  final category = categories[index];
                  return _CategoryItem(
                    category: category,
                    label: category.localizedName(loc),
                    isSelected: widget.selectedCategory?.id == category.id,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onSelected(category);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TypeTabButton extends StatelessWidget {
  const _TypeTabButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? LuminaColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : LuminaColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.category,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final CustomCategory category;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 88,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? category.color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? category.color.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              color: isSelected ? Colors.white : category.color,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryButton extends StatelessWidget {
  const _AddCategoryButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: LuminaColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_rounded,
              size: 22,
              color: LuminaColors.textSecondary,
            ),
            const SizedBox(height: 2),
            Text(
              loc.create,
              style: const TextStyle(
                fontSize: 10,
                color: LuminaColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
