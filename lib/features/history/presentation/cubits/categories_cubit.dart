import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../../data/models/custom_category_model.dart';

// --- СОСТОЯНИЯ КУБИТА (States) ---

abstract class CategoriesState {
  const CategoriesState();
}

/// Состояние первоначальной загрузки данных из Hive
class CategoriesLoading extends CategoriesState {
  const CategoriesLoading();
}

/// Состояние, когда список категорий успешно считан и готов к отображению в UI
class CategoriesLoaded extends CategoriesState {
  final List<CustomCategory> categories;

  const CategoriesLoaded(this.categories);
}

/// Состояние на случай непредвиденных ошибок при работе с базой данных
class CategoriesError extends CategoriesState {
  final String message;

  const CategoriesError(this.message);
}

// --- САМ КУБИТ (Cubit) ---

class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit() : super(const CategoriesLoading());

  /// Удобный геттер для быстрого доступа к открытому в main.dart боксу Hive
  Box<CustomCategory> get _box => Hive.box<CustomCategory>('categories_box');

  /// Загружает категории из локального хранилища Hive.
  /// Если приложение запущено впервые и бокс пуст, наполняет его базовыми категориями.
  Future<void> loadCategories() async {
    try {
      emit(const CategoriesLoading());

      // Проверяем, если бокс абсолютно пустой — создаем базовый набор
      if (_box.isEmpty) {
        final defaultCategories = [
          CustomCategory(
            id: 'default_food',
            name: 'food',
            iconKey: 'food',
            colorHex: 0xFFFF9F43, // Оранжевый
            type: 'expense',
          ),
          CustomCategory(
            id: 'default_transport',
            name: 'transport',
            iconKey: 'transport',
            colorHex: 0xFF3B82F6, // Синий
            type: 'expense',
          ),
          CustomCategory(
            id: 'default_shopping',
            name: 'shopping',
            iconKey: 'shopping',
            colorHex: 0xFFFF4757, // Красный
            type: 'expense',
          ),
          CustomCategory(
            id: 'default_entertainment',
            name: 'entertainment',
            iconKey: 'entertainment',
            colorHex: 0xFF9B5DE5, // Фиолетовый
            type: 'expense',
          ),
        ];

        // Сохраняем все дефолтные категории в локальную БД
        for (var category in defaultCategories) {
          await _box.put(category.id, category);
        }
      }

      // Получаем все сохраненные объекты, преобразуем в List и отдаем в UI
      final List<CustomCategory> loadedList = _box.values.toList();
      emit(CategoriesLoaded(loadedList));
    } catch (e) {
      emit(CategoriesError('Не удалось загрузить категории: ${e.toString()}'));
    }
  }

  /// Добавляет новую кастомную категорию, созданную пользователем из UI.
  /// [name] — Имя категории (или ключ локализации).
  /// [iconKey] — Строковый идентификатор иконки ('health', 'education' и т.д.).
  /// [colorHex] — Числовое представление цвета (например, 0xFF10B981).
  /// [type] — Тип транзакции: 'expense' (расход) или 'income' (доход).
  Future<void> addCategory({
    required String name,
    required String iconKey,
    required int colorHex,
    required String type,
  }) async {
    try {
      // Генерируем уникальный ID на основе текущего штампа времени
      final String uniqueId = DateTime.now().millisecondsSinceEpoch.toString();

      final newCategory = CustomCategory(
        id: uniqueId,
        name: name,
        iconKey: iconKey,
        colorHex: colorHex,
        type: type,
      );

      // Записываем объект в Hive
      await _box.put(uniqueId, newCategory);

      // Информируем UI об успешном обновлении списка данных
      await loadCategories();
    } catch (e) {
      emit(CategoriesError('Не удалось создать категорию: ${e.toString()}'));
    }
  }

  /// Дополнительный метод: позволяет удалить категорию по её ID, если это необходимо
  Future<void> deleteCategory(String id) async {
    try {
      await _box.delete(id);
      await loadCategories();
    } catch (e) {
      emit(CategoriesError('Не удалось удалить категорию: ${e.toString()}'));
    }
  }
}
