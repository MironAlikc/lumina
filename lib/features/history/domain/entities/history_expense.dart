class HistoryExpense {
  final String id;
  final DateTime date;
  final String productName;
  final double price; // Имя совпадает с моделью
  final String category;
  final String type;
  final bool isSynced;

  const HistoryExpense({
    required this.id,
    required this.date,
    required this.productName,
    required this.price,
    required this.category,
    required this.type,
    this.isSynced = false,
  });
}
