import 'package:hive/hive.dart';
import 'package:lumina/features/history/domain/entities/history_expense.dart';

part 'history_expense_model.g.dart';

@HiveType(typeId: 0)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

@HiveType(typeId: 1)
class HistoryExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime date;
  @HiveField(2)
  final String productName;
  @HiveField(3)
  final double price;
  @HiveField(4)
  final bool isSynced;
  @HiveField(5)
  final String categoryId;
  @HiveField(6)
  final TransactionType type;
  @HiveField(7)
  final String? categoryName;

  HistoryExpenseModel({
    required this.id,
    required this.date,
    required this.productName,
    required this.price,
    this.isSynced = false,
    required this.categoryId,
    this.type = TransactionType.expense,
    this.categoryName,
  });

  bool get isIncome => type == TransactionType.income;

  HistoryExpenseModel copyWith({
    String? id,
    DateTime? date,
    String? productName,
    double? price,
    bool? isSynced,
    String? categoryId,
    TransactionType? type,
    String? categoryName,
  }) {
    return HistoryExpenseModel(
      id: id ?? this.id,
      date: date ?? this.date,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      isSynced: isSynced ?? this.isSynced,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  HistoryExpense toEntity() => HistoryExpense(
    id: id,
    date: date,
    productName: productName,
    price: price,
    category: categoryId,
    type: type.name,
    isSynced: isSynced,
  );

  // ВАЖНО: доменная сущность HistoryExpense хранит только один идентификатор
  // категории (category = categoryId), без отдельного имени. Раньше здесь была
  // эвристика (entity.category.startsWith('cat_')), которая пыталась угадать,
  // хранится ли в этом поле id или готовое имя — но т.к. и дефолтные, и
  // пользовательские категории получают id с префиксом 'cat_' (см.
  // CategoriesCubit.addCategory), эвристика всегда считала это id и теряла имя.
  //
  // Единая точка истины теперь — CategoriesCubit: имя категории ищется по
  // categoryId через categoryMap в момент отображения (CustomCategory.name /
  // .localizedName(loc)), а не хранится дублирующей копией здесь. categoryName
  // остаётся полем модели (нужно для Supabase-совместимости и старых данных),
  // но fromEntity больше не пытается его восстановить эвристикой.
  factory HistoryExpenseModel.fromEntity(HistoryExpense entity) {
    return HistoryExpenseModel(
      id: entity.id,
      date: entity.date,
      productName: entity.productName,
      price: entity.price,
      categoryId: entity.category,
      categoryName: null,
      type: entity.type == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      isSynced: entity.isSynced,
    );
  }

  Map<String, dynamic> toSupabaseMap(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'product_name': productName,
      'price': price,
      'date': date.toIso8601String(),
      'category_id': categoryId,
      'category_name': categoryName ?? '',
      'type': type.name,
    };
  }

  factory HistoryExpenseModel.fromSupabase(Map<String, dynamic> map) {
    return HistoryExpenseModel(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      price: (map['price'] as num).toDouble(),
      productName: (map['product_name'] as String?) ?? '',
      isSynced: true,
      categoryId: (map['category_id'] as String?) ?? 'cat_food',
      categoryName: map['category_name'] as String?,
      type: (map['type'] as String?) == 'income'
          ? TransactionType.income
          : TransactionType.expense,
    );
  }
}
