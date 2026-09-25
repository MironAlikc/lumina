import 'package:lumina/features/receipts/domain/entities/scanned_receipt.dart';

class FiscalQrService {
  static bool looksLikeFiscal(String raw) {
    final v = raw.toLowerCase();
    return v.contains('cabinet.tax.gov.ua') ||
        v.contains('cashregs/check') ||
        (v.contains('fn=') && v.contains('sm='));
  }

  static ScannedReceipt? parse(String raw) {
    Uri? uri;
    try {
      uri = Uri.parse(raw.trim());
    } catch (_) {
      return null;
    }
    if (!looksLikeFiscal(raw)) return null;

    final sm = uri.queryParameters['sm'] ?? uri.queryParameters['sum'];
    final dateRaw = uri.queryParameters['date'];
    final timeRaw = uri.queryParameters['time'];
    final fn = uri.queryParameters['fn'] ?? '';

    final amount = double.tryParse((sm ?? '0').replaceAll(',', '.')) ?? 0;
    final date = _parseDate(dateRaw, timeRaw) ?? DateTime.now();

    return ScannedReceipt(
      merchant: fn.isEmpty ? '' : 'ФН $fn',
      amount: amount,
      date: date,
      rawText: raw,
      source: ScannedReceiptSource.fiscalQr,
    );
  }

  static DateTime? _parseDate(String? dateRaw, String? timeRaw) {
    if (dateRaw == null || dateRaw.length < 8) return null;
    final y = int.tryParse(dateRaw.substring(0, 4));
    final m = int.tryParse(dateRaw.substring(4, 6));
    final d = int.tryParse(dateRaw.substring(6, 8));
    if (y == null || m == null || d == null) return null;
    var hour = 0;
    var minute = 0;
    if (timeRaw != null && timeRaw.length >= 4) {
      hour = int.tryParse(timeRaw.substring(0, 2)) ?? 0;
      minute = int.tryParse(timeRaw.substring(2, 4)) ?? 0;
    }
    return DateTime(y, m, d, hour, minute);
  }
}
