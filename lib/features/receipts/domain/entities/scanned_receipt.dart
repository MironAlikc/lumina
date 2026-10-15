import 'package:flutter/foundation.dart';

enum ScannedReceiptSource { ocr, qr, unknown }

@immutable
class ScannedLine {
  const ScannedLine({
    required this.name,
    required this.price,
    this.barcode,
    this.suggestedCategoryId,
  });

  final String name;
  final double price;
  final String? barcode;

  /// Подсказка категории. null: определить не удалось.
  final String? suggestedCategoryId;

  double get amount => price;

  ScannedLine copyWith({
    String? name,
    double? price,
    String? barcode,
    String? suggestedCategoryId,
  }) {
    return ScannedLine(
      name: name ?? this.name,
      price: price ?? this.price,
      barcode: barcode ?? this.barcode,
      suggestedCategoryId: suggestedCategoryId ?? this.suggestedCategoryId,
    );
  }
}

@immutable
class ScannedReceipt {
  const ScannedReceipt({
    required this.rawText,
    required this.date,
    required this.source,
    this.merchant = '',
    this.total,
    this.lines = const [],
  });

  final String rawText;
  final DateTime date;
  final ScannedReceiptSource source;
  final String merchant;
  final double? total;
  final List<ScannedLine> lines;

  /// Итог чека; если он не распознан, сумма позиций (с округлением до копеек).
  double get amount {
    final t = total;
    if (t != null && t > 0) return t;
    final sum = lines.fold<double>(0, (s, e) => s + e.price);
    return (sum * 100).round() / 100;
  }

  ScannedReceipt copyWith({
    String? rawText,
    DateTime? date,
    ScannedReceiptSource? source,
    String? merchant,
    double? total,
    List<ScannedLine>? lines,
  }) {
    return ScannedReceipt(
      rawText: rawText ?? this.rawText,
      date: date ?? this.date,
      source: source ?? this.source,
      merchant: merchant ?? this.merchant,
      total: total ?? this.total,
      lines: lines ?? this.lines,
    );
  }
}
