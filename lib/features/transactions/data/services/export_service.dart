import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Rect;

import 'package:intl/intl.dart';
import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/features/transactions/domain/entities/history_expense.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// В выбранном месяце нет операций.
class ExportEmptyException implements Exception {
  const ExportEmptyException();
}

class ExportService {
  ExportService._();

  /// Экспорт месяца в CSV (UTF-8 с BOM, разделитель «;», открывается в Excel).
  static Future<void> exportMonthToCSV(
    List<HistoryExpense> records,
    List<CustomCategory> categories,
    int month,
    int year,
    AppLocalizations loc, {
    Rect? sharePositionOrigin,
  }) async {
    final monthRecords = records
        .where((r) => r.date.month == month && r.date.year == year)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (monthRecords.isEmpty) throw const ExportEmptyException();

    final byId = {for (final c in categories) c.id: c};
    // Сумма в формате локали (12,50 для uk/ru), иначе Excel читает дату.
    final amountFormat = NumberFormat('0.00', loc.localeName);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    final buffer = StringBuffer()
      ..writeln(
        [
          loc.exportColId,
          loc.exportColDate,
          loc.exportColName,
          loc.exportColCategory,
          loc.exportColAmount,
          loc.exportColType,
        ].map(_cell).join(';'),
      );

    for (final r in monthRecords) {
      final category =
          byId[r.category]?.localizedName(loc) ?? loc.exportNoCategory;
      final type = switch (r.type) {
        'income' => loc.incomeType,
        'transfer' => loc.transfer,
        _ => loc.expense,
      };

      buffer.writeln(
        [
          _cell(r.id),
          _cell(dateFormat.format(r.date)),
          _cell(r.productName),
          _cell(category),
          amountFormat.format(r.price),
          _cell(type),
        ].join(';'),
      );
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/lumina_report_${year}_${month.toString().padLeft(2, '0')}.csv';
    await File(path).writeAsBytes([
      0xEF,
      0xBB,
      0xBF,
      ...utf8.encode(buffer.toString()),
    ]);

    await Share.shareXFiles(
      [XFile(path, mimeType: 'text/csv')],
      text: loc.exportShareText('$month', '$year'),
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Экранирование: кавычки удваиваются, переводы строк убираются, а значения,
  /// начинающиеся с `= + - @`, нейтрализуются (защита от CSV-инъекции формул).
  static String _cell(String value) {
    var s = value.replaceAll(RegExp(r'[\r\n]+'), ' ');
    if (s.isNotEmpty && '=+-@\t'.contains(s[0])) s = "'$s";
    return '"${s.replaceAll('"', '""')}"';
  }
}
