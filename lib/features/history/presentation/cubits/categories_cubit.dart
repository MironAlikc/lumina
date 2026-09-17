import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:lumina/features/history/presentation/cubits/categories_state.dart';
import '../../data/models/custom_category_model.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit() : super(CategoriesLoading()) {
    loadCategories();
  }

  Box<CustomCategory> get _box => Hive.box<CustomCategory>('categories_box');

  /// Вспомогательный метод для форматирования названия: первая буква заглавная, остальные без изменений
  String _formatCategoryName(String rawName) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  /// Загрузка категорий с инициализацией дефолтных значений при пустой базе
  Future<void> loadCategories() async {
    try {
      emit(CategoriesLoading());

      if (_box.isEmpty) {
        final defaultCategories = [
          // Расходы
          CustomCategory(
            id: 'cat_food',
            name: 'Food',
            iconKey: 'food',
            colorHex: 0xFFFF9F43,
            type: 'expense',
          ),
          CustomCategory(
            id: 'cat_transport',
            name: 'Transport',
            iconKey: 'transport',
            colorHex: 0xFF3B82F6,
            type: 'expense',
          ),
          CustomCategory(
            id: 'cat_shopping',
            name: 'Shopping',
            iconKey: 'shopping',
            colorHex: 0xFFFF4757,
            type: 'expense',
          ),
          // Доход (Приход)
          CustomCategory(
            id: 'cat_salary',
            name: 'Salary',
            iconKey: 'wallet',
            colorHex: 0xFF2ECC71,
            type: 'income',
          ),
        ];
        for (var cat in defaultCategories) {
          await _box.put(cat.id, cat);
        }
      }

      final list = _box.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      emit(CategoriesLoaded(list));
    } catch (e) {
      emit(CategoriesError('Не удалось загрузить категории: ${e.toString()}'));
    }
  }

  /// Добавление новой категории с авто-форматированием имени
  Future<void> addCategory({
    required String name,
    required String iconKey,
    required int colorHex,
    required String type,
  }) async {
    try {
      final formattedName = _formatCategoryName(name);
      final String id = 'cat_${DateTime.now().millisecondsSinceEpoch}';

      final newCategory = CustomCategory(
        id: id,
        name: formattedName,
        iconKey: iconKey,
        colorHex: colorHex,
        type: type,
      );

      await _box.put(id, newCategory);
      await loadCategories();
    } catch (e) {
      emit(CategoriesError('Ошибка добавления категории: ${e.toString()}'));
    }
  }

  /// Обновление существующей категории
  Future<void> updateCategory({
    required String id,
    required String name,
    required String iconKey,
    required int colorHex,
    required String type,
  }) async {
    try {
      final formattedName = _formatCategoryName(name);

      final updatedCategory = CustomCategory(
        id: id,
        name: formattedName,
        iconKey: iconKey,
        colorHex: colorHex,
        type: type,
      );

      await _box.put(id, updatedCategory);
      await loadCategories();
    } catch (e) {
      emit(CategoriesError('Ошибка обновления категории: ${e.toString()}'));
    }
  }

  /// Удаление категории по ID
  Future<void> deleteCategory(String id) async {
    try {
      await _box.delete(id);
      await loadCategories();
    } catch (e) {
      emit(CategoriesError('Ошибка удаления категории: ${e.toString()}'));
    }
  }
}
