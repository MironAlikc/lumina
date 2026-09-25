import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/theme/lumina_colors.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';
import 'package:lumina/features/categories/presentation/widgets/category_name_field.dart';
import 'package:lumina/features/categories/presentation/widgets/color_grid.dart';
import 'package:lumina/features/categories/presentation/widgets/icon_grid.dart';
import 'package:lumina/l10n/app_localizations.dart';

class CreateCategoryScreen extends StatefulWidget {
  const CreateCategoryScreen({super.key, this.initialType = 'expense'});

  final String initialType;

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final _nameController = TextEditingController();
  late String _selectedType;
  var _selectedColor = 0xFF00B4D8;
  var _selectedIcon = 'health';
  String? _errorMessage;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _nameController.addListener(() {
      if (_errorMessage != null) setState(() => _errorMessage = null);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_saving) return;
    final loc = AppLocalizations.of(context)!;
    final rawName = _nameController.text.trim();

    if (rawName.isEmpty) {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = loc.amountRequired);
      return;
    }

    final catState = context.read<CategoriesCubit>().state;
    if (catState is CategoriesLoaded) {
      final nameLower = rawName.toLowerCase();
      final exists = catState.categories.any((c) {
        return c.name.trim().toLowerCase() == nameLower ||
            c.localizedName(loc).toLowerCase() == nameLower;
      });
      if (exists) {
        HapticFeedback.heavyImpact();
        setState(() => _errorMessage = loc.categoryAlreadyExists);
        return;
      }
    }

    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    await context.read<CategoriesCubit>().addCategory(
      name: rawName,
      iconKey: _selectedIcon,
      colorHex: _selectedColor,
      type: _selectedType,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: LuminaColors.background,
      appBar: AppBar(
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
            onPressed: _saving ? null : _handleSave,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
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
      ),
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
                    child: _TypeCard(
                      label: loc.expense,
                      selected: _selectedType == 'expense',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedType = 'expense');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeCard(
                      label: loc.incomeType,
                      selected: _selectedType == 'income',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedType = 'income');
                      },
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
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? LuminaColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? LuminaColors.primary : LuminaColors.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: LuminaColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : LuminaColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
