import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:lumina/features/analytics/data/models/analytics_daily_point.dart';
import 'package:lumina/features/transactions/data/models/history_expense_model.dart';

@immutable
class AnalyticsSlice extends Equatable {
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

  @override
  List<Object?> get props => [categoryId, name, amount, colorHex];
}

@immutable
class AnalyticsState extends Equatable {
  const AnalyticsState({
    required this.selectedDate,
    this.slices = const [],
    this.dailyPoints = const [],
    this.monthExpenses = const [],
    this.totalSpent = 0,
    this.previousMonthTotal,
    this.insightMessage = '',
    this.isLoading = false,
    this.errorMessage,
    this.isLineChartMode = false,
  });

  factory AnalyticsState.initial() {
    final now = DateTime.now();
    return AnalyticsState(
      selectedDate: DateTime(now.year, now.month),
      isLoading: true,
    );
  }

  final List<AnalyticsSlice> slices;
  final List<AnalyticsDailyPoint> dailyPoints;
  final List<HistoryExpenseModel> monthExpenses;
  final double totalSpent;
  final double? previousMonthTotal;
  final String insightMessage;
  final DateTime selectedDate;
  final bool isLoading;
  final String? errorMessage;
  final bool isLineChartMode;

  AnalyticsState copyWith({
    List<AnalyticsSlice>? slices,
    List<AnalyticsDailyPoint>? dailyPoints,
    List<HistoryExpenseModel>? monthExpenses,
    double? totalSpent,
    double? previousMonthTotal,
    bool clearPreviousMonthTotal = false,
    String? insightMessage,
    DateTime? selectedDate,
    bool? isLoading,
    String? errorMessage,
    bool? isLineChartMode,
    bool clearError = false,
  }) {
    return AnalyticsState(
      slices: slices ?? this.slices,
      dailyPoints: dailyPoints ?? this.dailyPoints,
      monthExpenses: monthExpenses ?? this.monthExpenses,
      totalSpent: totalSpent ?? this.totalSpent,
      previousMonthTotal: clearPreviousMonthTotal
          ? null
          : (previousMonthTotal ?? this.previousMonthTotal),
      insightMessage: insightMessage ?? this.insightMessage,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLineChartMode: isLineChartMode ?? this.isLineChartMode,
    );
  }

  @override
  List<Object?> get props => [
    slices,
    dailyPoints,
    monthExpenses,
    totalSpent,
    previousMonthTotal,
    insightMessage,
    selectedDate,
    isLoading,
    errorMessage,
    isLineChartMode,
  ];
}
