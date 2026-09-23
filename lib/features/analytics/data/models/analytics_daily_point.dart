import 'package:flutter/foundation.dart';

@immutable
class AnalyticsDailyPoint {
  const AnalyticsDailyPoint({required this.day, required this.amount});

  final int day;
  final double amount;
}
