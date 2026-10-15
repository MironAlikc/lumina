import 'package:lumina/features/receipts/data/services/receipt_parser.dart';
import 'package:lumina/features/receipts/domain/entities/scanned_receipt.dart';

/// Разбор фискального QR. Ссылка только читается: сеть не используется,
/// данные чека остаются на устройстве.
class FiscalQrService {
  FiscalQrService._();

  static const _maxAmount = 10000000.0;

  static bool looksLikeFiscal(String raw) {
    final v = raw.toLowerCase();
    return v.contains('cabinet.tax.gov.ua') ||
        v.contains('cashregs/check') ||
        v.contains('check.checkbox') ||
        (v.contains('fn=') && (v.contains('sm=') || v.contains('sum=')));
  }

  /// Возвращает null, если это не фискальный QR или в нём нет суммы
  static ScannedReceipt? parse(String raw) {
    final trimmed = raw.trim();
    if (!looksLikeFiscal(trimmed)) return null;

    final Uri uri;
    try {
      uri = Uri.parse(trimmed);
    } catch (_) {
      return null;
    }

    final params = {
      for (final e in uri.queryParameters.entries) e.key.toLowerCase(): e.value,
    };

    final amount = ReceiptParser.parseAmount(
        params['sm'] ?? params['sum'] ?? params['s'] ?? '');
    if (amount == null || amount <= 0 || amount > _maxAmount) return null;

    final date = _parseDate(params['date'], params['time']) ?? DateTime.now();

    // Название магазина в QR отсутствует (fn - номер кассового аппарата),
    // позиций тоже нет: экран подтверждения покажет сумму и дату.
    return ScannedReceipt(
      total: amount,
      date: date,
      rawText: trimmed,
      source: ScannedReceiptSource.qr,
    );
  }

  static DateTime? _parseDate(String? dateRaw, String? timeRaw) {
    if (dateRaw == null || dateRaw.isEmpty) return null;
    final digits = dateRaw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return null;

    final y = int.tryParse(digits.substring(0, 4));
    final m = int.tryParse(digits.substring(4, 6));
    final d = int.tryParse(digits.substring(6, 8));
    if (y == null || m == null || d == null) return null;

    var hour = 0;
    var minute = 0;
    if (timeRaw != null) {
      final t = timeRaw.replaceAll(RegExp(r'\D'), '');
      if (t.length >= 4) {
        hour = int.tryParse(t.substring(0, 2)) ?? 0;
        minute = int.tryParse(t.substring(2, 4)) ?? 0;
      }
    }
    return ReceiptParser.buildDate(y, m, d, hour, minute);
  }
}
