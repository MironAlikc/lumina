import 'package:hive_flutter/hive_flutter.dart';

class HiveClient {
  static const String boxName = 'lumina_expenses_box';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);

    final box = Hive.box(boxName);
    if (box.isEmpty) {
      final demo = [
        {
          'id': '1',
          'date': DateTime(2026, 7, 1).millisecondsSinceEpoch,
          'productName': 'Красный перец 2',
          'price': 58.0,
        },
        {
          'id': '2',
          'date': DateTime(2026, 7, 1).millisecondsSinceEpoch,
          'productName': 'киви 3',
          'price': 62.0,
        },
        {
          'id': '3',
          'date': DateTime(2026, 7, 1).millisecondsSinceEpoch,
          'productName': 'молоко',
          'price': 39.0,
        },
        {
          'id': '4',
          'date': DateTime(2026, 7, 1).millisecondsSinceEpoch,
          'productName': 'огурци',
          'price': 12.0,
        },
        {
          'id': '5',
          'date': DateTime(2026, 6, 6).millisecondsSinceEpoch,
          'productName': 'молоко 2',
          'price': 90.0,
        },
        {
          'id': '6',
          'date': DateTime(2026, 6, 6).millisecondsSinceEpoch,
          'productName': 'Банан',
          'price': 46.0,
        },
        {
          'id': '7',
          'date': DateTime(2026, 6, 7).millisecondsSinceEpoch,
          'productName': 'огурци',
          'price': 65.0,
        },
        {
          'id': '8',
          'date': DateTime(2026, 6, 7).millisecondsSinceEpoch,
          'productName': 'помидоры чери',
          'price': 187.0,
        },
      ];
      for (var e in demo) {
        await box.put(e['id'], e);
      }
    }
  }
}
