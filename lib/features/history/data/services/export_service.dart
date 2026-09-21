import 'dart:convert';
import 'dart:io';

import 'package:lumina/features/history/data/models/custom_category_model.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static Future<void> exportMonthToCSV(
    List<HistoryExpenseModel> records,
    List<CustomCategory> categories,
    int month,
    int year,
    AppLocalizations loc,
  ) async {
    final monthRecords = records
        .where((r) => r.date.month == month && r.date.year == year)
        .toList();

    final buffer = StringBuffer();
    buffer.writeln(
      '${loc.exportColId};${loc.exportColDate};${loc.exportColName};${loc.exportColCategory};${loc.exportColAmount};${loc.exportColType}',
    );

    for (final r in monthRecords) {
      final category = categories.cast<CustomCategory?>().firstWhere(
        (c) => c!.id == r.categoryId,
        orElse: () => null,
      );
      final categoryName = category?.localizedName(loc) ?? loc.exportNoCategory;
      final dateStr =
          '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}';
      final typeStr = r.isIncome ? loc.incomeType : loc.expense;

      buffer.writeln(
        '"${_esc(r.id)}";"$dateStr";"${_esc(r.productName)}";"${_esc(categoryName)}";${r.price};"${_esc(typeStr)}"',
      );
    }

    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/lumina_report_${year}_${month.toString().padLeft(2, '0')}.csv';
    final file = File(path);
    await file.writeAsBytes([
      0xEF,
      0xBB,
      0xBF,
      ...utf8.encode(buffer.toString()),
    ]);

    // Миграция с deprecated Share.shareXFiles на новый API SharePlus.instance.share,
    // который принимает единый объект ShareParams вместо позиционных аргументов.
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text: loc.exportShareText('$month', '$year'),
      ),
    );
  }

  static String _esc(String value) => value.replaceAll('"', '""');
}
