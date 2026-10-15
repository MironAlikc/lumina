import 'package:equatable/equatable.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';

abstract class CategoriesState extends Equatable {
  const CategoriesState();

  @override
  List<Object?> get props => [];
}

class CategoriesLoading extends CategoriesState {
  const CategoriesLoading();
}

class CategoriesLoaded extends CategoriesState {
  const CategoriesLoaded(this.categories);

  final List<CustomCategory> categories;

  @override
  List<Object?> get props => [categories];
}

class CategoriesError extends CategoriesState {
  const CategoriesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
