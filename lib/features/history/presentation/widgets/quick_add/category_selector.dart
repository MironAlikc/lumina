import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/presentation/cubits/categories_state.dart';
import 'package:lumina/features/history/presentation/screens/create_category_screen.dart';
import 'package:lumina/l10n/app_localizations.dart';
import '../../cubits/categories_cubit.dart';

class CategorySelector extends StatefulWidget {
  final CustomCategory? selectedCategory;
  final ValueChanged<CustomCategory> onSelected;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  String _selectedType = 'expense';

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
                onTap: () => setState(() => _selectedType = 'expense'),
              ),
              const SizedBox(width: 12),
              _TypeTabButton(
                title: loc.incomeType,
                isSelected: _selectedType == 'income',
                onTap: () => setState(() => _selectedType = 'income'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 76,
          child: BlocBuilder<CategoriesCubit, CategoriesState>(
            builder: (context, state) {
              if (state is CategoriesLoading) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              }

              final allCategories = state is CategoriesLoaded
                  ? state.categories
                  : <CustomCategory>[];

              final categories = allCategories
                  .where((cat) => cat.type == _selectedType)
                  .toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == categories.length) {
                    return _AddCategoryButton(
                      onTap: () => _openCreateCategory(context),
                    );
                  }

                  final category = categories[index];
                  return _CategoryItem(
                    category: category,
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

  void _openCreateCategory(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (modalContext) => BlocProvider.value(
          value: context.read<CategoriesCubit>(),
          child: const CreateCategoryScreen(),
        ),
      ),
    );
  }
}

class _TypeTabButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeTabButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

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
  final CustomCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 74,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCategoryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: LuminaColors.textSecondary.withValues(alpha: 0.2),
            style: BorderStyle.solid,
            width: 1,
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
