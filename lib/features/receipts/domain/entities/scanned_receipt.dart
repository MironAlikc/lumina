import 'package:flutter/foundation.dart';

@immutable
class ScannedLine {
  const ScannedLine({required this.name, required this.amount});

  final String name;
  final double amount;
}

@immutable
class ScannedReceipt {
  const ScannedReceipt({
    required this.merchant,
    required this.amount,
    required this.date,
    this.rawText = '',
    this.lines = const [],
    this.source = ScannedReceiptSource.ocr,
  });

  final String merchant;
  final double amount;
  final DateTime date;
  final String rawText;
  final List<ScannedLine> lines;
  final ScannedReceiptSource source;

  ScannedReceipt copyWith({String? merchant, double? amount, DateTime? date}) {
    return ScannedReceipt(
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      rawText: rawText,
      lines: lines,
      source: source,
    );
  }
}

enum ScannedReceiptSource { ocr, fiscalQr }
