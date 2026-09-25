import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit() : super(CategoriesLoading()) {
    loadCategories();
  }

  Box<CustomCategory> get _box => Hive.box<CustomCategory>('categories_box');

  static const _aliasToDefaultId = <String, String>{
    'food': 'cat_food',
    'food & drinks': 'cat_food',
    'еда и напитки': 'cat_food',
    'їжа та напої': 'cat_food',
    'transport': 'cat_transport',
    'транспорт': 'cat_transport',
    'shopping': 'cat_shopping',
    'покупки': 'cat_shopping',
    'entertainment': 'cat_entertainment',
    'развлечения': 'cat_entertainment',
    'розваги': 'cat_entertainment',
    'housing': 'cat_housing',
    'home': 'cat_housing',
    'жильё': 'cat_housing',
    'житло': 'cat_housing',
    'salary': 'cat_salary',
    'зарплата': 'cat_salary',
    'income': 'cat_salary',
    'доход': 'cat_salary',
    'доходы': 'cat_salary',
    'доходи': 'cat_salary',
  };

  String _formatCategoryName(String rawName) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  bool _isDuplicateName(String formattedName, {String? exceptId}) {
    final needle = formattedName.toLowerCase();
    for (final c in _box.values) {
      if (c.id == exceptId) continue;
      if (c.name.toLowerCase() == needle) return true;
    }
    final defaultId = _aliasToDefaultId[needle];
    if (defaultId != null &&
        defaultId != exceptId &&
        _box.containsKey(defaultId)) {
      return true;
    }
    return false;
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
        await _mergeAliasDuplicates();
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

  Future<void> _mergeAliasDuplicates() async {
    for (final cat in _box.values.toList()) {
      if (cat.isDefault) continue;
      final targetId = _aliasToDefaultId[cat.name.toLowerCase()];
      if (targetId == null || !_box.containsKey(targetId)) continue;
      await _remapHistory(fromId: cat.id, intoId: targetId);
      await _box.delete(cat.id);
    }
  }

  Future<void> _remapHistory({
    required String fromId,
    required String intoId,
  }) async {
    if (!Hive.isBoxOpen(HiveClient.boxName)) return;
    final history = Hive.box<HistoryExpenseModel>(HiveClient.boxName);
    for (final rec in history.values.toList()) {
      if (rec.categoryId != fromId) continue;
      await history.put(
        rec.id,
        HistoryExpenseModel(
          id: rec.id,
          date: rec.date,
          productName: rec.productName,
          price: rec.price,
          categoryId: intoId,
          categoryName: rec.categoryName,
          type: rec.type,
        ),
      );
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

      if (_isDuplicateName(formattedName)) {
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
      final formatted = _formatCategoryName(name);
      if (_isDuplicateName(formatted, exceptId: id)) {
        emit(const CategoriesError('duplicate'));
        await loadCategories();
        return;
      }
      await _box.put(
        id,
        CustomCategory(
          id: id,
          name: formatted,
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
