import 'package:flutter/foundation.dart';

@immutable
class AnalyticsProductModel {
  const AnalyticsProductModel({
    required this.productName,
    required this.date,
    required this.price,
  });

  final String productName;
  final DateTime date;
  final double price;

  factory AnalyticsProductModel.fromMap(Map<dynamic, dynamic> map) {
    final rawDate = map['date'];
    final DateTime parsedDate = switch (rawDate) {
      int v => DateTime.fromMillisecondsSinceEpoch(v),
      DateTime v => v,
      _ => DateTime.now(),
    };

    return AnalyticsProductModel(
      productName: (map['productName'] ?? map['title'] ?? '') as String,
      date: parsedDate,
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : 0,
    );
  }
}
