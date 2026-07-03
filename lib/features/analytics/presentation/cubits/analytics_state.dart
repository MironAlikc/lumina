import '../../data/repositories/analytics_repository.dart';

class AnalyticsState {
  final String searchQuery;
  final Map<String, double> categoryData; // Данные для круговой диаграммы
  final double totalSpent;
  final String insightMessage; // Умная аналитика

  AnalyticsState({
    required this.searchQuery,
    required this.categoryData,
    required this.totalSpent,
    required this.insightMessage,
  });

  AnalyticsState copyWith({
    String? searchQuery,
    Map<String, double>? categoryData,
    double? totalSpent,
    String? insightMessage,
  }) {
    return AnalyticsState(
      searchQuery: searchQuery ?? this.searchQuery,
      categoryData: categoryData ?? this.categoryData,
      totalSpent: totalSpent ?? this.totalSpent,
      insightMessage: insightMessage ?? this.insightMessage,
    );
  }
}
