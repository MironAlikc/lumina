import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/categories/presentation/cubits/categories_state.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';
import 'package:uuid/uuid.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit() : super(const CategoriesLoading()) {
    loadCategories();
  }

  static const _migrationKey = 'category_ids_migrated_v1';

  /// Названия, под которыми категории хранились в старых версиях.
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

  Box<CustomCategory> get _box =>
      Hive.box<CustomCategory>(HiveClient.categoriesBox);
  Box<HistoryExpenseModel> get _history =>
      Hive.box<HistoryExpenseModel>(HiveClient.historyBox);
  Box<dynamic> get _settings => Hive.box(HiveClient.settingsBox);

  // ------------------------------------------------------------------ load

  /// Подготавливает данные (стандартные категории, слияние дублей, миграция)
  /// и публикует список. Состояние Loading эмитится только если данных ещё нет,
  /// иначе список в селекторе мигал бы.
  Future<void> loadCategories() async {
    if (isClosed) return;
    if (state is! CategoriesLoaded) emit(const CategoriesLoading());

    try {
      await _ensureDefaultCategories();
      await _mergeAliasDuplicates();
      await _migrateLegacyHistory();
      _publish();
    } catch (e, st) {
      debugPrint('loadCategories failed: $e\n$st');
      if (!isClosed) emit(const CategoriesError('load_failed'));
    }
  }

  void _publish() {
    if (isClosed) return;
    emit(CategoriesLoaded(_sorted()));
  }

  /// Порядок не зависит от языка: сначала тип, потом стандартные в порядке
  /// объявления, затем пользовательские по имени.
  List<CustomCategory> _sorted() {
    final order = {
      for (final (i, c) in CustomCategory.defaults().indexed) c.id: i,
    };
    int rank(String type) => switch (type) {
          CustomCategory.typeExpense => 0,
          CustomCategory.typeIncome => 1,
          _ => 2,
        };

    return _box.values.toList()
      ..sort((a, b) {
        final byType = rank(a.type).compareTo(rank(b.type));
        if (byType != 0) return byType;
        final ia = order[a.id];
        final ib = order[b.id];
        if (ia != null && ib != null) return ia.compareTo(ib);
        if (ia != null) return -1;
        if (ib != null) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
  }

  Future<void> _ensureDefaultCategories() async {
    final missing = {
      for (final c in CustomCategory.defaults())
        if (!_box.containsKey(c.id)) c.id: c,
    };
    if (missing.isNotEmpty) await _box.putAll(missing);
  }

  /// Пользовательская категория с «стандартным» именем сливается со
  /// стандартной (того же типа), а её операции переносятся.
  Future<void> _mergeAliasDuplicates() async {
    final remap = <String, String>{};
    for (final cat in _box.values) {
      if (cat.isDefault) continue;
      final targetId = _aliasToDefaultId[cat.name.trim().toLowerCase()];
      if (targetId == null) continue;
      final target = _box.get(targetId);
      if (target == null || target.type != cat.type) continue;
      remap[cat.id] = targetId;
    }
    if (remap.isEmpty) return;

    await _remapHistory(remap);
    await _box.deleteAll(remap.keys);
  }

  /// Переносит операции на другие категории, сохраняя все остальные поля
  /// (счета, время, статус синхронизации).
  Future<void> _remapHistory(Map<String, String> fromTo) async {
    final updates = <String, HistoryExpenseModel>{};
    for (final rec in _history.values) {
      final target = fromTo[rec.categoryId];
      if (target == null) continue;
      updates[rec.id] = rec.copyWith(categoryId: target, isSynced: false);
    }
    if (updates.isNotEmpty) await _history.putAll(updates);
  }

  /// Разовая миграция: у старых записей вместо id хранилось название
  /// категории («Еда», «food»). Переводим на id, чтобы в аналитике не было
  /// двух срезов для одной категории.
  Future<void> _migrateLegacyHistory() async {
    if (_settings.get(_migrationKey) == true) return;

    try {
      final ids = _box.keys.map((k) => k.toString()).toSet();

      final lookup = <String, String>{
        for (final e in _aliasToDefaultId.entries)
          if (ids.contains(e.value)) e.key: e.value,
        for (final c in _box.values) c.name.trim().toLowerCase(): c.id,
      };

      final updates = <String, HistoryExpenseModel>{};
      for (final rec in _history.values) {
        if (ids.contains(rec.categoryId)) continue;
        final target = lookup[rec.categoryId.trim().toLowerCase()] ??
            lookup[(rec.categoryName ?? '').trim().toLowerCase()];
        if (target == null) continue;
        updates[rec.id] = rec.copyWith(categoryId: target, isSynced: false);
      }

      if (updates.isNotEmpty) await _history.putAll(updates);
      await _settings.put(_migrationKey, true);
    } catch (e, st) {
      // Не блокируем загрузку категорий; миграция повторится при запуске.
      debugPrint('Legacy category migration failed: $e\n$st');
    }
  }

  // ------------------------------------------------------------ validation

  String _formatName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  bool _isDuplicateName(String name, {String? exceptId}) {
    final needle = name.toLowerCase();
    for (final c in _box.values) {
      if (c.id != exceptId && c.name.toLowerCase() == needle) return true;
    }
    final defaultId = _aliasToDefaultId[needle];
    return defaultId != null &&
        defaultId != exceptId &&
        _box.containsKey(defaultId);
  }

  // ------------------------------------------------------------- mutations

  /// Ошибка эмитится и сразу заменяется актуальным списком; слушатели
  /// (например, экран создания) получают оба состояния по порядку.
  void _fail(String code) {
    if (isClosed) return;
    emit(CategoriesError(code));
    _publish();
  }

  Future<void> addCategory({
    required String name,
    required String iconKey,
    required int colorHex,
    required String type,
  }) async {
    try {
      final formatted = _formatName(name);
      if (formatted.isEmpty) return;
      if (type != CustomCategory.typeExpense &&
          type != CustomCategory.typeIncome) {
        return _fail('invalid_type');
      }
      if (_isDuplicateName(formatted)) return _fail('duplicate');

      final id = 'cat_${const Uuid().v4()}';
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
      _publish();
    } catch (e, st) {
      debugPrint('addCategory failed: $e\n$st');
      if (!isClosed) emit(const CategoriesError('add_failed'));
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
      if (id == CustomCategory.transferId || !_box.containsKey(id)) return;

      final formatted = _formatName(name);
      if (formatted.isEmpty) return;
      if (_isDuplicateName(formatted, exceptId: id)) return _fail('duplicate');

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
      _publish();
    } catch (e, st) {
      debugPrint('updateCategory failed: $e\n$st');
      if (!isClosed) emit(const CategoriesError('update_failed'));
    }
  }

  /// Стандартные категории удалять нельзя. Операции удалённой категории
  /// остаются и показываются как «Другое».
  Future<void> deleteCategory(String id) async {
    try {
      if (CustomCategory.defaults().any((c) => c.id == id)) return;
      await _box.delete(id);
      _publish();
    } catch (e, st) {
      debugPrint('deleteCategory failed: $e\n$st');
      if (!isClosed) emit(const CategoriesError('delete_failed'));
    }
  }
}
