import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/lumina_theme.dart'; // Импортируем тему
import '../../../../core/localization/lumina_localizations.dart';
import '../cubits/categories_cubit.dart';

class CreateCategoryView extends StatefulWidget {
  const CreateCategoryView({Key? key}) : super(key: key);

  @override
  State<CreateCategoryView> createState() => _CreateCategoryViewState();
}

class _CreateCategoryViewState extends State<CreateCategoryView> {
  final TextEditingController _nameController = TextEditingController();

  // Дефолтный выбранный цвет теперь — наш мятно-бирюзовый!
  int _selectedColorHex = 0xFF00B4D8;
  String _selectedIconKey = 'health';
  String _selectedType = 'expense';

  // Премиальная обновленная палитра сочных цветов (Hex) с мятным на первом месте
  final List<int> _colors = [
    0xFF00B4D8, // Наш премиальный мятно-бирюзовый
    0xFF10B981, // Элегантный зеленый
    0xFFFF9F43, // Теплый оранжевый
    0xFFFF4757, // Коралловый красный
    0xFF9B5DE5, // Глубокий фиолетовый
    0xFFEC4899, // Неоновый розовый
    0xFF06B6D4, // Морская волна
    0xFFF59E0B, // Солнечный желтый
  ];

  final Map<String, IconData> _availableIcons = {
    'health': Icons.medical_services_rounded,
    'education': Icons.school_rounded,
    'home': Icons.home_rounded,
    'food': Icons.fastfood_rounded,
    'transport': Icons.directions_car_rounded,
    'shopping': Icons.local_mall_rounded,
    'entertainment': Icons.confirmation_number_rounded,
    'work': Icons.work_rounded,
    'sport': Icons.fitness_center_rounded,
    'gifts': Icons.card_giftcard_rounded,
  };

  void _saveCategory() {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      HapticFeedback.vibrate();
      return;
    }

    HapticFeedback.mediumImpact();

    context.read<CategoriesCubit>().addCategory(
      name: name,
      iconKey: _selectedIconKey,
      colorHex: _selectedColorHex,
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
    final loc = LuminaLocalizations.of(context);

    return Scaffold(
      backgroundColor: LuminaTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Новая категория',
          style: TextStyle(
            color: LuminaTheme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
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
            onPressed: _saveCategory,
            child: Text(
              loc.translate('done') ?? 'Создать',
              style: const TextStyle(
                color: LuminaTheme
                    .accentColor, // Премиальный бирюзовый вместо синего
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ТЕКСТОВОЕ ПОЛЕ ИМЕНИ
              TextField(
                controller: _nameController,
                maxLines: 1,
                maxLength: 20,
                cursorColor: LuminaTheme.accentColor, // Курсор в цвет темы
                style: const TextStyle(
                  fontSize: 16,
                  color: LuminaTheme.textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Название категории',
                  hintStyle: const TextStyle(color: Colors.black26),
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 2. ВЫБОР ЦВЕТА
              const Text(
                'ЦВЕТ КАТЕГОРИИ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: LuminaTheme.subTitleColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _colors.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final colorHex = _colors[index];
                  final isSelected = _selectedColorHex == colorHex;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedColorHex = colorHex);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: Color(colorHex),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: LuminaTheme.textColor, width: 3)
                            : null,
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: Color(colorHex).withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // 3. ВЫБОР ИКОНКИ
              const Text(
                'ИКОНКА КАТЕГОРИИ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: LuminaTheme.subTitleColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _availableIcons.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final String key = _availableIcons.keys.elementAt(index);
                  final IconData iconData = _availableIcons[key]!;
                  final isSelected = _selectedIconKey == key;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedIconKey = key);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(_selectedColorHex)
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : const Color(0xFFF1F5F9),
                          width: 1.5,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: Color(_selectedColorHex).withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          else
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Icon(
                        iconData,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF475569),
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
