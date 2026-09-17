import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/features/history/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/history/presentation/cubits/categories_state.dart';
import 'package:lumina/features/history/presentation/widgets/create_category/category_name_field.dart';
import 'package:lumina/features/history/presentation/widgets/create_category/color_grid.dart';
import 'package:lumina/features/history/presentation/widgets/create_category/icon_grid.dart';
import 'package:lumina/l10n/app_localizations.dart';

class CreateCategoryScreen extends StatefulWidget {
  const CreateCategoryScreen({super.key});

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedColor = 0xFF00B4D8;
  String _selectedIcon = 'health';
  String _selectedType = 'expense';
  String? _errorMessage;

  void _handleSave(AppLocalizations loc) {
    final rawName = _nameController.text.trim();
    if (rawName.isEmpty) return;

    final catState = context.read<CategoriesCubit>().state;
    if (catState is CategoriesLoaded) {
      final nameLower = rawName.toLowerCase();
      final exists = catState.categories.any(
        (c) => c.name.trim().toLowerCase() == nameLower,
      );

      if (exists) {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = loc.categoryAlreadyExists;
        });
        return;
      }
    }

    HapticFeedback.lightImpact();
    context.read<CategoriesCubit>().addCategory(
      name: rawName,
      iconKey: _selectedIcon,
      colorHex: _selectedColor,
      type: _selectedType,
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: LuminaColors.background,
      appBar: _buildAppBar(context, loc),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(LuminaDimensions.paddingXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFDC2626),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                loc.categoryType,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: LuminaColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = 'expense'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selectedType == 'expense'
                              ? LuminaColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _selectedType == 'expense'
                              ? [
                                  BoxShadow(
                                    color: LuminaColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                          border: Border.all(
                            color: _selectedType == 'expense'
                                ? LuminaColors.primary
                                : LuminaColors.border,
                          ),
                        ),
                        child: Text(
                          loc.expense,
                          style: TextStyle(
                            color: _selectedType == 'expense'
                                ? Colors.white
                                : LuminaColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = 'income'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selectedType == 'income'
                              ? LuminaColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _selectedType == 'income'
                              ? [
                                  BoxShadow(
                                    color: LuminaColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                          border: Border.all(
                            color: _selectedType == 'income'
                                ? LuminaColors.primary
                                : LuminaColors.border,
                          ),
                        ),
                        child: Text(
                          loc.incomeType,
                          style: TextStyle(
                            color: _selectedType == 'income'
                                ? Colors.white
                                : LuminaColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CategoryNameField(controller: _nameController),
              const SizedBox(height: 28),
              ColorGrid(
                selectedColor: _selectedColor,
                onChanged: (c) => setState(() => _selectedColor = c),
              ),
              const SizedBox(height: 28),
              IconGrid(
                selectedIcon: _selectedIcon,
                activeColor: _selectedColor,
                onChanged: (i) => setState(() => _selectedIcon = i),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppLocalizations loc) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        loc.newCategory,
        style: const TextStyle(
          color: LuminaColors.textMain,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: LuminaColors.textMain,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        TextButton(
          onPressed: () => _handleSave(loc),
          child: Text(
            loc.create,
            style: const TextStyle(
              color: LuminaColors.accent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: LuminaDimensions.paddingS),
      ],
    );
  }
}
