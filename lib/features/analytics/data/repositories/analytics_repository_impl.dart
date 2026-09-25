import 'package:hive/hive.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/features/analytics/data/models/analytics_product_model.dart';
import 'package:lumina/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';

class AnalyticsRepositoryImpl implements IAnalyticsRepository {
  @override
  List<AnalyticsProductModel> searchByProductName(String query) {
    final trimmed = query.toLowerCase().trim();
    if (trimmed.isEmpty) return const [];

    final box = Hive.box<HistoryExpenseModel>(HiveClient.boxName);
    final results =
        box.values
            .where((e) => e.productName.toLowerCase().contains(trimmed))
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
