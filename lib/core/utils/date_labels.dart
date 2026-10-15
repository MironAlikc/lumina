import 'package:intl/intl.dart';

abstract final class DateLabels {
  static String capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  /// «Октябрь 2026». Паттерн LLLL y даёт именительный падеж без «г.».
  static String monthYear(String locale, DateTime date) =>
      capitalize(DateFormat('LLLL y', locale).format(date));

  /// «Октябрь».
  static String month(String locale, int month) =>
      capitalize(DateFormat('LLLL', locale).format(DateTime(2000, month)));
}
