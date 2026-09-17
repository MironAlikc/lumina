import 'package:flutter/foundation.dart';

@immutable
class AnalyticsProductModel {
  final String productName;
  final DateTime date;
  final double price;

  const AnalyticsProductModel({
    required this.productName,
    required this.date,
    required this.price,
  });

  factory AnalyticsProductModel.fromMap(Map<dynamic, dynamic> map) {
    final rawDate = map['date'];
    DateTime parsedDate;

    if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else {
      parsedDate = DateTime.now();
    }

    return AnalyticsProductModel(
      productName: (map['productName'] ?? map['title'] ?? '') as String,
      date: parsedDate,
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : 0.0,
    );
  }
}
