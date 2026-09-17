import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:lumina/core/database/hive_client.dart';
import 'package:lumina/core/enums/app_currency.dart';

class CurrencyCubit extends Cubit<AppCurrency> {
  static const currencyKey = 'selected_currency';

  CurrencyCubit() : super(AppCurrency.uah);

  Future<void> hydrate() async {
    try {
      final box = await _settingsBox();
      final saved = box.get(currencyKey);
      final currency = AppCurrency.fromStored(saved is String ? saved : null);
      if (currency != state) emit(currency);
    } catch (e, st) {
      debugPrint('Error loading currency: $e\n$st');
    }
  }

  Future<void> changeCurrency(AppCurrency currency) async {
    if (currency == state) return;
    try {
      final box = await _settingsBox();
      await box.put(currencyKey, currency.name);
      emit(currency);
    } catch (e, st) {
      debugPrint('Error saving currency: $e\n$st');
    }
  }

  Future<Box<dynamic>> _settingsBox() async {
    if (Hive.isBoxOpen(HiveClient.boxName)) {
      return Hive.box(HiveClient.boxName);
    }
    return Hive.openBox(HiveClient.boxName);
  }
}
