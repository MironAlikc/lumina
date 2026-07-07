class AnalyticsState {
  final String searchQuery;
  final Map<String, double> categoryData;
  final double totalSpent;
  final String insightMessage;
  final bool isLoading;
  final String? errorMessage;

  const AnalyticsState({
    this.searchQuery = '',
    this.categoryData = const {},
    this.totalSpent = 0.0,
    this.insightMessage = 'Добавьте больше расходов для анализа.',
    this.isLoading = false,
    this.errorMessage,
  });

  AnalyticsState copyWith({
    String? searchQuery,
    Map<String, double>? categoryData,
    double? totalSpent,
    String? insightMessage,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AnalyticsState(
      searchQuery: searchQuery ?? this.searchQuery,
      categoryData: categoryData ?? this.categoryData,
      totalSpent: totalSpent ?? this.totalSpent,
      insightMessage: insightMessage ?? this.insightMessage,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
