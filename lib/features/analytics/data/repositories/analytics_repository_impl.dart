import 'package:hive/hive.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/features/analytics/data/models/analytics_product_model.dart';
import 'package:lumina/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';

class AnalyticsRepositoryImpl implements IAnalyticsRepository {
  Box<HistoryExpenseModel> get _box =>
      Hive.box<HistoryExpenseModel>(HiveClient.historyBox);

  @override
  List<AnalyticsProductModel> searchByProductName(String query) {
    final needle = query.toLowerCase().trim();
    if (needle.isEmpty) return const [];

    return [
      for (final e in _box.values)
        if (e.productName.toLowerCase().contains(needle))
          AnalyticsProductModel(
            productName: e.productName,
            date: e.date,
            price: e.price,
          ),
    ]..sort((a, b) => b.date.compareTo(a.date));
  }
}
