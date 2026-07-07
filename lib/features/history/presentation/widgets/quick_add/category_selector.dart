import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/localization/lumina_localizations.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/presentation/screens/create_category_screen.dart';
import '../../cubits/categories_cubit.dart';

class CategorySelector extends StatelessWidget {
  final CustomCategory? selectedCategory;
  final Function(CustomCategory) onSelected;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: BlocBuilder<CategoriesCubit, CategoriesState>(
        builder: (context, state) {
          if (state is CategoriesLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          final categories = state is CategoriesLoaded
              ? state.categories
              : <CustomCategory>[];

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              if (index == categories.length)
                return _AddCategoryButton(
                  onTap: () => _openCreateCategory(context),
                );

              final category = categories[index];
              return _CategoryItem(
                category: category,
                isSelected: selectedCategory?.id == category.id,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSelected(category);
                },
              );
            },
          );
        },
      ),
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
    final loc = LuminaLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 88,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? category.color : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? category.color.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              color: isSelected ? Colors.white : category.color,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              loc.translate(category.name) ?? category.name,
              style: TextStyle(
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
  final VoidCallback onTap;
  const _AddCategoryButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 88,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(Icons.add_rounded, size: 26), Text('Создать')],
      ),
    ),
  );
}
