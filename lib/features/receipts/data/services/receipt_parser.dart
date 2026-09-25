import 'package:lumina/features/receipts/domain/entities/scanned_receipt.dart';

class ReceiptParser {
  static const _totalHints = [
    'до сплати',
    'до оплаты',
    'разом',
    'всего',
    'ітого',
    'итого',
    'сума',
    'сумма',
    'total',
    'amount',
    'grand total',
  ];

  static final _dateRe = RegExp(r'(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})');

  static final _moneyRe = RegExp(
    r'(?<!\d)(\d{1,3}(?:[ \u00A0]\d{3})+|\d+)([.,]\d{2})?(?!\d)',
  );

  static ScannedReceipt parse(String raw) {
    final text = raw.replaceAll('\u00A0', ' ').trim();
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return ScannedReceipt(
      merchant: _merchant(lines),
      amount: _amount(text, lines),
      date: _date(text) ?? DateTime.now(),
      rawText: text,
    );
  }

  static String _merchant(List<String> lines) {
    for (final line in lines.take(8)) {
      final lower = line.toLowerCase();
      if (line.length < 3) continue;
      if (_moneyRe.hasMatch(line) && line.length < 12) continue;
      if (lower.contains('чек') ||
          lower.contains('фіскаль') ||
          lower.contains('фискал') ||
          lower.contains('пн') ||
          lower.contains('fn') ||
          lower.contains('кассир') ||
          lower.contains('каса')) {
        continue;
      }
      return line;
    }
    return '';
  }

  static double _amount(String text, List<String> lines) {
    final lower = text.toLowerCase();

    for (final hint in _totalHints) {
      final idx = lower.lastIndexOf(hint);
      if (idx < 0) continue;
      final window = text.substring(idx, text.length.clamp(0, idx + 80));
      final value = _lastMoney(window);
      if (value != null && value > 0) return value;
    }

    double? best;
    for (final line in lines.reversed.take(12)) {
      final value = _lastMoney(line);
      if (value == null) continue;
      if (best == null || value > best) best = value;
    }
    return best ?? 0;
  }

  static double? _lastMoney(String input) {
    final matches = _moneyRe.allMatches(input).toList();
    if (matches.isEmpty) return null;
    return _toDouble(matches.last.group(0)!);
  }

  static double? _toDouble(String raw) {
    var s = raw.replaceAll(RegExp(r'[ \u00A0]'), '');
    if (s.contains(',') && s.contains('.')) {
      s = s.replaceAll(',', '');
    } else {
      s = s.replaceAll(',', '.');
    }
    return double.tryParse(s);
  }

  static DateTime? _date(String text) {
    final m = _dateRe.firstMatch(text);
    if (m == null) return null;
    final d = int.tryParse(m.group(1)!) ?? 0;
    final mo = int.tryParse(m.group(2)!) ?? 0;
    var y = int.tryParse(m.group(3)!) ?? 0;
    if (y < 100) y += 2000;
    if (d < 1 || d > 31 || mo < 1 || mo > 12) return null;
    return DateTime(y, mo, d);
  }
}
