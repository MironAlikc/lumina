class HistoryExpenseModel {
  final String id;
  final DateTime date;
  final String productName;
  final double price;

  HistoryExpenseModel({
    required this.id,
    required this.date,
    required this.productName,
    required this.price,
  });

  factory HistoryExpenseModel.fromMap(Map<dynamic, dynamic> map) {
    return HistoryExpenseModel(
      id: map['id'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      productName: map['productName'] as String,
      // ИСПРАВЛЕНО: Безопасное приведение к double с помощью num.toDouble()
      price: (map['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.millisecondsSinceEpoch,
    'productName': productName,
    'price': price,
  };
}
