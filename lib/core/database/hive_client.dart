import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lumina/features/history/data/models/history_expense_model.dart';

class HiveClient {
  /// Транзакции. Сюда нельзя класть язык/валюту/лимит.
  static const String boxName = 'history_box';

  /// Язык, валюта, месячный лимит.
  static const String settingsBox = 'settings_box';

  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HistoryExpenseModelAdapter());
    }

    await _openHistoryBox();
    await _openUntypedBox(settingsBox);
  }

  Future<void> _openHistoryBox() async {
    if (Hive.isBoxOpen(boxName)) return;

    try {
      await Hive.openBox<HistoryExpenseModel>(boxName);
      return;
    } catch (e) {
      debugPrint('Typed history_box open failed: $e');
    }

    try {
      final raw = await Hive.openBox(boxName);
      final recovered = <String, HistoryExpenseModel>{};
      for (final value in raw.values) {
        if (value is HistoryExpenseModel) {
          recovered[value.id] = value;
        }
      }
      await raw.close();
      await Hive.deleteBoxFromDisk(boxName);
      final box = await Hive.openBox<HistoryExpenseModel>(boxName);
      if (recovered.isNotEmpty) {
        await box.putAll(recovered);
      }
    } catch (e, st) {
      debugPrint('history_box recovery failed: $e\n$st');
      await Hive.deleteBoxFromDisk(boxName);
      await Hive.openBox<HistoryExpenseModel>(boxName);
    }
  }

  Future<void> _openUntypedBox(String name) async {
    try {
      if (!Hive.isBoxOpen(name)) {
        await Hive.openBox(name);
      }
    } catch (e, st) {
      debugPrint('$name damaged, recreating: $e\n$st');
      await Hive.deleteBoxFromDisk(name);
      await Hive.openBox(name);
    }
  }
}
