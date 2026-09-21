import 'package:flutter/foundation.dart';

@immutable
class AnalyticsSlice {
  const AnalyticsSlice({
    required this.categoryId,
    required this.name,
    required this.amount,
    required this.colorHex,
  });

  final String categoryId;
  final String name;
  final double amount;
  final int colorHex;

  double percentOf(double total) => total > 0 ? amount / total * 100 : 0;
}

@immutable
class AnalyticsState {
  const AnalyticsState({
    this.slices = const [],
    this.totalSpent = 0.0,
    this.insightMessage = '',
    required this.selectedDate,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<AnalyticsSlice> slices;
  final double totalSpent;
  final String insightMessage;
  final DateTime selectedDate;
  final bool isLoading;
  final String? errorMessage;

  AnalyticsState copyWith({
    List<AnalyticsSlice>? slices,
    double? totalSpent,
    String? insightMessage,
    DateTime? selectedDate,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AnalyticsState(
      slices: slices ?? this.slices,
      totalSpent: totalSpent ?? this.totalSpent,
      insightMessage: insightMessage ?? this.insightMessage,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
