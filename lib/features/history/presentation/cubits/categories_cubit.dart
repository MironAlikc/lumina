import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/presentation/cubits/categories_state.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit() : super(CategoriesLoading()) {
    loadCategories();
  }

  Box<CustomCategory> get _box => Hive.box<CustomCategory>('categories_box');

  String _formatCategoryName(String rawName) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  Future<void> loadCategories() async {
    try {
      emit(CategoriesLoading());

      if (_box.isEmpty) {
        for (final cat in CustomCategory.defaults()) {
          await _box.put(cat.id, cat);
        }
      } else {
        await _ensureDefaultCategories();
      }

      final list = _box.values.toList()
        ..sort((a, b) {
          final byType = a.type.compareTo(b.type);
          if (byType != 0) return byType;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

      emit(CategoriesLoaded(list));
    } catch (e) {
      emit(const CategoriesError('load_failed'));
    }
  }

  Future<void> _ensureDefaultCategories() async {
    for (final cat in CustomCategory.defaults()) {
      if (!_box.containsKey(cat.id)) {
        await _box.put(cat.id, cat);
      }
    }
  }

  Future<void> addCategory({
    required String name,
    required String iconKey,
    required int colorHex,
    required String type,
  }) async {
    try {
      final formattedName = _formatCategoryName(name);
      if (formattedName.isEmpty) return;

      final duplicate = _box.values.any(
        (c) => c.name.toLowerCase() == formattedName.toLowerCase(),
      );
      if (duplicate) {
        emit(const CategoriesError('duplicate'));
        await loadCategories();
        return;
      }

      final id = 'cat_${DateTime.now().millisecondsSinceEpoch}';
      await _box.put(
        id,
        CustomCategory(
          id: id,
          name: formattedName,
          iconKey: iconKey,
          colorHex: colorHex,
          type: type,
        ),
      );
      await loadCategories();
    } catch (_) {
      emit(const CategoriesError('add_failed'));
    }
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required String iconKey,
    required int colorHex,
    required String type,
  }) async {
    try {
      await _box.put(
        id,
        CustomCategory(
          id: id,
          name: _formatCategoryName(name),
          iconKey: iconKey,
          colorHex: colorHex,
          type: type,
        ),
      );
      await loadCategories();
    } catch (_) {
      emit(const CategoriesError('update_failed'));
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      if (CustomCategory.defaults().any((c) => c.id == id)) return;
      await _box.delete(id);
      await loadCategories();
    } catch (_) {
      emit(const CategoriesError('delete_failed'));
    }
  }
}
