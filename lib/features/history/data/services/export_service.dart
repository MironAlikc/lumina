import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/history_expense_model.dart';

class ExportService {
  /// Экспортирует записи за выбранный месяц в CSV-файл и открывает меню «Поделиться»
  static Future<void> exportMonthToCSV(
    List<HistoryExpenseModel> records,
    List<dynamic> categories,
    int month,
    int year,
  ) async {
    // 1. Фильтруем записи за нужный месяц и год
    final monthRecords = records.where((r) {
      return r.date.month == month && r.date.year == year;
    }).toList();

    // 2. Создаем структуру CSV-документа
    final buffer = StringBuffer();
    // Заголовки (используем ';' для корректного открытия в Excel)
    buffer.writeln('ID;Дата;Название;Категория;Сумма;Тип');

    for (var r in monthRecords) {
      // Безопасный поиск названия категории
      String categoryName = 'Без категории';
      try {
        final category = categories.firstWhere(
          (c) => c != null && c.id == r.categoryId,
        );
        if (category != null) {
          categoryName = category.name ?? 'Без категории';
        }
      } catch (_) {
        categoryName = 'Без категории';
      }

      // Форматируем дату в читаемый вид (YYYY-MM-DD)
      final dateStr =
          '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}';

      // Определяем текстовый тип транзакции
      final typeStr = r.isIncome ? 'Доход' : 'Расход';

      // Экранируем возможные кавычки в названии, чтобы не ломать CSV структуру
      final safeProductName = r.productName.replaceAll('"', '""');
      final safeCategoryName = categoryName.replaceAll('"', '""');

      buffer.writeln(
        '"${r.id}";"$dateStr";"$safeProductName";"$safeCategoryName";${r.price};"$typeStr"',
      );
    }

    // 3. Сохраняем файл во временную директорию устройства
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/lumina_report_${year}_${month.toString().padLeft(2, '0')}.csv';
    final file = File(path);

    // 4. Записываем байты с BOM (UTF-8 with BOM), чтобы Excel корректно отображал кириллицу
    await file.writeAsBytes([0xEF, 0xBB, 0xBF, ...buffer.toString().codeUnits]);

    // 5. Вызываем системное диалоговое окно «Поделиться / Сохранить файл»
    await Share.shareXFiles([
      XFile(path),
    ], text: 'Финансовый отчет за $month.$year из приложения Lumina 📊');
  }
}
