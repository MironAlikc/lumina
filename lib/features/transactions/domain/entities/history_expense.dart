class HistoryExpense {
  final String id;
  final DateTime date;
  final String productName;
  final double price;
  final bool isSynced;
  final String category;
  final String type; // 'income' или 'expense'

  const HistoryExpense({
    required this.id,
    required this.date,
    required this.productName,
    required this.price,
    required this.isSynced,
    required this.category,
    required this.type,
  });

  bool get isIncome => type == 'income';
}
