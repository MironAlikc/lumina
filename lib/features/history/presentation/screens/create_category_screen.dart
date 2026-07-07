import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumina/core/theme/lumina_theme.dart';
import 'package:lumina/core/localization/lumina_localizations.dart';
import 'package:lumina/features/history/presentation/cubits/categories_cubit.dart';
import 'package:lumina/features/history/presentation/widgets/create_category/category_name_field.dart';
import 'package:lumina/features/history/presentation/widgets/create_category/color_grid.dart';
import 'package:lumina/features/history/presentation/widgets/create_category/icon_grid.dart';

class CreateCategoryScreen extends StatefulWidget {
  const CreateCategoryScreen({super.key});

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedColor = 0xFF00B4D8;
  String _selectedIcon = 'health';

  void _handleSave() {
    if (_nameController.text.trim().isEmpty) return;

    context.read<CategoriesCubit>().addCategory(
      name: _nameController.text.trim(),
      iconKey: _selectedIcon,
      colorHex: _selectedColor,
      type: 'expense',
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
    return Scaffold(
      backgroundColor: LuminaTheme.backgroundColor,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final loc = LuminaLocalizations.of(context);
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        loc.translate('newCategory') ?? 'Новая категория',
        style: const TextStyle(
          color: LuminaTheme.textColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: LuminaTheme.textColor,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        TextButton(
          onPressed: _handleSave,
          child: Text(
            loc.translate('done') ?? 'Создать',
            style: const TextStyle(
              color: LuminaTheme.accentColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
