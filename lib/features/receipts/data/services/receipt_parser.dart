import 'package:lumina/features/receipts/data/services/receipt_categorizer.dart';
import 'package:lumina/features/receipts/domain/entities/scanned_receipt.dart';

class ReceiptParser {
  const ReceiptParser();

  // ---------------------------------------------------------------- regexes

  /// Цена в конце строки с необязательной налоговой литерой (А, Б, В, Г).
  static final _priceRe = RegExp(
    r'(\d{1,3}(?:[ \u00a0]\d{3})+[.,]\d{2}|\d+[.,]\d{2})\s*[АБВГA-D]?\s*$',
    caseSensitive: false,
  );
  static final _anyPriceRe = RegExp(r'\d+[.,]\d{2}');

  /// Строка количества: «2 x 15.00», «0.350 кг x 80.00».
  static final _qtyRe = RegExp(
    r'^\s*(\d+(?:[.,]\d+)?)\s*(?:шт|кг|г|л|уп)?\.?\s*[xх×*]\s*\d+[.,]\d{2}',
    caseSensitive: false,
  );
  static final _trailingQtyRe = RegExp(
    r'\s*\d+(?:[.,]\d+)?\s*(?:шт|кг|г|л|уп)?\.?\s*[xх×*]\s*\d+[.,]\d{2}\s*[=\-]?\s*$',
    caseSensitive: false,
  );

  static final _itemStartRe = RegExp(r'^(\d{1,3})\s+(.+)$');
  static final _barcodeRe = RegExp(
    r'(?:штрих\s*код|barcode)\s*[:\s]*(\d{8,14})',
    caseSensitive: false,
  );
  static final _totalRe = RegExp(
    r'(?:до\s*сплати|сума|сумма|итого|разом|всього|total)\s*:?\s*'
    r'(\d+(?:[ \u00a0]\d{3})*[.,]\d{2})',
    caseSensitive: false,
  );
  static final _payableRe = RegExp(
    r'до\s*сплати\s*:?\s*(\d+(?:[ \u00a0]\d{3})*[.,]\d{2})',
    caseSensitive: false,
  );
  static final _dmyRe = RegExp(
    r'(?<!\d)(\d{1,2})[./](\d{1,2})[./](\d{4}|\d{2})(?!\d)'
    r'(?:\s+(\d{1,2}):(\d{2})(?::(\d{2}))?)?',
  );
  static final _isoRe = RegExp(
    r'(?<!\d)(\d{4})-(\d{2})-(\d{2})(?!\d)'
    r'(?:[ T]+(\d{1,2}):(\d{2})(?::(\d{2}))?)?',
  );
  static final _merchantRe = RegExp(
    r'(?:^|[\s"«“])(?:тов|тзов|фоп|пп|пат|ат)(?=[\s"»”]|$)'
    r'|маркет|магазин|атб|сільпо|silpo|novus|varus|фора|ашан',
    caseSensitive: false,
  );
  static final _chequePrefixRe = RegExp(
    r'^чек\s*№?\s*\d+\s*',
    caseSensitive: false,
  );

  /// Служебные строки: позициями не считаются.
  static const _skipNeedles = [
    'штрих код',
    'знижка',
    'скидка',
    'ціна кг',
    'цена кг',
    'ідент',
    'термінал',
    'комісія',
    'платіжна',
    'вид операції',
    'епз',
    'код авт',
    'rrn',
    'пдв',
    'ндс',
    'ідентифіковано',
    'каса',
    'безготівкова',
  ];

  /// Строки с цифрами, которые не являются товарами (для позиций без номера).
  static const _stopNeedles = [
    'сума',
    'сумма',
    'разом',
    'итого',
    'всього',
    'до сплати',
    'готівк',
    'наличн',
    'картк',
    'карта',
    'решта',
    'сдача',
    'оплат',
    'сплачено',
    'податок',
    'округл',
    'заокр',
    'бонус',
    'дата',
    'чек',
    'фн ',
    'пн ',
  ];

  // ----------------------------------------------------------------- public

  static ScannedReceipt parse(
    String raw, {
    ScannedReceiptSource source = ScannedReceiptSource.ocr,
  }) {
    final lines = raw
        .split(RegExp(r'\r?\n'))
        .map((e) => e.replaceAll('\u00a0', ' ').trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return ScannedReceipt(
      rawText: raw,
      date: _findDate(lines) ?? DateTime.now(),
      source: source,
      merchant: _findMerchant(lines),
      total: _findTotal(lines),
      lines: _parseItems(lines),
    );
  }

  /// Разбирает сумму в разных форматах: «1234.5», «1 234,50», «1.234,50».
  /// Возвращает null для нечисловой строки.
  static double? parseAmount(String raw) {
    var s = raw.replaceAll(RegExp(r'[\s\u00a0]'), '');
    if (s.isEmpty) return null;

    final lastComma = s.lastIndexOf(',');
    final lastDot = s.lastIndexOf('.');

    if (lastComma >= 0 && lastDot >= 0) {
      // Десятичный разделитель - тот, что стоит правее.
      s = lastComma > lastDot
          ? s.replaceAll('.', '').replaceAll(',', '.')
          : s.replaceAll(',', '');
    } else if (lastComma >= 0) {
      final single = s.indexOf(',') == lastComma;
      final digitsAfter = s.length - lastComma - 1;
      s = single && digitsAfter <= 2
          ? s.replaceAll(',', '.')
          : s.replaceAll(',', '');
    } else if (lastDot >= 0 && s.indexOf('.') != lastDot) {
      s = s.replaceAll('.', ''); // «1.234.567»
    }

    final value = double.tryParse(s);
    if (value == null || value.isNaN || value.isInfinite) return null;
    return (value * 100).round() / 100;
  }

  /// Собирает дату, отвергая невозможные значения (35.13.2024, год 2090).
  static DateTime? buildDate(
    int year,
    int month,
    int day, [
    int hour = 0,
    int minute = 0,
    int second = 0,
  ]) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (hour > 23 || minute > 59 || second > 59) return null;

    final result = DateTime(year, month, day, hour, minute, second);
    if (result.month != month || result.day != day) return null;

    final limit = DateTime.now().add(const Duration(days: 1));
    if (year < 2000 || result.isAfter(limit)) return null;
    return result;
  }

  // ---------------------------------------------------------------- helpers

  static String _findMerchant(List<String> lines) {
    for (final line in lines.take(8)) {
      if (!_merchantRe.hasMatch(line)) continue;
      final cleaned = line.replaceFirst(_chequePrefixRe, '').trim();
      if (cleaned.isNotEmpty) return cleaned;
    }
    return '';
  }

  static DateTime? _findDate(List<String> lines) {
    // Дата обычно в нижней части чека.
    for (final line in lines.reversed) {
      final iso = _isoRe.firstMatch(line);
      if (iso != null) {
        final date = buildDate(
          int.parse(iso.group(1)!),
          int.parse(iso.group(2)!),
          int.parse(iso.group(3)!),
          int.tryParse(iso.group(4) ?? '') ?? 0,
          int.tryParse(iso.group(5) ?? '') ?? 0,
          int.tryParse(iso.group(6) ?? '') ?? 0,
        );
        if (date != null) return date;
      }

      final dmy = _dmyRe.firstMatch(line);
      if (dmy != null) {
        var year = int.parse(dmy.group(3)!);
        if (year < 100) year += 2000;
        final date = buildDate(
          year,
          int.parse(dmy.group(2)!),
          int.parse(dmy.group(1)!),
          int.tryParse(dmy.group(4) ?? '') ?? 0,
          int.tryParse(dmy.group(5) ?? '') ?? 0,
          int.tryParse(dmy.group(6) ?? '') ?? 0,
        );
        if (date != null) return date;
      }
    }
    return null;
  }

  static String _normalizeForTotal(String lower) =>
      lower.replaceAll(RegExp(r'грн\.?'), '');

  static bool _isTotalLine(String lower) =>
      _totalRe.hasMatch(_normalizeForTotal(lower));

  static double? _findTotal(List<String> lines) {
    double? total;
    double? payable;
    for (final line in lines) {
      final lower = _normalizeForTotal(line.toLowerCase());
      final p = _payableRe.firstMatch(lower);
      if (p != null) payable = parseAmount(p.group(1)!);
      final m = _totalRe.firstMatch(lower);
      if (m != null) total = parseAmount(m.group(1)!);
    }
    final result = payable ?? total;
    return result != null && result > 0 ? result : null;
  }

  static String _cleanName(String raw) {
    return raw
        .replaceFirst(_trailingQtyRe, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[\s=]+$'), '')
        .trim();
  }

  static bool _hasLetters(String s) =>
      RegExp(r'\p{L}', unicode: true).hasMatch(s);

  static bool _isMeta(String lower) {
    return lower.contains('грн') ||
        lower.contains('сума') ||
        lower.contains('пн ') ||
        lower.contains('дата') ||
        lower.startsWith('тов');
  }

  static List<ScannedLine> _parseItems(List<String> lines) {
    final items = <ScannedLine>[];
    String? pendingName;
    String? pendingBarcode;
    var continuation = 0;

    void flush(String name, double price) {
      final clean = _cleanName(name);
      if (clean.isEmpty || price <= 0) return;
      items.add(
        ScannedLine(
          name: clean,
          price: price,
          barcode: pendingBarcode,
          suggestedCategoryId: ReceiptCategorizer.suggest(clean),
        ),
      );
      pendingBarcode = null;
    }

    for (final line in lines) {
      final lower = line.toLowerCase();

      final bar = _barcodeRe.firstMatch(lower);
      if (bar != null) {
        pendingBarcode = bar.group(1);
        continue;
      }

      // Дальше начинается итог и оплата: позиций больше нет.
      if (_isTotalLine(lower)) {
        if (items.isNotEmpty) break;
        continue;
      }

      final isItemStart = _itemStartRe.hasMatch(line);
      final isSkip = _skipNeedles.any(lower.contains);
      if (isSkip && !isItemStart) {
        if (lower.contains('знижка') || lower.contains('скидка')) {
          final m = _priceRe.firstMatch(
            line.replaceAll('−', '-').replaceAll('–', '-'),
          );
          if (m != null && items.isNotEmpty) {
            final discount = parseAmount(m.group(1)!) ?? 0;
            final last = items.removeLast();
            final next = (last.price - discount).clamp(0, last.price);
            items.add(last.copyWith(price: next.toDouble()));
          }
        }
        continue;
      }

      // Строка количества относится к предыдущему названию.
      final qty = _qtyRe.firstMatch(line);
      if (qty != null && pendingName != null) {
        final prices = _anyPriceRe.allMatches(line).toList();
        if (prices.isNotEmpty) {
          final last = parseAmount(prices.last.group(0)!) ?? 0;
          var price = last;
          if (prices.length == 1) {
            final count = parseAmount(qty.group(1)!) ?? 1;
            price = (last * count * 100).round() / 100;
          }
          flush(pendingName, price);
          pendingName = null;
          continue;
        }
      }

      final start = _itemStartRe.firstMatch(line);
      if (start != null && qty == null) {
        final rest = start.group(2)!.trim();
        final restPrice = _priceRe.firstMatch(rest);
        if (restPrice != null) {
          flush(
            rest.substring(0, restPrice.start),
            parseAmount(restPrice.group(1)!) ?? 0,
          );
          pendingName = null;
        } else {
          pendingName = rest;
          continuation = 0;
        }
        continue;
      }

      final priceMatch = _priceRe.firstMatch(line);

      if (pendingName != null) {
        if (priceMatch != null) {
          flush(pendingName, parseAmount(priceMatch.group(1)!) ?? 0);
          pendingName = null;
        } else if (!_isMeta(lower) && continuation < 2) {
          pendingName = '$pendingName $line';
          continuation++;
        }
        continue;
      }

      // Позиция без номера: «Хліб білий  25.00 А».
      if (priceMatch != null && !_stopNeedles.any(lower.contains)) {
        final name = line.substring(0, priceMatch.start);
        if (_hasLetters(name)) {
          flush(name, parseAmount(priceMatch.group(1)!) ?? 0);
        }
      }
    }

    return items;
  }
}
