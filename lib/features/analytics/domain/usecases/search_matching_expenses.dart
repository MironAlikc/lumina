import 'package:lumina/features/analytics/data/models/analytics_product_model.dart';
import 'package:lumina/features/analytics/domain/repositories/analytics_repository.dart';

class SearchMatchingExpenses {
  const SearchMatchingExpenses(this._repository);

  final IAnalyticsRepository _repository;

  List<AnalyticsProductModel> call(String query) {
    return _repository.searchByProductName(query);
  }
}
