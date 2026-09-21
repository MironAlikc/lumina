import 'package:hive/hive.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/features/analytics/data/models/analytics.product.model.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';

class AnalyticsRepository {
  List<AnalyticsProductModel> getMatchingExpenses(String query) {
    final box = Hive.box<HistoryExpenseModel>(HiveClient.boxName);
    final trimmedQuery = query.toLowerCase().trim();
    if (trimmedQuery.isEmpty) return const [];

    final results =
        box.values
            .where((e) => e.productName.toLowerCase().contains(trimmedQuery))
            .map(
              (e) => AnalyticsProductModel(
                productName: e.productName,
                date: e.date,
                price: e.price,
              ),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    return results;
  }
}
