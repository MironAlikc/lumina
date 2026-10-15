import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/features/accounts/presentation/cubits/account_cubit.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';
import 'package:lumina/features/categories/presentation/screens/create_category_screen.dart';
import 'package:lumina/l10n/app_localizations.dart';

class CategorySelector extends StatefulWidget {
  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
    this.autoSelect = true,
  });

  final CustomCategory? selectedCategory;
  final ValueChanged<CustomCategory> onSelected;

  /// Выбирать первую категорию автоматически. При редактировании нужно
  /// выключить, иначе выбор затрёт редактируемую категорию.
  final bool autoSelect;

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  late String _type;
  bool _didAutoSelect = false;

  @override
  void initState() {
    super.initState();
    _type = widget.selectedCategory?.type ?? CustomCategory.typeExpense;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _autoSelect(context.read<CategoriesCubit>().state);
    });
  }

  @override
  void didUpdateWidget(CategorySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Категорию могли выбрать снаружи (например, загрузилась при
    // редактировании): вкладка должна соответствовать её типу.
    final selected = widget.selectedCategory;
    if (selected != null &&
        selected != oldWidget.selectedCategory &&
        selected.type != _type) {
      _type = selected.type;
    }
  }

  List<CustomCategory> _forType(CategoriesState state, String type) {
    if (state is! CategoriesLoaded) return const [];
    return [
      for (final c in state.categories)
        if (c.type == type) c,
    ];
  }

  void _autoSelect(CategoriesState state) {
    if (!widget.autoSelect ||
        _didAutoSelect ||
        widget.selectedCategory != null) {
      return;
    }
    final list = _forType(state, _type);
    if (list.isEmpty) return;
    _didAutoSelect = true;
    widget.onSelected(list.first);
  }

  void _selectType(String type) {
    if (_type == type) return;
    HapticFeedback.selectionClick();
    setState(() => _type = type);

    final next = _forType(context.read<CategoriesCubit>().state, type);
    if (next.isNotEmpty) widget.onSelected(next.first);
  }

  Future<void> _openCreateCategory() async {
    HapticFeedback.lightImpact();
    final cubit = context.read<CategoriesCubit>();
    final before = {
      for (final c in _forType(cubit.state, _type)) c.id,
    };

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: CreateCategoryScreen(initialType: _type),
        ),
      ),
    );

    if (!mounted) return;
    final created = _forType(cubit.state, _type)
        .where((c) => !before.contains(c.id))
        .toList();
    if (created.isNotEmpty) widget.onSelected(created.last);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    // Переводы имеют смысл только при двух и более счетах.
    final accountCount = context.select(
      (AccountCubit c) => c.state.accounts.length,
    );
    final showTransfer =
        accountCount >= 2 || _type == CustomCategory.typeTransfer;
    final canCreate = _type != CustomCategory.typeTransfer;

    return BlocListener<CategoriesCubit, CategoriesState>(
      listener: (_, state) => _autoSelect(state),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
            child: Wrap(
              spacing: 8,
              children: [
                _TypeTab(
                  title: loc.expense,
                  selected: _type == CustomCategory.typeExpense,
                  onTap: () => _selectType(CustomCategory.typeExpense),
                ),
                _TypeTab(
                  title: loc.incomeType,
                  selected: _type == CustomCategory.typeIncome,
                  onTap: () => _selectType(CustomCategory.typeIncome),
                ),
                if (showTransfer)
                  _TypeTab(
                    title: loc.transfer,
                    selected: _type == CustomCategory.typeTransfer,
                    onTap: () => _selectType(CustomCategory.typeTransfer),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 82,
            child: BlocBuilder<CategoriesCubit, CategoriesState>(
              // Error приходит на один кадр перед Loaded: не перерисовываем.
              buildWhen: (_, next) => next is! CategoriesError,
              builder: (context, state) {
                if (state is CategoriesLoading) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }

                final categories = _forType(state, _type);

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: categories.length + (canCreate ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == categories.length) {
                      return _AddCategoryButton(onTap: _openCreateCategory);
                    }
                    final category = categories[index];
                    return _CategoryItem(
                      category: category,
                      label: category.localizedName(loc),
                      selected: widget.selectedCategory?.id == category.id,
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
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  const _TypeTab({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? LuminaColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                widthFactor: 1,
                child: Text(
                  title,
                  style: TextStyle(
                    color: selected ? Colors.white : LuminaColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
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
    required this.selected,
    required this.onTap,
  });

  final CustomCategory category;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    final radius = BorderRadius.circular(20);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 88,
          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: selected ? color : LuminaColors.surface,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: selected
                    ? color.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: selected ? 12 : 6,
                offset: const Offset(0, 3),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category.icon,
                      color: selected ? Colors.white : color,
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
                        color: selected
                            ? Colors.white
                            : LuminaColors.textSecondary,
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

class _AddCategoryButton extends StatelessWidget {
  const _AddCategoryButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final radius = BorderRadius.circular(20);

    return Semantics(
      button: true,
      label: loc.newCategory,
      child: Container(
        width: 88,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: LuminaColors.surface.withValues(alpha: 0.6),
          borderRadius: radius,
          border: Border.all(
            color: LuminaColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
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
        ),
      ),
    );
  }
}
