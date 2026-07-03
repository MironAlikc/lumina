import 'dart:async';
import 'package:flutter/material.dart';

class LuminaLocalizations {
  final Locale locale;
  LuminaLocalizations(this.locale);

  static LuminaLocalizations of(BuildContext context) {
    return Localizations.of<LuminaLocalizations>(context, LuminaLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Lumina',
      'totalSpent': 'Total spent in selected filter',
      'searchHint': 'Search product (e.g. cucumbers)...',
      'addPurchase': 'New Purchase',
      'productName': 'Product Name',
      'price': 'Price',
      'addButton': 'Add to list',
      'emptyList': 'No items found. Time to shop!',
      'allMonths': 'All Time',
      'priceTrend': 'Price Dynamic',
      'analytics': 'Analytics',
    },
    'uk': {
      'appTitle': 'Lumina',
      'totalSpent': 'Всього витрачено за фільтром',
      'searchHint': 'Пошук продукту (напр. огірки)...',
      'addPurchase': 'Нова покупка',
      'productName': 'Назва товару',
      'price': 'Ціна',
      'addButton': 'Додати до списку',
      'emptyList': 'Нічого не знайдено. Час оновити витрати!',
      'allMonths': 'Весь час',
      'priceTrend': 'Динаміка цін',
      'analytics': 'Аналітика',
    },
    'ru': {
      'appTitle': 'Lumina',
      'totalSpent': 'Всего потрачено по фильтру',
      'searchHint': 'Поиск продукта (напр. огурцы)...',
      'addPurchase': 'Новая покупка',
      'productName': 'Название товара',
      'price': 'Цена',
      'addButton': 'Добавить в список',
      'emptyList': 'Ничего не найдено. Время внести расходы!',
      'allMonths': 'Все время',
      'priceTrend': 'Динамика цен',
      'analytics': 'Аналитика',
    },
  };

  String translate(String key) =>
      _localizedValues[locale.languageCode]?[key] ?? key;
}

class LuminaLocalizationsDelegate
    extends LocalizationsDelegate<LuminaLocalizations> {
  const LuminaLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) =>
      ['en', 'uk', 'ru'].contains(locale.languageCode);
  @override
  Future<LuminaLocalizations> load(Locale locale) async =>
      LuminaLocalizations(locale);
  @override
  bool shouldReload(LuminaLocalizationsDelegate old) => false;
}
