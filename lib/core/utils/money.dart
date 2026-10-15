import 'package:intl/intl.dart';

/// Работа с денежными значениями: округление до копеек, разбор ввода
/// и единое форматирование.
abstract final class Money {
  static final _formats = <String, NumberFormat>{};

  /// NumberFormat дорого создавать, а в списке сумм вызывается на каждую строку.
  static NumberFormat _format(String locale, int digits) =>
      _formats.putIfAbsent(
        '$locale/$digits',
        () => NumberFormat.decimalPatternDigits(
          locale: locale,
          decimalDigits: digits,
        ),
      );

  static double round2(double v) => (v * 100).round() / 100;

  /// Разбирает «1234.5», «1 234,50», «1.234,50». null для некорректной строки.
  static double? parse(String raw) {
    var s = raw.replaceAll(RegExp(r'[\s\u00a0]'), '');
    if (s.isEmpty) return null;

    final lastComma = s.lastIndexOf(',');
    final lastDot = s.lastIndexOf('.');

    if (lastComma >= 0 && lastDot >= 0) {
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
      s = s.replaceAll('.', '');
    }

    final value = double.tryParse(s);
    if (value == null || value.isNaN || value.isInfinite) return null;
    return round2(value);
  }

  /// Копейки показываются только если они есть.
  static String format(double value, String locale, {String? symbol}) {
    final hasFraction = (value * 100).round() % 100 != 0;
    final text = _format(locale, hasFraction ? 2 : 0).format(value);
    return symbol == null ? text : '$text $symbol';
  }

  /// Значение для текстового поля: без лишних нулей.
  static String forInput(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}
