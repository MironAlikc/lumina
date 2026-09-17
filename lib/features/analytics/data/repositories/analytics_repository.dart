import 'package:hive/hive.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/features/analytics/data/models/analytics.product.model.dart';

class AnalyticsRepository {
  List<AnalyticsProductModel> getMatchingExpenses(String query) {
    final box = Hive.box(HiveClient.boxName);
    final trimmedQuery = query.toLowerCase().trim();

    final results = box.values
        .where((e) => e is Map)
        .map((e) => AnalyticsProductModel.fromMap(e as Map))
        .where((e) => e.productName.toLowerCase().contains(trimmedQuery))
        .toList();

    results.sort((a, b) => b.date.compareTo(a.date));
    return results;
  }
}
