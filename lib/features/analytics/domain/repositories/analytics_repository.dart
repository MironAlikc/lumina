import 'package:lumina/features/analytics/data/models/analytics_product_model.dart';

abstract class IAnalyticsRepository {
  List<AnalyticsProductModel> searchByProductName(String query);
}
