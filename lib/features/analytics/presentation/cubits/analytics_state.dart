import 'package:flutter/foundation.dart';

@immutable
class AnalyticsState {
  final Map<String, double> categoryData;
  final double totalSpent;
  final String insightMessage;
  final DateTime selectedDate;
  final bool isLoading;
  final String? errorMessage;

  const AnalyticsState({
    this.categoryData = const {},
    this.totalSpent = 0.0,
    this.insightMessage = '',
    required this.selectedDate,
    this.isLoading = false,
    this.errorMessage,
  });

  AnalyticsState copyWith({
    Map<String, double>? categoryData,
    double? totalSpent,
    String? insightMessage,
    DateTime? selectedDate,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AnalyticsState(
      categoryData: categoryData ?? this.categoryData,
      totalSpent: totalSpent ?? this.totalSpent,
      insightMessage: insightMessage ?? this.insightMessage,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
