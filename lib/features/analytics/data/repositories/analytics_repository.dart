import 'package:hive/hive.dart';

import '../../../../core/database/hive_client.dart';

class AnalyticsProductModel {
  final String productName;
  final DateTime date;
  final double price;

  AnalyticsProductModel({
    required this.productName,
    required this.date,
    required this.price,
  });

  factory AnalyticsProductModel.fromMap(Map<dynamic, dynamic> map) {
    return AnalyticsProductModel(
      productName: map['productName'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      price: map['price'] as double,
    );
  }
}

class AnalyticsRepository {
  List<AnalyticsProductModel> getMatchingExpenses(String query) {
    final box = Hive.box(HiveClient.boxName);
    return box.values
        .map((e) => AnalyticsProductModel.fromMap(e as Map))
        .where(
          (e) =>
              e.productName.toLowerCase().contains(query.toLowerCase().trim()),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}
